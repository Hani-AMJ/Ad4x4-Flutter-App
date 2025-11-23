import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../data/models/timeline_models.dart';
import '../../data/providers/timeline_provider.dart';

/// Logbook Timeline Visualization Screen
/// Interactive visual timeline of skill verifications with milestones
class LogbookTimelineVisualizationScreen extends ConsumerStatefulWidget {
  final int? memberId;

  const LogbookTimelineVisualizationScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<LogbookTimelineVisualizationScreen> createState() =>
      _LogbookTimelineVisualizationScreenState();
}

class _LogbookTimelineVisualizationScreenState
    extends ConsumerState<LogbookTimelineVisualizationScreen> {
  TimelineViewMode _viewMode = TimelineViewMode.chronological;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final targetMemberId = widget.memberId ?? authState.user?.id;

    final entriesAsync = ref.watch(filteredTimelineEntriesProvider(targetMemberId));
    final statsAsync = ref.watch(timelineStatisticsProvider(targetMemberId));
    final filter = ref.watch(timelineFilterProvider);

    final isViewingOwnTimeline = targetMemberId == authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isViewingOwnTimeline
            ? 'My Skill Timeline'
            : 'Skill Timeline'),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          PopupMenuButton<TimelineViewMode>(
            icon: const Icon(Icons.view_list),
            tooltip: 'View Mode',
            onSelected: (mode) {
              setState(() {
                _viewMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TimelineViewMode.chronological,
                child: Row(
                  children: [
                    Icon(Icons.timeline),
                    SizedBox(width: 12),
                    Text('Chronological'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TimelineViewMode.byMonth,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 12),
                    Text('By Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TimelineViewMode.byLevel,
                child: Row(
                  children: [
                    Icon(Icons.layers),
                    SizedBox(width: 12),
                    Text('By Level'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats, theme),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Active Filters
          if (filter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildFilterChips(filter),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(timelineFilterProvider.notifier).clearAll();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Timeline View
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildTimelineView(entries, theme);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading timeline',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(timelineEntriesProvider(targetMemberId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(TimelineStatistics stats, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Timeline Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    stats.totalEntries.toString(),
                    Icons.verified,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Days Active',
                    stats.daysActive.toString(),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg/Month',
                    stats.averageVerificationsPerMonth.toStringAsFixed(1),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Best Streak',
                    stats.longestStreak.toString(),
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
            if (stats.firstVerification != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Started Journey',
                          style: theme.textTheme.bodySmall),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(stats.firstVerification!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Latest Achievement',
                          style: theme.textTheme.bodySmall),
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(stats.lastVerification!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimelineView(List<TimelineEntry> entries, ThemeData theme) {
    switch (_viewMode) {
      case TimelineViewMode.chronological:
        return _buildChronologicalTimeline(entries, theme);
      case TimelineViewMode.byMonth:
        return _buildMonthlyGroupedTimeline(entries, theme);
      case TimelineViewMode.byLevel:
        return _buildLevelGroupedTimeline(entries, theme);
      default:
        return _buildChronologicalTimeline(entries, theme);
    }
  }

  Widget _buildChronologicalTimeline(
      List<TimelineEntry> entries, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        final authState = ref.read(authProviderV2);
        final targetMemberId = widget.memberId ?? authState.user?.id;
        ref.invalidate(timelineEntriesProvider(targetMemberId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isLast = index == entries.length - 1;
          return _buildTimelineItem(entry, isLast, theme);
        },
      ),
    );
  }

  Widget _buildTimelineItem(
      TimelineEntry entry, bool isLast, ThemeData theme) {
    final levelColor = _getLevelColor(entry.skillLevel);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: entry.isMilestone ? Colors.amber : levelColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: entry.isMilestone
                    ? const Icon(Icons.star, size: 10, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(entry.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Milestone badge (if applicable)
                  if (entry.isMilestone) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.celebration,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            entry.milestoneText ?? 'Milestone',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Skill card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Skill name and level
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: levelColor),
                                ),
                                child: Text(
                                  'L${entry.skillLevel}',
                                  style: TextStyle(
                                    color: levelColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.verification.logbookSkill.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Verifier
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                entry.verification.verifiedBy.displayName,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),

                          // Trip (if applicable)
                          if (entry.verification.trip != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.directions_car,
                                    size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.verification.trip!.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Comment (if applicable)
                          if (entry.verification.comment != null &&
                              entry.verification.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.verification.comment!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGroupedTimeline(
      List<TimelineEntry> entries, ThemeData theme) {
    // Group entries by month
    final groupedByMonth = <String, List<TimelineEntry>>{};
    for (final entry in entries) {
      final monthKey = DateFormat('yyyy-MM').format(entry.date);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(entry);
    }

    final sortedMonths = groupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final monthKey = sortedMonths[index];
        final monthEntries = groupedByMonth[monthKey]!;
        final date = DateTime.parse('$monthKey-01');
        final monthLabel = DateFormat('MMMM yyyy').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${monthEntries.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Month entries
            ...monthEntries.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final timelineEntry = entry.value;
              final isLast = itemIndex == monthEntries.length - 1;
              return _buildTimelineItem(timelineEntry, isLast, theme);
            }),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildLevelGroupedTimeline(
      List<TimelineEntry> entries, ThemeData theme) {
    // Group entries by level
    final groupedByLevel = <int, List<TimelineEntry>>{};
    for (final entry in entries) {
      groupedByLevel.putIfAbsent(entry.skillLevel, () => []).add(entry);
    }

    final sortedLevels = groupedByLevel.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLevels.length,
      itemBuilder: (context, index) {
        final level = sortedLevels[index];
        final levelEntries = groupedByLevel[level]!;
        final levelColor = _getLevelColor(level);
        final levelName = _getLevelName(level);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: levelColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.layers, size: 20, color: levelColor),
                  const SizedBox(width: 8),
                  Text(
                    'Level $level - $levelName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${levelEntries.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Level entries
            ...levelEntries.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final timelineEntry = entry.value;
              final isLast = itemIndex == levelEntries.length - 1;
              return _buildTimelineItem(timelineEntry, isLast, theme);
            }),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No timeline entries',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(TimelineFilter filter) {
    final chips = <Widget>[];

    if (filter.skillLevel != null) {
      chips.add(Chip(
        label: Text('Level ${filter.skillLevel}'),
        onDeleted: () {
          ref.read(timelineFilterProvider.notifier).setLevelFilter(null);
        },
      ));
    }

    if (filter.startDate != null || filter.endDate != null) {
      final dateText = filter.startDate != null && filter.endDate != null
          ? '${DateFormat('MMM dd').format(filter.startDate!)} - ${DateFormat('MMM dd, yyyy').format(filter.endDate!)}'
          : filter.startDate != null
              ? 'From ${DateFormat('MMM dd, yyyy').format(filter.startDate!)}'
              : 'Until ${DateFormat('MMM dd, yyyy').format(filter.endDate!)}';

      chips.add(Chip(
        label: Text(dateText),
        onDeleted: () {
          ref.read(timelineFilterProvider.notifier).setDateRange(null, null);
        },
      ));
    }

    if (filter.withTrips == true) {
      chips.add(Chip(
        label: const Text('With Trips'),
        onDeleted: () {
          ref.read(timelineFilterProvider.notifier).setTripFilter(null);
        },
      ));
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      chips.add(Chip(
        label: Text('Search: "${filter.searchQuery}"'),
        onDeleted: () {
          ref.read(timelineFilterProvider.notifier).setSearchQuery(null);
        },
      ));
    }

    return chips;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter Timeline'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by Level:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int level = 1; level <= 5; level++)
                    FilterChip(
                      label: Text('Level $level'),
                      selected: ref.read(timelineFilterProvider).skillLevel == level,
                      onSelected: (selected) {
                        ref.read(timelineFilterProvider.notifier)
                            .setLevelFilter(selected ? level : null);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Show only trip-based verifications'),
                value: ref.read(timelineFilterProvider).withTrips == true,
                onChanged: (value) {
                  ref.read(timelineFilterProvider.notifier)
                      .setTripFilter(value == true ? true : null);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(timelineFilterProvider.notifier).clearAll();
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Unknown';
    }
  }
}
