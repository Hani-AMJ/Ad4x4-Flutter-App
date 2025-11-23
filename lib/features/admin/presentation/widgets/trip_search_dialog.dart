import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';

/// Reusable Trip Search Dialog
/// 
/// Searchable dialog for selecting a trip
/// Returns selected trip data: {id, title, startTime, leadName, levelName}
class TripSearchDialog extends ConsumerStatefulWidget {
  final String title;
  final String searchHint;

  const TripSearchDialog({
    super.key,
    this.title = 'Select Trip',
    this.searchHint = 'Search by trip title...',
  });

  @override
  ConsumerState<TripSearchDialog> createState() => _TripSearchDialogState();
}

class _TripSearchDialogState extends ConsumerState<TripSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreTrips();
      }
    }
  }

  /// Search trips by title, description, or location
  Future<void> _searchTrips(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _trips = [];
        _hasSearched = false;
        _hasMore = true;
        _currentPage = 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _trips = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // ⚠️ Backend does NOT support 'search' parameter for trips
      // ✅ Order by start time (newest first) for better UX
      // ✅ Get ALL trips initially, then filter client-side by title
      // ⚠️ CRITICAL: API uses snake_case 'start_time' NOT camelCase 'startTime'
      final response = await repository.getTrips(
        ordering: '-start_time',  // Backend expects snake_case!
        page: 1,
        pageSize: 100, // Get more results since we're filtering client-side
      );

      final results = response['results'] as List<dynamic>? ?? [];
      
      // Filter by title client-side (backend doesn't support search for trips)
      final queryLower = query.toLowerCase();
      final filtered = results
          .cast<Map<String, dynamic>>()
          .where((trip) {
            final title = (trip['title'] as String? ?? '').toLowerCase();
            final description = (trip['description'] as String? ?? '').toLowerCase();
            return title.contains(queryLower) || description.contains(queryLower);
          })
          .toList();
      
      setState(() {
        _trips = filtered;
        _hasMore = false; // No pagination with client-side filtering
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load more trips (pagination)
  Future<void> _loadMoreTrips() async {
    if (_isLoading || !_hasMore || _searchController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      // Note: Pagination disabled for trip search due to client-side filtering
      // Backend doesn't support 'search' parameter for trips endpoint
      setState(() {
        _isLoading = false;
        _currentPage--; // Revert page increment
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPage--; // Revert page increment on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchTrips('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchTrips(value);
                    }
                  });
                },
                onSubmitted: _searchTrips,
              ),
            ),

            // Results list
            Expanded(
              child: () {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_hasSearched) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search trips',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_trips.isEmpty) {
                  return Center(
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: _trips.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index >= _trips.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final trip = _trips[index];
                    final tripId = trip['id'] as int;
                    final title = trip['title'] as String? ?? 'Untitled Trip';
                    final startTimeStr = trip['startTime'] as String?;
                    final lead = trip['lead'] as Map<String, dynamic>?;
                    
                    DateTime? startTime;
                    if (startTimeStr != null) {
                      try {
                        startTime = DateTime.parse(startTimeStr);
                      } catch (e) {
                        // Ignore parse errors
                      }
                    }

                    final leadName = lead != null
                        ? '${lead['firstName'] ?? ''} ${lead['lastName'] ?? ''}'.trim()
                        : 'Unknown Lead';
                    
                    // Handle level - can be either a string or an object
                    String levelName;
                    final levelData = trip['level'];
                    if (levelData is String) {
                      levelName = levelData;
                    } else if (levelData is Map<String, dynamic>) {
                      levelName = levelData['name'] as String? ?? 'Unknown Level';
                    } else {
                      levelName = 'Unknown Level';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: colors.onSurface.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  startTime != null ? dateFormat.format(startTime) : 'No date',
                                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: colors.onSurface.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    leadName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Chip(
                              label: Text(
                                levelName,
                                style: const TextStyle(fontSize: 11),
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.of(context).pop({
                            'id': tripId,
                            'title': title,
                            'startTime': startTimeStr,
                            'leadName': leadName,
                            'levelName': levelName,
                          });
                        },
                      ),
                    );
                  },
                );
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
