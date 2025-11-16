import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/trip_filters.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Trips State - Manages trips data and loading state
/// 
/// ✅ PHASE 3: Enhanced with lastRefreshTime for smart refresh
class TripsState {
  final List<TripListItem> trips;          // Currently loaded trips
  final int totalCount;                     // Total trips in database
  final int currentPage;                    // Current page number
  final bool hasMore;                       // Are there more pages?
  final bool isLoading;                     // Initial loading state
  final bool isLoadingMore;                 // Loading more pages state
  final String? errorMessage;
  final TripFilters filters;
  final Set<int> registeredTripIds;         // Trip IDs where user is registered
  final DateTime? lastRefreshTime;          // ✅ PHASE 3: Track last refresh time

  const TripsState({
    this.trips = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.filters = const TripFilters(),
    this.registeredTripIds = const {},
    this.lastRefreshTime,
  });

  /// ✅ PHASE 3: Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastRefreshTime == null) return true;
    final age = DateTime.now().difference(lastRefreshTime!);
    return age.inMinutes >= 5;
  }

  TripsState copyWith({
    List<TripListItem>? trips,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    TripFilters? filters,
    Set<int>? registeredTripIds,
    DateTime? lastRefreshTime,  // ✅ PHASE 3: Add lastRefreshTime
  }) {
    return TripsState(
      trips: trips ?? this.trips,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
      registeredTripIds: registeredTripIds ?? this.registeredTripIds,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,  // ✅ PHASE 3
    );
  }

  // Filter trips by status
  List<TripListItem> get allTrips {
    // API returns upcoming trips only (filtered by startTimeAfter in loadTrips)
    // Sorted by start_time based on filters.ordering
    return trips;
  }
  
  List<TripListItem> get upcomingTrips {
    // API already filters for upcoming trips via startTimeAfter parameter
    // Just need to sort by start time (soonest first)
    final upcoming = List<TripListItem>.from(trips);
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming;
  }
  
  List<TripListItem> getMyTrips(int userId) {
    if (userId == 0) return []; // Not logged in
    
    final now = DateTime.now();
    final myTrips = trips.where((trip) {
      // ✅ Show trips where user is registered OR waitlisted OR is the lead
      // ✅ Only show UPCOMING trips (future trips only)
      return (trip.isRegistered || trip.isWaitlisted || trip.lead.id == userId) && 
             trip.startTime.isAfter(now);
    }).toList();
    
    // Sort by start time ascending (soonest first for My Trips)
    myTrips.sort((a, b) => a.startTime.compareTo(b.startTime));
    return myTrips;
  }
}

/// Trips Notifier - Manages trips state and API calls
class TripsNotifier extends StateNotifier<TripsState> {
  final Ref _ref;

  TripsNotifier(this._ref) : super(const TripsState());

  /// Load user's registered trip IDs
  /// ✅ DEPRECATED: No longer needed - API now provides isRegistered field directly
  /// Kept for backward compatibility but returns empty set
  Future<Set<int>> _loadRegisteredTripIds() async {
    try {
      final authState = _ref.read(authProviderV2);
      final userId = authState.user?.id;
      
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️  [TripsProvider] No user ID - user not authenticated');
        }
        return {};
      }
      
      if (kDebugMode) {
        print('✅ [TripsProvider] Using API-provided isRegistered field for user $userId');
        print('   No need to fetch registered trip IDs separately');
      }
      
