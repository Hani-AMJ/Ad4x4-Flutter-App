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
    _tabController = TabController(length: 3, vsync: this);
    
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
    final currentUserId = authState.user?.id ?? 0;
    
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
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Past Trips'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tripsState.totalCount}',  // Show total count from API
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
                              _buildTripsList(allTrips, tripsState.filters, showLoadMore: true, showJoinedBadge: false),
                            ],
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/create'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
      ),
    );
  }

  Widget _buildTripsList(List<TripListItem> trips, TripFilters filters, {bool showLoadMore = false, bool showJoinedBadge = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tripsState = ref.watch(tripsProvider);

    if (trips.isEmpty && !tripsState.isLoading) {
      return EmptyStateWidget(
        icon: Icons.explore_off,
        title: 'No Trips Found',
        message: filters.isDefault
            ? 'There are no trips available at the moment.'
            : 'No trips match your filters. Try adjusting them.',
        actionButtonText: 'Create Trip',
        onAction: () => context.push('/trips/create'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length + (showLoadMore && tripsState.hasMore ? 1 : 0), // +1 for Load More button only in All Trips tab
        itemBuilder: (context, index) {
          // Load More button at the end (only for All Trips tab)
          if (showLoadMore && index == trips.length) {
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

          final trip = trips[index];
          // Use trip.isRegistered field from API (backend provides this)
          // Fallback: Check if user is the trip lead
          final authState = ref.watch(authProviderV2);
          final currentUserId = authState.user?.id ?? 0;
          final isJoined = trip.isRegistered || trip.lead.id == currentUserId;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TripCard(
              title: trip.title,
              date: DateFormat('EEE, MMM d, y').format(trip.startTime),
              location: trip.location,
              difficulty: trip.level.name,
              participants: trip.registeredCount,
              maxParticipants: trip.capacity,
              imageUrl: trip.imageUrl,
              isJoined: isJoined,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Get all trips based on current tab
    List<TripListItem> displayTrips;
    switch (_tabController.index) {
      case 0:
        displayTrips = upcomingTrips;
        break;
      case 1:
        displayTrips = myTrips;
        break;
      case 2:
        displayTrips = allTrips;
        break;
      default:
        displayTrips = upcomingTrips;
    }

    return Stack(
      children: [
        // Map placeholder
        Container(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 80,
                  color: colors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Interactive map with ${displayTrips.length} trip${displayTrips.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction,
                        color: colors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Map Integration Coming Soon',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll show trip meeting points on an interactive map with clustering and custom markers.',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Trip list overlay at bottom
        if (displayTrips.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Trips list
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayTrips.length,
                      itemBuilder: (context, index) {
                        final trip = displayTrips[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          child: TripCard(
                            title: trip.title,
                            date: DateFormat('MMM d').format(trip.startTime),
                            location: trip.location,
                            difficulty: trip.level.name,
                            participants: trip.registeredCount,
                            maxParticipants: trip.capacity,
                            imageUrl: trip.imageUrl,
                            isJoined: trip.isRegistered,
                            onTap: () => context.push('/trips/${trip.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
