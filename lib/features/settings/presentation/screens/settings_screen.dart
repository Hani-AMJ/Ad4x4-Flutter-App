import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import 'package:flutter/foundation.dart'; // V2 - Clean implementation
import '../../../../shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _tripReminders = true;
  bool _eventUpdates = true;
  bool _newMessages = true;
  bool _locationSharing = false;
  String _language = 'English';
  String _theme = 'Dark';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Account Section
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => context.push('/profile/edit'),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () {
                // TODO: Navigate to privacy settings
              },
            ),
            _SettingsTile(
              icon: Icons.garage,
              title: 'My Vehicles',
              subtitle: 'Manage your vehicle information',
              onTap: () => context.push('/vehicles'),
            ),

            const Divider(height: 32),

            // Notifications Section
            _SectionHeader(title: 'Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Push Notifications'),
              subtitle: const Text('Enable or disable all notifications'),
              value: _notificationsEnabled,
              activeColor: colors.primary,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.event_outlined),
              title: const Text('Trip Reminders'),
              subtitle: const Text('Get reminders about upcoming trips'),
              value: _tripReminders,
              activeColor: colors.primary,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _tripReminders = value;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.event_available),
              title: const Text('Event Updates'),
              subtitle: const Text('Notifications about club events'),
              value: _eventUpdates,
              activeColor: colors.primary,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _eventUpdates = value;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.message_outlined),
              title: const Text('New Messages'),
              subtitle: const Text('Notifications for new messages'),
              value: _newMessages,
              activeColor: colors.primary,
              onChanged: _notificationsEnabled
                  ? (value) {
                      setState(() {
                        _newMessages = value;
                      });
                    }
                  : null,
            ),

            const Divider(height: 32),

            // Privacy Section
            _SectionHeader(title: 'Privacy'),
            SwitchListTile(
              secondary: const Icon(Icons.location_on_outlined),
              title: const Text('Location Sharing'),
              subtitle: const Text('Share location during trips'),
              value: _locationSharing,
              activeColor: colors.primary,
              onChanged: (value) {
                setState(() {
                  _locationSharing = value;
                });
              },
            ),

            const Divider(height: 32),

            // Appearance Section
            _SectionHeader(title: 'Appearance'),
            _SettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: _language,
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              subtitle: _theme,
              onTap: () {
                _showThemeDialog(context);
              },
            ),

            const Divider(height: 32),

            // About Section
            _SectionHeader(title: 'About'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About AD4x4',
              subtitle: 'App version 1.0.0',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or contact us',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            _SettingsTile(
              icon: Icons.gavel,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms',
              onTap: () {
                // TODO: Show terms
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                // TODO: Show privacy policy
              },
            ),

            // Debug section (development only)
            if (kDebugMode || kIsWeb) ...[
              const Divider(height: 32),
              _SectionHeader(title: 'Debug'),
              _SettingsTile(
                icon: Icons.bug_report,
                title: 'Permission Debug',
                subtitle: 'Check your admin permissions',
                onTap: () => context.push('/debug/permissions'),
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'Auth Debug',
                subtitle: 'View authentication details',
                onTap: () => context.push('/debug/auth'),
              ),
            ],

            const SizedBox(height: 32),

            // Danger Zone
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SecondaryButton(
                    text: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    width: double.infinity,
                    height: 56,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('العربية (Arabic)'),
              value: 'Arabic',
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abu Dhabi Off-Road Club'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'The region\'s largest and most active off-road club. Join us for amazing desert adventures!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
              
              // Call auth provider logout
              // Note: On web, this will IMMEDIATELY reload the page
              // On mobile, this will clear storage and state
              await ref.read(authProviderV2.notifier).logout();
              
              // No need for manual navigation - page reload handles it on web
              // Router will redirect to /login after reload
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

  void _showDeleteAccountDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colors.onSurface.withValues(alpha: 0.7)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}
