import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';

/// Trip Requests Summary Widget - Shows statistics about trip requests
/// Displays counts for different request statuses with quick navigation
class TripRequestsSummaryWidget extends ConsumerStatefulWidget {
  const TripRequestsSummaryWidget({super.key});

  @override
  ConsumerState<TripRequestsSummaryWidget> createState() => _TripRequestsSummaryWidgetState();
}

class _TripRequestsSummaryWidgetState extends ConsumerState<TripRequestsSummaryWidget> {
  bool _isLoading = true;
  String? _error;
  
  int _totalRequests = 0;
  int _pendingRequests = 0;
  int _approvedRequests = 0;
  int _declinedRequests = 0;
  int _convertedRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadRequestStats();
  }

  Future<void> _loadRequestStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Fetch requests with large page size to get all counts
      final response = await repository.getAllTripRequests(pageSize: 1000);
      final results = response['results'] as List<dynamic>? ?? [];
      
      // Count by status
      int total = results.length;
      int pending = 0;
      int approved = 0;
      int declined = 0;
      int converted = 0;
      
      for (var request in results) {
        final status = request['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'declined':
            declined++;
            break;
          case 'converted':
            converted++;
            break;
        }
      }
      
      setState(() {
        _totalRequests = total;
        _pendingRequests = pending;
        _approvedRequests = approved;
        _declinedRequests = declined;
        _convertedRequests = converted;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load trip request stats';
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
                    color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFFE91E63),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Member trip suggestions',
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
                    onPressed: _loadRequestStats,
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
                      onPressed: _loadRequestStats,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Total Requests (Large)
                  InkWell(
                    onTap: () => context.push('/admin/trip-requests'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Requests',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _totalRequests.toString(),
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          label: 'Pending',
                          count: _pendingRequests,
                          color: Colors.orange,
                          icon: Icons.pending_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatusCard(
                          label: 'Approved',
                          count: _approvedRequests,
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          label: 'Declined',
                          count: _declinedRequests,
                          color: Colors.red,
                          icon: Icons.cancel_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatusCard(
                          label: 'Converted',
                          count: _convertedRequests,
                          color: Colors.blue,
                          icon: Icons.event_available_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // View All Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('View All Requests'),
                      onPressed: () => context.push('/admin/trip-requests'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

/// Individual status count card
class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
