import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../widgets/trip_requests_summary_widget.dart';
import '../widgets/upgrade_requests_summary_widget.dart';
import '../widgets/performance_metrics_widget.dart';
// Trip leadership leaderboard removed
import 'package:flutter/foundation.dart';

/// Admin Dashboard Home Screen
///
/// Overview screen showing statistics, quick actions, and recent activity.
/// This is the main landing page when admins navigate to /admin/dashboard.
///
/// ✅ AUDIT FIX: Added real API metrics (Priority 1 - HIGH)
class AdminDashboardHomeScreen extends ConsumerStatefulWidget {
  const AdminDashboardHomeScreen({super.key});

  @override
  ConsumerState<AdminDashboardHomeScreen> createState() =>
      _AdminDashboardHomeScreenState();
}

class _AdminDashboardHomeScreenState
    extends ConsumerState<AdminDashboardHomeScreen> {
  // Dashboard statistics
  int? _pendingTripsCount;
  int? _activeMembersCount;
  int? _totalTripsCount;
  int? _monthlyRegistrationsCount;

  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadDashboardStatistics();
  }

  /// Load all dashboard statistics from API
  Future<void> _loadDashboardStatistics() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);

      // Calculate date ranges
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfMonthISO = firstDayOfMonth.toIso8601String();

      // Load all statistics in parallel
      final results = await Future.wait([
        // 1. Pending trips count
        repository.getTrips(approvalStatus: 'P', pageSize: 1),

        // 2. Active members count (all members)
        repository.getMembers(pageSize: 1),

        // 3. Total trips count (all approved trips)
        repository.getTrips(approvalStatus: 'A', pageSize: 1),

        // 4. Monthly registrations - trips starting this month
        repository.getTrips(
          approvalStatus: 'A',
          startTimeAfter: firstDayOfMonthISO,
          pageSize: 1,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _pendingTripsCount = results[0]['count'] as int? ?? 0;
        _activeMembersCount = results[1]['count'] as int? ?? 0;
        _totalTripsCount = results[2]['count'] as int? ?? 0;
        _monthlyRegistrationsCount = results[3]['count'] as int? ?? 0;
        _isLoadingStats = false;
      });

      if (kDebugMode) {
        debugPrint(
          '✅ Dashboard stats loaded: Pending=$_pendingTripsCount, Members=$_activeMembersCount, Total=$_totalTripsCount, Monthly=$_monthlyRegistrationsCount',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statsError = 'Failed to load statistics: $e';
        _isLoadingStats = false;
      });

      if (kDebugMode) {
        debugPrint('❌ Dashboard stats error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome back, ${user?.firstName ?? 'Admin'}!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with Abu Dhabi Off-road Club',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Cards with real data
            _StatisticsSection(
              pendingTripsCount: _pendingTripsCount,
              activeMembersCount: _activeMembersCount,
              totalTripsCount: _totalTripsCount,
              monthlyRegistrationsCount: _monthlyRegistrationsCount,
              isLoading: _isLoadingStats,
              errorMessage: _statsError,
              onRetry: _loadDashboardStatistics,
            ),
            const SizedBox(height: 24),

            // Phase B: Enhanced Dashboard Widgets
            // Two-column layout for desktop, stacked for mobile
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 900;

                if (isWideScreen) {
                  // Desktop: Two columns
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const TripRequestsSummaryWidget(),
                            const SizedBox(height: 24),
                            const UpgradeRequestsSummaryWidget(),
                            const SizedBox(height: 24),
                            const PerformanceMetricsWidget(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _QuickActionsSection(user: user),
                            const SizedBox(height: 24),
                            _RecentActivitySection(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile: Stacked
                  return Column(
                    children: [
                      const TripRequestsSummaryWidget(),
                      const SizedBox(height: 24),
                      const UpgradeRequestsSummaryWidget(),
                      const SizedBox(height: 24),
                      const PerformanceMetricsWidget(),
                      const SizedBox(height: 24),
                      _QuickActionsSection(user: user),
                      const SizedBox(height: 24),
                      _RecentActivitySection(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics overview cards - Redesigned to match Trip Requests widget style
/// ✅ AUDIT FIX: Now displays real API data
class _StatisticsSection extends StatelessWidget {
  final int? pendingTripsCount;
  final int? activeMembersCount;
  final int? totalTripsCount;
  final int? monthlyRegistrationsCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _StatisticsSection({
    required this.pendingTripsCount,
    required this.activeMembersCount,
    required this.totalTripsCount,
    required this.monthlyRegistrationsCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

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
            // Header matching Trip Requests widget
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard_outlined,
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
                        'Quick Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Key metrics at a glance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error state
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Failed to load statistics',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // Statistics Grid - 2x2 layout
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.approval_outlined,
                    iconColor: colors.primary,
                    title: 'Pending Trips',
                    value: isLoading
                        ? '...'
                        : (pendingTripsCount?.toString() ?? '0'),
                    subtitle: 'Awaiting approval',
                    onTap: (context) => context.go('/admin/trips/pending'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_outline,
                    iconColor: Colors.blue,
                    title: 'Active Members',
                    value: isLoading
                        ? '...'
                        : (activeMembersCount?.toString() ?? '0'),
                    subtitle: 'Club members',
                    onTap: (context) => context.go('/admin/members'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_outlined,
                    iconColor: Colors.green,
                    title: 'Total Trips',
                    value: isLoading
                        ? '...'
                        : (totalTripsCount?.toString() ?? '0'),
                    subtitle: 'All time',
                    onTap: (context) => context.go('/admin/trips/all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.how_to_reg_outlined,
                    iconColor: Colors.orange,
                    title: 'Trips This Month',
                    value: isLoading
                        ? '...'
                        : (monthlyRegistrationsCount?.toString() ?? '0'),
                    subtitle: 'Starting this month',
                    onTap: (context) =>
                        context.go('/admin/registration-analytics'),
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

/// Individual statistic card - Redesigned to match Performance Metrics style
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final void Function(BuildContext)? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap != null ? () => onTap!(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Icon at top
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),

            // Value - large and bold
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action buttons section
class _QuickActionsSection extends StatelessWidget {
  final dynamic user;

  const _QuickActionsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Logbook Analytics
            if (user?.hasPermission('sign_logbook_skills') ?? false)
              _QuickActionButton(
                icon: Icons.analytics,
                label: 'Logbook Analytics',
                onTap: () => context.go('/admin/logbook/analytics'),
                color: const Color(0xFF9C27B0),
              ),

            // Phase B Features (Priority)
            if (user?.hasPermission('approve_trip') ?? false)
              _QuickActionButton(
                icon: Icons.assignment_outlined,
                label: 'Trip Requests',
                onTap: () => context.go('/admin/trip-requests'),
                color: const Color(0xFFE91E63),
              ),

            if (user?.hasPermission('view_members') ?? false)
              _QuickActionButton(
                icon: Icons.feedback_outlined,
                label: 'Feedback',
                onTap: () => context.go('/admin/feedback'),
                color: Colors.purple,
              ),

            // Core Trip Management
            if (user?.hasPermission('approve_trip') ?? false)
              _QuickActionButton(
                icon: Icons.approval,
                label: 'Pending Trips',
                onTap: () => context.go('/admin/trips/pending'),
              ),

            if (user?.hasPermission('create_trip') ?? false)
              _QuickActionButton(
                icon: Icons.add_circle,
                label: 'Create Trip',
                onTap: () => context.go('/trips/create'),
                color: Colors.green,
              ),

            // Member Management
            if (user?.hasPermission('view_members') ?? false)
              _QuickActionButton(
                icon: Icons.people,
                label: 'View Members',
                onTap: () => context.go('/admin/members'),
              ),

            if (user?.hasPermission('view_upgrade_req') ?? false)
              _QuickActionButton(
                icon: Icons.upgrade,
                label: 'Upgrade Requests',
                onTap: () => context.go('/admin/upgrade-requests'),
              ),

            // Gallery Management
            if (user?.hasPermission('edit_trip_media') ?? false)
              _QuickActionButton(
                icon: Icons.admin_panel_settings,
                label: 'Gallery Admin',
                onTap: () => context.go('/admin/gallery-management'),
              ),

            if (user?.hasPermission('delete_trip_comments') ?? false)
              _QuickActionButton(
                icon: Icons.comment,
                label: 'Comments',
                onTap: () => context.go('/admin/comments-moderation'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final buttonColor = color ?? colors.primary;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: buttonColor),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(color: buttonColor.withValues(alpha: 0.5)),
        foregroundColor: buttonColor,
      ),
    );
  }
}

/// Recent activity section (placeholder)
class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No recent activity',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Activity feed will appear here when actions are taken',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
