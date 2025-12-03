/// Skill Recommendation Models
/// 
/// Data structures for intelligent skill recommendations
library;

import '../../../../data/models/logbook_model.dart';

/// Represents a recommended skill with reasoning
class SkillRecommendation {
  final LogbookSkill skill;
  final RecommendationReason reason;
  final int priority; // 1-5, where 5 is highest priority
  final String explanation;
  final List<String> benefits;
  final String? nextStepTip;
  final bool isUpcomingTripOpportunity;
  final int? relatedTripCount; // Number of upcoming trips where this skill is useful

  const SkillRecommendation({
    required this.skill,
    required this.reason,
    required this.priority,
    required this.explanation,
    required this.benefits,
    this.nextStepTip,
    this.isUpcomingTripOpportunity = false,
    this.relatedTripCount,
  });

  /// Priority level as text
  String get priorityText {
    switch (priority) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      default:
        return 'Optional';
    }
  }

  /// Priority color
  String get priorityColor {
    switch (priority) {
      case 5:
        return '#E53935'; // Red
      case 4:
        return '#FB8C00'; // Orange
      case 3:
        return '#FDD835'; // Yellow
      case 2:
        return '#43A047'; // Green
      default:
        return '#90A4AE'; // Grey
    }
  }
}

/// Reason why a skill is recommended
enum RecommendationReason {
  nextInProgression, // Natural next step in skill progression
  foundationSkill, // Important foundation skill for current level
  upcomingTrip, // Useful for upcoming trips
  popularWithPeers, // Many peers at same level have this
  completesLevel, // Last skill needed to complete current level
  prerequisiteForAdvanced, // Needed before advancing to next level
  frequentlyUsed, // Commonly verified in trips
  safetyRelated, // Important for safety
}

/// Extension for recommendation reason display
extension RecommendationReasonExtension on RecommendationReason {
  String get displayName {
    switch (this) {
      case RecommendationReason.nextInProgression:
        return 'Next in Progression';
      case RecommendationReason.foundationSkill:
        return 'Foundation Skill';
      case RecommendationReason.upcomingTrip:
        return 'Upcoming Trip';
      case RecommendationReason.popularWithPeers:
        return 'Popular with Peers';
      case RecommendationReason.completesLevel:
        return 'Completes Level';
      case RecommendationReason.prerequisiteForAdvanced:
        return 'Prerequisite';
      case RecommendationReason.frequentlyUsed:
        return 'Frequently Used';
      case RecommendationReason.safetyRelated:
        return 'Safety Related';
    }
  }

  String get icon {
    switch (this) {
      case RecommendationReason.nextInProgression:
        return '🎯';
      case RecommendationReason.foundationSkill:
        return '🏗️';
      case RecommendationReason.upcomingTrip:
        return '🚗';
      case RecommendationReason.popularWithPeers:
        return '👥';
      case RecommendationReason.completesLevel:
        return '✅';
      case RecommendationReason.prerequisiteForAdvanced:
        return '🔑';
      case RecommendationReason.frequentlyUsed:
        return '⭐';
      case RecommendationReason.safetyRelated:
        return '🛡️';
    }
  }

  String get description {
    switch (this) {
      case RecommendationReason.nextInProgression:
        return 'Logical next step based on your current skills';
      case RecommendationReason.foundationSkill:
        return 'Essential foundation for your current level';
      case RecommendationReason.upcomingTrip:
        return 'Will be useful for your upcoming trips';
      case RecommendationReason.popularWithPeers:
        return 'Commonly verified by members at your level';
      case RecommendationReason.completesLevel:
        return 'Last skill needed to complete your current level';
      case RecommendationReason.prerequisiteForAdvanced:
        return 'Required before advancing to next level';
      case RecommendationReason.frequentlyUsed:
        return 'One of the most frequently verified skills';
      case RecommendationReason.safetyRelated:
        return 'Important for safe off-roading';
    }
  }
}

/// Recommendation statistics and insights
class RecommendationStats {
  final int totalRecommendations;
  final int highPriorityCount;
  final int upcomingTripOpportunities;
  final String? nextLevelTarget;
  final int skillsNeededForNextLevel;
  final double currentLevelCompletion; // 0.0 to 1.0
  final List<String> topCategories; // Most recommended categories

  const RecommendationStats({
    required this.totalRecommendations,
    required this.highPriorityCount,
    required this.upcomingTripOpportunities,
    this.nextLevelTarget,
    required this.skillsNeededForNextLevel,
    required this.currentLevelCompletion,
    required this.topCategories,
  });
}

/// Filter for recommendations
class RecommendationFilter {
  final List<int>? levels; // Filter by skill level
  final List<RecommendationReason>? reasons; // Filter by reason
  final int? minPriority; // Minimum priority (1-5)
  final bool? upcomingTripOnly; // Only skills for upcoming trips
  final String? searchQuery; // Search in skill names

  const RecommendationFilter({
    this.levels,
    this.reasons,
    this.minPriority,
    this.upcomingTripOnly,
    this.searchQuery,
  });

  /// Check if filter is empty
  bool get isEmpty =>
      levels == null &&
      reasons == null &&
      minPriority == null &&
      upcomingTripOnly == null &&
      (searchQuery == null || searchQuery!.isEmpty);

  /// Create filter with updated values
  RecommendationFilter copyWith({
    List<int>? levels,
    List<RecommendationReason>? reasons,
    int? minPriority,
    bool? upcomingTripOnly,
    String? searchQuery,
  }) {
    return RecommendationFilter(
      levels: levels ?? this.levels,
      reasons: reasons ?? this.reasons,
      minPriority: minPriority ?? this.minPriority,
      upcomingTripOnly: upcomingTripOnly ?? this.upcomingTripOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clear all filters
  RecommendationFilter clear() {
    return const RecommendationFilter();
  }
}
