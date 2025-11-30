import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/trip_media_model.dart';
import '../../../../core/providers/repository_providers.dart';

// ============================================================================
// TRIP MEDIA STATE
// ============================================================================

/// Trip Media State - Manages list of media items with pagination and filters
class TripMediaState {
  final List<TripMedia> media;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int? tripFilter;
  final bool? approvedFilter; // null = all, true = approved, false = pending

  const TripMediaState({
    this.media = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.tripFilter,
    this.approvedFilter,
  });

  TripMediaState copyWith({
    List<TripMedia>? media,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? tripFilter,
    bool? approvedFilter,
  }) {
    return TripMediaState(
      media: media ?? this.media,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tripFilter: tripFilter ?? this.tripFilter,
      approvedFilter: approvedFilter ?? this.approvedFilter,
    );
  }

  /// Get only pending media
  List<TripMedia> get pendingMedia => media.where((m) => m.isPending).toList();

  /// Get only approved media
  List<TripMedia> get approvedMedia => media.where((m) => m.approved).toList();

  /// Get pending count
  int get pendingCount => media.where((m) => m.isPending).length;
}

/// Trip Media Notifier
class TripMediaNotifier extends StateNotifier<TripMediaState> {
  final Ref _ref;

  TripMediaNotifier(this._ref) : super(const TripMediaState());

  /// Load trip media
  Future<void> loadMedia({
    int? tripId,
    bool? approvedOnly,
    int page = 1,
  }) async {
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        tripFilter: tripId,
        approvedFilter: approvedOnly,
      );
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getTripMedia(
        tripId: tripId ?? 0,
        page: page,
        pageSize: 20,
        approvedOnly: approvedOnly,
      );

      final mediaResponse = TripMediaResponse.fromJson(response);

      state = state.copyWith(
        media: page == 1
            ? mediaResponse.results
            : [...state.media, ...mediaResponse.results],
        totalCount: mediaResponse.count,
        currentPage: page,
        hasMore: mediaResponse.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more media (pagination)
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadMedia(
        tripId: state.tripFilter,
        approvedOnly: state.approvedFilter,
        page: state.currentPage + 1,
      );
    }
  }

  /// Refresh media
  Future<void> refresh() async {
    await loadMedia(
      tripId: state.tripFilter,
      approvedOnly: state.approvedFilter,
      page: 1,
    );
  }

  /// Clear filters
  void clearFilters() {
    state = const TripMediaState();
  }
}

/// Trip Media Provider
final tripMediaProvider =
    StateNotifierProvider<TripMediaNotifier, TripMediaState>((ref) {
      return TripMediaNotifier(ref);
    });

// ============================================================================
// PENDING MEDIA STATE
// ============================================================================

