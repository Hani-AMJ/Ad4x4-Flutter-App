import 'package:flutter/material.dart';

/// Refreshable list wrapper with pull-to-refresh functionality
/// Provides consistent refresh experience across all list screens
class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? indicatorColor;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.child,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: indicatorColor ?? colors.primary,
      backgroundColor: colors.surface,
      displacement: 60.0,
      strokeWidth: 3.0,
      child: child,
    );
  }
}

/// Helper widget to ensure RefreshIndicator works with non-scrollable content
class RefreshableContainer extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshableContainer({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshableList(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: child,
        ),
      ),
    );
  }
}
