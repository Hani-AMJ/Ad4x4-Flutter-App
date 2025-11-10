import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
              // Welcome Section
              Text(
                'Welcome to AD4x4',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abu Dhabi Off-Road Club',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions Grid
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
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
                    title: 'Trip Requests',
                    color: const Color(0xFFE91E63),
                    onTap: () => context.push('/trip-requests'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity Section
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ActivityCard(
                icon: Icons.directions_car,
                title: 'Upcoming Desert Safari',
                subtitle: 'This Friday, 6:00 AM',
                trailing: 'Join',
                onTap: () => context.push('/trips/upcoming-safari'),
              ),
              const SizedBox(height: 12),
              _ActivityCard(
                icon: Icons.event,
                title: 'Annual BBQ Event',
                subtitle: 'Next Saturday, 5:00 PM',
                trailing: 'Register',
                onTap: () => context.push('/events/annual-bbq'),
              ),
              const SizedBox(height: 12),
              _ActivityCard(
                icon: Icons.photo_camera,
                title: 'New Photos Added',
                subtitle: 'Last Week\'s Trip Album',
                trailing: 'View',
                onTap: () => context.push('/gallery/album/last-week'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push('/trips');
              break;
            case 2:
              context.push('/gallery');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
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
