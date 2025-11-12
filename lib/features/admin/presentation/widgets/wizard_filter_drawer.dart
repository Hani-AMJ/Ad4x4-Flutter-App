import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/admin_trip_search_criteria.dart';
import '../../../../shared/constants/level_constants.dart';
import '../providers/admin_wizard_provider.dart';

/// Wizard Filter Drawer
/// 
/// Bottom sheet for editing search filters from results page
class WizardFilterDrawer extends ConsumerWidget {
  const WizardFilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criteria = ref.watch(adminWizardProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Refine Search',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Filter sections (scrollable)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildTripTypeSection(context, ref, criteria),
                    const SizedBox(height: 24),
                    _buildLevelSection(context, ref, criteria),
                    const SizedBox(height: 24),
                    _buildLeadSection(context, ref, criteria),
                    const SizedBox(height: 24),
                    _buildAreaSection(context, ref, criteria),
                  ],
                ),
              ),

              // Apply button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton(
                    onPressed: () {
                      // Re-execute search with updated filters
                      ref.read(adminWizardResultsProvider.notifier).executeSearch(
                            ref.read(adminWizardProvider),
                          );
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripTypeSection(
    BuildContext context,
    WidgetRef ref,
    AdminTripSearchCriteria criteria,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TripType.values.map((type) {
            final isSelected = criteria.tripType == type;
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(adminWizardProvider.notifier).setTripType(type);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLevelSection(
    BuildContext context,
    WidgetRef ref,
    AdminTripSearchCriteria criteria,
  ) {
    final theme = Theme.of(context);
    final allSelected = criteria.levelIds.length == LevelConstants.allLevels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Difficulty Levels',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                ref.read(adminWizardProvider.notifier).setAllLevels(!allSelected);
              },
              icon: Icon(allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18),
              label: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LevelConstants.allLevels.map((levelData) {
            final isSelected = criteria.levelIds.contains(levelData.id);
            return FilterChip(
              avatar: Icon(levelData.icon, size: 16, color: levelData.color),
              label: Text(levelData.name),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(adminWizardProvider.notifier).toggleLevel(levelData.id);
              },
            );
          }).toList(),
        ),
        if (criteria.levelIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${criteria.levelIds.length} level${criteria.levelIds.length == 1 ? '' : 's'} selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeadSection(
    BuildContext context,
    WidgetRef ref,
    AdminTripSearchCriteria criteria,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Lead',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (criteria.leadUserId != null)
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Filtered by specific lead'),
            subtitle: Text('User ID: ${criteria.leadUserId}'),
            trailing: IconButton(
              onPressed: () {
                ref.read(adminWizardProvider.notifier).setLeadFilter(null);
              },
              icon: const Icon(Icons.clear),
            ),
            tileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(adminWizardProvider.notifier).goToStep(3);
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Select Trip Lead'),
          ),
      ],
    );
  }

  Widget _buildAreaSection(
    BuildContext context,
    WidgetRef ref,
    AdminTripSearchCriteria criteria,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (criteria.meetingPointArea != null)
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(criteria.meetingPointArea!),
            trailing: IconButton(
              onPressed: () {
                ref.read(adminWizardProvider.notifier).setAreaFilter(null);
              },
              icon: const Icon(Icons.clear),
            ),
            tileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(adminWizardProvider.notifier).goToStep(4);
            },
            icon: const Icon(Icons.add_location),
            label: const Text('Select Location'),
          ),
      ],
    );
  }
}
