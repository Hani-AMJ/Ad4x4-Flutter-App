import '../../../../data/models/logbook_model.dart';

/// Skill Verification Certificate Model
/// 
/// Represents a certificate for verified skills with all necessary metadata
class SkillCertificate {
  final String certificateId;
  final MemberBasicInfo member;
  final List<CertifiedSkill> skills;
  final DateTime issueDate;
  final String clubName;
  final String clubLogo;
  final CertificateStats stats;
  final String? notes;

  const SkillCertificate({
    required this.certificateId,
    required this.member,
    required this.skills,
    required this.issueDate,
    required this.clubName,
    required this.clubLogo,
    required this.stats,
    this.notes,
  });

  /// Get certificate title
  String get title {
    if (skills.length == 1) {
      return '${skills.first.skill.name} Certificate';
    } else if (skills.isEmpty) {
      return 'Skills Certificate';
    } else {
      return '${skills.length} Skills Certificate';
    }
  }

  /// Get certificate description
  String get description {
    final levelCounts = <String, int>{};
    for (var skill in skills) {
      final level = skill.skill.level.name;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }
    
    if (levelCounts.isEmpty) return 'No skills';
    
    final parts = levelCounts.entries.map((e) => '${e.value} ${e.key}').toList();
    return parts.join(', ');
  }

  /// Check if certificate is recent (within 30 days)
  bool get isRecent {
    final daysSince = DateTime.now().difference(issueDate).inDays;
    return daysSince <= 30;
  }

  Map<String, dynamic> toJson() {
    return {
      'certificateId': certificateId,
      'member': member.toJson(),
      'skills': skills.map((s) => s.toJson()).toList(),
      'issueDate': issueDate.toIso8601String(),
      'clubName': clubName,
      'clubLogo': clubLogo,
      'stats': stats.toJson(),
      'notes': notes,
    };
  }

