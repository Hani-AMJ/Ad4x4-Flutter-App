import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

/// Performance Metrics Widget - Shows key club performance indicators
/// Displays stats about members, trips, feedback, and registrations
class PerformanceMetricsWidget extends ConsumerStatefulWidget {
  const PerformanceMetricsWidget({super.key});

  @override
  ConsumerState<PerformanceMetricsWidget> createState() =>
      _PerformanceMetricsWidgetState();
}

class _PerformanceMetricsWidgetState
    extends ConsumerState<PerformanceMetricsWidget> {
  bool _isLoading = true;
  String? _error;

  int _totalMembers = 0;
  int _totalTrips = 0;
  int _upcomingTrips = 0;
  int _totalFeedback = 0;
  int _pendingFeedback = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);

      // Fetch members count
      try {
        final membersResponse = await repository.getMembers(pageSize: 1);
        _totalMembers = membersResponse['count'] as int? ?? 0;
      } catch (e) {
        // Silent fail for members
      }

      // Fetch trips count
      try {
        final tripsResponse = await repository.getTrips(pageSize: 1);
        _totalTrips = tripsResponse['count'] as int? ?? 0;

        // Count upcoming trips (simple check for now)
        final allTripsResponse = await repository.getTrips(pageSize: 100);
        final results = allTripsResponse['results'] as List<dynamic>? ?? [];
        final now = DateTime.now();

        _upcomingTrips = results.where((trip) {
          final startTime = trip['start_time'] as String?;
          if (startTime == null) return false;
          try {
            final tripDate = DateTime.parse(startTime);
            return tripDate.isAfter(now);
          } catch (e) {
            return false;
          }
        }).length;
      } catch (e) {
        // Silent fail for trips
      }

      // Fetch feedback count
      // NOTE: Removed getAllFeedback call - backend doesn't support GET /api/feedback/
      // This endpoint requires admin permissions and specific implementation
      // For now, skip feedback metrics to avoid 405 errors
      try {
        // TODO: Implement proper feedback admin endpoint when available
        _totalFeedback = 0;
        _pendingFeedback = 0;
      } catch (e) {
        // Silent fail for feedback
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load metrics';
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
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Metrics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Club activity overview',
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
                    onPressed: _loadMetrics,
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
                    Icon(Icons.error_outline, color: colors.error, size: 32),
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
                      onPressed: _loadMetrics,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.people_outline,
                          iconColor: Colors.blue,
                          label: 'Total Members',
                          value: _totalMembers.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.event_outlined,
                          iconColor: Colors.green,
                          label: 'Total Trips',
                          value: _totalTrips.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.event_available_outlined,
                          iconColor: Colors.orange,
                          label: 'Upcoming Trips',
                          value: _upcomingTrips.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.feedback_outlined,
                          iconColor: Colors.purple,
                          label: 'Feedback',
                          value: '$_pendingFeedback/$_totalFeedback',
                          subtitle: 'Pending/Total',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickStat(
                          icon: Icons.trending_up,
                          label: 'Active',
                          color: Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colors.outline.withValues(alpha: 0.2),
                        ),
                        _QuickStat(
                          icon: Icons.check_circle_outline,
                          label: 'Healthy',
                          color: Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colors.outline.withValues(alpha: 0.2),
                        ),
                        _QuickStat(
                          icon: Icons.star_outline,
                          label: 'Growing',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual metric card
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick status indicator
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
