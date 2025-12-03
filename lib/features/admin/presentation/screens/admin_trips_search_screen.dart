import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_search_criteria.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/utils/status_helpers.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../providers/admin_trips_search_provider.dart';
import '../widgets/advanced_filters_modal.dart';
import '../../../../data/models/approval_status_choice_model.dart';
import '../providers/approval_status_provider.dart';

/// Admin Trips Search Screen
/// 
/// Modern single-screen search interface with quick filters and advanced options
class AdminTripsSearchScreen extends ConsumerStatefulWidget {
  const AdminTripsSearchScreen({super.key});

  @override
  ConsumerState<AdminTripsSearchScreen> createState() => _AdminTripsSearchScreenState();
}

class _AdminTripsSearchScreenState extends ConsumerState<AdminTripsSearchScreen> {
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(adminTripsSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
        actions: [
          // Advanced filters button
          IconButton(
            icon: Badge(
              isLabelVisible: searchState.criteria.hasAdvancedFilters,
              label: Text('${searchState.criteria.activeFilterCount}'),
              child: const Icon(Icons.tune),
            ),
            tooltip: 'Advanced Filters',
            onPressed: () => _showAdvancedFiltersModal(context),
          ),
          // Reset button
          if (searchState.criteria.hasAdvancedFilters)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset filters',
              onPressed: () {
                ref.read(adminTripsSearchProvider.notifier).clearAdvancedFilters();
              },
            ),
          // Sort menu
          _SortMenuButton(),
        ],
      ),
      body: Column(
        children: [
          // Quick filters (always visible)
          _QuickFiltersBar(),

          // Active filters chips (compact display)
          if (searchState.criteria.hasAdvancedFilters)
            _ActiveFiltersChips(),

          const Divider(height: 1),

          // Results section (no interference from filters!)
          Expanded(
            child: _buildResults(context, searchState),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFiltersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdvancedFiltersModal(),
    );
  }

  Widget _buildResults(BuildContext context, AdminTripsSearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Searching trips...'),
          ],
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Error loading trips',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                searchState.error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(adminTripsSearchProvider.notifier).executeSearch();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!searchState.hasSearched) {
      return const Center(child: Text('Start searching...'));
    }

    if (searchState.results.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Results count header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${searchState.results.length} trip${searchState.results.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (searchState.results.length != searchState.totalCount)
                Chip(
                  label: Text(
                    'Filtered from ${searchState.totalCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(adminTripsSearchProvider.notifier).executeSearch();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searchState.results.length,
              itemBuilder: (context, index) {
                return _TripResultCard(trip: searchState.results[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No trips found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search filters',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(adminTripsSearchProvider.notifier).clearAdvancedFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Filters Bar
/// 
/// Horizontal chips for main search types
class _QuickFiltersBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criteria = ref.watch(adminTripsSearchProvider).criteria;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TripSearchType.values.map((type) {
            final isSelected = criteria.searchType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(type.displayName),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(adminTripsSearchProvider.notifier).updateSearchType(type);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Advanced Filters Panel
/// 
/// Expandable panel with date, level, lead, and area filters

/// Active Filters Chips
class _ActiveFiltersChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criteria = ref.watch(adminTripsSearchProvider).criteria;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (criteria.dateFrom != null || criteria.dateTo != null)
              _FilterChipWidget(
                label: 'Date Range',
                icon: Icons.date_range,
                onRemove: () {
                  ref.read(adminTripsSearchProvider.notifier).updateDateRange(null, null);
                },
              ),
            if (criteria.levelIds.isNotEmpty)
              _FilterChipWidget(
                label: '${criteria.levelIds.length} Level${criteria.levelIds.length > 1 ? 's' : ''}',
                icon: Icons.terrain,
                onRemove: () async {
                  // Clear all levels
                  for (final id in List.from(criteria.levelIds)) {
                    await ref.read(adminTripsSearchProvider.notifier).toggleLevel(id);
                  }
                },
              ),
            if (criteria.leadUsername != null)
              _FilterChipWidget(
                label: criteria.leadUsername!,
                icon: Icons.person,
                onRemove: () {
                  ref.read(adminTripsSearchProvider.notifier).updateLeadFilter(null);
                },
              ),
            if (criteria.meetingPointArea != null)
              _FilterChipWidget(
                label: criteria.meetingPointArea!,
                icon: Icons.location_on,
                onRemove: () {
                  ref.read(adminTripsSearchProvider.notifier).updateAreaFilter(null);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChipWidget({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              Icons.close,
              size: 16,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort Menu Button
class _SortMenuButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(adminTripsSearchProvider).criteria.sortBy;

    return PopupMenuButton<TripSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort by',
      onSelected: (option) {
        ref.read(adminTripsSearchProvider.notifier).updateSortBy(option);
      },
      itemBuilder: (context) {
        return TripSortOption.values.map((option) {
          return PopupMenuItem<TripSortOption>(
            value: option,
            child: Row(
              children: [
                if (sortBy == option)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 12),
                Text(option.displayName),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

/// Trip Result Card
class _TripResultCard extends ConsumerWidget {
  final TripListItem trip;

  const _TripResultCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and approval status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: trip.approvalStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Level badge
              LevelDisplayHelper.buildCompactBadge(trip.level),
              const SizedBox(height: 12),

              // Trip details
              _DetailRow(
                icon: Icons.person,
                text: trip.lead.username,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.calendar_today,
                text: dateFormat.format(trip.startTime),
              ),
              if (trip.meetingPoint != null) ...[
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.location_on,
                  text: trip.meetingPoint!.name,
                ),
              ],
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.people,
                text: '${trip.registeredCount}/${trip.capacity} registered',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends ConsumerWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(approvalStatusChoicesProvider);

    return statusesAsync.when(
      data: (statuses) => _buildDynamicBadge(context, statuses),
      loading: () => _buildFallbackBadge(context),
      error: (e, s) => _buildFallbackBadge(context),
    );
  }

  /// Build dynamic badge with backend-driven labels and colors
  Widget _buildDynamicBadge(BuildContext context, List<ApprovalStatusChoice> statuses) {
    // Find matching status from backend choices
    ApprovalStatusChoice? matchedStatus;
    
    for (final choice in statuses) {
      final choiceValue = choice.value.toLowerCase();
      final statusLower = status.toLowerCase();
      
      // Match by value or backward compatibility (P=pending, A=approved, D=declined)
      if (choiceValue == statusLower ||
          (choiceValue == 'p' && statusLower == 'pending') ||
          (choiceValue == 'a' && statusLower == 'approved') ||
          (choiceValue == 'd' && statusLower == 'declined')) {
        matchedStatus = choice;
        break;
      }
    }

    // Use matched status or fallback
    final label = matchedStatus?.label ?? _getFallbackLabel(status);
    
    // Get color from matched status's static method or fallback
    final colorHex = matchedStatus != null 
        ? ApprovalStatusChoice.getColorHex(matchedStatus.value)
        : null;
    final color = _parseColor(colorHex, context) ?? _getFallbackColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build fallback badge with hardcoded labels (offline resilience)
  Widget _buildFallbackBadge(BuildContext context) {
    final label = _getFallbackLabel(status);
    final color = _getFallbackColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get fallback label based on status helpers
  String _getFallbackLabel(String status) {
    if (isPending(status)) return 'Pending';
    if (isApproved(status)) return 'Approved';
    if (isDeclined(status)) return 'Declined';
    return status;
  }

  /// Get fallback color based on status helpers
  Color _getFallbackColor(String status) {
    if (isPending(status)) return Colors.orange;
    if (isApproved(status)) return Colors.green;
    if (isDeclined(status)) return Colors.red;
    return Colors.grey;
  }

  /// Parse hex color string to Color object
  Color? _parseColor(String? hexColor, BuildContext context) {
    if (hexColor == null || !hexColor.startsWith('#')) return null;
    
    try {
      final hex = hexColor.substring(1);
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