  factory SkillCertificate.fromJson(Map<String, dynamic> json) {
    return SkillCertificate(
      certificateId: json['certificateId'] as String,
      member: MemberBasicInfo.fromJson(json['member'] as Map<String, dynamic>),
      skills: (json['skills'] as List)
          .map((s) => CertifiedSkill.fromJson(s as Map<String, dynamic>))
          .toList(),
      issueDate: DateTime.parse(json['issueDate'] as String),
      clubName: json['clubName'] as String,
      clubLogo: json['clubLogo'] as String,
      stats: CertificateStats.fromJson(json['stats'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
    );
  }
}

/// Certified Skill Entry
/// 
/// Individual skill with verification details
class CertifiedSkill {
  final LogbookSkillBasicInfo skill;
  final DateTime verifiedDate;
  final MemberBasicInfo verifiedBy;
  final String? tripName;
  final int? tripId;
  final String? notes;

  const CertifiedSkill({
    required this.skill,
    required this.verifiedDate,
    required this.verifiedBy,
    this.tripName,
    this.tripId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'skill': skill.toJson(),
      'verifiedDate': verifiedDate.toIso8601String(),
      'verifiedBy': verifiedBy.toJson(),
      'tripName': tripName,
      'tripId': tripId,
      'notes': notes,
    };
  }

  factory CertifiedSkill.fromJson(Map<String, dynamic> json) {
    return CertifiedSkill(
      skill: LogbookSkillBasicInfo.fromJson(json['skill'] as Map<String, dynamic>),
      verifiedDate: DateTime.parse(json['verifiedDate'] as String),
      verifiedBy: MemberBasicInfo.fromJson(json['verifiedBy'] as Map<String, dynamic>),
      tripName: json['tripName'] as String?,
      tripId: json['tripId'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Certificate Statistics
/// 
/// Aggregate stats for certificate display
/// UPDATED: Now uses dynamic level mapping instead of hard-coded fields
class CertificateStats {
  final int totalSkills;
  final Map<String, int> skillsByLevel; // Dynamic level counts (e.g., {"Newbie": 5, "Advanced": 10})
  final int uniqueSignOffs; // Number of different marshals who signed off
  final List<String> categories; // Skill categories represented

  const CertificateStats({
    required this.totalSkills,
    required this.skillsByLevel,
    required this.uniqueSignOffs,
    required this.categories,
  });

  // DEPRECATED: Legacy getters for backward compatibility
  @deprecated
  int get beginnerSkills => _getLevelCount('beginner');
  @deprecated
  int get intermediateSkills => _getLevelCount('intermediate');
  @deprecated
  int get advancedSkills => _getLevelCount('advanced');
  @deprecated
  int get expertSkills => _getLevelCount('expert');

  int _getLevelCount(String levelNameFragment) {
    for (var entry in skillsByLevel.entries) {
      if (entry.key.toLowerCase().contains(levelNameFragment)) {
        return entry.value;
      }
    }
    return 0;
  }

  /// Get primary level (most skills)
  String get primaryLevel {
    if (skillsByLevel.isEmpty) return 'No Level';
    
    final sorted = skillsByLevel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSkills': totalSkills,
      'skillsByLevel': skillsByLevel,
      'uniqueSignOffs': uniqueSignOffs,
      'categories': categories,
    };
  }

  factory CertificateStats.fromJson(Map<String, dynamic> json) {
    return CertificateStats(
      totalSkills: json['totalSkills'] as int,
      skillsByLevel: Map<String, int>.from(json['skillsByLevel'] as Map? ?? {}),
      uniqueSignOffs: json['uniqueSignOffs'] as int,
      categories: (json['categories'] as List).cast<String>(),
    );
  }
}

/// Certificate Filter Options
class CertificateFilter {
  final CertificateTimeRange timeRange;
  final Set<int> selectedLevelIds; // 1-4: beginner to expert
  final Set<String> selectedCategories;
  final bool onlyRecent; // Only certificates from last 30 days

  const CertificateFilter({
    this.timeRange = CertificateTimeRange.all,
    this.selectedLevelIds = const {},
    this.selectedCategories = const {},
    this.onlyRecent = false,
  });

  bool get hasActiveFilters {
    return timeRange != CertificateTimeRange.all ||
        selectedLevelIds.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        onlyRecent;
  }

  int get activeFilterCount {
    int count = 0;
    if (timeRange != CertificateTimeRange.all) count++;
    if (selectedLevelIds.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (onlyRecent) count++;
    return count;
  }

  CertificateFilter copyWith({
    CertificateTimeRange? timeRange,
    Set<int>? selectedLevelIds,
    Set<String>? selectedCategories,
    bool? onlyRecent,
  }) {
    return CertificateFilter(
      timeRange: timeRange ?? this.timeRange,
      selectedLevelIds: selectedLevelIds ?? this.selectedLevelIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      onlyRecent: onlyRecent ?? this.onlyRecent,
    );
  }

  CertificateFilter reset() {
    return const CertificateFilter();
  }
}

/// Time Range for Certificate Filtering
enum CertificateTimeRange {
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  all,
}

extension CertificateTimeRangeExtension on CertificateTimeRange {
  String get displayName {
    switch (this) {
      case CertificateTimeRange.lastMonth:
        return 'Last Month';
      case CertificateTimeRange.last3Months:
        return 'Last 3 Months';
      case CertificateTimeRange.last6Months:
        return 'Last 6 Months';
      case CertificateTimeRange.lastYear:
        return 'Last Year';
      case CertificateTimeRange.all:
        return 'All Time';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case CertificateTimeRange.lastMonth:
        return now.subtract(const Duration(days: 30));
      case CertificateTimeRange.last3Months:
        return now.subtract(const Duration(days: 90));
      case CertificateTimeRange.last6Months:
        return now.subtract(const Duration(days: 180));
      case CertificateTimeRange.lastYear:
        return now.subtract(const Duration(days: 365));
      case CertificateTimeRange.all:
        return null;
    }
  }
}
