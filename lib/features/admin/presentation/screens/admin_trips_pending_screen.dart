import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/status_helpers.dart';
import '../widgets/trip_approval_card.dart';

/// Admin Trip Approval Queue Screen
/// 
/// Displays pending trips that require approval/decline action.
/// Only visible to users with 'can_approve_trips' permission.
/// 
/// Features:
/// - List of pending trips (approval_status = 'pending')
/// - Approve/Decline actions with confirmation
/// - Auto-refresh after actions
/// - Pull-to-refresh support
/// - Empty state when no pending trips
class AdminTripsPendingScreen extends ConsumerStatefulWidget {
  const AdminTripsPendingScreen({super.key});

  @override
  ConsumerState<AdminTripsPendingScreen> createState() =>
      _AdminTripsPendingScreenState();
}

class _AdminTripsPendingScreenState
    extends ConsumerState<AdminTripsPendingScreen> {
  
  @override
  void initState() {
    super.initState();
    // Auto-load pending trips on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingTrips();
    });
  }

  /// Load pending trips from API
  Future<void> _loadPendingTrips() async {
    setState(() {
      _pendingTripsAsync = _fetchPendingTrips();
    });
  }

  /// Fetch pending trips using approval status filter
  /// 
  /// NOTE: Backend doesn't support approvalStatus filter yet.
  /// Workaround: Fetch all trips and filter client-side by approval_status = 'pending'
  Future<List<TripListItem>> _fetchPendingTrips() async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Fetch recent trips (backend doesn't support approvalStatus filter yet)
      final response = await repository.getTrips(
        ordering: '-created', // Newest first
        page: 1,
        pageSize: 100, // Load more trips to find pending ones
      );

      final tripsData = response['results'] as List<dynamic>? ?? [];
      
      // Parse all trips
      final allTrips = tripsData
          .map((json) => TripListItem.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter for pending trips only (client-side filtering)
      // ✅ FIXED: Use status helper to check backend codes (P = pending)
      final pendingTrips = allTrips
          .where((trip) => isPending(trip.approvalStatus))
          .toList();

      print('✅ [AdminPending] Loaded ${pendingTrips.length} pending trips (from ${allTrips.length} total)');
      return pendingTrips;
    } catch (e, stackTrace) {
      print('❌ [AdminPending] Error loading pending trips: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  late Future<List<TripListItem>> _pendingTripsAsync = _fetchPendingTrips();

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    await _loadPendingTrips();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permission - user must have approve_trip permission
    final canApprove = user?.hasPermission('approve_trip') ?? false;
    
    if (!canApprove) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Trip Approval Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to approve trips.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Back to Admin Panel'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Approval Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<TripListItem>>(
        future: _pendingTripsAsync,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading pending trips...'),
                ],
              ),
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
                    'Error loading pending trips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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

          final pendingTrips = snapshot.data ?? [];

          // Empty state
          if (pendingTrips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Trips',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All trip requests have been reviewed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Trips list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingTrips.length,
              itemBuilder: (context, index) {
                final trip = pendingTrips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TripApprovalCard(
                    trip: trip,
                    onApproved: _handleRefresh,
                    onDeclined: _handleRefresh,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
