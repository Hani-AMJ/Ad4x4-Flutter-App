import '../../../../data/models/logbook_model.dart';

/// Comprehensive logbook progress statistics
/// Updated to use profile level as source of truth
class LogbookProgressStats {
  // Current level from user profile (source of truth)
  final String currentLevelName;  // e.g., "Advanced", "Intermediate"
  final int currentLevelNumeric;  // e.g., 200 for Advanced
  final int currentLevelId;  // Level ID in database
  
  // Skills for current level only
  final int totalSkillsForCurrentLevel;
  final int verifiedSkillsForCurrentLevel;
  
  // All skills across all levels (for skills matrix)
  final int totalSkillsAllLevels;
  final int verifiedSkillsAllLevels;
  
  // Trip statistics
  final int totalTrips;
  final int checkedInTrips;
  
  // Recent activity
  final List<LogbookEntry> recentEntries;
  
  // Breakdown for all levels (for skills matrix display)
  final Map<int, LevelProgressData> allLevelsBreakdown;

  LogbookProgressStats({
    required this.currentLevelName,
    required this.currentLevelNumeric,
    required this.currentLevelId,
    required this.totalSkillsForCurrentLevel,
    required this.verifiedSkillsForCurrentLevel,
    required this.totalSkillsAllLevels,
    required this.verifiedSkillsAllLevels,
    required this.totalTrips,
    required this.checkedInTrips,
    required this.recentEntries,
    required this.allLevelsBreakdown,
  });

  /// Progress percentage for current level only (0-100)
  double get currentLevelProgressPercentage {
    if (totalSkillsForCurrentLevel == 0) return 0.0;
    return (verifiedSkillsForCurrentLevel / totalSkillsForCurrentLevel * 100).clamp(0.0, 100.0);
  }
  
  /// Overall progress across all levels (for reference)
  double get overallProgressPercentage {
    if (totalSkillsAllLevels == 0) return 0.0;
    return (verifiedSkillsAllLevels / totalSkillsAllLevels * 100).clamp(0.0, 100.0);
  }

  /// Get level progress data for specific level
  LevelProgressData? getLevelProgress(int levelId) {
    return allLevelsBreakdown[levelId];
  }
  
  /// Get current level progress data
  LevelProgressData? get currentLevelProgress {
    return allLevelsBreakdown[currentLevelId];
  }
  
  /// Check if current level has any verified skills
  bool get hasVerifiedSkills {
    return verifiedSkillsForCurrentLevel > 0;
  }
  
  /// Remaining skills for current level
  int get remainingSkillsForCurrentLevel {
    return (totalSkillsForCurrentLevel - verifiedSkillsForCurrentLevel).clamp(0, totalSkillsForCurrentLevel);
  }

  // ============================================================
  // COMPATIBILITY PROPERTIES FOR OLD WIDGET API
  // ============================================================
  
  /// Legacy property: officialLevel
  /// Maps to current profile level (source of truth)
  ({int id, String name})? get officialLevel {
    return (id: currentLevelId, name: currentLevelName);
  }
  
  /// Legacy property: workingLevel
  /// Maps to current level progress data
  ({
    int levelId,
    String levelName,
    int skillsVerified,
    int totalSkills,
    int skillsRemaining,
    double progress,
  })? get workingLevel {
    final current = currentLevelProgress;
    if (current == null) return null;
    
    return (
      levelId: current.levelId,
      levelName: current.levelName,
      skillsVerified: current.verifiedSkills,
      totalSkills: current.totalSkills,
      skillsRemaining: current.remainingSkills,
      progress: current.progressPercentage / 100.0,
    );
  }
  
  /// Legacy property: nextLevel
  /// Calculates next level from allLevelsBreakdown
  ({
    int levelId,
    String levelName,
    int totalSkills,
  })? get nextLevel {
    // Sort levels by numeric ID and find the next one after current
    final sortedLevels = allLevelsBreakdown.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final currentIndex = sortedLevels.indexWhere((e) => e.key == currentLevelId);
    if (currentIndex == -1 || currentIndex >= sortedLevels.length - 1) {
      return null; // No next level
    }
    
    final next = sortedLevels[currentIndex + 1].value;
    return (
      levelId: next.levelId,
      levelName: next.levelName,
      totalSkills: next.totalSkills,
    );
  }
  
  /// Legacy property: totalSkillsVerified
  /// Maps to verifiedSkillsAllLevels
  int get totalSkillsVerified => verifiedSkillsAllLevels;
  
  /// Legacy property: totalSkillsAvailable
  /// Maps to totalSkillsAllLevels
  int get totalSkillsAvailable => totalSkillsAllLevels;
  
  /// Legacy property: overallProgress
  /// Maps to overallProgressPercentage as 0-1 fraction
  double get overallProgress => overallProgressPercentage / 100.0;
}

/// Progress data for a specific skill level
class LevelProgressData {
  final int levelId;
  final String levelName;
  final int totalSkills;
  final int verifiedSkills;
  final List<LogbookSkill> skills;

  LevelProgressData({
    required this.levelId,
    required this.levelName,
    required this.totalSkills,
    required this.verifiedSkills,
    required this.skills,
  });

  /// Progress percentage for this level (0-100)
  double get progressPercentage {
    if (totalSkills == 0) return 0.0;
    return (verifiedSkills / totalSkills * 100).clamp(0.0, 100.0);
  }

  /// Number of skills remaining to verify
  int get remainingSkills => (totalSkills - verifiedSkills).clamp(0, totalSkills);

  /// Check if level is completed (70% threshold)
  bool get isCompleted {
    final threshold = (totalSkills * 0.7).ceil();
    return verifiedSkills >= threshold;
  }

  /// DEPRECATED: Get level color based on level ID
  /// Use LevelConfigurationService.getLevelColor() instead for dynamic levels
  @deprecated
  String get levelColor {
    switch (levelId) {
      case 1:
        return '#4CAF50'; // Green
      case 2:
        return '#2196F3'; // Blue
      case 3:
        return '#FF9800'; // Orange
      case 4:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// DEPRECATED: Get level emoji
  /// Use LevelConfigurationService.getLevelEmoji() instead for dynamic levels
  @deprecated
  String get levelEmoji {
    switch (levelId) {
      case 1:
        return '🟢';
      case 2:
        return '🔵';
      case 3:
        return '🟠';
      case 4:
        return '🔴';
      default:
        return '⚪';
    }
  }
}

/// Requirements for progressing to next level
/// Kept for backward compatibility but no longer actively used
/// Profile level is source of truth, not calculated progression
class NextLevelRequirements {
  final int currentLevel;
  final int nextLevel;
  final int requiredSkills;
  final int currentSkills;
  final int remainingSkills;
  final String levelName;

  NextLevelRequirements({
    required this.currentLevel,
    required this.nextLevel,
    required this.requiredSkills,
    required this.currentSkills,
    required this.remainingSkills,
    required this.levelName,
  });

  /// Progress percentage towards next level (0-100)
  double get progressPercentage {
    if (requiredSkills == 0) return 100.0;
    return (currentSkills / requiredSkills * 100).clamp(0.0, 100.0);
  }

  /// Check if requirements are met
  bool get requirementsMet => remainingSkills == 0;

  /// Get motivational message
  String get motivationalMessage {
    if (requirementsMet) {
      return 'You\'re ready for $levelName! 🎉';
    } else if (remainingSkills == 1) {
      return 'Just 1 more skill needed! 💪';
    } else if (progressPercentage >= 50) {
      return 'Halfway there! Keep going! 🚀';
    } else {
      return '$remainingSkills skills to $levelName';
    }
  }
}
