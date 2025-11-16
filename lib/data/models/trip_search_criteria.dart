import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_search_criteria.freezed.dart';

/// Trip Search Criteria
/// 
/// Simplified search criteria for admin trips search with smart API parameter building
@freezed
class TripSearchCriteria with _$TripSearchCriteria {
  const factory TripSearchCriteria({
    /// Quick filter type (upcoming, pending, completed, all)
    @Default(TripSearchType.upcoming) TripSearchType searchType,
    
    /// Date range filter (optional)
    DateTime? dateFrom,
    DateTime? dateTo,
    
    /// Selected level IDs (multi-select - filtered client-side if multiple)
    @Default([]) List<int> levelIds,
    
    /// Trip lead username (autocomplete search - filtered client-side)
    String? leadUsername,
    
    /// Meeting point area filter (single area - API supported)
    String? meetingPointArea,
    
    /// Sort option
    @Default(TripSortOption.dateNewest) TripSortOption sortBy,
  }) = _TripSearchCriteria;

  const TripSearchCriteria._();

  /// Check if search has any active filters beyond search type
  bool get hasAdvancedFilters =>
      dateFrom != null ||
      dateTo != null ||
      levelIds.isNotEmpty ||
      leadUsername != null ||
      meetingPointArea != null;

  /// Get active filter count (excluding search type)
  int get activeFilterCount {
    int count = 0;
    if (dateFrom != null || dateTo != null) count++; // Date range counts as 1
    if (levelIds.isNotEmpty) count++;
    if (leadUsername != null) count++;
    if (meetingPointArea != null) count++;
    return count;
  }

  /// Build API query parameters (only backend-supported params)
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{};

    // Ordering (always included)
    params['ordering'] = sortBy.apiValue;

    // Search type determines approval status and time filters
    switch (searchType) {
      case TripSearchType.upcoming:
        params['approvalStatus'] = 'A'; // Approved only
        params['startTimeAfter'] = DateTime.now().toIso8601String();
        break;
      case TripSearchType.pending:
        params['approvalStatus'] = 'P'; // Pending only
        break;
      case TripSearchType.completed:
        params['approvalStatus'] = 'A'; // Approved only
        params['endTimeBefore'] = DateTime.now().toIso8601String();
        break;
      case TripSearchType.all:
        // No approval status filter
        break;
    }

    // Date range (user-defined, overrides search type dates)
    if (dateFrom != null) {
      params['startTimeAfter'] = dateFrom!.toIso8601String();
    }
    if (dateTo != null) {
      params['startTimeBefore'] = dateTo!.toIso8601String();
    }

    // Level filter (only first level for API - rest filtered client-side)
    // API limitation: only supports single level_Id
    if (levelIds.isNotEmpty) {
      params['level_Id'] = levelIds.first;
    }

    // Meeting point area (API supported)
    if (meetingPointArea != null) {
      params['meetingPoint_Area'] = meetingPointArea;
    }

    return params;
  }

  /// Check if we need client-side filtering (multi-level or lead filter)
  bool get needsClientFiltering =>
      levelIds.length > 1 || // Multiple levels
      leadUsername != null; // Lead filter

  /// Apply client-side filters to trip list
  List<T> applyClientFilters<T>(
    List<T> trips,
    int Function(T) getLevelId,
    String Function(T) getLeadUsername,
  ) {
    var filtered = trips;

    // Multi-level filtering (if more than one level selected)
    if (levelIds.length > 1) {
      final levelSet = levelIds.toSet();
      filtered = filtered.where((trip) => levelSet.contains(getLevelId(trip))).toList();
    }

    // Lead username filtering
    if (leadUsername != null && leadUsername!.isNotEmpty) {
      final query = leadUsername!.toLowerCase();
      filtered = filtered.where((trip) {
        final username = getLeadUsername(trip).toLowerCase();
        return username.contains(query);
      }).toList();
    }

    return filtered;
  }
}

/// Trip search type enum
enum TripSearchType {
  upcoming,
  pending,
  completed,
  all,
}

/// Extension for TripSearchType display properties
extension TripSearchTypeExtension on TripSearchType {
  String get displayName {
    switch (this) {
      case TripSearchType.upcoming:
        return 'Upcoming';
      case TripSearchType.pending:
        return 'Pending';
      case TripSearchType.completed:
        return 'Completed';
      case TripSearchType.all:
        return 'All Trips';
    }
  }

  String get icon {
    switch (this) {
      case TripSearchType.upcoming:
        return '📅';
      case TripSearchType.pending:
        return '⏳';
      case TripSearchType.completed:
        return '✅';
      case TripSearchType.all:
        return '📋';
    }
  }

  String get description {
    switch (this) {
      case TripSearchType.upcoming:
        return 'Approved trips starting in the future';
      case TripSearchType.pending:
        return 'Trips waiting for approval';
      case TripSearchType.completed:
        return 'Trips that have ended';
      case TripSearchType.all:
        return 'All trips regardless of status';
    }
  }
}

/// Trip sort options
enum TripSortOption {
  dateNewest,
  dateOldest,
  levelAsc,
  levelDesc,
  registrationsHigh,
  registrationsLow,
}

/// Extension for TripSortOption
extension TripSortOptionExtension on TripSortOption {
  String get displayName {
    switch (this) {
      case TripSortOption.dateNewest:
        return 'Date (Newest First)';
      case TripSortOption.dateOldest:
        return 'Date (Oldest First)';
      case TripSortOption.levelAsc:
        return 'Level (Easiest First)';
      case TripSortOption.levelDesc:
        return 'Level (Hardest First)';
      case TripSortOption.registrationsHigh:
        return 'Most Registered';
      case TripSortOption.registrationsLow:
        return 'Least Registered';
    }
  }

  /// API ordering parameter (for backend sorting)
  String get apiValue {
    switch (this) {
      case TripSortOption.dateNewest:
        return '-start_time'; // Newest first
      case TripSortOption.dateOldest:
        return 'start_time'; // Oldest first
      case TripSortOption.levelAsc:
      case TripSortOption.levelDesc:
      case TripSortOption.registrationsHigh:
      case TripSortOption.registrationsLow:
        // These require client-side sorting after fetch
        return '-start_time'; // Default to date sort for API
    }
  }

  /// Whether this sort option requires client-side sorting
  bool get needsClientSorting =>
      this == TripSortOption.levelAsc ||
      this == TripSortOption.levelDesc ||
      this == TripSortOption.registrationsHigh ||
      this == TripSortOption.registrationsLow;

  /// Apply client-side sorting to trip list
  List<T> applyClientSort<T>(
    List<T> trips,
    int Function(T) getNumericLevel,
    int Function(T) getRegisteredCount,
  ) {
    switch (this) {
      case TripSortOption.levelAsc:
        trips.sort((a, b) => getNumericLevel(a).compareTo(getNumericLevel(b)));
        break;
      case TripSortOption.levelDesc:
        trips.sort((a, b) => getNumericLevel(b).compareTo(getNumericLevel(a)));
        break;
      case TripSortOption.registrationsHigh:
        trips.sort((a, b) => getRegisteredCount(b).compareTo(getRegisteredCount(a)));
        break;
      case TripSortOption.registrationsLow:
        trips.sort((a, b) => getRegisteredCount(a).compareTo(getRegisteredCount(b)));
        break;
      default:
        // Date sorting handled by backend
        break;
    }
    return trips;
  }
}
