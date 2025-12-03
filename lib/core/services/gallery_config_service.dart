/// Gallery Configuration Service
/// 
/// Handles loading gallery system configuration from backend API.
/// Configuration is loaded once on app startup and cached globally.
/// 
/// Design Philosophy: Backend-driven configuration with graceful fallback
/// - Attempts to load from backend API
/// - Falls back to default configuration if API unavailable
/// - Never crashes app due to configuration errors
/// - Logs errors for debugging
/// 
/// Backend API: GET /api/settings/gallery-config/
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/gallery_config_model.dart';

class GalleryConfigService {
  static const String _configEndpoint = '/api/settings/gallery-config/';
  static const Duration _loadTimeout = Duration(seconds: 10);
  
  // Singleton instance for caching
  static GalleryConfigModel? _cachedConfig;
  static DateTime? _lastLoadTime;
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  /// Load gallery configuration from backend
  /// 
  /// Called once on app startup. Uses cached value if still valid.
  /// Falls back to default configuration if:
  /// - API endpoint doesn't exist yet (backend not ready)
  /// - Network error occurs
  /// - Timeout exceeds 10 seconds
  /// - Invalid JSON response
  /// 
  /// Returns: GalleryConfigModel (never null)
  static Future<GalleryConfigModel> loadConfiguration({
    String baseUrl = 'https://ap.ad4x4.com',
    bool forceRefresh = false,
  }) async {
    // Return cached config if still valid
    if (!forceRefresh && _cachedConfig != null && _lastLoadTime != null) {
      final age = DateTime.now().difference(_lastLoadTime!);
      if (age < _cacheExpiry) {
        print('✅ Gallery config loaded from cache (age: ${age.inMinutes}m)');
        return _cachedConfig!;
      }
    }
    
    try {
      print('🔄 Loading gallery configuration from backend...');
      
      final uri = Uri.parse('$baseUrl$_configEndpoint');
      
      // Load with timeout
      final response = await http.get(uri).timeout(
        _loadTimeout,
        onTimeout: () {
          print('⚠️ Gallery config API timeout after ${_loadTimeout.inSeconds}s');
          throw TimeoutException('Config API timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final config = GalleryConfigModel.fromJson(json);
        
        // Cache the result
        _cachedConfig = config;
        _lastLoadTime = DateTime.now();
        
        print('✅ Gallery config loaded successfully from backend');
        print('   - Enabled: ${config.enabled}');
        print('   - API URL: ${config.apiUrl}');
        print('   - Can Upload: ${config.canUpload}');
        
        return config;
      } else if (response.statusCode == 404) {
        // API endpoint doesn't exist yet - backend not ready
        print('⚠️ Gallery config API not found (404) - using defaults');
        print('   Backend may not have configuration endpoint implemented yet.');
        return _getDefaultConfiguration();
      } else {
        // Other HTTP error
        print('⚠️ Gallery config API error: ${response.statusCode}');
        return _getDefaultConfiguration();
      }
    } on TimeoutException catch (e) {
      print('⚠️ Gallery config timeout: $e');
      return _getDefaultConfiguration();
    } catch (e) {
      // Any other error (network, JSON parsing, etc.)
      print('⚠️ Failed to load gallery config: $e');
      print('   Using default configuration as fallback.');
      return _getDefaultConfiguration();
    }
  }
  
  /// Get default configuration (matches backend defaults)
  /// 
  /// Used as fallback when backend API is unavailable.
  /// Values match the backend default configuration to ensure consistency.
  static GalleryConfigModel _getDefaultConfiguration() {
    print('📦 Using default gallery configuration');
    return GalleryConfigModel.defaultConfig();
  }
  
  /// Clear cached configuration (force reload on next access)
  static void clearCache() {
    _cachedConfig = null;
    _lastLoadTime = null;
    print('🗑️ Gallery config cache cleared');
  }
  
  /// Get cached configuration (if available)
  static GalleryConfigModel? getCachedConfig() {
    if (_cachedConfig != null && _lastLoadTime != null) {
      final age = DateTime.now().difference(_lastLoadTime!);
      if (age < _cacheExpiry) {
        return _cachedConfig;
      }
    }
    return null;
  }
  
  /// Check if configuration is cached and valid
  static bool get isCacheValid {
    if (_cachedConfig == null || _lastLoadTime == null) return false;
    final age = DateTime.now().difference(_lastLoadTime!);
    return age < _cacheExpiry;
  }
  
  /// Get cache age (for debugging)
  static Duration? get cacheAge {
    if (_lastLoadTime == null) return null;
    return DateTime.now().difference(_lastLoadTime!);
  }
}
