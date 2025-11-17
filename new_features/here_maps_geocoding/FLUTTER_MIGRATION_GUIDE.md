# HERE Maps Geocoding - Flutter Migration Guide

**Version:** 1.0  
**Date:** November 17, 2025  
**Target:** Flutter Development Team  
**Priority:** High (After Backend Implementation)

---

## 📋 Overview

This guide provides step-by-step instructions for migrating HERE Maps geocoding from client-side to backend-driven architecture.

### Prerequisites
- ✅ Backend API endpoints implemented and deployed
- ✅ Backend configuration endpoint accessible
- ✅ Test credentials available for staging

### Migration Goal
- Remove client-side HERE Maps API calls
- Load configuration from backend
- Call backend API for geocoding
- Remove hardcoded API key
- Remove OpenStreetMap Nominatim fallback

---

## 🎯 Migration Strategy

### Phase 1: Create Backend Integration (Before Removal)
1. Create new models for backend configuration
2. Create service to load configuration from backend
3. Create repository to call backend geocoding API
4. Test backend integration thoroughly

### Phase 2: Update Existing Code (Gradual Migration)
5. Update service to use backend API
6. Update provider to load from backend
7. Update admin screen to save to backend

### Phase 3: Cleanup (After Backend Verified Working)
8. Remove hardcoded API key
9. Remove OpenStreetMap Nominatim code
10. Remove local caching logic (backend handles this)

---

## 📁 Files to Create

### 1. Backend Configuration Model

**File:** `lib/data/models/here_maps_config_model.dart`

```dart
/// HERE Maps Backend Configuration Model
/// 
/// Stores configuration loaded from backend API
/// Loaded once on app startup
class HereMapsConfigModel {
  final bool enabled;
  final List<String> selectedFields;
  final int maxFields;
  final List<HereMapsDisplayField> availableFields;

  const HereMapsConfigModel({
    required this.enabled,
    required this.selectedFields,
    required this.maxFields,
    required this.availableFields,
  });

  /// Check if geocoding service is available
  bool get isAvailable => enabled && selectedFields.isNotEmpty;

  /// Factory: Create from backend API response
  factory HereMapsConfigModel.fromJson(Map<String, dynamic> json) {
    return HereMapsConfigModel(
      enabled: json['enabled'] as bool? ?? false,
      selectedFields: (json['selectedFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      maxFields: json['maxFields'] as int? ?? 2,
      availableFields: (json['availableFields'] as List<dynamic>?)
              ?.map((field) => HereMapsDisplayField.fromJson(
                  field as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Factory: Create default configuration (fallback)
  factory HereMapsConfigModel.defaultConfig() {
    return const HereMapsConfigModel(
      enabled: false,
      selectedFields: [],
      maxFields: 2,
      availableFields: [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'selectedFields': selectedFields,
      'maxFields': maxFields,
      'availableFields': availableFields.map((f) => f.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'HereMapsConfig(enabled: $enabled, fields: ${selectedFields.length})';
  }
}

/// Display Field Configuration
class HereMapsDisplayField {
  final String name;
  final String displayName;

  const HereMapsDisplayField({
    required this.name,
    required this.displayName,
  });

  factory HereMapsDisplayField.fromJson(Map<String, dynamic> json) {
    return HereMapsDisplayField(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HereMapsDisplayField && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
```

---

### 2. Backend Configuration Service

