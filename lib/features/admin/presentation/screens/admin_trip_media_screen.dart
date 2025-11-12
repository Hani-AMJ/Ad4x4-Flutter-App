import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_media_model.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/trip_media_provider.dart';

/// Admin Trip Media Screen
/// 
/// Photo and video moderation interface for admins
/// Accessible by users with edit_trip_media permission
class AdminTripMediaScreen extends ConsumerStatefulWidget {
  const AdminTripMediaScreen({super.key});

  @override
  ConsumerState<AdminTripMediaScreen> createState() =>
      _AdminTripMediaScreenState();
}

class _AdminTripMediaScreenState extends ConsumerState<AdminTripMediaScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedTripId;
  bool _showPendingOnly = true;

  @override
  void initState() {
    super.initState();
    
    // Load pending media on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingMediaProvider.notifier).loadPending();
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
      if (_showPendingOnly) {
        ref.read(pendingMediaProvider.notifier).loadMore();
      } else {
        ref.read(tripMediaProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final pendingState = ref.watch(pendingMediaProvider);
    final mediaState = ref.watch(tripMediaProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canModerate = user?.hasPermission('edit_trip_media') ?? false;
    if (!canModerate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Media')),
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
                'You don\'t have permission to moderate trip media',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final media = _showPendingOnly ? pendingState.pendingMedia : mediaState.media;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip Media'),
            if (pendingState.totalCount > 0)
              Text(
                '${pendingState.totalCount} pending approval',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        actions: [
          // Toggle pending/all filter
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Pending'),
                icon: Icon(Icons.pending_actions, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('All'),
                icon: Icon(Icons.photo_library, size: 16),
              ),
            ],
            selected: {_showPendingOnly},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _showPendingOnly = selection.first;
              });
              if (_showPendingOnly) {
                ref.read(pendingMediaProvider.notifier).refresh();
              } else {
                ref.read(tripMediaProvider.notifier).refresh();
              }
            },
          ),
          const SizedBox(width: 8),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_showPendingOnly) {
                ref.read(pendingMediaProvider.notifier).refresh();
              } else {
                ref.read(tripMediaProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
      body: (_showPendingOnly ? pendingState.isLoading : mediaState.isLoading) && media.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : (_showPendingOnly ? pendingState.error : mediaState.error) != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Media',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_showPendingOnly ? pendingState.error : mediaState.error) ?? 'Unknown error',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () {
                          if (_showPendingOnly) {
                            ref.read(pendingMediaProvider.notifier).refresh();
                          } else {
                            ref.read(tripMediaProvider.notifier).refresh();
                          }
                        },
                      ),
                    ],
                  ),
                )
              : media.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showPendingOnly ? Icons.check_circle : Icons.photo_library,
                            size: 64,
                            color: colors.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showPendingOnly
                                ? 'No Pending Media'
                                : 'No Media Found',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showPendingOnly
                                ? 'All photos have been reviewed'
                                : 'No media has been uploaded yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_showPendingOnly) {
                          await ref.read(pendingMediaProvider.notifier).refresh();
                        } else {
                          await ref.read(tripMediaProvider.notifier).refresh();
                        }
                      },
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: media.length + ((_showPendingOnly ? pendingState.hasMore : mediaState.hasMore) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= media.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _MediaCard(
                            media: media[index],
                            showActions: _showPendingOnly,
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Media Card Widget
class _MediaCard extends ConsumerWidget {
  final TripMedia media;
  final bool showActions;

  const _MediaCard({
    required this.media,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder image (since we don't have actual image URLs yet)
                Container(
                  color: colors.surfaceContainerHighest,
                  child: media.thumbnailUrl != null
                      ? Image.network(
                          media.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: colors.outline,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: colors.outline,
                          ),
                        ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: media.isPending
                          ? colors.tertiaryContainer
                          : media.approved
                              ? colors.primaryContainer
                              : colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      media.isPending
                          ? 'PENDING'
                          : media.approved
                              ? 'APPROVED'
                              : 'REJECTED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: media.isPending
                            ? colors.onTertiaryContainer
                            : media.approved
                                ? colors.onPrimaryContainer
                                : colors.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Media info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uploader
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        media.uploadedBy.displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        media.uploadedBy.displayName,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  dateFormat.format(media.uploadDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                // Caption (if available)
                if (media.caption != null && media.caption!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    media.caption!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // File size
                if (media.fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    media.fileSizeFormatted,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action buttons (for pending media)
          if (showActions && media.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _handleApprove(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleReject(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ),
          // Delete button (for non-pending media)
          if (!showActions && !media.isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  onPressed: () => _handleDelete(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(mediaModerationActionsProvider.notifier).approvePhoto(media.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve photo: $e'),
            backgroundColor: Colors.red,
          ),
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
      await ref.read(mediaModerationActionsProvider.notifier).rejectPhoto(
        media.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(mediaModerationActionsProvider.notifier).deletePhoto(media.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: Colors.red,
          ),
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
      title: const Text('Reject Photo'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          hintText: 'Why is this photo being rejected?',
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
