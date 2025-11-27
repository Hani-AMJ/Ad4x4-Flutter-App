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

  /// Smart area code detection from HERE Maps city name
  /// 
  /// Detects the appropriate area code based on city name from HERE Maps.
  /// Uses multiple strategies for robust detection:
  /// 1. Exact city name match (case-insensitive)
  /// 2. Partial city name match (contains check)
  /// 3. District name fallback for Al Ain/Liwa
  /// 
  /// Parameters:
  /// - [city]: City name from HERE Maps (e.g., "Dubai", "Abu Dhabi")
  /// - [district]: District name for additional context (optional)
  /// 
  /// Returns:
  /// - Area code (DXB, AUH, NOR, AAN, LIW) if detected
  /// - null if location cannot be mapped to known areas
  /// 
  /// Examples:
  /// ```dart
  /// detectAreaCode('Dubai', 'Business Bay')    // Returns: 'DXB'
  /// detectAreaCode('Abu Dhabi', 'Al Karamah') // Returns: 'AUH'
  /// detectAreaCode('Sharjah', 'Al Majaz')     // Returns: 'NOR'
  /// detectAreaCode('Al Ain', 'Al Jimi')       // Returns: 'AAN'
  /// detectAreaCode('Muscat', '')              // Returns: null (not UAE)
  /// ```
  static String? detectAreaCode(String city, [String? district]) {
    final cityLower = city.toLowerCase().trim();
    final districtLower = (district ?? '').toLowerCase().trim();

    // Strategy 1: Exact and partial city name matching
    final cityMapping = {
      'dubai': 'DXB',
      'abu dhabi': 'AUH',
      'abudhabi': 'AUH',
      'sharjah': 'NOR',
      'ajman': 'NOR',
      'ras al khaimah': 'NOR',
      'ras al-khaimah': 'NOR',
      'fujairah': 'NOR',
      'umm al quwain': 'NOR',
      'umm al-quwain': 'NOR',
      'al ain': 'AAN',
      'liwa': 'LIW',
    };

    // Check for exact matches first
    for (var entry in cityMapping.entries) {
      if (cityLower == entry.key || cityLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Strategy 2: District-based detection for ambiguous cases
    if (districtLower.isNotEmpty) {
      // Al Ain specific districts
      if (districtLower.contains('al ain') || 
          districtLower.contains('al jimi') ||
          districtLower.contains('tawam')) {
        return 'AAN';
      }

      // Liwa specific districts
      if (districtLower.contains('liwa') || 
          districtLower.contains('madinat zayed')) {
        return 'LIW';
      }

      // Northern Emirates districts (if city detection failed)
      if (districtLower.contains('sharjah') ||
          districtLower.contains('ajman') ||
          districtLower.contains('fujairah') ||
          districtLower.contains('rak') ||
          districtLower.contains('umm')) {
        return 'NOR';
      }
    }

    // Strategy 3: Fallback - check if any area name appears in the full string
    final fullText = '$cityLower $districtLower';
    for (var entry in cityMapping.entries) {
      if (fullText.contains(entry.key)) {
        return entry.value;
      }
    }

    // No match found
    return null;
  }

  /// Validate detected area code and provide confidence level
  /// 
  /// Returns a map with detection result and confidence:
  /// - 'code': Detected area code or null
  /// - 'confidence': 'high', 'medium', or 'low'
  /// - 'reason': Human-readable explanation
  /// 
  /// Example:
  /// ```dart
  /// final result = validateAreaCodeDetection('Dubai', 'Business Bay');
  /// // Returns: {
  /// //   'code': 'DXB',
  /// //   'confidence': 'high',
  /// //   'reason': 'Exact city name match'
  /// // }
  /// ```
  static Map<String, String?> validateAreaCodeDetection(
    String city, [
    String? district,
  ]) {
    final detectedCode = detectAreaCode(city, district);
    
    if (detectedCode == null) {
      return {
        'code': null,
        'confidence': 'low',
        'reason': 'Location not recognized as UAE area',
      };
    }

    // Check confidence based on match quality
    final cityLower = city.toLowerCase().trim();
    final exactMatches = ['dubai', 'abu dhabi', 'sharjah', 'ajman', 
                          'fujairah', 'al ain', 'liwa'];
    
    if (exactMatches.any((name) => cityLower == name || cityLower.contains(name))) {
      return {
        'code': detectedCode,
        'confidence': 'high',
        'reason': 'Exact city name match',
      };
    }

    if (district != null && district.isNotEmpty) {
      return {
        'code': detectedCode,
        'confidence': 'medium',
        'reason': 'Detected from district name',
      };
    }

    return {
      'code': detectedCode,
      'confidence': 'medium',
      'reason': 'Partial text match',
    };
  }
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
