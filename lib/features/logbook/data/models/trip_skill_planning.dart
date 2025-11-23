/// Trip Skill Planning Models
/// Data structures for trip-based skill planning feature
library;

import '../../../../data/models/logbook_model.dart';

/// Trip with Skill Opportunities
/// Combines trip information with available skill verification opportunities
class TripWithSkills {
  final TripBasicInfo trip;
  final List<SkillOpportunity> skillOpportunities;
  final int totalSkillsAvailable;
  final int skillsAlreadyVerified;
  final TripDifficultyLevel difficultyLevel;

  const TripWithSkills({
    required this.trip,
    required this.skillOpportunities,
    required this.totalSkillsAvailable,
    required this.skillsAlreadyVerified,
    required this.difficultyLevel,
  });

  /// Calculate percentage of skills already verified for this trip type
  double get verificationProgress {
    if (totalSkillsAvailable == 0) return 0.0;
    return (skillsAlreadyVerified / totalSkillsAvailable) * 100;
  }

  /// Skills remaining to be verified
  int get remainingSkills => totalSkillsAvailable - skillsAlreadyVerified;
}

/// Skill Opportunity
/// Represents a skill that can potentially be verified on a trip
class SkillOpportunity {
  final LogbookSkill skill;
  final bool isVerified;
  final bool meetsPrerequisites;
  final List<String> prerequisites;
  final OpportunityLevel opportunityLevel;
  final String? verificationTips;

  const SkillOpportunity({
    required this.skill,
    required this.isVerified,
    required this.meetsPrerequisites,
    required this.prerequisites,
    required this.opportunityLevel,
    this.verificationTips,
  });

  /// Whether this skill can be attempted on the trip
  bool get canAttempt => !isVerified && meetsPrerequisites;

  /// Whether this skill should be focused on
  bool get isPriority => 
      !isVerified && 
      meetsPrerequisites && 
      opportunityLevel == OpportunityLevel.high;
}

/// Opportunity Level
/// Indicates how likely a skill can be verified on a trip
enum OpportunityLevel {
  high,      // Very likely to have opportunity
  medium,    // Moderate opportunity
  low,       // Possible but unlikely
}

/// Trip Difficulty Level
/// Overall difficulty rating of a trip based on skill requirements
enum TripDifficultyLevel {
  beginner,      // Entry-level skills (first 1-2 skill levels)
  intermediate,  // Mid-level skills (middle skill levels)
  advanced,      // Advanced skills (upper-mid skill levels)
  expert,        // Expert skills (highest skill levels)
}

/// Skill Planning Goal
/// Member's personal goal for skill verification on a trip
class SkillPlanningGoal {
  final int id;
  final int memberId;
  final int tripId;
  final List<int> targetSkillIds;
  final String? notes;
  final DateTime createdAt;
  final bool completed;

  const SkillPlanningGoal({
    required this.id,
    required this.memberId,
    required this.tripId,
    required this.targetSkillIds,
    this.notes,
    required this.createdAt,
    required this.completed,
  });

  factory SkillPlanningGoal.fromJson(Map<String, dynamic> json) {
    return SkillPlanningGoal(
      id: json['id'] as int,
      memberId: json['memberId'] as int,
      tripId: json['tripId'] as int,
      targetSkillIds: (json['targetSkillIds'] as List<dynamic>)
          .map((id) => id as int)
          .toList(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'tripId': tripId,
      'targetSkillIds': targetSkillIds,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed,
    };
  }
}

/// Trip Skill Planning Statistics
class TripSkillPlanningStats {
  final int totalUpcomingTrips;
  final int totalSkillOpportunities;
  final int plannedSkills;
  final int completedFromPlanned;
  final Map<TripDifficultyLevel, int> tripsByDifficulty;
  final Map<int, int> opportunitiesByLevel; // skill level -> count

  const TripSkillPlanningStats({
    required this.totalUpcomingTrips,
    required this.totalSkillOpportunities,
    required this.plannedSkills,
    required this.completedFromPlanned,
    required this.tripsByDifficulty,
    required this.opportunitiesByLevel,
  });

  /// Planning success rate
  double get planningSuccessRate {
    if (plannedSkills == 0) return 0.0;
    return (completedFromPlanned / plannedSkills) * 100;
  }
}
