import 'package:flutter/material.dart';

/// Enhanced error state widget with retry mechanism
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final bool showRetryButton;
  final Widget? customAction;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText,
    this.showRetryButton = true,
    this.customAction,
  });

  /// Network error state
  factory ErrorStateWidget.network({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      message: message ?? 'Please check your internet connection and try again',
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }

  /// Server error state
  factory ErrorStateWidget.server({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.cloud_off,
      title: 'Server Error',
      message: message ?? 'Something went wrong on our end. Please try again',
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }

  /// Not found error state
  factory ErrorStateWidget.notFound({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.search_off,
      title: 'Not Found',
      message: message ?? 'The content you\'re looking for doesn\'t exist',
      onRetry: onRetry,
      retryButtonText: 'Go Back',
      showRetryButton: onRetry != null,
    );
  }

  /// Timeout error state
  factory ErrorStateWidget.timeout({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.timer_off,
      title: 'Request Timeout',
      message: message ?? 'The request took too long. Please try again',
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }

  /// Permission denied error state
  factory ErrorStateWidget.permissionDenied({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.lock,
      title: 'Permission Denied',
      message: message ?? 'You don\'t have permission to access this content',
      onRetry: onRetry,
      retryButtonText: 'Request Access',
      showRetryButton: onRetry != null,
    );
  }

  /// Generic error state
  factory ErrorStateWidget.generic({
    VoidCallback? onRetry,
    String? title,
    String? message,
  }) {
    return ErrorStateWidget(
      icon: Icons.error_outline,
      title: title ?? 'Something Went Wrong',
      message: message ?? 'An unexpected error occurred. Please try again',
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              icon ?? Icons.error_outline,
              size: 80,
              color: colors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),

            // Error title
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            
            if (title != null) const SizedBox(height: 12),

            // Error message
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Custom action or retry button
            if (customAction != null)
              customAction!
            else if (showRetryButton && onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with optional message
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionButtonText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty icon
            Icon(
              icon ?? Icons.inbox,
              size: 80,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),

            // Empty title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),

            // Empty message
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

            if (onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(actionButtonText ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
