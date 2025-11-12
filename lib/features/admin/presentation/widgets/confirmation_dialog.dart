import 'package:flutter/material.dart';

/// Confirmation Dialog Widget
/// 
/// A reusable confirmation dialog for critical actions.
/// Features:
/// - Customizable title, message, and button text
/// - Icon support with color customization
/// - Cancel and Confirm buttons
/// - Material Design 3 styling
/// 
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (context) => ConfirmationDialog(
///     title: 'Delete Item',
///     message: 'Are you sure you want to delete this item?',
///     confirmText: 'Delete',
///     confirmColor: Colors.red,
///     icon: Icons.delete,
///     iconColor: Colors.red,
///   ),
/// );
/// 
/// if (confirmed == true) {
///   // Perform action
/// }
/// ```
class ConfirmationDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog message/description
  final String message;

  /// Confirm button text (default: 'Confirm')
  final String confirmText;

  /// Cancel button text (default: 'Cancel')
  final String cancelText;

  /// Confirm button color (default: primary color)
  final Color? confirmColor;

  /// Cancel button color (default: text button default)
  final Color? cancelColor;

  /// Optional icon to display above title
  final IconData? icon;

  /// Icon color (default: primary color)
  final Color? iconColor;

  /// Icon size (default: 48)
  final double iconSize;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.cancelColor,
    this.icon,
    this.iconColor,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: iconSize,
            )
          : null,
      title: Text(title),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: cancelColor != null
              ? TextButton.styleFrom(foregroundColor: cancelColor)
              : null,
          child: Text(cancelText),
        ),

        // Confirm button
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Destructive Confirmation Dialog
/// 
/// Pre-configured confirmation dialog for destructive actions (delete, remove, etc.).
/// Uses red color scheme by default.
class DestructiveConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;

  const DestructiveConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Delete',
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      confirmColor: Colors.red,
      icon: Icons.warning,
      iconColor: Colors.red,
    );
  }
}

/// Success Confirmation Dialog
/// 
/// Pre-configured confirmation dialog for success/approval actions.
/// Uses green color scheme by default.
class SuccessConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;

  const SuccessConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Approve',
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      confirmColor: Colors.green,
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );
  }
}

/// Information Dialog
/// 
/// A simple information dialog with OK button (no cancel).
/// Used for displaying information that doesn't require confirmation.
class InformationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData? icon;
  final Color? iconColor;

  const InformationDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: 48,
            )
          : null,
      title: Text(title),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
