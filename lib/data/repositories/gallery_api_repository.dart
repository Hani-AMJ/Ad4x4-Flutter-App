import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    String? sortBy,  // recent-photo, name, newest, oldest, photo-count
    String? tripLevel,  // all, easy, moderate, hard, extreme
    String? filter,  // my, all
  }) async {
    final options = await _getAuthOptions();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (tripLevel != null && tripLevel != 'all') queryParams['trip_level'] = tripLevel;
    if (filter != null && filter != 'all') queryParams['filter'] = filter;
    
    final response = await _apiClient.get(
      GalleryApiEndpoints.galleries,
      queryParameters: queryParams,
      options: options,
    );
    return response.data;
  }

  /// Get gallery detail
  Future<Map<String, dynamic>> getGalleryDetail(String id) async {
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

  /// Rename gallery
  Future<Map<String, dynamic>> renameGallery(String galleryId, String newTitle) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.post(
      '/api/galleries/$galleryId/rename',
      data: {'title': newTitle},
      options: options,
    );
    return response.data;
  }

  /// Delete gallery (soft delete with 30-day restore window)
  Future<void> deleteGallery(String galleryId) async {
    final options = await _getAuthOptions();
    await _apiClient.delete(
      '/api/galleries/$galleryId',
      options: options,
    );
  }

  /// Get gallery statistics
  Future<Map<String, dynamic>> getGalleryStats(String galleryId) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      '/api/galleries/$galleryId/stats',
      options: options,
    );
    return response.data;
  }

  // ============================================================================
  // PHOTOS
  // ============================================================================

  /// Get photos for a gallery
  Future<Map<String, dynamic>> getGalleryPhotos({
    required String galleryId,
    int page = 1,
    int limit = 50,
    String? sortBy,  // newest, oldest, recently-uploaded, camera, file-size
  }) async {
    final options = await _getAuthOptions();
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    
    final response = await _apiClient.get(
      GalleryApiEndpoints.galleryPhotos(galleryId),
      queryParameters: queryParams,
      options: options,
    );
    return response.data;
  }

  /// Search photos
  Future<Map<String, dynamic>> searchPhotos({
    required String query,
    int page = 1,
    int limit = 20,
    String? tripLevel,  // Filter by trip level (easy, moderate, hard, extreme)
    String? camera,     // Filter by camera make/model
  }) async {
    final options = await _getAuthOptions();
    final queryParams = <String, dynamic>{
      'query': query,
      'page': page,
      'limit': limit,
    };
    
    if (tripLevel != null && tripLevel != 'all') {
      queryParams['trip_level'] = tripLevel;
    }
    if (camera != null && camera.isNotEmpty) {
      queryParams['camera'] = camera;
    }
    
    final response = await _apiClient.get(
      GalleryApiEndpoints.photoSearch,
      queryParameters: queryParams,
      options: options,
    );
    return response.data;
  }

  // ============================================================================
  // UPLOAD
  // ============================================================================

  /// Create upload session
  Future<Map<String, dynamic>> createUploadSession({
    required String galleryId,
    int? maxResolution,  // Optional: 1920, 2560, or 3840 pixels
  }) async {
    final options = await _getAuthOptions();
    final data = <String, dynamic>{'gallery_id': galleryId};
    if (maxResolution != null) {
      data['max_resolution'] = maxResolution;
    }
    
    final response = await _apiClient.post(
      GalleryApiEndpoints.uploadSession,
      data: data,
      options: options,
    );
    return response.data;
  }

  /// Upload photo (multipart)
  Future<Map<String, dynamic>> uploadPhoto({
    required String sessionId,
    required String filePath,
    List<int>? fileBytes,  // For web platform
    String? fileName,  // For web platform
    String? caption,
    ProgressCallback? onProgress,
  }) async {
    final options = await _getAuthOptions();
    
    // Web platform: Use bytes directly (no file system access)
    // Mobile platform: Use file path
    final MultipartFile multipartFile;
    if (kIsWeb) {
      if (fileBytes == null) {
        throw Exception('File bytes required for web platform upload');
      }
      multipartFile = MultipartFile.fromBytes(
        fileBytes,
        filename: fileName ?? 'upload.jpg',
      );
    } else {
      multipartFile = await MultipartFile.fromFile(filePath);
    }
    
    final formData = FormData.fromMap({
      'session_id': sessionId,
      'file': multipartFile,
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

  /// Like photo (Gallery API uses favorites)
  Future<void> likePhoto(String photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      GalleryApiEndpoints.photoLike(photoId),
      options: options,
    );
  }

  /// Unlike photo (Gallery API uses favorites)
  Future<void> unlikePhoto(String photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      GalleryApiEndpoints.photoUnlike(photoId),
      options: options,
    );
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.delete(
      '/api/photos/$photoId',
      options: options,
    );
  }

  /// Rotate photo
  Future<void> rotatePhoto(String photoId, {required String direction}) async {
    final options = await _getAuthOptions();
    await _apiClient.patch(
      '/api/photos/$photoId/rotate',
      data: {'direction': direction},  // 'left' or 'right'
      options: options,
    );
  }

  /// Get photo download URL (for downloading to device)
  String getPhotoDownloadUrl(String photoId) {
    return 'https://media.ad4x4.com/api/photos/$photoId/download';
  }

  // ============================================================================
  // FAVORITES
  // ============================================================================

  /// Get user's favorite photos
  Future<Map<String, dynamic>> getFavoritePhotos({
    int page = 1,
    int limit = 50,
    String? tripLevel,  // Filter by trip level
  }) async {
    final options = await _getAuthOptions();
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': (page - 1) * limit,
    };
    
    if (tripLevel != null && tripLevel != 'all') {
      queryParams['trip_level'] = tripLevel;
    }
    
    final response = await _apiClient.get(
      '/api/photos/favorites',  // Correct endpoint
      queryParameters: queryParams,
      options: options,
    );
    return response.data;
  }

  /// Add photo to favorites
  Future<void> addToFavorites(String photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.post(
      '/api/photos/$photoId/favorite',  // Correct endpoint
      options: options,
    );
  }

  /// Remove photo from favorites
  Future<void> removeFromFavorites(String photoId) async {
    final options = await _getAuthOptions();
    await _apiClient.delete(
      '/api/photos/$photoId/favorite',  // Correct endpoint
      options: options,
    );
  }
  
  /// Get random favorite photo
  Future<Map<String, dynamic>> getRandomFavorite() async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      '/api/photos/favorites/random',
      options: options,
    );
    return response.data;
  }

  /// Check if photo is favorited
  Future<bool> isFavorited(String photoId) async {
    final options = await _getAuthOptions();
    final response = await _apiClient.get(
      '/api/favorites/$photoId/status',
      options: options,
    );
    return response.data['is_favorited'] as bool? ?? false;
  }
}
