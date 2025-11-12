import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/main_api_repository.dart';
import '../../data/repositories/gallery_api_repository.dart';
import '../network/api_client.dart';
import '../services/image_upload_service.dart';
import '../config/api_config.dart';

/// Main API Client Provider
final mainApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConfig.mainApiBaseUrl);
});

/// Gallery API Client Provider
final galleryApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConfig.galleryApiBaseUrl);
});

/// Main API Repository Provider
final mainApiRepositoryProvider = Provider<MainApiRepository>((ref) {
  final apiClient = ref.watch(mainApiClientProvider);
  return MainApiRepository(apiClient: apiClient);
});

/// Gallery API Repository Provider
final galleryApiRepositoryProvider = Provider<GalleryApiRepository>((ref) {
  final apiClient = ref.watch(galleryApiClientProvider);
  return GalleryApiRepository(apiClient: apiClient);
});

/// Image Upload Service Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final apiClient = ref.watch(mainApiClientProvider);
  return ImageUploadService(apiClient.dio);
});
