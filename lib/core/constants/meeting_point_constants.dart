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
  static String? detectAreaCode(String city, [String? district, String? area]) {
    final cityLower = city.toLowerCase().trim();
    final districtLower = (district ?? '').toLowerCase().trim();
    final areaLower = (area ?? '').toLowerCase().trim();

    // Strategy 1: Exact and partial matching across ALL fields
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

    // Check city field first (highest priority)
    for (var entry in cityMapping.entries) {
      if (cityLower == entry.key || cityLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Strategy 2: Check district field
    if (districtLower.isNotEmpty) {
      for (var entry in cityMapping.entries) {
        if (districtLower.contains(entry.key)) {
          return entry.value;
        }
      }
      
      // Al Ain specific districts
      if (districtLower.contains('al jimi') ||
          districtLower.contains('tawam') ||
          districtLower.contains('buraimi')) {
        return 'AAN';
      }

      // Liwa specific districts
      if (districtLower.contains('madinat zayed') ||
          districtLower.contains('ghayathi')) {
        return 'LIW';
      }
    }

    // Strategy 3: Check area (full location text) - IMPORTANT for places like "Al Madam"
    if (areaLower.isNotEmpty) {
      for (var entry in cityMapping.entries) {
        if (areaLower.contains(entry.key)) {
          return entry.value;
        }
      }
      
      // Northern Emirates specific locations
      // Al Madam, Hatta, Kalba, Dibba, Masafi are all in Northern Emirates
      if (areaLower.contains('al madam') ||
          areaLower.contains('hatta') ||
          areaLower.contains('kalba') ||
          areaLower.contains('dibba') ||
          areaLower.contains('masafi') ||
          areaLower.contains('khor fakkan') ||
          areaLower.contains('khorfakkan')) {
        return 'NOR';
      }
      
      // Al Ain region locations
      if (areaLower.contains('buraimi')) {
        return 'AAN';
      }
    }

    // Strategy 4: Combined text search (last resort)
    final fullText = '$cityLower $districtLower $areaLower';
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
    String? area,
  ]) {
    final detectedCode = detectAreaCode(city, district, area);
    
    if (detectedCode == null) {
      return {
        'code': null,
        'confidence': 'low',
        'reason': 'Location not recognized as UAE area',
      };
    }

    // Check confidence based on match quality
    final cityLower = city.toLowerCase().trim();
    final districtLower = (district ?? '').toLowerCase().trim();
    final areaLower = (area ?? '').toLowerCase().trim();
    
    final exactMatches = ['dubai', 'abu dhabi', 'sharjah', 'ajman', 
                          'fujairah', 'al ain', 'liwa'];
    
    // High confidence: Exact city name match
    if (exactMatches.any((name) => cityLower == name || cityLower.contains(name))) {
      return {
        'code': detectedCode,
        'confidence': 'high',
        'reason': 'Exact city name match',
      };
    }

    // High confidence: Known specific locations in area field
    final knownLocations = ['al madam', 'hatta', 'kalba', 'dibba', 'masafi', 'khor fakkan'];
    if (knownLocations.any((loc) => areaLower.contains(loc) || districtLower.contains(loc))) {
      return {
        'code': detectedCode,
        'confidence': 'high',
        'reason': 'Known specific location',
      };
    }

    // Medium confidence: District or area field match
    if (districtLower.isNotEmpty || areaLower.isNotEmpty) {
      return {
        'code': detectedCode,
        'confidence': 'medium',
        'reason': 'Detected from district/area name',
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