**File:** `lib/core/services/here_maps_config_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/here_maps_config_model.dart';

/// HERE Maps Configuration Service
/// 
/// Loads configuration from backend API on app startup
/// Falls back to defaults if backend unavailable
class HereMapsConfigService {
  static const String _configEndpoint = '/api/settings/here-maps-config/';
  static const Duration _loadTimeout = Duration(seconds: 10);
  
  // Singleton cache
  static HereMapsConfigModel? _cachedConfig;
  static DateTime? _lastLoadTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Load configuration from backend
  /// 
  /// Called once on app startup
  /// Uses cached value if still valid
  /// 
  /// Returns: HereMapsConfigModel (never null)
  static Future<HereMapsConfigModel> loadConfiguration({
    String baseUrl = 'https://ap.ad4x4.com',
    bool forceRefresh = false,
  }) async {
    // Return cached config if still valid
    if (!forceRefresh && _cachedConfig != null && _lastLoadTime != null) {
      final age = DateTime.now().difference(_lastLoadTime!);
      if (age < _cacheExpiry) {
        if (kDebugMode) {
          print('✅ HERE Maps config loaded from cache (age: ${age.inMinutes}m)');
        }
        return _cachedConfig!;
      }
    }

    try {
      final url = Uri.parse('$baseUrl$_configEndpoint');
      
      if (kDebugMode) {
        print('🔄 Loading HERE Maps config from: $url');
      }

      final response = await http.get(url).timeout(_loadTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final config = HereMapsConfigModel.fromJson(json);

        // Cache the config
        _cachedConfig = config;
        _lastLoadTime = DateTime.now();

        if (kDebugMode) {
          print('✅ HERE Maps config loaded: ${config.enabled ? "Enabled" : "Disabled"}');
        }

        return config;
      } else if (response.statusCode == 404) {
        // Endpoint not implemented yet
        if (kDebugMode) {
          print('⚠️ HERE Maps config endpoint not found (404) - using defaults');
        }
        return HereMapsConfigModel.defaultConfig();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      if (kDebugMode) {
        print('⚠️ HERE Maps config load timeout - using defaults');
      }
      return HereMapsConfigModel.defaultConfig();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load HERE Maps config: $e - using defaults');
      }
      return HereMapsConfigModel.defaultConfig();
    }
  }

  /// Clear cache (useful for testing)
  static void clearCache() {
    _cachedConfig = null;
    _lastLoadTime = null;
  }
}
```

---

### 3. Backend Geocoding Repository

**File:** `lib/data/repositories/here_maps_backend_repository.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HERE Maps Backend Repository
/// 
/// Calls backend API for geocoding instead of calling HERE Maps directly
class HereMapsBackendRepository {
  final String baseUrl;
  final String? authToken;
  
  static const String _geocodeEndpoint = '/api/geocoding/reverse/';
  static const Duration _requestTimeout = Duration(seconds: 15);

  HereMapsBackendRepository({
    this.baseUrl = 'https://ap.ad4x4.com',
    this.authToken,
  });

  /// Reverse geocode coordinates via backend API
  /// 
  /// Returns formatted area string or empty string on error
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$_geocodeEndpoint');
      
      if (kDebugMode) {
        print('🗺️ Reverse geocoding: ($latitude, $longitude)');
      }

      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (json['success'] == true) {
          final area = json['area'] as String? ?? '';
          final cached = json['cached'] as bool? ?? false;
          
          if (kDebugMode) {
            print('✅ Geocoded: $area ${cached ? "(cached)" : ""}');
          }
          
          return area;
        } else {
          // Backend returned error
          final error = json['error'] as String? ?? 'Unknown error';
          if (kDebugMode) {
            print('❌ Geocoding failed: $error');
          }
          return '';
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 503) {
        // Service disabled
        if (kDebugMode) {
          print('⚠️ HERE Maps service disabled');
        }
        return '';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      if (kDebugMode) {
        print('⚠️ Geocoding request timeout');
      }
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Geocoding error: $e');
      }
      return '';
    }
  }

  /// Update admin configuration (admin only)
  Future<bool> updateConfiguration({
    required bool enabled,
    String? apiKey,
    List<String>? selectedFields,
    int? maxFields,
    int? cacheDuration,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/settings/here-maps-config/');
      
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final body = jsonEncode({
        'enabled': enabled,
        if (apiKey != null) 'apiKey': apiKey,
        if (selectedFields != null) 'selectedFields': selectedFields,
        if (maxFields != null) 'maxFields': maxFields,
        if (cacheDuration != null) 'cacheDuration': cacheDuration,
      });

      final response = await http
          .put(url, headers: headers, body: body)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Configuration updated successfully');
        }
        return true;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['error'] ?? 'Failed to update configuration');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update configuration: $e');
      }
      rethrow;
    }
  }
}
```

---

## 📝 Files to Modify

### 4. Update HERE Maps Service

**File:** `lib/core/services/here_maps_service.dart`

**BEFORE (Current - Calls HERE Maps directly):**
```dart
Future<String> reverseGeocode({
  required double lat,
  required double lon,
  required HereMapsSettings settings,
}) async {
  try {
    // Call Here Maps API directly
    final url = '$_baseUrl/revgeocode';
    final result = await _dio.get(
      url,
      queryParameters: {
        'at': '$lat,$lon',
        'lang': 'en-US',
        'apiKey': settings.apiKey,  // ← Client-side API key!
      },
    );
    // ...
  }
}
```

