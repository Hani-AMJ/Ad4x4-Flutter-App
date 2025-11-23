/// Timeline Visualization Models
/// Data structures for logbook entry timeline visualization
library;

import '../../../../data/models/logbook_model.dart';

/// Timeline Entry
/// Represents a single entry in the timeline visualization
class TimelineEntry {
  final LogbookSkillReference verification;
  final TimelineEntryType type;
  final bool isMilestone;
  final String? milestoneText;

  const TimelineEntry({
    required this.verification,
    required this.type,
    this.isMilestone = false,
    this.milestoneText,
  });

  /// Get the date of this timeline entry
  DateTime get date => verification.verifiedAt;

  /// Get skill level
  int get skillLevel => verification.logbookSkill.level.numericLevel;

  /// Get skill level ID (for use with LevelConfigurationService)
  int get skillLevelId => verification.logbookSkill.level.id;

  /// Get color based on skill level
  /// 
  /// **DEPRECATED**: Use `LevelConfigurationService.getLevelColor(skillLevelId)` instead.
  /// This method uses hard-coded level assumptions and won't reflect dynamic level configuration.
  @Deprecated('Use LevelConfigurationService.getLevelColor(skillLevelId) instead')
  String get levelColor {
    switch (skillLevel) {
      case 1:
        return 'green';
      case 2:
        return 'blue';
      case 3:
        return 'orange';
      case 4:
        return 'red';
      case 5:
        return 'purple';
      default:
        return 'grey';
    }
  }
}

/// Timeline Entry Type
enum TimelineEntryType {
  regular,      // Regular skill verification
  firstEver,    // First skill ever verified
  levelUp,      // First skill in a new level
  milestone,    // Special milestone (5th, 10th, 20th skill, etc.)
}

/// Timeline Period
/// Groups timeline entries by time period
class TimelinePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final List<TimelineEntry> entries;
  final TimelinePeriodType type;

  const TimelinePeriod({
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.entries,
    required this.type,
  });

  /// Get total verifications in this period
  int get totalVerifications => entries.length;

  /// Get unique skills verified in this period
  int get uniqueSkills => 
      entries.map((e) => e.verification.logbookSkill.id).toSet().length;

  /// Get verifications by level
  Map<int, int> get verificationsByLevel {
    final counts = <int, int>{};
    for (final entry in entries) {
      final level = entry.skillLevel;
      counts[level] = (counts[level] ?? 0) + 1;
    }
    return counts;
  }

  /// Get most common level in this period
  int? get dominantLevel {
    if (entries.isEmpty) return null;
    final counts = verificationsByLevel;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Timeline Period Type
enum TimelinePeriodType {
  day,
  week,
  month,
  year,
}

/// Timeline Statistics
class TimelineStatistics {
  final int totalEntries;
  final DateTime? firstVerification;
  final DateTime? lastVerification;
  final int daysActive;
  final double averageVerificationsPerMonth;
  final int longestStreak;
  final Map<int, int> verificationsByLevel;
  final Map<String, int> verificationsByMonth; // 'YYYY-MM' -> count
  final List<TimelineMilestone> milestones;

  const TimelineStatistics({
    required this.totalEntries,
    this.firstVerification,
    this.lastVerification,
    required this.daysActive,
    required this.averageVerificationsPerMonth,
    required this.longestStreak,
    required this.verificationsByLevel,
    required this.verificationsByMonth,
    required this.milestones,
  });

  /// Calculate verification frequency (verifications per day)
  double get verificationFrequency {
    if (daysActive == 0) return 0.0;
    return totalEntries / daysActive;
  }

  /// Get most productive month
  String? get mostProductiveMonth {
    if (verificationsByMonth.isEmpty) return null;
    return verificationsByMonth.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get total days since first verification
  int get totalDays {
    if (firstVerification == null || lastVerification == null) return 0;
    return lastVerification!.difference(firstVerification!).inDays + 1;
  }
}

/// Timeline Milestone
/// Special achievement in timeline
class TimelineMilestone {
  final String title;
  final String description;
  final DateTime achievedAt;
  final MilestoneType type;
  final int? relatedSkillLevel;

  const TimelineMilestone({
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.type,
    this.relatedSkillLevel,
  });

  /// Get icon for milestone type
  String get icon {
    switch (type) {
      case MilestoneType.firstSkill:
        return '🎯';
      case MilestoneType.firstLevel:
        return '🏆';
      case MilestoneType.skillCount:
        return '⭐';
      case MilestoneType.levelComplete:
        return '👑';
      case MilestoneType.streak:
        return '🔥';
    }
  }
}

/// Milestone Type
enum MilestoneType {
  firstSkill,     // First skill ever
  firstLevel,     // First skill in a new level
  skillCount,     // Reached 5, 10, 20, 50 skills
  levelComplete,  // Completed all skills in a level
  streak,         // Verification streak milestone
}

/// Timeline View Mode
enum TimelineViewMode {
  chronological,  // Show in date order (newest first)
  byLevel,        // Group by skill level
  byMonth,        // Group by month
  byYear,         // Group by year
}

/// Timeline Filter
class TimelineFilter {
  final int? skillLevel;
  final int? verifierId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? withTrips;
  final String? searchQuery;

  const TimelineFilter({
    this.skillLevel,
    this.verifierId,
    this.startDate,
    this.endDate,
    this.withTrips,
    this.searchQuery,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      skillLevel != null ||
      verifierId != null ||
      startDate != null ||
      endDate != null ||
      withTrips != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Count active filters
  int get activeFilterCount {
    int count = 0;
    if (skillLevel != null) count++;
    if (verifierId != null) count++;
    if (startDate != null || endDate != null) count++;
    if (withTrips != null && withTrips!) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }

  /// Create copy with updated fields
  TimelineFilter copyWith({
    int? skillLevel,
    int? verifierId,
    DateTime? startDate,
    DateTime? endDate,
    bool? withTrips,
    String? searchQuery,
    bool clearLevel = false,
    bool clearVerifier = false,
    bool clearDates = false,
    bool clearTrips = false,
    bool clearSearch = false,
  }) {
    return TimelineFilter(
      skillLevel: clearLevel ? null : (skillLevel ?? this.skillLevel),
      verifierId: clearVerifier ? null : (verifierId ?? this.verifierId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      withTrips: clearTrips ? null : (withTrips ?? this.withTrips),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Clear all filters
  TimelineFilter clear() {
    return const TimelineFilter();
  }
}
