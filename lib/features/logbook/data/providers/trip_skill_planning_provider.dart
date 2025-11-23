import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../models/trip_skill_planning.dart';
import 'skill_planning_goals_provider.dart';

/// Provider for upcoming trips with skill opportunities
/// Fetches upcoming trips and calculates which skills can be verified
final upcomingTripsWithSkillsProvider = FutureProvider.autoDispose<List<TripWithSkills>>((ref) async {
  final authState = ref.watch(authProviderV2);
  final user = authState.user;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(mainApiRepositoryProvider);

  // Fetch upcoming trips (next 30 days)
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
  final trips = tripsData
      .map((json) => TripBasicInfo.fromJson(json as Map<String, dynamic>))
      .toList();

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
  final memberSkillsResponse = await repository.getMemberLogbookSkills(
    memberId: user.id,
    page: 1,
    pageSize: 100,
  );

  final memberSkillsData = memberSkillsResponse['results'] as List<dynamic>;
  final verifiedSkillIds = memberSkillsData
      .map((json) => json['skill']['id'] as int)
      .toSet();

  // Build TripWithSkills for each trip
  final tripsWithSkills = <TripWithSkills>[];

  for (final trip in trips) {
    // Determine trip difficulty based on trip metadata or defaults
    final difficultyLevel = _calculateTripDifficulty(trip);

    // Get skills appropriate for this trip
    final skillOpportunities = _getSkillOpportunitiesForTrip(
      trip,
      allSkills,
      verifiedSkillIds,
      difficultyLevel,
    );

    final totalSkills = skillOpportunities.length;
    final verifiedCount = skillOpportunities.where((s) => s.isVerified).length;

    tripsWithSkills.add(TripWithSkills(
      trip: trip,
      skillOpportunities: skillOpportunities,
      totalSkillsAvailable: totalSkills,
      skillsAlreadyVerified: verifiedCount,
      difficultyLevel: difficultyLevel,
    ));
  }

  // Sort by trip date
  tripsWithSkills.sort((a, b) => a.trip.startTime.compareTo(b.trip.startTime));

  return tripsWithSkills;
});

/// Calculate trip difficulty level
TripDifficultyLevel _calculateTripDifficulty(TripBasicInfo trip) {
  // Check trip title for difficulty indicators
  final title = trip.title.toLowerCase();
  
  if (title.contains('beginner') || title.contains('easy') || title.contains('training')) {
    return TripDifficultyLevel.beginner;
  } else if (title.contains('expert') || title.contains('extreme') || title.contains('challenge')) {
    return TripDifficultyLevel.expert;
  } else if (title.contains('advanced') || title.contains('difficult')) {
    return TripDifficultyLevel.advanced;
  } else if (title.contains('intermediate') || title.contains('moderate')) {
    return TripDifficultyLevel.intermediate;
  }

  // Check required level if available
  final tripLevel = trip.level;
  if (tripLevel != null) {
    final levelId = tripLevel.id;
    if (levelId <= 2) return TripDifficultyLevel.beginner;
    if (levelId == 3) return TripDifficultyLevel.intermediate;
    if (levelId == 4) return TripDifficultyLevel.advanced;
    return TripDifficultyLevel.expert;
  }

  // Default to intermediate
  return TripDifficultyLevel.intermediate;
}

