import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/trip_search_criteria.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';

part 'admin_trips_search_provider.g.dart';

/// Admin Trips Search State
///
/// Unified state for trips search functionality
class AdminTripsSearchState {
  final List<TripListItem> results;
  final bool isLoading;
  final String? error;
  final TripSearchCriteria criteria;
  final int totalCount; // Total from API before client filtering
  final bool hasSearched; // Whether user has executed a search

  const AdminTripsSearchState({
    required this.results,
    required this.isLoading,
    this.error,
    required this.criteria,
    required this.totalCount,
    required this.hasSearched,
  });

  factory AdminTripsSearchState.initial() {
    return AdminTripsSearchState(
      results: const [],
      isLoading: false,
      error: null,
      criteria: const TripSearchCriteria(),
      totalCount: 0,
      hasSearched: false,
    );
  }

  AdminTripsSearchState copyWith({
    List<TripListItem>? results,
    bool? isLoading,
    String? error,
    TripSearchCriteria? criteria,
    int? totalCount,
    bool? hasSearched,
  }) {
    return AdminTripsSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      criteria: criteria ?? this.criteria,
      totalCount: totalCount ?? this.totalCount,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

/// Admin Trips Search Provider
///
/// Single unified provider for all trips search operations
@riverpod
class AdminTripsSearch extends _$AdminTripsSearch {
  @override
  AdminTripsSearchState build() {
    // Initialize with default search (Upcoming trips)
    // Auto-execute search on first build
    Future.microtask(() => executeSearch());
    return AdminTripsSearchState.initial();
  }

  /// Execute search with current or provided criteria
  Future<void> executeSearch([TripSearchCriteria? newCriteria]) async {
    final criteria = newCriteria ?? state.criteria;

    print('🔍 [AdminTripsSearch] ========== EXECUTING SEARCH ==========');
    print(
      '🔍 [AdminTripsSearch] Search Type: ${criteria.searchType.displayName}',
    );
    print(
      '🔍 [AdminTripsSearch] Date Range: ${criteria.dateFrom} to ${criteria.dateTo}',
    );
    print('🔍 [AdminTripsSearch] Levels: ${criteria.levelIds}');
    print('🔍 [AdminTripsSearch] Lead: ${criteria.leadUsername ?? "Any"}');
    print('🔍 [AdminTripsSearch] Area: ${criteria.meetingPointArea ?? "Any"}');
    print('🔍 [AdminTripsSearch] Sort By: ${criteria.sortBy.displayName}');

    // Update state to loading
    state = state.copyWith(
      isLoading: true,
      error: null,
      criteria: criteria,
      hasSearched: true,
    );

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final apiParams = criteria.toApiParams();

      print('🔍 [AdminTripsSearch] API Params: $apiParams');

      // Fetch trips with pagination
      final allTrips = await _fetchAllTrips(repository, apiParams, criteria);

      print('🔍 [AdminTripsSearch] Fetched ${allTrips.length} trips from API');

      // Apply client-side filters if needed
      var filteredTrips = allTrips;
      if (criteria.needsClientFiltering) {
        print('🔍 [AdminTripsSearch] Applying client-side filters...');
        filteredTrips = criteria.applyClientFilters<TripListItem>(
          allTrips,
          (trip) => trip.level.id,
          (trip) => trip.lead.username,
        );
        print(
          '🔍 [AdminTripsSearch] After client filtering: ${filteredTrips.length} trips',
        );
      }

      // Apply client-side sorting if needed
      if (criteria.sortBy.needsClientSorting) {
        print('🔍 [AdminTripsSearch] Applying client-side sorting...');
        filteredTrips = criteria.sortBy.applyClientSort<TripListItem>(
          filteredTrips,
          (trip) => trip.level.numericLevel,
          (trip) => trip.registeredCount,
        );
      }

      print(
        '🔍 [AdminTripsSearch] ✅ FINAL RESULT: ${filteredTrips.length} trips',
      );

      // Update state with results
      state = state.copyWith(
        results: filteredTrips,
        isLoading: false,
        error: null,
        totalCount: allTrips.length,
      );
    } catch (e, stackTrace) {
      print('❌ [AdminTripsSearch] Search failed: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        results: [],
      );
    }
  }

  /// Fetch all trips with pagination
  Future<List<TripListItem>> _fetchAllTrips(
    dynamic repository,
    Map<String, dynamic> apiParams,
    TripSearchCriteria criteria,
  ) async {
    final List<TripListItem> allTrips = [];
    int currentPage = 1;

    // Determine pagination strategy based on search type
    final bool fetchAllPages =
        criteria.searchType == TripSearchType.all ||
        criteria.needsClientFiltering;
    final int pageSize = fetchAllPages ? 200 : 50;
    bool hasMorePages = true;
    final int maxPages = fetchAllPages
        ? 50
        : 3; // "All Trips" fetches everything, others fetch limited

    print(
      '🔍 [AdminTripsSearch] Starting pagination (pageSize: $pageSize, maxPages: $maxPages, searchType: ${criteria.searchType.displayName}, fetchAll: $fetchAllPages)...',
    );

    while (hasMorePages && currentPage <= maxPages) {
      print('🔍 [AdminTripsSearch] Fetching page $currentPage...');

      final response = await repository.getTrips(
        startTimeAfter: apiParams['startTimeAfter'] as String?,
        startTimeBefore: apiParams['startTimeBefore'] as String?,
        endTimeBefore: apiParams['endTimeBefore'] as String?,
        approvalStatus: apiParams['approvalStatus'] as String?,
        levelId: apiParams['level_Id'] as int?,
        meetingPointArea: apiParams['meetingPoint_Area'] as String?,
        ordering: apiParams['ordering'] as String?,
        page: currentPage,
        pageSize: pageSize,
      );

      final tripsData = response['results'] as List<dynamic>? ?? [];
      final nextUrl = response['next'] as String?;

      print(
        '🔍 [AdminTripsSearch] Page $currentPage: ${tripsData.length} trips (next: ${nextUrl != null})',
      );

      final pageTrips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();

      allTrips.addAll(pageTrips);

      // Check if there are more pages
      hasMorePages = nextUrl != null && tripsData.length == pageSize;
      currentPage++;
    }

    print(
      '🔍 [AdminTripsSearch] ✅ Pagination complete: ${allTrips.length} total trips from ${currentPage - 1} pages',
    );
    return allTrips;
  }

  /// Update search criteria and re-execute search
  Future<void> updateCriteria(TripSearchCriteria criteria) async {
    await executeSearch(criteria);
  }

  /// Update search type (quick filter)
  Future<void> updateSearchType(TripSearchType type) async {
    final newCriteria = state.criteria.copyWith(searchType: type);
    await executeSearch(newCriteria);
  }

  /// Update date range
  Future<void> updateDateRange(DateTime? from, DateTime? to) async {
    final newCriteria = state.criteria.copyWith(dateFrom: from, dateTo: to);
    await executeSearch(newCriteria);
  }

  /// Toggle level selection (multi-select)
  Future<void> toggleLevel(int levelId) async {
    final currentLevels = List<int>.from(state.criteria.levelIds);
    if (currentLevels.contains(levelId)) {
      currentLevels.remove(levelId);
    } else {
      currentLevels.add(levelId);
    }
    final newCriteria = state.criteria.copyWith(levelIds: currentLevels);
    await executeSearch(newCriteria);
  }

  /// Update lead username filter
  Future<void> updateLeadFilter(String? username) async {
    final newCriteria = state.criteria.copyWith(leadUsername: username);
    await executeSearch(newCriteria);
  }

  /// Update area filter
  Future<void> updateAreaFilter(String? area) async {
    final newCriteria = state.criteria.copyWith(meetingPointArea: area);
    await executeSearch(newCriteria);
  }

  /// Update sort option
  Future<void> updateSortBy(TripSortOption sortBy) async {
    final newCriteria = state.criteria.copyWith(sortBy: sortBy);
    await executeSearch(newCriteria);
  }

  /// Clear all advanced filters (keep search type)
  Future<void> clearAdvancedFilters() async {
    final newCriteria = state.criteria.copyWith(
      dateFrom: null,
      dateTo: null,
      levelIds: [],
      leadUsername: null,
      meetingPointArea: null,
    );
    await executeSearch(newCriteria);
  }

  /// Reset to initial state
  void reset() {
    state = AdminTripsSearchState.initial();
    Future.microtask(() => executeSearch());
  }
}
