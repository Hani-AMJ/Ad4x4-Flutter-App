import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/admin_trip_search_criteria.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/status_helpers.dart';
import '../../../../shared/constants/level_constants.dart';
import '../providers/admin_wizard_provider.dart';
import '../widgets/wizard_filter_drawer.dart';
import '../../../../data/models/approval_status_choice_model.dart';
import '../providers/approval_status_provider.dart';

/// Admin Trips Wizard Results Screen
/// 
/// Displays search results with editable filters
class AdminTripsWizardResultsScreen extends ConsumerStatefulWidget {
  const AdminTripsWizardResultsScreen({super.key});

  @override
  ConsumerState<AdminTripsWizardResultsScreen> createState() => _AdminTripsWizardResultsScreenState();
}

class _AdminTripsWizardResultsScreenState extends ConsumerState<AdminTripsWizardResultsScreen> {
  @override
  void initState() {
    super.initState();
    print('📊 [ResultsScreen] initState called');
    // Force a rebuild on next frame to ensure provider state is fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📊 [ResultsScreen] PostFrameCallback - forcing rebuild');
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('📊 [ResultsScreen] Building results screen...');
    final criteria = ref.watch(adminWizardProvider);
    final searchResults = criteria.searchResults;
    final isSearching = criteria.isSearching;
    final searchError = criteria.searchError;
    
    print('📊 [ResultsScreen] Current step: ${criteria.currentStep}');
    print('📊 [ResultsScreen] isSearching: $isSearching');
    print('📊 [ResultsScreen] searchError: $searchError');
    print('📊 [ResultsScreen] searchResults: ${searchResults?.length ?? 0} trips');
    
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active filters chip bar
        if (criteria.hasFilters)
          _ActiveFiltersBar(criteria: criteria),

        // Results content
        Expanded(
          child: () {
            if (isSearching) {
              print('📊 [ResultsScreen] Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }
            
            if (searchError != null) {
              print('📊 [ResultsScreen] Showing error: $searchError');
              return _buildError(context, searchError);
            }
            
            if (searchResults == null) {
              print('📊 [ResultsScreen] No results yet');
              return const Center(child: Text('No search executed'));
            }
            
            final trips = searchResults.cast<TripListItem>();
            print('📊 [ResultsScreen] Rendering ${trips.length} trips');
            return _buildResults(context, ref, trips, criteria);
          }(),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    List<TripListItem> trips,
    AdminTripSearchCriteria criteria,
  ) {
    if (trips.isEmpty) {
      return _buildEmptyState(context, ref, criteria);
    }

    return Column(
      children: [
        // Results count and refine button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${trips.length} trip${trips.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showFilterDrawer(context, ref),
                icon: const Icon(Icons.tune, size: 20),
                label: const Text('Refine'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Trips list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(adminWizardResultsProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                return _TripResultCard(trip: trips[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    AdminTripSearchCriteria criteria,
  ) {
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
              onPressed: () => _showFilterDrawer(context, ref),
              icon: const Icon(Icons.tune),
              label: const Text('Modify Filters'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(adminWizardProvider.notifier).resetWizard();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Start New Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
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
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDrawer(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WizardFilterDrawer(),
    );
  }
}

/// Active Filters Bar
/// 
/// Horizontal scrollable chips showing active filters
class _ActiveFiltersBar extends ConsumerWidget {
  final AdminTripSearchCriteria criteria;

  const _ActiveFiltersBar({required this.criteria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Active Filters',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(adminWizardProvider.notifier).clearAllFilters();
                  ref.read(adminWizardResultsProvider.notifier).executeSearch(
                        ref.read(adminWizardProvider),
                      );
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (criteria.tripType != null)
                  _FilterChip(
                    label: criteria.tripType!.displayName,
                    icon: criteria.tripType!.icon,
                    onRemove: () {
                      ref
                          .read(adminWizardProvider.notifier)
                          .removeFilter('tripType');
                      _reExecuteSearch(ref);
                    },
                  ),
                if (criteria.levelIds.isNotEmpty)
                  _FilterChip(
                    label:
                        '${criteria.levelIds.length} Level${criteria.levelIds.length == 1 ? '' : 's'}',
                    icon: '🏔️',
                    onRemove: () {
                      ref.read(adminWizardProvider.notifier).removeFilter('levels');
                      _reExecuteSearch(ref);
                    },
                  ),
                if (criteria.leadUserId != null)
                  _FilterChip(
                    label: 'Trip Lead',
                    icon: '👤',
                    onRemove: () {
                      ref.read(adminWizardProvider.notifier).removeFilter('lead');
                      _reExecuteSearch(ref);
                    },
                  ),
                if (criteria.meetingPointArea != null)
                  _FilterChip(
                    label: criteria.meetingPointArea!,
                    icon: '📍',
                    onRemove: () {
                      ref.read(adminWizardProvider.notifier).removeFilter('area');
                      _reExecuteSearch(ref);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reExecuteSearch(WidgetRef ref) {
    ref.read(adminWizardResultsProvider.notifier).executeSearch(
          ref.read(adminWizardProvider),
        );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onRemove;

  const _FilterChip({
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
          Text(
            icon,
            style: const TextStyle(fontSize: 14),
          ),
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

/// Trip Result Card
/// 
/// Displays trip information in search results
class _TripResultCard extends ConsumerWidget {
  final TripListItem trip;

  const _TripResultCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    final user = ref.watch(authProviderV2).user;

    final levelData = LevelConstants.getIconAndColor(
      trip.level.numericLevel,
      trip.level.name,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: levelData.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: levelData.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(levelData.icon, size: 14, color: levelData.color),
                    const SizedBox(width: 6),
                    Text(
                      trip.level.name,
                      style: TextStyle(
                        color: levelData.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Details
              _DetailRow(
                icon: Icons.person,
                text: trip.lead.displayName,
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
              const SizedBox(height: 12),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/admin/trips/${trip.id}/registrants'),
                    icon: const Icon(Icons.people, size: 18),
                    label: Text('Registrants (${trip.registeredCount})'),
                  ),
                  if (user?.hasPermission('edit_trips') ?? false)
                    TextButton.icon(
                      onPressed: () => context.push('/trips/${trip.id}/edit'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                ],
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
