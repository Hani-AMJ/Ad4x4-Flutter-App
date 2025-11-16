import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/utils/level_display_helper.dart';

/// Trips Map View Widget
/// 
/// Displays trips on an interactive OpenStreetMap with markers and popups
class TripsMapView extends StatefulWidget {
  final List<TripListItem> trips;
  final VoidCallback? onClose;

  const TripsMapView({
    super.key,
    required this.trips,
    this.onClose,
  });

  @override
  State<TripsMapView> createState() => _TripsMapViewState();
}

class _TripsMapViewState extends State<TripsMapView> {
  final MapController _mapController = MapController();
  TripListItem? _selectedTrip;

  // UAE center coordinates (Abu Dhabi)
  static const LatLng _defaultCenter = LatLng(24.4539, 54.3773);
  static const double _defaultZoom = 10.0;

  @override
  void initState() {
    super.initState();
    // Center map on first trip with coordinates or default to UAE center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnTrips();
    });
  }

  @override
  void didUpdateWidget(TripsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recenter map when trips list changes (e.g., tab switch)
    if (oldWidget.trips != widget.trips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnTrips();
      });
    }
  }

  // Helper to parse latitude from string
  double? _parseLatitude(TripListItem trip) {
    if (trip.meetingPoint?.lat == null) return null;
    return double.tryParse(trip.meetingPoint!.lat!);
  }

  // Helper to parse longitude from string
  double? _parseLongitude(TripListItem trip) {
    if (trip.meetingPoint?.lon == null) return null;
    return double.tryParse(trip.meetingPoint!.lon!);
  }

  void _centerMapOnTrips() {
    if (widget.trips.isEmpty) return;

    // Find trips with valid coordinates
    final tripsWithCoords = widget.trips.where((trip) {
      return _parseLatitude(trip) != null && _parseLongitude(trip) != null;
    }).toList();

    if (tripsWithCoords.isEmpty) {
      // No trips with coordinates, use default center
      _mapController.move(_defaultCenter, _defaultZoom);
      return;
    }

    if (tripsWithCoords.length == 1) {
      // Single trip - center on it
      final trip = tripsWithCoords.first;
      final lat = _parseLatitude(trip)!;
      final lng = _parseLongitude(trip)!;
      _mapController.move(
        LatLng(lat, lng),
        12.0,
      );
      return;
    }

    // Multiple trips - calculate bounds
    double minLat = _parseLatitude(tripsWithCoords.first)!;
    double maxLat = minLat;
    double minLng = _parseLongitude(tripsWithCoords.first)!;
    double maxLng = minLng;

    for (var trip in tripsWithCoords) {
      final lat = _parseLatitude(trip)!;
      final lng = _parseLongitude(trip)!;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    for (var trip in widget.trips) {
      // Skip trips without valid coordinates
      final lat = _parseLatitude(trip);
      final lng = _parseLongitude(trip);
      if (lat == null || lng == null) {
        continue;
      }

      final position = LatLng(lat, lng);

      markers.add(
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTrip = trip;
              });
            },
            child: _TripMarker(
              isSelected: _selectedTrip?.id == trip.id,
              levelNumeric: trip.level.numericLevel,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              // Deselect marker when tapping on map
              setState(() {
                _selectedTrip = null;
              });
            },
          ),
          children: [
            // OpenStreetMap Tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ad4x4.mobile',
              maxZoom: 19,
            ),
            // Trip Markers
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),

        // Exit button (top right)
        if (widget.onClose != null)
          Positioned(
            top: 16,
            right: 16,
            child: _MapButton(
              icon: Icons.close,
              onPressed: widget.onClose!,
              tooltip: 'Exit Map',
            ),
          ),

        // Map controls overlay (top right, below exit button)
        Positioned(
          top: widget.onClose != null ? 72 : 16,
          right: 16,
          child: Column(
            children: [
              // Zoom in
              _MapButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                tooltip: 'Zoom In',
              ),
              const SizedBox(height: 8),
              // Zoom out
              _MapButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                tooltip: 'Zoom Out',
              ),
              const SizedBox(height: 8),
              // Recenter
              _MapButton(
                icon: Icons.my_location,
                onPressed: _centerMapOnTrips,
                tooltip: 'Recenter',
              ),
            ],
          ),
        ),

        // Trip info popup (bottom)
        if (_selectedTrip != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _TripInfoPopup(
              trip: _selectedTrip!,
              onClose: () {
                setState(() {
                  _selectedTrip = null;
                });
              },
              onViewDetails: () {
                context.push('/trips/${_selectedTrip!.id}');
              },
            ),
          ),

        // Trip count badge (top left)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.trips.length} trip${widget.trips.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

/// Trip Marker Widget - Uses level-specific icons
class _TripMarker extends StatelessWidget {
  final bool isSelected;
  final int levelNumeric;

  const _TripMarker({
    required this.isSelected,
    required this.levelNumeric,
  });

  // Get icon and color using LevelDisplayHelper
  ({IconData icon, Color color}) _getLevelIconAndColor() {
    return (
      icon: LevelDisplayHelper.getLevelIcon(levelNumeric),
      color: LevelDisplayHelper.getLevelColor(levelNumeric)
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final levelData = _getLevelIconAndColor();

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? levelData.color : colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : levelData.color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          levelData.icon,
          size: 20,
          color: isSelected ? Colors.white : levelData.color,
        ),
      ),
    );
  }
}

/// Map Control Button
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: colors.primary,
        tooltip: tooltip,
      ),
    );
  }
}

/// Trip Info Popup
class _TripInfoPopup extends StatelessWidget {
  final TripListItem trip;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _TripInfoPopup({
    required this.trip,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Trip details
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, MMM d, y').format(trip.startTime),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.location ?? 'No location',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                trip.level.displayName ?? trip.level.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.people,
                size: 16,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${trip.registeredCount}/${trip.capacity}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // View Details button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
