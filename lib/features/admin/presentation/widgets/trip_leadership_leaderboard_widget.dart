import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/trip_statistics.dart';

/// Trip Leadership Leaderboard Widget
/// 
/// Shows top trip leaders ranked by number of trips created
/// Displays:
/// - Rank badge (gold, silver, bronze for top 3)
/// - Leader name
/// - Trips created count
/// - Leadership role indicators
class TripLeadershipLeaderboardWidget extends ConsumerStatefulWidget {
  const TripLeadershipLeaderboardWidget({super.key});

  @override
  ConsumerState<TripLeadershipLeaderboardWidget> createState() =>
      _TripLeadershipLeaderboardWidgetState();
}

class _TripLeadershipLeaderboardWidgetState
    extends ConsumerState<TripLeadershipLeaderboardWidget> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _leaders = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);

      // Fetch all members (limited to reasonable number)
      final membersResponse = await repository.getMembers(pageSize: 100);
      final membersData = membersResponse['results'] as List<dynamic>? ?? [];

      // Fetch trip statistics for each member
      final leaderData = <Map<String, dynamic>>[];

      for (var memberJson in membersData) {
        try {
          final memberId = memberJson['id'] as int;
          final memberName = memberJson['display_name'] as String? ??
              memberJson['username'] as String? ??
              'Unknown';

          // Get trip counts for this member
          final statsResponse = await repository.getMemberTripCounts(memberId);
          final statsData = statsResponse['data'] ?? statsResponse['results'] ?? statsResponse;
          final stats = TripStatistics.fromJson(
              statsData is Map<String, dynamic> ? statsData : {});

          // Only include members with leadership experience
          if (stats.asLeadTrips > 0) {
            leaderData.add({
              'memberId': memberId,
              'memberName': memberName,
              'tripsLead': stats.asLeadTrips,
              'tripsMarshal': stats.asMarshalTrips,
              'totalLeadership': stats.totalLeadershipRoles,
              'completedTrips': stats.completedTrips,
            });
          }
        } catch (e) {
          // Skip members with errors
          continue;
        }
      }

      // Sort by trips lead descending
      leaderData.sort((a, b) =>
          (b['tripsLead'] as int).compareTo(a['tripsLead'] as int));

      // Take top 10
      final topLeaders = leaderData.take(10).toList();

      setState(() {
        _leaders = topLeaders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.leaderboard,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Leadership Leaderboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Top trip organizers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadLeaderboard,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colors.error,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _loadLeaderboard,
                    ),
                  ],
                ),
              )
            else if (_leaders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: colors.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trip leaders yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _leaders.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final leader = entry.value;
                  return _buildLeaderCard(rank, leader, theme, colors);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderCard(
    int rank,
    Map<String, dynamic> leader,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final memberName = leader['memberName'] as String;
    final tripsLead = leader['tripsLead'] as int;
    final tripsMarshal = leader['tripsMarshal'] as int;
    final totalLeadership = leader['totalLeadership'] as int;

    // Rank badge color
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = colors.outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rank <= 3
            ? rankColor.withValues(alpha: 0.05)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.2),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Leader info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$tripsLead trips led',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (tripsMarshal > 0) ...[
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.shield,
                        size: 14,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$tripsMarshal as marshal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total leadership score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalLeadership',
              style: TextStyle(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