**AFTER (Updated - Calls backend API):**
```dart
import '../../data/repositories/here_maps_backend_repository.dart';

class HereMapsService {
  final HereMapsBackendRepository _repository;
  
  HereMapsService({HereMapsBackendRepository? repository})
      : _repository = repository ?? HereMapsBackendRepository();

  /// Reverse geocode coordinates (via backend)
  Future<String> reverseGeocode({
    required double lat,
    required double lon,
    String? authToken,
  }) async {
    try {
      // Call backend API instead of HERE Maps directly
      final area = await _repository.reverseGeocode(
        latitude: lat,
        longitude: lon,
      );

      return area;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HERE Maps service error: $e');
      }
      return ''; // Return empty string on error
    }
  }

  // Remove: _extractField() method - backend handles this
  // Remove: _cache - backend handles caching
  // Remove: _formatCoordinates() - not needed anymore
}
```

---

### 5. Update Settings Provider

**File:** `lib/core/providers/here_maps_settings_provider.dart`

**BEFORE (Current - In-memory state):**
```dart
class HereMapsSettingsNotifier extends StateNotifier<HereMapsSettings> {
  HereMapsSettingsNotifier() : super(HereMapsSettings.defaultSettings());
  // ...
}

final hereMapsSettingsProvider =
    StateNotifierProvider<HereMapsSettingsNotifier, HereMapsSettings>((ref) {
  return HereMapsSettingsNotifier();
});
```

**AFTER (Updated - Loads from backend):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/here_maps_config_model.dart';
import '../../core/services/here_maps_config_service.dart';

/// HERE Maps Configuration Provider
/// 
/// Loads configuration from backend on app startup
/// Configuration is provided globally via main.dart
final hereMapsConfigProvider = Provider<HereMapsConfigModel>((ref) {
  // This provider is overridden in main.dart with loaded config
  // Default config used only if override fails (should never happen)
  return HereMapsConfigModel.defaultConfig();
});

/// Legacy settings provider for backwards compatibility
/// Will be removed after full migration
@Deprecated('Use hereMapsConfigProvider instead')
final hereMapsSettingsProvider = Provider<HereMapsSettings>((ref) {
  return HereMapsSettings.defaultSettings();
});
```

---

### 6. Update Main.dart to Load Configuration

**File:** `lib/main.dart`

**Add after gallery configuration loading:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization code ...
  
  // Load gallery configuration
  GalleryConfigModel galleryConfig;
  try {
    galleryConfig = await GalleryConfigService.loadConfiguration();
    // ...
  } catch (e) {
    galleryConfig = GalleryConfigModel.defaultConfig();
  }
  
  // Load HERE Maps configuration
  HereMapsConfigModel hereMapsConfig;
  try {
    hereMapsConfig = await HereMapsConfigService.loadConfiguration();
    developer.log('✅ HERE Maps configuration loaded successfully', name: 'Main');
  } catch (e) {
    hereMapsConfig = HereMapsConfigModel.defaultConfig();
    developer.log('⚠️ Using default HERE Maps config: $e', name: 'Main');
  }
  
  // Run app with Riverpod
  runApp(
    ProviderScope(
      overrides: [
        galleryConfigProvider.overrideWithValue(galleryConfig),
        hereMapsConfigProvider.overrideWithValue(hereMapsConfig), // ← Add this
      ],
      child: AD4x4App(brandTokens: brandTokens),
    ),
  );
}
```

---

### 7. Update Admin Settings Screen

**File:** `lib/features/admin/presentation/screens/admin_here_maps_settings_screen.dart`

**Changes needed:**

1. **Load configuration from backend instead of local state:**

```dart
@override
void initState() {
  super.initState();
  // Load from backend config provider
  final config = ref.read(hereMapsConfigProvider);
  _apiKeyController = TextEditingController(text: '***HIDDEN***');
  _selectedFields = List.from(config.selectedFields);
}
```

2. **Save configuration to backend instead of local state:**

