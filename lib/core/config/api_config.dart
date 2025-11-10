/// API Configuration for AD4x4 App
/// 
/// Manages base URLs and endpoints for Main API and Gallery API
class ApiConfig {
  // Base URLs
  static const String mainApiBaseUrl = String.fromEnvironment(
    'MAIN_API_BASE',
    defaultValue: 'https://ap.ad4x4.com',
  );

  static const String galleryApiBaseUrl = String.fromEnvironment(
    'GALLERY_API_BASE',
    defaultValue: 'https://media.ad4x4.com',
  );

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Request retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Upload limits
  static const int maxUploadBatchSizeMB = 95;
  static const int maxPhotoSizeMB = 10;

  // Cache TTLs
  static const Duration tripsCacheTTL = Duration(minutes: 5);
  static const Duration gallerySpotlightCacheTTL = Duration(minutes: 10);
  static const Duration levelsCacheTTL = Duration(hours: 24);
  static const Duration profileCacheTTL = Duration(minutes: 30);

  // Feature flags (for development)
  static const bool enableMockData = bool.fromEnvironment(
    'ENABLE_MOCK_DATA',
    defaultValue: true, // Default to true for Phase 2 development
  );

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_API_LOGGING',
    defaultValue: true,
  );

  // API version headers
  static const String apiVersion = 'v1';
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
