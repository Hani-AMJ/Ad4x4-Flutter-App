import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../shared/widgets/widgets.dart';

/// Trip History with Logbook Context Screen
/// 
/// Shows member's trip history with logbook entries and skills verified per trip
/// Provides comprehensive view of member's progression through club activities
class TripHistoryWithLogbookScreen extends ConsumerStatefulWidget {
  final int? memberId; // Optional - defaults to current user

  const TripHistoryWithLogbookScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<TripHistoryWithLogbookScreen> createState() =>
      _TripHistoryWithLogbookScreenState();
}

class _TripHistoryWithLogbookScreenState
    extends ConsumerState<TripHistoryWithLogbookScreen> {
  final _repository = MainApiRepository();

  List<TripHistoryItem> _tripHistory = [];
  Map<int, List<LogbookEntry>> _tripLogbookEntries = {};
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  // Filter states
  String _filterStatus = 'all'; // all, upcoming, completed, attended

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripHistory();
    });
  }

  Future<void> _loadTripHistory({bool isLoadMore = false}) async {
    if (_isLoading && isLoadMore) return;
    if (!_hasMore && isLoadMore) return;

    setState(() {
      if (!isLoadMore) {
        _isLoading = true;
        _currentPage = 1;
      }
      _errorMessage = null;
    });

    try {
      // Get target member ID (current user or specified)
      final user = ref.read(currentUserProviderV2);
      final targetMemberId = widget.memberId ?? user?.id ?? 0;

      // Load trip history
      final response = await _repository.getMemberTripHistory(
        memberId: targetMemberId,
        page: _currentPage,
        pageSize: 20,
      );

      // Parse trip history
      final List<TripHistoryItem> newTrips = [];
      final data = response['results'] ?? response['data'] ?? response;

      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              newTrips.add(TripHistoryItem.fromJson(item));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Failed to parse trip history item: $e');
              }
            }
          }
        }
      }

      // Load logbook entries for these trips
      await _loadLogbookEntriesForTrips(newTrips, targetMemberId);

      setState(() {
        if (isLoadMore) {
          _tripHistory.addAll(newTrips);
        } else {
          _tripHistory = newTrips;
        }
        _hasMore = newTrips.length >= 20;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLogbookEntriesForTrips(
    List<TripHistoryItem> trips,
    int memberId,
  ) async {
    for (var trip in trips) {
      try {
        final response = await _repository.getLogbookEntries(
          memberId: memberId,
          tripId: trip.tripId,
        );

        final List<LogbookEntry> entries = [];
        final data = response['results'] ?? response['data'] ?? response;

        if (data is List) {
          for (var item in data) {
            if (item != null && item is Map<String, dynamic>) {
              try {
                entries.add(LogbookEntry.fromJson(item));
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('Failed to parse logbook entry: $e');
                }
              }
            }
          }
        }

        // Enrich entries
        final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
        final enrichedEntries = await enrichmentService.enrichLogbookEntries(entries);
        
        _tripLogbookEntries[trip.tripId] = enrichedEntries;
      } catch (e) {
        print('⚠️ Failed to load logbook entries for trip ${trip.tripId}: $e');
        _tripLogbookEntries[trip.tripId] = [];
      }
    }
  }

  List<TripHistoryItem> get _filteredTrips {
    final now = DateTime.now();

    switch (_filterStatus) {
      case 'upcoming':
        return _tripHistory
            .where((t) => t.startTime.isAfter(now))
            .toList();
      case 'completed':
        return _tripHistory
            .where((t) => t.startTime.isBefore(now))
            .toList();
      case 'attended':
        return _tripHistory
            .where((t) => t.attended && t.startTime.isBefore(now))
            .toList();
      default:
        return _tripHistory;
    }
  }

  /// Calculate stats for display
  Map<String, int> get _stats {
    final now = DateTime.now();
    return {
      'total': _tripHistory.length,
      'upcoming': _tripHistory.where((t) => t.startTime.isAfter(now)).length,
      'completed': _tripHistory.where((t) => t.startTime.isBefore(now)).length,
      'attended': _tripHistory.where((t) => t.attended).length,
      'skillsVerified': _tripLogbookEntries.values
          .expand((entries) => entries)
          .expand((entry) => entry.skillsVerified)
          .toSet()
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading && _tripHistory.isEmpty
          ? const LoadingIndicator(message: 'Loading trip history...')
          : _errorMessage != null && _tripHistory.isEmpty
              ? ErrorState(
                  title: 'Error Loading History',
                  message: _errorMessage!,
                  onRetry: _loadTripHistory,
                )
              : Column(
                  children: [
                    // Stats Header
                    _buildStatsHeader(colors, stats),

                    // Filter Chips
                    _buildFilterChips(colors),

                    // Trip History List
                    Expanded(
                      child: _filteredTrips.isEmpty
                          ? EmptyState(
                              icon: Icons.history,
                              title: 'No Trip History',
                              message: _filterStatus == 'all'
                                  ? 'No trips found in your history.'
                                  : 'No trips match the selected filter.',
                              actionText: _filterStatus != 'all'
                                  ? 'Clear Filter'
                                  : null,
                              onAction: _filterStatus != 'all'
                                  ? () => setState(() => _filterStatus = 'all')
                                  : null,
                            )
                          : RefreshIndicator(
                              onRefresh: () => _loadTripHistory(isLoadMore: false),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredTrips.length + 1,
                                itemBuilder: (context, index) {
                                  // Load more trigger
                                  if (index == _filteredTrips.length) {
                                    if (_hasMore) {
                                      _loadTripHistory(isLoadMore: true);
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }

                                  final trip = _filteredTrips[index];
                                  final logbookEntries =
                                      _tripLogbookEntries[trip.tripId] ?? [];

                                  return _TripHistoryCard(
                                    trip: trip,
                                    logbookEntries: logbookEntries,
                                    onTap: () => context.push('/trips/${trip.tripId}'),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatsHeader(ColorScheme colors, Map<String, int> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.directions_car,
            label: 'Total Trips',
            value: '${stats['total']}',
            color: colors.onPrimaryContainer,
          ),
          _StatItem(
            icon: Icons.check_circle,
            label: 'Attended',
            value: '${stats['attended']}',
            color: colors.onPrimaryContainer,
          ),
          _StatItem(
            icon: Icons.star,
            label: 'Skills',
            value: '${stats['skillsVerified']}',
            color: colors.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: _filterStatus == 'all',
              onTap: () => setState(() => _filterStatus = 'all'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Upcoming',
              isSelected: _filterStatus == 'upcoming',
              onTap: () => setState(() => _filterStatus = 'upcoming'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Completed',
              isSelected: _filterStatus == 'completed',
              onTap: () => setState(() => _filterStatus = 'completed'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Attended',
              isSelected: _filterStatus == 'attended',
              onTap: () => setState(() => _filterStatus = 'attended'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trip History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Trips'),
              value: 'all',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Upcoming Trips'),
              value: 'upcoming',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Completed Trips'),
              value: 'completed',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Trips Attended'),
              value: 'attended',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primaryContainer,
      backgroundColor: colors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

/// Trip History Card Widget
class _TripHistoryCard extends StatelessWidget {
  final TripHistoryItem trip;
  final List<LogbookEntry> logbookEntries;
  final VoidCallback onTap;

  const _TripHistoryCard({
    required this.trip,
    required this.logbookEntries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();
    final isUpcoming = trip.startTime.isAfter(now);
    final hasLogbookEntries = logbookEntries.isNotEmpty;

    // Calculate total skills verified
    final skillsVerified = logbookEntries
        .expand((entry) => entry.skillsVerified)
        .toSet()
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUpcoming
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.2),
          width: isUpcoming ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? colors.primaryContainer.withValues(alpha: 0.3)
                    : colors.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUpcoming ? colors.primary : colors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMM').format(trip.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUpcoming ? colors.onPrimary : colors.onSurface,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(trip.startTime),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isUpcoming ? colors.onPrimary : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Trip Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (trip.level != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  trip.level!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (trip.attended)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  Icon(
                    isUpcoming ? Icons.schedule : Icons.check,
                    color: isUpcoming ? colors.primary : colors.outline,
                  ),
                ],
              ),
            ),

            // Logbook Summary (if available)
            if (hasLogbookEntries)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.1),
                  border: Border(
                    top: BorderSide(
                      color: colors.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fact_check,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logbook Entries',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Skills Verified Summary
                    if (skillsVerified > 0) ...[
                      _LogbookStatRow(
                        icon: Icons.star,
                        label: 'Skills Verified',
                        value: '$skillsVerified',
                        color: colors.primary,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Verified By
                    if (logbookEntries.isNotEmpty)
                      _LogbookStatRow(
                        icon: Icons.person,
                        label: 'Signed by',
                        value: logbookEntries
                            .map((e) => e.signedBy.displayName)
                            .toSet()
                            .join(', '),
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),

                    // Skills List Preview
                    if (skillsVerified > 0) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: logbookEntries
                            .expand((entry) => entry.skillsVerified)
                            .toSet()
                            .take(5)
                            .map((skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    skill.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSecondaryContainer,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      if (skillsVerified > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${skillsVerified - 5} more',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

            // No Logbook Entry Message
            if (!hasLogbookEntries && !isUpcoming)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No logbook entries for this trip',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogbookStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LogbookStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Trip History Item Model
/// Simplified model for trip history display
class TripHistoryItem {
  final int tripId;
  final String title;
  final DateTime startTime;
  final String? level;
  final bool attended;
  final bool checkedIn;
  final bool checkedOut;

  const TripHistoryItem({
    required this.tripId,
    required this.title,
    required this.startTime,
    this.level,
    required this.attended,
    required this.checkedIn,
    required this.checkedOut,
  });

  factory TripHistoryItem.fromJson(Map<String, dynamic> json) {
    return TripHistoryItem(
      tripId: json['trip_id'] as int? ?? json['tripId'] as int? ?? json['id'] as int,
      title: json['title'] as String,
      startTime: DateTime.parse(
        json['start_time'] as String? ?? json['startTime'] as String,
      ),
      level: json['level'] as String?,
      attended: json['attended'] as bool? ?? false,
      checkedIn: json['checked_in'] as bool? ?? json['checkedIn'] as bool? ?? false,
      checkedOut: json['checked_out'] as bool? ?? json['checkedOut'] as bool? ?? false,
    );
  }
}
