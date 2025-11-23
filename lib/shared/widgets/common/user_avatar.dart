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

    // Display user avatar image with fallback to initials
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Network error - show initials fallback
              if (kDebugMode) {
                debugPrint('Avatar load error: $error');
              }
              return CircleAvatar(
                radius: radius,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircleAvatar(
                radius: radius,
                backgroundColor: colors.surfaceContainerHighest,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }

    // No image URL - show initials
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      child: Text(
        _getInitials(),
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
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
