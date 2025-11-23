import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';

/// Logbook Progress Chart Widget
/// 
/// Visualizes skill acquisition progress over time
/// Shows monthly breakdown of skills verified
class LogbookProgressChartWidget extends StatelessWidget {
  final List<LogbookEntry> logbookEntries;
  final ColorScheme colors;

  const LogbookProgressChartWidget({
    super.key,
    required this.logbookEntries,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (logbookEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 64,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No progress data yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group entries by month and count skills
    final monthlyData = _groupEntriesByMonth();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.trending_up, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Progress Over Time',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Summary statistics
        _buildSummaryStats(theme, monthlyData),
        
        const SizedBox(height: 24),
        
        // Progress chart
        _buildProgressChart(theme, monthlyData),
        
        const SizedBox(height: 24),
        
        // Monthly breakdown list
        _buildMonthlyBreakdown(theme, monthlyData),
      ],
    );
  }

  Map<String, MonthlyProgress> _groupEntriesByMonth() {
    final Map<String, MonthlyProgress> monthlyData = {};
    
    for (final entry in logbookEntries) {
      final monthKey = DateFormat('yyyy-MM').format(entry.createdAt);
      final monthName = DateFormat('MMM yyyy').format(entry.createdAt);
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = MonthlyProgress(
          monthKey: monthKey,
          monthName: monthName,
          entries: [],
          skillsVerified: {},
        );
      }
      
      monthlyData[monthKey]!.entries.add(entry);
      for (final skill in entry.skillsVerified) {
        monthlyData[monthKey]!.skillsVerified.add(skill.id);
      }
    }
    
    // Sort by month (oldest first for chart)
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Map.fromEntries(sortedEntries);
  }

  Widget _buildSummaryStats(ThemeData theme, Map<String, MonthlyProgress> monthlyData) {
    final totalMonths = monthlyData.length;
    final totalEntries = logbookEntries.length;
    final totalSkills = logbookEntries
        .expand((entry) => entry.skillsVerified)
        .map((skill) => skill.id)
        .toSet()
        .length;
    
    final avgEntriesPerMonth = totalMonths > 0 ? (totalEntries / totalMonths).toStringAsFixed(1) : '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            icon: Icons.calendar_month,
            label: 'Active Months',
            value: totalMonths.toString(),
            theme: theme,
          ),
          _buildStatColumn(
            icon: Icons.timeline,
            label: 'Avg/Month',
            value: avgEntriesPerMonth,
            theme: theme,
          ),
          _buildStatColumn(
            icon: Icons.workspace_premium,
            label: 'Total Skills',
            value: totalSkills.toString(),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(ThemeData theme, Map<String, MonthlyProgress> monthlyData) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();
    
    final maxSkills = monthlyData.values
        .map((m) => m.skillsVerified.length)
        .reduce((a, b) => a > b ? a : b);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills Verified Per Month',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Bar chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: monthlyData.entries.map((entry) {
                  final progress = entry.value;
                  final skillCount = progress.skillsVerified.length;
                  final heightPercent = maxSkills > 0 ? (skillCount / maxSkills) : 0.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value label
                          Text(
                            skillCount.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Bar
                          Container(
                            height: heightPercent * 150,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Month label
                          RotatedBox(
                            quarterTurns: monthlyData.length > 6 ? 1 : 0,
                            child: Text(
                              DateFormat('MMM').format(
                                DateFormat('yyyy-MM').parse(progress.monthKey)
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
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

  Widget _buildMonthlyBreakdown(ThemeData theme, Map<String, MonthlyProgress> monthlyData) {
    // Show months in reverse order (newest first)
    final reversedData = monthlyData.entries.toList().reversed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ...reversedData.map((entry) {
          final progress = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(
                        DateFormat('yyyy-MM').parse(progress.monthKey)
                      ).toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy').format(
                        DateFormat('yyyy-MM').parse(progress.monthKey)
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                '${progress.skillsVerified.length} skills verified',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${progress.entries.length} logbook ${progress.entries.length == 1 ? 'entry' : 'entries'}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Monthly Progress Data Class
class MonthlyProgress {
  final String monthKey; // yyyy-MM format
  final String monthName; // Display name
  final List<LogbookEntry> entries;
  final Set<int> skillsVerified; // Unique skill IDs

  MonthlyProgress({
    required this.monthKey,
    required this.monthName,
    required this.entries,
    required this.skillsVerified,
  });
}
