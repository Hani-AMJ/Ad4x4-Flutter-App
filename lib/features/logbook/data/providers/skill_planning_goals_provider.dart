import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/trip_skill_planning.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';

/// Skill Planning Goals Provider
/// 
/// Manages skill verification goals for upcoming trips
/// Uses local storage (SharedPreferences) since backend doesn't have goals endpoint yet
class SkillPlanningGoalsNotifier extends StateNotifier<List<SkillPlanningGoal>> {
  final int memberId;
  static const String _storageKey = 'skill_planning_goals';

  SkillPlanningGoalsNotifier(this.memberId) : super([]) {
    _loadGoals();
  }

  /// Load goals from local storage
  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? goalsJson = prefs.getString('$_storageKey\_$memberId');
      
      if (goalsJson != null) {
        final List<dynamic> goalsList = json.decode(goalsJson);
        final goals = goalsList
            .map((json) => SkillPlanningGoal.fromJson(json))
            .toList();
        
        // Sort by created date (newest first)
        goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        state = goals;
      }
    } catch (e) {
      // If error loading, start with empty list
      state = [];
    }
  }

  /// Save goals to local storage
  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = json.encode(
        state.map((goal) => goal.toJson()).toList(),
      );
      await prefs.setString('$_storageKey\_$memberId', goalsJson);
    } catch (e) {
      // Silently fail - goals will be lost but won't crash app
    }
  }

  /// Create a new goal for a trip
  Future<void> createGoal({
    required int tripId,
    required List<int> targetSkillIds,
    String? notes,
  }) async {
    final newGoal = SkillPlanningGoal(
      id: DateTime.now().millisecondsSinceEpoch, // Use timestamp as ID
      memberId: memberId,
      tripId: tripId,
      targetSkillIds: targetSkillIds,
      notes: notes,
      createdAt: DateTime.now(),
      completed: false,
    );

    state = [newGoal, ...state];
    await _saveGoals();
  }

  /// Update goal's target skills
  Future<void> updateGoalSkills({
    required int goalId,
    required List<int> targetSkillIds,
  }) async {
    state = state.map((goal) {
      if (goal.id == goalId) {
        return SkillPlanningGoal(
          id: goal.id,
          memberId: goal.memberId,
          tripId: goal.tripId,
          targetSkillIds: targetSkillIds,
          notes: goal.notes,
          createdAt: goal.createdAt,
          completed: goal.completed,
        );
      }
      return goal;
    }).toList();
    
    await _saveGoals();
  }

  /// Update goal notes
  Future<void> updateGoalNotes({
    required int goalId,
    String? notes,
  }) async {
    state = state.map((goal) {
      if (goal.id == goalId) {
        return SkillPlanningGoal(
          id: goal.id,
          memberId: goal.memberId,
          tripId: goal.tripId,
          targetSkillIds: goal.targetSkillIds,
          notes: notes,
          createdAt: goal.createdAt,
          completed: goal.completed,
        );
      }
      return goal;
    }).toList();
    
    await _saveGoals();
  }

  /// Mark goal as completed
  Future<void> completeGoal(int goalId) async {
    state = state.map((goal) {
      if (goal.id == goalId) {
        return SkillPlanningGoal(
          id: goal.id,
          memberId: goal.memberId,
          tripId: goal.tripId,
          targetSkillIds: goal.targetSkillIds,
          notes: goal.notes,
          createdAt: goal.createdAt,
          completed: true,
        );
      }
      return goal;
    }).toList();
    
    await _saveGoals();
  }

  /// Delete a goal
  Future<void> deleteGoal(int goalId) async {
    state = state.where((goal) => goal.id != goalId).toList();
    await _saveGoals();
  }

  /// Get goal for a specific trip
  SkillPlanningGoal? getGoalForTrip(int tripId) {
    try {
      return state.firstWhere((goal) => goal.tripId == tripId);
    } catch (e) {
      return null;
    }
  }

  /// Get all goals for member
  List<SkillPlanningGoal> getAllGoals() {
    return state;
  }

  /// Get active (non-completed) goals
  List<SkillPlanningGoal> getActiveGoals() {
    return state.where((goal) => !goal.completed).toList();
  }

  /// Get completed goals
  List<SkillPlanningGoal> getCompletedGoals() {
    return state.where((goal) => goal.completed).toList();
  }

  /// Calculate goal achievement rate
  double calculateAchievementRate() {
    if (state.isEmpty) return 0.0;
    final completed = state.where((goal) => goal.completed).length;
    return (completed / state.length) * 100;
  }
}

/// Provider for skill planning goals
final skillPlanningGoalsProvider = StateNotifierProvider.autoDispose
    .family<SkillPlanningGoalsNotifier, List<SkillPlanningGoal>, int>(
  (ref, memberId) {
    return SkillPlanningGoalsNotifier(memberId);
  },
);

/// Provider for goals statistics
final goalsStatisticsProvider = Provider.autoDispose.family<GoalsStatistics, int>(
  (ref, memberId) {
    final goals = ref.watch(skillPlanningGoalsProvider(memberId));
    
    final totalGoals = goals.length;
    final activeGoals = goals.where((g) => !g.completed).length;
    final completedGoals = goals.where((g) => g.completed).length;
    
    // Calculate total planned skills
    final totalPlannedSkills = goals.fold<int>(
      0,
      (sum, goal) => sum + goal.targetSkillIds.length,
    );
    
    // Achievement rate
    final achievementRate = totalGoals > 0 
        ? (completedGoals / totalGoals) * 100 
        : 0.0;
    
    return GoalsStatistics(
      totalGoals: totalGoals,
      activeGoals: activeGoals,
      completedGoals: completedGoals,
      totalPlannedSkills: totalPlannedSkills,
      achievementRate: achievementRate,
    );
  },
);

/// Goals Statistics
class GoalsStatistics {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int totalPlannedSkills;
  final double achievementRate;

  const GoalsStatistics({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.totalPlannedSkills,
    required this.achievementRate,
  });
}

/// Provider for trip-specific goal
final tripGoalProvider = Provider.autoDispose.family<SkillPlanningGoal?, TripGoalParams>(
  (ref, params) {
    final goals = ref.watch(skillPlanningGoalsProvider(params.memberId));
    try {
      return goals.firstWhere((goal) => goal.tripId == params.tripId);
    } catch (e) {
      return null;
    }
  },
);

/// Parameters for trip goal provider
class TripGoalParams {
  final int memberId;
  final int tripId;

  const TripGoalParams({
    required this.memberId,
    required this.tripId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripGoalParams &&
          runtimeType == other.runtimeType &&
          memberId == other.memberId &&
          tripId == other.tripId;

  @override
  int get hashCode => memberId.hashCode ^ tripId.hashCode;
}
