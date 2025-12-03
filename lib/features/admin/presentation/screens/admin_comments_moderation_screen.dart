import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/comment_moderation_model.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/comment_moderation_provider.dart';

/// Admin Comments Moderation Screen
/// 
/// Moderate trip comments with approve/reject/edit/ban functionality
/// Accessible by users with delete_trip_comments permission
class AdminCommentsModerationScreen extends ConsumerStatefulWidget {
  const AdminCommentsModerationScreen({super.key});

  @override
  ConsumerState<AdminCommentsModerationScreen> createState() =>
      _AdminCommentsModerationScreenState();
}

class _AdminCommentsModerationScreenState
    extends ConsumerState<AdminCommentsModerationScreen> {
  final ScrollController _scrollController = ScrollController();
  ModerationStatus? _statusFilter;
  bool _flaggedOnly = false;

  @override
  void initState() {
    super.initState();
    
    // Load pending comments on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingCommentsProvider.notifier).loadPending();
      ref.read(flaggedCommentsProvider.notifier).loadFlagged();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(allCommentsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final pendingState = ref.watch(pendingCommentsProvider);
    final flaggedState = ref.watch(flaggedCommentsProvider);
    final allState = ref.watch(allCommentsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canModerate = user?.hasPermission('delete_trip_comments') ?? false;
    if (!canModerate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comments Moderation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to moderate comments',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comments Moderation'),
            if (pendingState.totalCount > 0 || flaggedState.totalCount > 0)
              Text(
                '${pendingState.totalCount} pending • ${flaggedState.totalCount} flagged',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        actions: [
          // Filter dropdown
          PopupMenuButton<ModerationStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Status',
            onSelected: (status) {
              setState(() => _statusFilter = status);
              ref.read(allCommentsProvider.notifier).loadComments(
                status: status,
                flaggedOnly: _flaggedOnly,
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Comments'),
              ),
              const PopupMenuItem(
                value: ModerationStatus.pending,
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: ModerationStatus.approved,
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: ModerationStatus.rejected,
                child: Text('Rejected'),
              ),
            ],
          ),
          // Flagged filter toggle
          IconButton(
            icon: Icon(
              _flaggedOnly ? Icons.flag : Icons.outlined_flag,
              color: _flaggedOnly ? colors.error : null,
            ),
            tooltip: 'Show Flagged Only',
            onPressed: () {
              setState(() => _flaggedOnly = !_flaggedOnly);
              ref.read(allCommentsProvider.notifier).loadComments(
                status: _statusFilter,
                flaggedOnly: _flaggedOnly,
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(pendingCommentsProvider.notifier).refresh();
              ref.read(flaggedCommentsProvider.notifier).refresh();
              ref.read(allCommentsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(pendingCommentsProvider.notifier).refresh();
          await ref.read(flaggedCommentsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Pending Comments Section
            if (pendingState.pendingComments.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Approval (${pendingState.totalCount})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CommentCard(
                    comment: pendingState.pendingComments[index],
                    showFullActions: true,
                  ),
                  childCount: pendingState.pendingComments.length,
                ),
              ),
            ],
            // Flagged Comments Section
            if (flaggedState.flaggedComments.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 20, color: colors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Flagged Comments (${flaggedState.totalCount})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CommentCard(
                    comment: flaggedState.flaggedComments[index],
                    showFullActions: true,
                  ),
                  childCount: flaggedState.flaggedComments.length,
                ),
              ),
            ],
            // All Comments Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'All Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            allState.isLoading && allState.comments.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : allState.error != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: colors.error),
                              const SizedBox(height: 16),
                              Text('Error Loading Comments', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(allState.error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(allCommentsProvider.notifier).refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : allState.comments.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                              child: Text('No comments found'),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= allState.comments.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _CommentCard(
                                  comment: allState.comments[index],
                                  showFullActions: false,
                                );
                              },
                              childCount: allState.comments.length + (allState.hasMore ? 1 : 0),
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}

/// Comment Card Widget
class _CommentCard extends ConsumerWidget {
  final TripCommentWithModeration comment;
  final bool showFullActions;

  const _CommentCard({
    required this.comment,
    required this.showFullActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author info + status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    comment.authorAvatar,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        dateFormat.format(comment.created),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: comment.isPending
                        ? colors.tertiaryContainer
                        : comment.approved
                            ? colors.primaryContainer
                            : colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment.status.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: comment.isPending
                          ? colors.onTertiaryContainer
                          : comment.approved
                              ? colors.onPrimaryContainer
                              : colors.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Comment text
            Text(
              comment.comment,
              style: theme.textTheme.bodyMedium,
            ),
            // Flagged indicator
            if (comment.flagged) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Flagged by ${comment.flagCount} user(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Moderation info
            if (comment.moderatedBy != null) ...[
              const SizedBox(height: 8),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 16, color: colors.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Moderated by ${comment.moderatedBy!.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              if (comment.moderationReason != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Reason: ${comment.moderationReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
            // Action buttons
            if (showFullActions && comment.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      onPressed: () => _handleApprove(context, ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      onPressed: () => _handleReject(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => _handleEdit(context, ref),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Ban User'),
                      onPressed: () => _handleBanUser(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(commentModerationActionsProvider.notifier).approveComment(comment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment approved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );
    if (reason == null) return;

    try {
      await ref.read(commentModerationActionsProvider.notifier).rejectComment(
        comment.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => _EditCommentDialog(currentText: comment.comment),
    );
    if (newText == null || newText == comment.comment) return;

    try {
      await ref.read(commentModerationActionsProvider.notifier).editComment(
        comment.id,
        newText,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleBanUser(BuildContext context, WidgetRef ref) async {
    final banRequest = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BanUserDialog(userName: comment.authorName),
    );
    if (banRequest == null) return;

    try {
      await ref.read(commentModerationActionsProvider.notifier).banUser(
        userId: comment.member.id,
        duration: banRequest['duration'] as BanDuration,
        reason: banRequest['reason'] as String,
        notifyUser: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${comment.authorName} has been banned from commenting'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Reject Reason Dialog
class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Comment'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        maxLength: 200,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

/// Edit Comment Dialog
class _EditCommentDialog extends StatefulWidget {
  final String currentText;

  const _EditCommentDialog({required this.currentText});

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Comment'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Comment',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        maxLength: 1000,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Ban User Dialog
class _BanUserDialog extends StatefulWidget {
  final String userName;

  const _BanUserDialog({required this.userName});

  @override
  State<_BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<_BanUserDialog> {
  BanDuration _duration = BanDuration.oneDay;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ban ${widget.userName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Duration:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<BanDuration>(
            initialValue: _duration,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: BanDuration.values
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.displayName),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _duration = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reason is required')),
              );
              return;
            }
            Navigator.pop(context, {
              'duration': _duration,
              'reason': _reasonController.text.trim(),
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Ban User'),
        ),
      ],
    );
  }
}
