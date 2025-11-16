import 'package:flutter/material.dart';
import '../../../data/models/vehicle_modifications_model.dart';

/// Verification Status Badge
/// 
/// Displays the current verification status of vehicle modifications.
/// Used throughout the app to show pending/approved/rejected status.

class VerificationStatusBadge extends StatelessWidget {
  final VerificationStatus status;
  final bool compact;

  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case VerificationStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.pending_outlined;
        text = compact ? 'Pending' : 'Pending Verification';
        break;
      case VerificationStatus.approved:
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        icon = Icons.verified_outlined;
        text = compact ? 'Verified' : 'Verified ✓';
        break;
      case VerificationStatus.rejected:
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        text = compact ? 'Rejected' : 'Rejected';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: textColor),
          SizedBox(width: compact ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Verification Type Badge
/// 
/// Shows the verification method (On-Trip or Expedited)
class VerificationTypeBadge extends StatelessWidget {
  final VerificationType type;

  const VerificationTypeBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case VerificationType.onTrip:
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.directions_car;
        break;
      case VerificationType.expedited:
        backgroundColor = Colors.purple.withValues(alpha: 0.15);
        textColor = Colors.purple.shade700;
        icon = Icons.bolt;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
