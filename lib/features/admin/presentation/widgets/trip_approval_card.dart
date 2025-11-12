import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import 'confirmation_dialog.dart';

/// Trip Approval Card Widget
/// 
/// Displays pending trip information with approve/decline actions.
/// Features:
/// - Trip details (title, organizer, date, level, capacity)
/// - Trip image if available
/// - Approve button (green) - shows confirmation dialog
/// - Decline button (red) - shows confirmation dialog with optional reason
/// - Loading state during API calls
/// - Error handling with snackbar feedback
class TripApprovalCard extends ConsumerStatefulWidget {
  final TripListItem trip;
  final VoidCallback onApproved;
  final VoidCallback onDeclined;

  const TripApprovalCard({
    super.key,
    required this.trip,
    required this.onApproved,
    required this.onDeclined,
  });

  @override
  ConsumerState<TripApprovalCard> createState() => _TripApprovalCardState();
}

class _TripApprovalCardState extends ConsumerState<TripApprovalCard> {
  bool _isLoading = false;

  /// Show approve confirmation dialog
  Future<void> _showApproveDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Approve Trip',
        message:
            'Are you sure you want to approve "${widget.trip.title}"?\n\nThis will make the trip visible to all members.',
        confirmText: 'Approve',
        confirmColor: Colors.green,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      ),
    );

    if (confirmed == true && mounted) {
      await _handleApprove();
    }
  }

  /// Show decline confirmation dialog with optional reason
  Future<void> _showDeclineDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DeclineReasonDialog(
        tripTitle: widget.trip.title,
      ),
    );

    if (result?['confirmed'] == true && mounted) {
      final reason = result?['reason'] as String?;
      await _handleDecline(reason: reason);
    }
  }

  /// Handle approve action
  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.approveTrip(widget.trip.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trip "${widget.trip.title}" approved'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Callback to refresh parent list
        widget.onApproved();
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a permission error
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403') ||
            errorMessage.contains('not allowed');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to approve trips'
                  : '❌ Failed to approve trip: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle decline action
  Future<void> _handleDecline({String? reason}) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.declineTrip(widget.trip.id, reason: reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trip "${widget.trip.title}" declined'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // Callback to refresh parent list
        widget.onDeclined();
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a permission error
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403') ||
            errorMessage.contains('not allowed');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to decline trips'
                  : '❌ Failed to decline trip: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip image (if available)
          if (widget.trip.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.trip.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.terrain, size: 48),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip title
                Text(
                  widget.trip.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Organizer
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Organized by ${widget.trip.lead.displayName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(widget.trip.startTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trip info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Level chip
                    _InfoChip(
                      icon: Icons.trending_up,
                      label: widget.trip.level.name,
                      color: _getLevelColor(widget.trip.level.numericLevel),
                    ),
                    // Capacity chip
                    _InfoChip(
                      icon: Icons.people,
                      label: '${widget.trip.registeredCount}/${widget.trip.capacity}',
                      color: theme.colorScheme.primary,
                    ),
                    // Meeting point chip
                    if (widget.trip.meetingPoint != null)
                      _InfoChip(
                        icon: Icons.location_on,
                        label: widget.trip.meetingPoint!.name,
                        color: theme.colorScheme.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description preview
                if (widget.trip.description.isNotEmpty)
                  Text(
                    widget.trip.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),

                // Action buttons
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDeclineDialog,
                          icon: const Icon(Icons.close),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Approve button
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _showApproveDialog,
                          icon: const Icon(Icons.check),
                          label: const Text('Approve Trip'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on level numeric value
  Color _getLevelColor(int numericLevel) {
    if (numericLevel <= 2) return Colors.green;
    if (numericLevel <= 4) return Colors.blue;
    if (numericLevel <= 6) return Colors.orange;
    return Colors.red;
  }
}

/// Info chip widget for displaying trip metadata
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decline Reason Dialog
/// 
/// Shows a dialog with an optional text field for decline reason.
class DeclineReasonDialog extends StatefulWidget {
  final String tripTitle;

  const DeclineReasonDialog({
    super.key,
    required this.tripTitle,
  });

  @override
  State<DeclineReasonDialog> createState() => _DeclineReasonDialogState();
}

class _DeclineReasonDialogState extends State<DeclineReasonDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.cancel, color: Colors.red, size: 48),
      title: const Text('Decline Trip'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to decline "${widget.tripTitle}"?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Enter reason for declining...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 8),
          Text(
            'The organizer will be notified of this decision.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'confirmed': false}),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'confirmed': true,
              'reason': _reasonController.text.trim().isEmpty
                  ? null
                  : _reasonController.text.trim(),
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Decline Trip'),
        ),
      ],
    );
  }
}
