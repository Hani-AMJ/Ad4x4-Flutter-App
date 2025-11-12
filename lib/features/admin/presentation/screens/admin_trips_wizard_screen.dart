import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_wizard_provider.dart';
import '../widgets/wizard_landing_card.dart';
import '../widgets/wizard_progress_dots.dart';
import '../widgets/wizard_step_trip_type.dart';
import '../widgets/wizard_step_level_filter.dart';
import '../widgets/wizard_step_user_filter.dart';
import '../widgets/wizard_step_location_filter.dart';
import 'admin_trips_wizard_results_screen.dart';

/// Admin Trips Wizard Screen
/// 
/// Mobile-first wizard interface for searching admin trips
/// Steps: Landing → Trip Type → Level → User → Location → Results
class AdminTripsWizardScreen extends ConsumerWidget {
  const AdminTripsWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(adminWizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: wizardState.currentStep == 0 || wizardState.currentStep == 5
          ? AppBar(
              title: const Text('Trips Search'),
              leading: wizardState.currentStep == 5
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        // Go back to landing
                        ref.read(adminWizardProvider.notifier).resetWizard();
                      },
                    )
                  : null,
            )
          : AppBar(
              title: Text(_getStepTitle(wizardState.currentStep)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(adminWizardProvider.notifier).previousStep();
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: WizardProgressDots(currentStep: wizardState.currentStep),
              ),
            ),
      body: _buildCurrentStep(context, ref, wizardState.currentStep),
      bottomNavigationBar: _buildBottomNav(context, ref, wizardState),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Trip Type';
      case 2:
        return 'Difficulty Level';
      case 3:
        return 'Trip Lead';
      case 4:
        return 'Location';
      default:
        return 'Search';
    }
  }

  Widget _buildCurrentStep(BuildContext context, WidgetRef ref, int step) {
    print('🎬 [WizardScreen] Building step: $step');
    switch (step) {
      case 0:
        // Landing page
        print('🎬 [WizardScreen] Showing landing page');
        return WizardLandingCard(
          onStartWizard: () {
            ref.read(adminWizardProvider.notifier).nextStep();
          },
        );
      case 1:
        // Step 1: Trip Type
        print('🎬 [WizardScreen] Showing trip type step');
        return const WizardStepTripType();
      case 2:
        // Step 2: Level Filter
        print('🎬 [WizardScreen] Showing level filter step');
        return const WizardStepLevelFilter();
      case 3:
        // Step 3: User Filter
        print('🎬 [WizardScreen] Showing user filter step');
        return const WizardStepUserFilter();
      case 4:
        // Step 4: Location Filter
        print('🎬 [WizardScreen] Showing location filter step');
        return const WizardStepLocationFilter();
      case 5:
        // Results page
        print('🎬 [WizardScreen] Showing RESULTS SCREEN');
        return const AdminTripsWizardResultsScreen();
      default:
        print('🎬 [WizardScreen] Unknown step, showing nothing');
        return const SizedBox.shrink();
    }
  }

  Widget? _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    wizardState,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Don't show bottom nav on landing or results page
    if (wizardState.currentStep == 0 || wizardState.currentStep == 5) {
      return null;
    }

    final isLastStep = wizardState.currentStep == 4;
    final canProceed = _canProceedFromStep(wizardState.currentStep, wizardState);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Skip button (only on optional steps)
            if (wizardState.currentStep >= 3) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    if (isLastStep) {
                      // Show loading overlay and execute search
                      await _executeSearchWithProgress(context, ref);
                    } else {
                      // Skip to next step
                      ref.read(adminWizardProvider.notifier).nextStep();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Next/Search button
            Expanded(
              flex: wizardState.currentStep >= 3 ? 1 : 2,
              child: FilledButton(
                onPressed: canProceed
                    ? () async {
                        print('🔘 [WizardScreen] Bottom nav button pressed');
                        print('🔘 [WizardScreen] Current step: ${wizardState.currentStep}, isLastStep: $isLastStep');
                        if (isLastStep) {
                          // Show loading overlay and execute search
                          print('🔘 [WizardScreen] Last step - showing progress dialog...');
                          await _executeSearchWithProgress(context, ref);
                        } else {
                          // Next step
                          print('🔘 [WizardScreen] Going to next step...');
                          ref.read(adminWizardProvider.notifier).nextStep();
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? 'Show Results' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLastStep ? Icons.search : Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedFromStep(int step, wizardState) {
    switch (step) {
      case 1:
        // Trip type is required
        return wizardState.tripType != null;
      case 2:
        // Level selection is optional (can select 0 or more)
        return true;
      case 3:
      case 4:
        // User and location filters are optional
        return true;
      default:
        return false;
    }
  }

  Future<void> _executeSearch(WidgetRef ref) async {
    print('🚀 [WizardScreen] _executeSearch called');
    final criteria = ref.read(adminWizardProvider);
    print('🚀 [WizardScreen] Current criteria: $criteria');
    print('🚀 [WizardScreen] Calling adminWizardResultsProvider.executeSearch...');
    await ref.read(adminWizardResultsProvider.notifier).executeSearch(criteria);
    print('🚀 [WizardScreen] executeSearch completed');
  }

  /// Execute search with loading dialog
  Future<void> _executeSearchWithProgress(BuildContext context, WidgetRef ref) async {
    print('🔄 [WizardScreen] Showing loading dialog...');
    
    // CRITICAL: Capture notifier BEFORE any async operations to avoid disposal issues
    final wizardNotifier = ref.read(adminWizardProvider.notifier);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Searching trips...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fetching all matching trips from server',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Execute search and store results in wizard state
      print('🔄 [WizardScreen] Executing search with results storage...');
      await wizardNotifier.executeSearchAndStoreResults();
      print('🔄 [WizardScreen] Search completed successfully');
      print('🔄 [WizardScreen] Results count: ${ref.read(adminWizardProvider).searchResults?.length ?? 0}');
      
      // Close dialog FIRST
      if (context.mounted) {
        Navigator.of(context).pop();
        print('🔄 [WizardScreen] Dialog closed');
      }

      // Small delay to let dialog close
      await Future.delayed(const Duration(milliseconds: 100));

      // THEN navigate to results (using captured notifier)
      print('🔄 [WizardScreen] Navigating to results...');
      wizardNotifier.goToResults();
      print('🔄 [WizardScreen] Navigation complete');
    } catch (e) {
      print('❌ [WizardScreen] Search failed: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
