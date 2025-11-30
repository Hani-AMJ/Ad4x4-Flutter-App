import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/registration_analytics_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';

// ============================================================================
// REGISTRATION ANALYTICS STATE
// ============================================================================

/// Registration Analytics Provider - Family provider for trip analytics
final registrationAnalyticsProvider =
    FutureProvider.family<RegistrationAnalytics, int>((ref, tripId) async {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getRegistrationAnalytics(tripId);
      return RegistrationAnalytics.fromJson(response);
    });

// ============================================================================
// REGISTRATION LIST STATE
// ============================================================================

/// Registration List State - Manages detailed registration list
class RegistrationListState {
  final List<TripRegistrationWithAnalytics> registrations;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int? tripFilter;
  final String? statusFilter;
  final List<int> selectedIds;

  const RegistrationListState({
    this.registrations = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.tripFilter,
    this.statusFilter,
    this.selectedIds = const [],
  });

  RegistrationListState copyWith({
    List<TripRegistrationWithAnalytics>? registrations,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? tripFilter,
    String? statusFilter,
    List<int>? selectedIds,
  }) {
    return RegistrationListState(
      registrations: registrations ?? this.registrations,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tripFilter: tripFilter ?? this.tripFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Check if any registrations are selected
  bool get hasSelection => selectedIds.isNotEmpty;

  /// Get selected registrations
  List<TripRegistrationWithAnalytics> get selectedRegistrations => registrations
      .where((r) => selectedIds.contains(r.registration.id))
      .toList();
}

/// Registration List Notifier
class RegistrationListNotifier extends StateNotifier<RegistrationListState> {
  final Ref _ref;

  RegistrationListNotifier(this._ref) : super(const RegistrationListState());

  /// Load registrations
  Future<void> loadRegistrations({
    required int tripId,
    String? status,
    int page = 1,
  }) async {
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        tripFilter: tripId,
        statusFilter: status,
      );
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getDetailedRegistrations(
        tripId: tripId,
        status: status,
        page: page,
        pageSize: 20,
      );

      final results =
          (response['results'] as List<dynamic>?)
              ?.map(
                (item) => TripRegistrationWithAnalytics.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [];

      state = state.copyWith(
        registrations: page == 1
            ? results
            : [...state.registrations, ...results],
        totalCount: response['count'] as int? ?? 0,
        currentPage: page,
        hasMore: response['next'] != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more registrations
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore && state.tripFilter != null) {
      await loadRegistrations(
        tripId: state.tripFilter!,
        status: state.statusFilter,
        page: state.currentPage + 1,
      );
    }
  }

  /// Refresh registrations
  Future<void> refresh() async {
    if (state.tripFilter != null) {
      await loadRegistrations(
        tripId: state.tripFilter!,
        status: state.statusFilter,
        page: 1,
      );
    }
  }

  /// Toggle registration selection
  void toggleSelection(int registrationId) {
    final selected = List<int>.from(state.selectedIds);
    if (selected.contains(registrationId)) {
      selected.remove(registrationId);
    } else {
      selected.add(registrationId);
    }
    state = state.copyWith(selectedIds: selected);
  }

  /// Select all registrations
  void selectAll() {
    state = state.copyWith(
      selectedIds: state.registrations.map((r) => r.registration.id).toList(),
    );
  }

  /// Deselect all registrations
  void deselectAll() {
    state = state.copyWith(selectedIds: []);
  }

  /// Clear state
  void clear() {
    state = const RegistrationListState();
  }
}

/// Registration List Provider
final registrationListProvider =
    StateNotifierProvider<RegistrationListNotifier, RegistrationListState>((
      ref,
    ) {
      return RegistrationListNotifier(ref);
    });

// ============================================================================
// REGISTRATION BULK ACTIONS
// ============================================================================

/// Registration Bulk Actions Notifier
class RegistrationBulkActionsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  RegistrationBulkActionsNotifier(this._ref) : super(false);

  /// Bulk approve registrations
  Future<void> bulkApprove(List<int> registrationIds) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.bulkApproveRegistrations(registrationIds);

      // Refresh registration list
      _ref.read(registrationListProvider.notifier).refresh();

      // Refresh analytics
      final tripId = _ref.read(registrationListProvider).tripFilter;
      if (tripId != null) {
        _ref.invalidate(registrationAnalyticsProvider(tripId));
      }

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Bulk reject registrations
  Future<void> bulkReject(List<int> registrationIds, {String? reason}) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.bulkRejectRegistrations(
        registrationIds: registrationIds,
        reason: reason,
      );

      // Refresh registration list
      _ref.read(registrationListProvider.notifier).refresh();

      // Refresh analytics
      final tripId = _ref.read(registrationListProvider).tripFilter;
      if (tripId != null) {
        _ref.invalidate(registrationAnalyticsProvider(tripId));
      }

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Bulk check-in registrations
  Future<void> bulkCheckin(List<int> registrationIds) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.bulkCheckinRegistrations(registrationIds);

      // Refresh registration list
      _ref.read(registrationListProvider.notifier).refresh();

      // Refresh analytics
      final tripId = _ref.read(registrationListProvider).tripFilter;
      if (tripId != null) {
        _ref.invalidate(registrationAnalyticsProvider(tripId));
      }

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Send notification to registrants
  Future<void> notifyRegistrants({
    required int tripId,
    required String message,
    List<int>? memberIds,
    String notificationType = 'general',
    bool pushNotification = true,
    bool emailNotification = false,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.notifyRegistrants(
        tripId: tripId,
        message: message,
        memberIds: memberIds,
        notificationType: notificationType,
        pushNotification: pushNotification,
        emailNotification: emailNotification,
      );

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

/// Registration Bulk Actions Provider
final registrationBulkActionsProvider =
    StateNotifierProvider<RegistrationBulkActionsNotifier, bool>((ref) {
      return RegistrationBulkActionsNotifier(ref);
    });

// ============================================================================
// WAITLIST MANAGEMENT STATE
// ============================================================================

/// Waitlist Management State
class WaitlistManagementState {
  final List<TripWaitlist> waitlist;
  final int totalCount;
  final bool isLoading;
  final String? error;
  final int? tripFilter;
  final List<int> selectedIds;

  const WaitlistManagementState({
    this.waitlist = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.tripFilter,
    this.selectedIds = const [],
  });

  WaitlistManagementState copyWith({
    List<TripWaitlist>? waitlist,
    int? totalCount,
    bool? isLoading,
    String? error,
    int? tripFilter,
    List<int>? selectedIds,
  }) {
    return WaitlistManagementState(
      waitlist: waitlist ?? this.waitlist,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tripFilter: tripFilter ?? this.tripFilter,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Check if any waitlist members are selected
  bool get hasSelection => selectedIds.isNotEmpty;

  /// Get selected waitlist members
  List<TripWaitlist> get selectedMembers =>
      waitlist.where((w) => selectedIds.contains(w.member.id)).toList();
}

/// Waitlist Management Notifier
class WaitlistManagementNotifier
    extends StateNotifier<WaitlistManagementState> {
  final Ref _ref;

  WaitlistManagementNotifier(this._ref)
    : super(const WaitlistManagementState());

  /// Load waitlist
  Future<void> loadWaitlist(int tripId) async {
    state = state.copyWith(isLoading: true, error: null, tripFilter: tripId);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getTripDetail(tripId);

      final waitlistData = response['waitlist'] as List<dynamic>? ?? [];
      final waitlist = waitlistData
          .map((item) => TripWaitlist.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        waitlist: waitlist,
        totalCount: waitlist.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh waitlist
  Future<void> refresh() async {
    if (state.tripFilter != null) {
      await loadWaitlist(state.tripFilter!);
    }
  }

  /// Toggle member selection
  void toggleSelection(int memberId) {
    final selected = List<int>.from(state.selectedIds);
    if (selected.contains(memberId)) {
      selected.remove(memberId);
    } else {
      selected.add(memberId);
    }
    state = state.copyWith(selectedIds: selected);
  }

  /// Select all waitlist members
  void selectAll() {
    state = state.copyWith(
      selectedIds: state.waitlist.map((w) => w.member.id).toList(),
    );
  }

  /// Deselect all
  void deselectAll() {
    state = state.copyWith(selectedIds: []);
  }

  /// Move members to registered
  Future<void> moveToRegistered({
    required List<int> memberIds,
    bool notifyMembers = true,
  }) async {
    if (state.tripFilter == null) return;

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.bulkMoveFromWaitlist(
        tripId: state.tripFilter!,
        memberIds: memberIds,
        notifyMembers: notifyMembers,
      );

      // Refresh waitlist and registration list
      await refresh();
      _ref.read(registrationListProvider.notifier).refresh();

      // Refresh analytics
      _ref.invalidate(registrationAnalyticsProvider(state.tripFilter!));

      // Clear selection
      state = state.copyWith(selectedIds: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Reorder waitlist
  Future<void> reorder(List<WaitlistPosition> positions) async {
    if (state.tripFilter == null) return;

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.reorderWaitlist(
        tripId: state.tripFilter!,
        positions: positions
            .map((p) => {'member_id': p.memberId, 'position': p.newPosition})
            .toList(),
      );

      // Refresh waitlist
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear state
  void clear() {
    state = const WaitlistManagementState();
  }
}

/// Waitlist Management Provider
final waitlistManagementProvider =
    StateNotifierProvider<WaitlistManagementNotifier, WaitlistManagementState>((
      ref,
    ) {
      return WaitlistManagementNotifier(ref);
    });

// ============================================================================
// EXPORT STATE
// ============================================================================

/// Export State - Tracks export progress
class ExportState {
  final bool isExporting;
  final String? downloadUrl;
  final String? error;

  const ExportState({this.isExporting = false, this.downloadUrl, this.error});

  ExportState copyWith({
    bool? isExporting,
    String? downloadUrl,
    String? error,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      downloadUrl: downloadUrl,
      error: error,
    );
  }
}

/// Export Notifier
class ExportNotifier extends StateNotifier<ExportState> {
  final Ref _ref;

  ExportNotifier(this._ref) : super(const ExportState());

  /// Export registrations
  Future<void> exportRegistrations({
    required int tripId,
    required String format,
    List<String>? fields,
    List<String>? statuses,
  }) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.exportRegistrations(
        tripId: tripId,
        format: format,
        fields: fields,
        statuses: statuses,
      );

      final exportResponse = RegistrationExportResponse.fromJson(response);

      state = state.copyWith(
        isExporting: false,
        downloadUrl: exportResponse.downloadUrl,
      );
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  /// Clear export state
  void clear() {
    state = const ExportState();
  }
}

/// Export Provider
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((
  ref,
) {
  return ExportNotifier(ref);
});