```dart
Future<void> _saveSettings() async {
  setState(() => _isSaving = true);
  
  try {
    final authState = ref.read(authProviderV2);
    final token = authState.token;
    
    final repository = HereMapsBackendRepository(authToken: token);
    
    final success = await repository.updateConfiguration(
      enabled: _enabled,
      apiKey: _apiKeyController.text.trim().isEmpty 
          ? null 
          : _apiKeyController.text.trim(),
      selectedFields: _selectedFields.map((f) => f.name).toList(),
    );
    
    if (success && mounted) {
      // Force refresh configuration
      await HereMapsConfigService.loadConfiguration(forceRefresh: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

3. **Update field selection UI to use backend config:**

```dart
Widget _buildFieldSelection() {
  final config = ref.watch(hereMapsConfigProvider);
  
  return Column(
    children: config.availableFields.map((field) {
      final isSelected = _selectedFields.any((f) => f.name == field.name);
      final canSelect = !_isAtMaxFields || isSelected;
      
      return CheckboxListTile(
        title: Text(field.displayName),
        value: isSelected,
        enabled: canSelect,
        onChanged: canSelect ? (bool? value) {
          setState(() {
            if (value == true) {
              _selectedFields.add(field);
            } else {
              _selectedFields.removeWhere((f) => f.name == field.name);
            }
          });
        } : null,
      );
    }).toList(),
  );
}
```

---

### 8. Update Meeting Point Form

**File:** `lib/features/admin/presentation/screens/admin_meeting_point_form_screen.dart`

**Changes needed:**

1. **Update fetch location button to use backend API:**

```dart
Future<void> _fetchLocationFromHereMaps() async {
  // Validate coordinates
  if (_latController.text.trim().isEmpty || _lonController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Please enter latitude and longitude first'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    final lat = double.parse(_latController.text.trim());
    final lon = double.parse(_lonController.text.trim());

    // Check if service is available
    final config = ref.read(hereMapsConfigProvider);
    if (!config.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Geocoding service is not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('🗺️ Fetching location from HERE Maps...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    // Get auth token
    final authState = ref.read(authProviderV2);
    final token = authState.token;

    // Call backend API
    final repository = HereMapsBackendRepository(authToken: token);
    final areaValue = await repository.reverseGeocode(
      latitude: lat,
      longitude: lon,
    );

    // Hide loading
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (areaValue.isEmpty) {
      // No data available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No location data available for these coordinates'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      setState(() {
        _areaController.text = '';
      });
    } else {
      // Success - update field
      setState(() {
        _areaController.text = areaValue;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Location fetched: $areaValue'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } on FormatException {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Invalid coordinates format'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Failed to fetch location: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

2. **REMOVE OpenStreetMap Nominatim code (Lines 234-307):**

```dart
// DELETE THIS ENTIRE FUNCTION:
Future<String> _getAreaFromCoordinates(String lat, String lon) async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      // ...
    );
    // ... entire function body ...
  }
}
```

3. **REMOVE automatic OpenStreetMap call from save function:**

```dart
Future<void> _saveMeetingPoint() async {
  // ...
  
  // DELETE THESE LINES (292-306):
  // if (lat.isNotEmpty && lon.isNotEmpty) {
  //   final fetchedArea = await _getAreaFromCoordinates(lat, lon);
  //   if (fetchedArea.isNotEmpty) {
  //     areaValue = fetchedArea;
  //   }
  // }
  
  // Keep only this:
  String areaValue = _areaController.text.trim();
  
  final data = {
    'name': _nameController.text.trim(),
    'area': areaValue,  // Use whatever is in the field
    'lat': _latController.text.trim(),
    'lon': _lonController.text.trim(),
    'link': _linkController.text.trim(),
  };
  
  // ... rest of save logic ...
}
```

---

### 9. Remove Hardcoded API Key

**File:** `lib/data/models/here_maps_settings.dart`

**DELETE these lines:**

```dart
// DELETE THIS:
static const String defaultApiKey = 'tLzdVrbRbvWpl_8Em4JbjHxzFMIvIRyMo9xyKn7fBW8';

// And update defaultSettings:
factory HereMapsSettings.defaultSettings() {
  return const HereMapsSettings(
    apiKey: '',  // ← Change from defaultApiKey to empty string
    selectedFields: [HereMapsDisplayField.district],
    enableReverseGeocode: true,
  );
}
```

**Note:** This model will eventually be deprecated and removed entirely, but keep it for backwards compatibility during migration.

---

## 🧪 Testing Requirements

### Unit Tests

**File:** `test/services/here_maps_config_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

void main() {
  group('HereMapsConfigService', () {
    test('loads configuration from backend', () async {
      // Test configuration loading
    });
    
    test('falls back to defaults on 404', () async {
      // Test fallback behavior
    });
    
    test('caches configuration for 1 hour', () async {
      // Test caching
    });
  });
}
```

### Integration Tests

**File:** `integration_test/here_maps_test.dart`

```dart
void main() {
  testWidgets('Fetch location updates area field', (tester) async {
    // 1. Navigate to meeting point form
    // 2. Enter coordinates
    // 3. Tap "Fetch Location" button
    // 4. Verify area field populated
    // 5. Tap save
    // 6. Verify area saved correctly
  });
}
```

---

## 📋 Migration Checklist

### Phase 1: Create New Backend Integration
- [ ] Create `here_maps_config_model.dart`
- [ ] Create `here_maps_config_service.dart`
- [ ] Create `here_maps_backend_repository.dart`
- [ ] Add configuration provider
- [ ] Test configuration loading from staging backend

### Phase 2: Update Existing Code
- [ ] Update `here_maps_service.dart` to use backend API
- [ ] Update `here_maps_settings_provider.dart` with new provider
- [ ] Update `main.dart` to load configuration on startup
- [ ] Update admin settings screen to save to backend
- [ ] Update meeting point form to use backend geocoding
- [ ] Test all changes thoroughly

### Phase 3: Cleanup
- [ ] Remove hardcoded API key from `here_maps_settings.dart`
- [ ] Remove `_getAreaFromCoordinates()` function (lines 234-274)
- [ ] Remove automatic OpenStreetMap call from save (lines 292-306)
- [ ] Remove client-side caching logic
- [ ] Remove old imports
- [ ] Run `flutter analyze` to check for issues

### Phase 4: Testing
- [ ] Test configuration loading
- [ ] Test geocoding via backend
- [ ] Test admin settings update
- [ ] Test with backend disabled (graceful degradation)
- [ ] Test with invalid coordinates
- [ ] Test caching behavior
- [ ] Test on staging environment
- [ ] Deploy to production

### Phase 5: Post-Deployment
- [ ] Monitor for errors
- [ ] Verify backend API calls working
- [ ] Check performance metrics
- [ ] Rotate HERE Maps API key (security)
- [ ] Remove deprecated code after verification

---

## ⚠️ Important Notes

### Backwards Compatibility

During migration, maintain backwards compatibility:

1. **Keep old models** until full migration complete
2. **Gradual provider migration** - deprecated old, add new
3. **Test both paths** during transition period

### Error Handling

Always show user-friendly error messages:

```dart
try {
  // Backend call
} catch (e) {
  if (e.toString().contains('401')) {
    // Authentication error
    showError('Please log in again');
  } else if (e.toString().contains('503')) {
    // Service disabled
    showError('Geocoding service temporarily unavailable');
  } else {
    // Generic error
    showError('Failed to fetch location. Please try again.');
  }
}
```

### Testing Strategy

1. **Test with backend staging** first
2. **Test with service disabled** (graceful degradation)
3. **Test with invalid tokens** (authentication)
4. **Test with slow network** (timeout handling)
5. **Test with invalid coordinates** (validation)

---

## 🚀 Deployment Steps

### Pre-Deployment Checklist
- [ ] Backend API deployed to production
- [ ] Backend configuration created and tested
- [ ] Flutter changes tested on staging
- [ ] All tests passing
- [ ] Code reviewed

### Deployment Process

1. **Deploy Flutter App:**
   ```bash
   flutter build apk --release
   # OR
   flutter build web --release
   ```

2. **Monitor Logs:**
   - Check for configuration loading errors
   - Verify backend API calls successful
   - Monitor geocoding success rate

3. **Rollback Plan:**
   - If errors occur, revert to previous version
   - Backend API remains available (no breaking changes)

### Post-Deployment

1. **Rotate API Key** (Security):
   - Generate new HERE Maps API key
   - Update in backend admin panel
   - Old key in Flutter app is now useless

2. **Monitor Metrics:**
   - Configuration load success rate: Should be > 99%
   - Geocoding success rate: Should be > 95%
   - Cache hit rate: Should be > 70%
   - Response time: Should be < 2s

3. **Cleanup:**
   - After 1 week of successful operation
   - Remove deprecated code
   - Remove old models and providers

---

## 📊 Success Criteria

- ✅ Configuration loads from backend on startup
- ✅ Geocoding calls backend API successfully
- ✅ Admin can update settings via admin screen
- ✅ No hardcoded API keys in Flutter app
- ✅ OpenStreetMap code removed
- ✅ Graceful degradation if service unavailable
- ✅ All tests passing
- ✅ Zero production errors

---

**Status:** Migration Guide Complete  
**Estimated Time:** 4-5 hours  
**Priority:** High (After Backend Deployed)  
**Next Step:** Create GitHub Issues
