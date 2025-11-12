import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_trip_search_criteria.freezed.dart';

/// Admin Trip Search Criteria
/// 
/// Holds wizard state and search parameters for admin trips search
@freezed
class AdminTripSearchCriteria with _$AdminTripSearchCriteria {
  const factory AdminTripSearchCriteria({
    /// Trip type filter (upcoming, pending, completed, all)
    TripType? tripType,
    
    /// Selected level IDs (multi-select)
    @Default([]) List<int> levelIds,
    
    /// Trip lead user ID filter (single user only - API limitation)
    int? leadUserId,
    
    /// Meeting point area filter (single area only - API limitation)
    String? meetingPointArea,
    
    /// Current wizard step (0=landing, 1-4=wizard steps, 5=results)
    @Default(0) int currentStep,
    
    /// Search results (populated after search execution)
    @Default(null) List<dynamic>? searchResults,
    
    /// Loading state for search
    @Default(false) bool isSearching,
    
    /// Error message if search failed
    @Default(null) String? searchError,
  }) = _AdminTripSearchCriteria;

  const AdminTripSearchCriteria._();

  /// Check if search has any active filters
  bool get hasFilters =>
      tripType != null ||
      levelIds.isNotEmpty ||
      leadUserId != null ||
      meetingPointArea != null;

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (tripType != null) count++;
    if (levelIds.isNotEmpty) count++;
    if (leadUserId != null) count++;
    if (meetingPointArea != null) count++;
    return count;
  }

  /// Build API query parameters from search criteria
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'ordering': '-created', // Always newest first by creation date
      'page': 1,
      'pageSize': 200,
    };

    // Trip type filter
    if (tripType != null) {
      switch (tripType!) {
        case TripType.upcoming:
          params['approvalStatus'] = 'approved';
          params['startTimeAfter'] = DateTime.now().toIso8601String();
          break;
        case TripType.pending:
          params['approvalStatus'] = 'pending';
          break;
        case TripType.completed:
          params['approvalStatus'] = 'approved';
          params['startTimeBefore'] = DateTime.now().toIso8601String();
          break;
        case TripType.all:
          // No filter
          break;
      }
    }

    // Level IDs filter (multi-select)
    if (levelIds.isNotEmpty) {
      params['level_Id'] = levelIds;
    }

    // Lead user ID filter
    if (leadUserId != null) {
      params['lead'] = leadUserId;
    }

    // Meeting point area filter
    if (meetingPointArea != null) {
      params['meetingPoint_Area'] = meetingPointArea;
    }

    return params;
  }
}

/// Trip type enum for admin search
enum TripType {
  upcoming,
  pending,
  completed,
  all,
}

/// Extension for TripType display properties
extension TripTypeExtension on TripType {
  String get displayName {
    switch (this) {
      case TripType.upcoming:
        return 'Upcoming Trips';
      case TripType.pending:
        return 'Pending Approvals';
      case TripType.completed:
        return 'Completed Trips';
      case TripType.all:
        return 'All Trips';
    }
  }

  String get icon {
    switch (this) {
      case TripType.upcoming:
        return '📅';
      case TripType.pending:
        return '⏳';
      case TripType.completed:
        return '✅';
      case TripType.all:
        return '📋';
    }
  }

  String get description {
    switch (this) {
      case TripType.upcoming:
        return 'Approved trips starting in the future';
      case TripType.pending:
        return 'Trips waiting for approval';
      case TripType.completed:
        return 'Trips that have ended';
      case TripType.all:
        return 'All trips regardless of status';
    }
  }
}
