import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../data/models/trip_history_filters.dart';
import '../../data/providers/trip_history_filter_provider.dart';
import 'trip_history_with_logbook_screen.dart';

/// Trip History Enhanced Screen with Advanced Filtering
/// 
/// Provides comprehensive filtering, sorting, and search capabilities for trip history
class TripHistoryEnhancedScreen extends ConsumerStatefulWidget {
  final int? memberId;

  const TripHistoryEnhancedScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<TripHistoryEnhancedScreen> createState() =>
      _TripHistoryEnhancedScreenState();
}

class _TripHistoryEnhancedScreenState
    extends ConsumerState<TripHistoryEnhancedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search updates
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final user = ref.read(currentUserProviderV2);
      final targetMemberId = widget.memberId ?? user?.id ?? 0;
      final provider = ref.read(tripHistoryFilterProvider(targetMemberId).notifier);
      final currentFilters = provider.filters;
      provider.updateFilters(
        currentFilters.copyWith(searchQuery: _searchController.text),
      );
    });
  }

  int get _targetMemberId {
    final user = ref.read(currentUserProviderV2);
    return widget.memberId ?? user?.id ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dataAsync = ref.watch(tripHistoryFilterProvider(_targetMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          // Filter button with badge
          dataAsync.whenOrNull(
            data: (data) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterBottomSheet(context, data.filters),
                ),
                if (data.filters.activeFilterCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${data.filters.activeFilterCount}',
                        style: TextStyle(
                          color: colors.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: dataAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading trip history...'),
        error: (error, stack) => ErrorState(
          title: 'Error Loading History',
          message: error.toString(),
          onRetry: () {
            ref.read(tripHistoryFilterProvider(_targetMemberId).notifier).refresh();
          },
        ),
        data: (data) => Column(
          children: [
            // Search Bar
            _buildSearchBar(colors),

            // Filter Summary & Stats
            _buildFilterSummary(data, colors),

            // Trip List
            Expanded(
              child: data.filteredTrips.isEmpty
                  ? EmptyState(
                      icon: Icons.filter_list_off,
                      title: 'No Trips Found',
                      message: data.filters.isDefault
                          ? 'No trips in your history yet.'
                          : 'No trips match the current filters.',
                      actionText: data.filters.isDefault ? null : 'Clear Filters',
                      onAction: data.filters.isDefault
                          ? null
                          : () {
                              ref.read(tripHistoryFilterProvider(_targetMemberId).notifier)
                                  .resetFilters();
                              _searchController.clear();
                            },
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(tripHistoryFilterProvider(_targetMemberId).notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.filteredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = data.filteredTrips[index];
                          final logbookEntries = data.getLogbookEntries(trip.tripId);
                          final skillsCount = data.getSkillsVerifiedCount(trip.tripId);

                          return _TripHistoryCard(
                            trip: trip,
                            logbookEntriesCount: logbookEntries.length,
                            skillsVerifiedCount: skillsCount,
                            onTap: () => context.push('/trips/${trip.tripId}'),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search trips...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colors.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildFilterSummary(TripHistoryFilteredData data, ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: data.filters.activeFilterCount > 0
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.stats.summary,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (!data.filters.isDefault) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.filters.filterSummary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!data.filters.isDefault)
                TextButton.icon(
                  onPressed: () {
                    ref.read(tripHistoryFilterProvider(_targetMemberId).notifier)
                        .resetFilters();
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                ),
            ],
          ),
          
          // Quick Stats Row
          if (data.filteredTrips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickStat(
                  icon: Icons.star,
                  label: 'Skills',
                  value: '${data.stats.totalSkillsVerified}',
                  color: colors.primary,
                ),
                const SizedBox(width: 16),
                _QuickStat(
                  icon: Icons.fact_check,
                  label: 'With Skills',
                  value: '${data.stats.tripsWithSkills}',
                  color: colors.tertiary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, TripHistoryFilters currentFilters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialFilters: currentFilters,
        onApply: (newFilters) {
          ref.read(tripHistoryFilterProvider(_targetMemberId).notifier)
              .updateFilters(newFilters);
        },
      ),
    );
  }
}

/// Quick Stat Widget
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

/// Trip History Card Widget
class _TripHistoryCard extends StatelessWidget {
  final TripHistoryItem trip;
  final int logbookEntriesCount;
  final int skillsVerifiedCount;
  final VoidCallback onTap;

  const _TripHistoryCard({
    required this.trip,
    required this.logbookEntriesCount,
    required this.skillsVerifiedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();
    final isUpcoming = trip.startTime.isAfter(now);
    final hasSkills = skillsVerifiedCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUpcoming
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.2),
          width: isUpcoming ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                width: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUpcoming ? colors.primary : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(trip.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUpcoming ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(trip.startTime),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isUpcoming ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Trip Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Level & Attendance
                    Row(
                      children: [
                        if (trip.level != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              trip.level!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (trip.attended)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: colors.primary,
                          ),
                      ],
                    ),

                    // Skills Summary
                    if (hasSkills) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$skillsVerifiedCount skill${skillsVerifiedCount > 1 ? 's' : ''} verified',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($logbookEntriesCount ${logbookEntriesCount > 1 ? 'entries' : 'entry'})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status Icon
              Icon(
                isUpcoming ? Icons.schedule : Icons.check,
                color: isUpcoming ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final TripHistoryFilters initialFilters;
  final Function(TripHistoryFilters) onApply;

  const _FilterBottomSheet({
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TripHistoryFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Trip History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_filters.isDefault)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filters = const TripHistoryFilters();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Filter Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Section
                    _buildSectionTitle('Date Range'),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 24),

                    // Trip Level Section
                    _buildSectionTitle('Trip Level'),
                    _buildLevelSelector(),
                    const SizedBox(height: 24),

                    // Attendance Filter Section
                    _buildSectionTitle('Trip Status'),
                    _buildAttendanceFilter(),
                    const SizedBox(height: 24),

                    // Skills Filter Section
                    _buildSectionTitle('Skills'),
                    _buildSkillsFilter(),
                    const SizedBox(height: 24),

                    // Sort Section
                    _buildSectionTitle('Sort By'),
                    _buildSortSelector(),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(
                    _filters.activeFilterCount > 0
                        ? 'Apply ${_filters.activeFilterCount} Filter${_filters.activeFilterCount > 1 ? 's' : ''}'
                        : 'Apply Filters',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DateRangePreset.values.map((preset) {
        final isSelected = _filters.dateRangePreset == preset;
        return FilterChip(
          label: Text(preset.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(dateRangePreset: preset);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLevelSelector() {
    final levels = [
      {'id': 1, 'name': 'Beginner'},
      {'id': 2, 'name': 'Intermediate'},
      {'id': 3, 'name': 'Advanced'},
      {'id': 4, 'name': 'Expert'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final levelId = level['id'] as int;
        final isSelected = _filters.selectedLevelIds.contains(levelId);
        return FilterChip(
          label: Text(level['name'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              final newLevels = Set<int>.from(_filters.selectedLevelIds);
              if (selected) {
                newLevels.add(levelId);
              } else {
                newLevels.remove(levelId);
              }
              _filters = _filters.copyWith(selectedLevelIds: newLevels);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TripAttendanceFilter.values.map((filter) {
        final isSelected = _filters.attendanceFilter == filter;
        return FilterChip(
          label: Text(filter.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(attendanceFilter: filter);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSkillsFilter() {
    return SwitchListTile(
      title: const Text('Only trips with verified skills'),
      subtitle: const Text('Show only trips where you verified skills'),
      value: _filters.onlyTripsWithSkills,
      onChanged: (value) {
        setState(() {
          _filters = _filters.copyWith(onlyTripsWithSkills: value);
        });
      },
    );
  }

  Widget _buildSortSelector() {
    return Column(
      children: TripHistorySortOption.values.map((option) {
        return ListTile(
          leading: Radio<TripHistorySortOption>(
            value: option,
            groupValue: _filters.sortBy,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(sortBy: value);
              });
            },
          ),
          title: Text(option.displayName),
          onTap: () {
            setState(() {
              _filters = _filters.copyWith(sortBy: option);
            });
          },
        );
      }).toList(),
    );
  }
}
