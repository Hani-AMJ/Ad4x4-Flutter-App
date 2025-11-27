import 'package:flutter/material.dart';

/// Meeting Point Constants
/// 
/// Shared constants for meeting point areas, including:
/// - Area codes and display names
/// - Area colors for UI consistency
/// - Sorting and filtering utilities
class MeetingPointConstants {
  // Prevent instantiation
  MeetingPointConstants._();

  /// Area code definitions with display names
  static const Map<String, String> areaNames = {
    'DXB': 'Dubai',
    'NOR': 'Northern Emirates',
    'AUH': 'Abu Dhabi',
    'AAN': 'Al Ain',
    'LIW': 'Liwa',
  };

  /// Area codes for dropdown/filter (includes "All Areas" option)
  static const Map<String?, String> areaOptions = {
    null: 'All Areas',
    'DXB': 'Dubai',
    'NOR': 'Northern Emirates',
    'AUH': 'Abu Dhabi',
    'AAN': 'Al Ain',
    'LIW': 'Liwa',
  };

  /// Get display name for area code
  /// Returns the full name if code is valid, otherwise returns the code itself
  static String getAreaName(String? areaCode) {
    if (areaCode == null || areaCode.isEmpty) return 'Unknown';
    return areaNames[areaCode] ?? areaCode;
  }

  /// Get color for area code
  /// Returns a unique color for each area for visual distinction
  static Color getAreaColor(String? areaCode) {
    switch (areaCode) {
      case 'DXB':
        return const Color(0xFF2196F3); // Blue - Dubai
      case 'NOR':
        return const Color(0xFF4CAF50); // Green - Northern Emirates
      case 'AUH':
        return const Color(0xFFFF9800); // Orange - Abu Dhabi
      case 'AAN':
        return const Color(0xFF9C27B0); // Purple - Al Ain
      case 'LIW':
        return const Color(0xFFF44336); // Red - Liwa
      default:
        return Colors.grey; // Default color for unknown areas
    }
  }

  /// Check if area code is valid
  static bool isValidAreaCode(String? areaCode) {
    if (areaCode == null) return false;
    return areaNames.containsKey(areaCode);
  }

  /// Get all area codes (without null option)
  static List<String> get allAreaCodes => areaNames.keys.toList();

  /// Get all area options for filters (includes null/"All Areas")
  static List<MapEntry<String?, String>> get allAreaOptions => 
      areaOptions.entries.toList();
}

/// Meeting Point Utilities
/// 
/// Utility functions for sorting and filtering meeting points
class MeetingPointUtils {
  // Prevent instantiation
  MeetingPointUtils._();

  /// Compare function for sorting meeting points by area then name
  /// 
  /// Sorts meeting points by:
  /// 1. Area code (alphabetically)
  /// 2. Name (alphabetically)
  /// 
  /// Null/empty areas are sorted last
  static int compareByAreaThenName(
    dynamic a,
    dynamic b, {
    String? Function(dynamic)? getArea,
    String Function(dynamic)? getName,
  }) {
    // Extract area values
    final aArea = getArea?.call(a) ?? (a as dynamic).area as String?;
    final bArea = getArea?.call(b) ?? (b as dynamic).area as String?;

    // Compare areas (null/empty goes last)
    final areaCompare = (aArea ?? '').compareTo(bArea ?? '');
    if (areaCompare != 0) return areaCompare;

    // If areas are equal, compare names
    final aName = getName?.call(a) ?? (a as dynamic).name as String;
    final bName = getName?.call(b) ?? (b as dynamic).name as String;
    return aName.compareTo(bName);
  }
}
