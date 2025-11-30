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

      // For level filtering, we need to fetch ALL pages first, then filter
      // This is because client-side filtering only sees the current page
      if (widget.filterType == 'level' && widget.levelNumeric != null && !loadMore) {
        print('📥 [LevelFilter] Fetching ALL trips before filtering by levelNumeric=${widget.levelNumeric}');
        
        List<dynamic> allTrips = [];
        int currentPage = 1;
        int totalCount = 0;
        bool hasMorePages = true;
        
        // Fetch all pages
        while (hasMorePages) {
          final response = await repository.getMemberTripHistory(
            memberId: widget.memberId,
            checkedIn: checkedInFilter,
            page: currentPage,
            pageSize: 20,
          );
          
          final results = response['results'] as List<dynamic>? ?? [];
          final count = response['count'] as int? ?? 0;
          totalCount = count;
          
          allTrips.addAll(results);
          
          print('   📄 Fetched page $currentPage: ${results.length} trips (${allTrips.length}/$totalCount total)');
          
          // Check if there are more pages
          hasMorePages = results.length >= 20 && allTrips.length < totalCount;
          currentPage++;
        }
        
        print('   ✅ Fetched all ${allTrips.length} trips across ${currentPage - 1} pages');
        
        // Now filter all trips by level
        print('🔍 [LevelFilter] Filtering ${allTrips.length} trips for levelNumeric=${widget.levelNumeric}');
        
        final filteredTrips = allTrips.where((tripJson) {
          final levelData = tripJson['level'];
          if (levelData == null) {
            return false;
          }
          
          if (levelData is! Map<String, dynamic>) {
            return false;
          }
          
          final numericLevel = levelData['numericLevel'] as int? ?? 0;
          return numericLevel == widget.levelNumeric;
        }).toList();
        
        print('   📊 After filtering: ${filteredTrips.length} trips matched (${((filteredTrips.length / allTrips.length) * 100).toStringAsFixed(1)}%)');
        
        setState(() {
          _trips = filteredTrips;
          _totalCount = filteredTrips.length;
          _hasMore = false; // All trips loaded and filtered
          _isLoading = false;
        });
        
        return;
      }

      // For non-level filters (completed, upcoming), use normal pagination
      final response = await repository.getMemberTripHistory(
        memberId: widget.memberId,
        checkedIn: checkedInFilter,
        page: _currentPage,
        pageSize: 20,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final count = response['count'] as int? ?? 0;

      print('🔍 [FilteredTrips] Loaded ${results.length} trips (page $_currentPage)');
      print('   Filter type: ${widget.filterType}');
      print('   Total count: $count');

      setState(() {
        if (loadMore) {
          _trips.addAll(results);
        } else {
          _trips = results;
        }
        _totalCount = count;
        
        // Determine if there are more trips to load
        _hasMore = results.length >= 20 && _trips.length < count;
        
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
            Row(
              children: [
                if (widget.filterType == 'level' && widget.levelNumeric != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getLevelColor(widget.levelNumeric!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terrain,
                      size: 18,
                      color: _getLevelColor(widget.levelNumeric!),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isLoading)
              Row(
                children: [
                  Text(
                    '${_trips.length} trip${_trips.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  if (_trips.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_trips.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: widget.filterType == 'level' && widget.levelNumeric != null
                                  ? _getLevelColor(widget.levelNumeric!).withValues(alpha: 0.1)
                                  : colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.filterType == 'level'
                                  ? Icons.terrain
                                  : Icons.event_busy,
                              size: 48,
                              color: widget.filterType == 'level' && widget.levelNumeric != null
                                  ? _getLevelColor(widget.levelNumeric!)
                                  : colors.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.filterType == 'level' && widget.levelNumeric != null
                                ? 'No ${_getLevelName(widget.levelNumeric!)} trips yet'
                                : 'No trips found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.filterType == 'level'
                                ? 'Try checking other difficulty levels'
                                : 'Check back later for updates',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurface.withValues(alpha: 0.5),
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
    
    // Backend always provides level object with all required fields
    final levelData = tripJson['level'] as Map<String, dynamic>?;
    final levelName = levelData?['name'] as String? ?? 'Unknown';
    final levelNumeric = levelData?['numericLevel'] as int? ?? 0;

    final levelColor = _getLevelColor(levelNumeric);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shadowColor: levelColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: levelColor,
              width: 4,
            ),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/trips/$id'),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      levelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Date and Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.calendar_today, size: 14, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(startTime),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.access_time, size: 14, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(startTime),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              // Checked-in Status
              if (checkedIn) ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checked In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}
