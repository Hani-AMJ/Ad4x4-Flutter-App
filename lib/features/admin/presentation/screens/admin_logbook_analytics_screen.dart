import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';

/// Admin Logbook Analytics Screen
/// 
/// Comprehensive dashboard for logbook system analytics
/// Shows system-wide statistics, trends, and insights
class AdminLogbookAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminLogbookAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminLogbookAnalyticsScreen> createState() => 
      _AdminLogbookAnalyticsScreenState();
}

class _AdminLogbookAnalyticsScreenState 
    extends ConsumerState<AdminLogbookAnalyticsScreen> {
  bool _isLoading = false;
  String? _error;
  
  // Analytics data
  List<LogbookEntry> _allEntries = [];
  List<Map<String, dynamic>> _allSkills = [];
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load all logbook entries
      final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
      final entriesResults = entriesResponse['results'] as List;
      final entries = entriesResults
          .map((json) {
            try {
              return LogbookEntry.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Failed to parse logbook entry: $e');
              }
              return null;
            }
          })
          .whereType<LogbookEntry>()
          .toList();
      
      // Load all skills
      final skillsResponse = await repository.getLogbookSkills(pageSize: 100);
      final skillsResults = skillsResponse['results'] as List;
      
      // Calculate analytics
      final analytics = _calculateAnalytics(entries, skillsResults.cast<Map<String, dynamic>>());
      
      setState(() {
        _allEntries = entries;
        _allSkills = skillsResults.cast<Map<String, dynamic>>();
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateAnalytics(
    List<LogbookEntry> entries,
    List<Map<String, dynamic>> skills,
  ) {
    // Total counts
    final totalEntries = entries.length;
    final totalSkills = skills.length;
    
    // Unique members and marshals
    final uniqueMembers = entries
        .map((e) => e.member.id)
        .toSet()
        .length;
    
    final uniqueMarshals = entries
        .map((e) => e.signedBy.id)
        .toSet()
        .length;
    
    // Skills verified statistics
    final allVerifiedSkills = entries
        .expand((e) => e.skillsVerified)
        .toList();
    
    final uniqueSkillsVerified = allVerifiedSkills
        .map((s) => s.id)
        .toSet()
        .length;
    
    final totalSkillVerifications = allVerifiedSkills.length;
    final avgSkillsPerEntry = totalEntries > 0 
        ? (totalSkillVerifications / totalEntries).toStringAsFixed(1)
        : '0';
    
    // Time-based analytics
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final entriesLast30Days = entries
        .where((e) => e.createdAt.isAfter(last30Days))
        .length;
    
    final entriesLast7Days = entries
        .where((e) => e.createdAt.isAfter(last7Days))
        .length;
    
    // Most active marshal
    final marshalActivity = <int, int>{};
    for (final entry in entries) {
      marshalActivity[entry.signedBy.id] = 
          (marshalActivity[entry.signedBy.id] ?? 0) + 1;
    }
    
    String? mostActiveMarshal;
    int maxActivity = 0;
    for (final entry in entries) {
      final activity = marshalActivity[entry.signedBy.id] ?? 0;
      if (activity > maxActivity) {
        maxActivity = activity;
        mostActiveMarshal = entry.signedBy.displayName;
      }
    }
    
    // Skill popularity
    final skillVerificationCounts = <int, int>{};
    for (final skill in allVerifiedSkills) {
      skillVerificationCounts[skill.id] = 
          (skillVerificationCounts[skill.id] ?? 0) + 1;
    }
    
    final sortedSkillCounts = skillVerificationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topSkills = sortedSkillCounts.take(5).map((entry) {
      final skillData = allVerifiedSkills
          .firstWhere((s) => s.id == entry.key);
      return {
        'name': skillData.name,
        'count': entry.value,
      };
    }).toList();
    
    // Growth trend (last 6 months)
    final monthlyGrowth = <String, int>{};
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    
    for (final entry in entries) {
      if (entry.createdAt.isAfter(sixMonthsAgo)) {
        final monthKey = DateFormat('yyyy-MM').format(entry.createdAt);
        monthlyGrowth[monthKey] = (monthlyGrowth[monthKey] ?? 0) + 1;
      }
    }
    
    return {
      'totalEntries': totalEntries,
      'totalSkills': totalSkills,
      'uniqueMembers': uniqueMembers,
      'uniqueMarshals': uniqueMarshals,
      'uniqueSkillsVerified': uniqueSkillsVerified,
      'totalSkillVerifications': totalSkillVerifications,
      'avgSkillsPerEntry': avgSkillsPerEntry,
      'entriesLast30Days': entriesLast30Days,
      'entriesLast7Days': entriesLast7Days,
      'mostActiveMarshal': mostActiveMarshal,
      'maxActivity': maxActivity,
      'topSkills': topSkills,
      'monthlyGrowth': monthlyGrowth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colors),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnalyticsData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, colors),
          
          const SizedBox(height: 24),
          
          // Key metrics cards
          _buildKeyMetrics(theme, colors),
          
          const SizedBox(height: 24),
          
          // Activity overview
          _buildActivityOverview(theme, colors),
          
          const SizedBox(height: 24),
          
          // Top skills chart
          _buildTopSkillsChart(theme, colors),
          
          const SizedBox(height: 24),
          
          // Growth trend
          _buildGrowthTrend(theme, colors),
          
          const SizedBox(height: 24),
          
          // Quick actions
          _buildQuickActions(theme, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.primaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 48, color: colors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Analytics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comprehensive logbook system overview',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              icon: Icons.receipt_long,
              label: 'Total Entries',
              value: _analytics['totalEntries']?.toString() ?? '0',
              color: const Color(0xFF2196F3),
              theme: theme,
            ),
            _buildMetricCard(
              icon: Icons.people,
              label: 'Active Members',
              value: _analytics['uniqueMembers']?.toString() ?? '0',
              color: const Color(0xFF4CAF50),
              theme: theme,
            ),
            _buildMetricCard(
              icon: Icons.verified,
              label: 'Skills Verified',
              value: _analytics['totalSkillVerifications']?.toString() ?? '0',
              color: const Color(0xFF9C27B0),
              theme: theme,
            ),
            _buildMetricCard(
              icon: Icons.psychology,
              label: 'Unique Skills',
              value: '${_analytics['uniqueSkillsVerified']}/${_analytics['totalSkills']}',
              color: const Color(0xFFFF9800),
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
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
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOverview(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Activity Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildActivityRow(
              'Last 7 Days',
              _analytics['entriesLast7Days']?.toString() ?? '0',
              'entries',
              colors.primary,
              theme,
            ),
            const Divider(),
            _buildActivityRow(
              'Last 30 Days',
              _analytics['entriesLast30Days']?.toString() ?? '0',
              'entries',
              colors.secondary,
              theme,
            ),
            const Divider(),
            _buildActivityRow(
              'Avg Skills/Entry',
              _analytics['avgSkillsPerEntry']?.toString() ?? '0',
              'skills',
              colors.tertiary,
              theme,
            ),
            
            if (_analytics['mostActiveMarshal'] != null) ...[
              const Divider(),
              _buildActivityRow(
                'Most Active Marshal',
                _analytics['mostActiveMarshal'] as String,
                '${_analytics['maxActivity']} entries',
                const Color(0xFFE91E63),
                theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(
    String label,
    String value,
    String subtitle,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkillsChart(ThemeData theme, ColorScheme colors) {
    final topSkills = _analytics['topSkills'] as List? ?? [];
    
    if (topSkills.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final maxCount = topSkills.first['count'] as int;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Skills',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...topSkills.map((skill) {
              final name = skill['name'] as String;
              final count = skill['count'] as int;
              final percentage = maxCount > 0 ? (count / maxCount) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthTrend(ThemeData theme, ColorScheme colors) {
    final monthlyGrowth = _analytics['monthlyGrowth'] as Map<String, dynamic>? ?? {};
    
    if (monthlyGrowth.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final sortedMonths = monthlyGrowth.keys.toList()..sort();
    final maxValue = monthlyGrowth.values.reduce((a, b) => a > b ? a : b) as int;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  '6-Month Growth Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: sortedMonths.map((monthKey) {
                  final count = monthlyGrowth[monthKey] as int;
                  final heightPercent = maxValue > 0 ? (count / maxValue) : 0.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            count.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: heightPercent * 80,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM').format(
                              DateFormat('yyyy-MM').parse(monthKey)
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.people, color: colors.primary),
                title: const Text('Member Skills Report'),
                subtitle: const Text('View all members and their progress'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/admin/logbook/member-skills');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.person_pin, color: colors.secondary),
                title: const Text('Marshal Activity Report'),
                subtitle: const Text('Track marshal sign-off activity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/admin/logbook/marshal-activity');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.settings, color: colors.tertiary),
                title: const Text('Bulk Operations'),
                subtitle: const Text('Manage skills in bulk'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/admin/logbook/bulk-operations');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.download, color: const Color(0xFFFF9800)),
                title: const Text('Export Data'),
                subtitle: const Text('Download reports as CSV'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/admin/logbook/export');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.history, color: const Color(0xFFE91E63)),
                title: const Text('Logbook History'),
                subtitle: const Text('View chronological sign-off timeline'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/admin/logbook/audit-log');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
