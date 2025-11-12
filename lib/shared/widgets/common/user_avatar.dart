import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// User avatar with fallback to initials
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.onTap,
  });

  String _getInitials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty 
          ? NetworkImage(imageUrl!) 
          : null,
      onBackgroundImageError: imageUrl != null 
          ? (exception, stackTrace) {
              // Image failed to load - fallback to initials (handled by child)
              if (kDebugMode) {
                debugPrint('Failed to load avatar image: $exception');
              }
            }
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              _getInitials(),
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }

    return avatar;
  }
}
