import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/status_helpers.dart';
import '../../../../core/utils/level_display_helper.dart';
import 'package:go_router/go_router.dart';

/// Admin Deleted Trips Screen
/// 
/// Displays all trips with approval status 'D' (Deleted).
/// Sorted by newest start date first.
/// Features:
/// - View deleted trips only
/// - Sort by start date (newest first)
/// - Read-only view (no edit/delete actions)
/// - Navigate to trip details
class AdminTripsDeletedScreen extends ConsumerStatefulWidget {
  const AdminTripsDeletedScreen({super.key});

  @override
  ConsumerState<AdminTripsDeletedScreen> createState() => _AdminTripsDeletedScreenState();
}

class _AdminTripsDeletedScreenState extends ConsumerState<AdminTripsDeletedScreen> {
  late Future<List<TripListItem>> _tripsAsync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeletedTrips();
    });
  }

  /// Load deleted trips from API
  Future<void> _loadDeletedTrips() async {
    setState(() {
      _tripsAsync = _fetchDeletedTrips();
    });
  }

  /// Fetch deleted trips from API
  Future<List<TripListItem>> _fetchDeletedTrips() async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      print('🗑️ [AdminTripsDeleted] Fetching deleted trips...');
      final response = await repository.getTrips(
        approvalStatus: 'D', // ✅ Only deleted trips
        ordering: '-start_time', // Newest start date first
        page: 1,
        pageSize: 100, // Show up to 100 deleted trips
      );

      final tripsData = response['results'] as List<dynamic>? ?? [];
      print('🗑️ [AdminTripsDeleted] Received ${tripsData.length} deleted trips from API');
      
      final trips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();

      return trips;
    } catch (e, stack) {
      print('❌ [AdminTripsDeleted] Error fetching deleted trips: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗑️ Deleted Trips'),
        backgroundColor: Colors.grey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDeletedTrips,
          ),
        ],
      ),
      body: FutureBuilder<List<TripListItem>>(
        future: _tripsAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading deleted trips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDeletedTrips,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Deleted Trips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All trips are active or archived',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with trip count
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Showing ${trips.length} deleted trip${trips.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Sorted by start date (newest first)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Trips list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _DeletedTripCard(
                      trip: trip,
                      onTap: () {
                        context.push('/admin/trips/${trip.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget: Deleted Trip Card
class _DeletedTripCard extends StatelessWidget {
  final TripListItem trip;
  final VoidCallback onTap;

  const _DeletedTripCard({
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardTheme.color, // ✅ Use theme card color (no white override)
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Deleted badge in single row with proper spacing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DELETED badge first (top-left)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'DELETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title (takes remaining space)
                  Expanded(
                    child: Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Compact info chips - single row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Date only (shorter)
                  _CompactChip(
                    icon: Icons.calendar_today,
                    label: dateFormatter.format(trip.startTime),
                    color: colors.primary,
                  ),
                  
                  // Level
                  _CompactChip(
                    icon: Icons.terrain,
                    label: trip.level.displayName ?? trip.level.name,
                    color: LevelDisplayHelper.getLevelColor(trip.level.id),
                  ),
                  
                  // Participants only (no "By organizer")
                  _CompactChip(
                    icon: Icons.group,
                    label: '${trip.registeredCount}/${trip.capacity}',
                    color: colors.tertiary,
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

/// Widget: Compact Info Chip (smaller for deleted trips)
class _CompactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
