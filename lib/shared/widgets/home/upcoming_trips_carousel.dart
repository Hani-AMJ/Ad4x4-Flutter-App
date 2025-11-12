import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/repositories/main_api_repository.dart';

/// Upcoming Trips Carousel Widget
/// 
/// Displays a horizontal scrolling carousel of upcoming approved trips
class UpcomingTripsCarousel extends StatefulWidget {
  const UpcomingTripsCarousel({super.key});

  @override
  State<UpcomingTripsCarousel> createState() => _UpcomingTripsCarouselState();
}

class _UpcomingTripsCarouselState extends State<UpcomingTripsCarousel> {
  final _repository = MainApiRepository();
  List<TripListItem> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingTrips();
  }

  Future<void> _loadUpcomingTrips() async {
    try {
      // Get all upcoming trips (filtering by date)
      final now = DateTime.now();
      final startTimeAfter = now.toIso8601String();
      
      final response = await _repository.getTrips(
        startTimeAfter: startTimeAfter,
        page: 1,
        pageSize: 5,
        ordering: 'startTime', // Earliest first
      );

      final List<TripListItem> trips = [];
      final data = response['results'] ?? response['data'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            final trip = TripListItem.fromJson(item as Map<String, dynamic>);
            // Only include future trips
            if (trip.startTime.isAfter(DateTime.now())) {
              trips.add(trip);
            }
          } catch (e) {
            print('⚠️ [Carousel] Error parsing trip: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [Carousel] Error: $e');
      if (mounted) {
        setState(() {
          _trips = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trips.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return _TripCard(trip: trip);
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripListItem trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/trips/${trip.id}'),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.3),
                      colors.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('EEE, MMM d').format(trip.startTime),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    if (trip.location != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trip.location!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Participants
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.participants}/${trip.maxParticipants}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
}