      // Return empty set - isRegistered field is now provided by API
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ [TripsProvider] Error: $e');
      }
      return {};
    }
  }

  /// Load trips from API with filters (initial load - first page only)
  Future<void> loadTrips({TripFilters? filters}) async {
    final updatedFilters = filters ?? state.filters;
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      filters: updatedFilters,
      trips: [], // Clear existing trips on fresh load
      currentPage: 0,
      totalCount: 0,
      hasMore: false,
    );

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      
      print('🔄 [TripsProvider] Loading upcoming trips (pageSize: 200)...');
      
      // Load registered trip IDs in parallel
      final registeredIdsFuture = _loadRegisteredTripIds();
      
      // ✅ For upcoming/my trips, fetch from now onwards with larger pageSize
      // to ensure all user's registered trips are included
      final now = DateTime.now();
      
      // ✅ Use proper UTC format with 'Z' suffix (no milliseconds)
      // Backend expects: "2025-11-14T02:03:11Z" not "2025-11-14T02:03:11.162"
      final startTimeFilter = (updatedFilters.startDate ?? now)
          .toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final endTimeFilter = updatedFilters.endDate
          ?.toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final response = await repository.getTrips(
        approvalStatus: 'A', // ✅ CRITICAL: Only show APPROVED trips (excludes Deleted 'D', Pending 'P', Rejected 'R')
        startTimeAfter: startTimeFilter,
        startTimeBefore: endTimeFilter,
        ordering: updatedFilters.ordering,
        levelId: updatedFilters.levelId,
        meetingPointArea: updatedFilters.area,
        // ✅ NEW: Advanced filters (Phase A Task #4)
        meetingPoint: updatedFilters.meetingPointId,
        lead: updatedFilters.leadId,
        endTimeAfter: updatedFilters.endTimeAfter
            ?.toUtc()
            .toIso8601String()
            .replaceFirst(RegExp(r'\.\d+Z'), 'Z'),
        endTimeBefore: updatedFilters.endTimeBefore
            ?.toUtc()
            .toIso8601String()
            .replaceFirst(RegExp(r'\.\d+Z'), 'Z'),
        page: 1,
        pageSize: 200, // ✅ Increased from 50 to 200 to capture more user trips
      );

      // Get total count
      final totalCount = response['count'] as int? ?? 0;
      print('📊 [TripsProvider] Total trips available: $totalCount');

      // Parse trips from response
      final tripsData = response['results'] as List<dynamic>?;
      if (tripsData == null) {
        throw Exception('Invalid response format: results field is null');
      }

      print('   Loaded ${tripsData.length} trips from page 1');

      final loadedTrips = <TripListItem>[];
      for (var i = 0; i < tripsData.length; i++) {
        try {
          final tripJson = tripsData[i] as Map<String, dynamic>;
          final trip = TripListItem.fromJson(tripJson);
          loadedTrips.add(trip);
        } catch (e) {
          print('❌ [TripsProvider] Error parsing trip: $e');
          // Continue with other trips
        }
      }

      // Check if there are more pages
      final hasNext = response['next'] != null;

      // Wait for registered trip IDs (currently returns empty - see method comment)
      final registeredIds = await registeredIdsFuture;

      print('✅ [TripsProvider] Successfully loaded ${loadedTrips.length} of $totalCount trips');
      if (loadedTrips.isNotEmpty) {
        print('   First trip: ${loadedTrips[0].title}');
        print('   Last trip: ${loadedTrips[loadedTrips.length - 1].title}');
      }
      
      // Debug: Check upcoming trips count in loaded data
      final upcomingCount = loadedTrips.where((trip) => trip.startTime.isAfter(now)).length;
      print('   📅 Upcoming trips in loaded data: $upcomingCount');
      print('   ✅ Registered trips: ${registeredIds.length}');

      state = state.copyWith(
        trips: loadedTrips,
        totalCount: totalCount,
        currentPage: 1,
        hasMore: hasNext,
        isLoading: false,
        registeredTripIds: registeredIds,
        lastRefreshTime: DateTime.now(),  // ✅ PHASE 3: Track refresh time
      );
    } catch (e, stackTrace) {
      print('❌ [TripsProvider] Error loading trips: $e');
      print('   Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load trips: ${e.toString()}',
      );
    }
  }

  /// Load more trips (next page)
  Future<void> loadMoreTrips() async {
    if (state.isLoadingMore || !state.hasMore) {
      print('⚠️  [TripsProvider] Already loading or no more trips available');
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final nextPage = state.currentPage + 1;
      
      print('🔄 [TripsProvider] Loading page $nextPage...');
      
      // ✅ Apply proper UTC date formatting for all date filters
      final startTimeFilter = state.filters.startDate
          ?.toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final endTimeFilter = state.filters.endDate
          ?.toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final endTimeAfterFilter = state.filters.endTimeAfter
          ?.toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final endTimeBeforeFilter = state.filters.endTimeBefore
          ?.toUtc()
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z'), 'Z');
      
      final response = await repository.getTrips(
        approvalStatus: 'A', // ✅ CRITICAL: Only show APPROVED trips (excludes Deleted 'D', Pending 'P', Rejected 'R')
        startTimeAfter: startTimeFilter,
        startTimeBefore: endTimeFilter,
        ordering: state.filters.ordering,
        levelId: state.filters.levelId,
        meetingPointArea: state.filters.area,
        // ✅ NEW: Advanced filters (Phase A Task #4)
        meetingPoint: state.filters.meetingPointId,
        lead: state.filters.leadId,
        endTimeAfter: endTimeAfterFilter,
        endTimeBefore: endTimeBeforeFilter,
        page: nextPage,
        pageSize: 50, // Load 50 more trips per page
      );

      // Parse trips from response
      final tripsData = response['results'] as List<dynamic>?;
      if (tripsData == null) {
        throw Exception('Invalid response format: results field is null');
      }

      print('   Loaded ${tripsData.length} trips from page $nextPage');

      final newTrips = <TripListItem>[];
      for (var i = 0; i < tripsData.length; i++) {
        try {
          final tripJson = tripsData[i] as Map<String, dynamic>;
          final trip = TripListItem.fromJson(tripJson);
          newTrips.add(trip);
        } catch (e) {
          print('❌ [TripsProvider] Error parsing trip: $e');
        }
      }

      // Check if there are more pages
      final hasNext = response['next'] != null;

      // Append new trips to existing list
      final allTrips = [...state.trips, ...newTrips];

      print('✅ [TripsProvider] Successfully loaded page $nextPage');
      print('   Total loaded so far: ${allTrips.length} of ${state.totalCount}');

      state = state.copyWith(
        trips: allTrips,
        currentPage: nextPage,
        hasMore: hasNext,
        isLoadingMore: false,
      );
    } catch (e, stackTrace) {
      print('❌ [TripsProvider] Error loading more trips: $e');
      print('   Stack trace: $stackTrace');
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more trips: ${e.toString()}',
      );
    }
  }

  /// Update filters and reload trips
  Future<void> updateFilters(TripFilters filters) async {
    print('🔄 [TripsProvider] Updating filters:');
    print('   Date Range: ${filters.dateRange}');
    print('   Start Date: ${filters.startDate}');
    print('   End Date: ${filters.endDate}');
    print('   Level: ${filters.levelId}');
    print('   Area: ${filters.area}');
    await loadTrips(filters: filters);
  }

  /// Refresh trips (reload with current filters)
  Future<void> refresh() async {
    await loadTrips();
  }

  /// Remove a trip from cached list (when 404 encountered)
  /// 
  /// ✅ PHASE 2: Smart cache invalidation
  /// Called when a trip is found to be deleted (404 error)
  void removeTripFromCache(int tripId) {
    final updatedTrips = state.trips.where((t) => t.id != tripId).toList();
    final removedCount = state.trips.length - updatedTrips.length;
    
    if (removedCount > 0) {
      state = state.copyWith(
        trips: updatedTrips,
        totalCount: state.totalCount - removedCount,
      );
      
      if (kDebugMode) {
        print('🗑️ [TripsProvider] Removed deleted trip $tripId from cache');
        print('   Trips count: ${state.trips.length} → ${updatedTrips.length}');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ [TripsProvider] Trip $tripId not found in cache to remove');
      }
    }
  }
}

