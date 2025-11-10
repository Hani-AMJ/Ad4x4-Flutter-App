import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/trip_comment_model.dart';

/// Trip Chat State - Manages comments/chat data
class TripChatState {
  final List<TripComment> comments;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;

  const TripChatState({
    this.comments = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.currentPage = 0,
    this.hasMore = false,
  });

  TripChatState copyWith({
    List<TripComment>? comments,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
  }) {
    return TripChatState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Trip Chat Notifier - Manages chat state and API calls
class TripChatNotifier extends StateNotifier<TripChatState> {
  final Ref _ref;
  final int _tripId;

  TripChatNotifier(this._ref, this._tripId) : super(const TripChatState());

  /// Load comments for the trip
  Future<void> loadComments() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      comments: [],
      currentPage: 0,
      hasMore: false,
    );

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      
      print('🔄 [TripChat] Loading comments for trip $_tripId...');
      
      final response = await repository.getTripComments(
        tripId: _tripId,
        ordering: 'created',  // Oldest first (chronological order)
        page: 1,
        pageSize: 100,  // Load many messages at once
      );

      final totalCount = response['count'] as int? ?? 0;
      print('📊 [TripChat] Total comments: $totalCount');

      final commentsData = response['results'] as List<dynamic>?;
      if (commentsData == null) {
        throw Exception('Invalid response format: results field is null');
      }

      final loadedComments = <TripComment>[];
      for (var commentJson in commentsData) {
        try {
          if (commentJson is! Map<String, dynamic>) {
            print('⚠️  [TripChat] Invalid comment type: ${commentJson.runtimeType}');
            print('   Raw data: $commentJson');
            continue;
          }
          
          final comment = TripComment.fromJson(commentJson);
          loadedComments.add(comment);
        } catch (e, stackTrace) {
          print('❌ [TripChat] Error parsing comment: $e');
          print('   Comment JSON: $commentJson');
          print('   Stack trace: $stackTrace');
        }
      }

      final hasNext = response['next'] != null;

      print('✅ [TripChat] Loaded ${loadedComments.length} comments');

      state = state.copyWith(
        comments: loadedComments,
        isLoading: false,
        currentPage: 1,
        hasMore: hasNext,
      );
    } catch (e, stackTrace) {
      print('❌ [TripChat] Error loading comments: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      // Create detailed error message
      String errorMsg = 'Error: ${e.toString()}';
      if (e.runtimeType.toString().contains('DioException') || 
          e.runtimeType.toString().contains('DioError')) {
        errorMsg = 'Network error: Unable to connect to server';
      } else if (e.toString().contains('type') && e.toString().contains('is not a subtype')) {
        errorMsg = 'Data parsing error: API response format mismatch\n${e.toString()}';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  /// Send a new comment
  Future<void> sendComment(String message) async {
    if (message.trim().isEmpty || state.isSending) return;

    state = state.copyWith(isSending: true);

    try {
      final repository = _ref.read(mainApiRepositoryProvider);
      
      print('🔄 [TripChat] Sending comment: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      
      final response = await repository.postTripComment(
        tripId: _tripId,
        comment: message.trim(),
      );

      print('📦 [TripChat] API Response: $response');

      // Try to parse the new comment from response
      // If parsing fails, just reload all comments
      try {
        final newComment = TripComment.fromJson(response);
        
        // Add to existing comments (append to end - chronological order)
        final updatedComments = [...state.comments, newComment];

        print('✅ [TripChat] Comment sent successfully');

        state = state.copyWith(
          comments: updatedComments,
          isSending: false,
        );
      } catch (parseError) {
        print('⚠️  [TripChat] Could not parse response, reloading all comments');
        print('   Parse error: $parseError');
        
        // Reload all comments to get the new one
        state = state.copyWith(isSending: false);
        await loadComments();
      }
    } catch (e, stackTrace) {
      print('❌ [TripChat] Error sending comment: $e');
      print('   Stack trace: $stackTrace');
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Failed to send comment: ${e.toString()}',
      );
      rethrow;  // Let UI handle the error
    }
  }

  /// Refresh comments
  Future<void> refresh() async {
    await loadComments();
  }
}

/// Trip Chat Provider Factory
/// Creates a provider for a specific trip's chat
final tripChatProvider = StateNotifierProvider.family<TripChatNotifier, TripChatState, int>(
  (ref, tripId) {
    return TripChatNotifier(ref, tripId);
  },
);
