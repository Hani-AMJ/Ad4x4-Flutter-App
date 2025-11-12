import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/status_helpers.dart';
import '../widgets/admin_trip_filters_bar.dart';
import 'package:go_router/go_router.dart';

/// Admin Trip List Screen
/// 
/// Displays all trips with advanced filtering and management options.
/// Features:
/// - View all trips (not just pending)
/// - Filter by: status, date range, level, organizer
/// - Search by title/description
/// - Sort options
/// - Quick actions: Edit, Delete, View Details
class AdminTripsAllScreen extends ConsumerStatefulWidget {
  const AdminTripsAllScreen({super.key});

  @override
  ConsumerState<AdminTripsAllScreen> createState() => _AdminTripsAllScreenState();
}

class _AdminTripsAllScreenState extends ConsumerState<AdminTripsAllScreen> {
  // Filter states
  String _statusFilter = 'all'; // all, pending, approved, upcoming, completed
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  int? _levelFilter; // null = all levels
  int? _organizerFilter; // null = all organizers

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  /// Load trips with current filters
  Future<void> _loadTrips() async {
    setState(() {
      _tripsAsync = _fetchTrips();
    });
  }

  /// Fetch trips from API with filters
  Future<List<TripListItem>> _fetchTrips() async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Always sort by creation date (newest first)
      print('🔍 [AdminTripsAll] Fetching trips with ordering: -created');
      final response = await repository.getTrips(
        startTimeAfter: _startDate?.toIso8601String(),
        startTimeBefore: _endDate?.toIso8601String(),
        levelId: _levelFilter,
        ordering: '-created', // Always newest first (by creation date)
        page: 1,
        pageSize: 100,
      );

      final tripsData = response['results'] as List<dynamic>? ?? [];
      print('📊 [AdminTripsAll] Received ${tripsData.length} trips from API');
      var trips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      // ✅ FIXED: Use status helpers to check backend codes (A, P, D)
      if (_statusFilter != 'all') {
        if (_statusFilter == 'pending') {
          trips = trips.where((t) => isPending(t.approvalStatus)).toList();
        } else if (_statusFilter == 'approved') {
          trips = trips.where((t) => isApproved(t.approvalStatus)).toList();
        } else if (_statusFilter == 'upcoming') {
          final now = DateTime.now();
          trips = trips.where((t) => t.startTime.isAfter(now) && isApproved(t.approvalStatus)).toList();
        } else if (_statusFilter == 'completed') {
          final now = DateTime.now();
          trips = trips.where((t) => t.endTime.isBefore(now)).toList();
        }
      }

      // Organizer filter (client-side)
      if (_organizerFilter != null) {
        trips = trips.where((t) => t.lead.id == _organizerFilter).toList();
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        trips = trips.where((t) => 
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.lead.displayName.toLowerCase().contains(query)
        ).toList();
      }

      // Debug: Print first and last trip dates to verify sorting
      if (trips.isNotEmpty) {
        print('✅ [AdminTripsAll] Loaded ${trips.length} trips (ordered by: -created)');
        print('   First trip: ${trips.first.title} - Created: ${trips.first.created}');
        print('   Last trip: ${trips.last.title} - Created: ${trips.last.created}');
      }
      return trips;
    } catch (e, stackTrace) {
      print('❌ [AdminTripsAll] Error loading trips: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  late Future<List<TripListItem>> _tripsAsync = _fetchTrips();

  /// Handle filter changes
  void _onFiltersChanged({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int? levelId,
    int? organizerId,
  }) {
    setState(() {
      if (status != null) _statusFilter = status;
      if (startDate != null) _startDate = startDate;
      if (endDate != null) _endDate = endDate;
      if (search != null) _searchQuery = search;
      if (levelId != null) _levelFilter = levelId;
      if (organizerId != null) _organizerFilter = organizerId;
    });
    _loadTrips();
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    await _loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    
    // Check permissions
    final canEdit = user?.hasPermission('edit_trips') ?? false;
    final canDelete = user?.hasPermission('delete_trips') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
          // Add Trip button (if user has create permission)
          if (user?.hasPermission('create_trip') ?? false)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/trips/create'),
              tooltip: 'Create Trip',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters bar
          AdminTripFiltersBar(
            statusFilter: _statusFilter,
            startDate: _startDate,
            endDate: _endDate,
            searchQuery: _searchQuery,
            levelFilter: _levelFilter,
            organizerFilter: _organizerFilter,
            onFiltersChanged: _onFiltersChanged,
          ),

          // Trips list
          Expanded(
            child: FutureBuilder<List<TripListItem>>(
              future: _tripsAsync,
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading trips',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _handleRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final trips = snapshot.data ?? [];

                // Empty state
                if (trips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Trips Found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No trips match your search'
                              : 'No trips match your filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _statusFilter = 'all';
                              _startDate = null;
                              _endDate = null;
                              _searchQuery = '';
                            });
                            _loadTrips();
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                // Trips list
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _TripAdminCard(
                        trip: trip,
                        canEdit: canEdit,
                        canDelete: canDelete,
                        onRefresh: _handleRefresh,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Trip Admin Card Widget
class _TripAdminCard extends ConsumerWidget {
  final TripListItem trip;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onRefresh;

  const _TripAdminCard({
    required this.trip,
    required this.canEdit,
    required this.canDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

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
              // Header: Title and status badge
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
              const SizedBox(height: 8),

              // Organizer
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    trip.lead.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(trip.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.trending_up,
                    label: trip.level.name,
                    color: _getLevelColor(trip.level.numericLevel),
                  ),
                  _InfoChip(
                    icon: Icons.people,
                    label: '${trip.registeredCount}/${trip.capacity}',
                    color: theme.colorScheme.primary,
                  ),
                  if (trip.meetingPoint != null)
                    _InfoChip(
                      icon: Icons.location_on,
                      label: trip.meetingPoint!.name,
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),
              
              // Action buttons (wrapped to prevent overflow)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Registrants button (always visible)
                    TextButton.icon(
                      onPressed: () => context.push('/admin/trips/${trip.id}/registrants'),
                      icon: const Icon(Icons.people, size: 18),
                      label: Text('Registrants (${trip.registeredCount})'),
                    ),
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => context.push('/trips/${trip.id}/edit'),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    if (canDelete)
                      TextButton.icon(
                        onPressed: () => _showDeleteDialog(context, ref),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int numericLevel) {
    if (numericLevel <= 2) return Colors.green;
    if (numericLevel <= 4) return Colors.blue;
    if (numericLevel <= 6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete "${trip.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _handleDelete(context, ref);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.deleteTrip(trip.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Trip "${trip.title}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to delete trips'
                  : '❌ Failed to delete trip: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'declined':
        color = Colors.red;
        label = 'Declined';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
