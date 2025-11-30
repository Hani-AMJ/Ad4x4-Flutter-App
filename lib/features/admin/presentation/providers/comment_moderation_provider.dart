import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/comment_moderation_model.dart';
import '../../../../core/providers/repository_providers.dart';

// ============================================================================
// ALL COMMENTS STATE
// ============================================================================

/// All Comments State - Manages all comments with moderation data
class AllCommentsState {
  final List<TripCommentWithModeration> comments;
  final int totalCount;
  final int pendingCount;
  final int flaggedCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int? tripFilter;
  final ModerationStatus? statusFilter;
  final bool flaggedOnly;

  const AllCommentsState({
    this.comments = const [],
    this.totalCount = 0,
    this.pendingCount = 0,
    this.flaggedCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.tripFilter,
    this.statusFilter,
    this.flaggedOnly = false,
  });

  AllCommentsState copyWith({
    List<TripCommentWithModeration>? comments,
    int? totalCount,
    int? pendingCount,
    int? flaggedCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? tripFilter,
    ModerationStatus? statusFilter,
    bool? flaggedOnly,
  }) {
    return AllCommentsState(
      comments: comments ?? this.comments,
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      flaggedCount: flaggedCount ?? this.flaggedCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tripFilter: tripFilter ?? this.tripFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      flaggedOnly: flaggedOnly ?? this.flaggedOnly,
    );
  }

  /// Get pending comments
  List<TripCommentWithModeration> get pendingComments =>
      comments.where((c) => c.isPending).toList();

  /// Get flagged comments
  List<TripCommentWithModeration> get flaggedComments =>
      comments.where((c) => c.flagged).toList();

  /// Get approved comments
  List<TripCommentWithModeration> get approvedComments =>
      comments.where((c) => c.approved).toList();
}

/// All Comments Notifier
class AllCommentsNotifier extends StateNotifier<AllCommentsState> {
  final Ref _ref;

  AllCommentsNotifier(this._ref) : super(const AllCommentsState());

  /// Load comments
  Future<void> loadComments({
    int? tripId,
    ModerationStatus? status,
    bool flaggedOnly = false,
    int page = 1,
  }) async {
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        tripFilter: tripId,
        statusFilter: status,
        flaggedOnly: flaggedOnly,
      );
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getAllComments(
        tripId: tripId,
        pendingOnly: status == ModerationStatus.pending,
        flaggedOnly: flaggedOnly,
        page: page,
        pageSize: 20,
      );

      final commentsResponse = CommentModerationResponse.fromJson(response);

      state = state.copyWith(
        comments: page == 1
            ? commentsResponse.results
            : [...state.comments, ...commentsResponse.results],
        totalCount: commentsResponse.count,
        pendingCount: commentsResponse.pendingCount,
        flaggedCount: commentsResponse.flaggedCount,
        currentPage: page,
        hasMore: commentsResponse.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more comments
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadComments(
        tripId: state.tripFilter,
        status: state.statusFilter,
        flaggedOnly: state.flaggedOnly,
        page: state.currentPage + 1,
      );
    }
  }

  /// Refresh comments
  Future<void> refresh() async {
    await loadComments(
      tripId: state.tripFilter,
      status: state.statusFilter,
      flaggedOnly: state.flaggedOnly,
      page: 1,
    );
  }

  /// Remove comment from list (after moderation)
  void removeComment(int commentId) {
    state = state.copyWith(
      comments: state.comments.where((c) => c.id != commentId).toList(),
      totalCount: state.totalCount - 1,
    );
  }

  /// Update comment in list
  void updateComment(TripCommentWithModeration updatedComment) {
    state = state.copyWith(
      comments: state.comments.map((c) {
        return c.id == updatedComment.id ? updatedComment : c;
      }).toList(),
    );
  }

  /// Clear filters
  void clearFilters() {
    state = const AllCommentsState();
  }
}

/// All Comments Provider
final allCommentsProvider =
    StateNotifierProvider<AllCommentsNotifier, AllCommentsState>((ref) {
      return AllCommentsNotifier(ref);
    });

// ============================================================================
// PENDING COMMENTS STATE
// ============================================================================

