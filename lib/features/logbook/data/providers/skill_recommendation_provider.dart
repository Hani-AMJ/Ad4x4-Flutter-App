/// Skill Recommendation Provider
/// 
/// Intelligent skill recommendations based on progression, trips, and peers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../models/skill_recommendation.dart';

/// Provider for skill recommendations
final skillRecommendationsProvider = FutureProvider.autoDispose
    .family<List<SkillRecommendation>, int?>((ref, memberId) async {
  final authState = ref.watch(authProviderV2);
  final effectiveMemberId = memberId ?? authState.user?.id;
  
  if (effectiveMemberId == null) {
    throw Exception('No member ID provided');
  }

  final repository = ref.watch(mainApiRepositoryProvider);

  // Fetch all skills
  final skillsResponse = await repository.getLogbookSkills(
    page: 1,
    pageSize: 100,
  );
  final skillsData = skillsResponse['results'] as List<dynamic>;
  final allSkills = skillsData
      .map((json) => LogbookSkill.fromJson(json as Map<String, dynamic>))
      .toList();

  // Fetch member's verified skills
  final verifiedSkillsResponse = await repository.getLogbookSkillReferences(
    memberId: effectiveMemberId,
    page: 1,
    pageSize: 100,
  );
  final verifiedData = verifiedSkillsResponse['results'] as List<dynamic>;
  final verifiedSkills = verifiedData
      .map((json) {
        try {
          return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ [SkillRecommendations] Failed to parse verified skill: $e');
          print('   JSON: $json');
          return null;
        }
      })
      .whereType<LogbookSkillReference>()
      .toList();

  // Get upcoming trips
  final now = DateTime.now();
  final thirtyDaysLater = now.add(const Duration(days: 30));
  final tripsResponse = await repository.getTrips(
    page: 1,
    pageSize: 50,
    startTimeAfter: now.toIso8601String(),
    startTimeBefore: thirtyDaysLater.toIso8601String(),
    approvalStatus: 'P',
  );
  final tripsData = tripsResponse['results'] as List<dynamic>;
  final upcomingTrips = tripsData
      .map((json) => TripBasicInfo.fromJson(json as Map<String, dynamic>))
      .toList();
  
  // Get verified skill IDs
  final verifiedSkillIds = verifiedSkills.map((ref) => ref.logbookSkill.id).toSet();
  
  // Get unverified skills
  final unverifiedSkills = allSkills
      .where((skill) => !verifiedSkillIds.contains(skill.id))
      .toList();
  
  // Generate recommendations
  final recommendations = <SkillRecommendation>[];
  
  // Determine member's current level from user profile (source of truth)
  final currentLevel = _determineCurrentLevel(authState.user);
  
  for (final skill in unverifiedSkills) {
    final recommendation = _generateRecommendation(
      skill,
      verifiedSkills,
      allSkills,
      currentLevel,
      upcomingTrips,
    );
    
    if (recommendation != null) {
      recommendations.add(recommendation);
    }
  }
  
  // Sort by priority (highest first)
  recommendations.sort((a, b) => b.priority.compareTo(a.priority));
  
  return recommendations;
});

/// Provider for recommendation statistics
final recommendationStatsProvider = FutureProvider.autoDispose
    .family<RecommendationStats, int?>((ref, memberId) async {
  final authState = ref.watch(authProviderV2);
  final effectiveMemberId = memberId ?? authState.user?.id;
  
  if (effectiveMemberId == null) {
    throw Exception('No member ID provided');
  }

  final repository = ref.watch(mainApiRepositoryProvider);
  
  final recommendations = await ref.watch(skillRecommendationsProvider(effectiveMemberId).future);
  
  // Fetch all skills
  final skillsResponse = await repository.getLogbookSkills(
    page: 1,
    pageSize: 100,
  );
  final skillsData = skillsResponse['results'] as List<dynamic>;
  final allSkills = skillsData
      .map((json) => LogbookSkill.fromJson(json as Map<String, dynamic>))
      .toList();

  // Fetch member's verified skills
  final verifiedSkillsResponse = await repository.getLogbookSkillReferences(
    memberId: effectiveMemberId,
    page: 1,
    pageSize: 100,
  );
  final verifiedData = verifiedSkillsResponse['results'] as List<dynamic>;
  final verifiedSkills = verifiedData
      .map((json) {
        try {
          return LogbookSkillReference.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ [RecommendationStats] Failed to parse verified skill: $e');
          print('   JSON: $json');
          return null;
        }
      })
      .whereType<LogbookSkillReference>()
      .toList();
  
  final highPriorityCount = recommendations.where((r) => r.priority >= 4).length;
  final upcomingTripOpportunities = recommendations
      .where((r) => r.isUpcomingTripOpportunity)
      .length;
  
  // Calculate current level completion from user profile (source of truth)
  final currentLevel = _determineCurrentLevel(authState.user);
  final currentLevelSkills = allSkills.where((s) => s.level.numericLevel == currentLevel).toList();
  final verifiedSkillIds = verifiedSkills.map((r) => r.logbookSkill.id).toSet();
  final verifiedCurrentLevel = currentLevelSkills
      .where((s) => verifiedSkillIds.contains(s.id))
      .length;
  final currentLevelCompletion = currentLevelSkills.isEmpty
      ? 0.0
      : verifiedCurrentLevel / currentLevelSkills.length;
  
  // Next level target
  final nextLevel = currentLevel + 1;
  final nextLevelName = nextLevel <= 5 ? _getLevelName(nextLevel) : null;
  final skillsNeededForNextLevel = allSkills
      .where((s) => s.level.numericLevel == nextLevel)
      .length;
  
  // Top categories (most recommended skill types)
  final categoryCount = <String, int>{};
  for (final rec in recommendations) {
    final category = _getSkillCategory(rec.skill.name);
    categoryCount[category] = (categoryCount[category] ?? 0) + 1;
  }
  final topCategories = categoryCount.entries
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  final topCategoryNames = topCategories.take(3).map((e) => e.key).toList();
  
  return RecommendationStats(
    totalRecommendations: recommendations.length,
    highPriorityCount: highPriorityCount,
    upcomingTripOpportunities: upcomingTripOpportunities,
    nextLevelTarget: nextLevelName,
    skillsNeededForNextLevel: skillsNeededForNextLevel,
    currentLevelCompletion: currentLevelCompletion,
    topCategories: topCategoryNames,
  );
});