/// Pending Media State - Specifically for moderation queue
class PendingMediaState {
  final List<TripMedia> pendingMedia;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const PendingMediaState({
    this.pendingMedia = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  PendingMediaState copyWith({
    List<TripMedia>? pendingMedia,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PendingMediaState(
      pendingMedia: pendingMedia ?? this.pendingMedia,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Pending Media Notifier
class PendingMediaNotifier extends StateNotifier<PendingMediaState> {
  final Ref _ref;

  PendingMediaNotifier(this._ref) : super(const PendingMediaState());

  /// Load pending media
  Future<void> loadPending({int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getPendingPhotos(
        page: page,
        pageSize: 20,
      );

      final mediaResponse = TripMediaResponse.fromJson(response);

      state = state.copyWith(
        pendingMedia: page == 1
            ? mediaResponse.results
            : [...state.pendingMedia, ...mediaResponse.results],
        totalCount: mediaResponse.count,
        currentPage: page,
        hasMore: mediaResponse.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more pending media
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadPending(page: state.currentPage + 1);
    }
  }

  /// Refresh pending media
  Future<void> refresh() async {
    await loadPending(page: 1);
  }

  /// Remove media from pending list (after moderation)
  void removeMedia(int mediaId) {
    state = state.copyWith(
      pendingMedia: state.pendingMedia.where((m) => m.id != mediaId).toList(),
      totalCount: state.totalCount - 1,
    );
  }
}

/// Pending Media Provider
final pendingMediaProvider =
    StateNotifierProvider<PendingMediaNotifier, PendingMediaState>((ref) {
      return PendingMediaNotifier(ref);
    });

// ============================================================================
// MEDIA UPLOAD STATE
// ============================================================================

/// Media Upload State - Tracks upload progress
class MediaUploadState {
  final Map<String, MediaUploadProgress> uploads; // uploadId -> progress
  final bool isUploading;
  final String? error;

  const MediaUploadState({
    this.uploads = const {},
    this.isUploading = false,
    this.error,
  });

  MediaUploadState copyWith({
    Map<String, MediaUploadProgress>? uploads,
    bool? isUploading,
    String? error,
  }) {
    return MediaUploadState(
      uploads: uploads ?? this.uploads,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }

  /// Get active uploads
  List<MediaUploadProgress> get activeUploads =>
      uploads.values.where((u) => u.isUploading).toList();

  /// Get completed uploads
  List<MediaUploadProgress> get completedUploads =>
      uploads.values.where((u) => u.isComplete).toList();

  /// Get failed uploads
  List<MediaUploadProgress> get failedUploads =>
      uploads.values.where((u) => u.isFailed).toList();
}

/// Media Upload Notifier
class MediaUploadNotifier extends StateNotifier<MediaUploadState> {
  final Ref _ref;

  MediaUploadNotifier(this._ref) : super(const MediaUploadState());

  /// Start upload
  Future<void> uploadPhoto({
    required int tripId,
    required String filePath,
    String? caption,
  }) async {
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add upload to state
    final newUpload = MediaUploadProgress(
      uploadId: uploadId,
      tripId: tripId,
      progress: 0.0,
      status: UploadStatus.uploading,
    );

    state = state.copyWith(
      uploads: {...state.uploads, uploadId: newUpload},
      isUploading: true,
    );

    try {
      final repository = _ref.read(mainApiRepositoryProvider);

      // TODO: Add progress tracking with Dio
      final response = await repository.uploadTripPhoto(
        tripId: tripId,
        filePath: filePath,
        caption: caption,
      );

      final uploadedMedia = TripMedia.fromJson(response);

      // Update upload as complete
      state = state.copyWith(
        uploads: {
          ...state.uploads,
          uploadId: newUpload.copyWith(
            progress: 1.0,
            status: UploadStatus.completed,
            uploadedMedia: uploadedMedia,
          ),
        },
        isUploading: state.activeUploads.length > 1,
      );

      // Refresh media lists
      _ref.read(tripMediaProvider.notifier).refresh();
    } catch (e) {
      // Update upload as failed
      state = state.copyWith(
        uploads: {
          ...state.uploads,
          uploadId: newUpload.copyWith(
            status: UploadStatus.failed,
            errorMessage: e.toString(),
          ),
        },
        isUploading: state.activeUploads.length > 1,
        error: e.toString(),
      );
    }
  }

  /// Clear completed uploads
  void clearCompleted() {
    final activeUploads = Map<String, MediaUploadProgress>.fromEntries(
      state.uploads.entries.where((e) => !e.value.isComplete),
    );
    state = state.copyWith(uploads: activeUploads);
  }

  /// Clear all uploads
  void clearAll() {
    state = const MediaUploadState();
  }
}

/// Media Upload Provider
final mediaUploadProvider =
    StateNotifierProvider<MediaUploadNotifier, MediaUploadState>((ref) {
      return MediaUploadNotifier(ref);
    });

// ============================================================================
// MEDIA MODERATION ACTIONS
// ============================================================================

/// Media Moderation Actions Notifier
class MediaModerationActionsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  MediaModerationActionsNotifier(this._ref) : super(false);

  /// Approve photo
  Future<void> approvePhoto(int photoId) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.moderatePhoto(photoId: photoId, approved: true);

      // Update pending media list
      _ref.read(pendingMediaProvider.notifier).removeMedia(photoId);

      // Refresh main media list
      _ref.read(tripMediaProvider.notifier).refresh();

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Reject photo
  Future<void> rejectPhoto(int photoId, {String? reason}) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.moderatePhoto(
        photoId: photoId,
        approved: false,
        reason: reason,
      );

      // Update pending media list
      _ref.read(pendingMediaProvider.notifier).removeMedia(photoId);

      // Refresh main media list
      _ref.read(tripMediaProvider.notifier).refresh();

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Delete photo
  Future<void> deletePhoto(int photoId) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.deleteTripPhoto(photoId);

      // Refresh both lists
      _ref.read(pendingMediaProvider.notifier).refresh();
      _ref.read(tripMediaProvider.notifier).refresh();

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

/// Media Moderation Actions Provider
final mediaModerationActionsProvider =
    StateNotifierProvider<MediaModerationActionsNotifier, bool>((ref) {
      return MediaModerationActionsNotifier(ref);
    });

// ============================================================================
// TRIP MEDIA GALLERY PROVIDER (for specific trip)
// ============================================================================

/// Trip Media Gallery Provider - Family provider for individual trip galleries
final tripMediaGalleryProvider = FutureProvider.family<TripMediaGallery, int>((
  ref,
  tripId,
) async {
  final repository = ref.read(mainApiRepositoryProvider);
  final response = await repository.getTripMediaGallery(tripId);
  return TripMediaGallery.fromJson(response);
});
