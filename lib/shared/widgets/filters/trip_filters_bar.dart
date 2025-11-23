import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip_filters.dart';
import '../../../features/trips/presentation/providers/levels_provider.dart';
import '../../../features/trips/presentation/providers/meeting_points_provider.dart';
import '../../../core/utils/level_display_helper.dart';

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
                      const SizedBox(width: 8),

                      // ✅ NEW: Eligible Only filter toggle
                      _FilterChip(
                        label: 'Eligible Only',
                        icon: filters.showEligibleOnly ? Icons.check_circle : Icons.lock_open,
                        isActive: filters.showEligibleOnly,
                        onTap: () => onFiltersChanged(
                          filters.copyWith(showEligibleOnly: !filters.showEligibleOnly),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ✅ NEW: More Filters button
                      _FilterChip(
                        label: 'More',
                        icon: Icons.filter_list,
                        isActive: filters.meetingPointId != null || 
                                  filters.leadId != null ||
                                  filters.endTimeAfter != null ||
                                  filters.endTimeBefore != null,
                        onTap: () => _showAdvancedFiltersSheet(context, ref),
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

  // ✅ NEW: Show advanced filters sheet
  void _showAdvancedFiltersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AdvancedFiltersSheet(
        filters: filters,
        onFiltersChanged: onFiltersChanged,
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
                  // Level options using centralized LevelDisplayHelper
                  ...levels.map((level) {
                    final isSelected = currentLevelId == level.id;
                    
                    // Use centralized helper for consistent icon and color
                    final levelIcon = LevelDisplayHelper.getLevelIcon(level.numericLevel);
                    final levelColor = LevelDisplayHelper.getLevelColor(level.numericLevel);
                    
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

/// Meeting Point Selection Sheet with Search
/// 
/// Searchable modal for selecting meeting points - handles hundreds of points efficiently
class _MeetingPointSheet extends ConsumerStatefulWidget {
  final int? currentMeetingPointId;
  final ValueChanged<int?> onSelected;

  const _MeetingPointSheet({
    required this.currentMeetingPointId,
    required this.onSelected,
  });

  @override
  ConsumerState<_MeetingPointSheet> createState() => _MeetingPointSheetState();
}

class _MeetingPointSheetState extends ConsumerState<_MeetingPointSheet> {
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
                      'Select Meeting Point',
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
                        hintText: 'Search meeting points...',
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
              // Meeting Points list
              Expanded(
                child: meetingPointsAsync.when(
                  data: (meetingPoints) {
                    if (meetingPoints.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No meeting points available',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }

                    // Filter by search query
                    final filteredMeetingPoints = _searchQuery.isEmpty
                        ? meetingPoints
                        : meetingPoints
                            .where((mp) =>
                                mp.name.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filteredMeetingPoints.isEmpty) {
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
                                'No meeting points found',
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
                        // "All Meeting Points" option
                        ListTile(
                          leading: Icon(
                            Icons.place,
                            color: widget.currentMeetingPointId == null
                                ? colors.primary
                                : null,
                          ),
                          title: const Text('All Meeting Points'),
                          trailing: widget.currentMeetingPointId == null
                              ? Icon(Icons.check, color: colors.primary)
                              : null,
                          onTap: () => widget.onSelected(null),
                        ),
                        const Divider(),
                        // Meeting point options
                        ...filteredMeetingPoints.map((mp) {
                          final isSelected = widget.currentMeetingPointId == mp.id;
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected ? colors.primary : null,
                            ),
                            title: Text(mp.name),
                            subtitle: mp.area != null && mp.area!.isNotEmpty
                                ? Text(
                                    mp.area!,
                                    style: TextStyle(
                                      color: colors.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? Icon(Icons.check, color: colors.primary)
                                : null,
                            onTap: () => widget.onSelected(mp.id),
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
                            'Failed to load meeting points',
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

/// Advanced Filters Sheet
/// 
/// Shows additional filter options: Meeting Point, Lead, End Time
class _AdvancedFiltersSheet extends ConsumerStatefulWidget {
  final TripFilters filters;
  final ValueChanged<TripFilters> onFiltersChanged;

  const _AdvancedFiltersSheet({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  ConsumerState<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends ConsumerState<_AdvancedFiltersSheet> {
  late int? _selectedMeetingPointId;
  late int? _selectedLeadId;
  late DateTime? _endTimeAfter;
  late DateTime? _endTimeBefore;

  @override
  void initState() {
    super.initState();
    _selectedMeetingPointId = widget.filters.meetingPointId;
    _selectedLeadId = widget.filters.leadId;
    _endTimeAfter = widget.filters.endTimeAfter;
    _endTimeBefore = widget.filters.endTimeBefore;
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      widget.filters.copyWith(
        meetingPointId: _selectedMeetingPointId,
        leadId: _selectedLeadId,
        endTimeAfter: _endTimeAfter,
        endTimeBefore: _endTimeBefore,
      ),
    );
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _selectedMeetingPointId = null;
      _selectedLeadId = null;
      _endTimeAfter = null;
      _endTimeBefore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced Filters',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Meeting Point Filter - Searchable UI for scalability
                    Text(
                      'Meeting Point',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    meetingPointsAsync.when(
                      data: (meetingPoints) {
                        // Get selected meeting point name for display
                        final selectedMeetingPoint = _selectedMeetingPointId != null
                            ? meetingPoints.firstWhere(
                                (mp) => mp.id == _selectedMeetingPointId,
                                orElse: () => meetingPoints.first,
                              )
                            : null;

                        return InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _MeetingPointSheet(
                                currentMeetingPointId: _selectedMeetingPointId,
                                onSelected: (selectedId) {
                                  setState(() {
                                    _selectedMeetingPointId = selectedId;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outline),
                              borderRadius: BorderRadius.circular(12),
                              color: colors.surfaceContainerHighest,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedMeetingPoint?.name ?? 'All Meeting Points',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: selectedMeetingPoint != null
                                          ? colors.onSurface
                                          : colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Text(
                        'Failed to load meeting points',
                        style: TextStyle(color: colors.error),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // End Time Filter
                    Text(
                      'Trip End Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endTimeAfter ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _endTimeAfter = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _endTimeAfter != null
                                  ? 'After: ${DateFormat('MMM d, y').format(_endTimeAfter!)}'
                                  : 'After...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endTimeBefore ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _endTimeBefore = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _endTimeBefore != null
                                  ? 'Before: ${DateFormat('MMM d, y').format(_endTimeBefore!)}'
                                  : 'Before...',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_endTimeAfter != null || _endTimeBefore != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _endTimeAfter = null;
                            _endTimeBefore = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear End Time'),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
