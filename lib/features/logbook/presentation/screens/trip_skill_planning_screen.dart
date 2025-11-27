import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/trip_skill_planning.dart';
import '../../data/providers/trip_skill_planning_provider.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Trip Skill Planning Screen
/// Shows upcoming trips with skill verification opportunities
class TripSkillPlanningScreen extends ConsumerStatefulWidget {
  const TripSkillPlanningScreen({super.key});

  @override
  ConsumerState<TripSkillPlanningScreen> createState() =>
      _TripSkillPlanningScreenState();
}

class _TripSkillPlanningScreenState
    extends ConsumerState<TripSkillPlanningScreen> {
  TripDifficultyLevel? _selectedDifficulty;
  bool _showOnlyUnverified = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final authState = ref.watch(authProviderV2);
    final user = authState.user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Skill Planning')),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    final tripsAsync = ref.watch(upcomingTripsWithSkillsProvider);
    final statsAsync = ref.watch(tripSkillPlanningStatsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Skill Planning'),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats, theme),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Active Filters
          if (_selectedDifficulty != null || _showOnlyUnverified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedDifficulty != null)
                    Chip(
                      label: Text(_getDifficultyLabel(_selectedDifficulty!)),
                      onDeleted: () {
                        setState(() {
                          _selectedDifficulty = null;
                        });
                      },
                    ),
                  if (_showOnlyUnverified)
                    Chip(
                      label: const Text('Unverified Skills Only'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyUnverified = false;
                        });
                      },
                    ),
                ],
              ),
            ),

          // Trip List
          Expanded(
            child: tripsAsync.when(
              data: (trips) {
                final filteredTrips = _filterTrips(trips);

                if (filteredTrips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          trips.isEmpty
                              ? 'No upcoming trips'
                              : 'No trips match your filters',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (trips.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDifficulty = null;
                                _showOnlyUnverified = false;
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(upcomingTripsWithSkillsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(filteredTrips[index], theme);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading trips',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(error.toString(),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(upcomingTripsWithSkillsProvider);
                      },
                      child: const Text('Retry'),
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

  Widget _buildStatsCard(TripSkillPlanningStats stats, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Planning Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Upcoming Trips',
                    stats.totalUpcomingTrips.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Skill Opportunities',
                    stats.totalSkillOpportunities.toString(),
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTripCard(TripWithSkills tripData, ThemeData theme) {
    final colors = theme.colorScheme;
    final difficultyColor = _getDifficultyColor(tripData.difficultyLevel);
    final difficultyLabel = _getDifficultyLabel(tripData.difficultyLevel);

    final unverifiedSkills = tripData.skillOpportunities
        .where((s) => !s.isVerified)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showTripSkillsDialog(tripData);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Title and Difficulty
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tripData.trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: difficultyColor),
                    ),
                    child: Text(
                      difficultyLabel,
                      style: TextStyle(
                        color: difficultyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Trip Date
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, MMM dd, yyyy • HH:mm')
                        .format(tripData.trip.startTime),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Required Level
              if (tripData.trip.level != null) ...[
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Required: ${tripData.trip.level!.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 4),

              // Skill Opportunities Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unverifiedSkills skill${unverifiedSkills != 1 ? 's' : ''} you can verify',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          if (tripData.skillsAlreadyVerified > 0)
                            Text(
                              '${tripData.skillsAlreadyVerified} already completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: colors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripSkillsDialog(TripWithSkills tripData) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripData.trip.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMMM dd, yyyy')
                            .format(tripData.trip.startTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Skills List or Empty State
                Expanded(
                  child: tripData.skillOpportunities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 64,
                                  color: colors.onSurface.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No skill opportunities',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This trip doesn\'t have any matching skills for your current level.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: tripData.skillOpportunities.length,
                          itemBuilder: (context, index) {
                            final opportunity = tripData.skillOpportunities[index];
                            return _buildSkillOpportunityCard(opportunity);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillOpportunityCard(SkillOpportunity opportunity) {
    final levelColor = _getLevelColor(opportunity.skill.level.numericLevel);
    final opportunityColor = _getOpportunityColor(opportunity.opportunityLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill name and badges
            Row(
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: levelColor),
                  ),
                  child: Text(
                    'L${opportunity.skill.level.numericLevel}',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opportunity.skill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Status indicator
                if (opportunity.isVerified)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else if (!opportunity.meetsPrerequisites)
                  const Icon(Icons.lock, color: Colors.orange, size: 20)
                else
                  Icon(
                    Icons.circle,
                    color: opportunityColor,
                    size: 12,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              opportunity.skill.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Opportunity level
            if (!opportunity.isVerified) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: opportunityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getOpportunityLabel(opportunity.opportunityLevel),
                      style: TextStyle(
                        color: opportunityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (opportunity.isPriority) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.purple),
                          SizedBox(width: 2),
                          Text(
                            'PRIORITY',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Prerequisites warning
            if (!opportunity.meetsPrerequisites) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prerequisites required: ${opportunity.prerequisites.join(", ")}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verification tips
            if (opportunity.canAttempt) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opportunity.verificationTips,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TripWithSkills> _filterTrips(List<TripWithSkills> trips) {
    var filtered = trips;

    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((trip) => trip.difficultyLevel == _selectedDifficulty)
          .toList();
    }

    if (_showOnlyUnverified) {
      filtered = filtered
          .where((trip) =>
              trip.skillOpportunities.any((skill) => !skill.isVerified))
          .toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trips'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trip Difficulty:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedDifficulty == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedDifficulty = null;
                        });
                      },
                    ),
                    for (final difficulty in TripDifficultyLevel.values)
                      FilterChip(
                        label: Text(_getDifficultyLabel(difficulty)),
                        selected: _selectedDifficulty == difficulty,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedDifficulty = selected ? difficulty : null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Show only trips with unverified skills'),
                  value: _showOnlyUnverified,
                  onChanged: (value) {
                    setDialogState(() {
                      _showOnlyUnverified = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDifficulty = null;
                _showOnlyUnverified = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 12),
            Text('Trip Skill Planning'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Plan which skills to verify on upcoming trips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('🟢 High Opportunity - Very likely to verify this skill'),
              SizedBox(height: 6),
              Text('🟡 Medium Opportunity - Possible to verify'),
              SizedBox(height: 6),
              Text('🔴 Low Opportunity - Unlikely but available'),
              SizedBox(height: 12),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text('• Focus on high-opportunity skills for best results'),
              SizedBox(height: 4),
              Text('• Check prerequisites before planning'),
              SizedBox(height: 4),
              Text('• Discuss goals with trip marshal before the trip'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(TripDifficultyLevel difficulty) {
    switch (difficulty) {
      case TripDifficultyLevel.beginner:
        return Colors.green;
      case TripDifficultyLevel.intermediate:
        return Colors.blue;
      case TripDifficultyLevel.advanced:
        return Colors.orange;
      case TripDifficultyLevel.expert:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(TripDifficultyLevel difficulty) {
    switch (difficulty) {
      case TripDifficultyLevel.beginner:
        return 'Beginner';
      case TripDifficultyLevel.intermediate:
        return 'Intermediate';
      case TripDifficultyLevel.advanced:
        return 'Advanced';
      case TripDifficultyLevel.expert:
        return 'Expert';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getOpportunityColor(OpportunityLevel level) {
    switch (level) {
      case OpportunityLevel.high:
        return Colors.green;
      case OpportunityLevel.medium:
        return Colors.orange;
      case OpportunityLevel.low:
        return Colors.red;
    }
  }

  String _getOpportunityLabel(OpportunityLevel level) {
    switch (level) {
      case OpportunityLevel.high:
        return 'High Opportunity';
      case OpportunityLevel.medium:
        return 'Medium Opportunity';
      case OpportunityLevel.low:
        return 'Low Opportunity';
    }
  }
}
