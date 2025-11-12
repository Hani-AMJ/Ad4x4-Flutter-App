import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Dashboard Home Screen
/// 
/// Overview screen showing statistics, quick actions, and recent activity.
/// This is the main landing page when admins navigate to /admin/dashboard.
class AdminDashboardHomeScreen extends ConsumerWidget {
  const AdminDashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // Statistics Cards
            _StatisticsSection(),
            const SizedBox(height: 32),

            // Quick Actions
            _QuickActionsSection(user: user),
            const SizedBox(height: 32),

            // Recent Activity (placeholder)
            _RecentActivitySection(),
          ],
        ),
      ),
    );
  }
}

/// Statistics overview cards
class _StatisticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Statistics Grid
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              icon: Icons.approval_outlined,
              iconColor: colors.primary,
              title: 'Pending Trips',
              value: '—',
              subtitle: 'Awaiting approval',
              onTap: (context) => context.go('/admin/trips/pending'),
            ),
            _StatCard(
              icon: Icons.people_outline,
              iconColor: Colors.blue,
              title: 'Active Members',
              value: '—',
              subtitle: 'Club members',
              onTap: (context) => context.go('/admin/members'),
            ),
            _StatCard(
              icon: Icons.event_outlined,
              iconColor: Colors.green,
              title: 'Total Trips',
              value: '—',
              subtitle: 'All time',
              onTap: (context) => context.go('/admin/trips/all'),
            ),
            _StatCard(
              icon: Icons.how_to_reg_outlined,
              iconColor: Colors.orange,
              title: 'Registrations',
              value: '—',
              subtitle: 'This month',
              onTap: (context) => context.go('/admin/registration-analytics'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual statistic card
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
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap != null ? () => onTap!(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
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
            if (user?.hasPermission('approve_trip') ?? false)
              _QuickActionButton(
                icon: Icons.approval,
                label: 'Pending Trips',
                onTap: () => context.go('/admin/trips/pending'),
              ),
            
            if (user?.hasPermission('view_upgrade_req') ?? false)
              _QuickActionButton(
                icon: Icons.upgrade,
                label: 'Upgrade Requests',
                onTap: () => context.go('/admin/upgrade-requests'),
              ),
            
            if (user?.hasPermission('edit_trip_media') ?? false)
              _QuickActionButton(
                icon: Icons.photo_library,
                label: 'Media Moderation',
                onTap: () => context.go('/admin/trip-media'),
              ),
            
            if (user?.hasPermission('delete_trip_comments') ?? false)
              _QuickActionButton(
                icon: Icons.comment,
                label: 'Comments',
                onTap: () => context.go('/admin/comments-moderation'),
              ),
            
            if (user?.hasPermission('view_members') ?? false)
              _QuickActionButton(
                icon: Icons.people,
                label: 'View Members',
                onTap: () => context.go('/admin/members'),
              ),
            
            if (user?.hasPermission('create_trip') ?? false)
              _QuickActionButton(
                icon: Icons.add_circle,
                label: 'Create Trip',
                onTap: () => context.go('/trips/create'),
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

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
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
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.2),
            ),
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
