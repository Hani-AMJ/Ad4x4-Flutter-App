import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import 'package:flutter/foundation.dart'; // V2 - Clean implementation
import '../../../../shared/widgets/widgets.dart';
import '../../../../data/repositories/main_api_repository.dart'; // ✅ NEW
import '../../../../core/services/deletion_state_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ✅ NEW: Repository for backend API calls
  final _repository = MainApiRepository();
  
  // GDPR Account Deletion State
  DeletionStateService? _deletionService;
  
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
    _initializeDeletionService();
    _loadNotificationSettings();
  }
  
  Future<void> _initializeDeletionService() async {
    final prefs = await SharedPreferences.getInstance();
    // CRITICAL: Get current user ID to make deletion state user-specific
    final userId = prefs.getString('user_id');
    setState(() {
      _deletionService = DeletionStateService(prefs, userId: userId);
    });
    
    // Debug logging
    // ignore: avoid_print
    print('🔧 [DeletionService] Initialized for user: $userId');
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
            
            // Deletion Warning Banner
            if (_deletionService?.isDeletionRequested == true) ...[
              _buildDeletionWarningBanner(),
              const SizedBox(height: 16),
            ],
            
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
                activeThumbColor: colors.primary,
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
                activeThumbColor: colors.primary,
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
                activeThumbColor: colors.primary,
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
                activeThumbColor: colors.primary,
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
                activeThumbColor: colors.primary,
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
              activeThumbColor: colors.primary,
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

            // Developer section
            const Divider(height: 32),
            _SectionHeader(title: 'Developer'),
            _SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Error Logs',
              subtitle: 'View app errors and crashes',
              onTap: () {
                context.push('/settings/error-logs');
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
                    onPressed: _deletionService?.isDeletionRequested == true
                        ? null  // Disable button if deletion already requested
                        : () {
                            _showDeleteAccountDialog(context);
                          },
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: _deletionService?.isDeletionRequested == true
                            ? colors.onSurface.withValues(alpha: 0.3)  // Gray out when disabled
                            : colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Show hint text when button is disabled
                  if (_deletionService?.isDeletionRequested == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                      child: Text(
                        'Account deletion already requested. See orange banner above to cancel.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
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
            onPressed: () async {
              // Close confirmation dialog
              Navigator.pop(context);
              if (!context.mounted) return;
              
              // CRITICAL: Capture ScaffoldMessenger BEFORE async operations
              // This ensures we can dismiss the loading SnackBar even if widget unmounts
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Show loading using SnackBar (not Dialog - avoids Navigator.pop issues)
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Processing deletion request...'),
                    ],
                  ),
                  duration: Duration(hours: 1), // Will be dismissed manually
                ),
              );
              
              try {
                final result = await _repository.requestAccountDeletion();
                
                // Production-safe logging
                // ignore: avoid_print
                print('🔍 [DeleteAccount] Backend response: $result');
                // ignore: avoid_print
                print('   Dismissing loading SnackBar...');
                
                // ALWAYS dismiss loading, even if widget unmounted
                scaffoldMessenger.hideCurrentSnackBar();
                
                // ignore: avoid_print
                print('   Loading dismissed!');
                
                // Parse response
                final success = result['success'] == true;
                final message = result['message']?.toString() ?? '';
                final isAlreadyExists = message.contains('already') || 
                                       message == 'deletion_request_already_exists';
                
                // ignore: avoid_print
                print('   success=$success, isAlreadyExists=$isAlreadyExists');
                // ignore: avoid_print
                print('   context.mounted=${context.mounted}');
                
                if (success || isAlreadyExists) {
                  // Update local state (suppress errors - backend is source of truth)
                  try {
                    if (_deletionService != null) {
                      await _deletionService!.setDeletionRequested();
                      // ignore: avoid_print
                      print('   ✅ Local deletion state updated');
                    }
                  } catch (e) {
                    // ignore: avoid_print
                    print('⚠️ [DeleteAccount] Failed to update local state: $e');
                  }
                  
                  // CRITICAL: Force UI refresh to show/hide cancel button
                  // Use postFrameCallback to ensure safe timing
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {});
                      // ignore: avoid_print
                      print('   ✅ UI refreshed - cancel button should now appear');
                    }
                  });
                  
                  // CRITICAL: Show success message EVEN IF WIDGET UNMOUNTED
                  // ScaffoldMessenger persists across route changes
                  final snackBarMessage = isAlreadyExists
                      ? 'A deletion request is already active. You can cancel it below.'
                      : 'Account deletion requested. Your account will be deleted in 30 days.';
                  
                  // ignore: avoid_print
                  print('   📩 Showing success SnackBar: $snackBarMessage');
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(snackBarMessage),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                } else {
                  // Handle error - show message EVEN IF WIDGET UNMOUNTED
                  final errorMessage = message.isNotEmpty ? message : 'Unknown error occurred';
                  
                  // ignore: avoid_print
                  print('   ❌ Showing error SnackBar: $errorMessage');
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to request deletion: $errorMessage'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                // Catch ANY unexpected errors
                // ignore: avoid_print
                print('❌ [DeleteAccount] Unexpected error: $e');
                // ignore: avoid_print
                print('   Stack trace: $stackTrace');
                
                // ALWAYS dismiss loading, even if widget unmounted
                scaffoldMessenger.hideCurrentSnackBar();
                
                if (!context.mounted) return;
                
                // Show error to user
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Unexpected error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
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
  
  Widget _buildDeletionWarningBanner() {
    final colors = Theme.of(context).colorScheme;
    final daysLeft = _deletionService?.daysUntilDeletion;
    final scheduledDate = _deletionService?.formattedDeletionDate;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade900,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Account Deletion Scheduled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scheduledDate != null
                ? 'Your account will be permanently deleted on $scheduledDate.'
                : 'Your account is scheduled for deletion.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
            ),
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 8),
            Text(
              daysLeft <= 0
                  ? 'Deletion is overdue. Please contact support.'
                  : daysLeft == 1
                      ? '1 day remaining'
                      : '$daysLeft days remaining',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: daysLeft <= 7 ? Colors.red.shade700 : Colors.orange.shade700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showCancelDeletionDialog(context);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Deletion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCancelDeletionDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Account Deletion'),
        content: const Text(
          'Are you sure you want to cancel the account deletion request? '
          'Your account will remain active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Deletion'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog
              Navigator.pop(context);
              if (!context.mounted) return;
              
              // CRITICAL: Capture ScaffoldMessenger BEFORE async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Show loading using SnackBar
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Cancelling deletion request...'),
                    ],
                  ),
                  duration: Duration(hours: 1),
                ),
              );
              
              try {
                final result = await _repository.cancelAccountDeletion();
                
                // Production-safe logging
                // ignore: avoid_print
                print('🔍 [CancelDeletion] Backend response: $result');
                
                // ALWAYS dismiss loading
                scaffoldMessenger.hideCurrentSnackBar();
                
                // Parse response
                final success = result['success'] == true;
                final message = result['message']?.toString() ?? '';
                final notFound = message == 'deletion_request_not_found';
                
                if (success || notFound) {
                  // Clear deletion state
                  try {
                    if (_deletionService != null) {
                      await _deletionService!.clearDeletionState();
                      // ignore: avoid_print
                      print('   ✅ Local deletion state cleared');
                    }
                  } catch (e) {
                    // ignore: avoid_print
                    print('⚠️ [CancelDeletion] Failed to clear local state: $e');
                  }
                  
                  // CRITICAL: Force UI refresh to hide cancel button and enable delete button
                  // Use postFrameCallback to ensure safe timing
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {});
                      // ignore: avoid_print
                      print('   ✅ UI refreshed - cancel button should now disappear');
                    }
                  });
                  
                  // Show success message EVEN IF UNMOUNTED
                  final snackBarMessage = notFound
                      ? 'No active deletion request found'
                      : 'Account deletion cancelled successfully';
                  final snackBarColor = notFound ? Colors.orange : Colors.green;
                  
                  // ignore: avoid_print
                  print('   📩 Showing success SnackBar: $snackBarMessage');
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(snackBarMessage),
                      backgroundColor: snackBarColor,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  // Handle error - show message EVEN IF UNMOUNTED
                  final errorMessage = message.isNotEmpty ? message : 'Unknown error occurred';
                  
                  // ignore: avoid_print
                  print('   ❌ Showing error SnackBar: $errorMessage');
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel deletion: $errorMessage'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                // Catch ANY unexpected errors
                // ignore: avoid_print
                print('❌ [CancelDeletion] Unexpected error: $e');
                // ignore: avoid_print
                print('   Stack trace: $stackTrace');
                
                // ALWAYS dismiss loading
                scaffoldMessenger.hideCurrentSnackBar();
                
                // Show error to user EVEN IF UNMOUNTED
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel deletion: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Deletion'),
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
