import 'package:flutter/material.dart';

/// Level Data Model
/// 
/// Centralized level information with exact icons and colors
class LevelData {
  final int id;
  final int numericLevel;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const LevelData({
    required this.id,
    required this.numericLevel,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Level Constants
/// 
/// Centralized level data with exact icons and colors matching trip filter
class LevelConstants {
  // Prevent instantiation
  LevelConstants._();

  /// All levels with exact icons and colors
  static const List<LevelData> allLevels = [
    LevelData(
      id: 1,
      numericLevel: 1,
      name: 'Club Event',
      icon: Icons.event,
      color: Color(0xFF8E44AD), // Purple
      description: 'Open club events for all members',
    ),
    LevelData(
      id: 2,
      numericLevel: 2,
      name: 'ANIT',
      icon: Icons.school,
      color: Color(0xFF27AE60), // Dark Green
      description: 'All-New-In-Training level',
    ),
    LevelData(
      id: 3,
      numericLevel: 3,
      name: 'Newbie',
      icon: Icons.school,
      color: Color(0xFF2ECC71), // Light Green
      description: 'Beginner-friendly trips',
    ),
    LevelData(
      id: 4,
      numericLevel: 4,
      name: 'Intermediate',
      icon: Icons.trending_up,
      color: Color(0xFF3498DB), // Blue
      description: 'Moderate difficulty trips',
    ),
    LevelData(
      id: 5,
      numericLevel: 5,
      name: 'Advanced',
      icon: Icons.speed,
      color: Color(0xFFE67E22), // Orange
      description: 'Challenging trips for experienced members',
    ),
    LevelData(
      id: 6,
      numericLevel: 6,
      name: 'Expert',
      icon: Icons.star,
      color: Color(0xFFF39C12), // Golden Yellow
      description: 'Expert-level expeditions',
    ),
    LevelData(
      id: 7,
      numericLevel: 7,
      name: 'Explorer',
      icon: Icons.explore,
      color: Color(0xFFE74C3C), // Red
      description: 'Extreme exploration trips',
    ),
    LevelData(
      id: 8,
      numericLevel: 8,
      name: 'Marshal',
      icon: Icons.shield,
      color: Color(0xFFF39C12), // Golden Yellow
      description: 'Marshal-led special trips',
    ),
    LevelData(
      id: 9,
      numericLevel: 9,
      name: 'Board Member',
      icon: Icons.workspace_premium,
      color: Color(0xFF34495E), // Dark Blue
      description: 'Board member exclusive trips',
    ),
  ];

  /// Get level data by numeric level
  static LevelData? getByNumericLevel(int numericLevel) {
    try {
      return allLevels.firstWhere((level) => level.numericLevel == numericLevel);
    } catch (e) {
      return null;
    }
  }

  /// Get level data by ID
  static LevelData? getById(int id) {
    try {
      return allLevels.firstWhere((level) => level.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get level data by name (case-insensitive)
  static LevelData? getByName(String name) {
    try {
      return allLevels.firstWhere(
        (level) => level.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get icon and color for level (helper method)
  static ({IconData icon, Color color}) getIconAndColor(int? numericLevel, String? levelName) {
    // Try by numeric level first
    if (numericLevel != null) {
      final levelData = getByNumericLevel(numericLevel);
      if (levelData != null) {
        return (icon: levelData.icon, color: levelData.color);
      }
    }

    // Fallback to name-based matching
    if (levelName != null) {
      final levelData = getByName(levelName);
      if (levelData != null) {
        return (icon: levelData.icon, color: levelData.color);
      }

      // Partial name matching for backward compatibility
      final nameLower = levelName.toLowerCase();
      if (nameLower.contains('club event')) {
        return (icon: Icons.event, color: const Color(0xFF8E44AD));
      } else if (nameLower.contains('anit')) {
        return (icon: Icons.school, color: const Color(0xFF27AE60));
      } else if (nameLower.contains('newbie')) {
        return (icon: Icons.school, color: const Color(0xFF2ECC71));
      } else if (nameLower.contains('intermediate')) {
        return (icon: Icons.trending_up, color: const Color(0xFF3498DB));
      } else if (nameLower.contains('advanc')) {
        return (icon: Icons.speed, color: const Color(0xFFE67E22));
      } else if (nameLower.contains('expert')) {
        return (icon: Icons.star, color: const Color(0xFFF39C12));
      } else if (nameLower.contains('explorer')) {
        return (icon: Icons.explore, color: const Color(0xFFE74C3C));
      } else if (nameLower.contains('marshal')) {
        return (icon: Icons.shield, color: const Color(0xFFF39C12));
      } else if (nameLower.contains('board')) {
        return (icon: Icons.workspace_premium, color: const Color(0xFF34495E));
      }
    }

    // Default fallback
    return (icon: Icons.terrain, color: const Color(0xFF64B5F6));
  }
}
