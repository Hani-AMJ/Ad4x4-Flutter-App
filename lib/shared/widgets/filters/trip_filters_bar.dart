import 'package:flutter/material.dart';
import '../../../data/models/trip_filters.dart';

/// Trip Filters Bar Component
/// 
/// Shows filter chips for Level, Area, Date, Status, and View toggle
class TripFiltersBar extends StatelessWidget {
  final TripFilters filters;
  final ValueChanged<TripFilters> onFiltersChanged;

  const TripFiltersBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                        isActive: filters.dateRange != TripDateRange.thisWeek,
                        onTap: () => _showDateRangeSheet(context),
                      ),
                      const SizedBox(width: 8),

                      // Status filter
                      _FilterChip(
                        label: filters.status.displayName,
                        icon: Icons.filter_list,
                        isActive: filters.status != TripStatus.upcoming,
                        onTap: () => _showStatusSheet(context),
                      ),
                      const SizedBox(width: 8),

                      // Level filter (if set)
                      if (filters.levelId != null)
                        _FilterChip(
                          label: 'Level ${filters.levelId}',
                          icon: Icons.trending_up,
                          isActive: true,
                          onTap: () => _showLevelSheet(context),
                          onClear: () => onFiltersChanged(
                            filters.copyWith(levelId: null),
                          ),
                        ),
                      if (filters.levelId == null)
                        _FilterChip(
                          label: 'Level',
                          icon: Icons.trending_up,
                          isActive: false,
                          onTap: () => _showLevelSheet(context),
                        ),
                      const SizedBox(width: 8),

                      // Area filter (if set)
                      if (filters.area != null)
                        _FilterChip(
                          label: filters.area!,
                          icon: Icons.location_on,
                          isActive: true,
                          onTap: () => _showAreaSheet(context),
                          onClear: () => onFiltersChanged(
                            filters.copyWith(area: null),
                          ),
                        ),
                      if (filters.area == null)
                        _FilterChip(
                          label: 'Area',
                          icon: Icons.location_on,
                          isActive: false,
                          onTap: () => _showAreaSheet(context),
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

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _StatusSheet(
        currentStatus: filters.status,
        onSelected: (status) {
          onFiltersChanged(filters.copyWith(status: status));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLevelSheet(BuildContext context) {
    // TODO: Implement level selection sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Level filter coming soon')),
    );
  }

  void _showAreaSheet(BuildContext context) {
    // TODO: Implement area selection sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Area filter coming soon')),
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

class _StatusSheet extends StatelessWidget {
  final TripStatus currentStatus;
  final ValueChanged<TripStatus> onSelected;

  const _StatusSheet({
    required this.currentStatus,
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
              'Select Trip Status',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...TripStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                Icons.filter_list,
                color: currentStatus == status ? colors.primary : null,
              ),
              title: Text(status.displayName),
              trailing: currentStatus == status
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () => onSelected(status),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
