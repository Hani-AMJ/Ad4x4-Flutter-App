import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/error/error_state_widget.dart';

/// Filtered Trips Screen
/// 
/// Displays trips filtered by specific criteria:
/// - Completed trips (checked-in)
/// - Upcoming trips (registered, not checked-in)
/// - Level-specific trips (filtered by difficulty level)
class FilteredTripsScreen extends ConsumerStatefulWidget {
  final int memberId;
  final String filterType; // 'completed', 'upcoming', 'level'
  final int? levelNumeric; // 10, 100, 200, 300 for level filtering
  final String title; // Screen title

  const FilteredTripsScreen({
    super.key,
    required this.memberId,
    required this.filterType,
    this.levelNumeric,
    required this.title,
  });

  @override
  ConsumerState<FilteredTripsScreen> createState() => _FilteredTripsScreenState();
}

class _FilteredTripsScreenState extends ConsumerState<FilteredTripsScreen> {
  List<dynamic> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    setState(() {
      if (loadMore) {
        _currentPage++;
      } else {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _trips = [];
      }
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Determine checkedIn parameter based on filter type
      bool? checkedInFilter;
      if (widget.filterType == 'completed') {
        checkedInFilter = true;
      } else if (widget.filterType == 'upcoming') {
        checkedInFilter = false;
      } else if (widget.filterType == 'level') {
        checkedInFilter = true; // Level filtering shows completed trips
      }

      // Fetch trip history
      final response = await repository.getMemberTripHistory(
        memberId: widget.memberId,
        checkedIn: checkedInFilter,
        page: _currentPage,
        pageSize: 20,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? 0;

      // Client-side level filtering if needed
      List<dynamic> filteredTrips = results;
      if (widget.filterType == 'level' && widget.levelNumeric != null) {
        // Debug: Log all trips and their levels BEFORE filtering
        print('🔍 [DEBUG] Filtering ${results.length} trips for levelNumeric=${widget.levelNumeric}');
        
        for (int i = 0; i < results.length && i < 5; i++) {
          final tripJson = results[i];
          final levelData = tripJson['level'];
          final tripTitle = tripJson['title'] ?? 'Unknown';
          print('   Trip $i: "$tripTitle" - level: $levelData (type: ${levelData.runtimeType})');
        }
        
        filteredTrips = results.where((tripJson) {
          final levelData = tripJson['level'];
          if (levelData == null) return false;
          
          // Handle both String and Map formats
          int numericLevel = 0;
          if (levelData is Map<String, dynamic>) {
            numericLevel = levelData['numeric_level'] as int? ?? 
                          levelData['numericLevel'] as int? ?? 
                          0;
          } else if (levelData is String) {
            // Map level name to numeric value
            switch (levelData) {
              case 'Club Event':
              case 'CLUB EVENT':
                numericLevel = 5;
                break;
              case 'Newbie':
              case 'NEWBIE':
              case 'ANIT':
                numericLevel = 10;
                break;
              case 'Intermediate':
              case 'INTERMEDIATE':
                numericLevel = 100;
                break;
              case 'Advanced':
              case 'ADVANCED':
              case 'Advance':  // Backend variation without 'd'
              case 'ADVANCE':
                numericLevel = 200;
                break;
              case 'Expert':
              case 'EXPERT':
                numericLevel = 300;
                break;
            }
          }
          
          final matches = numericLevel == widget.levelNumeric;
          if (!matches && levelData != null) {
            // Debug: Log mismatches for first few trips
            print('   ❌ Mismatch: level=$levelData, numericLevel=$numericLevel, expected=${widget.levelNumeric}');
          }
          
          return matches;
        }).toList();
        
        print('   ✅ After filtering: ${filteredTrips.length} trips matched');
      }

      print('🔍 [FilteredTrips] Loaded ${filteredTrips.length} trips (page $_currentPage)');
      print('   Filter type: ${widget.filterType}');
      print('   Level numeric: ${widget.levelNumeric}');
      print('   Total count: $count');

      setState(() {
        if (loadMore) {
          _trips.addAll(filteredTrips);
        } else {
          _trips = filteredTrips;
        }
        _totalCount = count;
        
        // Determine if there are more trips to load
        // If we got fewer results than pageSize, we've reached the end
        // This handles both normal pagination and client-side filtering
        _hasMore = filteredTrips.length >= 20;
        
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [FilteredTrips] Error loading trips: $e');
      setState(() {
        _errorMessage = 'Failed to load trips: $e';
        _isLoading = false;
      });
    }
  }

  String _getLevelName(int numericLevel) {
    switch (numericLevel) {
      case 5:
        return 'Club Event';
      case 10:
        return 'Newbie';
      case 100:
        return 'Intermediate';
      case 200:
        return 'Advanced';
      case 300:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  Color _getLevelColor(int numericLevel) {
    switch (numericLevel) {
      case 5:
        return Colors.purple;
      case 10:
        return Colors.green;
      case 100:
        return Colors.blue;
      case 200:
        return Colors.orange;
      case 300:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading)
              Text(
                '${_trips.length} trip${_trips.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingStateWidget(message: 'Loading trips...')
          : _errorMessage != null
              ? ErrorStateWidget.network(
                  onRetry: _loadTrips,
                  message: _errorMessage!,
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: colors.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No trips found',
                            style: TextStyle(
                              fontSize: 18,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTrips,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _trips.length) {
                            // Load more button
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _loadTrips(loadMore: true),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Load More'),
                                ),
                              ),
                            );
                          }

                          final tripJson = _trips[index] as Map<String, dynamic>;
                          return _buildTripCard(tripJson, colors);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> tripJson, ColorScheme colors) {
    final id = tripJson['id'] as int? ?? 0;
    final title = tripJson['title'] as String? ?? 'Untitled Trip';
    final startTimeStr = tripJson['start_time'] as String? ?? 
                         tripJson['startTime'] as String? ?? 
                         DateTime.now().toIso8601String();
    final startTime = DateTime.parse(startTimeStr);
    final checkedIn = tripJson['checked_in'] as bool? ?? 
                      tripJson['checkedIn'] as bool? ?? 
                      false;
    
    // Handle level data - can be String or Map
    final levelData = tripJson['level'];
    String levelName = 'Unknown';
    int levelNumeric = 0;
    
    if (levelData is Map<String, dynamic>) {
      levelName = levelData['name'] as String? ?? 'Unknown';
      levelNumeric = levelData['numeric_level'] as int? ?? 
                     levelData['numericLevel'] as int? ?? 
                     0;
    } else if (levelData is String) {
      levelName = levelData;
      // Map level name to numeric value
      switch (levelData) {
        case 'Club Event':
        case 'CLUB EVENT':
          levelNumeric = 5;
          break;
        case 'Newbie':
        case 'NEWBIE':
        case 'ANIT':
          levelNumeric = 10;
          break;
        case 'Intermediate':
        case 'INTERMEDIATE':
          levelNumeric = 100;
          break;
        case 'Advanced':
        case 'ADVANCED':
        case 'Advance':  // Backend variation without 'd'
        case 'ADVANCE':
          levelNumeric = 200;
          break;
        case 'Expert':
        case 'EXPERT':
          levelNumeric = 300;
          break;
      }
    }

    final levelColor = _getLevelColor(levelNumeric);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/trips/$id'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Level Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      levelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date and Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              // Checked-in Status
              if (checkedIn) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Checked In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
