/// Skills Comparison Provider
/// 
/// Provides skill comparison data between two members

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../models/skills_comparison.dart';

/// Represents a comparison pair (primary member ID, comparison member ID)
class ComparisonPair {
  final int primaryMemberId;
  final int comparisonMemberId;

  const ComparisonPair(this.primaryMemberId, this.comparisonMemberId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonPair &&
          primaryMemberId == other.primaryMemberId &&
          comparisonMemberId == other.comparisonMemberId;

  @override
  int get hashCode => Object.hash(primaryMemberId, comparisonMemberId);
}

/// Provider for skills comparison between two members
final skillsComparisonProvider = FutureProvider.autoDispose
    .family<SkillsComparison, ComparisonPair>((ref, pair) async {
  final repository = ref.watch(mainApiRepositoryProvider);

  // Fetch all skills
  final skillsResponse = await repository.getLogbookSkills(
    page: 1,
    pageSize: 100,
  );
  final skillsData = skillsResponse['results'] as List<dynamic>;
  final allSkills = skillsData
      .map((json) => LogbookSkill.fromJson(json as Map<String, dynamic>))
      .toList();

  // Fetch primary member's verified skills
  final primarySkillsResponse = await repository.getLogbookSkillReferences(
    memberId: pair.primaryMemberId,
    page: 1,
    pageSize: 100,
  );
  final primaryData = primarySkillsResponse['results'] as List<dynamic>;
  final primaryVerifications = primaryData
      .map((json) => LogbookSkillReference.fromJson(json as Map<String, dynamic>))
      .toList();

  // Fetch comparison member's verified skills
  final comparisonSkillsResponse = await repository.getLogbookSkillReferences(
    memberId: pair.comparisonMemberId,
    page: 1,
    pageSize: 100,
  );
  final comparisonData = comparisonSkillsResponse['results'] as List<dynamic>;
  final comparisonVerifications = comparisonData
      .map((json) => LogbookSkillReference.fromJson(json as Map<String, dynamic>))
      .toList();

  // Create maps for quick lookup
  final primaryVerifiedMap = <int, LogbookSkillReference>{};
  for (final ref in primaryVerifications) {
    primaryVerifiedMap[ref.logbookSkill.id] = ref;
  }

  final comparisonVerifiedMap = <int, LogbookSkillReference>{};
  for (final ref in comparisonVerifications) {
    comparisonVerifiedMap[ref.logbookSkill.id] = ref;
  }

  // Build comparison items
  final comparisonItems = <SkillComparisonItem>[];
  for (final skill in allSkills) {
    final primaryVerified = primaryVerifiedMap.containsKey(skill.id);
    final comparisonVerified = comparisonVerifiedMap.containsKey(skill.id);

    ComparisonStatus status;
    if (primaryVerified && comparisonVerified) {
      status = ComparisonStatus.bothVerified;
    } else if (primaryVerified) {
      status = ComparisonStatus.onlyYouVerified;
    } else if (comparisonVerified) {
      status = ComparisonStatus.onlyThemVerified;
    } else {
      status = ComparisonStatus.noneVerified;
    }

    comparisonItems.add(SkillComparisonItem(
      skill: skill,
      primaryMemberVerified: primaryVerified,
      comparisonMemberVerified: comparisonVerified,
      primaryVerifiedAt: primaryVerified ? primaryVerifiedMap[skill.id]!.verifiedAt : null,
      comparisonVerifiedAt: comparisonVerified ? comparisonVerifiedMap[skill.id]!.verifiedAt : null,
      status: status,
    ));
  }

  // Calculate statistics
  final stats = _calculateStatistics(comparisonItems, allSkills);

  // Get member info (use first verification's member info, or fetch separately)
  final primaryMember = primaryVerifications.isNotEmpty
      ? primaryVerifications.first.member
      : MemberBasicInfo(id: pair.primaryMemberId, firstName: 'Member', lastName: '${pair.primaryMemberId}', level: null);

  final comparisonMember = comparisonVerifications.isNotEmpty
      ? comparisonVerifications.first.member
      : MemberBasicInfo(id: pair.comparisonMemberId, firstName: 'Member', lastName: '${pair.comparisonMemberId}', level: null);

  return SkillsComparison(
    primaryMember: primaryMember,
    comparisonMember: comparisonMember,
    skills: comparisonItems,
    statistics: stats,
  );
});

/// Provider for filtered comparison
final filteredComparisonProvider = FutureProvider.autoDispose
    .family<List<SkillComparisonItem>, ComparisonPair>((ref, pair) async {
  final comparison = await ref.watch(skillsComparisonProvider(pair).future);
  final filter = ref.watch(comparisonFilterProvider);

  if (filter.isEmpty) {
    return comparison.skills;
  }

  return comparison.skills.where((item) {
    // Filter by level
    if (filter.levels != null && !filter.levels!.contains(item.skill.level.numericLevel)) {
      return false;
    }

    // Filter by status
    if (filter.statuses != null && !filter.statuses!.contains(item.status)) {
      return false;
    }

    // Filter by search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      final skillName = item.skill.name.toLowerCase();
      if (!skillName.contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// State provider for comparison filter
final comparisonFilterProvider =
    StateProvider.autoDispose<ComparisonFilter>((ref) {
  return const ComparisonFilter();
});

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate comparison statistics
ComparisonStatistics _calculateStatistics(
  List<SkillComparisonItem> items,
  List<LogbookSkill> allSkills,
) {
  int bothVerified = 0;
  int onlyPrimaryVerified = 0;
  int onlyComparisonVerified = 0;
  int neitherVerified = 0;

  for (final item in items) {
    switch (item.status) {
      case ComparisonStatus.bothVerified:
        bothVerified++;
        break;
      case ComparisonStatus.onlyYouVerified:
        onlyPrimaryVerified++;
        break;
      case ComparisonStatus.onlyThemVerified:
        onlyComparisonVerified++;
        break;
      case ComparisonStatus.noneVerified:
        neitherVerified++;
        break;
    }
  }

  final primaryTotalVerified = bothVerified + onlyPrimaryVerified;
  final comparisonTotalVerified = bothVerified + onlyComparisonVerified;

  final totalSkills = items.length;
  final primaryCompletionPercentage = totalSkills > 0
      ? (primaryTotalVerified / totalSkills) * 100
      : 0.0;
  final comparisonCompletionPercentage = totalSkills > 0
      ? (comparisonTotalVerified / totalSkills) * 100
      : 0.0;

  // Analyze categories
  final primaryCategories = <String, int>{};
  final comparisonCategories = <String, int>{};

  for (final item in items) {
    final category = _getSkillCategory(item.skill.name);
    
    if (item.primaryMemberVerified) {
      primaryCategories[category] = (primaryCategories[category] ?? 0) + 1;
    }
    
    if (item.comparisonMemberVerified) {
      comparisonCategories[category] = (comparisonCategories[category] ?? 0) + 1;
    }
  }

  // Find common strengths (both have high counts)
  final commonStrengths = <String>[];
  final primaryStrengths = <String>[];
  final comparisonStrengths = <String>[];

  for (final category in primaryCategories.keys) {
    final primaryCount = primaryCategories[category] ?? 0;
    final comparisonCount = comparisonCategories[category] ?? 0;

    if (primaryCount >= 3 && comparisonCount >= 3) {
      commonStrengths.add(category);
    } else if (primaryCount >= 3 && comparisonCount < 2) {
      primaryStrengths.add(category);
    }
  }

  for (final category in comparisonCategories.keys) {
    final comparisonCount = comparisonCategories[category] ?? 0;
    final primaryCount = primaryCategories[category] ?? 0;

    if (comparisonCount >= 3 && primaryCount < 2 && !comparisonStrengths.contains(category)) {
      comparisonStrengths.add(category);
    }
  }

  return ComparisonStatistics(
    totalSkills: totalSkills,
    bothVerified: bothVerified,
    onlyPrimaryVerified: onlyPrimaryVerified,
    onlyComparisonVerified: onlyComparisonVerified,
    neitherVerified: neitherVerified,
    primaryTotalVerified: primaryTotalVerified,
    comparisonTotalVerified: comparisonTotalVerified,
    primaryCompletionPercentage: primaryCompletionPercentage,
    comparisonCompletionPercentage: comparisonCompletionPercentage,
    skillsAhead: onlyPrimaryVerified,
    skillsBehind: onlyComparisonVerified,
    commonStrengths: commonStrengths,
    primaryStrengths: primaryStrengths,
    comparisonStrengths: comparisonStrengths,
  );
}

/// Get skill category from skill name
String _getSkillCategory(String skillName) {
  final name = skillName.toLowerCase();
  
  if (name.contains('dune') || name.contains('sand')) {
    return 'Sand Driving';
  }
  if (name.contains('rock') || name.contains('boulder')) {
    return 'Rock Crawling';
  }
  if (name.contains('mud') || name.contains('water')) {
    return 'Mud & Water';
  }
  if (name.contains('recovery') || name.contains('winch') || name.contains('stuck')) {
    return 'Recovery';
  }
  if (name.contains('navigation') || name.contains('map')) {
    return 'Navigation';
  }
  if (name.contains('vehicle') || name.contains('maintenance')) {
    return 'Vehicle Care';
  }
  
  return 'General Skills';
}
