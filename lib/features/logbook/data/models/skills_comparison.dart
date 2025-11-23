/// Skills Matrix Comparison Models
/// 
/// Data structures for comparing skill verification between members

import '../../../../data/models/logbook_model.dart';

/// Comparison between two members' skill verification status
class SkillsComparison {
  final MemberBasicInfo primaryMember;
  final MemberBasicInfo comparisonMember;
  final List<SkillComparisonItem> skills;
  final ComparisonStatistics statistics;

  const SkillsComparison({
    required this.primaryMember,
    required this.comparisonMember,
    required this.skills,
    required this.statistics,
  });
}

/// Individual skill comparison between two members
class SkillComparisonItem {
  final LogbookSkill skill;
  final bool primaryMemberVerified;
  final bool comparisonMemberVerified;
  final DateTime? primaryVerifiedAt;
  final DateTime? comparisonVerifiedAt;
  final ComparisonStatus status;

  const SkillComparisonItem({
    required this.skill,
    required this.primaryMemberVerified,
    required this.comparisonMemberVerified,
    this.primaryVerifiedAt,
    this.comparisonVerifiedAt,
    required this.status,
  });

  /// Who verified first?
  String? get whoVerifiedFirst {
    if (primaryVerifiedAt == null || comparisonVerifiedAt == null) {
      return null;
    }
    return primaryVerifiedAt!.isBefore(comparisonVerifiedAt!)
        ? 'You'
        : 'Them';
  }

  /// Days difference between verifications
  int? get daysDifference {
    if (primaryVerifiedAt == null || comparisonVerifiedAt == null) {
      return null;
    }
    return primaryVerifiedAt!.difference(comparisonVerifiedAt!).inDays.abs();
  }
}

/// Comparison status for a skill
enum ComparisonStatus {
  bothVerified,    // Both members have verified this skill
  onlyYouVerified, // Only primary member has verified
  onlyThemVerified, // Only comparison member has verified
  noneVerified,    // Neither member has verified
}

extension ComparisonStatusExtension on ComparisonStatus {
  String get displayName {
    switch (this) {
      case ComparisonStatus.bothVerified:
        return 'Both Verified';
      case ComparisonStatus.onlyYouVerified:
        return 'Only You';
      case ComparisonStatus.onlyThemVerified:
        return 'Only Them';
      case ComparisonStatus.noneVerified:
        return 'None Verified';
    }
  }

  String get icon {
    switch (this) {
      case ComparisonStatus.bothVerified:
        return '✅';
      case ComparisonStatus.onlyYouVerified:
        return '🟢';
      case ComparisonStatus.onlyThemVerified:
        return '🔵';
      case ComparisonStatus.noneVerified:
        return '⚪';
    }
  }

  String get description {
    switch (this) {
      case ComparisonStatus.bothVerified:
        return 'Both members have verified this skill';
      case ComparisonStatus.onlyYouVerified:
        return 'You have verified, they have not';
      case ComparisonStatus.onlyThemVerified:
        return 'They have verified, you have not';
      case ComparisonStatus.noneVerified:
        return 'Neither member has verified this skill';
    }
  }
}

/// Statistics about the comparison
class ComparisonStatistics {
  final int totalSkills;
  final int bothVerified;
  final int onlyPrimaryVerified;
  final int onlyComparisonVerified;
  final int neitherVerified;
  
  final int primaryTotalVerified;
  final int comparisonTotalVerified;
  
  final double primaryCompletionPercentage;
  final double comparisonCompletionPercentage;
  
  final int skillsAhead; // How many more skills primary has
  final int skillsBehind; // How many more skills comparison has
  
  final List<String> commonStrengths; // Categories both excel in
  final List<String> primaryStrengths; // Categories primary excels in
  final List<String> comparisonStrengths; // Categories comparison excels in

  const ComparisonStatistics({
    required this.totalSkills,
    required this.bothVerified,
    required this.onlyPrimaryVerified,
    required this.onlyComparisonVerified,
    required this.neitherVerified,
    required this.primaryTotalVerified,
    required this.comparisonTotalVerified,
    required this.primaryCompletionPercentage,
    required this.comparisonCompletionPercentage,
    required this.skillsAhead,
    required this.skillsBehind,
    required this.commonStrengths,
    required this.primaryStrengths,
    required this.comparisonStrengths,
  });

  /// Get comparison message
  String get comparisonMessage {
    if (skillsAhead > skillsBehind) {
      return 'You are ahead by ${skillsAhead - skillsBehind} skills';
    } else if (skillsBehind > skillsAhead) {
      return 'They are ahead by ${skillsBehind - skillsAhead} skills';
    } else {
      return 'You both have the same number of verified skills';
    }
  }

  /// Get motivational message
  String get motivationalMessage {
    if (onlyComparisonVerified > 0) {
      return 'You can learn $onlyComparisonVerified skill${onlyComparisonVerified > 1 ? 's' : ''} from them!';
    } else if (onlyPrimaryVerified > 0) {
      return 'You can share knowledge about $onlyPrimaryVerified skill${onlyPrimaryVerified > 1 ? 's' : ''}!';
    } else {
      return 'Great teamwork! You both have similar skills.';
    }
  }
}

/// Filter for comparison view
class ComparisonFilter {
  final List<int>? levels; // Filter by skill level
  final List<ComparisonStatus>? statuses; // Filter by verification status
  final String? searchQuery; // Search in skill names

  const ComparisonFilter({
    this.levels,
    this.statuses,
    this.searchQuery,
  });

  /// Check if filter is empty
  bool get isEmpty =>
      levels == null &&
      statuses == null &&
      (searchQuery == null || searchQuery!.isEmpty);

  /// Create filter with updated values
  ComparisonFilter copyWith({
    List<int>? levels,
    List<ComparisonStatus>? statuses,
    String? searchQuery,
  }) {
    return ComparisonFilter(
      levels: levels ?? this.levels,
      statuses: statuses ?? this.statuses,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clear all filters
  ComparisonFilter clear() {
    return const ComparisonFilter();
  }
}
