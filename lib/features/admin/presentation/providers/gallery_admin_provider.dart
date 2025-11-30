import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

// ============================================================================
// GALLERY ADMIN STATS STATE
// ============================================================================

/// Gallery Admin Stats - System statistics for board members
class GalleryAdminStats {
  final int totalPhotos;
  final int totalGalleries;
  final int totalUsers;
  final int totalFavorites;
  final double storageMb;

  const GalleryAdminStats({
    this.totalPhotos = 0,
    this.totalGalleries = 0,
    this.totalUsers = 0,
    this.totalFavorites = 0,
    this.storageMb = 0.0,
  });

  factory GalleryAdminStats.fromJson(Map<String, dynamic> json) {
    return GalleryAdminStats(
      totalPhotos: json['total_photos'] as int? ?? 0,
      totalGalleries: json['total_galleries'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      totalFavorites: json['total_favorites'] as int? ?? 0,
      storageMb: (json['storage_used_mb'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get storageFormatted {
    if (storageMb < 1024) {
      return '${storageMb.toStringAsFixed(1)} MB';
    } else {
      return '${(storageMb / 1024).toStringAsFixed(2)} GB';
    }
  }
}

/// Gallery Admin Stats State
class GalleryAdminStatsState {
  final GalleryAdminStats? stats;
  final bool isLoading;
  final String? error;

  const GalleryAdminStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  GalleryAdminStatsState copyWith({
    GalleryAdminStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return GalleryAdminStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Gallery Admin Stats Notifier
class GalleryAdminStatsNotifier extends StateNotifier<GalleryAdminStatsState> {
  final Ref _ref;

  GalleryAdminStatsNotifier(this._ref) : super(const GalleryAdminStatsState());

  /// Load admin stats
  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      final response = await repository.getAdminStats();

      // Handle both response formats: {success: true, stats: {...}} or direct stats {...}
      Map<String, dynamic> statsData;
      if (response.containsKey('stats')) {
        statsData = response['stats'] as Map<String, dynamic>;
      } else {
        statsData = response; // API returns stats directly
      }

      final stats = GalleryAdminStats.fromJson(statsData);
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh stats
  Future<void> refresh() async {
    await loadStats();
  }
}

/// Gallery Admin Stats Provider
final galleryAdminStatsProvider =
    StateNotifierProvider<GalleryAdminStatsNotifier, GalleryAdminStatsState>(
      (ref) => GalleryAdminStatsNotifier(ref),
    );

// ============================================================================
// NOTE: Gallery Admin Activity provider has been moved to:
// lib/features/admin/presentation/providers/gallery_admin_activity_provider.dart
// ============================================================================

// ============================================================================
// GALLERY ADMIN AUDIT LOGS STATE
// ============================================================================

/// Audit Log Entry
class AuditLogEntry {
  final String id;
  final String username;
  final String action;
  final String details;
  final DateTime timestamp;

  const AuditLogEntry({
    required this.id,
    required this.username,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      username: json['username'] as String,
      action: json['action'] as String,
      details: json['details'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Gallery Admin Audit Logs State
class GalleryAdminAuditLogsState {
  final List<AuditLogEntry> logs;
  final bool isLoading;
  final String? error;

  const GalleryAdminAuditLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  GalleryAdminAuditLogsState copyWith({
    List<AuditLogEntry>? logs,
    bool? isLoading,
    String? error,
  }) {
    return GalleryAdminAuditLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Gallery Admin Audit Logs Notifier
class GalleryAdminAuditLogsNotifier
    extends StateNotifier<GalleryAdminAuditLogsState> {
  final Ref _ref;

  GalleryAdminAuditLogsNotifier(this._ref)
    : super(const GalleryAdminAuditLogsState());

  /// Load audit logs
  Future<void> loadLogs({int limit = 100}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(galleryApiRepositoryProvider);
      final response = await repository.getAdminLogs(limit: limit);

      if (response['success'] == true) {
        final logsList = response['logs'] as List<dynamic>? ?? [];
        final logs = logsList
            .map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(logs: logs, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load logs');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh logs
  Future<void> refresh({int limit = 100}) async {
    await loadLogs(limit: limit);
  }
}

/// Gallery Admin Audit Logs Provider
final galleryAdminAuditLogsProvider =
    StateNotifierProvider<
      GalleryAdminAuditLogsNotifier,
      GalleryAdminAuditLogsState
    >((ref) => GalleryAdminAuditLogsNotifier(ref));
