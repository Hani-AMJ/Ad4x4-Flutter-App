import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/utils/status_helpers.dart';

/// Trip Status Badge
/// 
/// A compact, glassmorphism-styled badge that displays trip approval status
/// as an overlay on the trip hero image.
/// 
/// Designed to replace the full-width TripAdminRibbon status banner,
/// providing a cleaner, more space-efficient UI.
class TripStatusBadge extends StatelessWidget {
  final String approvalStatus; // Backend code: "A", "P", "D"
  final BadgePosition position;

  const TripStatusBadge({
    super.key,
    required this.approvalStatus,
    this.position = BadgePosition.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      right: position == BadgePosition.bottomRight ? 12 : null,
      left: position == BadgePosition.bottomLeft ? 12 : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(approvalStatus).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(approvalStatus),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(approvalStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (isApproved(status)) return Colors.green;
    if (isPending(status)) return Colors.orange;
    if (isDeclined(status)) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (isApproved(status)) return Icons.check_circle;
    if (isPending(status)) return Icons.pending;
    if (isDeclined(status)) return Icons.cancel;
    return Icons.help;
  }

  String _getStatusText(String status) {
    return getApprovalStatusText(status).toUpperCase();
  }
}

/// Badge position options
enum BadgePosition {
  bottomLeft,
  bottomRight,
}
