import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../../services/certificate_service.dart';

/// Certificate Provider
/// 
/// Manages skill verification certificates with generation and filtering
class CertificatesNotifier extends StateNotifier<AsyncValue<List<SkillCertificate>>> {
  final MainApiRepository _repository;
  final int memberId;
  final CertificateService _certificateService = CertificateService();
  CertificateFilter _filter = const CertificateFilter();

  CertificatesNotifier(this._repository, this.memberId) : super(const AsyncValue.loading()) {
    _loadCertificates();
  }

  CertificateFilter get filter => _filter;

  /// Load all certificates for member
  /// ✅ CLIENT-SIDE ENRICHMENT: Fetches full objects for member, skill, marshal, trip
  /// Backend returns only IDs despite expand parameter, so we enrich client-side
  Future<void> _loadCertificates() async {
    state = const AsyncValue.loading();

    try {
      if (kDebugMode) {
        debugPrint('🔍 [Certificates] Loading certificates for member $memberId...');
      }

      // Fetch skill references (verified skills) for the member
      final response = await _repository.getMemberLogbookSkills(
        memberId: memberId,
        page: 1,
        pageSize: 200,
      );
      
      final List<Map<String, dynamic>> rawData = [];
      final data = response['results'] ?? response['data'] ?? response;

      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            rawData.add(item);
          }
        }
      }

      if (kDebugMode) {
        debugPrint('🔍 [Certificates] Loaded ${rawData.length} skill references (ID-only), starting enrichment...');
      }

      // Collect all unique IDs for batch fetching
      final memberIds = <int>{};
      final skillIds = <int>{};
      final tripIds = <int>{};

      for (final item in rawData) {
        if (item['member'] is int) memberIds.add(item['member'] as int);
        if (item['logbookSkill'] is int) skillIds.add(item['logbookSkill'] as int);
        if (item['trip'] is int) tripIds.add(item['trip'] as int);
        // Note: API doesn't return verifiedBy/signedBy field for this endpoint
      }

      if (kDebugMode) {
        debugPrint('🔍 [Certificates] Collected IDs - Members: ${memberIds.length}, Skills: ${skillIds.length}, Trips: ${tripIds.length}');
      }

      // Fetch all members
      final memberCache = <int, MemberBasicInfo>{};
      for (final id in memberIds) {
        try {
          final memberResponse = await _repository.getMemberProfile(id);
          memberCache[id] = MemberBasicInfo.fromJson(memberResponse);
          if (kDebugMode) {
            debugPrint('✅ [Certificates] Cached member $id: ${memberCache[id]?.displayName}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [Certificates] Failed to fetch member $id: $e');
          }
          memberCache[id] = MemberBasicInfo(
            id: id,
            firstName: 'Member',
            lastName: '#$id',
          );
        }
      }

      // Fetch all skills
      final skillCache = <int, LogbookSkillBasicInfo>{};
      final skillsResponse = await _repository.getLogbookSkills(page: 1, pageSize: 100);
      final skillsData = skillsResponse['results'] as List<dynamic>? ?? [];
      for (final json in skillsData) {
        try {
          final skill = LogbookSkill.fromJson(json as Map<String, dynamic>);
          skillCache[skill.id] = LogbookSkillBasicInfo(
            id: skill.id,
            name: skill.name,
            description: skill.description,
            order: skill.order,
            level: skill.level,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [Certificates] Failed to parse skill: $e');
          }
        }
      }
      if (kDebugMode) {
        debugPrint('✅ [Certificates] Cached ${skillCache.length} skills');
      }

      // Fetch all trips
      final tripCache = <int, TripBasicInfo>{};
      for (final id in tripIds) {
        try {
          final tripResponse = await _repository.getTrip(id);
          tripCache[id] = TripBasicInfo.fromJson(tripResponse);
          if (kDebugMode) {
            debugPrint('✅ [Certificates] Cached trip $id: ${tripCache[id]?.title}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [Certificates] Failed to fetch trip $id: $e');
          }
          tripCache[id] = TripBasicInfo(
            id: id,
            title: 'Trip #$id',
            startTime: DateTime.now(),
          );
        }
      }

      // Enrich skill references
      final List<LogbookSkillReference> skillRefs = [];
      for (var item in rawData) {
        try {
          // Extract IDs
          final memberId = item['member'] as int?;
          final skillId = item['logbookSkill'] as int?;
          final tripId = item['trip'] as int?;

          if (memberId == null || skillId == null) continue;

          // Enrich with cached data
          final enrichedMember = memberCache[memberId] ?? MemberBasicInfo(
            id: memberId,
            firstName: 'Member',
            lastName: '#$memberId',
          );

          final enrichedSkill = skillCache[skillId] ?? LogbookSkillBasicInfo(
            id: skillId,
            name: 'Skill #$skillId',
            description: '',
            order: 0,
            level: SkillLevel(
              id: 1,
              name: 'Unknown',
              numericLevel: 1,
              displayName: 'Unknown',
              active: true,
            ),
          );

          final enrichedTrip = tripId != null ? (tripCache[tripId] ?? TripBasicInfo(
            id: tripId,
            title: 'Trip #$tripId',
            startTime: DateTime.now(),
          )) : null;

          // Note: API doesn't provide verifiedBy for this endpoint
          // Use placeholder marshal
          final placeholderMarshal = MemberBasicInfo(
            id: 0,
            firstName: 'Marshal',
            lastName: 'Unknown',
          );

          skillRefs.add(LogbookSkillReference(
            id: item['id'] as int? ?? 0,
            member: enrichedMember,
            logbookSkill: enrichedSkill,
            trip: enrichedTrip,
            verifiedBy: placeholderMarshal,
            verifiedAt: DateTime.now(), // API doesn't provide this field
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [Certificates] Failed to enrich skill reference: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ [Certificates] Enrichment complete! Created ${skillRefs.length} enriched skill references');
      }

      // Generate certificates from enriched skill references
      final certificates = await _generateCertificatesFromSkillReferences(skillRefs);

      state = AsyncValue.data(certificates);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ [Certificates] Error loading certificates: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  /// Generate certificates from skill references (verified skills)
  Future<List<SkillCertificate>> _generateCertificatesFromSkillReferences(
    List<LogbookSkillReference> skillRefs,
  ) async {
    if (skillRefs.isEmpty) return [];

    // Group skills by verification date (monthly certificates)
    final skillsByMonth = <String, List<CertifiedSkill>>{};
    
    for (var skillRef in skillRefs) {
      final monthKey = '${skillRef.verifiedAt.year}-${skillRef.verifiedAt.month.toString().padLeft(2, '0')}';
      
      final certifiedSkill = CertifiedSkill(
        skill: skillRef.logbookSkill,
        verifiedDate: skillRef.verifiedAt,
        verifiedBy: skillRef.verifiedBy,
        tripName: skillRef.trip?.title,
        tripId: skillRef.trip?.id,
        notes: skillRef.comment,
      );

      skillsByMonth.putIfAbsent(monthKey, () => []).add(certifiedSkill);
    }

    // Create certificates for each month
    final certificates = <SkillCertificate>[];
    final uuid = const Uuid();

    // Get member info from first skill reference
    final memberInfo = skillRefs.isNotEmpty 
        ? skillRefs.first.member 
        : MemberBasicInfo(
            id: memberId,
            firstName: 'Member',
            lastName: '#$memberId',
            level: null,
          );

    for (var entry in skillsByMonth.entries) {
      final skills = entry.value;
      if (skills.isEmpty) continue;

      // Calculate statistics
      final stats = _calculateStats(skills);
      
      // Use first day of month as issue date
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final issueDate = DateTime(year, month, 1);

      certificates.add(SkillCertificate(
        certificateId: uuid.v4().substring(0, 8).toUpperCase(),
        member: memberInfo,
        skills: skills,
        issueDate: issueDate,
        clubName: 'Abu Dhabi Off-Road Club',
        clubLogo: 'https://ap.ad4x4.com/static/images/club-logo.png', // Club logo from backend
        stats: stats,
      ));
    }

    // Sort certificates by issue date (newest first)
    certificates.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return certificates;
  }

  /// Calculate certificate statistics
  /// UPDATED: Now uses dynamic level names instead of hard-coded numeric levels
  CertificateStats _calculateStats(List<CertifiedSkill> skills) {
    final levelCounts = <String, int>{}; // Changed to String keys for level names
    final signOffs = <int>{};
    final categories = <String>{};

    for (var skill in skills) {
      final levelName = skill.skill.level.name; // Use level name instead of numeric
      levelCounts[levelName] = (levelCounts[levelName] ?? 0) + 1;
      signOffs.add(skill.verifiedBy.id);
      
      // Derive category from skill name
      final category = _deriveSkillCategory(skill.skill.name);
      if (category != null) {
        categories.add(category);
      }
    }

    return CertificateStats(
      totalSkills: skills.length,
      skillsByLevel: levelCounts, // Dynamic level mapping
      uniqueSignOffs: signOffs.length,
      categories: categories.toList(),
    );
  }

  /// Derive skill category from skill name
  /// Smart categorization based on skill name keywords
  String? _deriveSkillCategory(String skillName) {
    final name = skillName.toLowerCase();
    
    // Driving skills
    if (name.contains('dune') || name.contains('sand') || name.contains('desert')) {
      return 'Dune Driving';
    }
    if (name.contains('rock') || name.contains('boulder') || name.contains('mountain')) {
      return 'Rock Crawling';
    }
    if (name.contains('mud') || name.contains('water') || name.contains('crossing')) {
      return 'Water/Mud Driving';
    }
    
    // Technical skills
    if (name.contains('recovery') || name.contains('winch') || name.contains('snatch')) {
      return 'Vehicle Recovery';
    }
    if (name.contains('maintenance') || name.contains('repair') || name.contains('mechanic')) {
      return 'Vehicle Maintenance';
    }
    if (name.contains('tire') || name.contains('tyre') || name.contains('deflation')) {
      return 'Tire Management';
    }
    
    // Navigation & Communication
    if (name.contains('navigation') || name.contains('gps') || name.contains('map')) {
      return 'Navigation';
    }
    if (name.contains('communication') || name.contains('radio') || name.contains('cb')) {
      return 'Communication';
    }
    
    // Safety & Leadership
    if (name.contains('safety') || name.contains('first aid') || name.contains('emergency')) {
      return 'Safety';
    }
    if (name.contains('convoy') || name.contains('marshal') || name.contains('leader')) {
      return 'Leadership';
    }
    if (name.contains('trip planning') || name.contains('route')) {
      return 'Trip Planning';
    }
    
    // Environmental
    if (name.contains('environment') || name.contains('tread lightly') || name.contains('eco')) {
      return 'Environmental';
    }
    
    // Default to general if no specific category matches
    return 'General Skills';
  }

  /// Update filter and apply
  Future<void> updateFilter(CertificateFilter newFilter) async {
    _filter = newFilter;
    await _applyFilter();
  }

  /// Reset filter
  Future<void> resetFilter() async {
    _filter = const CertificateFilter();
    await _loadCertificates();
  }

  /// Apply current filter to certificates
  Future<void> _applyFilter() async {
    state.whenData((allCertificates) {
      var filtered = List<SkillCertificate>.from(allCertificates);

      // Time range filter
      final startDate = _filter.timeRange.startDate;
      if (startDate != null) {
        filtered = filtered.where((cert) => cert.issueDate.isAfter(startDate)).toList();
      }

      // Recent filter
      if (_filter.onlyRecent) {
        filtered = filtered.where((cert) => cert.isRecent).toList();
      }

      // Level filter
      if (_filter.selectedLevelIds.isNotEmpty) {
        filtered = filtered.where((cert) {
          return cert.skills.any((skill) {
            return _filter.selectedLevelIds.contains(
              skill.skill.level.numericLevel,
            );
          });
        }).toList();
      }

      // Category filter - use derived categories
      if (_filter.selectedCategories.isNotEmpty) {
        filtered = filtered.where((cert) {
          // Check if certificate has skills in selected categories
          return cert.skills.any((skill) {
            final category = _deriveSkillCategory(skill.skill.name);
            return category != null && _filter.selectedCategories.contains(category);
          });
        }).toList();
      }

      state = AsyncValue.data(filtered);
    });
  }

  /// Refresh certificates
  Future<void> refresh() async {
    await _loadCertificates();
  }

  /// Generate certificate PDF (the slow part - PDF generation)
  Future<Uint8List> generateCertificatePDF(SkillCertificate certificate) async {
    return _certificateService.generateCertificatePDF(certificate);
  }

  /// Show preview with pre-generated PDF (fast - just display)
  Future<void> showPreview(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showPreview(certificate, pdfData);
  }

  /// Show share sheet with pre-generated PDF (fast - just display)
  Future<void> showShare(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showShare(certificate, pdfData);
  }

  /// Show print dialog with pre-generated PDF (fast - just display)
  Future<void> showPrint(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showPrint(certificate, pdfData);
  }

  /// Generate certificate PDF (legacy method)
  Future<Uint8List> generatePDF(SkillCertificate certificate) async {
    return _certificateService.generateCertificatePDF(certificate);
  }

  /// Preview certificate (legacy method - slow, combines generation + display)
  Future<void> previewCertificate(SkillCertificate certificate) async {
    await _certificateService.previewCertificate(certificate);
  }

  /// Share certificate (legacy method - slow, combines generation + display)
  Future<void> shareCertificate(SkillCertificate certificate) async {
    await _certificateService.shareCertificate(certificate);
  }

  /// Print certificate (legacy method - slow, combines generation + display)
  Future<void> printCertificate(SkillCertificate certificate) async {
    await _certificateService.printCertificate(certificate);
  }
}

/// Provider for certificates
final certificatesProvider = StateNotifierProvider.family
    .autoDispose<CertificatesNotifier, AsyncValue<List<SkillCertificate>>, int>(
  (ref, memberId) {
    final repository = ref.watch(mainApiRepositoryProvider);
    return CertificatesNotifier(repository, memberId);
  },
);

/// Provider for filtered certificates count
final filteredCertificatesCountProvider = Provider.family.autoDispose<int, int>((ref, memberId) {
  final certificatesAsync = ref.watch(certificatesProvider(memberId));
  return certificatesAsync.maybeWhen(
    data: (certificates) => certificates.length,
    orElse: () => 0,
  );
});
