import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../core/providers/repository_providers.dart';

// ============================================================================
// LOGBOOK ENTRIES STATE
// ============================================================================

/// Logbook Entries State
class LogbookEntriesState {
  final List<LogbookEntry> entries;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int? memberFilter;
  final int? tripFilter;

  const LogbookEntriesState({
    this.entries = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.memberFilter,
    this.tripFilter,
  });

  LogbookEntriesState copyWith({
    List<LogbookEntry>? entries,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? memberFilter,
    int? tripFilter,
  }) {
    return LogbookEntriesState(
      entries: entries ?? this.entries,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberFilter: memberFilter ?? this.memberFilter,
      tripFilter: tripFilter ?? this.tripFilter,
    );
  }
}

/// Logbook Entries Notifier
class LogbookEntriesNotifier extends StateNotifier<LogbookEntriesState> {
  final Ref _ref;

  LogbookEntriesNotifier(this._ref) : super(const LogbookEntriesState());

  /// Load logbook entries
  Future<void> loadEntries({int? memberId, int? tripId, int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        memberFilter: memberId,
        tripFilter: tripId,
      );
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getLogbookEntries(
        memberId: memberId,
        tripId: tripId,
        page: page,
        pageSize: 20,
      );

      final entriesResponse = LogbookEntriesResponse.fromJson(response);

      if (page == 1) {
        state = state.copyWith(
          entries: entriesResponse.results,
          totalCount: entriesResponse.count,
          currentPage: page,
          hasMore: entriesResponse.hasMore,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          entries: [...state.entries, ...entriesResponse.results],
          currentPage: page,
          hasMore: entriesResponse.hasMore,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load logbook entries: $e',
      );
    }
  }

  /// Load more entries (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadEntries(
      memberId: state.memberFilter,
      tripId: state.tripFilter,
      page: state.currentPage + 1,
    );
  }

  /// Set member filter
  Future<void> setMemberFilter(int? memberId) async {
    await loadEntries(memberId: memberId, tripId: state.tripFilter);
  }

  /// Set trip filter
  Future<void> setTripFilter(int? tripId) async {
    await loadEntries(memberId: state.memberFilter, tripId: tripId);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    await loadEntries();
  }

  /// Refresh entries
  Future<void> refresh() async {
    await loadEntries(memberId: state.memberFilter, tripId: state.tripFilter);
  }
}

/// Logbook Entries Provider
final logbookEntriesProvider =
    StateNotifierProvider<LogbookEntriesNotifier, LogbookEntriesState>((ref) {
      return LogbookEntriesNotifier(ref);
    });

// ============================================================================
// LOGBOOK SKILLS STATE
// ============================================================================

/// Logbook Skills State
class LogbookSkillsState {
  final List<LogbookSkill> skills;
  final int totalCount;
  final bool isLoading;
  final String? error;
  final int? levelFilter;

  const LogbookSkillsState({
    this.skills = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.levelFilter,
  });

  LogbookSkillsState copyWith({
    List<LogbookSkill>? skills,
    int? totalCount,
    bool? isLoading,
    String? error,
    int? levelFilter,
  }) {
    return LogbookSkillsState(
      skills: skills ?? this.skills,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      levelFilter: levelFilter ?? this.levelFilter,
    );
  }

  /// Get skills grouped by level
  Map<LevelBasicInfo, List<LogbookSkill>> get skillsByLevel {
    final grouped = <LevelBasicInfo, List<LogbookSkill>>{};
    for (final skill in skills) {
      grouped.putIfAbsent(skill.level, () => []).add(skill);
    }
    return grouped;
  }
}

/// Logbook Skills Notifier
class LogbookSkillsNotifier extends StateNotifier<LogbookSkillsState> {
  final Ref _ref;

  LogbookSkillsNotifier(this._ref) : super(const LogbookSkillsState());

  /// Load all logbook skills
  Future<void> loadSkills({int? levelId}) async {
    state = state.copyWith(isLoading: true, error: null, levelFilter: levelId);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getLogbookSkills(
        levelEq: levelId,
        pageSize: 100, // Get all skills
      );

      final skillsResponse = LogbookSkillsResponse.fromJson(response);

      state = state.copyWith(
        skills: skillsResponse.results,
        totalCount: skillsResponse.count,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load logbook skills: $e',
      );
    }
  }

  /// Set level filter
  Future<void> setLevelFilter(int? levelId) async {
    await loadSkills(levelId: levelId);
  }

  /// Clear filter
  Future<void> clearFilter() async {
    await loadSkills();
  }

  /// Refresh skills
  Future<void> refresh() async {
    await loadSkills(levelId: state.levelFilter);
  }
}

/// Logbook Skills Provider
final logbookSkillsProvider =
    StateNotifierProvider<LogbookSkillsNotifier, LogbookSkillsState>((ref) {
      return LogbookSkillsNotifier(ref);
    });

// ============================================================================
// MEMBER SKILLS STATUS PROVIDER
// ============================================================================

