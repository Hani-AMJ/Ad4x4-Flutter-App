import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

/// Photo item for content manager
class PhotoItem {
  final String id;
  final String filename;
  final String? galleryName;
  final String? galleryId;
  final String thumbnailUrl;
  final String fullUrl;
  final DateTime uploadedAt;

  PhotoItem({
    required this.id,
    required this.filename,
    this.galleryName,
    this.galleryId,
    required this.thumbnailUrl,
    required this.fullUrl,
    required this.uploadedAt,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    return PhotoItem(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] as String? ?? 'unknown.jpg',
      galleryName: json['gallery_name'] as String?,
      galleryId: json['gallery_id']?.toString(),
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      fullUrl: json['url'] as String? ?? json['file_url'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Gallery item for content manager
class GalleryItem {
  final String id;
  final String name;
  final int photoCount;
  final DateTime createdAt;
  final List<String> samplePhotos;

  GalleryItem({
    required this.id,
    required this.name,
    required this.photoCount,
    required this.createdAt,
    required this.samplePhotos,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed Gallery',
      photoCount: json['photo_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      samplePhotos:
          (json['sample_photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// State for recent photos
class RecentPhotosState {
  final List<PhotoItem> photos;
  final bool isLoading;
  final String? error;

  const RecentPhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.error,
  });

  RecentPhotosState copyWith({
    List<PhotoItem>? photos,
    bool? isLoading,
    String? error,
  }) {
    return RecentPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for recent photos
class RecentPhotosNotifier extends StateNotifier<RecentPhotosState> {
  final Ref _ref;

  RecentPhotosNotifier(this._ref) : super(const RecentPhotosState());

  /// Load recent photos
  Future<void> loadPhotos({int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(galleryApiRepositoryProvider);

      // Get all galleries first, then get photos from each
      final galleriesResponse = await repository.getGalleries(
        page: 1,
        limit: 10,
        sortBy: 'newest',
      );

      final galleries =
          (galleriesResponse['results'] as List<dynamic>?)
              ?.map((json) => json as Map<String, dynamic>)
              .toList() ??
          [];

      // Collect photos from galleries
      final List<PhotoItem> allPhotos = [];

      for (var gallery in galleries.take(5)) {
        try {
          final galleryId = gallery['id']?.toString();
          if (galleryId == null) continue;

          final photosResponse = await repository.getGalleryPhotos(
            galleryId: galleryId,
            page: 1,
            limit: 10,
          );

          final photos =
              (photosResponse['results'] as List<dynamic>?)?.map((json) {
                final photoJson = json as Map<String, dynamic>;
                // Add gallery info to photo
                photoJson['gallery_name'] = gallery['name'];
                photoJson['gallery_id'] = galleryId;
                return PhotoItem.fromJson(photoJson);
              }).toList() ??
              [];

          allPhotos.addAll(photos);

          if (allPhotos.length >= limit) break;
        } catch (e) {
          // Skip failed galleries
          continue;
        }
      }

      // Sort by upload date and take limit
      allPhotos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      final recentPhotos = allPhotos.take(limit).toList();

      state = state.copyWith(photos: recentPhotos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load photos: ${e.toString()}',
      );
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      await repository.deletePhoto(photoId);

      // Remove from local state
      final updatedPhotos = state.photos.where((p) => p.id != photoId).toList();
      state = state.copyWith(photos: updatedPhotos);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete photo: ${e.toString()}');
    }
  }

  /// Refresh photos
  Future<void> refresh() async {
    await loadPhotos();
  }
}

/// Provider for recent photos
final recentPhotosProvider =
    StateNotifierProvider<RecentPhotosNotifier, RecentPhotosState>((ref) {
      return RecentPhotosNotifier(ref);
    });

/// State for galleries list
class GalleriesListState {
  final List<GalleryItem> galleries;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const GalleriesListState({
    this.galleries = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  GalleriesListState copyWith({
    List<GalleryItem>? galleries,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return GalleriesListState(
      galleries: galleries ?? this.galleries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier for galleries list
class GalleriesListNotifier extends StateNotifier<GalleriesListState> {
  final Ref _ref;

  GalleriesListNotifier(this._ref) : super(const GalleriesListState());

  /// Load galleries
  Future<void> loadGalleries({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      final response = await repository.getGalleries(
        page: page,
        limit: limit,
        sortBy: 'newest',
      );

      final galleriesData =
          (response['results'] as List<dynamic>?)
              ?.map(
                (json) => GalleryItem.fromJson(json as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final totalCount = response['count'] as int? ?? 0;
      final hasMore = galleriesData.length < totalCount;

      if (page == 1) {
        state = state.copyWith(
          galleries: galleriesData,
          isLoading: false,
          hasMore: hasMore,
          currentPage: page,
        );
      } else {
        state = state.copyWith(
          galleries: [...state.galleries, ...galleriesData],
          isLoading: false,
          hasMore: hasMore,
          currentPage: page,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load galleries: ${e.toString()}',
      );
    }
  }

  /// Load more galleries (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await loadGalleries(page: state.currentPage + 1);
  }

  /// Delete a gallery
  Future<void> deleteGallery(String galleryId) async {
    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      await repository.deleteGallery(galleryId);

      // Remove from local state
      final updatedGalleries = state.galleries
          .where((g) => g.id != galleryId)
          .toList();
      state = state.copyWith(galleries: updatedGalleries);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete gallery: ${e.toString()}',
      );
    }
  }

  /// Refresh galleries
  Future<void> refresh() async {
    await loadGalleries(page: 1);
  }
}

/// Provider for galleries list
final galleriesListProvider =
    StateNotifierProvider<GalleriesListNotifier, GalleriesListState>((ref) {
      return GalleriesListNotifier(ref);
    });
