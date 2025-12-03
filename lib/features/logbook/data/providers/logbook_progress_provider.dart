import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../models/logbook_progress_stats.dart';
import '../../../../data/models/logbook_model.dart';

/// Provider for logbook progress statistics
/// Aggregates data from multiple endpoints to provide comprehensive progress metrics
final logbookProgressProvider = FutureProvider.autoDispose<LogbookProgressStats?>((ref) async {
  final authState = ref.watch(authProviderV2);
  final user = authState.user;
  
  if (user == null) return null;
  
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    print('🔍 [LogbookProgress] Fetching data for user ${user.id}');
    
    // Fetch all required data in parallel
    final results = await Future.wait<Map<String, dynamic>>([
      repository.getLogbookSkills(page: 1, pageSize: 100),
      repository.getMemberLogbookSkills(memberId: user.id, page: 1, pageSize: 100),
      repository.getMemberLogbookEntries(memberId: user.id, page: 1, pageSize: 100),
      repository.getMemberTripCounts(user.id),
    ]);
    
    final allSkillsResponse = results[0];
    final memberSkillsResponse = results[1];
    final entriesResponse = results[2];
    final tripCountsResponse = results[3];
    
    print('📊 [LogbookProgress] API Response Summary:');
    print('   All Skills: ${allSkillsResponse['count'] ?? 'N/A'} total, ${(allSkillsResponse['results'] as List).length} in this page');
    print('   Member Skills: ${memberSkillsResponse['count'] ?? 'N/A'} total, ${(memberSkillsResponse['results'] as List).length} in this page');
    print('   Logbook Entries: ${entriesResponse['count'] ?? 'N/A'} total, ${(entriesResponse['results'] as List).length} in this page');
    print('   Trip Counts: ${tripCountsResponse['total_trips'] ?? 0} total trips, ${tripCountsResponse['checked_in_trips'] ?? 0} checked in');
    
    // Parse all skills
    final allSkills = (allSkillsResponse['results'] as List<dynamic>)
        .map((json) {
          try {
            return LogbookSkill.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Failed to parse skill: $e');
            }
            return null;
          }
        })
        .whereType<LogbookSkill>()
        .toList();
    
    // Parse member's verified skills - these are actually skill REFERENCES with just IDs
    final verifiedSkillRefs = (memberSkillsResponse['results'] as List<dynamic>)
        .map((json) {
          try {
            return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Failed to parse skill reference: $e');
            print('   JSON: $json');
            return null;
          }
        })
        .whereType<LogbookSkillReference>()
        .toList();
    
    // Extract verified skill IDs
    final verifiedSkillIds = verifiedSkillRefs.map((ref) => ref.logbookSkill.id).toSet();
    
    print('🔍 [LogbookProgress] Verified skill IDs from API: $verifiedSkillIds');
    
    // Cross-reference with full skills list to get complete skill data
    final verifiedSkills = allSkills.where((skill) => verifiedSkillIds.contains(skill.id)).toList();
    
    print('✅ [LogbookProgress] Parsed ${verifiedSkills.length} verified skills:');
    for (final skill in verifiedSkills) {
      print('   - ID: ${skill.id}, Name: ${skill.name}, Level: ${skill.level.id} (${skill.level.name})');
    }
    
    // Parse logbook entries for recent activity
    print('🔍 [LogbookProgress] Parsing ${(entriesResponse['results'] as List).length} logbook entries...');
    final entries = (entriesResponse['results'] as List<dynamic>)
        .map((json) {
          try {
            return LogbookEntry.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Failed to parse logbook entry: $e');
            print('   Entry JSON: $json');
            return null;
          }
        })
        .whereType<LogbookEntry>() // Filter out nulls
        .toList();
    
    print('✅ [LogbookProgress] Successfully parsed ${entries.length} entries');
    
    // Get trip counts
    final totalTrips = tripCountsResponse['total_trips'] as int? ?? 0;
    final checkedInTrips = tripCountsResponse['checked_in_trips'] as int? ?? 0;
    
    // Get user's profile level (source of truth)
    final userProfileLevel = user.level;
    if (userProfileLevel == null) {
      throw Exception('User profile level is missing');
    }
    final currentLevelId = userProfileLevel.id;
    final currentLevelName = userProfileLevel.displayName ?? userProfileLevel.name;
    final currentLevelNumeric = userProfileLevel.numericLevel;
    
    print('👤 [LogbookProgress] User Profile Level:');
    print('   Level ID: $currentLevelId');
    print('   Level Name: $currentLevelName');
    print('   Numeric Level: $currentLevelNumeric');
    
    // Calculate skills for current level only
    final currentLevelSkills = allSkills.where((s) => s.level.id == currentLevelId).toList();
    final verifiedCurrentLevel = verifiedSkills.where((s) => s.level.id == currentLevelId).toList();
    
    print('📊 [LogbookProgress] Current Level Skills:');
    print('   Total for $currentLevelName: ${currentLevelSkills.length}');
    print('   Verified for $currentLevelName: ${verifiedCurrentLevel.length}');
    
    // Calculate breakdown for ALL levels (for skills matrix)
    final allLevelsBreakdown = _calculateAllLevelsBreakdown(allSkills, verifiedSkills);
    
    print('📈 [LogbookProgress] Final Statistics:');
    print('   Current Level: $currentLevelName ($currentLevelNumeric)');
    print('   Current Level Skills: ${verifiedCurrentLevel.length}/${currentLevelSkills.length}');
    print('   All Skills: ${verifiedSkills.length}/${allSkills.length}');
    print('   Checked-In Trips: $checkedInTrips');
    print('   Logbook Entries: ${entries.length}');
    
    // Return statistics based on profile level
    return LogbookProgressStats(
      currentLevelName: currentLevelName,
      currentLevelNumeric: currentLevelNumeric,
      currentLevelId: currentLevelId,
      totalSkillsForCurrentLevel: currentLevelSkills.length,
      verifiedSkillsForCurrentLevel: verifiedCurrentLevel.length,
      totalSkillsAllLevels: allSkills.length,
      verifiedSkillsAllLevels: verifiedSkills.length,
      totalTrips: totalTrips,
      checkedInTrips: checkedInTrips,
      recentEntries: entries.take(5).toList(),
      allLevelsBreakdown: allLevelsBreakdown,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error fetching logbook progress: $e');
    }
    rethrow;
  }
});

