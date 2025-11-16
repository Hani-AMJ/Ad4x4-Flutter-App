import 'package:flutter/material.dart';

/// Notification service for showing toast messages and snackbars
/// Provides a consistent notification experience across the app
class NotificationService {
  /// Show success notification
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show error notification
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show warning notification
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: Colors.orange,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show info notification
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.blue,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show loading notification
  static void showLoading(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(hours: 1), // Long duration for loading
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dismiss current notification
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Private method to show customized snackbar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Extension method for easier access to notification service
extension NotificationExtension on BuildContext {
  /// Show success notification
  void showSuccessNotification(
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    NotificationService.showSuccess(
      this,
      message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show error notification
  void showErrorNotification(
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    NotificationService.showError(
      this,
      message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show warning notification
  void showWarningNotification(
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    NotificationService.showWarning(
      this,
      message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show info notification
  void showInfoNotification(
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    NotificationService.showInfo(
      this,
      message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show loading notification
  void showLoadingNotification(String message) {
    NotificationService.showLoading(this, message);
  }

  /// Dismiss current notification
  void dismissNotification() {
    NotificationService.dismiss(this);
  }
}
