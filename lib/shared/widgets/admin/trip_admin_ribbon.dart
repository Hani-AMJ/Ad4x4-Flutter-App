import 'package:flutter/material.dart';
import '../../../core/utils/status_helpers.dart';

/// Trip Admin Ribbon
/// 
/// Sticky action bar for marshal/admin trip management actions
/// 
/// Now accepts status as String (backend code: A, P, D) instead of enum
/// for better compatibility with dynamic approval statuses.
class TripAdminRibbon extends StatelessWidget {
  final String tripId;
  final String approvalStatus; // Backend code: "A", "P", "D"
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onEdit;
  final VoidCallback? onManageRegistrants;
  final VoidCallback? onCheckin;
  final VoidCallback? onExport;
  final VoidCallback? onBindGallery;

  const TripAdminRibbon({
    super.key,
    required this.tripId,
    required this.approvalStatus,
    this.onApprove,
    this.onDecline,
    this.onEdit,
    this.onManageRegistrants,
    this.onCheckin,
    this.onExport,
    this.onBindGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colors.onSurface.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getStatusColor(approvalStatus, colors),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(approvalStatus),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(approvalStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ADMIN VIEW',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Approval actions (if pending)
                  if (isPending(approvalStatus)) ...[
                    _ActionButton(
                      icon: Icons.check_circle,
                      label: 'Approve',
                      color: Colors.green,
                      onTap: onApprove,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.cancel,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: onDecline,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Edit trip
                  _ActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: colors.primary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),

                  // Manage registrants
                  _ActionButton(
                    icon: Icons.people,
                    label: 'Registrants',
                    color: Colors.blue,
                    onTap: onManageRegistrants,
                  ),
                  const SizedBox(width: 8),

                  // Check-in
                  _ActionButton(
                    icon: Icons.how_to_reg,
                    label: 'Check-in',
                    color: Colors.orange,
                    onTap: onCheckin,
                  ),
                  const SizedBox(width: 8),

                  // Export
                  _ActionButton(
                    icon: Icons.download,
                    label: 'Export',
                    color: Colors.purple,
                    onTap: onExport,
                  ),
                  const SizedBox(width: 8),

                  // Bind gallery
                  _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.teal,
                    onTap: onBindGallery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colors) {
    if (isApproved(status)) return Colors.green;
    if (isPending(status)) return Colors.orange;
    if (isDeclined(status)) return Colors.red;
    return Colors.grey; // Unknown status
  }

  IconData _getStatusIcon(String status) {
    if (isApproved(status)) return Icons.check_circle;
    if (isPending(status)) return Icons.pending;
    if (isDeclined(status)) return Icons.cancel;
    return Icons.help; // Unknown status
  }

  String _getStatusText(String status) {
    return getApprovalStatusText(status).toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label action coming soon')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⚠️ DEPRECATED: TripApprovalStatus enum
/// 
/// This enum is kept for backward compatibility but is no longer used.
/// The TripAdminRibbon now accepts String status codes (A, P, D) directly.
/// 
/// For new code, use:
/// - String status codes: "A", "P", "D"
/// - Status helpers: isApproved(), isPending(), isDeclined()
/// - Dynamic choices: ApprovalStatusChoice model + provider
@Deprecated('Use String status codes with status_helpers.dart instead')
enum TripApprovalStatus {
  pending,
  approved,
  declined,
}
