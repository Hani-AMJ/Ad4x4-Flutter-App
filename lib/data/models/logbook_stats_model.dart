/// Logbook statistics model for dashboard display
/// 
/// Aggregates member's logbook progress across all skill levels
class LogbookStats {
  final int totalSkills;
  final int verifiedSkills;
  final int pendingSkills;
  final int rejectedSkills;
  final double progressPercentage;
  
  // Level-specific stats
  final LevelStats beginnerStats;
  final LevelStats intermediateStats;
  final LevelStats advancedStats;
  final LevelStats expertStats;
  
  // Counts
  final int totalEntries;
  final int totalTrips;
  final int recentActivityCount;

  const LogbookStats({
    required this.totalSkills,
    required this.verifiedSkills,
    required this.pendingSkills,
    required this.rejectedSkills,
    required this.progressPercentage,
    required this.beginnerStats,
    required this.intermediateStats,
    required this.advancedStats,
    required this.expertStats,
    required this.totalEntries,
    required this.totalTrips,
    required this.recentActivityCount,
  });

  factory LogbookStats.fromJson(Map<String, dynamic> json) {
    return LogbookStats(
      totalSkills: json['total_skills'] ?? 0,
      verifiedSkills: json['verified_skills'] ?? 0,
      pendingSkills: json['pending_skills'] ?? 0,
      rejectedSkills: json['rejected_skills'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      beginnerStats: LevelStats.fromJson(json['beginner_stats'] ?? {}),
      intermediateStats: LevelStats.fromJson(json['intermediate_stats'] ?? {}),
      advancedStats: LevelStats.fromJson(json['advanced_stats'] ?? {}),
      expertStats: LevelStats.fromJson(json['expert_stats'] ?? {}),
      totalEntries: json['total_entries'] ?? 0,
      totalTrips: json['total_trips'] ?? 0,
      recentActivityCount: json['recent_activity_count'] ?? 0,
    );
  }

  /// Create empty stats (for initial state or errors)
  factory LogbookStats.empty() {
    return LogbookStats(
      totalSkills: 0,
      verifiedSkills: 0,
      pendingSkills: 0,
      rejectedSkills: 0,
      progressPercentage: 0.0,
      beginnerStats: LevelStats.empty(),
      intermediateStats: LevelStats.empty(),
      advancedStats: LevelStats.empty(),
      expertStats: LevelStats.empty(),
      totalEntries: 0,
      totalTrips: 0,
      recentActivityCount: 0,
    );
  }
}

/// Statistics for a specific skill level
class LevelStats {
  final String levelName;
  final int totalSkills;
  final int verifiedSkills;
  final double progressPercentage;

  const LevelStats({
    required this.levelName,
    required this.totalSkills,
    required this.verifiedSkills,
    required this.progressPercentage,
  });

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    final verified = json['verified'] ?? 0;
    final total = json['total'] ?? 0;
    final percentage = total > 0 ? (verified / total * 100) : 0.0;
    
    return LevelStats(
      levelName: json['level_name'] ?? '',
      totalSkills: total,
      verifiedSkills: verified,
      progressPercentage: percentage,
    );
  }

  factory LevelStats.empty() {
    return const LevelStats(
      levelName: '',
      totalSkills: 0,
      verifiedSkills: 0,
      progressPercentage: 0.0,
    );
  }
}
