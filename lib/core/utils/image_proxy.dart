import 'package:flutter/foundation.dart';

/// Image Proxy Utility
/// 
/// Handles CORS issues with images on web platform
/// Uses backend imageproxy endpoint: https://ap.ad4x4.com/imageproxy?url=...
class ImageProxy {
  /// Backend proxy endpoint (use HTTP to avoid CORS preflight)
  static const String _proxyEndpoint = 'http://ap.ad4x4.com/imageproxy';
  
  /// Check if we're running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Get image URL for display with CORS workaround
  /// 
  /// On web platform, routes through backend proxy to bypass CORS restrictions
  /// On mobile, returns original URL (no CORS issues)
  static String getProxiedUrl(String? imageUrl) {
    // Return empty string for null/empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // Make a local non-nullable copy
    String url = imageUrl;
    
    // Debug logging in development
    if (kDebugMode) {
      print('[ImageProxy] Input URL: $url');
    }
    
    // FIX: If sandbox URL, extract the actual path and reconstruct
    if (url.contains('sandbox.novita.ai')) {
      try {
        final uri = Uri.parse(url);
        final path = uri.path;
        // Check if path starts with /uploads (actual image path)
        if (path.startsWith('/uploads')) {
          url = 'http://ap.ad4x4.com$path';
          if (kDebugMode) {
            print('[ImageProxy] Reconstructed from sandbox URL: $url');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[ImageProxy] Error parsing sandbox URL: $e');
        }
      }
    }
    
    // Skip if already proxied
    if (url.contains('/imageproxy') || url.contains('localhost')) {
      if (kDebugMode) {
        print('[ImageProxy] Skipping (already proxied): $url');
      }
      return url;
    }
    
    // On web platform, use backend proxy for external images
    if (kIsWeb) {
      // Only proxy actual image URLs from ad4x4.com domains
      if ((url.startsWith('http://') || url.startsWith('https://')) &&
          (url.contains('media.ad4x4.com') || 
           url.contains('ap.ad4x4.com/uploads'))) {
        // Route through backend imageproxy
        final proxiedUrl = '$_proxyEndpoint?url=${Uri.encodeComponent(url)}';
        if (kDebugMode) {
          print('[ImageProxy] Proxying: $url');
          print('[ImageProxy] Output: $proxiedUrl');
        }
        return proxiedUrl;
      }
    }
    
    // Return original URL for mobile or non-proxied URLs
    if (kDebugMode) {
      print('[ImageProxy] Returning original: $url');
    }
    return url;
  }
  
  /// Get original URL without proxy (for downloads, sharing, etc.)
  static String getOriginalUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    return imageUrl;
  }
}
