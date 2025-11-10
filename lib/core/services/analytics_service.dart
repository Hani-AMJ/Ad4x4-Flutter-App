import 'package:flutter/foundation.dart';

/// Analytics Service for tracking user events
/// TODO: Integrate with Firebase Analytics or your analytics provider
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isEnabled = true;

  /// Initialize analytics
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('📊 Analytics Service Initialized');
    }
    // TODO: Initialize Firebase Analytics
    // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }

  /// Enable/disable analytics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) {
      debugPrint('📊 Analytics ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isEnabled) return;

    if (kDebugMode) {
      debugPrint('📊 Analytics Event: $name');
      if (parameters != null && parameters.isNotEmpty) {
        debugPrint('   Parameters: $parameters');
      }
    }

    // TODO: Send to analytics provider
    // await FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: parameters,
    // );
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) return;

    if (kDebugMode) {
      debugPrint('📊 Screen View: $screenName');
    }

    // TODO: Send to analytics provider
    // await FirebaseAnalytics.instance.logScreenView(
    //   screenName: screenName,
    //   screenClass: screenClass,
    // );
  }

  /// Log user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isEnabled) return;

    if (kDebugMode) {
      debugPrint('📊 User Property: $name = $value');
    }

    // TODO: Send to analytics provider
    // await FirebaseAnalytics.instance.setUserProperty(
    //   name: name,
    //   value: value,
    // );
  }

  // Predefined event loggers for common actions

  /// Log trip view
  Future<void> logTripView(String tripId, String tripTitle) async {
    await logEvent(
      name: 'trip_view',
      parameters: {
        'trip_id': tripId,
        'trip_title': tripTitle,
      },
    );
  }

  /// Log trip join
  Future<void> logTripJoin(String tripId, String tripTitle) async {
    await logEvent(
      name: 'trip_join',
      parameters: {
        'trip_id': tripId,
        'trip_title': tripTitle,
      },
    );
  }

  /// Log trip create
  Future<void> logTripCreate(String tripTitle, String difficulty) async {
    await logEvent(
      name: 'trip_create',
      parameters: {
        'trip_title': tripTitle,
        'difficulty': difficulty,
      },
    );
  }

  /// Log trip edit
  Future<void> logTripEdit(String tripId) async {
    await logEvent(
      name: 'trip_edit',
      parameters: {'trip_id': tripId},
    );
  }

  /// Log search
  Future<void> logSearch(String searchQuery, int resultCount) async {
    await logEvent(
      name: 'search',
      parameters: {
        'search_query': searchQuery,
        'result_count': resultCount,
      },
    );
  }

  /// Log member profile view
  Future<void> logMemberView(String memberId) async {
    await logEvent(
      name: 'member_view',
      parameters: {'member_id': memberId},
    );
  }

  /// Log gallery view
  Future<void> logGalleryView(String albumId, String albumTitle) async {
    await logEvent(
      name: 'gallery_view',
      parameters: {
        'album_id': albumId,
        'album_title': albumTitle,
      },
    );
  }

  /// Log photo upload
  Future<void> logPhotoUpload(int photoCount) async {
    await logEvent(
      name: 'photo_upload',
      parameters: {'photo_count': photoCount},
    );
  }

  /// Log login
  Future<void> logLogin(String method) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  /// Log logout
  Future<void> logLogout() async {
    await logEvent(name: 'logout');
  }

  /// Log registration
  Future<void> logSignup(String method) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method},
    );
  }

  /// Log share
  Future<void> logShare(String contentType, String contentId) async {
    await logEvent(
      name: 'share',
      parameters: {
        'content_type': contentType,
        'content_id': contentId,
      },
    );
  }

  /// Log error
  Future<void> logError(String errorMessage, String? stackTrace) async {
    await logEvent(
      name: 'error',
      parameters: {
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }
}
