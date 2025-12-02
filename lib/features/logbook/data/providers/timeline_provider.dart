import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../models/timeline_models.dart';

/// Provider for timeline entries
/// Converts logbook entries into timeline entries with milestone detection
/// ✅ CLIENT-SIDE ENRICHMENT: Fetches full objects for member, marshal, skill, trip
/// Backend returns only IDs despite expand parameter, so we enrich client-side
final timelineEntriesProvider = FutureProvider.autoDispose
    .family<List<TimelineEntry>, int?>((ref, memberId) async {
  if (memberId == null) return [];

  // Get logbook entries from repository
  final repository = ref.watch(mainApiRepositoryProvider);
  final response = await repository.getLogbookEntries(
    memberId: memberId,
    pageSize: 200, // Get all entries for timeline
  );

  final entriesResponse = LogbookEntriesResponse.fromJson(response);
  
  if (entriesResponse.results.isEmpty) {
    return [];
  }

  print('🔍 [Timeline] Loaded ${entriesResponse.results.length} entries, starting enrichment...');

  // Collect all unique IDs for batch fetching
  final memberIds = <int>{};
  final marshalIds = <int>{};
  final skillIds = <int>{};
  final tripIds = <int>{};

  for (final entry in entriesResponse.results) {
    // Extract IDs from entries (backend returns only IDs, not objects)
    if (entry.member.id > 0) memberIds.add(entry.member.id);
    if (entry.signedBy.id > 0) marshalIds.add(entry.signedBy.id);
    if (entry.trip?.id != null && entry.trip!.id > 0) tripIds.add(entry.trip!.id);
    for (final skill in entry.skillsVerified) {
      if (skill.id > 0) skillIds.add(skill.id);
    }
  }

  print('🔍 [Timeline] Collected IDs - Members: ${memberIds.length}, Marshals: ${marshalIds.length}, Skills: ${skillIds.length}, Trips: ${tripIds.length}');

  // Fetch all members (includes marshals)
  final allMemberIds = {...memberIds, ...marshalIds};
  final memberCache = <int, MemberBasicInfo>{};
  
  for (final id in allMemberIds) {
    try {
      final memberResponse = await repository.getMemberProfile(id);
      memberCache[id] = MemberBasicInfo.fromJson(memberResponse);
      print('✅ [Timeline] Cached member $id: ${memberCache[id]?.displayName}');
    } catch (e) {
      print('⚠️ [Timeline] Failed to fetch member $id: $e');
      memberCache[id] = MemberBasicInfo(
        id: id,
        firstName: 'Member',
        lastName: '#$id',
      );
    }
  }

  // Fetch all skills
  final skillCache = <int, LogbookSkillBasicInfo>{};
  final skillsResponse = await repository.getLogbookSkills(page: 1, pageSize: 100);
  final skillsData = skillsResponse['results'] as List<dynamic>? ?? [];
  for (final json in skillsData) {
    try {
      final skill = LogbookSkill.fromJson(json as Map<String, dynamic>);
      skillCache[skill.id] = LogbookSkillBasicInfo(
        id: skill.id,
        name: skill.name,
        description: skill.description,
        order: skill.order,
        level: skill.level,
      );
    } catch (e) {
      print('⚠️ [Timeline] Failed to parse skill: $e');
    }
  }
  print('✅ [Timeline] Cached ${skillCache.length} skills');

  // Fetch all trips
  final tripCache = <int, TripBasicInfo>{};
  for (final id in tripIds) {
    try {
      final tripResponse = await repository.getTrip(id);
      tripCache[id] = TripBasicInfo.fromJson(tripResponse);
      print('✅ [Timeline] Cached trip $id: ${tripCache[id]?.title}');
    } catch (e) {
      print('⚠️ [Timeline] Failed to fetch trip $id: $e');
      tripCache[id] = TripBasicInfo(
        id: id,
        title: 'Trip #$id',
        startTime: DateTime.now(),
      );
    }
  }

  // Flatten entries into individual skill verifications with enrichment
  final verifications = <LogbookSkillReference>[];
  
  for (final entry in entriesResponse.results) {
    // Enrich member
    final enrichedMember = memberCache[entry.member.id] ?? entry.member;
    
    // Enrich marshal (signedBy)
    final enrichedMarshal = memberCache[entry.signedBy.id] ?? entry.signedBy;
    
    // Enrich trip
    final enrichedTrip = entry.trip != null ? (tripCache[entry.trip!.id] ?? entry.trip) : null;
    
    // Create verification for each skill in the entry
    for (final skill in entry.skillsVerified) {
      // Enrich skill
      final enrichedSkill = skillCache[skill.id] ?? skill;
      
      verifications.add(LogbookSkillReference(
        id: 0, // Not relevant for timeline
        member: enrichedMember,
        logbookSkill: enrichedSkill,
        trip: enrichedTrip,
        verifiedBy: enrichedMarshal, // ✅ Now has proper marshal name!
        verifiedAt: entry.createdAt,
      ));
    }
  }

  print('✅ [Timeline] Enrichment complete! Created ${verifications.length} skill verifications');

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
