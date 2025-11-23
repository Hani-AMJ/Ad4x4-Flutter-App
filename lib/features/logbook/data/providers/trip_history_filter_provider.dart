import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_history_filters.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../presentation/screens/trip_history_with_logbook_screen.dart';
import '../../../../data/models/logbook_model.dart';

/// Trip History with Filters Provider
/// 
/// Manages trip history data with comprehensive filtering capabilities
class TripHistoryWithFiltersNotifier extends StateNotifier<AsyncValue<TripHistoryFilteredData>> {
  final MainApiRepository _repository;
  final int memberId;
  TripHistoryFilters _filters = const TripHistoryFilters();

  TripHistoryWithFiltersNotifier(this._repository, this.memberId) : super(const AsyncValue.loading()) {
    _loadData();
  }

  TripHistoryFilters get filters => _filters;

  /// Update filters and reload data
  Future<void> updateFilters(TripHistoryFilters newFilters) async {
    _filters = newFilters;
    await _loadData();
  }

  /// Reset filters to default
  Future<void> resetFilters() async {
    _filters = const TripHistoryFilters();
    await _loadData();
  }

  /// Reload data with current filters
  Future<void> refresh() async {
    await _loadData();
  }

  /// Load trip history data and apply filters
  Future<void> _loadData() async {
    state = const AsyncValue.loading();

    try {
      // Fetch all trip history (we'll filter client-side for comprehensive filtering)
      final response = await _repository.getMemberTripHistory(
        memberId: memberId,
        page: 1,
        pageSize: 200, // Fetch more for comprehensive client-side filtering
      );

      // Parse trip history
      final List<TripHistoryItem> allTrips = [];
      final data = response['results'] ?? response['data'] ?? response;

      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              allTrips.add(TripHistoryItem.fromJson(item));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Failed to parse trip history item: $e');
              }
            }
          }
        }
      }

      // Load logbook entries for all trips
      final Map<int, List<LogbookEntry>> tripLogbookMap = {};
      for (var trip in allTrips) {
        try {
          final logbookResponse = await _repository.getLogbookEntries(
            memberId: memberId,
            tripId: trip.tripId,
          );

          final List<LogbookEntry> entries = [];
          final logbookData = logbookResponse['results'] ?? 
                             logbookResponse['data'] ?? 
                             logbookResponse;

          if (logbookData is List) {
            for (var item in logbookData) {
              if (item != null && item is Map<String, dynamic>) {
                try {
                  entries.add(LogbookEntry.fromJson(item));
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Failed to parse logbook entry: $e');
                  }
                }
              }
            }
          }

          tripLogbookMap[trip.tripId] = entries;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to load logbook for trip ${trip.tripId}: $e');
          }
          tripLogbookMap[trip.tripId] = [];
        }
      }

      // Apply filters
      final filteredData = _applyFilters(allTrips, tripLogbookMap);

      state = AsyncValue.data(filteredData);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error loading trip history: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  /// Apply all filters to trip history data
  TripHistoryFilteredData _applyFilters(
    List<TripHistoryItem> allTrips,
    Map<int, List<LogbookEntry>> logbookMap,
  ) {
    List<TripHistoryItem> filtered = List.from(allTrips);

    // 1. Date Range Filter
    final startDate = _filters.effectiveStartDate;
    final endDate = _filters.effectiveEndDate;
    if (startDate != null) {
      filtered = filtered.where((trip) => trip.startTime.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((trip) => trip.startTime.isBefore(endDate)).toList();
    }

    // 2. Level Filter
    if (_filters.selectedLevelIds.isNotEmpty) {
      filtered = filtered.where((trip) {
        if (trip.level == null) return false;
        // Extract numeric level from string (e.g., "Beginner" -> 1)
        final levelNum = _getLevelNumber(trip.level!);
        return _filters.selectedLevelIds.contains(levelNum);
      }).toList();
    }

    // 3. Attendance Filter
    final now = DateTime.now();
    switch (_filters.attendanceFilter) {
      case TripAttendanceFilter.attended:
        filtered = filtered.where((trip) => trip.attended).toList();
        break;
      case TripAttendanceFilter.registered:
        filtered = filtered.where((trip) => trip.checkedIn || trip.checkedOut).toList();
        break;
      case TripAttendanceFilter.upcoming:
        filtered = filtered.where((trip) => trip.startTime.isAfter(now)).toList();
        break;
      case TripAttendanceFilter.completed:
        filtered = filtered.where((trip) => trip.startTime.isBefore(now)).toList();
        break;
      case TripAttendanceFilter.all:
        // No filter
        break;
    }

    // 4. Only Trips with Skills Filter
    if (_filters.onlyTripsWithSkills) {
      filtered = filtered.where((trip) {
        final entries = logbookMap[trip.tripId] ?? [];
        return entries.isNotEmpty && 
               entries.any((entry) => entry.skillsVerified.isNotEmpty);
      }).toList();
    }

    // 5. Search Query Filter
    if (_filters.searchQuery.isNotEmpty) {
      final query = _filters.searchQuery.toLowerCase();
      filtered = filtered.where((trip) {
        return trip.title.toLowerCase().contains(query);
      }).toList();
    }

    // 6. Sort
    filtered = _sortTrips(filtered, logbookMap);

    // Calculate statistics
    final stats = _calculateStats(allTrips, filtered, logbookMap);

    return TripHistoryFilteredData(
      allTrips: allTrips,
      filteredTrips: filtered,
      logbookMap: logbookMap,
      stats: stats,
      filters: _filters,
    );
  }

  /// Sort trips based on selected sort option
  List<TripHistoryItem> _sortTrips(
    List<TripHistoryItem> trips,
    Map<int, List<LogbookEntry>> logbookMap,
  ) {
    final sorted = List<TripHistoryItem>.from(trips);

    switch (_filters.sortBy) {
      case TripHistorySortOption.dateNewest:
        sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case TripHistorySortOption.dateOldest:
        sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case TripHistorySortOption.skillsVerified:
        sorted.sort((a, b) {
          final aSkills = (logbookMap[a.tripId] ?? [])
              .expand((e) => e.skillsVerified)
              .length;
          final bSkills = (logbookMap[b.tripId] ?? [])
              .expand((e) => e.skillsVerified)
              .length;
          return _filters.sortDescending 
              ? bSkills.compareTo(aSkills)
              : aSkills.compareTo(bSkills);
        });
        break;
      case TripHistorySortOption.tripLevel:
        sorted.sort((a, b) {
          final aLevel = _getLevelNumber(a.level ?? '');
          final bLevel = _getLevelNumber(b.level ?? '');
          return _filters.sortDescending
              ? bLevel.compareTo(aLevel)
              : aLevel.compareTo(bLevel);
        });
        break;
      case TripHistorySortOption.title:
        sorted.sort((a, b) {
          return _filters.sortDescending
              ? b.title.compareTo(a.title)
              : a.title.compareTo(b.title);
        });
        break;
    }

    return sorted;
  }

  /// Calculate filter statistics
  TripHistoryFilterStats _calculateStats(
    List<TripHistoryItem> allTrips,
    List<TripHistoryItem> filteredTrips,
    Map<int, List<LogbookEntry>> logbookMap,
  ) {
    // Total skills verified across all trips
    final totalSkills = allTrips
        .expand((trip) => logbookMap[trip.tripId] ?? [])
        .expand((entry) => entry.skillsVerified)
        .toSet()
        .length;

    // Trips with skills verified
    final tripsWithSkills = filteredTrips.where((trip) {
      final entries = logbookMap[trip.tripId] ?? [];
      return entries.isNotEmpty && entries.any((e) => e.skillsVerified.isNotEmpty);
    }).length;

    // Level breakdown
    final levelCounts = <String, int>{};
    for (var trip in filteredTrips) {
      final level = trip.level ?? 'Unknown';
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }
    final levelBreakdown = levelCounts.entries
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    return TripHistoryFilterStats(
      totalTrips: allTrips.length,
      filteredTrips: filteredTrips.length,
      totalSkillsVerified: totalSkills,
      tripsWithSkills: tripsWithSkills,
      levelBreakdown: levelBreakdown,
    );
  }

  /// Helper to convert level name to numeric value
  int _getLevelNumber(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('beginner') || lower.contains('1')) return 1;
    if (lower.contains('intermediate') || lower.contains('2')) return 2;
    if (lower.contains('advanced') || lower.contains('3')) return 3;
    if (lower.contains('expert') || lower.contains('4')) return 4;
    return 0;
  }
}

/// Filtered Trip History Data Container
class TripHistoryFilteredData {
  final List<TripHistoryItem> allTrips;
  final List<TripHistoryItem> filteredTrips;
  final Map<int, List<LogbookEntry>> logbookMap;
  final TripHistoryFilterStats stats;
  final TripHistoryFilters filters;

  const TripHistoryFilteredData({
    required this.allTrips,
    required this.filteredTrips,
    required this.logbookMap,
    required this.stats,
    required this.filters,
  });

  /// Get logbook entries for a specific trip
  List<LogbookEntry> getLogbookEntries(int tripId) {
    return logbookMap[tripId] ?? [];
  }

  /// Get skills verified count for a specific trip
  int getSkillsVerifiedCount(int tripId) {
    final entries = logbookMap[tripId] ?? [];
    return entries.expand((e) => e.skillsVerified).toSet().length;
  }
}

/// Provider for trip history with filters
final tripHistoryFilterProvider = StateNotifierProvider.family
    .autoDispose<TripHistoryWithFiltersNotifier, AsyncValue<TripHistoryFilteredData>, int>(
  (ref, memberId) {
    final repository = ref.watch(mainApiRepositoryProvider);
    return TripHistoryWithFiltersNotifier(repository, memberId);
  },
);
