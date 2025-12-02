import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';

/// Provider for fetching member's skill verification history (RAW DATA)
/// Returns list of LogbookSkillReference sorted by verification date (newest first)
/// NOTE: Use memberSkillVerificationHistoryEnrichedProvider for enriched data with names
final memberSkillVerificationHistoryProvider = FutureProvider.autoDispose
    .family<List<LogbookSkillReference>, int?>((ref, memberId) async {
  final authState = ref.watch(authProviderV2);
  final targetMemberId = memberId ?? authState.user?.id;
  
  if (targetMemberId == null) {
    throw Exception('No member ID provided');
  }

  final repository = ref.watch(mainApiRepositoryProvider);
  
  final response = await repository.getLogbookSkillReferences(
    memberId: targetMemberId,
    page: 1,
    pageSize: 100, // Get all verifications
  );

  final results = response['results'] as List<dynamic>;
  final references = results
      .map((json) {
        try {
          return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ [MemberVerificationHistory] Failed to parse reference: $e');
          print('   JSON: $json');
          return null;
        }
      })
      .whereType<LogbookSkillReference>()  // Filter out nulls
      .toList();

  // Sort by verification date (newest first)
  references.sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

  return references;
});

/// Provider for enriched member's skill verification history
/// Returns references with resolved member/verifiedBy names
/// This provider automatically enriches the data when it changes
final memberSkillVerificationHistoryEnrichedProvider = FutureProvider.autoDispose
    .family<List<LogbookSkillReference>, int?>((ref, memberId) async {
  // Get raw references first
  final rawReferences = await ref.watch(memberSkillVerificationHistoryProvider(memberId).future);
  
  if (rawReferences.isEmpty) {
    return rawReferences;
  }

  // Enrich the references with actual names
  final enrichmentService = ref.watch(logbookEnrichmentServiceProvider);
  print('🔄 [EnrichedProvider] Auto-enriching ${rawReferences.length} references...');
  
  try {
    final enriched = await enrichmentService.enrichSkillReferences(rawReferences);
    print('✅ [EnrichedProvider] Successfully enriched ${enriched.length} references');
    return enriched;
  } catch (e) {
    print('⚠️ [EnrichedProvider] Enrichment failed: $e');
    return rawReferences; // Fallback to raw data
  }
});

/// Provider for fetching verifications for a specific skill
/// Shows who has been verified for this skill
final skillVerificationHistoryProvider = FutureProvider.autoDispose
    .family<List<LogbookSkillReference>, int>((ref, skillId) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  final response = await repository.getLogbookSkillReferences(
    skillId: skillId,
    page: 1,
    pageSize: 100,
  );

  final results = response['results'] as List<dynamic>;
  final references = results
      .map((json) {
        try {
          return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ [SkillVerificationHistory] Failed to parse reference: $e');
          print('   JSON: $json');
          return null;
        }
      })
      .whereType<LogbookSkillReference>()  // Filter out nulls
      .toList();

  // Sort by verification date (newest first)
  references.sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

  return references;
});

/// Provider for fetching verifications on a specific trip
/// Shows all skills verified during a trip
final tripSkillVerificationsProvider = FutureProvider.autoDispose
    .family<List<LogbookSkillReference>, int>((ref, tripId) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  final response = await repository.getLogbookSkillReferences(
    tripId: tripId,
    page: 1,
    pageSize: 100,
  );

  final results = response['results'] as List<dynamic>;
  final references = results
      .map((json) {
        try {
          return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ [TripSkillVerifications] Failed to parse reference: $e');
          print('   JSON: $json');
          return null;
        }
      })
      .whereType<LogbookSkillReference>()  // Filter out nulls
      .toList();

  // Group by member for easier display
  references.sort((a, b) {
    // First sort by member name
    final memberCompare = a.member.displayName.compareTo(b.member.displayName);
    if (memberCompare != 0) return memberCompare;
    // Then by skill level
    return a.logbookSkill.level.numericLevel.compareTo(b.logbookSkill.level.numericLevel);
  });

  return references;
});

/// Verification statistics for a member
class VerificationStats {
  final int totalVerifications;
  final int uniqueSkills;
  final int uniqueVerifiers;
  final int verificationsWithTrips;
  final DateTime? firstVerification;
  final DateTime? lastVerification;
  final Map<int, int> verificationsByLevel; // level -> count

  const VerificationStats({
    required this.totalVerifications,
    required this.uniqueSkills,
    required this.uniqueVerifiers,
    required this.verificationsWithTrips,
    this.firstVerification,
    this.lastVerification,
    required this.verificationsByLevel,
  });
}

/// Provider for member verification statistics
final memberVerificationStatsProvider = FutureProvider.autoDispose
    .family<VerificationStats, int?>((ref, memberId) async {
  final references = await ref.watch(memberSkillVerificationHistoryProvider(memberId).future);

  if (references.isEmpty) {
    return const VerificationStats(
      totalVerifications: 0,
      uniqueSkills: 0,
      uniqueVerifiers: 0,
      verificationsWithTrips: 0,
      verificationsByLevel: {},
    );
  }

  final uniqueSkills = references.map((r) => r.logbookSkill.id).toSet().length;
  final uniqueVerifiers = references.map((r) => r.verifiedBy.id).toSet().length;
  final verificationsWithTrips = references.where((r) => r.trip != null).length;

  // Count by level
  final verificationsByLevel = <int, int>{};
  for (final ref in references) {
    final level = ref.logbookSkill.level.numericLevel;
    verificationsByLevel[level] = (verificationsByLevel[level] ?? 0) + 1;
  }

  // Get date range
  final dates = references.map((r) => r.verifiedAt).toList()..sort();

  return VerificationStats(
    totalVerifications: references.length,
    uniqueSkills: uniqueSkills,
    uniqueVerifiers: uniqueVerifiers,
    verificationsWithTrips: verificationsWithTrips,
    firstVerification: dates.first,
    lastVerification: dates.last,
    verificationsByLevel: verificationsByLevel,
  );
});
