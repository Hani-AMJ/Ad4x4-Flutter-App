import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Dashboard Screen
/// 
/// Main admin panel with sidebar navigation and content area.
/// Only accessible to users with admin permissions.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  final Widget child;

  const AdminDashboardScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isDrawerExpanded = false; // Start collapsed
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Create pulse animation for menu button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start pulsing after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDrawerExpanded) {
        _pulseController.repeat(reverse: true);
        // Stop pulsing after 3 cycles
        Future.delayed(const Duration(milliseconds: 4500), () {
          if (mounted) {
            _pulseController.stop();
            _pulseController.value = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user has ANY admin permission
    final hasAdminAccess = _hasAdminPermission(user);

    if (!hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access the admin panel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDrawerExpanded ? 1.0 : _pulseAnimation.value,
              child: IconButton(
                icon: Icon(_isDrawerExpanded ? Icons.menu_open : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isDrawerExpanded = !_isDrawerExpanded;
                    if (_isDrawerExpanded) {
                      _pulseController.stop();
                      _pulseController.value = 0;
                    }
                  });
                },
                tooltip: _isDrawerExpanded ? 'Collapse Menu' : 'Expand Menu',
              ),
            );
          },
        ),
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: colors.primary),
            const SizedBox(width: 8),
            const Text('Admin Panel'),
          ],
        ),
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primary.withValues(alpha: 0.2),
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user.level?.displayName ?? 'Member',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => context.go('/'),
            tooltip: 'Exit Admin Panel',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isDrawerExpanded ? 240 : 72,
            child: _buildSidebar(context, user, _isDrawerExpanded),
          ),
          
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.outline.withValues(alpha: 0.2),
          ),
          
          // Main Content Area
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  /// Build sidebar navigation
  Widget _buildSidebar(BuildContext context, dynamic user, bool expanded) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentPath = GoRouterState.of(context).matchedLocation;

    // 🔍 DEBUG: Log all user permissions
    print('🔍 [AdminMenu] === PERMISSION DEBUG ===');
    print('🔍 [AdminMenu] User: ${user.displayName} (ID: ${user.id})');
    print('🔍 [AdminMenu] Total permissions: ${user.permissions.length}');
    print('🔍 [AdminMenu] Permissions list:');
    for (var perm in user.permissions) {
      print('🔍 [AdminMenu]   - ${perm.action}');
    }
    
    // Check specific permissions for missing items
    print('🔍 [AdminMenu] === CHECKING SPECIFIC PERMISSIONS ===');
    print('🔍 [AdminMenu] edit_trip_registrations: ${user.hasPermission('edit_trip_registrations')}');
    print('🔍 [AdminMenu] edit_trip_media: ${user.hasPermission('edit_trip_media')}');
    print('🔍 [AdminMenu] delete_trip_comments: ${user.hasPermission('delete_trip_comments')}');
    print('🔍 [AdminMenu] create_trip_report: ${user.hasPermission('create_trip_report')}');
    print('🔍 [AdminMenu] === END DEBUG ===');

    return Container(
      color: colors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Dashboard
          if (user.hasPermission('edit_trips') || 
              user.hasPermission('view_members'))
            _NavItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Dashboard',
              isSelected: currentPath == '/admin/dashboard',
              isExpanded: expanded,
              onTap: () => context.go('/admin/dashboard'),
            ),

          const SizedBox(height: 8),
          
          // Trip Management Section
          if (_hasTripPermissions(user)) ...[
            _SectionHeader(
              label: 'TRIP MANAGEMENT',
              isExpanded: expanded,
            ),
            
            if (user.hasPermission('approve_trip'))
              _NavItem(
                icon: Icons.approval_outlined,
                selectedIcon: Icons.approval,
                label: 'Approval Queue',
                isSelected: currentPath == '/admin/trips/pending',
                isExpanded: expanded,
                onTap: () => context.go('/admin/trips/pending'),
              ),
            
            // All Trips - visible to anyone with trip permissions (NEW: Wizard interface)
            if (_hasTripPermissions(user))
              _NavItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: 'Search Trips',
                isSelected: currentPath == '/admin/trips/wizard',
                isExpanded: expanded,
                onTap: () => context.go('/admin/trips/wizard'),
              ),
            
            if (user.hasPermission('create_trip'))
              _NavItem(
                icon: Icons.add_circle_outline,
                selectedIcon: Icons.add_circle,
                label: 'Create Trip',
                isSelected: currentPath == '/trips/create',
                isExpanded: expanded,
                onTap: () => context.go('/trips/create'),
              ),
            
            // Trip Registrants Management (Phase 3B - moved here for better organization)
            if (user.hasPermission('edit_trip_registrations'))
              _NavItem(
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics,
                label: 'Registration Analytics',
                isSelected: currentPath == '/admin/registration-analytics',
                isExpanded: expanded,
                onTap: () => context.go('/admin/registration-analytics'),
              ),
            
            if (user.hasPermission('edit_trip_registrations'))
              _NavItem(
                icon: Icons.checklist_outlined,
                selectedIcon: Icons.checklist,
                label: 'Bulk Actions',
                isSelected: currentPath == '/admin/bulk-registrations',
                isExpanded: expanded,
                onTap: () => context.go('/admin/bulk-registrations'),
              ),
            
            if (user.hasPermission('edit_trip_registrations'))
              _NavItem(
                icon: Icons.list_outlined,
                selectedIcon: Icons.list,
                label: 'Waitlist',
                isSelected: currentPath == '/admin/waitlist-management',
                isExpanded: expanded,
                onTap: () => context.go('/admin/waitlist-management'),
              ),
            
            // Trip Media & Comments (Phase 3B - moved here for better organization)
            if (user.hasPermission('edit_trip_media'))
              _NavItem(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: 'Trip Media',
                isSelected: currentPath == '/admin/trip-media',
                isExpanded: expanded,
                onTap: () => context.go('/admin/trip-media'),
              ),
            
            if (user.hasPermission('delete_trip_comments'))
              _NavItem(
                icon: Icons.comment_outlined,
                selectedIcon: Icons.comment,
                label: 'Comments',
                isSelected: currentPath == '/admin/comments-moderation',
                isExpanded: expanded,
                onTap: () => context.go('/admin/comments-moderation'),
              ),
            
            // Trip Reports (moved here for better organization)
            if (user.hasPermission('create_trip_report'))
              _NavItem(
                icon: Icons.description_outlined,
                selectedIcon: Icons.description,
                label: 'Trip Reports',
                isSelected: currentPath == '/admin/trip-reports',
                isExpanded: expanded,
                onTap: () => context.go('/admin/trip-reports'),
              ),
            
            const SizedBox(height: 8),
          ],

          // Member Management Section
          if (user.hasPermission('view_members')) ...[
            _SectionHeader(
              label: 'MEMBER MANAGEMENT',
              isExpanded: expanded,
            ),
            
            _NavItem(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: 'All Members',
              isSelected: currentPath == '/admin/members',
              isExpanded: expanded,
              onTap: () => context.go('/admin/members'),
            ),
            
            const SizedBox(height: 8),
          ],

          // Upgrade Requests Section
          if (user.hasPermission('view_upgrade_req')) ...[
            _SectionHeader(
              label: 'UPGRADE REQUESTS',
              isExpanded: expanded,
            ),
            
            _NavItem(
              icon: Icons.upgrade_outlined,
              selectedIcon: Icons.upgrade,
              label: 'Upgrade Requests',
              isSelected: currentPath == '/admin/upgrade-requests',
              isExpanded: expanded,
              onTap: () => context.go('/admin/upgrade-requests'),
            ),
            
            const SizedBox(height: 8),
          ],

          // Marshal Panel Section
          if (_hasMarshalPermissions(user)) ...[
            _SectionHeader(
              label: 'MARSHAL PANEL',
              isExpanded: expanded,
            ),
            
            if (user.hasPermission('create_logbook_entries'))
              _NavItem(
                icon: Icons.book_outlined,
                selectedIcon: Icons.book,
                label: 'Logbook Entries',
                isSelected: currentPath == '/admin/logbook/entries',
                isExpanded: expanded,
                onTap: () => context.go('/admin/logbook/entries'),
              ),
            
            if (user.hasPermission('sign_logbook_skills'))
              _NavItem(
                icon: Icons.verified_outlined,
                selectedIcon: Icons.verified,
                label: 'Sign Off Skills',
                isSelected: currentPath == '/admin/logbook/sign-off',
                isExpanded: expanded,
                onTap: () => context.go('/admin/logbook/sign-off'),
              ),
            
            // Trip Reports moved to Trip Management section
            
            const SizedBox(height: 8),
          ],

          // Content Moderation Section (Phase 3B) - REMOVED, moved to Trip Management

          // Advanced Registration Management Section (Phase 3B) - REMOVED, moved to Trip Management

          // Meeting Points Section
          if (_hasMeetingPointPermissions(user)) ...[
            _SectionHeader(
              label: 'RESOURCES',
              isExpanded: expanded,
            ),
            
            _NavItem(
              icon: Icons.place_outlined,
              selectedIcon: Icons.place,
              label: 'Meeting Points',
              isSelected: currentPath == '/admin/meeting-points',
              isExpanded: expanded,
              onTap: () => context.go('/admin/meeting-points'),
            ),
          ],
        ],
      ),
    );
  }

  /// Check if user has admin permission
  /// 
  /// NEW LOGIC: Allow access to admin panel for Admins, Board Members, and Marshals
  /// Individual actions will be permission-gated inside the tools
  bool _hasAdminPermission(dynamic user) {
    // Check if user has ANY of these common admin/marshal/board permissions
    final adminPermissions = [
      // Trip management (admins, board, marshals)
      'create_trip',
      'create_trip_no_approval_needed',
      'create_trip_with_approval',
      'edit_trips',
      'delete_trips',
      'approve_trip',
      'decline_trip',
      'force_register_member_to_trip',
      'remove_member_from_trip',
      'add_member_from_waitlist',
      'check_in_member',
      'check_out_member',
      'view_trip_registrations',
      'edit_trip_registrations',
      'export_trip_registrants',
      'bypass_level_requirements_for_trip',
      
      // Member management
      'view_members',
      'edit_membership_payments',
      
      // Meeting points
      'create_meeting_points',
      'edit_meeting_points',
      'delete_meeting_points',
      
      // Trip requests
      'approve_trip_request',
      'decline_trip_request',
      
      // Logbook (marshals)
      'create_logbook_entries',
      'sign_logbook_skills',
      
      // Content moderation (Phase 3B)
      'edit_trip_media',
      'delete_trip_comments',
      
      // Advanced registration management (Phase 3B)
      'edit_trip_registrations',
    ];
    
    // Return true if user has ANY of these permissions
    return adminPermissions.any((permission) => user.hasPermission(permission));
  }

  /// Check if user has any trip management permissions
  bool _hasTripPermissions(dynamic user) {
    return user.hasPermission('create_trip') ||
           user.hasPermission('create_trip_no_approval_needed') ||
           user.hasPermission('create_trip_with_approval') ||
           user.hasPermission('edit_trips') ||
           user.hasPermission('delete_trips') ||
           user.hasPermission('approve_trip') ||
           user.hasPermission('decline_trip') ||
           user.hasPermission('view_trip_registrations') ||
           user.hasPermission('edit_trip_registrations');
  }

  bool _hasMeetingPointPermissions(dynamic user) {
    return user.hasPermission('create_meeting_points') ||
           user.hasPermission('edit_meeting_points') ||
           user.hasPermission('delete_meeting_points');
  }

  /// Check if user has any marshal panel permissions
  bool _hasMarshalPermissions(dynamic user) {
    return user.hasPermission('create_logbook_entries') ||
           user.hasPermission('sign_logbook_skills') ||
           user.hasPermission('create_trip_report');
  }

  /// Check if user has any content moderation permissions (Phase 3B)
  bool _hasContentModerationPermissions(dynamic user) {
    return user.hasPermission('edit_trip_media') ||
           user.hasPermission('delete_trip_comments');
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isExpanded;

  const _SectionHeader({
    required this.label,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!isExpanded) {
      return const Divider(height: 1);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Navigation Item Widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? badge;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? colors.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colors.onPrimaryContainer
                      : colors.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? colors.onPrimaryContainer
                            : colors.onSurface.withValues(alpha: 0.9),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
