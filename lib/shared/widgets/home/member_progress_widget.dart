import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider_v2.dart';
import '../../../core/providers/level_configuration_provider.dart';
import '../../../features/logbook/data/providers/logbook_progress_provider.dart';

/// Member Progress Widget
/// 
/// Shows current user's logbook progress:
/// - Official club level
/// - Current working level with progress
/// - Overall skills verified
class MemberProgressWidget extends ConsumerWidget {
  const MemberProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(currentUserProviderV2);

    if (user == null) return const SizedBox.shrink();

    // Watch logbook progress
    final progressAsync = ref.watch(logbookProgressProvider);
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);

    return Card(
      child: InkWell(
        onTap: () => context.push('/logbook'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: progressAsync.when(
            data: (progress) {
              // Handle null progress
              if (progress == null) {
                return Center(
                  child: Text(
                    'No progress data available',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              
              return levelConfigAsync.when(
              data: (levelConfig) {
                // Get level display info
                final officialLevelEmoji = progress.officialLevel != null
                    ? levelConfig.getLevelEmoji(progress.officialLevel!.id)
                    : '';
                final officialLevelName = progress.officialLevel != null
                    ? levelConfig.getCleanLevelName(progress.officialLevel!.name)
                    : 'Member';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Official Level
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            color: colors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Progress',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Official Club Level',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Official Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: progress.officialLevel != null
                                ? levelConfig.getLevelColor(progress.officialLevel!.id)
                                : colors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$officialLevelName $officialLevelEmoji',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Currently Working On Section
                    if (progress.workingLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 16,
                                  color: levelConfig.getLevelColor(progress.workingLevel!.levelId),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Currently Working On',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${levelConfig.getCleanLevelName(progress.workingLevel!.levelName)} ${levelConfig.getLevelEmoji(progress.workingLevel!.levelId)} Level',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: levelConfig.getLevelColor(progress.workingLevel!.levelId),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Working Level Stats
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.check_circle,
                              label: 'Skills',
                              value: '${progress.workingLevel!.skillsVerified}/${progress.workingLevel!.totalSkills}',
                              color: const Color(0xFF81C784),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.flag,
                              label: 'Remaining',
                              value: '${progress.workingLevel!.skillsRemaining}',
                              color: const Color(0xFF64B5F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress Bar for Current Level
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level Progress',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(progress.workingLevel!.progress * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: levelConfig.getLevelColor(progress.workingLevel!.levelId),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.workingLevel!.progress,
                              minHeight: 8,
                              backgroundColor: colors.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                levelConfig.getLevelColor(progress.workingLevel!.levelId),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Overall Progress Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall: ${progress.totalSkillsVerified}/${progress.totalSkillsAvailable} skills verified',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.overallProgress,
                                    minHeight: 6,
                                    backgroundColor: colors.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Next Level Section
                    if (progress.nextLevel != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.navigate_next,
                              size: 18,
                              color: levelConfig.getLevelColor(progress.nextLevel!.levelId),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '${levelConfig.getCleanLevelName(progress.nextLevel!.levelName)} ${levelConfig.getLevelEmoji(progress.nextLevel!.levelId)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: levelConfig.getLevelColor(progress.nextLevel!.levelId),
                              ),
                            ),
                            Text(
                              ' (${progress.nextLevel!.totalSkills} skills)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => _LoadingState(theme: theme, colors: colors),
              error: (e, s) => _ErrorState(theme: theme, colors: colors),
            );
            },
            loading: () => _LoadingState(theme: theme, colors: colors),
            error: (e, s) => _ErrorState(theme: theme, colors: colors),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _LoadingState({
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _ErrorState({
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: colors.error,
        ),
        const SizedBox(height: 8),
        Text(
          'Unable to load logbook progress',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.error,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.push('/logbook'),
          child: const Text('View Logbook'),
        ),
      ],
    );
  }
}
