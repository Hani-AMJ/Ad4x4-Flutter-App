/// Skills Comparison Screen
/// 
/// Compare skill verification status between two members

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/level_configuration_provider.dart';
import '../../data/models/skills_comparison.dart';
import '../../data/providers/skills_comparison_provider.dart';

class SkillsComparisonScreen extends ConsumerStatefulWidget {
  final int? comparisonMemberId;

  const SkillsComparisonScreen({
    super.key,
    this.comparisonMemberId,
  });

  @override
  ConsumerState<SkillsComparisonScreen> createState() => _SkillsComparisonScreenState();
}

class _SkillsComparisonScreenState extends ConsumerState<SkillsComparisonScreen> {
  int? selectedComparisonMemberId;

  @override
  void initState() {
    super.initState();
    selectedComparisonMemberId = widget.comparisonMemberId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final primaryMemberId = authState.user?.id;

    if (primaryMemberId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skills Comparison')),
        body: const Center(child: Text('Please log in to compare skills')),
      );
    }

    if (selectedComparisonMemberId == null) {
      return _buildMemberSelectionScreen(context, theme, colors);
    }

    final comparisonPair = ComparisonPair(primaryMemberId, selectedComparisonMemberId!);
    final comparisonAsync = ref.watch(skillsComparisonProvider(comparisonPair));
    final filteredItemsAsync = ref.watch(filteredComparisonProvider(comparisonPair));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                selectedComparisonMemberId = null;
              });
            },
          ),
        ],
      ),
      body: comparisonAsync.when(
        data: (comparison) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(skillsComparisonProvider(comparisonPair));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMemberCards(comparison, theme, colors),
                const SizedBox(height: 24),
                _buildStatisticsCard(comparison.statistics, theme, colors),
                const SizedBox(height: 24),
                filteredItemsAsync.when(
                  data: (items) => _buildComparisonList(items, theme, colors, context),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading comparison: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSelectionScreen(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Member to Compare')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 64, color: colors.primary),
              const SizedBox(height: 24),
              Text(
                'Select a member to compare skills',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To use Skills Comparison, navigate to the Members List, select a member\'s profile, then tap "Compare Skills"',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/members'),
                icon: const Icon(Icons.people),
                label: const Text('Go to Members List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCards(SkillsComparison comparison, ThemeData theme, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: _buildMemberCard(
            comparison.primaryMember.displayName,
            comparison.statistics.primaryTotalVerified,
            comparison.statistics.primaryCompletionPercentage,
            colors.primary,
            theme,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.compare_arrows, color: colors.primary, size: 32),
        ),
        Expanded(
          child: _buildMemberCard(
            comparison.comparisonMember.displayName,
            comparison.statistics.comparisonTotalVerified,
            comparison.statistics.comparisonCompletionPercentage,
            colors.secondary,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(String name, int verified, double percentage, Color color, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              verified.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Skills',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(ComparisonStatistics stats, ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stats.comparisonMessage,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Motivational message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stats.motivationalMessage,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Both',
                    value: stats.bothVerified.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.person,
                    label: 'Only You',
                    value: stats.onlyPrimaryVerified.toString(),
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Only Them',
                    value: stats.onlyComparisonVerified.toString(),
                    color: colors.secondary,
                  ),
                ),
              ],
            ),

            if (stats.commonStrengths.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Common Strengths',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stats.commonStrengths.map((category) {
                  return Chip(
                    label: Text(category),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: Colors.green),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparisonList(
    List<SkillComparisonItem> items,
    ThemeData theme,
    ColorScheme colors,
    BuildContext context,
  ) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.filter_alt_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No skills match the current filters',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group by level
    final byLevel = <int, List<SkillComparisonItem>>{};
    for (final item in items) {
      final level = item.skill.level.numericLevel;
      byLevel.putIfAbsent(level, () => []).add(item);
    }

    final sortedLevels = byLevel.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills Breakdown (${items.length})',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedLevels.map((level) {
          final levelItems = byLevel[level]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLevelHeader(level, levelItems.length, theme),
                const SizedBox(height: 8),
                ...levelItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildComparisonCard(item, theme, colors),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLevelHeader(int level, int count, ThemeData theme) {
    final levelName = _getLevelName(level);
    final levelConfig = ref.read(levelConfigurationProvider);
    final emoji = levelConfig.getLevelEmoji(level);
    final color = levelConfig.getLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            'Level $level - $levelName',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$count skill${count > 1 ? 's' : ''}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(SkillComparisonItem item, ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Text(
          item.status.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          item.skill.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.status.displayName),
        trailing: item.whoVerifiedFirst != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.whoVerifiedFirst} first',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.daysDifference != null)
                    Text(
                      '${item.daysDifference}d diff',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(comparisonFilterProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter Comparison',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(comparisonFilterProvider.notifier).state =
                        const ComparisonFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Filter
            Text(
              'Verification Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ComparisonStatus.values.map((status) {
                final isSelected = currentFilter.statuses?.contains(status) ?? false;
                return FilterChip(
                  label: Text('${status.icon} ${status.displayName}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newStatuses = List<ComparisonStatus>.from(
                      currentFilter.statuses ?? [],
                    );
                    if (selected) {
                      newStatuses.add(status);
                    } else {
                      newStatuses.remove(status);
                    }
                    ref.read(comparisonFilterProvider.notifier).state =
                        currentFilter.copyWith(
                      statuses: newStatuses.isEmpty ? null : newStatuses,
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Intermediate';
      case 3: return 'Advanced';
      case 4: return 'Expert';
      case 5: return 'Master';
      default: return 'Level $level';
    }
  }
}
