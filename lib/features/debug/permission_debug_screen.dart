import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider_v2.dart';

/// Permission Debug Screen
/// 
/// Shows current user's permissions for debugging admin access issues.
class PermissionDebugScreen extends ConsumerWidget {
  const PermissionDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProviderV2);
    final user = authState.user;

    // Check admin access with CORRECT permissions (verified from backend API)
    // Reference: CORRECT_PERMISSIONS_REFERENCE.md
    final hasAdminAccess = user != null &&
        (user.hasPermission('approve_trip') ||              // Trip approval
            user.hasPermission('edit_trips') ||             // Trip management
            user.hasPermission('delete_trips') ||           // Trip deletion
            user.hasPermission('view_members') ||           // View members
            user.hasPermission('create_meeting_points') ||  // Meeting points (plural!)
            user.hasPermission('edit_meeting_points') ||    // Meeting points (plural!)
            user.hasPermission('delete_meeting_points') ||  // Meeting points (plural!)
            user.hasPermission('edit_trip_registrations') || // Registration management
            user.hasPermission('delete_trip_comments') ||   // Comment moderation
            user.hasPermission('edit_trip_media'));         // Media moderation

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              ref.read(authProviderV2.notifier).refreshProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile refreshed')),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow('ID', '${user.id}'),
                          _InfoRow('Username', user.username),
                          _InfoRow('Email', user.email),
                          _InfoRow('Name', user.displayName),
                          if (user.level != null)
                            _InfoRow('Level', user.level!.name),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Access Status Card
                  Card(
                    color: hasAdminAccess ? Colors.green.shade50 : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasAdminAccess ? Icons.check_circle : Icons.cancel,
                                color: hasAdminAccess ? Colors.green : Colors.red,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  hasAdminAccess
                                      ? 'Admin Access: GRANTED'
                                      : 'Admin Access: DENIED',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: hasAdminAccess ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasAdminAccess
                                ? 'You should see the Admin Panel button on home screen'
                                : 'You need at least one of these permissions to access admin panel',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Required Permissions Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Admin Permissions (CORRECTED)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Any ONE of these permissions grants admin access:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Trip Management
                          _PermissionCheck(user, 'approve_trip', 'Approve Trips'),
                          _PermissionCheck(user, 'edit_trips', 'Edit Trips'),
                          _PermissionCheck(user, 'delete_trips', 'Delete Trips'),
                          const Divider(height: 24),
                          // Member Management
                          _PermissionCheck(user, 'view_members', 'View Members'),
                          const Divider(height: 24),
                          // Meeting Points (note: PLURAL forms!)
                          _PermissionCheck(user, 'create_meeting_points', 'Create Meeting Points'),
                          _PermissionCheck(user, 'edit_meeting_points', 'Edit Meeting Points'),
                          _PermissionCheck(user, 'delete_meeting_points', 'Delete Meeting Points'),
                          const Divider(height: 24),
                          // Content Moderation
                          _PermissionCheck(user, 'edit_trip_registrations', 'Edit Registrations'),
                          _PermissionCheck(user, 'delete_trip_comments', 'Delete Comments'),
                          _PermissionCheck(user, 'edit_trip_media', 'Edit Trip Media'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // All Permissions Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Your Permissions (${user.permissions.length})',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy all permissions',
                                onPressed: () {
                                  final permissionsList = user.permissions
                                      .map((p) => p.action)
                                      .join('\n');
                                  Clipboard.setData(ClipboardData(text: permissionsList));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Permissions copied to clipboard'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (user.permissions.isEmpty)
                            const Text('No permissions assigned')
                          else
                            ...user.permissions.map((permission) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        permission.action,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'How to Access Admin Panel',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InstructionStep(
                            '1',
                            'Look at "Admin Access" status above',
                          ),
                          _InstructionStep(
                            '2',
                            'If GRANTED: Go to Home screen and look for the Admin Panel icon (⚙️) in the top-right corner',
                          ),
                          _InstructionStep(
                            '3',
                            'Alternatively, find "Admin Panel" card in Quick Actions section',
                          ),
                          _InstructionStep(
                            '4',
                            'If DENIED: Contact an administrator to grant you the required permissions',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _PermissionCheck extends StatelessWidget {
  final dynamic user;
  final String permissionAction;
  final String displayName;

  const _PermissionCheck(this.user, this.permissionAction, this.displayName);

  @override
  Widget build(BuildContext context) {
    final hasPermission = user.hasPermission(permissionAction);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                color: hasPermission ? Colors.black : Colors.grey,
                fontWeight: hasPermission ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            permissionAction,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue.shade900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