/// Provider for filtered recommendations
final filteredRecommendationsProvider = FutureProvider.autoDispose
    .family<List<SkillRecommendation>, int?>((ref, memberId) async {
  final allRecommendations = await ref.watch(skillRecommendationsProvider(memberId).future);
  final filter = ref.watch(recommendationFilterProvider);
  
  if (filter.isEmpty) {
    return allRecommendations;
  }
  
  return allRecommendations.where((rec) {
    // Filter by level
    if (filter.levels != null && !filter.levels!.contains(rec.skill.level.numericLevel)) {
      return false;
    }
    
    // Filter by reason
    if (filter.reasons != null && !filter.reasons!.contains(rec.reason)) {
      return false;
    }
    
    // Filter by minimum priority
    if (filter.minPriority != null && rec.priority < filter.minPriority!) {
      return false;
    }
    
    // Filter by upcoming trip opportunity
    if (filter.upcomingTripOnly == true && !rec.isUpcomingTripOpportunity) {
      return false;
    }
    
    // Filter by search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      final skillName = rec.skill.name.toLowerCase();
      if (!skillName.contains(query)) {
        return false;
      }
    }
    
    return true;
  }).toList();
});

/// State provider for recommendation filter
final recommendationFilterProvider =
    StateProvider.autoDispose<RecommendationFilter>((ref) {
  return const RecommendationFilter();
});

// ============================================================================
// Helper Functions
// ============================================================================

/// Determine member's current level from user profile (source of truth)
/// Uses official profile level instead of calculating from verified skills
/// This ensures recommendations align with user's official club level
int _determineCurrentLevel(user) {
  // Use user's profile level as source of truth
  final userProfileLevel = user?.level;
  if (userProfileLevel == null) {
    return 1; // Default to level 1 (ANIT/Beginner) if no level set
  }
  
  return userProfileLevel.numericLevel;
}

