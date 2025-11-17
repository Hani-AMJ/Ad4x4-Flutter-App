# Gallery Integration - Critical Flutter Changes

**Date:** January 17, 2025  
**Priority:** 🔴 **HIGH** - Implement before feature development

---

## 🎯 Summary of Changes

**Previous Design:** Hardcoded Gallery API URL in Flutter code.  
**New Design:** All configuration loaded from backend API - flexible system.

---

## ⚠️ CRITICAL REQUIREMENTS

### 1. **Load Configuration on App Startup**

**File:** `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load rating configuration
  final ratingConfig = await RatingConfigService.loadConfiguration();
  
  // 🔴 NEW: Load gallery configuration
  final galleryConfig = await GalleryConfigService.loadConfiguration();
  
  runApp(
    MultiProvider(
      providers: [
        // ... existing providers ...
        Provider<RatingConfigModel>.value(value: ratingConfig),
        
        // 🔴 NEW: Provide gallery configuration globally
        Provider<GalleryConfigModel>.value(value: galleryConfig),
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. **Create Gallery Configuration Model**

**File:** `lib/data/models/gallery_config_model.dart`

```dart
class GalleryConfigModel {
  final bool enabled;
  final bool autoCreate;
  final bool allowManualCreation;
  final String apiUrl;
  final int timeout;
  final GalleryFeatures features;
  
  GalleryConfigModel({
    required this.enabled,
    required this.autoCreate,
    required this.allowManualCreation,
    required this.apiUrl,
    required this.timeout,
    required this.features,
  });
  
  factory GalleryConfigModel.fromJson(Map<String, dynamic> json) {
    return GalleryConfigModel(
      enabled: json['enabled'] as bool,
      autoCreate: json['autoCreate'] as bool,
      allowManualCreation: json['allowManualCreation'] as bool,
      apiUrl: json['apiUrl'] as String,
      timeout: json['timeout'] as int,
      features: GalleryFeatures.fromJson(json['features']),
    );
  }
  
  /// Check if gallery system is available
  bool get isAvailable => enabled;
  
  /// Check if user can upload photos
  bool get canUpload => enabled && features.allowUserUploads;
  
  /// Check if user can delete their photos
  bool get canDelete => enabled && features.allowUserDeletes;
}

class GalleryFeatures {
  final bool allowUserUploads;
  final bool allowUserDeletes;
  final int maxPhotoSize;
  final List<String> supportedFormats;
  
  GalleryFeatures({
    required this.allowUserUploads,
    required this.allowUserDeletes,
    required this.maxPhotoSize,
    required this.supportedFormats,
  });
  
  factory GalleryFeatures.fromJson(Map<String, dynamic> json) {
    return GalleryFeatures(
      allowUserUploads: json['allowUserUploads'] as bool,
      allowUserDeletes: json['allowUserDeletes'] as bool,
      maxPhotoSize: json['maxPhotoSize'] as int,
      supportedFormats: List<String>.from(json['supportedFormats']),
    );
  }
  
  /// Get human-readable max photo size
  String get maxPhotoSizeFormatted {
    final mb = maxPhotoSize / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}
```

### 3. **Create Configuration Service**

**File:** `lib/core/services/gallery_config_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/gallery_config_model.dart';

class GalleryConfigService {
  static const String _configEndpoint = '/api/settings/gallery-config/';
  
  /// Load gallery configuration from backend
  /// Called once on app startup
  static Future<GalleryConfigModel> loadConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('https://ap.ad4x4.com$_configEndpoint'),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return GalleryConfigModel.fromJson(json);
      } else {
        // Return default configuration if API fails
        return _getDefaultConfiguration();
      }
    } catch (e) {
      print('Failed to load gallery configuration: $e');
      return _getDefaultConfiguration();
    }
  }
  
  /// Default configuration (matches backend defaults)
  static GalleryConfigModel _getDefaultConfiguration() {
    return GalleryConfigModel(
      enabled: true,
      autoCreate: true,
      allowManualCreation: true,
      apiUrl: 'https://media.ad4x4.com',
      timeout: 30,
      features: GalleryFeatures(
        allowUserUploads: true,
        allowUserDeletes: true,
        maxPhotoSize: 10485760, // 10MB
        supportedFormats: ['jpg', 'jpeg', 'png', 'heic'],
      ),
    );
  }
}
```

---

## 🚫 **REMOVE ALL HARDCODED VALUES**

### ❌ Delete These Patterns:

```dart
// ❌ WRONG - Hardcoded API URL
const String GALLERY_API_URL = 'https://media.ad4x4.com';

// ❌ WRONG - Hardcoded feature flags
const bool ALLOW_UPLOADS = true;
```

### ✅ Replace With:

```dart
// ✅ CORRECT - Use configuration from provider
final config = context.read<GalleryConfigModel>();

