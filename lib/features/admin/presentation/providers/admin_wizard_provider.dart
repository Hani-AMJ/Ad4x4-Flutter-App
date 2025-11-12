import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/admin_trip_search_criteria.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/status_helpers.dart';

part 'admin_wizard_provider.g.dart';

/// Admin Wizard State Notifier
/// 
/// Manages wizard navigation and search criteria for admin trips search
@riverpod
class AdminWizard extends _$AdminWizard {
  @override
  AdminTripSearchCriteria build() {
    return const AdminTripSearchCriteria();
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  /// Navigate to next step
  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go directly to results page
  void goToResults() {
    state = state.copyWith(currentStep: 5);
  }

  /// Execute search and store results in state
  Future<void> executeSearchAndStoreResults() async {
    print('🔍 [AdminWizard] executeSearchAndStoreResults called');
    
    // Set loading state
    state = state.copyWith(isSearching: true, searchError: null);
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final params = state.toQueryParams();
      
      print('🔍 [AdminWizard] Query params: $params');
      print('🔍 [AdminWizard] Starting pagination loop...');
      
      // Pagination loop to fetch ALL trips
      final List<TripListItem> allTrips = [];
      int currentPage = 1;
      const int pageSize = 200;
      bool hasMorePages = true;
      
      while (hasMorePages) {
        print('🔍 [AdminWizard] Fetching page $currentPage...');
        
        final response = await repository.getTrips(
          startTimeAfter: params['startTimeAfter'] as String?,
          startTimeBefore: params['startTimeBefore'] as String?,
          levelId: params['level_Id'] is List
              ? (params['level_Id'] as List<int>).first
              : params['level_Id'] as int?,
          meetingPointArea: params['meetingPoint_Area'] as String?,
          ordering: params['ordering'] as String?,
          page: currentPage,
          pageSize: pageSize,
        );

        final tripsData = response['results'] as List<dynamic>? ?? [];
        final nextUrl = response['next'] as String?;
        
        print('🔍 [AdminWizard] Page $currentPage: ${tripsData.length} trips');
        
        final pageTrips = tripsData
            .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
            .toList();
        
        allTrips.addAll(pageTrips);
        
        hasMorePages = nextUrl != null && tripsData.length == pageSize;
        currentPage++;
        
        if (currentPage > 50) {
          print('⚠️ [AdminWizard] Reached page limit (50 pages)');
          break;
        }
      }
      
      print('🔍 [AdminWizard] ✅ Pagination complete: ${allTrips.length} total trips');
      
      // Client-side filtering
      var trips = allTrips;
      
      // Filter by approval status
      if (params['approvalStatus'] != null) {
        final status = params['approvalStatus'] as String;
        final beforeFilter = trips.length;
        
        if (status == 'approved') {
          trips = trips.where((trip) => isApproved(trip.approvalStatus)).toList();
        } else if (status == 'pending') {
          trips = trips.where((trip) => isPending(trip.approvalStatus)).toList();
        } else if (status == 'declined') {
          trips = trips.where((trip) => isDeclined(trip.approvalStatus)).toList();
        }
        
        print('🔍 [AdminWizard] Approval filter ($status): $beforeFilter → ${trips.length}');
      }

      // Filter by lead user
      if (params['lead'] != null) {
        final leadId = params['lead'] as int;
        final beforeFilter = trips.length;
        trips = trips.where((trip) => trip.lead.id == leadId).toList();
        print('🔍 [AdminWizard] Lead filter ($leadId): $beforeFilter → ${trips.length}');
      }

      // Multi-level filtering
      if (params['level_Id'] is List) {
        final levelIds = (params['level_Id'] as List<int>).toSet();
        final beforeFilter = trips.length;
        trips = trips.where((trip) => levelIds.contains(trip.level.id)).toList();
        print('🔍 [AdminWizard] Multi-level filter ($levelIds): $beforeFilter → ${trips.length}');
      }

      print('🔍 [AdminWizard] ✅ FINAL TRIP COUNT: ${trips.length}');
      
      // Store results in state
      state = state.copyWith(
        searchResults: trips,
        isSearching: false,
        searchError: null,
      );
      
      print('🔍 [AdminWizard] ✅ Results stored in state');
    } catch (e, stackTrace) {
      print('❌ [AdminWizard] Search failed: $e');
      print('   Stack trace: $stackTrace');
      
      state = state.copyWith(
        isSearching: false,
        searchError: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Reset wizard to initial state
  void resetWizard() {
    state = const AdminTripSearchCriteria();
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  // ============================================================================
  // FILTER SETTERS
  // ============================================================================

  /// Set trip type filter
  void setTripType(TripType type) {
    state = state.copyWith(tripType: type);
  }

  /// Toggle level selection (multi-select)
  void toggleLevel(int levelId) {
    final currentLevels = List<int>.from(state.levelIds);
    if (currentLevels.contains(levelId)) {
      currentLevels.remove(levelId);
    } else {
      currentLevels.add(levelId);
    }
    state = state.copyWith(levelIds: currentLevels);
  }

  /// Set all levels (select all or deselect all)
  void setAllLevels(bool selectAll) {
    state = state.copyWith(
      levelIds: selectAll ? [1, 2, 3, 4, 5, 6, 7, 8, 9] : [],
    );
  }

  /// Set lead user filter
  void setLeadFilter(int? userId) {
    state = state.copyWith(leadUserId: userId);
  }

  /// Set meeting point area filter
  void setAreaFilter(String? area) {
    state = state.copyWith(meetingPointArea: area);
  }

  /// Remove specific filter
  void removeFilter(String filterType) {
    switch (filterType) {
      case 'tripType':
        state = state.copyWith(tripType: null);
        break;
      case 'levels':
        state = state.copyWith(levelIds: []);
        break;
      case 'lead':
        state = state.copyWith(leadUserId: null);
        break;
      case 'area':
        state = state.copyWith(meetingPointArea: null);
        break;
    }
  }

  /// Clear all filters
  void clearAllFilters() {
    state = state.copyWith(
      tripType: null,
      levelIds: [],
      leadUserId: null,
      meetingPointArea: null,
    );
  }
}

/// Admin Wizard Results Provider
/// 
/// Manages search results for admin trips wizard
@riverpod
class AdminWizardResults extends _$AdminWizardResults {
  @override
  AsyncValue<List<TripListItem>> build() {
    return const AsyncValue.loading();
  }

  /// Execute search with current criteria - FETCHES ALL PAGES
  Future<void> executeSearch(AdminTripSearchCriteria criteria) async {
    print('🔍 [AdminWizard] ========== EXECUTING SEARCH ==========');
    print('🔍 [AdminWizard] Criteria: ${criteria.toString()}');
    print('🔍 [AdminWizard] Trip Type: ${criteria.tripType}');
    print('🔍 [AdminWizard] Level IDs: ${criteria.levelIds}');
    print('🔍 [AdminWizard] Lead User ID: ${criteria.leadUserId}');
    print('🔍 [AdminWizard] Meeting Point Area: ${criteria.meetingPointArea}');
    
    state = const AsyncValue.loading();
    print('🔍 [AdminWizard] State set to loading...');

    state = await AsyncValue.guard(() async {
      try {
        final repository = ref.read(mainApiRepositoryProvider);
        final params = criteria.toQueryParams();
        
        print('🔍 [AdminWizard] Query params generated:');
        params.forEach((key, value) {
          print('   - $key: $value');
        });

        // ✅ PAGINATION: Fetch ALL trips from backend
        final List<TripListItem> allTrips = [];
        int currentPage = 1;
        const int pageSize = 200; // Reasonable page size for performance
        bool hasMorePages = true;
        
        print('🔍 [AdminWizard] Starting pagination loop...');
        
        while (hasMorePages) {
          print('🔍 [AdminWizard] Fetching page $currentPage...');
          
          final response = await repository.getTrips(
            startTimeAfter: params['startTimeAfter'] as String?,
            startTimeBefore: params['startTimeBefore'] as String?,
            levelId: params['level_Id'] is List
                ? (params['level_Id'] as List<int>).first
                : params['level_Id'] as int?, // ⚠️ API limitation: only one level supported
            meetingPointArea: params['meetingPoint_Area'] as String?,
            ordering: params['ordering'] as String?,
            page: currentPage,
            pageSize: pageSize,
          );

          final tripsData = response['results'] as List<dynamic>? ?? [];
          final nextUrl = response['next'] as String?;
          
          print('🔍 [AdminWizard] Page $currentPage: ${tripsData.length} trips');
          print('🔍 [AdminWizard] Next URL: ${nextUrl ?? "null (last page)"}');
          
          // Parse and add trips from this page
          final pageTrips = tripsData
              .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
              .toList();
          
          allTrips.addAll(pageTrips);
          
          // Check if there are more pages
          hasMorePages = nextUrl != null && tripsData.length == pageSize;
          currentPage++;
          
          // Safety limit to prevent infinite loops
          if (currentPage > 50) {
            print('⚠️ [AdminWizard] Reached page limit (50 pages)');
            break;
          }
        }
        
        print('🔍 [AdminWizard] ✅ Pagination complete: ${allTrips.length} total trips from ${currentPage - 1} pages');
        
        var trips = allTrips;

        // ⚠️ CLIENT-SIDE FILTERING for unsupported backend parameters
        
        // Filter by approval status (if not already handled by startTime filters)
        if (params['approvalStatus'] != null) {
          final status = params['approvalStatus'] as String;
          final beforeFilter = trips.length;
          
          // ✅ FIX: Backend uses single-letter codes (A, P, D), not full words
          if (status == 'approved') {
            trips = trips.where((trip) => isApproved(trip.approvalStatus)).toList();
          } else if (status == 'pending') {
            trips = trips.where((trip) => isPending(trip.approvalStatus)).toList();
          } else if (status == 'declined') {
            trips = trips.where((trip) => isDeclined(trip.approvalStatus)).toList();
          }
          
          print('🔍 [AdminWizard] Approval status filter ($status): $beforeFilter → ${trips.length}');
        }

        // Filter by lead user (if API doesn't support it)
        if (params['lead'] != null) {
          final leadId = params['lead'] as int;
          final beforeFilter = trips.length;
          trips = trips.where((trip) => trip.lead.id == leadId).toList();
          print('🔍 [AdminWizard] Lead user filter ($leadId): $beforeFilter → ${trips.length}');
        }

        // ✅ CRITICAL: Client-side multi-level filtering
        // Since backend only supports single level, filter client-side for multiple
        if (params['level_Id'] is List) {
          final levelIds = (params['level_Id'] as List<int>).toSet();
          final beforeFilter = trips.length;
          trips = trips.where((trip) => levelIds.contains(trip.level.id)).toList();
          print('🔍 [AdminWizard] Multi-level filter ($levelIds): $beforeFilter → ${trips.length}');
        }

        print('🔍 [AdminWizard] ✅ FINAL TRIP COUNT: ${trips.length}');
        print('🔍 [AdminWizard] ========== SEARCH COMPLETE ==========');
        return trips;
      } catch (e, stackTrace) {
        print('❌ [AdminWizard] ERROR during search:');
        print('   Error: $e');
        print('   Stack trace: $stackTrace');
        rethrow;
      }
    });
    
    print('🔍 [AdminWizard] State after guard: ${state.hasValue ? "✅ HAS VALUE (${state.value?.length} trips)" : state.hasError ? "❌ HAS ERROR: ${state.error}" : "⏳ LOADING"}');
  }

  /// Refresh current results
  Future<void> refresh() async {
    final criteria = ref.read(adminWizardProvider);
    await executeSearch(criteria);
  }
}
