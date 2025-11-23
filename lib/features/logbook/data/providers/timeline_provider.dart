import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../models/timeline_models.dart';
import 'skill_verification_history_provider.dart';

/// Provider for timeline entries
/// Converts skill verifications into timeline entries with milestone detection
final timelineEntriesProvider = FutureProvider.autoDispose
    .family<List<TimelineEntry>, int?>((ref, memberId) async {
  // Get verification history
  final verifications = await ref.watch(
      memberSkillVerificationHistoryProvider(memberId).future);

  if (verifications.isEmpty) {
    return [];
  }

  // Sort by date (oldest first for milestone calculation)
  final sortedVerifications = List<LogbookSkillReference>.from(verifications)
    ..sort((a, b) => a.verifiedAt.compareTo(b.verifiedAt));

  final entries = <TimelineEntry>[];
  final levelFirstSkills = <int>{};

  for (int i = 0; i < sortedVerifications.length; i++) {
    final verification = sortedVerifications[i];
    final skillLevel = verification.logbookSkill.level.numericLevel;
    
    TimelineEntryType type = TimelineEntryType.regular;
    bool isMilestone = false;
    String? milestoneText;

    // First skill ever
    if (i == 0) {
      type = TimelineEntryType.firstEver;
      isMilestone = true;
      milestoneText = '🎯 First Skill Verified!';
    }
    // First skill in a new level
    else if (!levelFirstSkills.contains(skillLevel)) {
      type = TimelineEntryType.levelUp;
      isMilestone = true;
      milestoneText = '🏆 First Level $skillLevel Skill!';
      levelFirstSkills.add(skillLevel);
    }
    // Count-based milestones
    else if ((i + 1) % 10 == 0) {
      type = TimelineEntryType.milestone;
      isMilestone = true;
      milestoneText = '⭐ ${i + 1} Skills Verified!';
    } else if ((i + 1) == 5) {
      type = TimelineEntryType.milestone;
      isMilestone = true;
      milestoneText = '⭐ First 5 Skills!';
    }

    entries.add(TimelineEntry(
      verification: verification,
      type: type,
      isMilestone: isMilestone,
      milestoneText: milestoneText,
    ));
  }

  // Return in reverse order (newest first)
  return entries.reversed.toList();
});

/// Provider for timeline periods (grouped by month)
final timelinePeriodsProvider = FutureProvider.autoDispose
    .family<List<TimelinePeriod>, int?>((ref, memberId) async {
  final entries = await ref.watch(timelineEntriesProvider(memberId).future);

  if (entries.isEmpty) {
    return [];
  }

  // Group by month
  final periodMap = <String, List<TimelineEntry>>{};

  for (final entry in entries) {
    final monthKey = DateFormat('yyyy-MM').format(entry.date);
    periodMap.putIfAbsent(monthKey, () => []).add(entry);
  }

  // Convert to TimelinePeriod objects
  final periods = <TimelinePeriod>[];

  for (final monthKey in periodMap.keys.toList()..sort((a, b) => b.compareTo(a))) {
    final entries = periodMap[monthKey]!;
    final date = DateTime.parse('$monthKey-01');
    final label = DateFormat('MMMM yyyy').format(date);

    periods.add(TimelinePeriod(
      startDate: DateTime(date.year, date.month, 1),
      endDate: DateTime(date.year, date.month + 1, 0),
      label: label,
      entries: entries,
      type: TimelinePeriodType.month,
    ));
  }

  return periods;
});

