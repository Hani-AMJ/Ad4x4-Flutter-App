import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../data/models/trip_comment_model.dart';
import '../../../../data/models/trip_model.dart';  // For BasicMember
import '../../../../data/models/firestore_message_model.dart';

/// Trip Chat State - Manages comments/chat data
class TripChatState {
  final List<TripComment> comments;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;
  final bool useFirestore;  // NEW: Track which backend we're using
  final bool isRealtime;    // NEW: Track if real-time is active

  const TripChatState({
    this.comments = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.currentPage = 0,
    this.hasMore = false,
    this.useFirestore = false,
    this.isRealtime = false,
  });

  TripChatState copyWith({
    List<TripComment>? comments,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    bool? useFirestore,
    bool? isRealtime,
  }) {
    return TripChatState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      useFirestore: useFirestore ?? this.useFirestore,
      isRealtime: isRealtime ?? this.isRealtime,
    );
  }
}

/// Trip Chat Notifier - Hybrid Firestore + REST API implementation
/// 
/// Automatically detects Firebase Auth availability:
/// - If Firebase Auth active → Use Firestore real-time streams
/// - If Firebase Auth not available → Fall back to REST API
/// 
/// This ensures the chat always works, regardless of Firebase status.
class TripChatNotifier extends StateNotifier<TripChatState> {
  final Ref _ref;
  final int _tripId;
  StreamSubscription<List<FirestoreMessage>>? _firestoreSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  TripChatNotifier(this._ref, this._tripId) : super(const TripChatState()) {
    _initializeChatMode();
  }
  
  /// Detect if Firebase is available and decide chat mode
  Future<void> _initializeChatMode() async {
    try {
      // Check if Firebase Auth is active by attempting to get messages
      // This will throw if Firebase is not authenticated
      _firestoreService.getMessagesStream(tripId: _tripId);
      
      // If we get here, Firebase is working - enable Firestore mode
      print('✅ [TripChat] Firebase available - enabling real-time chat');
      state = state.copyWith(useFirestore: true);
      _subscribeToFirestore();
      
    } catch (e) {
      // Firebase not available - use REST API
      print('ℹ️  [TripChat] Firebase not available - using REST API');
      state = state.copyWith(useFirestore: false);
      loadComments();  // Load via REST API
    }
  }
  
  /// Subscribe to Firestore real-time updates
  void _subscribeToFirestore() {
    try {
      state = state.copyWith(isLoading: true, isRealtime: true);
      
      print('🔥 [TripChat] Subscribing to Firestore stream for trip $_tripId');
      
      _firestoreSubscription = _firestoreService
          .getMessagesStream(tripId: _tripId)
          .listen(
        (firestoreMessages) {
          print('📨 [TripChat] Received ${firestoreMessages.length} Firestore messages');
          
          // Convert FirestoreMessage to TripComment
          final comments = firestoreMessages.map((msg) {
            // Split name into first and last
            final nameParts = msg.authorName.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1 
                ? nameParts.skip(1).join(' ') 
                : null;
            
            return TripComment(
              id: int.tryParse(msg.id) ?? 0,
              tripId: _tripId,
              comment: msg.text,
              member: BasicMember(
                id: msg.authorId,  // Already int
                username: msg.authorUsername,
                firstName: firstName,
                lastName: lastName,
                profileImage: msg.authorAvatar,
              ),
              created: msg.timestamp,
            );
          }).toList();
          
          state = state.copyWith(
            comments: comments,
            isLoading: false,
            errorMessage: null,
          );
        },
        onError: (error) {
          print('❌ [TripChat] Firestore stream error: $error');
          // Fall back to REST API
          state = state.copyWith(useFirestore: false, isRealtime: false);
          loadComments();
        },
      );
      
    } catch (e) {
      print('❌ [TripChat] Failed to subscribe to Firestore: $e');
      // Fall back to REST API
      state = state.copyWith(useFirestore: false, isRealtime: false);
      loadComments();
    }
  }
  
  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

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

  /// Send a new comment (Hybrid: Firestore or REST API)
  Future<void> sendComment(String message) async {
    if (message.trim().isEmpty || state.isSending) return;

    state = state.copyWith(isSending: true);

    try {
      if (state.useFirestore) {
        // ✅ FIRESTORE MODE: Send to Firestore
        print('🔥 [TripChat] Sending message via Firestore...');
        
        // Get current user info from auth provider
        final authState = _ref.read(authProviderV2);
        final user = authState.user;
        
        if (user == null) {
          throw Exception('User not authenticated');
        }
        
        await _firestoreService.sendMessage(
          tripId: _tripId,
          text: message.trim(),
          authorId: user.id,  // Already int, no need to convert
          authorName: user.displayName,
          authorUsername: user.username,
          authorAvatar: user.avatar,
        );
        
        print('✅ [TripChat] Message sent via Firestore');
        // Stream will automatically update the UI
        state = state.copyWith(isSending: false);
        
      } else {
        // ✅ REST API MODE: Send to backend API
        final repository = _ref.read(mainApiRepositoryProvider);
        
        print('🔄 [TripChat] Sending comment via REST API: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
        
        final response = await repository.postTripComment(
          tripId: _tripId,
          comment: message.trim(),
        );

        print('📦 [TripChat] API Response: $response');

        // Try to parse the new comment from response
        try {
          final newComment = TripComment.fromJson(response);
          
          // Add to existing comments (append to end - chronological order)
          final updatedComments = [...state.comments, newComment];

          print('✅ [TripChat] Comment sent successfully via REST API');

          state = state.copyWith(
            comments: updatedComments,
            isSending: false,
          );
        } catch (parseError) {
          print('⚠️  [TripChat] Could not parse response, reloading all comments');
          
          // Reload all comments to get the new one
          state = state.copyWith(isSending: false);
          await loadComments();
        }
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