/// Member Skills Status Provider (by member ID)
final memberSkillsStatusProvider =
    FutureProvider.family<List<MemberSkillStatus>, int>((ref, memberId) async {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getMemberLogbookSkills(
        memberId: memberId,
      );

      // API returns {'results': [...]} format
      final results = response['results'] as List<dynamic>?;
      if (results == null) return [];

      return results
          .map(
            (item) => MemberSkillStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });

// ============================================================================
// LOGBOOK ACTIONS PROVIDER
// ============================================================================

/// Logbook Actions Provider
class LogbookActionsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  LogbookActionsNotifier(this._ref) : super(false);

  /// Create a new logbook entry
  Future<void> createEntry({
    required int tripId,
    required int memberId,
    required List<int> skillIds,
    String? comment,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.createLogbookEntry(
        tripId: tripId,
        memberId: memberId,
        skillIds: skillIds,
        comment: comment,
      );

      // Invalidate entries to refresh
      _ref.invalidate(logbookEntriesProvider);
      _ref.invalidate(memberSkillsStatusProvider);
    } finally {
      state = false;
    }
  }

  /// Sign off on a skill
  Future<void> signOffSkill({
    required int memberId,
    required int skillId,
    int? tripId,
    String? comment,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.signOffSkill(
        memberId: memberId,
        skillId: skillId,
        tripId: tripId ?? 0, // tripId is required by API
      );

      // Invalidate member skills to refresh
      _ref.invalidate(memberSkillsStatusProvider);
    } finally {
      state = false;
    }
  }

  /// Create a trip report
  /// Serializes structured data into reportText for backend compatibility
  Future<void> createTripReport({
    required int tripId,
    required String report,
    String? safetyNotes,
    String? weatherConditions,
    String? terrainNotes,
    int? participantCount,
    List<String>? issues,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);

      // ✅ Serialize all structured data into reportText
      final reportText = TripReportSerializer.serialize(
        mainReport: report,
        safetyNotes: safetyNotes,
        weatherConditions: weatherConditions,
        terrainNotes: terrainNotes,
        participantCount: participantCount,
        issues: issues,
      );

      await repository.createTripReport(
        tripId: tripId,
        title: 'Trip Report', // Required field
        reportText: reportText,
      );

      // Invalidate trip reports to refresh list
      _ref.read(tripReportsProvider.notifier).refresh();
    } finally {
      state = false;
    }
  }

  /// Update a trip report
  /// Serializes structured data into reportText for backend compatibility
  Future<void> updateTripReport({
    required int reportId,
    required int tripId,
    required String report,
    String? safetyNotes,
    String? weatherConditions,
    String? terrainNotes,
    int? participantCount,
    List<String>? issues,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);

      // ✅ Serialize all structured data into reportText
      final reportText = TripReportSerializer.serialize(
        mainReport: report,
        safetyNotes: safetyNotes,
        weatherConditions: weatherConditions,
        terrainNotes: terrainNotes,
        participantCount: participantCount,
        issues: issues,
      );

      await repository.updateTripReport(
        id: reportId,
        tripId: tripId,
        title: 'Trip Report', // Required field
        reportText: reportText,
      );

      // Invalidate trip reports to refresh list
      _ref.read(tripReportsProvider.notifier).refresh();
    } finally {
      state = false;
    }
  }
}

/// Logbook Actions Provider
final logbookActionsProvider =
    StateNotifierProvider<LogbookActionsNotifier, bool>((ref) {
      return LogbookActionsNotifier(ref);
    });

// ============================================================================
// TRIP REPORTS STATE
// ============================================================================

/// Trip Reports State
class TripReportsState {
  final List<TripReport> reports;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int? tripFilter;
  final int? memberFilter;
  final String ordering;

  const TripReportsState({
    this.reports = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.tripFilter,
    this.memberFilter,
    this.ordering = '-createdAt', // Newest first by default
  });

  TripReportsState copyWith({
    List<TripReport>? reports,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? tripFilter,
    int? memberFilter,
    String? ordering,
  }) {
    return TripReportsState(
      reports: reports ?? this.reports,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tripFilter: tripFilter ?? this.tripFilter,
      memberFilter: memberFilter ?? this.memberFilter,
      ordering: ordering ?? this.ordering,
    );
  }
}

/// Trip Reports Notifier
class TripReportsNotifier extends StateNotifier<TripReportsState> {
  final Ref _ref;

  TripReportsNotifier(this._ref) : super(const TripReportsState());

