import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

/// Activity item model for admin activity feed
class AdminActivity {
  final String id;
  final String type;
  final String description;
  final String username;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AdminActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.username,
    required this.timestamp,
    this.metadata,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    return AdminActivity(
      id: json['id']?.toString() ?? '0',
      type: json['type']?.toString() ?? 'unknown',
      description: json['description']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown User',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get a user-friendly icon for this activity type
  String get icon {
    switch (type.toLowerCase()) {
      case 'photo_upload':
      case 'upload':
        return '📸';
      case 'gallery_create':
      case 'create':
        return '📁';
      case 'photo_delete':
      case 'delete':
        return '🗑️';
      case 'gallery_delete':
        return '📂';
      case 'like':
        return '❤️';
      case 'favorite':
        return '⭐';
      case 'rotation':
      case 'rotate':
        return '🔄';
      case 'rename':
        return '✏️';
      case 'maintenance':
        return '🔧';
      default:
        return '📋';
    }
  }

  /// Get a color for this activity type
  String get colorHex {
    switch (type.toLowerCase()) {
      case 'photo_upload':
      case 'upload':
      case 'gallery_create':
      case 'create':
        return '#4CAF50'; // Green
      case 'photo_delete':
      case 'delete':
      case 'gallery_delete':
        return '#F44336'; // Red
      case 'like':
      case 'favorite':
        return '#E91E63'; // Pink
      case 'rotation':
      case 'rotate':
      case 'rename':
        return '#2196F3'; // Blue
      case 'maintenance':
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E'; // Gray
    }
  }

  /// Format timestamp as relative time (e.g., "2 hours ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      // Format as date if older than 7 days
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// State for gallery admin activity
class GalleryAdminActivityState {
  final List<AdminActivity> activities;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final String? filterType;

  GalleryAdminActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.filterType,
  });

  GalleryAdminActivityState copyWith({
    List<AdminActivity>? activities,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    String? filterType,
  }) {
    return GalleryAdminActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filterType: filterType ?? this.filterType,
    );
  }
}

/// Notifier for gallery admin activity management
class GalleryAdminActivityNotifier
    extends StateNotifier<GalleryAdminActivityState> {
  final Ref _ref;

  GalleryAdminActivityNotifier(this._ref) : super(GalleryAdminActivityState());

  /// Load initial activity feed
  Future<void> loadActivities({String? filterType}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterType: filterType,
      currentPage: 1,
    );

    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      final response = await repository.getAdminActivity(limit: 50);

      // Handle multiple response formats
      List<dynamic> activitiesData;
      if (response.containsKey('results')) {
        activitiesData = response['results'] as List<dynamic>? ?? [];
      } else if (response.containsKey('activities')) {
        activitiesData = response['activities'] as List<dynamic>? ?? [];
      } else {
        activitiesData = []; // Empty list if no recognized format
      }

      final activities = activitiesData
          .map((json) => AdminActivity.fromJson(json as Map<String, dynamic>))
          .toList();

      final totalCount = response['count'] as int? ?? activities.length;
      final hasMore = activities.length < totalCount;

      state = state.copyWith(
        activities: activities,
        isLoading: false,
        hasMore: hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load activity: ${e.toString()}',
      );
    }
  }

  /// Load more activities (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      // Note: API doesn't support pagination yet, so this will fetch same data
      final repository = _ref.read(galleryApiRepositoryProvider);
      final response = await repository.getAdminActivity(limit: 50);

      final newActivities =
          (response['results'] as List<dynamic>?)
              ?.map(
                (json) => AdminActivity.fromJson(json as Map<String, dynamic>),
              )
              .toList() ??
          [];

      final totalCount = response['count'] as int? ?? 0;
      final allActivities = [...state.activities, ...newActivities];
      final hasMore = allActivities.length < totalCount;

      state = state.copyWith(
        activities: allActivities,
        isLoading: false,
        hasMore: hasMore,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more activities: ${e.toString()}',
      );
    }
  }

  /// Refresh activities (pull to refresh)
  Future<void> refresh() async {
    await loadActivities(filterType: state.filterType);
  }

  /// Filter activities by type
  Future<void> filterByType(String? type) async {
    await loadActivities(filterType: type);
  }

  /// Clear filter
  Future<void> clearFilter() async {
    await loadActivities(filterType: null);
  }
}

/// Provider for gallery admin activity feed
final galleryAdminActivityProvider =
    StateNotifierProvider<
      GalleryAdminActivityNotifier,
      GalleryAdminActivityState
    >((ref) {
      return GalleryAdminActivityNotifier(ref);
    });
