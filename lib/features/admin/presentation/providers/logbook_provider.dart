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
  Future<void> loadEntries({
    int? memberId,
    int? tripId,
    int page = 1,
  }) async {
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
        limit: 20,
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
    await loadEntries(
      memberId: state.memberFilter,
      tripId: state.tripFilter,
    );
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
    state = state.copyWith(
      isLoading: true,
      error: null,
      levelFilter: levelId,
    );

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getLogbookSkills(
        levelId: levelId,
        limit: 100, // Get all skills
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
  final response = await repository.getMemberLogbookSkills(memberId);

  // API returns {'results': [...]} format
  final results = response['results'] as List<dynamic>?;
  if (results == null) return [];

  return results
      .map((item) => MemberSkillStatus.fromJson(item as Map<String, dynamic>))
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
        tripId: tripId,
        comment: comment,
      );

      // Invalidate member skills to refresh
      _ref.invalidate(memberSkillsStatusProvider);
    } finally {
      state = false;
    }
  }

  /// Create a trip report
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
      await repository.createTripReport(
        tripId: tripId,
        report: report,
        safetyNotes: safetyNotes,
        weatherConditions: weatherConditions,
        terrainNotes: terrainNotes,
        participantCount: participantCount,
        issues: issues,
      );
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