/// Pending Comments State - Specifically for approval queue
class PendingCommentsState {
  final List<TripCommentWithModeration> pendingComments;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const PendingCommentsState({
    this.pendingComments = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  PendingCommentsState copyWith({
    List<TripCommentWithModeration>? pendingComments,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PendingCommentsState(
      pendingComments: pendingComments ?? this.pendingComments,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Pending Comments Notifier
class PendingCommentsNotifier extends StateNotifier<PendingCommentsState> {
  final Ref _ref;

  PendingCommentsNotifier(this._ref) : super(const PendingCommentsState());

  /// Load pending comments
  Future<void> loadPending({int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getAllComments(
        pendingOnly: true,
        page: page,
        pageSize: 20,
      );

      final commentsResponse = CommentModerationResponse.fromJson(response);

      state = state.copyWith(
        pendingComments: page == 1
            ? commentsResponse.results
            : [...state.pendingComments, ...commentsResponse.results],
        totalCount: commentsResponse.count,
        currentPage: page,
        hasMore: commentsResponse.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more pending comments
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadPending(page: state.currentPage + 1);
    }
  }

  /// Refresh pending comments
  Future<void> refresh() async {
    await loadPending(page: 1);
  }

  /// Remove comment from pending list
  void removeComment(int commentId) {
    state = state.copyWith(
      pendingComments: state.pendingComments
          .where((c) => c.id != commentId)
          .toList(),
      totalCount: state.totalCount - 1,
    );
  }
}

/// Pending Comments Provider
final pendingCommentsProvider =
    StateNotifierProvider<PendingCommentsNotifier, PendingCommentsState>((ref) {
      return PendingCommentsNotifier(ref);
    });

// ============================================================================
// FLAGGED COMMENTS STATE
// ============================================================================

/// Flagged Comments State - User-reported comments
class FlaggedCommentsState {
  final List<TripCommentWithModeration> flaggedComments;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const FlaggedCommentsState({
    this.flaggedComments = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  FlaggedCommentsState copyWith({
    List<TripCommentWithModeration>? flaggedComments,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return FlaggedCommentsState(
      flaggedComments: flaggedComments ?? this.flaggedComments,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Flagged Comments Notifier
class FlaggedCommentsNotifier extends StateNotifier<FlaggedCommentsState> {
  final Ref _ref;

  FlaggedCommentsNotifier(this._ref) : super(const FlaggedCommentsState());

  /// Load flagged comments
  Future<void> loadFlagged({int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.getFlaggedComments(
        page: page,
        pageSize: 20,
      );

      final commentsResponse = CommentModerationResponse.fromJson(response);

      state = state.copyWith(
        flaggedComments: page == 1
            ? commentsResponse.results
            : [...state.flaggedComments, ...commentsResponse.results],
        totalCount: commentsResponse.count,
        currentPage: page,
        hasMore: commentsResponse.next != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load more flagged comments
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadFlagged(page: state.currentPage + 1);
    }
  }

  /// Refresh flagged comments
  Future<void> refresh() async {
    await loadFlagged(page: 1);
  }

  /// Remove comment from flagged list
  void removeComment(int commentId) {
    state = state.copyWith(
      flaggedComments: state.flaggedComments
          .where((c) => c.id != commentId)
          .toList(),
      totalCount: state.totalCount - 1,
    );
  }
}

/// Flagged Comments Provider
final flaggedCommentsProvider =
    StateNotifierProvider<FlaggedCommentsNotifier, FlaggedCommentsState>((ref) {
      return FlaggedCommentsNotifier(ref);
    });

// ============================================================================
// COMMENT MODERATION ACTIONS
// ============================================================================

/// Comment Moderation Actions Notifier
class CommentModerationActionsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  CommentModerationActionsNotifier(this._ref) : super(false);

  /// Approve comment
  Future<void> approveComment(int commentId) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.approveComment(commentId);

      // Update all comment lists
      _ref.read(pendingCommentsProvider.notifier).removeComment(commentId);
      _ref.read(allCommentsProvider.notifier).refresh();

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Reject comment
  Future<void> rejectComment(int commentId, {String? reason}) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.rejectComment(commentId: commentId, reason: reason);

      // Update all comment lists
      _ref.read(pendingCommentsProvider.notifier).removeComment(commentId);
      _ref.read(flaggedCommentsProvider.notifier).removeComment(commentId);
      _ref.read(allCommentsProvider.notifier).removeComment(commentId);

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Edit comment
  Future<void> editComment(int commentId, String newText) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      final response = await repository.editComment(
        commentId: commentId,
        newText: newText,
      );

      final updatedComment = TripCommentWithModeration.fromJson(response);

      // Update comment in all lists
      _ref.read(allCommentsProvider.notifier).updateComment(updatedComment);

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  /// Ban user from commenting
  Future<void> banUser({
    required int userId,
    required BanDuration duration,
    required String reason,
    bool notifyUser = true,
  }) async {
    state = true;
    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      await repository.banUserFromCommenting(
        userId: userId,
        duration: duration.name,
        reason: reason,
        notifyUser: notifyUser,
      );

      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

/// Comment Moderation Actions Provider
final commentModerationActionsProvider =
    StateNotifierProvider<CommentModerationActionsNotifier, bool>((ref) {
      return CommentModerationActionsNotifier(ref);
    });
