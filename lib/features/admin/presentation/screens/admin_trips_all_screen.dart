import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/status_helpers.dart';
import '../../../../core/utils/level_display_helper.dart';
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
      
      // Sort by start_time descending (newest trips first)
      // Backend uses snake_case for field names
      print('🔍 [AdminTripsAll] Fetching trips with ordering: -start_time');
      
      // ✅ FIXED: Determine approval status filter
      // ⚠️ API only accepts single values, not comma-separated
      String? approvalStatusFilter;
      if (_statusFilter == 'pending' || _statusFilter == 'P') {
        approvalStatusFilter = 'P';
      } else if (_statusFilter == 'approved' || _statusFilter == 'A') {
        approvalStatusFilter = 'A';
      } else if (_statusFilter == 'rejected' || _statusFilter == 'R') {
        approvalStatusFilter = 'R';
      } else if (_statusFilter == 'declined' || _statusFilter == 'deleted' || _statusFilter == 'D') {
        approvalStatusFilter = 'D'; // Allow explicit deleted filter
      }
      // Note: When filter is 'all', we fetch all trips and filter deleted client-side
      // Note: 'upcoming' and 'completed' use time-based filters, not status
      
      final response = await repository.getTrips(
        approvalStatus: approvalStatusFilter,
        startTimeAfter: _startDate?.toIso8601String(),
        startTimeBefore: _endDate?.toIso8601String(),
        levelId: _levelFilter,
        ordering: '-start_time', // Newest first by start time (matches API docs example)
        page: 1,
        pageSize: 50, // Show recent 50 trips
      );

      final tripsData = response['results'] as List<dynamic>? ?? [];
      print('📊 [AdminTripsAll] Received ${tripsData.length} trips from API');
      var trips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      // ✅ FIXED: Use status helpers to check backend codes (A, P, R, D) or dynamic values
      
      // ✅ CRITICAL: Exclude deleted trips when filter is 'all'
      if (_statusFilter == 'all') {
        trips = trips.where((t) => !isDeclined(t.approvalStatus)).toList();
        print('📊 [AdminTripsAll] After excluding deleted: ${trips.length} trips');
      } else if (_statusFilter != 'all') {
        // Handle legacy filter values (pending, approved, rejected, deleted) and new backend codes (P, A, R, D)
        if (_statusFilter == 'pending' || _statusFilter == 'P') {
          trips = trips.where((t) => isPending(t.approvalStatus)).toList();
        } else if (_statusFilter == 'approved' || _statusFilter == 'A') {
          trips = trips.where((t) => isApproved(t.approvalStatus)).toList();
        } else if (_statusFilter == 'rejected' || _statusFilter == 'R') {
          trips = trips.where((t) => isRejected(t.approvalStatus)).toList();
        } else if (_statusFilter == 'declined' || _statusFilter == 'deleted' || _statusFilter == 'D') {
          trips = trips.where((t) => isDeclined(t.approvalStatus)).toList(); // Backend 'D' = Deleted
        } else if (_statusFilter == 'upcoming') {
          final now = DateTime.now();
          trips = trips.where((t) => t.startTime.isAfter(now) && isApproved(t.approvalStatus)).toList();
        } else if (_statusFilter == 'completed') {
          final now = DateTime.now();
          trips = trips.where((t) => t.endTime.isBefore(now)).toList();
        } else {
          // Handle any other dynamic status value by direct comparison
          trips = trips.where((t) => t.approvalStatus == _statusFilter).toList();
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
        print('✅ [AdminTripsAll] Loaded ${trips.length} trips (ordered by: -start_time)');
        print('   First trip: ID=${trips.first.id}, Title="${trips.first.title}", Start: ${trips.first.startTime}');
        print('   Last trip: ID=${trips.last.id}, Title="${trips.last.title}", Start: ${trips.last.startTime}');
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
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: trip.approvalStatus),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Metadata Row: Organizer + Date/Time
              Row(
                children: [
                  // Organizer
                  Icon(Icons.person_outline, size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    trip.lead.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Date
                  Icon(Icons.calendar_today, size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(trip.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Time
                  Icon(Icons.access_time, size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(trip.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Info Badges Row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  LevelDisplayHelper.buildCompactBadge(trip.level),
                  _buildTripStatusBadge(trip, colors),
                  _InfoChip(
                    icon: Icons.people,
                    label: '${trip.registeredCount}/${trip.capacity}',
                    color: colors.primary,
                  ),
                  if (trip.meetingPoint != null)
                    _InfoChip(
                      icon: Icons.location_on,
                      label: trip.meetingPoint!.name,
                      color: colors.tertiary,
                    ),
                ],
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    // Registrants
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/admin/trips/${trip.id}/registrants'),
                        icon: const Icon(Icons.people, size: 16),
                        label: Text(
                          'Registrants (${trip.registeredCount})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 6),
                    
                    // Edit
                    if (canEdit)
                      IconButton(
                        onPressed: () => context.push('/trips/${trip.id}/edit'),
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                      ),
                    
                    // Report Button
                    _buildReportButton(context, ref, trip),
                    
                    // More Menu
                    if (canDelete)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: 'More',
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(context, ref);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
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

  /// TODO: TRIP REPORTS FEATURE - UNDER DEVELOPMENT
  /// This method is temporarily disabled until feature development is complete.
  /// Uncomment the code below to re-enable trip report badges in the admin trips list.
  /*
  /// Build trip report badge (if eligible)
  Widget _buildReportBadge(BuildContext context, WidgetRef ref, TripListItem trip, ColorScheme colors) {
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    
    // Check trip completion status (approved + ended)
    final now = DateTime.now();
    final isCompleted = trip.approvalStatus == 'A' && now.isAfter(trip.endTime);
    
    // Check if user has permission to create trip reports
    final canCreateReport = currentUser?.hasPermission('create_trip_report') ?? false;
    
    // Only show badge for completed trips with permission
    if (!isCompleted || !canCreateReport) {
      return const SizedBox.shrink();
    }
    
    // Fetch trip reports for this trip
    final reportsAsync = ref.watch(tripReportsByTripProvider(trip.id));
    
    return reportsAsync.when(
      data: (reports) {
        if (reports.isNotEmpty) {
          // Green badge: Report exists
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Report',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Blue badge: Can create report
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Create Report',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  */
  
  /// Placeholder method while trip reports feature is under development
  Widget _buildReportBadge(BuildContext context, WidgetRef ref, TripListItem trip, ColorScheme colors) {
    return const SizedBox.shrink();
  }

  /// TODO: TRIP REPORTS FEATURE - UNDER DEVELOPMENT
  /// This method is temporarily disabled until feature development is complete.
  /// Uncomment the code below to re-enable trip report action buttons.
  /*
  /// Build clickable report button for action buttons section
  Widget _buildReportButton(BuildContext context, WidgetRef ref, TripListItem trip) {
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    
    // Check trip completion status (approved + ended)
    final now = DateTime.now();
    final isCompleted = trip.approvalStatus == 'A' && now.isAfter(trip.endTime);
    
    // Check if user has permission to create trip reports
    final canCreateReport = currentUser?.hasPermission('create_trip_report') ?? false;
    
    // Only show button for completed trips with permission
    if (!isCompleted || !canCreateReport) {
      return const SizedBox.shrink();
    }
    
    // Fetch trip reports for this trip
    final reportsAsync = ref.watch(tripReportsByTripProvider(trip.id));
    
    return reportsAsync.when(
      data: (reports) {
        if (reports.isNotEmpty) {
          // View Report icon button
          return IconButton(
            onPressed: () => context.push('/admin/trip-reports'),
            icon: const Icon(Icons.description, size: 18),
            tooltip: 'View Report',
            color: Colors.green,
            visualDensity: VisualDensity.compact,
          );
        } else {
          // Create Report icon button - Use Quick Report screen
          return IconButton(
            onPressed: () => context.push('/admin/quick-trip-report/${trip.id}'),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            tooltip: 'Create Report',
            color: Colors.blue,
            visualDensity: VisualDensity.compact,
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  */
  
  /// Placeholder method while trip reports feature is under development
  Widget _buildReportButton(BuildContext context, WidgetRef ref, TripListItem trip) {
    return const SizedBox.shrink();
  }

  /// Build trip status badge (Upcoming/Ongoing/Completed)
  Widget _buildTripStatusBadge(TripListItem trip, ColorScheme colors) {
    final now = DateTime.now();
    String status;
    Color badgeColor;
    IconData icon;

    if (now.isBefore(trip.startTime)) {
      status = 'Upcoming';
      badgeColor = Colors.green;
      icon = Icons.schedule;
    } else if (now.isAfter(trip.endTime)) {
      status = 'Completed';
      badgeColor = Colors.grey;
      icon = Icons.check_circle;
    } else {
      status = 'Ongoing';
      badgeColor = Colors.orange;
      icon = Icons.play_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
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

    // Map status codes to readable labels
    switch (status) {
      case 'P': // Pending
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'A': // Approved
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'R': // Rejected
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'D': // Deleted
      case 'declined':
      case 'deleted':
        color = Colors.grey;
        label = 'Deleted';
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
