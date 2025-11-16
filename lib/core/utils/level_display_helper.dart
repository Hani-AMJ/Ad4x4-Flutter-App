import 'package:flutter/material.dart';
import '../../data/models/trip_model.dart';

/// Level Display Helper
/// 
/// Centralized utility for displaying member ranks and trip difficulty levels.
/// Provides consistent colors, icons, and badge widgets across the entire app.
/// 
/// **Design Specifications:**
/// - Style: Compact Badge (Option 1)
/// - Color Scheme: Modified Scheme A (Advanced=Red, Marshal=Orange)
/// - Display Text: Always use displayName, fallback to name
/// - Logic: Uses numericLevel as single source of truth
/// 
/// **Database Levels:**
/// - 5: Club Event (Green)
/// - 10: Newbie/ANIT (Green)
/// - 100: Intermediate (Blue)
/// - 200: Advanced (Pink/Red) - SWAPPED
/// - 300: Expert (Purple)
/// - 400: Explorer (Deep Purple)
/// - 600: Marshal (Orange) - SWAPPED
/// - 800: Board member (Dark Gray)
class LevelDisplayHelper {
  /// Get color based on numeric level
  /// 
  /// Uses numericLevel as single source of truth (not ID or name)
  /// Color scheme: Modified Scheme A with swapped Advanced/Marshal colors
  static Color getLevelColor(int numericLevel) {
    if (numericLevel <= 10) {
      return const Color(0xFF4CAF50);  // 🟢 Green - Club Event, Newbie, ANIT
    } else if (numericLevel <= 100) {
      return const Color(0xFF2196F3);  // 🔵 Blue - Intermediate
    } else if (numericLevel <= 200) {
      return const Color(0xFFE91E63);  // 🔴 Pink/Red - Advanced (SWAPPED)
    } else if (numericLevel <= 300) {
      return const Color(0xFF9C27B0);  // 🟣 Purple - Expert
    } else if (numericLevel <= 400) {
      return const Color(0xFF673AB7);  // 🟣 Deep Purple - Explorer
    } else if (numericLevel <= 600) {
      return const Color(0xFFFF9800);  // 🟠 Orange - Marshal (SWAPPED)
    } else {
      return const Color(0xFFE5E4E2);  // 🥈 Platinum - Board member (changed from dark gray)
    }
  }

  /// Get icon based on numeric level
  /// 
  /// Uses numericLevel as single source of truth
  static IconData getLevelIcon(int numericLevel) {
    if (numericLevel <= 5) {
      return Icons.groups;              // 🌍 Community/Club Event
    } else if (numericLevel <= 10) {
      return Icons.school;              // 🎓 Training/Learning
    } else if (numericLevel <= 100) {
      return Icons.terrain;             // 🏔️ Moderate terrain
    } else if (numericLevel <= 200) {
      return Icons.landscape;           // 🏞️ Advanced landscape
    } else if (numericLevel <= 300) {
      return Icons.workspace_premium;   // 💎 Premium/Expert
    } else if (numericLevel <= 400) {
      return Icons.explore;             // 🧭 Exploration
    } else if (numericLevel <= 600) {
      return Icons.shield;              // 🛡️ Marshal/Leadership
    } else {
      return Icons.star;                // ⭐ Board/Elite
    }
  }

  /// Get display text from TripLevel
  /// 
  /// Always uses displayName, fallback to name
  static String getDisplayText(TripLevel level) {
    return level.displayName ?? level.name;
  }

  /// Get display text from string level (for member profiles)
  /// 
  /// Direct string display (used when only level name is available)
  static String getDisplayTextFromString(String levelName) {
    return levelName;
  }

  /// Build compact badge widget (Option 1 - Primary style)
  /// 
  /// Compact badge with light background, colored border, icon, and text
  /// Used in: trip cards, member lists, filters, most UI locations
  static Widget buildCompactBadge(TripLevel level) {
    final color = getLevelColor(level.numericLevel);
    final icon = getLevelIcon(level.numericLevel);
    final text = getDisplayText(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact badge from string level and numeric level
  /// 
  /// Used for member profiles when we have level name and numeric value separately
  static Widget buildCompactBadgeFromString({
    required String levelName,
    required int numericLevel,
  }) {
    final color = getLevelColor(numericLevel);
    final icon = getLevelIcon(numericLevel);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            levelName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build icon only (for minimal displays)
  /// 
  /// Used in very compact views where space is limited
  static Widget buildIconOnly(int numericLevel) {
    final color = getLevelColor(numericLevel);
    final icon = getLevelIcon(numericLevel);
    
    return Icon(icon, size: 18, color: color);
  }

  /// Get trip difficulty label from level index (1-5)
  /// Maps the level1-5 from trip statistics to actual difficulty names
  static String getTripLevelLabel(int levelIndex) {
    switch (levelIndex) {
      case 1:
        return 'Club Event';
      case 2:
        return 'Newbie';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Level $levelIndex';
    }
  }

  /// Get level description text (for tooltips or help text)
  static String getLevelDescription(int numericLevel) {
    if (numericLevel <= 5) {
      return 'Open community events suitable for all members';
    } else if (numericLevel <= 10) {
      return 'Beginner-friendly trips with basic off-road skills';
    } else if (numericLevel <= 100) {
      return 'Moderate difficulty requiring some off-road experience';
    } else if (numericLevel <= 200) {
      return 'Advanced trips requiring solid off-road skills';
    } else if (numericLevel <= 300) {
      return 'Expert-level trips with challenging terrain';
    } else if (numericLevel <= 400) {
      return 'Exploration trips requiring navigation skills';
    } else if (numericLevel <= 600) {
      return 'Trip leader with marshal certification';
    } else {
      return 'Club leadership and board members';
    }
  }
}
