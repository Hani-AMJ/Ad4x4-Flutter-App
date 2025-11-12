import 'package:flutter/material.dart';

/// Wizard Progress Dots
/// 
/// Mobile-friendly progress indicator showing wizard steps as dots
class WizardProgressDots extends StatelessWidget {
  final int currentStep; // 0=landing, 1-4=wizard steps, 5=results
  final int totalSteps; // Always 5 (landing + 4 wizard steps)

  const WizardProgressDots({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Don't show dots on landing page (step 0) or results page (step 5)
    if (currentStep == 0 || currentStep == 5) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final stepNumber = index + 1; // Steps 1-4
          final isActive = stepNumber == currentStep;
          final isCompleted = stepNumber < currentStep;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// Wizard Step Indicator
/// 
/// Shows current step number and title (alternative to dots for larger screens)
class WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final String stepTitle;

  const WizardStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Don't show on landing or results
    if (currentStep == 0 || currentStep == 5) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$currentStep',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Step $currentStep of 4',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '• $stepTitle',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
