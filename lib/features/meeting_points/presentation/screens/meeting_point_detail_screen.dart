import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/meeting_point_model.dart';

/// Meeting Point Detail Screen - Shows detailed view with interactive map
class MeetingPointDetailScreen extends StatefulWidget {
  final MeetingPoint meetingPoint;

  const MeetingPointDetailScreen({
    super.key,
    required this.meetingPoint,
  });

  @override
  State<MeetingPointDetailScreen> createState() => _MeetingPointDetailScreenState();
}

class _MeetingPointDetailScreenState extends State<MeetingPointDetailScreen> {
  late MapController _mapController;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Parse string coordinates to double for map display
  double _parseCoordinate(String? coord, double defaultValue) {
    if (coord == null) return defaultValue;
    return double.tryParse(coord) ?? defaultValue;
  }

  // Get formatted coordinates display
  String _formatCoordinates(double lat, double lon) {
    final latDirection = lat >= 0 ? 'N' : 'S';
    final lonDirection = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDirection, ${lon.abs().toStringAsFixed(4)}° $lonDirection';
  }

  // Get area color
  Color _getAreaColor(String? area) {
    switch (area) {
      case 'DXB':
        return const Color(0xFF2196F3); // Blue
      case 'NOR':
        return const Color(0xFF4CAF50); // Green
      case 'AUH':
        return const Color(0xFFFF9800); // Orange
      case 'AAN':
        return const Color(0xFF9C27B0); // Purple
      case 'LIW':
        return const Color(0xFFF44336); // Red
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // Get full area name
  String _getAreaName(String? area) {
    switch (area) {
      case 'DXB':
        return 'Dubai';
      case 'NOR':
        return 'Northern Emirates';
      case 'AUH':
        return 'Abu Dhabi';
      case 'AAN':
        return 'Al Ain';
      case 'LIW':
        return 'Liwa';
      default:
        return area ?? 'Unknown';
    }
  }

  // Launch Google Maps
  Future<void> _launchGoogleMaps() async {
    final lat = _parseCoordinate(widget.meetingPoint.lat, 0.0);
    final lon = _parseCoordinate(widget.meetingPoint.lon, 0.0);
    
    if (lat == 0.0 && lon == 0.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates not available')),
        );
      }
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Google Maps: $e')),
        );
      }
    }
  }

  // Launch Waze
  Future<void> _launchWaze() async {
    final lat = _parseCoordinate(widget.meetingPoint.lat, 0.0);
    final lon = _parseCoordinate(widget.meetingPoint.lon, 0.0);
    
    if (lat == 0.0 && lon == 0.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates not available')),
        );
      }
      return;
    }

    final url = Uri.parse('https://waze.com/ul?ll=$lat,$lon&navigate=yes');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Waze')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Waze: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Parse coordinates
    final latitude = _parseCoordinate(widget.meetingPoint.lat, 25.2048); // UAE default
    final longitude = _parseCoordinate(widget.meetingPoint.lon, 55.2708);
    final hasValidCoordinates = widget.meetingPoint.lat != null && 
                                  widget.meetingPoint.lon != null &&
                                  latitude != 0.0 && 
                                  longitude != 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingPoint.name),
        actions: [
          if (widget.meetingPoint.link != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final url = Uri.parse(widget.meetingPoint.link!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              tooltip: 'Open in Browser',
            ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Map (70% of screen)
          Expanded(
            flex: 7,
            child: hasValidCoordinates
                ? Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(latitude, longitude),
                          initialZoom: _currentZoom,
                          minZoom: 5.0,
                          maxZoom: 18.0,
                          onPositionChanged: (position, hasGesture) {
                            setState(() {
                              _currentZoom = position.zoom ?? _currentZoom;
                            });
                          },
                        ),
                        children: [
                          // OpenStreetMap Tile Layer
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ad4x4.app',
                            maxZoom: 19,
                          ),
                          
                          // Marker Layer
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitude, longitude),
                                width: 60,
                                height: 60,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      color: _getAreaColor(widget.meetingPoint.area),
                                      size: 48,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Zoom Controls
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              onPressed: () {
                                final newZoom = (_currentZoom + 1).clamp(5.0, 18.0);
                                _mapController.move(
                                  _mapController.camera.center,
                                  newZoom,
                                );
                              },
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              onPressed: () {
                                final newZoom = (_currentZoom - 1).clamp(5.0, 18.0);
                                _mapController.move(
                                  _mapController.camera.center,
                                  newZoom,
                                );
                              },
                              child: const Icon(Icons.remove),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'center',
                              onPressed: () {
                                _mapController.move(
                                  LatLng(latitude, longitude),
                                  15.0,
                                );
                              },
                              child: const Icon(Icons.my_location),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Location Not Available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Details Card (30% of screen)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.meetingPoint.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Area Badge
                    if (widget.meetingPoint.area != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getAreaColor(widget.meetingPoint.area).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.meetingPoint.area} - ${_getAreaName(widget.meetingPoint.area)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getAreaColor(widget.meetingPoint.area),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),

                    // Coordinates
                    if (hasValidCoordinates) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.pin_drop,
                            size: 20,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatCoordinates(latitude, longitude),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Navigation Buttons
                    if (hasValidCoordinates)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Google Maps'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _launchGoogleMaps,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.navigation),
                              label: const Text('Waze'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: const Color(0xFF33CCFF),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _launchWaze,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
