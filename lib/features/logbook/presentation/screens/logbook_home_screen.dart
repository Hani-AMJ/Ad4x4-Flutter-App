import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../widgets/skills_progress_dashboard.dart';

/// Logbook Home Screen - Dashboard for all logbook functionality
/// 
/// Simplified version - serves as hub for existing logbook features
class LogbookHomeScreen extends ConsumerWidget {
  const LogbookHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final user = authState.user;
    
    // Check if user is marshal (has marshal permissions)
    final isMarshal = user?.hasPermission('access_marshal_panel') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: colors.primary, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Logbook',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your off-road skills progression',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Skills Progress Dashboard
            const SkillsProgressDashboard(),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context, colors, isMarshal),
            const SizedBox(height: 24),
            
            // Info Card
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About Your Logbook',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your logbook tracks skills verified by marshals during trips. Skills are organized into 4 levels: Beginner, Intermediate, Advanced, and Expert.',
                      style: TextStyle(color: colors.onPrimaryContainer),
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

  Widget _buildQuickActionsGrid(BuildContext context, ColorScheme colors, bool isMarshal) {
    final actions = [
      _QuickActionData(
        icon: Icons.grid_view,
        title: 'Skills Matrix',
        subtitle: 'View all skills',
        color: colors.primary,
        onTap: () => context.push('/logbook/skills-matrix'),
      ),
      _QuickActionData(
        icon: Icons.assignment,
        title: 'My Entries',
        subtitle: 'Logbook timeline',
        color: const Color(0xFF42B883),
        onTap: () => context.push('/logbook/entries'),
      ),
      _QuickActionData(
        icon: Icons.directions_car,
        title: 'Trip History',
        subtitle: 'Filter & search',
        color: const Color(0xFF64B5F6),
        onTap: () => context.push('/logbook/trip-history-enhanced'),
      ),
      _QuickActionData(
        icon: Icons.history,
        title: 'Verification History',
        subtitle: 'Sign-offs',
        color: const Color(0xFF7E57C2),
        onTap: () => context.push('/logbook/verification-history'),
      ),
      _QuickActionData(
        icon: Icons.calendar_today,
        title: 'Trip Planning',
        subtitle: 'Plan goals',
        color: const Color(0xFF26A69A),
        onTap: () => context.push('/logbook/trip-planning'),
      ),
      _QuickActionData(
        icon: Icons.timeline,
        title: 'Timeline View',
        subtitle: 'Visual journey',
        color: const Color(0xFFEC407A),
        onTap: () => context.push('/logbook/timeline-visualization'),
      ),
      _QuickActionData(
        icon: Icons.recommend,
        title: 'Recommendations',
        subtitle: 'Suggestions',
        color: const Color(0xFF5E35B1),
        onTap: () => context.push('/logbook/skill-recommendations'),
      ),
      _QuickActionData(
        icon: Icons.card_membership,
        title: 'Certificates',
        subtitle: 'View & share',
        color: const Color(0xFFE91E63),
        onTap: () => context.push('/logbook/certificates'),
      ),
      _QuickActionData(
        icon: Icons.trending_up,
        title: 'Level Upgrades',
        subtitle: 'Request upgrade',
        color: const Color(0xFFFF9800),
        onTap: () => context.push('/logbook/upgrade-requests'),
      ),
      if (isMarshal)
        _QuickActionData(
          icon: Icons.flash_on,
          title: 'Quick Sign-Off',
          subtitle: 'Fast verification',
          color: const Color(0xFF4CAF50),
          onTap: () => context.push('/admin/logbook/quick-signoff'),
        ),
      if (isMarshal)
        _QuickActionData(
          icon: Icons.admin_panel_settings,
          title: 'Marshal Tools',
          subtitle: 'Manage entries',
          color: const Color(0xFF9C27B0),
          onTap: () => context.push('/admin/logbook/entries'),
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,  // Increased from 1.3 for more vertical space
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(action);
      },
    );
  }

  Widget _buildQuickActionCard(_QuickActionData action) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),  // Optimized padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,  // Prevent overflow
            children: [
              Icon(action.icon, size: 32, color: action.color),  // Slightly smaller icon
              const SizedBox(height: 8),
              Text(
                action.title,
                style: const TextStyle(
                  fontSize: 14,  // Reduced from 16
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,  // Allow wrapping
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                style: TextStyle(
                  fontSize: 11,  // Reduced from 12
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 12),
              Text('Logbook Help'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your logbook tracks your off-road skills progression through 4 levels:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildHelpItem('🟢 Beginner', 'Foundation skills for safe off-roading'),
                _buildHelpItem('🔵 Intermediate', 'Advanced techniques and vehicle control'),
                _buildHelpItem('🟠 Advanced', 'Expert-level skills and recovery'),
                _buildHelpItem('🔴 Expert', 'Master-level proficiency'),
                const SizedBox(height: 16),
                const Text(
                  'Skills are verified by marshals during trips. Use the quick actions to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildHelpItem('📖 Skills Matrix', 'View all available skills'),
                _buildHelpItem('📝 My Entries', 'See your logbook history'),
                _buildHelpItem('🚙 Trip History', 'Skills verified per trip'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}

/// Quick action card data class
class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
