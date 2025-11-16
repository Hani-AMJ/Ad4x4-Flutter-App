import 'package:flutter/material.dart';

/// Enhanced error state widget with illustrations and helpful actions
/// Provides better user experience for error scenarios
class EnhancedErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final ErrorStateType type;

  const EnhancedErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = ErrorStateType.general,
  });

  /// Factory constructor for network error
  factory EnhancedErrorState.network({
    Key? key,
    required VoidCallback onRetry,
    VoidCallback? onGoBack,
  }) {
    return EnhancedErrorState(
      key: key,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      type: ErrorStateType.network,
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
      secondaryActionLabel: onGoBack != null ? 'Go Back' : null,
      onSecondaryAction: onGoBack,
    );
  }

  /// Factory constructor for not found error
  factory EnhancedErrorState.notFound({
    Key? key,
    required String itemName,
    VoidCallback? onGoBack,
  }) {
    return EnhancedErrorState(
      key: key,
      title: '$itemName Not Found',
      message: 'The $itemName you\'re looking for doesn\'t exist or has been removed.',
      icon: Icons.search_off,
      type: ErrorStateType.notFound,
      primaryActionLabel: onGoBack != null ? 'Go Back' : null,
      onPrimaryAction: onGoBack,
    );
  }

  /// Factory constructor for unauthorized error
  factory EnhancedErrorState.unauthorized({
    Key? key,
    required VoidCallback onLogin,
  }) {
    return EnhancedErrorState(
      key: key,
      title: 'Access Denied',
      message: 'You don\'t have permission to access this content. Please log in.',
      icon: Icons.lock_outline,
      type: ErrorStateType.unauthorized,
      primaryActionLabel: 'Log In',
      onPrimaryAction: onLogin,
    );
  }

  /// Factory constructor for empty state
  factory EnhancedErrorState.empty({
    Key? key,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EnhancedErrorState(
      key: key,
      title: title,
      message: message,
      icon: Icons.inbox_outlined,
      type: ErrorStateType.empty,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
    );
  }

  /// Factory constructor for server error
  factory EnhancedErrorState.serverError({
    Key? key,
    required VoidCallback onRetry,
  }) {
    return EnhancedErrorState(
      key: key,
      title: 'Something Went Wrong',
      message: 'We\'re having trouble loading this content. Please try again.',
      icon: Icons.error_outline,
      type: ErrorStateType.server,
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final errorColor = _getErrorColor();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? _getDefaultIcon(),
                size: 64,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Actions
            if (primaryActionLabel != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(_getPrimaryActionIcon()),
                  label: Text(primaryActionLabel!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            if (secondaryActionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(secondaryActionLabel!),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: errorColor),
                    foregroundColor: errorColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getErrorColor() {
    switch (type) {
      case ErrorStateType.network:
        return Colors.orange;
      case ErrorStateType.notFound:
        return Colors.grey;
      case ErrorStateType.unauthorized:
        return Colors.red;
      case ErrorStateType.empty:
        return Colors.blue;
      case ErrorStateType.server:
        return Colors.red;
      case ErrorStateType.general:
        return Colors.red;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case ErrorStateType.network:
        return Icons.wifi_off;
      case ErrorStateType.notFound:
        return Icons.search_off;
      case ErrorStateType.unauthorized:
        return Icons.lock_outline;
      case ErrorStateType.empty:
        return Icons.inbox_outlined;
      case ErrorStateType.server:
        return Icons.error_outline;
      case ErrorStateType.general:
        return Icons.error_outline;
    }
  }

  IconData _getPrimaryActionIcon() {
    if (primaryActionLabel?.toLowerCase().contains('retry') ?? false) {
      return Icons.refresh;
    } else if (primaryActionLabel?.toLowerCase().contains('login') ?? false) {
      return Icons.login;
    } else if (primaryActionLabel?.toLowerCase().contains('back') ?? false) {
      return Icons.arrow_back;
    } else {
      return Icons.arrow_forward;
    }
  }
}

/// Error state types for different scenarios
enum ErrorStateType {
  network,
  notFound,
  unauthorized,
  empty,
  server,
  general,
}

/// Helper extension for showing error dialogs
extension ErrorDialogExtension on BuildContext {
  /// Show error dialog with retry option
  Future<void> showErrorDialog({
    required String title,
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (retryLabel != null && onRetry != null)
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