if (config.isAvailable) {
  // Gallery system is enabled
  if (config.canUpload) {
    // User can upload photos
  }
}
```

---

## 🎨 **UI Widget Updates**

### Example: Gallery Upload Button

```dart
class GalleryUploadButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔴 CRITICAL: Get configuration from provider
    final config = ref.watch<GalleryConfigModel>();
    
    // Hide button if gallery system disabled or uploads not allowed
    if (!config.canUpload) {
      return SizedBox.shrink();
    }
    
    return ElevatedButton.icon(
      onPressed: () => _uploadPhoto(context, config),
      icon: Icon(Icons.upload),
      label: Text('Upload Photo'),
    );
  }
  
  void _uploadPhoto(BuildContext context, GalleryConfigModel config) async {
    // Use config for validation
    final file = await pickImage();
    
    if (file != null && file.lengthSync() > config.features.maxPhotoSize) {
      showError('Photo exceeds maximum size of ${config.features.maxPhotoSizeFormatted}');
      return;
    }
    
    // Upload to gallery API
    // ...
  }
}
```

### Example: Gallery Admin Tab

```dart
class GalleryAdminTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch<GalleryConfigModel>();
    
    if (!config.enabled) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Gallery System Disabled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'The gallery feature is currently disabled by administrators.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Show gallery management UI
    return _buildGalleryManagementUI(config);
  }
}
```

---

## 📝 **Validation Updates**

### Photo Upload Validation

```dart
Future<bool> validatePhotoUpload(File photo, GalleryConfigModel config) async {
  // Check if uploads allowed
  if (!config.canUpload) {
    showError('Photo uploads are currently disabled');
    return false;
  }
  
  // Check file size
  if (photo.lengthSync() > config.features.maxPhotoSize) {
    showError('Photo exceeds maximum size of ${config.features.maxPhotoSizeFormatted}');
    return false;
  }
  
  // Check file format
  final extension = path.extension(photo.path).toLowerCase().replaceAll('.', '');
  if (!config.features.supportedFormats.contains(extension)) {
    showError('Format not supported. Allowed: ${config.features.supportedFormats.join(', ')}');
    return false;
  }
  
  return true;
}
```

---

## 🧪 **Testing Requirements**

### Unit Tests

```dart
void main() {
  group('GalleryConfigModel', () {
    test('should parse configuration correctly', () {
      final json = {
        'enabled': true,
        'autoCreate': true,
        'allowManualCreation': true,
        'apiUrl': 'https://media.ad4x4.com',
        'timeout': 30,
        'features': {
          'allowUserUploads': true,
          'allowUserDeletes': true,
          'maxPhotoSize': 10485760,
          'supportedFormats': ['jpg', 'jpeg', 'png', 'heic'],
        },
      };
      
      final config = GalleryConfigModel.fromJson(json);
      
      expect(config.enabled, true);
      expect(config.canUpload, true);
      expect(config.features.maxPhotoSizeFormatted, '10 MB');
    });
    
    test('should handle disabled gallery system', () {
      final config = GalleryConfigModel(
        enabled: false,
        autoCreate: false,
        allowManualCreation: false,
        apiUrl: 'https://media.ad4x4.com',
        timeout: 30,
        features: GalleryFeatures(
          allowUserUploads: false,
          allowUserDeletes: false,
          maxPhotoSize: 10485760,
          supportedFormats: ['jpg'],
        ),
      );
      
      expect(config.isAvailable, false);
      expect(config.canUpload, false);
      expect(config.canDelete, false);
    });
  });
}
```

---

## 📊 **Files Modified Summary**

| File | Change Type | Description |
|------|-------------|-------------|
| `main.dart` | **CRITICAL** | Load gallery config on startup |
| `gallery_config_model.dart` | **NEW** | Configuration model |
| `gallery_config_service.dart` | **NEW** | API service for config |
| `gallery_admin_tab.dart` | **MODIFY** | Use config for feature checks |
| `gallery_upload_button.dart` | **MODIFY** | Use config for validation |
| All gallery UI widgets | **MODIFY** | Check config.enabled |
| All photo upload logic | **MODIFY** | Validate against config |

---

## ✅ **Migration Checklist**

- [ ] Create `GalleryConfigModel` class
- [ ] Create `GalleryConfigService` class
- [ ] Update `main.dart` to load gallery configuration
- [ ] Add `GalleryConfigModel` to provider tree
- [ ] Update Gallery Admin Tab to check configuration
- [ ] Update photo upload validation to use configuration
- [ ] Hide upload buttons when uploads disabled
- [ ] Show appropriate messages when gallery system disabled
- [ ] Add unit tests for configuration model
- [ ] Test with gallery system disabled
- [ ] Test with different max photo sizes
- [ ] Document configuration loading in developer guide

---

## 🚨 **Critical Warnings**

1. **DO NOT START GALLERY DEVELOPMENT** without implementing configuration loading
2. **DO NOT HARDCODE** Gallery API URL or feature flags
3. **ALWAYS** check `config.enabled` before showing gallery features
4. **HANDLE** disabled state gracefully with user-friendly messages
5. **VALIDATE** all uploads against configuration limits

---

## 📞 **Questions?**

If configuration API is not ready:
1. Use default configuration as fallback
2. Log warning that backend configuration is unavailable
3. Continue development with default values
4. Replace with actual API call when backend is ready

**Backend API Endpoint:** `GET /api/settings/gallery-config/`  
**Backend Documentation:** See `GALLERY_INTEGRATION_BACKEND_SPEC.md` section on Configuration API

---

**End of Critical Changes Document**

*This document supplements the main Flutter implementation plan with configuration requirements.*
