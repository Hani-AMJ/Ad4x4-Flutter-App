import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/trip_filters.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Trips State - Manages trips data and loading state
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
  });

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
    );
  }

  // Filter trips by status
  List<TripListItem> get allTrips {
    // API returns data pre-sorted (newest first via -start_time ordering)
    return trips;
  }
  
  List<TripListItem> get upcomingTrips {
    final now = DateTime.now();
    // Get trips that haven't started yet (future trips)
    final upcoming = trips.where((trip) => trip.startTime.isAfter(now)).toList();
    // Sort by start time (soonest first for upcoming - ascending order)
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming;
  }
  
  List<TripListItem> getMyTrips(int userId) {
    if (userId == 0) return []; // Not logged in
    
    final myTrips = trips.where((trip) {
      // Show trips where user is the lead
      // TODO: When backend adds 'is_registered' flag, also include registered trips
      return trip.lead.id == userId;
    }).toList();
    
    // API returns pre-sorted (newest first), no need to re-sort
    return myTrips;
  }
}

/// Trips Notifier - Manages trips state and API calls
class TripsNotifier extends StateNotifier<TripsState> {
  final Ref _ref;

  TripsNotifier(this._ref) : super(const TripsState());

  /// Load user's registered trip IDs
  /// WORKAROUND: Since API doesn't provide is_registered field in trips list,
  /// we check trips where user is the lead (guaranteed to show badge)
  /// TODO: Backend should add is_registered field to trips list API response
  Future<Set<int>> _loadRegisteredTripIds() async {
    try {
      final authState = _ref.read(authProviderV2);
      final userId = authState.user?.id;
      
      if (userId == null) {
        print('⚠️  [TripsProvider] No user ID - skipping registered trips fetch');
        return {};
      }
      
      print('🔄 [TripsProvider] Using lead-based registration detection for user $userId');
      print('⚠️  [TripsProvider] LIMITATION: Only trips where user is lead will show "Joined" badge');
      print('💡 [TripsProvider] Backend needs to add is_registered field to trips list API');
      
      // Return empty set - we'll check lead status directly in the trip data
      return {};
    } catch (e) {
      print('❌ [TripsProvider] Error: $e');
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
      
      print('🔄 [TripsProvider] Loading first page of trips (50 items)...');
      
      // Load registered trip IDs in parallel
      final registeredIdsFuture = _loadRegisteredTripIds();
      
      final response = await repository.getTrips(
        startTimeAfter: updatedFilters.startDate?.toIso8601String(),
        startTimeBefore: updatedFilters.endDate?.toIso8601String(),
        ordering: updatedFilters.ordering,
        levelId: updatedFilters.levelId,
        meetingPointArea: updatedFilters.area,
        page: 1,
        pageSize: 50, // Initial load: 50 trips for fast display
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
      final now = DateTime.now();
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
      
      final response = await repository.getTrips(
        startTimeAfter: state.filters.startDate?.toIso8601String(),
        startTimeBefore: state.filters.endDate?.toIso8601String(),
        ordering: state.filters.ordering,
        levelId: state.filters.levelId,
        meetingPointArea: state.filters.area,
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
    print('   Status: ${filters.status}');
    print('   Start Date: ${filters.startDate}');
    print('   End Date: ${filters.endDate}');
    await loadTrips(filters: filters);
  }

  /// Refresh trips (reload with current filters)
  Future<void> refresh() async {
    await loadTrips();
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
final tripDetailProvider = FutureProvider.autoDispose.family<Trip, int>((ref, tripId) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getTripDetail(tripId);
    return Trip.fromJson(response);
  } catch (e) {
    throw Exception('Failed to load trip details: $e');
  }
});

/// Trip Registration Actions Provider
class TripActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TripActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Register for a trip
  Future<void> register(int tripId, {int? vehicleCapacity}) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.registerForTrip(tripId, vehicleCapacity: vehicleCapacity);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Unregister from a trip
  Future<void> unregister(int tripId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.unregisterFromTrip(tripId);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Join waitlist
  Future<void> joinWaitlist(int tripId) async {
    state = const AsyncValue.loading();
    
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.joinWaitlist(tripId);
      
      // Refresh trips list
      await _ref.read(tripsProvider.notifier).refresh();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
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
