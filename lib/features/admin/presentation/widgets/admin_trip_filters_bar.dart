import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../trips/presentation/providers/levels_provider.dart';
import '../providers/approval_status_provider.dart';
import '../../../../core/utils/level_display_helper.dart';

/// Admin Trip Filters Bar
/// 
/// Provides filtering and searching options for the trip admin list.
/// Features:
/// - Status filter (all, pending, approved, upcoming, completed)
/// - Date range picker
/// - Search by title/description/organizer
/// - Sort options (newest, oldest, start date)
/// - Level filter (difficulty levels)
/// - Organizer filter
class AdminTripFiltersBar extends ConsumerStatefulWidget {
  final String statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final int? levelFilter;
  final int? organizerFilter;
  final Function({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int? levelId,
    int? organizerId,
  }) onFiltersChanged;

  const AdminTripFiltersBar({
    super.key,
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.searchQuery,
    this.levelFilter,
    this.organizerFilter,
    required this.onFiltersChanged,
  });

  @override
  ConsumerState<AdminTripFiltersBar> createState() => _AdminTripFiltersBarState();
}

class _AdminTripFiltersBarState extends ConsumerState<AdminTripFiltersBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
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
                          widget.onFiltersChanged(search: '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                widget.onFiltersChanged(search: value);
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Status filter
                _FilterChip(
                  label: _getStatusLabel(widget.statusFilter),
                  icon: Icons.filter_list,
                  onTap: () => _showStatusFilterDialog(context),
                ),
                const SizedBox(width: 8),

                // Date range filter
                _FilterChip(
                  label: widget.startDate != null || widget.endDate != null
                      ? _formatDateRange()
                      : 'Date Range',
                  icon: Icons.date_range,
                  onTap: () => _showDateRangePicker(context),
                ),
                const SizedBox(width: 8),

                // Level filter
                _FilterChip(
                  label: widget.levelFilter != null 
                      ? _getLevelName(widget.levelFilter!)
                      : 'All Levels',
                  icon: Icons.terrain,
                  onTap: () => _showLevelFilterDialog(context),
                ),
                
                // Clear all filters (if any active)
                if (widget.statusFilter != 'all' ||
                    widget.startDate != null ||
                    widget.endDate != null ||
                    widget.searchQuery.isNotEmpty ||
                    widget.levelFilter != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      widget.onFiltersChanged(
                        status: 'all',
                        startDate: null,
                        endDate: null,
                        search: '',
                        levelId: null,
                        organizerId: null,
                      );
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    // Handle backend codes (P, A, R, D) and legacy values (pending, approved)
    switch (status.toUpperCase()) {
      case 'P':
      case 'PENDING':
        return 'Pending';
      case 'A':
      case 'APPROVED':
        return 'Approved';
      case 'R':
      case 'REJECTED':
        return 'Rejected';
      case 'D':
      case 'DECLINED':
      case 'DELETED':
        return 'Deleted'; // ✅ FIXED: Show "Deleted" instead of "Declined"
      case 'UPCOMING':
        return 'Upcoming';
      case 'COMPLETED':
        return 'Completed';
      case 'ALL':
        return 'All Trips';
      default:
        // For any unknown status, capitalize first letter
        return status.isNotEmpty 
            ? status[0].toUpperCase() + status.substring(1).toLowerCase()
            : 'All Trips';
    }
  }

  String _formatDateRange() {
    final format = DateFormat('MMM dd');
    if (widget.startDate != null && widget.endDate != null) {
      return '${format.format(widget.startDate!)} - ${format.format(widget.endDate!)}';
    } else if (widget.startDate != null) {
      return 'From ${format.format(widget.startDate!)}';
    } else if (widget.endDate != null) {
      return 'Until ${format.format(widget.endDate!)}';
    }
    return 'Date Range';
  }

  String _getLevelName(int levelId) {
    // ✅ Get level name from loaded levels
    final levelsAsync = ref.read(levelsProvider);
    return levelsAsync.maybeWhen(
      data: (levels) {
        final level = levels.where((l) => l.id == levelId).firstOrNull;
        return level?.name ?? 'Level $levelId';
      },
      orElse: () => 'Level $levelId',
    );
  }

  Future<void> _showStatusFilterDialog(BuildContext context) async {
    // ✅ Load dynamic approval statuses from backend
    final statusesAsync = ref.read(approvalStatusChoicesProvider);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: statusesAsync.when(
          data: (statuses) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Always include "All Trips" option first
                  _StatusOption('all', 'All Trips', widget.statusFilter),
                  // Then dynamic backend statuses
                  ...statuses.map((status) => _StatusOption(
                    status.value, 
                    status.label, 
                    widget.statusFilter,
                  )),
                  // Add computed filters (upcoming, completed) if needed
                  _StatusOption('upcoming', 'Upcoming', widget.statusFilter),
                  _StatusOption('completed', 'Completed', widget.statusFilter),
                ],
              ),
            );
          },
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusOption('all', 'All Trips', widget.statusFilter),
              _StatusOption('P', 'Pending', widget.statusFilter),
              _StatusOption('A', 'Approved', widget.statusFilter),
              _StatusOption('upcoming', 'Upcoming', widget.statusFilter),
              _StatusOption('completed', 'Completed', widget.statusFilter),
            ],
          ),
          error: (e, s) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusOption('all', 'All Trips', widget.statusFilter),
              _StatusOption('P', 'Pending', widget.statusFilter),
              _StatusOption('A', 'Approved', widget.statusFilter),
              _StatusOption('upcoming', 'Upcoming', widget.statusFilter),
              _StatusOption('completed', 'Completed', widget.statusFilter),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      widget.onFiltersChanged(status: result);
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
    );

    if (picked != null) {
      widget.onFiltersChanged(
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  Future<void> _showLevelFilterDialog(BuildContext context) async {
    // ✅ Load actual levels from database
    final levelsAsync = ref.read(levelsProvider);
    
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Level'),
        content: levelsAsync.when(
          data: (levels) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LevelOption(null, 'All Levels', widget.levelFilter, null, null),
                  ...levels.map((level) {
                    // ✅ Use actual level data with icons and colors
                    final color = LevelDisplayHelper.getLevelColor(level.numericLevel);
                    final icon = LevelDisplayHelper.getLevelIcon(level.numericLevel);
                    return _LevelOption(
                      level.id,
                      level.name, // ✅ Show actual name (Club Event, Newbie, etc.)
                      widget.levelFilter,
                      icon,
                      color,
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading levels: $error'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null || result == null && widget.levelFilter != null) {
      widget.onFiltersChanged(levelId: result);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String value;
  final String label;
  final String currentValue;

  const _StatusOption(this.value, this.label, this.currentValue);

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: currentValue,
      onChanged: (val) => Navigator.pop(context, val),
    );
  }
}

class _LevelOption extends StatelessWidget {
  final int? value;
  final String label;
  final int? currentValue;
  final IconData? icon;
  final Color? color;

  const _LevelOption(
    this.value,
    this.label,
    this.currentValue,
    this.icon,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return RadioListTile<int?>(
      title: Row(
        children: [
          if (icon != null && color != null) ...[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
      value: value,
      groupValue: currentValue,
      onChanged: (val) => Navigator.pop(context, val),
    );
  }
}
