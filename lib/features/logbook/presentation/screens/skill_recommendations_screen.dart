/// Skill Recommendations Screen
/// 
/// Displays intelligent skill recommendations with filtering and details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/level_configuration_provider.dart';
import '../../data/models/skill_recommendation.dart';
import '../../data/providers/skill_recommendation_provider.dart';

class SkillRecommendationsScreen extends ConsumerWidget {
  final int? memberId;

  const SkillRecommendationsScreen({
    super.key,
    this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final effectiveMemberId = memberId ?? authState.user?.id;

    final recommendationsAsync = ref.watch(filteredRecommendationsProvider(effectiveMemberId));
    final statsAsync = ref.watch(recommendationStatsProvider(effectiveMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(skillRecommendationsProvider(effectiveMemberId));
          ref.invalidate(recommendationStatsProvider(effectiveMemberId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Card
              statsAsync.when(
                data: (stats) => _buildStatsCard(stats, theme, colors),
                loading: () => _buildLoadingCard(theme),
                error: (error, stack) => _buildErrorCard(error.toString(), theme, colors),
              ),
              const SizedBox(height: 24),

              // Recommendations List
              recommendationsAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return _buildEmptyState(theme, colors);
                  }
                  return _buildRecommendationsList(recommendations, theme, colors, context, ref);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorCard(error.toString(), theme, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(RecommendationStats stats, ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact header with icon and title
            Row(
              children: [
                Icon(Icons.insights, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recommendation Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Compact 4-column stats grid in single row
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatItem(
                    icon: Icons.format_list_numbered,
                    label: 'Total',
                    value: stats.totalRecommendations.toString(),
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: _buildCompactStatItem(
                    icon: Icons.priority_high,
                    label: 'High Priority',
                    value: stats.highPriorityCount.toString(),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildCompactStatItem(
                    icon: Icons.calendar_today,
                    label: 'Trip Opportunities',
                    value: stats.upcomingTripOpportunities.toString(),
                    color: Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildCompactStatItem(
                    icon: Icons.trending_up,
                    label: 'Level Progress',
                    value: '${(stats.currentLevelCompletion * 100).toStringAsFixed(0)}%',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(
    List<SkillRecommendation> recommendations,
    ThemeData theme,
    ColorScheme colors,
    BuildContext context,
    WidgetRef ref,
  ) {
    // ✅ Use async FutureProvider to ensure cache is ready
    final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
    
    return levelConfigAsync.when(
      data: (levelConfig) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Skills (${recommendations.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecommendationCard(rec, theme, colors, context, ref, levelConfig),
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading level config: $e')),
    );
  }

  Widget _buildRecommendationCard(
    SkillRecommendation rec,
    ThemeData theme,
    ColorScheme colors,
    BuildContext context,
    WidgetRef ref,
    levelConfig,
  ) {
    final priorityColor = _getPriorityColor(rec.priority);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showRecommendationDetails(context, rec, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: priorityColor, width: 1),
                    ),
                    child: Text(
                      rec.priorityText,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelConfig.getLevelColor(rec.skill.level.id).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${levelConfig.getCleanLevelName(rec.skill.level.name)} ${levelConfig.getLevelEmoji(rec.skill.level.id)}',
                      style: TextStyle(
                        color: levelConfig.getLevelColor(rec.skill.level.id),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Reason Icon
                  Text(
                    rec.reason.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Skill Name
              Text(
                rec.skill.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Reason
              Text(
                '${rec.reason.icon} ${rec.reason.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Explanation
              Text(
                rec.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),

              // Trip Opportunity Badge
              if (rec.isUpcomingTripOpportunity && rec.relatedTripCount != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_available, color: Colors.teal, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${rec.relatedTripCount} upcoming trip${rec.relatedTripCount! > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tap hint
              const SizedBox(height: 12),
              Text(
                'Tap for details',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.primary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecommendationDetails(BuildContext context, SkillRecommendation rec, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // ⚠️ Using sync provider here - acceptable for modal since main list uses async
    final levelConfig = ref.read(levelConfigurationProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec.skill.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailBadge(
                      '${levelConfig.getCleanLevelName(rec.skill.level.name)} ${levelConfig.getLevelEmoji(rec.skill.level.id)}',
                      levelConfig.getLevelColor(rec.skill.level.id),
                    ),
                  _buildDetailBadge(
                    rec.priorityText,
                    _getPriorityColor(rec.priority),
                  ),
                  _buildDetailBadge(
                    rec.reason.displayName,
                    colors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Explanation
              Text(
                'Why This Skill?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rec.explanation,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Benefits
              Text(
                'Benefits',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...rec.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),

              // Trip Opportunities
              if (rec.isUpcomingTripOpportunity && rec.relatedTripCount != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_available, color: Colors.teal, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Upcoming Opportunities',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have ${rec.relatedTripCount} upcoming trip${rec.relatedTripCount! > 1 ? 's' : ''} where this skill can be verified!',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],

              // Next Step Tip
              if (rec.nextStepTip != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: colors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Next Step',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.nextStepTip!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],

              // Skill Description
              const SizedBox(height: 24),
              Text(
                'Skill Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rec.skill.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),

              // Action Button
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/logbook/trip-planning');
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('View Trip Planning'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(recommendationFilterProvider);

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
                  'Filter Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(recommendationFilterProvider.notifier).state =
                        const RecommendationFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Priority Filter
            Text(
              'Minimum Priority',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((priority) {
                final isSelected = currentFilter.minPriority == priority;
                return FilterChip(
                  label: Text(_getPriorityText(priority)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(recommendationFilterProvider.notifier).state =
                        currentFilter.copyWith(
                      minPriority: selected ? priority : null,
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Trip Opportunity Toggle
            SwitchListTile(
              title: const Text('Upcoming Trip Opportunities Only'),
              subtitle: const Text('Show only skills for upcoming trips'),
              value: currentFilter.upcomingTripOnly ?? false,
              onChanged: (value) {
                ref.read(recommendationFilterProvider.notifier).state =
                    currentFilter.copyWith(
                  upcomingTripOnly: value ? true : null,
                );
              },
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 12),
            Text('About Recommendations'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skill recommendations are personalized based on:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Your current skill level and progression'),
              Text('• Skills you\'ve already verified'),
              Text('• Upcoming trip opportunities'),
              Text('• Natural skill progression paths'),
              Text('• Safety and foundation skills'),
              SizedBox(height: 16),
              Text(
                'Priority Levels',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('🔴 Critical - Essential skills for your level'),
              Text('🟠 High - Strongly recommended'),
              Text('🟡 Medium - Good additions to your skills'),
              Text('🟢 Low - Optional but beneficial'),
              SizedBox(height: 16),
              Text(
                'Tap any recommendation to see full details, benefits, and next steps!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(String error, ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'All Caught Up!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve verified all recommended skills for your current level. Keep up the great work!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      default:
        return 'Optional';
    }
  }


}
