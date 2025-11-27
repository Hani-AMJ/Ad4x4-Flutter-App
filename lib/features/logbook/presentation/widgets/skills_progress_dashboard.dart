import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/logbook_progress_provider.dart';
import '../../data/models/logbook_progress_stats.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/level_configuration_provider.dart';

/// Comprehensive Skills Progress Dashboard
/// Shows overall progress, level breakdown, recent activity, and milestones
class SkillsProgressDashboard extends ConsumerWidget {
  const SkillsProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(logbookProgressProvider);
    
    return progressAsync.when(
      data: (stats) {
        if (stats == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Please log in to view your progress'),
            ),
          );
        }
        
        return _buildDashboard(context, ref, stats);
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading progress: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(logbookProgressProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, LogbookProgressStats stats) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Your Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Overall Progress Card
        _buildOverallProgressCard(context, ref, stats),
        const SizedBox(height: 16),
        
        // Level Breakdown Grid
        _buildLevelBreakdownGrid(context, ref, stats),
        const SizedBox(height: 16),
        
        // Recent Activity - Removed (already in Quick Actions)
        // if (stats.recentEntries.isNotEmpty) ...[
          // _buildRecentActivitySection(context, stats),
          // const SizedBox(height: 16),
        // ],
        
        // Milestones & Achievements
        _buildMilestonesSection(context, ref, stats),
      ],
    );
  }

  Widget _buildOverallProgressCard(BuildContext context, WidgetRef ref, LogbookProgressStats stats) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percentage = stats.currentLevelProgressPercentage;
    
    // ✅ Use FutureProvider for emoji (needs cache)
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
    
    return levelConfigAsync.when(
      data: (levelConfig) => Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentLevelName} Level Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.verifiedSkillsForCurrentLevel} of ${stats.totalSkillsForCurrentLevel} skills verified',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(height: 16),
            
            // Current Level & Trips Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Your Level',
                    levelConfig.getCleanLevelName(stats.currentLevelName),
                    levelConfig.getLevelEmoji(stats.currentLevelId),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colors.outlineVariant,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Trips Attended',
                    '${stats.checkedInTrips}',
                    '🗓️',
                  ),
                ),
              ],
            ),
            
            // Legacy member note if no skills verified
            if (!stats.hasVerifiedSkills) ...[
              const SizedBox(height: 16),
              Divider(color: colors.outlineVariant),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,  // Better dark theme color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your ${stats.currentLevelName} level is club-verified. Start attending trips to build your digital logbook!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    loading: () => Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (e, s) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading level config'),
      ),
    ),
  );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, String emoji) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
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
        ),
      ],
    );
  }

  // Removed: Next level requirements - profile level is source of truth

  Widget _buildLevelBreakdownGrid(BuildContext context, WidgetRef ref, LogbookProgressStats stats) {
    final theme = Theme.of(context);
    
    // Get sorted level IDs
    final levelIds = stats.allLevelsBreakdown.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Skills by Level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/logbook/skills-matrix'),
              child: const Text('View Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: levelIds.length,
          itemBuilder: (context, index) {
            final levelId = levelIds[index];
            final levelData = stats.getLevelProgress(levelId);
            if (levelData == null) return const SizedBox.shrink();
            
            // Check if this is the current user level
            final isCurrentLevel = levelId == stats.currentLevelId;
            
            // Determine level position relative to current
            final currentLevelIndex = levelIds.indexOf(stats.currentLevelId);
            final isBeforeCurrent = currentLevelIndex != -1 && index < currentLevelIndex;
            final isAfterCurrent = currentLevelIndex != -1 && index > currentLevelIndex;
            
            return _buildLevelCard(
              context, 
              ref, 
              levelData, 
              stats, 
              isCurrentLevel: isCurrentLevel,
              isBeforeCurrent: isBeforeCurrent,
              isAfterCurrent: isAfterCurrent,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context, 
    WidgetRef ref, 
    LevelProgressData levelData, 
    LogbookProgressStats stats, 
    {
      bool isCurrentLevel = false,
      bool isBeforeCurrent = false,
      bool isAfterCurrent = false,
    }
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompleted = levelData.isCompleted;
    
    // ✅ Use FutureProvider to ensure cache is ready
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
    
    return levelConfigAsync.when(
      data: (levelConfig) {
        // Get dynamic level configuration (cache is ready!)
        final cleanName = levelConfig.getCleanLevelName(levelData.levelName);
        final levelColor = levelConfig.getLevelColor(levelData.levelId);
        final levelEmoji = levelConfig.getLevelEmoji(levelData.levelId);
        final statusLabel = levelConfig.getLevelStatusLabel(levelData.levelId, stats.currentLevelId);
        
        return _buildLevelCardContent(
          context,
          theme,
          colors,
          levelData,
          stats,
          cleanName,
          levelColor,
          levelEmoji,
          statusLabel,
          isCurrentLevel: isCurrentLevel,
          isBeforeCurrent: isBeforeCurrent,
          isAfterCurrent: isAfterCurrent,
          isCompleted: isCompleted,
        );
      },
      loading: () => Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, s) => Card(
        child: Center(
          child: Icon(Icons.error, color: colors.error),
        ),
      ),
    );
  }

  Widget _buildLevelCardContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    LevelProgressData levelData,
    LogbookProgressStats stats,
    String cleanName,
    Color levelColor,
    String levelEmoji,
    String statusLabel,
    {
      required bool isCurrentLevel,
      required bool isBeforeCurrent,
      required bool isAfterCurrent,
      required bool isCompleted,
    }
  ) {
    
    return Card(
      elevation: isCurrentLevel ? 4 : (isBeforeCurrent ? 3 : 1),
      color: isCurrentLevel
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : (isBeforeCurrent 
              ? colors.primaryContainer.withValues(alpha: 0.5)
              : colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentLevel
            ? BorderSide(color: levelColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.push('/logbook/skills-matrix'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: Stars only
              Text(
                levelEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              // Middle: Skills count + Progress bar
              Row(
                children: [
                  Text(
                    '${levelData.verifiedSkills}/${levelData.totalSkills}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'skills',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: levelData.progressPercentage / 100,
                        minHeight: 5,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isBeforeCurrent ? Colors.green : levelColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bottom: Status badge on the left
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCurrentLevel
                      ? levelColor
                      : isBeforeCurrent
                          ? Colors.green.withValues(alpha: 0.2)
                          : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrentLevel
                        ? levelColor
                        : isBeforeCurrent
                            ? Colors.green.withValues(alpha: 0.5)
                            : colors.surfaceContainerHighest,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isCurrentLevel 
                      ? 'Current level' 
                      : isBeforeCurrent 
                          ? 'Completed level' 
                          : 'next level',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCurrentLevel
                        ? Colors.white
                        : isBeforeCurrent
                            ? Colors.green.shade800
                            : colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, LogbookProgressStats stats) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/logbook/entries'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.recentEntries.length.clamp(0, 5),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = stats.recentEntries[index];
              return _buildActivityItem(context, entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, dynamic entry) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Format date
    final dateStr = entry.createdAt != null 
        ? DateFormat('MMM dd, yyyy').format(entry.createdAt)
        : 'Unknown date';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(
          Icons.check_circle,
          color: colors.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        '${entry.skillsVerified?.length ?? 0} skills verified',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.trip != null)
            Text('Trip: ${entry.trip.title}'),
          Text('Signed by: ${entry.signedBy.displayName}'),
          Text(dateStr, style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to entry detail if implemented
      },
    );
  }

  Widget _buildMilestonesSection(BuildContext context, WidgetRef ref, LogbookProgressStats stats) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // ✅ Use FutureProvider for emoji (needs cache)
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
    
    return levelConfigAsync.when(
      data: (levelConfig) => Card(
      color: colors.surfaceContainerHigh,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: colors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Milestones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current level badge
            _buildMilestoneBadge(
              context,
              levelConfig.getLevelEmoji(stats.currentLevelId),
              '${levelConfig.getCleanLevelName(stats.currentLevelName)} Level',
            ),
            
            const SizedBox(height: 12),
            
            const SizedBox(height: 12),
            
            // Stats for current level
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    context,
                    '✅',
                    stats.verifiedSkillsForCurrentLevel.toString(),
                    'Skills Verified',
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    context,
                    '📊',
                    '${stats.currentLevelProgressPercentage.toStringAsFixed(0)}%',
                    'Level Progress',
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    context,
                    '🗓️',
                    stats.checkedInTrips.toString(),
                    'Trips Attended',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    loading: () => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (e, s) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading milestones'),
      ),
    ),
  );
  }

  Widget _buildMilestoneBadge(BuildContext context, String emoji, String label) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String emoji, String value, String label) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


}
