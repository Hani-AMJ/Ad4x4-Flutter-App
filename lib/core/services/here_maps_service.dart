import 'package:flutter/foundation.dart';
import '../../data/models/here_maps_settings.dart';
import '../../data/repositories/main_api_repository.dart';

/// Here Maps Service
/// 
/// ✅ MIGRATED TO BACKEND-DRIVEN ARCHITECTURE
/// - NO client-side API key (secured on backend)
/// - Configuration loaded from Django Admin panel
/// - Reverse geocoding via AD4x4 backend API
/// - JWT authentication required
/// - Backend handles caching (70%+ hit rate)
/// - Backend handles rate limiting
/// 
/// SECURITY IMPROVEMENTS:
/// ✅ API key protected server-side
/// ✅ Centralized usage monitoring
/// ✅ Input validation and sanitization
/// ✅ Rate limiting per user
/// 
/// PERFORMANCE IMPROVEMENTS:
/// ✅ Backend caching reduces API calls
/// ✅ Faster response times for cached locations
/// ✅ Reduced client complexity (no response parsing)
class HereMapsService {
  final MainApiRepository _repository;
  
  // Client-side cache for UI performance (short-term, 5 minutes)
  final Map<String, _CachedResult> _cache = {};
  static const _cacheDuration = Duration(minutes: 5);

  HereMapsService({MainApiRepository? repository})
      : _repository = repository ?? MainApiRepository();

  /// Load HERE Maps configuration from backend
  /// 
  /// Returns settings from Django Admin panel:
  /// - enabled: Global enable/disable toggle
  /// - selectedFields: Admin-selected display fields
  /// - maxFields: Maximum fields to display
  /// - availableFields: All field options
  /// 
  /// ✅ PUBLIC ENDPOINT - No authentication required
  /// ✅ Falls back to default settings if backend unavailable
  /// 
  /// Example:
  /// ```dart
  /// final settings = await hereMapsService.loadConfiguration();
  /// if (settings.enabled) {
  ///   // Geocoding is enabled
  /// }
  /// ```
  Future<HereMapsSettings> loadConfiguration() async {
    try {
      final response = await _repository.getHereMapsConfig();
      return HereMapsSettings.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load HERE Maps config from backend: $e');
        debugPrint('📋 Using default fallback configuration');
      }
      // Return default settings if backend unavailable
      return HereMapsSettings.defaultSettings();
    }
  }

  /// Reverse geocode coordinates to location information
  /// 
  /// Converts lat/lon to human-readable location string via backend API.
  /// 
  /// ✅ AUTHENTICATED ENDPOINT - Requires JWT token
  /// ✅ Backend handles API key, caching, rate limiting
  /// ✅ Returns pre-formatted display string
  /// 
  /// Parameters:
  /// - [lat]: Latitude in decimal degrees (-90 to 90)
  /// - [lon]: Longitude in decimal degrees (-180 to 180)
  /// - [settings]: Current configuration (checks if geocoding enabled)
  /// 
  /// Returns:
  /// - Pre-formatted location string (e.g., "Abu Dhabi, Al Karamah")
  /// - Empty string if geocoding disabled or error occurs
  /// 
  /// Behavior:
  /// - Checks client-side cache first (5 minute TTL)
  /// - If not cached, calls backend API
  /// - Backend checks its own cache (longer TTL, 24 hours)
  /// - Returns empty string on any error (graceful degradation)
  /// 
  /// Example:
  /// ```dart
  /// final location = await hereMapsService.reverseGeocode(
  ///   lat: 24.4539,
  ///   lon: 54.3773,
  ///   settings: currentSettings,
  /// );
  /// print(location); // "Abu Dhabi, Al Karamah"
  /// ```
  Future<String> reverseGeocode({
    required double lat,
    required double lon,
    required HereMapsSettings settings,
  }) async {
    try {
      // Check if reverse geocoding is enabled
      if (!settings.enabled) {
        if (kDebugMode) {
          debugPrint('ℹ️ HERE Maps reverse geocoding is disabled in backend settings');
        }
        return '';
      }

      // Check client-side cache first (performance optimization)
      final cacheKey = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
      
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().isBefore(cached.expiry)) {
          if (kDebugMode) {
            debugPrint('✅ HERE Maps: Cache hit for $cacheKey');
          }
          return cached.result;
        } else {
          // Cache expired, remove it
          _cache.remove(cacheKey);
        }
      }

      if (kDebugMode) {
        debugPrint('🌍 HERE Maps: Calling backend API for ($lat, $lon)');
      }

      // Call backend API (which has its own caching)
      final response = await _repository.reverseGeocode(
        latitude: lat,
        longitude: lon,
      );

      // Parse backend response
      if (response['success'] == true && response['area'] != null) {
        final area = response['area'] as String;
        
        // Cache the result client-side
        _cache[cacheKey] = _CachedResult(
          result: area,
          expiry: DateTime.now().add(_cacheDuration),
        );

        if (kDebugMode) {
          debugPrint('✅ HERE Maps: Success - "$area"');
        }

        return area;
      } else {
        // Backend returned success=false or no area
        if (kDebugMode) {
          debugPrint('⚠️ HERE Maps: Backend returned no location data');
          if (response['error'] != null) {
            debugPrint('   Error: ${response['error']}');
          }
        }
        return '';
      }
      
    } catch (e) {
      // Graceful error handling - return empty string
      if (kDebugMode) {
        debugPrint('❌ HERE Maps API error: $e');
      }
      return '';
    }
  }

  /// Clear client-side cache
  /// 
  /// Useful for:
  /// - Testing
  /// - Memory management
  /// - Forcing fresh data fetch
  /// 
  /// Note: This only clears the Flutter client cache.
  /// Backend cache is managed separately by the Django backend.
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('🧹 HERE Maps: Client cache cleared');
    }
  }

  /// Get client-side cache size
  /// 
  /// Returns number of cached location results in Flutter memory.
  /// Does not reflect backend cache size.
  int getCacheSize() {
    // Remove expired entries before counting
    _cache.removeWhere((key, value) => DateTime.now().isAfter(value.expiry));
    return _cache.length;
  }

  /// Get cache statistics for debugging
  /// 
  /// Returns map with cache metrics:
  /// - totalEntries: Number of cached results
  /// - validEntries: Number of non-expired entries
  /// - expiredEntries: Number of expired entries
  Map<String, int> getCacheStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((v) => now.isBefore(v.expiry)).length;
    final expiredEntries = _cache.values.where((v) => now.isAfter(v.expiry)).length;
    
    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
    };
  }
}

/// Internal cache result holder
class _CachedResult {
  final String result;
  final DateTime expiry;

  _CachedResult({
    required this.result,
    required this.expiry,
  });
}
