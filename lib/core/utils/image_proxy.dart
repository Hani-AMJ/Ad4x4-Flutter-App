import 'package:flutter/foundation.dart';

/// Image Proxy Utility
/// 
/// Utility for handling image URLs across platforms
/// Backend now serves images via HTTPS - proxy no longer needed!
class ImageProxy {
  /// Check if we're running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Get image URL for display
  /// 
  /// Returns original URL - backend now has CORS headers configured
  static String getProxiedUrl(String? imageUrl) {
    // Return empty string for null/empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // Backend (ap.ad4x4.com, media.ad4x4.com) now supports CORS
    // Return original URLs directly - no proxy needed!
    return imageUrl;
  }
  
}
