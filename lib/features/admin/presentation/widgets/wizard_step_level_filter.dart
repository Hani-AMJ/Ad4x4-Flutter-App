import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/level_constants.dart';
import '../providers/admin_wizard_provider.dart';

/// Wizard Step 2: Level Filter (Multi-Select)
/// 
/// Mobile-optimized level selection with exact icons and colors
class WizardStepLevelFilter extends ConsumerWidget {
  const WizardStepLevelFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(adminWizardProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    final selectedCount = wizardState.levelIds.length;
    final allSelected = selectedCount == LevelConstants.allLevels.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction text
          Text(
            'Select difficulty levels',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select one or multiple levels',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // All Levels toggle button
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(adminWizardProvider.notifier).setAllLevels(!allSelected);
            },
            icon: Icon(allSelected ? Icons.check_box : Icons.check_box_outline_blank),
            label: Text(allSelected ? 'Deselect All' : 'Select All Levels'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
          const SizedBox(height: 16),

          // Selected count
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '$selectedCount level${selectedCount == 1 ? '' : 's'} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Level badges grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: LevelConstants.allLevels.length,
            itemBuilder: (context, index) {
              final levelData = LevelConstants.allLevels[index];
              final isSelected = wizardState.levelIds.contains(levelData.id);

              return LevelFilterBadge(
                levelData: levelData,
                isSelected: isSelected,
                onTap: () {
                  ref.read(adminWizardProvider.notifier).toggleLevel(levelData.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Level Filter Badge Widget
/// 
/// Reusable level badge with exact icons and colors
class LevelFilterBadge extends StatelessWidget {
  final LevelData levelData;
  final bool isSelected;
  final VoidCallback onTap;

  const LevelFilterBadge({
    super.key,
    required this.levelData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? levelData.color.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: levelData.color,
              width: isSelected ? 3 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Level icon
              Icon(
                levelData.icon,
                size: 36,
                color: levelData.color,
              ),
              const SizedBox(height: 8),

              // Level name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  levelData.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: levelData.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Selection checkmark
              if (isSelected) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.check_circle,
                  color: levelData.color,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
