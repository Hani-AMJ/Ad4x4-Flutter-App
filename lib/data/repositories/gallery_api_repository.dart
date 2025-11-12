import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/gallery_api_endpoints.dart';
import '../../core/providers/gallery_auth_provider.dart';

/// Gallery API Repository
/// 
/// Handles all API calls to the Gallery API (Node.js media service)
/// Automatically includes Gallery API authentication token in requests
class GalleryApiRepository {
  final ApiClient _apiClient;

  GalleryApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: ApiConfig.galleryApiBaseUrl);

  /// Get request options with Gallery API auth token
  Future<Options> _getAuthOptions() async {
    final token = await getGalleryAuthToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // ============================================================================
  // GALLERIES (ALBUMS)
  // ============================================================================

  /// Get galleries list
  Future<Map<String, dynamic>> getGalleries({
    int page = 1,
    int limit = 8,
  }) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      GalleryApiEndpoints.galleries,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      options: options,
    );
    return response.data;
  }

  /// Get gallery detail
  Future<Map<String, dynamic>> getGalleryDetail(int id) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      GalleryApiEndpoints.galleryDetail(id),
      options: options,
    );
    return response.data;
  }

  /// Create gallery (server-to-server, typically done by Main API)
  Future<Map<String, dynamic>> createGallery(Map<String, dynamic> data) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.post(
      GalleryApiEndpoints.galleries,
      data: data,
      options: options,
    );
    return response.data;
  }

  // ============================================================================
  // PHOTOS
  // ============================================================================

  /// Get photos for a gallery
  Future<Map<String, dynamic>> getGalleryPhotos({
    required int galleryId,
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      GalleryApiEndpoints.galleryPhotos(galleryId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      options: options,
    );
    return response.data;
  }

  /// Search photos
  Future<Map<String, dynamic>> searchPhotos({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      GalleryApiEndpoints.photoSearch,
      queryParameters: {
        'query': query,
        'page': page,
        'limit': limit,
      },
      options: options,
    );
    return response.data;
  }

  // ============================================================================
  // UPLOAD
  // ============================================================================

  /// Create upload session
  Future<Map<String, dynamic>> createUploadSession({
    required int galleryId,
  }) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.post(
      GalleryApiEndpoints.uploadSession,
      data: {'gallery_id': galleryId},
      options: options,
    );
    return response.data;
  }

  /// Upload photo (multipart)
  Future<Map<String, dynamic>> uploadPhoto({
    required String sessionId,
    required String filePath,
    String? caption,
    ProgressCallback? onProgress,
  }) async {
    final options = await _getAuthOptions();
    final formData = FormData.fromMap({
      'session_id': sessionId,
      'file': await MultipartFile.fromFile(filePath),
      if (caption != null) 'caption': caption,
    });

    // Use Dio directly for upload progress callback
    final dio = _apiClient.dio;
    final response = await dio.post(
      GalleryApiEndpoints.upload,
      data: formData,
      options: options,
      onSendProgress: onProgress,
    );
    return response.data;
  }

  // ============================================================================
  // PHOTO ACTIONS
  // ============================================================================

  /// Like photo
  Future<void> likePhoto(int photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      GalleryApiEndpoints.photoLike(photoId),
      options: options,
    );
  }

  /// Unlike photo
  Future<void> unlikePhoto(int photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      GalleryApiEndpoints.photoUnlike(photoId),
      options: options,
    );
  }

  // ============================================================================
  // FAVORITES
  // ============================================================================

  /// Get user's favorite photos
  Future<Map<String, dynamic>> getFavoritePhotos({
    int page = 1,
    int limit = 50,
  }) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      '/api/favorites',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      options: options,
    );
    return response.data;
  }

  /// Add photo to favorites
  Future<void> addToFavorites(int photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      '/api/favorites/$photoId',
      options: options,
    );
  }

  /// Remove photo from favorites
  Future<void> removeFromFavorites(int photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.delete(
      '/api/favorites/$photoId',
      options: options,
    );
  }

  /// Check if photo is favorited
  Future<bool> isFavorited(int photoId) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      '/api/favorites/$photoId/status',
      options: options,
    );
    return response.data['is_favorited'] as bool? ?? false;
  }
}
