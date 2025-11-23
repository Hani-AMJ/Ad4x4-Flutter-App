import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/trip_filters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/error/error_state_widget.dart';
import '../providers/trips_provider.dart';
import '../widgets/trips_map_view.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen to tab changes to update map view
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Trigger rebuild when tab changes
        setState(() {});
      }
    });
    
    // Load trips on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripsProvider.notifier).loadTrips();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    await ref.read(tripsProvider.notifier).refresh();
  }

  void _handleFiltersChanged(TripFilters newFilters) {
    ref.read(tripsProvider.notifier).updateFilters(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Watch trips state
    final tripsState = ref.watch(tripsProvider);
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    final currentUserId = currentUser?.id ?? 0;
    
    // Check if user can create trips
    final canCreateTrip = currentUser?.hasPermission('create_trip') ?? false;
    
    // Get filtered trips for each tab
    final allTrips = tripsState.allTrips;
    final upcomingTrips = tripsState.upcomingTrips;
    final myTrips = tripsState.getMyTrips(currentUserId);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Trips',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Create Trip button (only show if user has permission)
          if (canCreateTrip)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => context.push('/trips/create'),
                icon: const Icon(Icons.add_circle),
                iconSize: 32,
                color: colors.primary,
                tooltip: 'Create Trip',
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100), // Adjust based on filters bar height
          child: Column(
            children: [
              // Filters Bar
              TripFiltersBar(
                filters: tripsState.filters,
                onFiltersChanged: _handleFiltersChanged,
              ),
              // Tabs with counts
              TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Upcoming'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${upcomingTrips.length}',  // Count from filtered loaded trips
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('My Trips'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${myTrips.length}',  // Count from filtered loaded trips
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: tripsState.isLoading
                ? const LoadingStateWidget(message: 'Loading trips...')
                : tripsState.errorMessage != null
                    ? ErrorStateWidget.network(
                        onRetry: _loadTrips,
                        message: tripsState.errorMessage!,
                      )
                    : tripsState.filters.view == TripViewMode.map
                        ? _buildMapView(allTrips, upcomingTrips, myTrips)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTripsList(upcomingTrips, tripsState.filters, showLoadMore: false, showJoinedBadge: false),
                              _buildTripsList(myTrips, tripsState.filters, showLoadMore: false, showJoinedBadge: true),
                            ],
                          ),
          ),
        ],
      ),
      // Removed floatingActionButton - now in app bar
    );
  }

  Widget _buildTripsList(List<TripListItem> trips, TripFilters filters, {bool showLoadMore = false, bool showJoinedBadge = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tripsState = ref.watch(tripsProvider);
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    final canCreateTrip = currentUser?.hasPermission('create_trip') ?? false;

    // ✅ NEW: Filter trips by eligibility if showEligibleOnly is enabled
    List<TripListItem> displayTrips = trips;
    if (filters.showEligibleOnly && currentUser != null) {
      final userLevel = currentUser.level?.numericLevel ?? 0;
      displayTrips = trips.where((trip) {
        final requiredLevel = trip.level.numericLevel ?? 0;
        final isEligible = userLevel >= requiredLevel;
        final isAlreadyJoined = trip.isRegistered || trip.lead.id == currentUser.id;
        // Show trip if user is eligible OR already registered
        return isEligible || isAlreadyJoined;
      }).toList();
    }

    if (displayTrips.isEmpty && !tripsState.isLoading) {
      return EmptyStateWidget(
        icon: Icons.explore_off,
        title: 'No Trips Found',
        message: filters.isDefault
            ? 'There are no trips available at the moment.'
            : 'No trips match your filters. Try adjusting them.',
        actionButtonText: canCreateTrip ? 'Create Trip' : 'Request Trip',
        onAction: () => canCreateTrip 
            ? context.push('/trips/create')
            : context.push('/trips/requests'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayTrips.length + (showLoadMore && tripsState.hasMore ? 1 : 0), // +1 for Load More button only in All Trips tab
        itemBuilder: (context, index) {
          // Load More button at the end (only for All Trips tab)
          if (showLoadMore && index == displayTrips.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: tripsState.isLoadingMore
                    ? Column(
                        children: [
                          CircularProgressIndicator(color: colors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Loading more trips...',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          ref.read(tripsProvider.notifier).loadMoreTrips();
                        },
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          'Load More (${tripsState.totalCount - tripsState.trips.length} remaining)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
              ),
            );
          }

          final trip = displayTrips[index];
          // Use trip.isRegistered and trip.isWaitlisted fields from API (backend provides these)
          // Fallback: Check if user is the trip lead
          final authState = ref.watch(authProviderV2);
          final currentUserId = authState.user?.id ?? 0;
          final currentUserObject = authState.user;
          final isJoined = trip.isRegistered || trip.lead.id == currentUserId;
          
          // ✅ Check trip completion status (approved + ended)
          final now = DateTime.now();
          final isCompleted = trip.approvalStatus == 'A' && now.isAfter(trip.endTime);
          
          // ✅ Check if user has permission to create trip reports
          final canCreateReport = currentUserObject?.hasPermission('create_trip_report') ?? false;
          
          // ✅ For Phase 4, we'll show the badge optimistically without fetching
          // The badge indicates potential report availability, not actual data
          // Actual report data is fetched when user opens trip details
          final showReportBadge = isCompleted && canCreateReport;
          
          // ✅ NEW: Check user eligibility based on level
          final userLevel = currentUserObject?.level?.numericLevel ?? 0;
          final requiredLevel = trip.level.numericLevel ?? 0;
          final isEligible = userLevel >= requiredLevel;
          final isLocked = !isEligible && !isJoined; // Show lock badge if not eligible and not already registered
          
          // ✅ NEW: Check if current user is the trip lead
          final isLead = trip.lead.id == currentUserId;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TripCard(
              title: trip.title,
              date: DateFormat('EEE, MMM d, y').format(trip.startTime),
              location: trip.location,
              difficulty: trip.level.name,
              levelNumeric: trip.level.numericLevel, // ✅ Pass numeric level for icon/color mapping
              participants: trip.registeredCount,
              maxParticipants: trip.capacity,
              imageUrl: trip.imageUrl,
              isJoined: isJoined,
              isWaitlisted: trip.isWaitlisted,
              isCompleted: isCompleted, // ✅ NEW: Trip completion status
              hasReport: false, // ✅ Phase 4: Optimistic - assume no report, actual check in detail view
              canCreateReport: showReportBadge, // ✅ NEW: Show "Create Report" badge for eligible trips
              isEligible: isEligible, // ✅ NEW: User eligibility status
              isLocked: isLocked, // ✅ NEW: Show lock badge for ineligible trips
              isLead: isLead, // ✅ NEW: User is the trip lead
              onTap: () => context.push('/trips/${trip.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(
    List<TripListItem> allTrips,
    List<TripListItem> upcomingTrips,
    List<TripListItem> myTrips,
  ) {
    // Get all trips based on current tab
    List<TripListItem> displayTrips;
    switch (_tabController.index) {
      case 0:
        displayTrips = upcomingTrips;
        break;
      case 1:
        displayTrips = myTrips;
        break;
      default:
        displayTrips = upcomingTrips;
    }

    // Use the new TripsMapView widget with exit button
    return TripsMapView(
      trips: displayTrips,
      onClose: () {
        // Switch back to list view
        ref.read(tripsProvider.notifier).updateFilters(
          ref.read(tripsProvider).filters.copyWith(view: TripViewMode.list),
        );
      },
    );
  }
}
