import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/trip_filters.dart';
import '../../../features/trips/presentation/providers/levels_provider.dart';
import '../../../features/trips/presentation/providers/meeting_points_provider.dart';

/// Trip Filters Bar Component
/// 
/// Shows filter chips for Level, Area, Date, and View toggle
class TripFiltersBar extends ConsumerWidget {
  final TripFilters filters;
  final ValueChanged<TripFilters> onFiltersChanged;

  const TripFiltersBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Top row: View toggle and filter chips
          Row(
            children: [
              // View Mode Toggle
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewModeButton(
                      icon: Icons.list,
                      isSelected: filters.view == TripViewMode.list,
                      onTap: () => onFiltersChanged(
                        filters.copyWith(view: TripViewMode.list),
                      ),
                    ),
                    _ViewModeButton(
                      icon: Icons.map,
                      isSelected: filters.view == TripViewMode.map,
                      onTap: () => onFiltersChanged(
                        filters.copyWith(view: TripViewMode.map),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Scrollable filter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date filter
                      _FilterChip(
                        label: filters.dateRange.displayName,
                        icon: Icons.calendar_today,
                        isActive: filters.dateRange != TripDateRange.all,
                        onTap: () => _showDateRangeSheet(context),
                      ),
                      const SizedBox(width: 8),

                      // Level filter (if set)
                      if (filters.levelId != null)
                        _FilterChip(
                          label: 'Level ${filters.levelId}',
                          icon: Icons.trending_up,
                          isActive: true,
                          onTap: () => _showLevelSheet(context, ref),
                          onClear: () => onFiltersChanged(
                            filters.copyWith(levelId: null),
                          ),
                        ),
                      if (filters.levelId == null)
                        _FilterChip(
                          label: 'Level',
                          icon: Icons.trending_up,
                          isActive: false,
                          onTap: () => _showLevelSheet(context, ref),
                        ),
                      const SizedBox(width: 8),

                      // Area filter (if set)
                      if (filters.area != null)
                        _FilterChip(
                          label: filters.area!,
                          icon: Icons.location_on,
                          isActive: true,
                          onTap: () => _showAreaSheet(context, ref),
                          onClear: () => onFiltersChanged(
                            filters.copyWith(area: null),
                          ),
                        ),
                      if (filters.area == null)
                        _FilterChip(
                          label: 'Area',
                          icon: Icons.location_on,
                          isActive: false,
                          onTap: () => _showAreaSheet(context, ref),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Active filters count or reset button
          if (filters.activeFilterCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filters.activeFilterCount} filter(s) active',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () => onFiltersChanged(const TripFilters()),
                  child: const Text('Reset all'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDateRangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DateRangeSheet(
        currentRange: filters.dateRange,
        onSelected: (range) {
          onFiltersChanged(filters.copyWith(dateRange: range));
          Navigator.pop(context);
        },
      ),
    );
  }

  // Status sheet removed - redundant without Past Trips tab

  void _showLevelSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LevelSheet(
        currentLevelId: filters.levelId,
        onSelected: (levelId) {
          onFiltersChanged(filters.copyWith(levelId: levelId));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAreaSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AreaSheet(
        currentArea: filters.area,
        onSelected: (area) {
          onFiltersChanged(filters.copyWith(area: area));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.2)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? colors.primary : colors.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? colors.primary : colors.onSurface,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRangeSheet extends StatelessWidget {
  final TripDateRange currentRange;
  final ValueChanged<TripDateRange> onSelected;

  const _DateRangeSheet({
    required this.currentRange,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Date Range',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...TripDateRange.values.map((range) {
            return ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: currentRange == range ? colors.primary : null,
              ),
              title: Text(range.displayName),
              trailing: currentRange == range
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () => onSelected(range),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Status sheet removed - redundant without Past Trips tab

/// Level Selection Sheet
class _LevelSheet extends ConsumerWidget {
  final int? currentLevelId;
  final ValueChanged<int?> onSelected;

  const _LevelSheet({
    required this.currentLevelId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final levelsAsync = ref.watch(levelsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Difficulty Level',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          levelsAsync.when(
            data: (levels) {
              return Column(
                children: [
                  // "All Levels" option
                  ListTile(
                    leading: Icon(
                      Icons.layers,
                      color: currentLevelId == null ? colors.primary : null,
                    ),
                    title: const Text('All Levels'),
                    trailing: currentLevelId == null
                        ? Icon(Icons.check, color: colors.primary)
                        : null,
                    onTap: () => onSelected(null),
                  ),
                  const Divider(),
                  // Level options with exact icons and colors from screenshot
                  ...levels.map((level) {
                    final isSelected = currentLevelId == level.id;
                    
                    // Get level-specific icon and color - exact match to screenshot
                    IconData levelIcon;
                    Color levelColor;
                    
                    final levelName = level.name.toLowerCase();
                    if (levelName.contains('club event') || level.numericLevel == 1) {
                      // Club Event → Calendar icon (purple #8E44AD)
                      levelIcon = Icons.event;
                      levelColor = const Color(0xFF8E44AD);
                    } else if (levelName.contains('newbie') && !levelName.contains('anit')) {
                      // Newbie → Mortarboard icon (light green #2ECC71)
                      levelIcon = Icons.school;
                      levelColor = const Color(0xFF2ECC71);
                    } else if (levelName.contains('anit') || level.numericLevel == 2 || level.numericLevel == 3) {
                      // ANIT → Mortarboard icon (dark green #27AE60)
                      levelIcon = Icons.school;
                      levelColor = const Color(0xFF27AE60);
                    } else if (levelName.contains('intermediate') || level.numericLevel == 4) {
                      // Intermediate → Trending up icon (blue #3498DB)
                      levelIcon = Icons.trending_up;
                      levelColor = const Color(0xFF3498DB);
                    } else if (levelName.contains('advanced') || level.numericLevel == 5) {
                      // Advanced → Speedometer icon (orange #E67E22)
                      levelIcon = Icons.speed;
                      levelColor = const Color(0xFFE67E22);
                    } else if (levelName.contains('expert') || level.numericLevel == 6) {
                      // Expert → Star icon (red - not in screenshot, using default)
                      levelIcon = Icons.star;
                      levelColor = const Color(0xFFF39C12);
                    } else if (levelName.contains('explorer') || level.numericLevel == 7) {
                      // Explorer → Compass icon (red #E74C3C)
                      levelIcon = Icons.explore;
                      levelColor = const Color(0xFFE74C3C);
                    } else if (levelName.contains('marshal') || level.numericLevel == 8) {
                      // Marshal → Shield icon (golden yellow #F39C12)
                      levelIcon = Icons.shield;
                      levelColor = const Color(0xFFF39C12);
                    } else if (levelName.contains('board') || level.numericLevel == 9) {
                      // Board Member → Star icon (dark blue #34495E)
                      levelIcon = Icons.workspace_premium;
                      levelColor = const Color(0xFF34495E);
                    } else {
                      // Default fallback
                      levelIcon = Icons.trending_up;
                      levelColor = Colors.grey;
                    }
                    
                    return ListTile(
                      leading: Icon(
                        levelIcon,
                        color: isSelected ? colors.primary : levelColor,
                        size: 28,
                      ),
                      title: Text(level.name),
                      subtitle: level.description != null
                          ? Text(
                              level.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      onTap: () => onSelected(level.id),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load levels',
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Area Selection Sheet with Search
class _AreaSheet extends ConsumerStatefulWidget {
  final String? currentArea;
  final ValueChanged<String?> onSelected;

  const _AreaSheet({
    required this.currentArea,
    required this.onSelected,
  });

  @override
  ConsumerState<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends ConsumerState<_AreaSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meetingPointsAsync = ref.watch(meetingPointsProvider);

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header with search
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Area',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search areas...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Area list
              Expanded(
                child: meetingPointsAsync.when(
                  data: (meetingPoints) {
                    // Get unique areas (filter out nulls and empty strings)
                    final areas = meetingPoints
                        .map((mp) => mp.area)
                        .where((area) => area != null && area.isNotEmpty)
                        .cast<String>()
                        .toSet()
                        .toList();
                    areas.sort();

                    // Filter by search query
                    final filteredAreas = _searchQuery.isEmpty
                        ? areas
                        : areas
                            .where((area) =>
                                area.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filteredAreas.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: colors.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No areas found',
                                style: TextStyle(
                                  color: colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView(
                      controller: scrollController,
                      children: [
                        // "All Areas" option
                        ListTile(
                          leading: Icon(
                            Icons.public,
                            color: widget.currentArea == null
                                ? colors.primary
                                : null,
                          ),
                          title: const Text('All Areas'),
                          trailing: widget.currentArea == null
                              ? Icon(Icons.check, color: colors.primary)
                              : null,
                          onTap: () => widget.onSelected(null),
                        ),
                        const Divider(),
                        // Area options
                        ...filteredAreas.map((area) {
                          final isSelected = widget.currentArea == area;
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected ? colors.primary : null,
                            ),
                            title: Text(area),
                            trailing: isSelected
                                ? Icon(Icons.check, color: colors.primary)
                                : null,
                            onTap: () => widget.onSelected(area),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load areas',
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
