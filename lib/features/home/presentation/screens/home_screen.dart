import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../shared/widgets/home/upcoming_trips_carousel.dart';
import '../../../../shared/widgets/home/member_progress_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final user = authState.user;

    // Check if user has admin permissions
    // Allow access for Admins, Board Members, and Marshals
    final hasAdminAccess = user != null && _hasAnyAdminPermission(user);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_transparent.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('AD4x4'),
          ],
        ),
        actions: [
          // Admin Panel button (only visible to admins)
          if (hasAdminAccess)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized Greeting
              if (user != null) ...[
                Text(
                  'Hello, ${user.displayName.split(' ').first}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your next adventure?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Member Progress Widget (moved to top)
              const MemberProgressWidget(),
              const SizedBox(height: 24),

              // Quick Actions Grid (compact 3-column layout)
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _QuickActionCard(
                    icon: Icons.explore_outlined,
                    title: 'Trips',
                    color: colors.primary,
                    onTap: () => context.push('/trips'),
                  ),
                  _QuickActionCard(
                    icon: Icons.event_outlined,
                    title: 'Events',
                    color: const Color(0xFF64B5F6),
                    onTap: () => context.push('/events'),
                  ),
                  _QuickActionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Gallery',
                    color: const Color(0xFF42B883),
                    onTap: () => context.push('/gallery'),
                  ),
                  _QuickActionCard(
                    icon: Icons.people_outline,
                    title: 'Members',
                    color: const Color(0xFFFFC107),
                    onTap: () => context.push('/members'),
                  ),
                  _QuickActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Requests',
                    color: const Color(0xFFE91E63),
                    onTap: () => context.push('/trip-requests'),
                  ),
                  _QuickActionCard(
                    icon: Icons.trending_up,
                    title: 'Logbook',
                    color: const Color(0xFFFF9800),
                    onTap: () => context.push('/logbook'),
                  ),
                  _QuickActionCard(
                    icon: Icons.location_on,
                    title: 'Points',
                    color: const Color(0xFF00BCD4),
                    onTap: () => context.push('/meeting-points'),
                  ),
                  // Admin Panel card (only visible to admins)
                  if (hasAdminAccess)
                    _QuickActionCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin',
                      color: const Color(0xFF9C27B0),
                      onTap: () => context.push('/admin'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Upcoming Trips Section
              Text(
                'Upcoming Trips',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const UpcomingTripsCarousel(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // Bottom navigation is now provided by AppShell
    );
  }

  /// Check if user has any admin/marshal/board permissions
  bool _hasAnyAdminPermission(dynamic user) {
    final adminPermissions = [
      // Trip management
      'create_trip',
      'create_trip_with_approval',
      'edit_trips',
      'delete_trips',
      'approve_trip',
      'edit_trip_registrations',
      
      // Member management
      'view_members',
      'edit_membership_payments',
      
      // Meeting points (FIXED: use plural forms)
      'create_meeting_points',
      'edit_meeting_points',
      'delete_meeting_points',
      
      // Marshal panel (NEW: added marshal access)
      'access_marshal_panel',
      'create_logbook_entries',
      'sign_logbook_skills',
      
      // Upgrade requests
      'view_upgrade_req',
      'approve_upgrade_req',
    ];
    return adminPermissions.any((permission) => user.hasPermission(permission));
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primary.withValues(alpha: 0.2),
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(trailing),
        ),
        onTap: onTap,
      ),
    );
  }
}