/// Calculate skills breakdown for ALL levels (used in skills matrix)
Map<int, LevelProgressData> _calculateAllLevelsBreakdown(
  List<LogbookSkill> allSkills,
  List<LogbookSkill> verifiedSkills,
) {
  final breakdown = <int, LevelProgressData>{};
  
  // Group skills by level ID
  final skillsByLevel = <int, List<LogbookSkill>>{};
  for (final skill in allSkills) {
    skillsByLevel.putIfAbsent(skill.level.id, () => []).add(skill);
  }
  
  // Create breakdown for each level that has skills
  for (final levelId in skillsByLevel.keys) {
    final levelSkills = skillsByLevel[levelId]!;
    final verifiedLevelSkills = verifiedSkills.where((s) => s.level.id == levelId).toList();
    
    // Use actual level name from API, not hardcoded mapping
    final levelName = levelSkills.first.level.name;
    
    breakdown[levelId] = LevelProgressData(
      levelId: levelId,
      levelName: levelName,
      totalSkills: levelSkills.length,
      verifiedSkills: verifiedLevelSkills.length,
      skills: levelSkills,
    );
    
    print('📊 [AllLevelsBreakdown] Level $levelId ($levelName): ${verifiedLevelSkills.length}/${levelSkills.length} skills');
  }
  
  return breakdown;
}