/// Trips Provider - Main provider for trips list
final tripsProvider = StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  return TripsNotifier(ref);
});

/// Auto-load trips when provider is first accessed
final tripsAutoLoadProvider = Provider<void>((ref) {
  // Trigger initial load
  Future.microtask(() {
    ref.read(tripsProvider.notifier).loadTrips();
  });
});

/// Single Trip Detail Provider
/// Fetches full trip details including registered members and waitlist
/// 
/// ✅ Enhanced: Preserves ApiException with status code for better error handling
final tripDetailProvider = FutureProvider.autoDispose.family<Trip, int>((ref, tripId) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getTripDetail(tripId);
    return Trip.fromJson(response);
  } catch (e) {
    // ✅ Preserve original ApiException with status code information
    if (e is ApiException) {
      rethrow;  // Keep status code for 404 detection
    }
    // Wrap other exceptions
    throw ApiException(
      message: 'Failed to load trip details: $e',
      statusCode: 0,
    );
  }
});

/// Trip Registration Actions Provider
class TripActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TripActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Register for a trip
  /// 
  /// ✅ PHASE 2: Enhanced with 404 detection and cache cleanup
  Future<void> register(int tripId, {int? vehicleCapacity}) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.registerForTrip(tripId, vehicleCapacity: vehicleCapacity);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // ✅ Check if trip was deleted (404 error)
      if (e is ApiException && e.isNotFound) {
        if (kDebugMode) {
          print('🗑️ [TripActions] Trip $tripId not found (404) - removing from cache');
        }
        // Remove from cache
        _ref.read(tripsProvider.notifier).removeTripFromCache(tripId);
      }
      
      state = AsyncValue.error(e, stack);
    }
  }

  /// Unregister from a trip
  /// 
  /// ✅ PHASE 2: Enhanced with 404 detection and cache cleanup
  Future<void> unregister(int tripId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.unregisterFromTrip(tripId);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // ✅ Check if trip was deleted (404 error)
      if (e is ApiException && e.isNotFound) {
        if (kDebugMode) {
          print('🗑️ [TripActions] Trip $tripId not found (404) - removing from cache');
        }
        // Remove from cache
        _ref.read(tripsProvider.notifier).removeTripFromCache(tripId);
      }
      
      state = AsyncValue.error(e, stack);
    }
  }

  /// Join waitlist
  /// 
  /// ✅ PHASE 2: Enhanced with 404 detection and cache cleanup
  Future<void> joinWaitlist(int tripId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.joinWaitlist(tripId);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // ✅ Check if trip was deleted (404 error)
      if (e is ApiException && e.isNotFound) {
        if (kDebugMode) {
          print('🗑️ [TripActions] Trip $tripId not found (404) - removing from cache');
        }
        // Remove from cache
        _ref.read(tripsProvider.notifier).removeTripFromCache(tripId);
      }
      
      state = AsyncValue.error(e, stack);
    }
  }

  /// Approve trip (admin/board)
  Future<void> approveTrip(int tripId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.approveTrip(tripId);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Decline trip (admin/board)
  Future<void> declineTrip(int tripId, {String? reason}) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.declineTrip(tripId, reason: reason);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Trip Actions Provider
final tripActionsProvider = StateNotifierProvider<TripActionsNotifier, AsyncValue<void>>((ref) {
  return TripActionsNotifier(ref);
});
