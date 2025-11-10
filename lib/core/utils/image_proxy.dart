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
  /// Proxies images to work around CORS restrictions on web platform
  /// Backend serves HTTPS but needs CORS headers configured
  static String getProxiedUrl(String? imageUrl) {
    // Return empty string for null/empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // On native platforms, return original URL
    if (!isWeb) {
      return imageUrl;
    }
    
    // On web, proxy all backend images to avoid CORS issues
    // This is temporary until backend adds CORS headers
    if (imageUrl.contains('ap.ad4x4.com') || imageUrl.contains('media.ad4x4.com')) {
      final uri = Uri.base;
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      final encodedUrl = Uri.encodeComponent(imageUrl);
      return '$origin/imageproxy?url=$encodedUrl';
    }
    
    // Other URLs (CDN, etc.) return as-is
    return imageUrl;
  }
  
}
