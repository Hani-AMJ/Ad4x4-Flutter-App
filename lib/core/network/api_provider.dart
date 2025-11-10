import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Provider for main API client (Django backend)
/// Now uses SharedPreferences directly - no complex storage abstraction
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiClient.mainApiUrl,
  );
});

/// Provider for gallery API client (Node.js backend)
final galleryApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ApiClient.galleryApiUrl,
  );
});
