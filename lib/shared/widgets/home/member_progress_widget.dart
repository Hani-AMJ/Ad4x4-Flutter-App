import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider_v2.dart';
import '../../../core/providers/level_configuration_provider.dart';
import '../../../features/logbook/data/providers/logbook_progress_provider.dart';

/// Member Progress Widget with Tabbed Interface
/// 
/// Shows current user's logbook progress in swipeable tabs:
/// - Tab 1: Current Level (working level + progress)
/// - Tab 2: Overall (total skills verified)
/// - Tab 3: Next (next level requirements)
class MemberProgressWidget extends ConsumerStatefulWidget {
  const MemberProgressWidget({super.key});

  @override
  ConsumerState<MemberProgressWidget> createState() => _MemberProgressWidgetState();
}

class _MemberProgressWidgetState extends ConsumerState<MemberProgressWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact Header with Official Level
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: progress.officialLevel != null
                                ? levelConfig.getLevelColor(progress.officialLevel!.id)
                                : colors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$officialLevelName $officialLevelEmoji',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: colors.primary,
                      unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
                      indicatorColor: colors.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: theme.textTheme.bodySmall,
                      tabs: const [
                        Tab(text: 'Current'),
                        Tab(text: 'Overall'),
                        Tab(text: 'Next'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tab Content
                    SizedBox(
                      height: 160,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Current Level
                          _CurrentLevelTab(
                            progress: progress,
                            levelConfig: levelConfig,
                            theme: theme,
                            colors: colors,
                          ),

                          // Tab 2: Overall Progress
                          _OverallTab(
                            progress: progress,
                            theme: theme,
                            colors: colors,
                          ),

                          // Tab 3: Next Level
                          _NextLevelTab(
                            progress: progress,
                            levelConfig: levelConfig,
                            theme: theme,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
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

// Tab 1: Current Level Progress
class _CurrentLevelTab extends StatelessWidget {
  final dynamic progress;
  final dynamic levelConfig;
  final ThemeData theme;
  final ColorScheme colors;

  const _CurrentLevelTab({
    required this.progress,
    required this.levelConfig,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.workingLevel == null) {
      return Center(
        child: Text(
          'No working level set',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final workingLevel = progress.workingLevel!;
    final levelColor = levelConfig.getLevelColor(workingLevel.levelId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level Name
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.school,
                size: 18,
                color: levelColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${levelConfig.getCleanLevelName(workingLevel.levelName)} ${levelConfig.getLevelEmoji(workingLevel.levelId)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Stats Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF81C784), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${workingLevel.skillsVerified}/${workingLevel.totalSkills}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skills Verified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Color(0xFF64B5F6), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${workingLevel.skillsRemaining}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Bar
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
                  '${(workingLevel.progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: workingLevel.progress,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(levelColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Tab 2: Overall Progress
class _OverallTab extends StatelessWidget {
  final dynamic progress;
  final ThemeData theme;
  final ColorScheme colors;

  const _OverallTab({
    required this.progress,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon and Title
        Icon(
          Icons.auto_awesome,
          size: 48,
          color: colors.primary,
        ),
        const SizedBox(height: 16),

        // Stats
        Text(
          '${progress.totalSkillsVerified}/${progress.totalSkillsAvailable}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Skills Verified',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Progress Bar
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.overallProgress,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Tab 3: Next Level
class _NextLevelTab extends StatelessWidget {
  final dynamic progress;
  final dynamic levelConfig;
  final ThemeData theme;
  final ColorScheme colors;

  const _NextLevelTab({
    required this.progress,
    required this.levelConfig,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.nextLevel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 48,
              color: colors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Maximum Level Reached!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ve completed all levels',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final nextLevel = progress.nextLevel!;
    final levelColor = levelConfig.getLevelColor(nextLevel.levelId);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Arrow Icon
        Icon(
          Icons.arrow_upward_rounded,
          size: 36,
          color: levelColor,
        ),
        const SizedBox(height: 10),

        // Next Level Name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${levelConfig.getCleanLevelName(nextLevel.levelName)} ${levelConfig.getLevelEmoji(nextLevel.levelId)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: levelColor,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Requirements
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: levelColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 20,
                color: levelColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${nextLevel.totalSkills} skills required',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: levelColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