/// Get skill opportunities for a specific trip
List<SkillOpportunity> _getSkillOpportunitiesForTrip(
  TripBasicInfo trip,
  List<LogbookSkill> allSkills,
  Set<int> verifiedSkillIds,
  TripDifficultyLevel tripDifficulty,
) {
  final opportunities = <SkillOpportunity>[];

  // Determine which skill levels are appropriate for this trip
  final appropriateLevels = _getAppropriateLevelsForTrip(tripDifficulty);

  for (final skill in allSkills) {
    // Skip if skill level doesn't match trip difficulty
    if (!appropriateLevels.contains(skill.level.numericLevel)) {
      continue;
    }

    final isVerified = verifiedSkillIds.contains(skill.id);

    // Determine opportunity level based on skill and trip characteristics
    final opportunityLevel = _calculateOpportunityLevel(skill, trip);

    // Check prerequisites (simplified - assumes lower level skills are prerequisites)
    final meetsPrerequisites = _checkPrerequisites(skill, verifiedSkillIds);
    final prerequisites = _getPrerequisitesList(skill);

    // Generate verification tips
    final tips = _generateVerificationTips(skill, trip);

    opportunities.add(SkillOpportunity(
      skill: skill,
      isVerified: isVerified,
      meetsPrerequisites: meetsPrerequisites,
      prerequisites: prerequisites,
      opportunityLevel: opportunityLevel,
      verificationTips: tips,
    ));
  }

  // Sort by priority (unverified + meets prerequisites + high opportunity first)
  opportunities.sort((a, b) {
    if (a.isPriority && !b.isPriority) return -1;
    if (!a.isPriority && b.isPriority) return 1;
    if (a.canAttempt && !b.canAttempt) return -1;
    if (!a.canAttempt && b.canAttempt) return 1;
    return a.skill.level.numericLevel.compareTo(b.skill.level.numericLevel);
  });

  return opportunities;
}

/// Get appropriate skill levels for trip difficulty
List<int> _getAppropriateLevelsForTrip(TripDifficultyLevel difficulty) {
  switch (difficulty) {
    case TripDifficultyLevel.beginner:
      return [1, 2];
    case TripDifficultyLevel.intermediate:
      return [2, 3];
    case TripDifficultyLevel.advanced:
      return [3, 4];
    case TripDifficultyLevel.expert:
      return [4, 5];
  }
}

/// Calculate opportunity level for a skill on a trip
OpportunityLevel _calculateOpportunityLevel(LogbookSkill skill, TripBasicInfo trip) {
  final skillName = skill.name.toLowerCase();
  final tripTitle = trip.title.toLowerCase();

  // High opportunity if skill type matches trip type
  if ((skillName.contains('dune') || skillName.contains('sand')) && 
      (tripTitle.contains('dune') || tripTitle.contains('desert') || tripTitle.contains('sand'))) {
    return OpportunityLevel.high;
  }

  if ((skillName.contains('rock') || skillName.contains('boulder')) && 
      (tripTitle.contains('rock') || tripTitle.contains('mountain') || tripTitle.contains('wadi'))) {
    return OpportunityLevel.high;
  }

  if ((skillName.contains('water') || skillName.contains('crossing')) && 
      (tripTitle.contains('water') || tripTitle.contains('wadi') || tripTitle.contains('river'))) {
    return OpportunityLevel.high;
  }

  if ((skillName.contains('recovery') || skillName.contains('winch')) && 
      (tripTitle.contains('challenge') || tripTitle.contains('difficult') || tripTitle.contains('extreme'))) {
    return OpportunityLevel.high;
  }

  // Medium opportunity for general skills
  if (skillName.contains('navigation') || skillName.contains('communication') || 
      skillName.contains('safety') || skillName.contains('convoy')) {
    return OpportunityLevel.medium;
  }

  // Default to low
  return OpportunityLevel.low;
}

/// Check if member meets skill prerequisites
bool _checkPrerequisites(LogbookSkill skill, Set<int> verifiedSkillIds) {
  // Simplified logic: Level 1 has no prerequisites
  if (skill.level.numericLevel == 1) return true;

  // For higher levels, check if member has verified skills at lower levels
  // In a real implementation, this would check specific prerequisite skills
  // For now, we assume prerequisites are met if member has any verified skills
  return verifiedSkillIds.isNotEmpty || skill.level.numericLevel == 1;
}