/// Generate recommendation for a skill
SkillRecommendation? _generateRecommendation(
  LogbookSkill skill,
  List<LogbookSkillReference> verifiedSkills,
  List<LogbookSkill> allSkills,
  int currentLevel,
  List<TripBasicInfo> upcomingTrips,
) {
  // Determine recommendation reason and priority
  RecommendationReason? reason;
  int priority = 1;
  String explanation = '';
  List<String> benefits = [];
  String? nextStepTip;
  bool isUpcomingTripOpportunity = false;
  int? relatedTripCount;
  
  final skillLevel = skill.level.numericLevel;
  
  // Check if skill is for current level
  if (skillLevel == currentLevel) {
    reason = RecommendationReason.nextInProgression;
    priority = 4;
    explanation = 'This is a ${_getLevelName(currentLevel)} skill that fits your current progression path.';
    benefits = [
      'Builds on your existing skills',
      'Natural progression for your level',
      'Commonly verified at this stage',
    ];
    nextStepTip = 'Look for opportunities on upcoming trips to demonstrate this skill.';
  }
  // Check if skill is one level above current
  else if (skillLevel == currentLevel + 1) {
    reason = RecommendationReason.prerequisiteForAdvanced;
    priority = 3;
    explanation = 'Learning this ${_getLevelName(skillLevel)} skill prepares you for advancing to the next level.';
    benefits = [
      'Prepares for next level advancement',
      'Expands your capabilities',
      'Opens up new trip opportunities',
    ];
    nextStepTip = 'Consider this skill after mastering more ${_getLevelName(currentLevel)} skills.';
  }
  // Check if skill is foundation (level 1) and member hasn't completed level 1
  else if (skillLevel == 1 && currentLevel <= 2) {
    reason = RecommendationReason.foundationSkill;
    priority = 5;
    explanation = 'This is a fundamental skill that every off-roader should master.';
    benefits = [
      'Essential foundation skill',
      'Required for safe off-roading',
      'Prerequisite for advanced techniques',
    ];
    nextStepTip = 'This skill can be verified on most beginner-friendly trips.';
  }
  
  // Check if skill is useful for upcoming trips
  final relatedTrips = _findRelatedTrips(skill, upcomingTrips);
  if (relatedTrips.isNotEmpty) {
    isUpcomingTripOpportunity = true;
    relatedTripCount = relatedTrips.length;
    
    // Boost priority if trip opportunity exists
    if (reason != null) {
      priority = (priority + 1).clamp(1, 5);
      benefits.insert(0, 'Useful for $relatedTripCount upcoming trip${relatedTripCount > 1 ? 's' : ''}');
    } else {
      reason = RecommendationReason.upcomingTrip;
      priority = 4;
      explanation = 'You have $relatedTripCount upcoming trip${relatedTripCount > 1 ? 's' : ''} where this skill will be useful.';
      benefits = [
        'Perfect timing for verification',
        'Maximize your trip experience',
        'Learn from real scenarios',
      ];
      nextStepTip = 'Join the trip and ask the marshal to verify this skill.';
    }
  }
  
  // Check if skill is safety-related
  if (_isSafetySkill(skill.name)) {
    if (reason != null) {
      priority = (priority + 1).clamp(1, 5);
      benefits.insert(0, '🛡️ Important for safety');
    } else {
      reason = RecommendationReason.safetyRelated;
      priority = 5;
      explanation = 'This skill is crucial for safe off-roading and self-recovery.';
      benefits = [
        'Essential safety skill',
        'Protects you and your vehicle',
        'Required for remote areas',
      ];
    }
  }
  
  // Only recommend if we have a reason
  if (reason == null) {
    return null;
  }
  
  return SkillRecommendation(
    skill: skill,
    reason: reason,
    priority: priority,
    explanation: explanation,
    benefits: benefits,
    nextStepTip: nextStepTip,
    isUpcomingTripOpportunity: isUpcomingTripOpportunity,
    relatedTripCount: relatedTripCount,
  );
}

/// Find trips where skill is relevant
List<TripBasicInfo> _findRelatedTrips(
  LogbookSkill skill,
  List<TripBasicInfo> upcomingTrips,
) {
  final skillName = skill.name.toLowerCase();
  final skillLevel = skill.level.numericLevel;
  
  return upcomingTrips.where((trip) {
    final tripTitle = trip.title.toLowerCase();
    final tripLevel = trip.level?.numericLevel;
    
    // Skip if trip has no level
    if (tripLevel == null) {
      return false;
    }
    
    // Check if trip level matches skill level (within 1 level)
    if ((tripLevel - skillLevel).abs() > 1) {
      return false;
    }
    
    // Check for skill-type matching in trip title
    if (skillName.contains('dune') || skillName.contains('sand')) {
      return tripTitle.contains('dune') || 
             tripTitle.contains('desert') || 
             tripTitle.contains('sand');
    }
    
    if (skillName.contains('rock') || skillName.contains('boulder')) {
      return tripTitle.contains('rock') || 
             tripTitle.contains('mountain') || 
             tripTitle.contains('wadi');
    }
    
    if (skillName.contains('mud') || skillName.contains('water')) {
      return tripTitle.contains('mud') || 
             tripTitle.contains('water') || 
             tripTitle.contains('wet');
    }
    
    if (skillName.contains('recovery') || skillName.contains('winch')) {
      return true; // Recovery skills are always relevant
    }
    
    // Default: match if levels are close
    return (tripLevel - skillLevel).abs() <= 1;
  }).toList();
}

/// Check if skill is safety-related
bool _isSafetySkill(String skillName) {
  final name = skillName.toLowerCase();
  return name.contains('recovery') ||
      name.contains('safety') ||
      name.contains('first aid') ||
      name.contains('communication') ||
      name.contains('winch') ||
      name.contains('stuck') ||
      name.contains('emergency');
}

/// Get level name from level number
String _getLevelName(int level) {
  switch (level) {
    case 1:
      return 'Beginner';
    case 2:
      return 'Intermediate';
    case 3:
      return 'Advanced';
    case 4:
      return 'Expert';
    case 5:
      return 'Master';
    default:
      return 'Level $level';
  }
}

/// Get skill category from skill name
String _getSkillCategory(String skillName) {
  final name = skillName.toLowerCase();
  
  if (name.contains('dune') || name.contains('sand')) {
    return 'Sand Driving';
  }
  if (name.contains('rock') || name.contains('boulder')) {
    return 'Rock Crawling';
  }
  if (name.contains('mud') || name.contains('water')) {
    return 'Mud & Water';
  }
  if (name.contains('recovery') || name.contains('winch') || name.contains('stuck')) {
    return 'Recovery';
  }
  if (name.contains('navigation') || name.contains('map')) {
    return 'Navigation';
  }
  if (name.contains('vehicle') || name.contains('maintenance')) {
    return 'Vehicle Care';
  }
  
  return 'General Skills';
}
