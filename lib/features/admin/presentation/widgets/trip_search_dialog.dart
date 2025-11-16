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
  List<Map<String, dynamic>> _filteredTrips = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search trips by title
  Future<void> _searchTrips(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredTrips = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Search approved trips only
      final response = await repository.getTrips(
        approvalStatus: 'A',
        pageSize: 50,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      
      // Filter by title client-side (backend doesn't support title search)
      final queryLower = query.toLowerCase();
      final filtered = results
          .cast<Map<String, dynamic>>()
          .where((trip) {
            final title = (trip['title'] as String? ?? '').toLowerCase();
            return title.contains(queryLower);
          })
          .toList();
      
      setState(() {
        _filteredTrips = filtered;
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

                if (_filteredTrips.isEmpty) {
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
                  itemCount: _filteredTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _filteredTrips[index];
                    final tripId = trip['id'] as int;
                    final title = trip['title'] as String? ?? 'Untitled Trip';
                    final startTimeStr = trip['startTime'] as String?;
                    final lead = trip['lead'] as Map<String, dynamic>?;
                    final level = trip['level'] as Map<String, dynamic>?;
                    
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
                    final levelName = level?['name'] as String? ?? 'Unknown Level';

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