/// Get list of prerequisite skill names
List<String> _getPrerequisitesList(LogbookSkill skill) {
  if (skill.level.numericLevel == 1) {
    return [];
  }

  // Simplified: Return generic prerequisites based on level
  switch (skill.level.numericLevel) {
    case 2:
      return ['Complete at least 2 Level 1 skills'];
    case 3:
      return ['Complete at least 3 Level 2 skills'];
    case 4:
      return ['Complete at least 3 Level 3 skills'];
    case 5:
      return ['Complete all Level 4 skills'];
    default:
      return [];
  }
}

/// Generate verification tips for a skill
String? _generateVerificationTips(LogbookSkill skill, TripBasicInfo trip) {
  final skillName = skill.name.toLowerCase();

  if (skillName.contains('navigation')) {
    return 'Practice using GPS and maps during the trip. Ask marshal to verify your route planning.';
  }
  if (skillName.contains('recovery')) {
    return 'Be prepared to assist in vehicle recovery situations. Demonstrate proper recovery techniques.';
  }
  if (skillName.contains('communication')) {
    return 'Maintain clear radio communication throughout the trip. Practice proper convoy protocols.';
  }
  if (skillName.contains('convoy')) {
    return 'Follow convoy procedures, maintain proper spacing, and assist other members as needed.';
  }
  if (skillName.contains('dune')) {
    return 'Practice proper dune driving techniques. Let air out of tires and follow marshal instructions.';
  }

  return 'Discuss with trip marshal about demonstrating this skill during the trip.';
}

/// Provider for trip skill planning statistics
final tripSkillPlanningStatsProvider = FutureProvider.autoDispose.family<TripSkillPlanningStats, int>(
  (ref, memberId) async {
    final tripsWithSkills = await ref.watch(upcomingTripsWithSkillsProvider.future);

    final totalTrips = tripsWithSkills.length;
    final totalOpportunities = tripsWithSkills.fold<int>(
      0, 
      (sum, trip) => sum + trip.skillOpportunities.where((s) => !s.isVerified).length,
    );

    // Count trips by difficulty
    final tripsByDifficulty = <TripDifficultyLevel, int>{};
    for (final trip in tripsWithSkills) {
      tripsByDifficulty[trip.difficultyLevel] = 
          (tripsByDifficulty[trip.difficultyLevel] ?? 0) + 1;
    }

    // Count opportunities by skill level
    final opportunitiesByLevel = <int, int>{};
    for (final trip in tripsWithSkills) {
      for (final opp in trip.skillOpportunities.where((s) => !s.isVerified)) {
        final level = opp.skill.level.numericLevel;
        opportunitiesByLevel[level] = (opportunitiesByLevel[level] ?? 0) + 1;
      }
    }

    // Get goals data from goals provider (import required)
    final goals = ref.watch(skillPlanningGoalsProvider(memberId));
    final activeGoals = goals.where((g) => !g.completed).toList();
    final completedGoals = goals.where((g) => g.completed).toList();
    
    // Calculate planned skills (total from all active goals)
    final plannedSkills = activeGoals.fold<int>(
      0,
      (sum, goal) => sum + goal.targetSkillIds.length,
    );
    
    // Calculate completed from planned (skills from completed goals)
    final completedFromPlanned = completedGoals.fold<int>(
      0,
      (sum, goal) => sum + goal.targetSkillIds.length,
    );

    return TripSkillPlanningStats(
      totalUpcomingTrips: totalTrips,
      totalSkillOpportunities: totalOpportunities,
      plannedSkills: plannedSkills,
      completedFromPlanned: completedFromPlanned,
      tripsByDifficulty: tripsByDifficulty,
      opportunitiesByLevel: opportunitiesByLevel,
    );
  },
);

/// Provider for a specific trip's skill opportunities
final tripSkillOpportunitiesProvider = FutureProvider.autoDispose
    .family<TripWithSkills?, int>((ref, tripId) async {
  final tripsWithSkills = await ref.watch(upcomingTripsWithSkillsProvider.future);
  
  try {
    return tripsWithSkills.firstWhere((trip) => trip.trip.id == tripId);
  } catch (e) {
    return null;
  }
});
