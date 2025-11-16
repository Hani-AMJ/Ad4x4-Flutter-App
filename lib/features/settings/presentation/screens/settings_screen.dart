import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import 'package:flutter/foundation.dart'; // V2 - Clean implementation
import '../../../../shared/widgets/widgets.dart';
import '../../../../data/repositories/main_api_repository.dart'; // ✅ NEW

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ✅ NEW: Repository for backend API calls
  final _repository = MainApiRepository();
  
  // ✅ UPDATED: Backend-synced notification settings
  bool _clubNewsEmail = true;
  bool _clubNewsPush = true;
  bool _newTripAlertsEmail = true;
  bool _newTripAlertsPush = true;
  bool _upgradeRequestReminderEmail = true;
  List<int> _newTripAlertsLevelFilter = [];
  
  // Local settings (not synced to backend yet)
  bool _locationSharing = false;
  String _language = 'English';
  String _theme = 'Dark';
  
  bool _isLoadingSettings = true;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  /// ✅ NEW: Load notification settings from backend
  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoadingSettings = true);
    
    try {
      final response = await _repository.getNotificationSettings();
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List && data.isNotEmpty) {
        final settings = data[0] as Map<String, dynamic>;
        setState(() {
          _clubNewsEmail = settings['clubNewsEnabledEmail'] ?? true;
          _clubNewsPush = settings['clubNewsEnabledAppPush'] ?? true;
          _newTripAlertsEmail = settings['newTripAlertsEnabledEmail'] ?? true;
          _newTripAlertsPush = settings['newTripAlertsEnabledAppPush'] ?? true;
          _upgradeRequestReminderEmail = settings['upgradeRequestReminderEmail'] ?? true;
          _newTripAlertsLevelFilter = (settings['newTripAlertsLevelFilter'] as List?)?.cast<int>() ?? [];
          _isLoadingSettings = false;
        });
      } else {
        setState(() => _isLoadingSettings = false);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to load notification settings: $e');
      setState(() => _isLoadingSettings = false);
    }
  }

  /// ✅ NEW: Save notification settings to backend
  Future<void> _saveNotificationSettings() async {
    setState(() => _isSavingSettings = true);
    
    try {
      await _repository.updateNotificationSettings(
        clubNewsEnabledEmail: _clubNewsEmail,
        clubNewsEnabledAppPush: _clubNewsPush,
        newTripAlertsEnabledEmail: _newTripAlertsEmail,
        newTripAlertsEnabledAppPush: _newTripAlertsPush,
        upgradeRequestReminderEmail: _upgradeRequestReminderEmail,
        newTripAlertsLevelFilter: _newTripAlertsLevelFilter.isNotEmpty ? _newTripAlertsLevelFilter : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSavingSettings = false);
    }
  }

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
            
            // ✅ UPDATED: Backend-synced notification settings
            if (_isLoadingSettings)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Club News Notifications
              SwitchListTile(
                secondary: const Icon(Icons.newspaper),
                title: const Text('Club News (Email)'),
                subtitle: const Text('Receive club news via email'),
                value: _clubNewsEmail,
                activeColor: colors.primary,
                onChanged: (value) {
                  setState(() => _clubNewsEmail = value);
                  _saveNotificationSettings();
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('Club News (Push)'),
                subtitle: const Text('Receive club news via push notifications'),
                value: _clubNewsPush,
                activeColor: colors.primary,
                onChanged: (value) {
                  setState(() => _clubNewsPush = value);
                  _saveNotificationSettings();
                },
              ),
              
              const Divider(height: 1, indent: 72),
              
              // New Trip Alerts
              SwitchListTile(
                secondary: const Icon(Icons.directions_car),
                title: const Text('New Trip Alerts (Email)'),
                subtitle: const Text('Email alerts for new trips'),
                value: _newTripAlertsEmail,
                activeColor: colors.primary,
                onChanged: (value) {
                  setState(() => _newTripAlertsEmail = value);
                  _saveNotificationSettings();
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.explore),
                title: const Text('New Trip Alerts (Push)'),
                subtitle: const Text('Push notifications for new trips'),
                value: _newTripAlertsPush,
                activeColor: colors.primary,
                onChanged: (value) {
                  setState(() => _newTripAlertsPush = value);
                  _saveNotificationSettings();
                },
              ),
              
              const Divider(height: 1, indent: 72),
              
              // Upgrade Request Reminders
              SwitchListTile(
                secondary: const Icon(Icons.star_outline),
                title: const Text('Upgrade Request Reminders'),
                subtitle: const Text('Email reminders for upgrade requests'),
                value: _upgradeRequestReminderEmail,
                activeColor: colors.primary,
                onChanged: (value) {
                  setState(() => _upgradeRequestReminderEmail = value);
                  _saveNotificationSettings();
                },
              ),
              
              // ✅ Saving indicator
              if (_isSavingSettings)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Saving settings...'),
                    ],
                  ),
                ),
            ],

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
                context.push('/settings/help-support');
              },
            ),
            _SettingsTile(
              icon: Icons.gavel,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms',
              onTap: () {
                context.push('/settings/terms');
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                context.push('/settings/privacy');
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