  /// Load trip reports
  Future<void> loadReports({
    int? tripId,
    int? memberId,
    String? ordering,
    int page = 1,
  }) async {
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        tripFilter: tripId,
        memberFilter: memberId,
        ordering: ordering ?? state.ordering,
      );
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);

      // Step 1: Get list of report IDs (minimal data)
      final response = await repository.getTripReports(
        tripId: tripId,
        memberId: memberId,
        ordering: ordering ?? state.ordering,
        page: page,
        pageSize: 20,
      );

      final listResults = (response['results'] as List<dynamic>?) ?? [];
      final count = response['count'] as int? ?? 0;
      final hasMore = response['next'] != null;

      // Step 2: Fetch full details for each report
      final results = <TripReport>[];

      for (final item in listResults) {
        try {
          if (item is! Map<String, dynamic>) continue;

          final reportId = item['id'] as int?;
          final reportTripId = item['trip'] as int?;
          if (reportId == null) continue;

          // Fetch full detail data
          final detailData = await repository.getTripReportDetail(reportId);

          // Fetch trip details if we have trip ID
          if (reportTripId != null) {
            try {
              final tripData = await repository.getTripDetail(reportTripId);
              final enrichedData = Map<String, dynamic>.from(detailData);
              enrichedData['trip'] = tripData;
              results.add(TripReport.fromJson(enrichedData));
            } catch (e) {
              // If trip fetch fails, use detail data as-is
              if (kDebugMode) {
                debugPrint('⚠️ Could not fetch trip $reportTripId: $e');
              }
              results.add(TripReport.fromJson(detailData));
            }
          } else {
            results.add(TripReport.fromJson(detailData));
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Error fetching report detail: $e');
            debugPrint('   Stack: $stackTrace');
          }
        }
      }

      if (page == 1) {
        state = state.copyWith(
          reports: results,
          totalCount: count,
          currentPage: page,
          hasMore: hasMore,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          reports: [...state.reports, ...results],
          currentPage: page,
          hasMore: hasMore,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trip reports: $e',
      );
    }
  }

  /// Load more reports (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadReports(
      tripId: state.tripFilter,
      memberId: state.memberFilter,
      ordering: state.ordering,
      page: state.currentPage + 1,
    );
  }

  /// Set trip filter
  Future<void> setTripFilter(int? tripId) async {
    await loadReports(
      tripId: tripId,
      memberId: state.memberFilter,
      ordering: state.ordering,
    );
  }

  /// Set member filter
  Future<void> setMemberFilter(int? memberId) async {
    await loadReports(
      tripId: state.tripFilter,
      memberId: memberId,
      ordering: state.ordering,
    );
  }

  /// Set ordering
  Future<void> setOrdering(String ordering) async {
    await loadReports(
      tripId: state.tripFilter,
      memberId: state.memberFilter,
      ordering: ordering,
    );
  }

  /// Clear filters
  Future<void> clearFilters() async {
    await loadReports(ordering: state.ordering);
  }

  /// Refresh reports
  Future<void> refresh() async {
    await loadReports(
      tripId: state.tripFilter,
      memberId: state.memberFilter,
      ordering: state.ordering,
    );
  }

  /// Delete a report
  Future<void> deleteReport(int reportId) async {
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.deleteTripReport(reportId);

      // Remove from local state
      state = state.copyWith(
        reports: state.reports.where((r) => r.id != reportId).toList(),
        totalCount: state.totalCount - 1,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete report: $e');
      rethrow;
    }
  }
}

/// Trip Reports Provider
final tripReportsProvider =
    StateNotifierProvider<TripReportsNotifier, TripReportsState>((ref) {
      return TripReportsNotifier(ref);
    });

/// Trip Reports by Trip ID Provider
/// Fetches all trip reports for a specific trip with FULL details
///
/// ⚠️ CRITICAL: The list endpoint returns minimal data (no reportText, no member info)
/// We must fetch the detail endpoint for each report to get complete data
final tripReportsByTripProvider = FutureProvider.family<List<TripReport>, int>((
  ref,
  tripId,
) async {
  final repository = ref.read(mainApiRepositoryProvider);

  if (kDebugMode) {
    debugPrint('🔍 [TripReports] Fetching reports for trip $tripId');
  }

  // Step 1: Get list of report IDs from list endpoint (minimal data)
  final listResponse = await repository.getTripReports(
    tripId: tripId,
    ordering: '-createdAt',
    pageSize: 100,
  );

  final listResults = (listResponse['results'] as List<dynamic>?) ?? [];

  if (kDebugMode) {
    debugPrint('🔍 [TripReports] Found ${listResults.length} reports in list');
  }

  // Step 2: Fetch full details for each report
  final reports = <TripReport>[];

  for (final item in listResults) {
    try {
      if (item is! Map<String, dynamic>) continue;

      final reportId = item['id'] as int?;
      if (reportId == null) continue;

      if (kDebugMode) {
        debugPrint('   📥 Fetching detail for report #$reportId');
      }

      // Fetch full detail data
      final detailData = await repository.getTripReportDetail(reportId);

      // Also fetch trip details to get full trip info
      final tripData = await repository.getTripDetail(tripId);

      // Merge trip data into detail response
      final enrichedData = Map<String, dynamic>.from(detailData);
      enrichedData['trip'] = tripData;

      final report = TripReport.fromJson(enrichedData);
      reports.add(report);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching report detail: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }
  }

  if (kDebugMode) {
    debugPrint(
      '✅ [TripReports] Successfully loaded ${reports.length} full reports',
    );
  }

  return reports;
});
