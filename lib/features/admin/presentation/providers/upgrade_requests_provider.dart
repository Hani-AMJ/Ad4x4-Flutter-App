import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/upgrade_request_model.dart';

/// Upgrade Requests State - Manages upgrade requests data and loading state
class UpgradeRequestsState {
  final List<UpgradeRequestListItem> requests;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? statusFilter; // 'pending', 'approved', 'declined', or null for all

  const UpgradeRequestsState({
    this.requests = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.statusFilter,
  });

  UpgradeRequestsState copyWith({
    List<UpgradeRequestListItem>? requests,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? statusFilter,
  }) {
    return UpgradeRequestsState(
      requests: requests ?? this.requests,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  // Filter requests by status
  List<UpgradeRequestListItem> get allRequests => requests;
  
  List<UpgradeRequestListItem> get pendingRequests {
    return requests.where((r) => r.isPending).toList();
  }
  
  List<UpgradeRequestListItem> get approvedRequests {
    return requests.where((r) => r.isApproved).toList();
  }
  
  List<UpgradeRequestListItem> get declinedRequests {
    return requests.where((r) => r.isDeclined).toList();
  }
}

/// Upgrade Requests Notifier - Manages upgrade requests state and API calls
class UpgradeRequestsNotifier extends StateNotifier<UpgradeRequestsState> {
  final Ref _ref;

  UpgradeRequestsNotifier(this._ref) : super(const UpgradeRequestsState());

  /// Load upgrade requests from API with optional status filter
  Future<void> loadRequests({String? status}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      statusFilter: status,
      requests: [], // Clear existing requests
      currentPage: 0,
      totalCount: 0,
      hasMore: false,
    );

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      
      final response = await repository.getUpgradeRequests(
        status: status,
        page: 1,
        limit: 20,
      );

      final upgradeRequestsResponse = UpgradeRequestsResponse.fromJson(response);

      state = state.copyWith(
        requests: upgradeRequestsResponse.results,
        totalCount: upgradeRequestsResponse.count,
        currentPage: 1,
        hasMore: upgradeRequestsResponse.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load upgrade requests: $e',
      );
    }
  }

  /// Load more upgrade requests (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final nextPage = state.currentPage + 1;

      final response = await repository.getUpgradeRequests(
        status: state.statusFilter,
        page: nextPage,
        limit: 20,
      );

      final upgradeRequestsResponse = UpgradeRequestsResponse.fromJson(response);

      state = state.copyWith(
        requests: [...state.requests, ...upgradeRequestsResponse.results],
        currentPage: nextPage,
        hasMore: upgradeRequestsResponse.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more requests: $e',
      );
    }
  }

  /// Refresh current requests
  Future<void> refresh() async {
    await loadRequests(status: state.statusFilter);
  }

  /// Update status filter and reload
  Future<void> setStatusFilter(String? status) async {
    await loadRequests(status: status);
  }
}

/// Upgrade Requests Provider
final upgradeRequestsProvider = StateNotifierProvider<UpgradeRequestsNotifier, UpgradeRequestsState>((ref) {
  return UpgradeRequestsNotifier(ref);
});

/// Individual Upgrade Request Detail Provider
final upgradeRequestDetailProvider = FutureProvider.family<UpgradeRequestDetail, int>((ref, requestId) async {
  final repository = ref.read(mainApiRepositoryProvider);
  final response = await repository.getUpgradeRequestDetail(requestId);
  return UpgradeRequestDetail.fromJson(response);
});

/// Upgrade Request Actions State
class UpgradeRequestActionsState {
  final bool isVoting;
  final bool isCommenting;
  final bool isApproving;
  final bool isDeclining;
  final String? errorMessage;

  const UpgradeRequestActionsState({
    this.isVoting = false,
    this.isCommenting = false,
    this.isApproving = false,
    this.isDeclining = false,
    this.errorMessage,
  });

  UpgradeRequestActionsState copyWith({
    bool? isVoting,
    bool? isCommenting,
    bool? isApproving,
    bool? isDeclining,
    String? errorMessage,
  }) {
    return UpgradeRequestActionsState(
      isVoting: isVoting ?? this.isVoting,
      isCommenting: isCommenting ?? this.isCommenting,
      isApproving: isApproving ?? this.isApproving,
      isDeclining: isDeclining ?? this.isDeclining,
      errorMessage: errorMessage,
    );
  }
}

/// Upgrade Request Actions Notifier - Handles vote, comment, approve/decline actions
class UpgradeRequestActionsNotifier extends StateNotifier<UpgradeRequestActionsState> {
  final Ref _ref;

  UpgradeRequestActionsNotifier(this._ref) : super(const UpgradeRequestActionsState());

  /// Vote on an upgrade request
  Future<void> vote({
    required int requestId,
    required bool approve,
    String? comment,
  }) async {
    state = state.copyWith(isVoting: true, errorMessage: null);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.voteUpgradeRequest(
        requestId: requestId,
        approve: approve,
        comment: comment,
      );

      state = state.copyWith(isVoting: false);
      
      // Invalidate detail provider to refresh data
      _ref.invalidate(upgradeRequestDetailProvider(requestId));
    } catch (e) {
      state = state.copyWith(
        isVoting: false,
        errorMessage: 'Failed to submit vote: $e',
      );
      rethrow;
    }
  }

  /// Add comment to upgrade request
  Future<void> addComment({
    required int requestId,
    required String text,
  }) async {
    state = state.copyWith(isCommenting: true, errorMessage: null);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.createUpgradeRequestComment(
        requestId: requestId,
        text: text,
      );

      state = state.copyWith(isCommenting: false);
      
      // Invalidate detail provider to refresh data
      _ref.invalidate(upgradeRequestDetailProvider(requestId));
    } catch (e) {
      state = state.copyWith(
        isCommenting: false,
        errorMessage: 'Failed to add comment: $e',
      );
      rethrow;
    }
  }

  /// Delete comment from upgrade request
  Future<void> deleteComment({
    required int requestId,
    required int commentId,
  }) async {
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.deleteUpgradeRequestComment(commentId);

      // Invalidate detail provider to refresh data
      _ref.invalidate(upgradeRequestDetailProvider(requestId));
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete comment: $e');
      rethrow;
    }
  }

  /// Approve upgrade request (final approval)
  Future<void> approve(int requestId) async {
    state = state.copyWith(isApproving: true, errorMessage: null);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.approveUpgradeRequest(requestId);

      state = state.copyWith(isApproving: false);
      
      // Refresh both detail and list
      _ref.invalidate(upgradeRequestDetailProvider(requestId));
      _ref.read(upgradeRequestsProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(
        isApproving: false,
        errorMessage: 'Failed to approve request: $e',
      );
      rethrow;
    }
  }

  /// Decline upgrade request (final decline)
  Future<void> decline({
    required int requestId,
    required String reason,
  }) async {
    state = state.copyWith(isDeclining: true, errorMessage: null);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.declineUpgradeRequest(
        requestId: requestId,
        reason: reason,
      );

      state = state.copyWith(isDeclining: false);
      
      // Refresh both detail and list
      _ref.invalidate(upgradeRequestDetailProvider(requestId));
      _ref.read(upgradeRequestsProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(
        isDeclining: false,
        errorMessage: 'Failed to decline request: $e',
      );
      rethrow;
    }
  }
}

/// Upgrade Request Actions Provider
final upgradeRequestActionsProvider = StateNotifierProvider<UpgradeRequestActionsNotifier, UpgradeRequestActionsState>((ref) {
  return UpgradeRequestActionsNotifier(ref);
});
