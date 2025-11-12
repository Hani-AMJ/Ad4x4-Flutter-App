import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/logbook_stats_model.dart';
import '../../../../data/models/logbook_entry_model.dart';
import '../../../../data/models/logbook_skill_model.dart';
import '../../../../data/repositories/api_repository.dart';

/// Logbook Home Screen - Dashboard for all logbook functionality
/// 
/// Features:
/// - Progress summary with level breakdown
/// - Quick action cards to main sections
/// - Recent activity feed
/// - Marshal tools (conditional)
class LogbookHomeScreen extends ConsumerStatefulWidget {
  const LogbookHomeScreen({super.key});

  @override
  ConsumerState<LogbookHomeScreen> createState() => _LogbookHomeScreenState();
}

class _LogbookHomeScreenState extends ConsumerState<LogbookHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  LogbookStats? _stats;
  List<LogbookEntry> _recentEntries = [];
  int _tripCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authProviderV2);
      final userId = authState.user?.id ?? 0;
      
      if (userId == 0) {
        throw Exception('User not authenticated');
      }

      final repository = ref.read(apiRepositoryProvider);

      // Load data in parallel
      final results = await Future.wait([
        _loadSkillsStats(repository, userId),
        _loadRecentEntries(repository, userId),
        _loadTripCount(repository, userId),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard: $e';
      });
    }
  }

  Future<void> _loadSkillsStats(ApiRepository repository, int userId) async {
    try {
      // Get member's skill progress
      final response = await repository.getMemberLogbookSkills(userId);
      final skills = (response['skills'] as List)
          .map((json) => LogbookSkill.fromJson(json))
          .toList();

      // Calculate stats
      final totalSkills = skills.length;
      final verifiedSkills = skills.where((s) => s.isVerified).length;
      final pendingSkills = skills.where((s) => s.isPending).length;
      final rejectedSkills = skills.where((s) => s.isRejected).length;
      final progressPercentage = totalSkills > 0 
          ? (verifiedSkills / totalSkills * 100)
          : 0.0;

      // Calculate level-specific stats
      final levelGroups = <String, List<LogbookSkill>>{};
      for (var skill in skills) {
        final levelName = skill.level.name;
        levelGroups.putIfAbsent(levelName, () => []).add(skill);
      }

      LevelStats _calculateLevelStats(String levelName) {
        final levelSkills = levelGroups[levelName] ?? [];
        final total = levelSkills.length;
        final verified = levelSkills.where((s) => s.isVerified).length;
        final percentage = total > 0 ? (verified / total * 100) : 0.0;
        
        return LevelStats(
          levelName: levelName,
          totalSkills: total,
          verifiedSkills: verified,
          progressPercentage: percentage,
        );
      }

      _stats = LogbookStats(
        totalSkills: totalSkills,
        verifiedSkills: verifiedSkills,
        pendingSkills: pendingSkills,
        rejectedSkills: rejectedSkills,
        progressPercentage: progressPercentage,
        beginnerStats: _calculateLevelStats('Beginner'),
        intermediateStats: _calculateLevelStats('Intermediate'),
        advancedStats: _calculateLevelStats('Advanced'),
        expertStats: _calculateLevelStats('Expert'),
        totalEntries: _recentEntries.length,
        totalTrips: _tripCount,
        recentActivityCount: _recentEntries.length,
      );
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load skills stats: $e');
      }
    }
  }

  Future<void> _loadRecentEntries(ApiRepository repository, int userId) async {
    try {
      final response = await repository.getLogbookEntries(
        memberId: userId,
        ordering: '-created_at',
        limit: 10,
      );
      
      _recentEntries = (response['results'] as List)
          .map((json) => LogbookEntry.fromJson(json))
          .toList();
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load recent entries: $e');
      }
    }
  }

  Future<void> _loadTripCount(ApiRepository repository, int userId) async {
    try {
      final response = await repository.getTripHistory(
        memberId: userId,
        limit: 1,
      );
      _tripCount = response['count'] ?? 0;
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load trip count: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Summary Card
                        _buildProgressSummaryCard(theme, colors),
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(colors, isMarshal),
                        const SizedBox(height: 24),
                        
                        // Recent Activity
                        Text(
                          'Recent Activity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecentActivityList(theme, colors),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressSummaryCard(ThemeData theme, ColorScheme colors) {
    final stats = _stats ?? LogbookStats.empty();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: colors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Logbook Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Overall progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${stats.verifiedSkills} of ${stats.totalSkills} skills verified',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  '${stats.progressPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: stats.progressPercentage / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            
            if (stats.pendingSkills > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.pendingSkills} skills pending review',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Level breakdown
            Text(
              'Progress by Level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLevelProgress(
                  'Beginner',
                  stats.beginnerStats.verifiedSkills,
                  stats.beginnerStats.totalSkills,
                  Colors.green,
                  theme,
                ),
                _buildLevelProgress(
                  'Intermediate',
                  stats.intermediateStats.verifiedSkills,
                  stats.intermediateStats.totalSkills,
                  Colors.blue,
                  theme,
                ),
                _buildLevelProgress(
                  'Advanced',
                  stats.advancedStats.verifiedSkills,
                  stats.advancedStats.totalSkills,
                  Colors.orange,
                  theme,
                ),
                _buildLevelProgress(
                  'Expert',
                  stats.expertStats.verifiedSkills,
                  stats.expertStats.totalSkills,
                  Colors.red,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(
    String label,
    int verified,
    int total,
    Color color,
    ThemeData theme,
  ) {
    final percentage = total > 0 ? (verified / total) : 0.0;
    
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '$verified',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          'of $total',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(ColorScheme colors, bool isMarshal) {
    final stats = _stats ?? LogbookStats.empty();
    
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
        subtitle: '${stats.totalEntries} entries',
        color: const Color(0xFF42B883),
        onTap: () => context.push('/logbook/entries'),
      ),
      _QuickActionData(
        icon: Icons.directions_car,
        title: 'Trip History',
        subtitle: '$_tripCount trips',
        color: const Color(0xFF64B5F6),
        onTap: () => context.push('/logbook/trip-history'),
      ),
      if (isMarshal)
        _QuickActionData(
          icon: Icons.admin_panel_settings,
          title: 'Marshal Tools',
          subtitle: 'Create & approve',
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
        childAspectRatio: 1.3,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 36, color: action.color),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(ThemeData theme, ColorScheme colors) {
    if (_recentEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your logbook entries will appear here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentEntries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _recentEntries[index];
          return _buildActivityTile(entry, colors);
        },
      ),
    );
  }

  Widget _buildActivityTile(LogbookEntry entry, ColorScheme colors) {
    IconData icon;
    Color iconColor;
    
    if (entry.isVerified) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (entry.isPending) {
      icon = Icons.pending;
      iconColor = Colors.orange;
    } else if (entry.isRejected) {
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else {
      icon = Icons.help_outline;
      iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        entry.skill.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.marshalName != null && entry.marshalName!.isNotEmpty)
            Text('Marshal: ${entry.marshalName}'),
          if (entry.tripTitle != null && entry.tripTitle!.isNotEmpty)
            Text('Trip: ${entry.tripTitle}'),
          Text(_formatTimeAgo(entry.createdAt)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to entry details
        _showEntryDetails(entry);
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showEntryDetails(LogbookEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(entry.skill.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Status', entry.statusDisplay),
                _buildDetailRow('Level', entry.skill.level.name),
                if (entry.marshalName != null && entry.marshalName!.isNotEmpty)
                  _buildDetailRow('Marshal', entry.marshalName!),
                if (entry.tripTitle != null && entry.tripTitle!.isNotEmpty)
                  _buildDetailRow('Trip', entry.tripTitle!),
                _buildDetailRow('Date', entry.createdAt.toString().substring(0, 10)),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.notes!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
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
