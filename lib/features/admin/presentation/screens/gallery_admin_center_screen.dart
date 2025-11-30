import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../providers/gallery_admin_provider.dart';
import '../providers/gallery_admin_activity_provider.dart';

/// Gallery Admin Center Screen
///
/// Centralized gallery management dashboard for board members
/// Accessible by users with edit_trip_media permission
class GalleryAdminCenterScreen extends ConsumerStatefulWidget {
  const GalleryAdminCenterScreen({super.key});

  @override
  ConsumerState<GalleryAdminCenterScreen> createState() =>
      _GalleryAdminCenterScreenState();
}

class _GalleryAdminCenterScreenState
    extends ConsumerState<GalleryAdminCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _activityScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryAdminStatsProvider.notifier).loadStats();
      ref.read(galleryAdminActivityProvider.notifier).loadActivities();
    });

    // Setup infinite scroll for activity feed
    _activityScrollController.addListener(_onActivityScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activityScrollController.dispose();
    super.dispose();
  }

  void _onActivityScroll() {
    if (_activityScrollController.position.pixels >=
        _activityScrollController.position.maxScrollExtent * 0.9) {
      ref.read(galleryAdminActivityProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canManage = user?.hasPermission('edit_trip_media') ?? false;
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery Admin')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Access Denied', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Board Members Only',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 24),
            SizedBox(width: 12),
            Text('Gallery Admin Center'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.photo_library), text: 'Content'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_tabController.index == 0) {
                ref.read(galleryAdminStatsProvider.notifier).refresh();
                ref.read(galleryAdminActivityProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_DashboardTab(), _ContentManagerTab()],
      ),
    );
  }
}

/// Dashboard Tab - System stats, activity feed, quick actions
class _DashboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(galleryAdminStatsProvider);
    final activityState = ref.watch(galleryAdminActivityProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(galleryAdminStatsProvider.notifier).refresh(),
          ref.read(galleryAdminActivityProvider.notifier).refresh(),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Statistics Cards
            Text(
              'System Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (statsState.isLoading && statsState.stats == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (statsState.error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statsState.error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(galleryAdminStatsProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (statsState.stats != null)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    icon: Icons.photo_library,
                    label: 'Total Photos',
                    value: statsState.stats!.totalPhotos.toString(),
                    color: colors.primary,
                  ),
                  _StatCard(
                    icon: Icons.folder,
                    label: 'Galleries',
                    value: statsState.stats!.totalGalleries.toString(),
                    color: colors.secondary,
                  ),
                  _StatCard(
                    icon: Icons.storage,
                    label: 'Storage Used',
                    value: statsState.stats!.storageFormatted,
                    color: colors.tertiary,
                  ),
                  _StatCard(
                    icon: Icons.people,
                    label: 'Total Users',
                    value: statsState.stats!.totalUsers.toString(),
                    color: colors.primary,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickActionButton(
                  icon: Icons.search,
                  label: 'Find Orphans',
                  onPressed: () => _handleFindOrphans(context, ref),
                ),
                _QuickActionButton(
                  icon: Icons.cleaning_services,
                  label: 'Cleanup',
                  onPressed: () => _handleCleanup(context, ref),
                ),
                _QuickActionButton(
                  icon: Icons.tune,
                  label: 'Optimize',
                  onPressed: () => _handleOptimize(context, ref),
                ),
                _QuickActionButton(
                  icon: Icons.list_alt,
                  label: 'Audit Logs',
                  onPressed: () => _handleViewLogs(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activityState.filterType != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filter'),
                    onPressed: () => ref
                        .read(galleryAdminActivityProvider.notifier)
                        .clearFilter(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (activityState.isLoading && activityState.activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (activityState.error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activityState.error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(galleryAdminActivityProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (activityState.activities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: colors.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activityState.activities.length > 10
                    ? 10
                    : activityState.activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = activityState.activities[index];
                  return _ActivityListTile(activity: activity);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFindOrphans(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(galleryApiRepositoryProvider);
      final result = await repository.getOrphanedPhotos();

      final orphanedCount = result['count'] as int? ?? 0;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.search),
            title: const Text('Orphaned Photos'),
            content: Text(
              orphanedCount == 0
                  ? 'No orphaned photos found. All photos belong to galleries.'
                  : 'Found $orphanedCount orphaned photo${orphanedCount == 1 ? '' : 's'}.',
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to find orphaned photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCleanup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange),
        title: const Text('Gallery Cleanup'),
        content: const Text(
          'This will permanently delete galleries that were soft-deleted more than 30 days ago.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final repository = ref.read(galleryApiRepositoryProvider);
      final result = await repository.cleanupGalleries();

      final deletedCount = result['deleted_count'] as int? ?? 0;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cleanup complete: $deletedCount galleries permanently deleted',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh stats
        ref.read(galleryAdminStatsProvider.notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleOptimize(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.tune),
        title: const Text('System Optimization'),
        content: const Text(
          'This will:\n• Optimize database indexes\n• Regenerate missing thumbnails\n• Clean up temporary files\n\nThis may take a few minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Optimize'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Optimizing system...'),
          ],
        ),
      ),
    );

    try {
      final repository = ref.read(galleryApiRepositoryProvider);
      final result = await repository.optimizeSystem();

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] as String? ?? 'Optimization complete',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh stats
        ref.read(galleryAdminStatsProvider.notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Optimization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleViewLogs(BuildContext context, WidgetRef ref) async {
    // TODO: Navigate to dedicated audit logs screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit Logs screen coming soon...')),
    );
  }
}

/// Content Manager Tab - Photo/Gallery management
class _ContentManagerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Management',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photo and gallery management features coming soon',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Under Development',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photo grid and gallery list will be added here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// Activity List Tile Widget
class _ActivityListTile extends StatelessWidget {
  final AdminActivity activity;

  const _ActivityListTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _parseColor(activity.colorHex).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Text(activity.icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        activity.description,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${activity.username} • ${activity.relativeTime}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}
