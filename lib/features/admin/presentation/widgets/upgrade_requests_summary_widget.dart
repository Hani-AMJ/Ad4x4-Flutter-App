import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';

/// Upgrade Requests Summary Widget - Shows statistics about upgrade requests
/// Displays counts for different request statuses with quick navigation
class UpgradeRequestsSummaryWidget extends ConsumerStatefulWidget {
  const UpgradeRequestsSummaryWidget({super.key});

  @override
  ConsumerState<UpgradeRequestsSummaryWidget> createState() => _UpgradeRequestsSummaryWidgetState();
}

class _UpgradeRequestsSummaryWidgetState extends ConsumerState<UpgradeRequestsSummaryWidget> {
  bool _isLoading = true;
  String? _error;
  
  int _totalRequests = 0;
  int _newRequests = 0;      // New requests with no votes yet
  int _pendingRequests = 0;  // Pending requests with votes
  int _approvedRequests = 0;
  int _declinedRequests = 0;

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
      
      // Fetch upgrade requests with large page size to get all counts
      final response = await repository.getUpgradeRequests(page: 1, limit: 1000);
      final results = response['results'] as List<dynamic>? ?? [];
      
      // Count by status - separate "New" from "Pending"
      int total = results.length;
      int newCount = 0;
      int pending = 0;
      int approved = 0;
      int declined = 0;
      
      for (var request in results) {
        final status = (request['status'] as String? ?? '').toLowerCase();
        
        // Count "New" and "In Progress" separately
        if (status == 'new') {
          newCount++;
        } else if (status == 'in progress' || status == 'pending') {
          pending++;  // Backend uses "In Progress", but handle "Pending" for backwards compatibility
        } else if (status == 'approved') {
          approved++;
        } else if (status == 'declined') {
          declined++;
        }
      }
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _totalRequests = total;
        _newRequests = newCount;
        _pendingRequests = pending;
        _approvedRequests = approved;
        _declinedRequests = declined;
        _isLoading = false;
      });
      
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to load upgrade request stats';
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.upgrade,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade Requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Member level upgrade requests',
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
                    onTap: () => context.push('/admin/upgrade-requests'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
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
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.orange,
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
                          label: 'New',
                          count: _newRequests,
                          color: const Color(0xFF9C27B0),  // Purple
                          icon: Icons.new_releases,
                          subtitle: 'No votes yet',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatusCard(
                          label: 'In Progress',
                          count: _pendingRequests,
                          color: Colors.orange,
                          icon: Icons.pending_outlined,
                          subtitle: 'Being reviewed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          label: 'Approved',
                          count: _approvedRequests,
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                          subtitle: 'Level upgraded',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatusCard(
                          label: 'Declined',
                          count: _declinedRequests,
                          color: Colors.red,
                          icon: Icons.cancel_outlined,
                          subtitle: 'Not approved',
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
                      onPressed: () => context.push('/admin/upgrade-requests'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                        foregroundColor: Colors.orange,
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
  final String? subtitle;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
