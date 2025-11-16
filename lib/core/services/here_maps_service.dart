import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/models/here_maps_settings.dart';

/// Here Maps Service
/// 
/// Handles reverse geocoding using Here Maps API
class HereMapsService {
  final Dio _dio;
  
  // Cache for reverse geocode results to avoid duplicate API calls
  final Map<String, Map<String, dynamic>> _cache = {};
  
  static const String _baseUrl = 'https://revgeocode.search.hereapi.com/v1';

  HereMapsService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      // Don't set User-Agent header - browsers don't allow it for security
      headers: {},
    ),
  );

  /// Reverse geocode coordinates to location information
  /// 
  /// Returns formatted string based on selected fields in settings
  Future<String> reverseGeocode({
    required double lat,
    required double lon,
    required HereMapsSettings settings,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
      
      Map<String, dynamic> response;
      if (_cache.containsKey(cacheKey)) {
        response = _cache[cacheKey]!;
      } else {
        // Call Here Maps API
        final url = '$_baseUrl/revgeocode';
        final result = await _dio.get(
          url,
          queryParameters: {
            'at': '$lat,$lon',
            'lang': 'en-US',
            'apiKey': settings.apiKey,
          },
        );
        
        response = result.data as Map<String, dynamic>;
        
        // Cache the response
        _cache[cacheKey] = response;
      }

      // Extract selected fields
      final parts = <String>[];
      for (final field in settings.selectedFields) {
        final value = _extractField(response, field);
        if (value.isNotEmpty) {
          parts.add(value);
        }
      }

      // Return combined string or empty if no data
      if (parts.isEmpty) {
        return ''; // Return empty string instead of coordinates
      }
      
      return parts.join(', ');
      
    } catch (e) {
      // Return empty string on error
      if (kDebugMode) {
        debugPrint('❌ Here Maps API error: $e');
      }
      return ''; // Return empty string instead of coordinates
    }
  }

  /// Extract specific field from Here Maps response
  String _extractField(Map<String, dynamic> response, HereMapsDisplayField field) {
    try {
      final items = response['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return '';
      }

      final item = items[0] as Map<String, dynamic>;
      
      switch (field) {
        case HereMapsDisplayField.title:
          return item['title'] as String? ?? '';
          
        case HereMapsDisplayField.district:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['district'] as String? ?? '';
          
        case HereMapsDisplayField.city:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['city'] as String? ?? '';
          
        case HereMapsDisplayField.county:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['county'] as String? ?? '';
          
        case HereMapsDisplayField.countryName:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['countryName'] as String? ?? '';
          
        case HereMapsDisplayField.postalCode:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['postalCode'] as String? ?? '';
          
        case HereMapsDisplayField.label:
          final address = item['address'] as Map<String, dynamic>?;
          return address?['label'] as String? ?? '';
          
        case HereMapsDisplayField.categoryName:
          final categories = item['categories'] as List<dynamic>?;
          if (categories != null && categories.isNotEmpty) {
            final category = categories[0] as Map<String, dynamic>;
            return category['name'] as String? ?? '';
          }
          return '';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error extracting field ${field.name}: $e');
      }
      return '';
    }
  }

  /// Format coordinates as fallback display
  String _formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
  }

  /// Get cache size
  int getCacheSize() {
    return _cache.length;
  }
}