/// Provider for timeline statistics
final timelineStatisticsProvider = FutureProvider.autoDispose
    .family<TimelineStatistics, int?>((ref, memberId) async {
  final entries = await ref.watch(timelineEntriesProvider(memberId).future);

  if (entries.isEmpty) {
    return const TimelineStatistics(
      totalEntries: 0,
      daysActive: 0,
      averageVerificationsPerMonth: 0.0,
      longestStreak: 0,
      verificationsByLevel: {},
      verificationsByMonth: {},
      milestones: [],
    );
  }

  // Sort by date
  final sortedEntries = List<TimelineEntry>.from(entries)
    ..sort((a, b) => a.date.compareTo(b.date));

  final firstDate = sortedEntries.first.date;
  final lastDate = sortedEntries.last.date;

  // Count by level
  final levelCounts = <int, int>{};
  for (final entry in entries) {
    final level = entry.skillLevel;
    levelCounts[level] = (levelCounts[level] ?? 0) + 1;
  }

  // Count by month
  final monthCounts = <String, int>{};
  for (final entry in entries) {
    final monthKey = DateFormat('yyyy-MM').format(entry.date);
    monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
  }

  // Calculate days active (days with at least one verification)
  final activeDays = entries.map((e) {
    final date = e.date;
    return DateTime(date.year, date.month, date.day);
  }).toSet().length;

  // Calculate average per month
  final monthsActive = monthCounts.keys.length;
  final avgPerMonth = monthsActive > 0 ? entries.length / monthsActive : 0.0;

  // Calculate longest streak
  final streak = _calculateLongestStreak(sortedEntries);

  // Collect milestones
  final milestones = entries
      .where((e) => e.isMilestone)
      .map((e) => TimelineMilestone(
            title: e.milestoneText ?? 'Milestone',
            description: e.verification.logbookSkill.name,
            achievedAt: e.date,
            type: _getMilestoneType(e.type),
            relatedSkillLevel: e.skillLevel,
          ))
      .toList();

  return TimelineStatistics(
    totalEntries: entries.length,
    firstVerification: firstDate,
    lastVerification: lastDate,
    daysActive: activeDays,
    averageVerificationsPerMonth: avgPerMonth,
    longestStreak: streak,
    verificationsByLevel: levelCounts,
    verificationsByMonth: monthCounts,
    milestones: milestones,
  );
});

/// Calculate longest verification streak
int _calculateLongestStreak(List<TimelineEntry> sortedEntries) {
  if (sortedEntries.isEmpty) return 0;

  int maxStreak = 1;
  int currentStreak = 1;
  DateTime lastDate = sortedEntries.first.date;

  for (int i = 1; i < sortedEntries.length; i++) {
    final currentDate = sortedEntries[i].date;
    final daysDiff = currentDate.difference(lastDate).inDays;

    if (daysDiff <= 7) {
      // Within a week, continue streak
      currentStreak++;
      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
    } else {
      // Break in streak
      currentStreak = 1;
    }

    lastDate = currentDate;
  }

  return maxStreak;
}

/// Convert timeline entry type to milestone type
MilestoneType _getMilestoneType(TimelineEntryType type) {
  switch (type) {
    case TimelineEntryType.firstEver:
      return MilestoneType.firstSkill;
    case TimelineEntryType.levelUp:
      return MilestoneType.firstLevel;
    case TimelineEntryType.milestone:
      return MilestoneType.skillCount;
    default:
      return MilestoneType.skillCount;
  }
}

/// State notifier for timeline filters
class TimelineFilterNotifier extends StateNotifier<TimelineFilter> {
  TimelineFilterNotifier() : super(const TimelineFilter());

  void setLevelFilter(int? level) {
    state = state.copyWith(skillLevel: level, clearLevel: level == null);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearDates: start == null && end == null,
    );
  }

  void setTripFilter(bool? withTrips) {
    state = state.copyWith(withTrips: withTrips, clearTrips: withTrips == null);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
  }

  void clearAll() {
    state = state.clear();
  }
}

/// Provider for timeline filter state
final timelineFilterProvider =
    StateNotifierProvider.autoDispose<TimelineFilterNotifier, TimelineFilter>(
  (ref) => TimelineFilterNotifier(),
);

/// Provider for filtered timeline entries
final filteredTimelineEntriesProvider = FutureProvider.autoDispose
    .family<List<TimelineEntry>, int?>((ref, memberId) async {
  final allEntries = await ref.watch(timelineEntriesProvider(memberId).future);
  final filter = ref.watch(timelineFilterProvider);

  if (!filter.hasActiveFilters) {
    return allEntries;
  }

  var filtered = allEntries;

  // Filter by level
  if (filter.skillLevel != null) {
    filtered = filtered
        .where((e) => e.skillLevel == filter.skillLevel)
        .toList();
  }

  // Filter by date range
  if (filter.startDate != null || filter.endDate != null) {
    filtered = filtered.where((e) {
      if (filter.startDate != null && e.date.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && e.date.isAfter(filter.endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Filter by trip association
  if (filter.withTrips == true) {
    filtered = filtered
        .where((e) => e.verification.trip != null)
        .toList();
  }

  // Filter by search query
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    filtered = filtered.where((e) {
      return e.verification.logbookSkill.name.toLowerCase().contains(query) ||
          e.verification.verifiedBy.displayName.toLowerCase().contains(query);
    }).toList();
  }

  return filtered;
});
