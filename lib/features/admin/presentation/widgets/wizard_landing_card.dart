import 'package:flutter/material.dart';

/// Wizard Landing Card
/// 
/// Welcome page for admin trips wizard with instructions and start button
class WizardLandingCard extends StatelessWidget {
  final VoidCallback onStartWizard;

  const WizardLandingCard({
    super.key,
    required this.onStartWizard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 16),
        child: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header icon
                  Icon(
                    Icons.explore,
                    size: isTablet ? 80 : 64,
                    color: colors.primary,
                  ),
                  SizedBox(height: isTablet ? 24 : 16),

                  // Title
                  Text(
                    'Admin Trips Search',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Find trips faster with guided search',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 32 : 24),

                  // Wizard steps preview
                  _buildStepPreview(
                    context,
                    icon: Icons.trip_origin,
                    title: '1. Trip Type',
                    description: 'Select upcoming, pending, completed, or all trips',
                  ),
                  const SizedBox(height: 16),

                  _buildStepPreview(
                    context,
                    icon: Icons.terrain,
                    title: '2. Difficulty Level',
                    description: 'Filter by one or multiple difficulty levels',
                  ),
                  const SizedBox(height: 16),

                  _buildStepPreview(
                    context,
                    icon: Icons.person,
                    title: '3. Trip Lead',
                    description: 'Filter by specific trip organizer (optional)',
                  ),
                  const SizedBox(height: 16),

                  _buildStepPreview(
                    context,
                    icon: Icons.location_on,
                    title: '4. Location',
                    description: 'Filter by city or meeting point area (optional)',
                  ),
                  const SizedBox(height: 16),

                  _buildStepPreview(
                    context,
                    icon: Icons.list,
                    title: '5. Results',
                    description: 'View and refine your search results',
                  ),
                  SizedBox(height: isTablet ? 32 : 24),

                  // Start button
                  FilledButton.icon(
                    onPressed: onStartWizard,
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Start Search Wizard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),

                  // Benefits
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Faster search with targeted filters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No more scrolling through thousands of trips',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Modify filters anytime from results page',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepPreview(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colors.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
