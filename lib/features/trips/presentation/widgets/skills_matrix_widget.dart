import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/logbook_model.dart';

/// Skills Matrix Widget
/// 
/// Visualizes a member's skill progression across all levels
/// Shows which skills are verified and which are pending
class SkillsMatrixWidget extends ConsumerWidget {
  final List<LogbookEntry> logbookEntries;
  final List<Map<String, dynamic>> allSkills;
  final ColorScheme colors;

  const SkillsMatrixWidget({
    super.key,
    required this.logbookEntries,
    required this.allSkills,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Group skills by level
    final skillsByLevel = _groupSkillsByLevel(allSkills);
    
    // Get all verified skill IDs from logbook entries
    final verifiedSkillIds = logbookEntries
        .expand((entry) => entry.skillsVerified)
        .map((skill) => skill.id)
        .toSet();
    
    // Calculate statistics
    final totalSkills = allSkills.length;
    final verifiedCount = verifiedSkillIds.length;
    final progressPercentage = totalSkills > 0 
        ? (verifiedCount / totalSkills * 100).toInt() 
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with progress
        _buildHeader(theme, verifiedCount, totalSkills, progressPercentage),
        
        const SizedBox(height: 16),
        
        // Progress bar
        _buildProgressBar(progressPercentage),
        
        const SizedBox(height: 24),
        
        // Skills matrix by level
        ...skillsByLevel.entries.map((entry) {
          final level = entry.key;
          final skills = entry.value;
          return _buildLevelSection(theme, level, skills, verifiedSkillIds);
        }),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, int verified, int total, int percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Skills Matrix',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$verified / $total ($percentage%)',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getProgressMessage(percentage),
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _getProgressMessage(int percentage) {
    if (percentage >= 80) return 'Excellent progress! Almost complete.';
    if (percentage >= 60) return 'Great progress! Keep it up.';
    if (percentage >= 40) return 'Good progress! You\'re getting there.';
    if (percentage >= 20) return 'You\'ve started! Continue building skills.';
    return 'Begin your skills journey!';
  }

  Widget _buildLevelSection(
    ThemeData theme,
    String level,
    List<Map<String, dynamic>> skills,
    Set<int> verifiedSkillIds,
  ) {
    final verifiedInLevel = skills
        .where((skill) => verifiedSkillIds.contains(skill['id'] as int))
        .length;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(level).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getLevelColor(level),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(level),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$verifiedInLevel / ${skills.length} completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Skills grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              final skillId = skill['id'] as int;
              final isVerified = verifiedSkillIds.contains(skillId);
              return _buildSkillChip(theme, skill, isVerified);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(ThemeData theme, Map<String, dynamic> skill, bool isVerified) {
    final skillName = skill['name'] as String;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isVerified 
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified 
              ? colors.primary.withValues(alpha: 0.5)
              : colors.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified) ...[
            Icon(
              Icons.check_circle,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              skillName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isVerified 
                    ? colors.onPrimaryContainer
                    : colors.onSurface.withValues(alpha: 0.6),
                fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupSkillsByLevel(
    List<Map<String, dynamic>> skills,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final skill in skills) {
      final level = _extractLevelName(skill['level']);
      if (!grouped.containsKey(level)) {
        grouped[level] = [];
      }
      grouped[level]!.add(skill);
    }
    
    // Sort levels: Beginner, Intermediate, Advanced, Expert
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final order = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
        final aIndex = order.indexOf(a.key);
        final bIndex = order.indexOf(b.key);
        return aIndex.compareTo(bIndex);
      });
    
    return Map.fromEntries(sortedEntries);
  }

  String _extractLevelName(dynamic level) {
    if (level == null) return 'Unspecified';
    
    if (level is String) {
      return level.isEmpty ? 'Unspecified' : level;
    }
    
    if (level is Map) {
      return (level['name'] as String?) ?? 'Unspecified';
    }
    
    return 'Unspecified';
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return colors.tertiary;
      case 'intermediate':
        return const Color(0xFF2196F3); // Blue
      case 'advanced':
        return const Color(0xFFFF9800); // Orange
      case 'expert':
        return const Color(0xFFE91E63); // Pink
      default:
        return colors.outline;
    }
  }
}
