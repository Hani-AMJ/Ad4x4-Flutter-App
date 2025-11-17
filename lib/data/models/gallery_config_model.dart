/// Gallery Configuration Model
/// 
/// Stores gallery system configuration loaded from backend API.
/// Configuration is loaded once on app startup and cached globally.
/// 
/// Design Philosophy: Backend-driven configuration
/// - All gallery behavior controlled by backend settings
/// - No hardcoded URLs, feature flags, or limits
/// - Admins can modify settings without app updates
/// 
/// Backend API: GET /api/settings/gallery-config/

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global gallery configuration provider
/// Initialized in main.dart with backend configuration
final galleryConfigProvider = Provider<GalleryConfigModel>((ref) {
  // This provider is overridden in main.dart with loaded config
  // Default config used only if override fails (should never happen)
  return GalleryConfigModel.defaultConfig();
});

class GalleryConfigModel {
  final bool enabled;
  final bool autoCreate;
  final bool allowManualCreation;
  final String apiUrl;
  final int timeout;
  final GalleryFeatures features;
  
  const GalleryConfigModel({
    required this.enabled,
    required this.autoCreate,
    required this.allowManualCreation,
    required this.apiUrl,
    required this.timeout,
    required this.features,
  });
  
  /// Check if gallery system is available
  bool get isAvailable => enabled;
  
  /// Check if user can upload photos
  bool get canUpload => enabled && features.allowUserUploads;
  
  /// Check if user can delete their photos
  bool get canDelete => enabled && features.allowUserDeletes;
  
  /// Check if galleries are auto-created for trips
  bool get autoCreatesGalleries => enabled && autoCreate;
  
  /// Factory: Create from JSON (backend API response)
  factory GalleryConfigModel.fromJson(Map<String, dynamic> json) {
    return GalleryConfigModel(
      enabled: json['enabled'] as bool? ?? true,
      autoCreate: json['autoCreate'] as bool? ?? true,
      allowManualCreation: json['allowManualCreation'] as bool? ?? true,
      apiUrl: json['apiUrl'] as String? ?? 'https://media.ad4x4.com',
      timeout: json['timeout'] as int? ?? 30,
      features: json['features'] != null
          ? GalleryFeatures.fromJson(json['features'] as Map<String, dynamic>)
          : GalleryFeatures.defaultFeatures(),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'autoCreate': autoCreate,
      'allowManualCreation': allowManualCreation,
      'apiUrl': apiUrl,
      'timeout': timeout,
      'features': features.toJson(),
    };
  }
  
  /// Create default configuration (fallback if API fails)
  factory GalleryConfigModel.defaultConfig() {
    return GalleryConfigModel(
      enabled: true,
      autoCreate: true,
      allowManualCreation: true,
      apiUrl: 'https://media.ad4x4.com',
      timeout: 30,
      features: GalleryFeatures.defaultFeatures(),
    );
  }
  
  /// Copy with method for updates
  GalleryConfigModel copyWith({
    bool? enabled,
    bool? autoCreate,
    bool? allowManualCreation,
    String? apiUrl,
    int? timeout,
    GalleryFeatures? features,
  }) {
    return GalleryConfigModel(
      enabled: enabled ?? this.enabled,
      autoCreate: autoCreate ?? this.autoCreate,
      allowManualCreation: allowManualCreation ?? this.allowManualCreation,
      apiUrl: apiUrl ?? this.apiUrl,
      timeout: timeout ?? this.timeout,
      features: features ?? this.features,
    );
  }
  
  @override
  String toString() {
    return 'GalleryConfig(enabled: $enabled, apiUrl: $apiUrl, canUpload: $canUpload)';
  }
}

/// Gallery Features Configuration
/// 
/// Controls what users can do with galleries
class GalleryFeatures {
  final bool allowUserUploads;
  final bool allowUserDeletes;
  final int maxPhotoSize;
  final List<String> supportedFormats;
  
  const GalleryFeatures({
    required this.allowUserUploads,
    required this.allowUserDeletes,
    required this.maxPhotoSize,
    required this.supportedFormats,
  });
  
  /// Get human-readable max photo size
  String get maxPhotoSizeFormatted {
    final mb = maxPhotoSize / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
  
  /// Get max photo size in megabytes
  double get maxPhotoSizeMB => maxPhotoSize / (1024 * 1024);
  
  /// Check if file format is supported
  bool isSupportedFormat(String extension) {
    final normalizedExt = extension.toLowerCase().replaceAll('.', '');
    return supportedFormats.contains(normalizedExt);
  }
  
  /// Factory: Create from JSON
  factory GalleryFeatures.fromJson(Map<String, dynamic> json) {
    return GalleryFeatures(
      allowUserUploads: json['allowUserUploads'] as bool? ?? true,
      allowUserDeletes: json['allowUserDeletes'] as bool? ?? true,
      maxPhotoSize: json['maxPhotoSize'] as int? ?? 10485760, // 10MB default
      supportedFormats: json['supportedFormats'] != null
          ? List<String>.from(json['supportedFormats'] as List)
          : ['jpg', 'jpeg', 'png', 'heic'],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'allowUserUploads': allowUserUploads,
      'allowUserDeletes': allowUserDeletes,
      'maxPhotoSize': maxPhotoSize,
      'supportedFormats': supportedFormats,
    };
  }
  
  /// Create default features
  factory GalleryFeatures.defaultFeatures() {
    return const GalleryFeatures(
      allowUserUploads: true,
      allowUserDeletes: true,
      maxPhotoSize: 10485760, // 10 MB
      supportedFormats: ['jpg', 'jpeg', 'png', 'heic'],
    );
  }
  
  @override
  String toString() {
    return 'GalleryFeatures(uploads: $allowUserUploads, deletes: $allowUserDeletes, maxSize: $maxPhotoSizeFormatted)';
  }
}
