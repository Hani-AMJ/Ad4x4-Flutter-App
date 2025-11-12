import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Get real user data from auth provider
    final authState = ref.watch(authProviderV2);
    final user = authState.user;

    // Show loading if user data not available
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Extract user data
    final userName = user.displayName;
    final userEmail = user.email;
    final userPhone = user.phoneNumber ?? 'Not provided';
    final memberSince = user.dateJoined != null && user.dateJoined!.isNotEmpty
        ? 'Member since ${user.dateJoined!.substring(0, 4)}'
        : 'Member';
    final userRole = user.level?.displayName ?? user.level?.name ?? 'Member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    UserAvatar(
                      name: userName,
                      imageUrl: user.avatar != null && user.avatar!.isNotEmpty 
                          ? (user.avatar!.startsWith('http') 
                              ? user.avatar 
                              : 'https://media.ad4x4.com${user.avatar}')
                          : null,
                      radius: 60,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userRole,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Member Since
                    Text(
                      memberSince,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.directions_car,
                      label: 'Trips',
                      value: '${user.tripCount ?? 0}',
                      colors: colors,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outline,
                    ),
                    _StatItem(
                      icon: Icons.photo_library,
                      label: 'Photos',
                      value: '0',  // TODO: Add photo count from Gallery API
                      colors: colors,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outline,
                    ),
                    _StatItem(
                      icon: Icons.local_fire_department,
                      label: 'Level',
                      value: '${user.level?.numericLevel ?? 0}',
                      colors: colors,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contact Information
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: userEmail,
                      iconColor: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      subtitle: userPhone,
                      iconColor: colors.primary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Vehicle Information (if available)
              if (user.carBrand != null || user.carModel != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoCard(
                        icon: Icons.directions_car,
                        title: 'Vehicle',
                        subtitle: '${user.carBrand ?? ''} ${user.carModel ?? ''} ${user.carYear != null ? '(${user.carYear})' : ''}'.trim(),
                        iconColor: const Color(0xFF64B5F6),
                      ),
                      if (user.carColor != null) ...[
                        const SizedBox(height: 12),
                        InfoCard(
                          icon: Icons.palette,
                          title: 'Color',
                          subtitle: user.carColor!,
                          iconColor: const Color(0xFF9C27B0),
                        ),
                      ],
                    ],
                  ),
                ),

              if (user.carBrand != null || user.carModel != null)
                const Divider(height: 1),

              // Emergency Contact (if available)
              if (user.iceName != null || user.icePhone != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contact',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (user.iceName != null)
                        InfoCard(
                          icon: Icons.person_outline,
                          title: 'ICE Contact',
                          subtitle: user.iceName!,
                          iconColor: const Color(0xFFFF5722),
                        ),
                      if (user.icePhone != null) ...[
                        const SizedBox(height: 12),
                        InfoCard(
                          icon: Icons.phone,
                          title: 'ICE Phone',
                          subtitle: user.icePhone!,
                          iconColor: const Color(0xFFFF5722),
                        ),
                      ],
                    ],
                  ),
                ),

              if (user.iceName != null || user.icePhone != null)
                const Divider(height: 1),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoCard(
                      icon: Icons.garage,
                      title: 'My Vehicles',
                      subtitle: 'Manage your vehicles',
                      iconColor: const Color(0xFF64B5F6),
                      onTap: () => context.push('/vehicles'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.explore,
                      title: 'My Trips',
                      subtitle: 'View your trip history',
                      iconColor: const Color(0xFF42B883),
                      onTap: () => context.push('/trips'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.event,
                      title: 'My Events',
                      subtitle: 'Registered events',
                      iconColor: const Color(0xFFFFC107),
                      onTap: () => context.push('/events'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.photo_library,
                      title: 'My Gallery',
                      subtitle: 'Your photo albums',
                      iconColor: const Color(0xFFE53935),
                      onTap: () => context.push('/gallery'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Account Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoCard(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      iconColor: colors.onSurface.withValues(alpha: 0.7),
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 12),
                    InfoCard(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      iconColor: const Color(0xFFE53935),
                      onTap: () {
                        _showLogoutDialog(context, ref);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Call auth provider V2 logout
              await ref.read(authProviderV2.notifier).logout();
              
              // Router will auto-redirect to login after logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
