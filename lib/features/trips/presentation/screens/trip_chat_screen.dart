import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/trip_comment_model.dart';
import '../providers/trip_chat_provider.dart';
import '../providers/trips_provider.dart';

/// Trip Chat Screen V3
/// 
/// Enhanced chat with:
/// - Auto-scroll to latest
/// - Different alignment for own vs others
/// - Trip context header
/// - Relative timestamps
/// - Fade-in animations
class TripChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripTitle;

  const TripChatScreen({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load comments and scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripId = int.tryParse(widget.tripId);
      if (tripId != null) {
        ref.read(tripChatProvider(tripId).notifier).loadComments();
        // Auto-scroll to latest message after load
        Future.delayed(const Duration(milliseconds: 800), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final tripId = int.tryParse(widget.tripId);
    if (tripId == null) return;

    try {
      await ref.read(tripChatProvider(tripId).notifier).sendComment(message);
      _messageController.clear();
      
      // Auto-refresh and scroll to bottom
      await Future.delayed(const Duration(milliseconds: 500));
      await ref.read(tripChatProvider(tripId).notifier).refresh();
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshComments() async {
    final tripId = int.tryParse(widget.tripId);
    if (tripId != null) {
      await ref.read(tripChatProvider(tripId).notifier).refresh();
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final tripId = int.tryParse(widget.tripId);
    if (tripId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid trip ID')),
      );
    }

    final chatState = ref.watch(tripChatProvider(tripId));
    final authState = ref.watch(authProviderV2);
    final currentUserId = authState.user?.id ?? 0;

    // Get trip details for context header
    final tripsState = ref.watch(tripsProvider);
    final trip = tripsState.trips.firstWhere(
      (t) => t.id == tripId,
      orElse: () => tripsState.trips.isNotEmpty ? tripsState.trips.first : null as dynamic,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFA726)),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trip Chat',
              style: TextStyle(
                color: Color(0xFFFFA726),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Real-time indicator
            if (chatState.isRealtime) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Only show refresh button if NOT in real-time mode
          if (!chatState.isRealtime)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFFFA726)),
              onPressed: _refreshComments,
            ),
        ],
      ),
      body: Column(
        children: [
          // Trip context header (pinned)
          if (trip case final tripValue) _TripContextHeader(trip: tripValue),
          
          // Messages list
          Expanded(
            child: chatState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFA726)),
                  )
                : chatState.errorMessage != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load comments',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  chatState.errorMessage ?? 'Unknown error',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _refreshComments,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA726),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : chatState.comments.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Color(0xFF48484A),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    color: Color(0xFF636366),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshComments,
                            color: const Color(0xFFFFA726),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: chatState.comments.length,
                              itemBuilder: (context, index) {
                                final comment = chatState.comments[index];
                                final isCurrentUser = comment.member.id == currentUserId;
                                
                                // Check if this is the last message from same user
                                final isLastInGroup = index == chatState.comments.length - 1 ||
                                    chatState.comments[index + 1].member.id != comment.member.id;
                                
                                return _MessageBubble(
                                  comment: comment,
                                  isCurrentUser: isCurrentUser,
                                  showTimestamp: isLastInGroup,
                                  key: ValueKey(comment.id),
                                );
                              },
                            ),
                          ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF48484A),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF3A3A3C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA726),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: chatState.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: chatState.isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trip Context Header
class _TripContextHeader extends StatelessWidget {
  final dynamic trip;

  const _TripContextHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF48484A),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip?.title ?? 'Trip Chat',
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (trip?.level != null) ...[
                const Icon(
                  Icons.terrain,
                  size: 14,
                  color: Color(0xFF8E8E93),
                ),
                const SizedBox(width: 4),
                Text(
                  trip.level.displayName ?? 'Level ${trip.level.numericLevel}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Icon(
                Icons.people,
                size: 14,
                color: Color(0xFF8E8E93),
              ),
              const SizedBox(width: 4),
              Text(
                '${trip?.registeredCount ?? 0} Members',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                ),
              ),
              if (trip?.lead != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.person,
                  size: 14,
                  color: Color(0xFFFFA726),
                ),
                const SizedBox(width: 4),
                Text(
                  'Led by ${trip.lead.firstName ?? trip.lead.username}',
                  style: const TextStyle(
                    color: Color(0xFFFFA726),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Enhanced Message Bubble with animations
class _MessageBubble extends StatelessWidget {
  final TripComment comment;
  final bool isCurrentUser;
  final bool showTimestamp;

  const _MessageBubble({
    super.key,
    required this.comment,
    required this.isCurrentUser,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final memberRank = comment.member.level ?? 'Member';
    final memberName = comment.authorName;
    
    // Safe timeago formatting with fallback
    String relativeTime;
    try {
      relativeTime = timeago.format(comment.created, locale: 'en_short');
    } catch (e) {
      // Fallback to manual relative time if timeago fails
      final now = DateTime.now();
      final difference = now.difference(comment.created);
      
      if (difference.inMinutes < 1) {
        relativeTime = 'now';
      } else if (difference.inMinutes < 60) {
        relativeTime = '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        relativeTime = '${difference.inHours}h';
      } else {
        relativeTime = '${difference.inDays}d';
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
        child: Row(
          mainAxisAlignment: isCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              // Avatar for others (left side)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8E8E93),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: comment.member.profileImage != null
                      ? NetworkImage(comment.member.profileImage!)
                      : null,
                  radius: 16,
                  child: comment.member.profileImage == null
                      ? Text(
                          comment.authorAvatar,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Message bubble
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFF3A3A3C) // Own messages: subtle gold tint
                      : const Color(0xFF2C2C2E), // Others: neutral dark
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isCurrentUser
                        ? const Color(0xFFFFA726).withValues(alpha: 0.2)
                        : const Color(0xFF48484A).withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with username and rank
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(17),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              memberName,
                              style: const TextStyle(
                                color: Color(0xFFFFA726),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              memberRank,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Message content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Text(
                        comment.comment,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 14,
                          height: 1.45,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    
                    // Timestamp (only for last in group)
                    if (showTimestamp)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Text(
                          relativeTime,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            if (isCurrentUser) ...[
              // Avatar for current user (right side)
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFA726),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1C1C1E),
                  backgroundImage: comment.member.profileImage != null
                      ? NetworkImage(comment.member.profileImage!)
                      : null,
                  radius: 16,
                  child: comment.member.profileImage == null
                      ? Text(
                          comment.authorAvatar,
                          style: const TextStyle(
                            color: Color(0xFFFFA726),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
