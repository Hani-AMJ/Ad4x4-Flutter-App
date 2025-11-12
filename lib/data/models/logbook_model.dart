/// Logbook Models
/// 
/// Models for logbook entries, skills, and skill references

// ============================================================================
// LOGBOOK ENTRY
// ============================================================================

/// Logbook Entry Model
/// Represents a single logbook entry for a member after completing a trip
class LogbookEntry {
  final int id;
  final MemberBasicInfo member;
  final TripBasicInfo? trip;
  final MemberBasicInfo signedBy;
  final List<LogbookSkillBasicInfo> skillsVerified;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LogbookEntry({
    required this.id,
    required this.member,
    this.trip,
    required this.signedBy,
    required this.skillsVerified,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    return LogbookEntry(
      id: json['id'] as int,
      member: MemberBasicInfo.fromJson(json['member'] as Map<String, dynamic>),
      trip: json['trip'] != null 
          ? TripBasicInfo.fromJson(json['trip'] as Map<String, dynamic>)
          : null,
      signedBy: MemberBasicInfo.fromJson(json['signedBy'] as Map<String, dynamic>),
      skillsVerified: (json['skillsVerified'] as List<dynamic>?)
          ?.map((s) => LogbookSkillBasicInfo.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      if (trip != null) 'trip': trip!.toJson(),
      'signedBy': signedBy.toJson(),
      'skillsVerified': skillsVerified.map((s) => s.toJson()).toList(),
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// ============================================================================
// LOGBOOK SKILL
// ============================================================================

/// Logbook Skill Model
/// Represents a skill that can be verified in the logbook system
class LogbookSkill {
  final int id;
  final String name;
  final String description;
  final LevelBasicInfo level;
  final int order;
  final bool active;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LogbookSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.order,
    required this.active,
    required this.createdAt,
    this.updatedAt,
  });

  factory LogbookSkill.fromJson(Map<String, dynamic> json) {
    return LogbookSkill(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      level: LevelBasicInfo.fromJson(json['level'] as Map<String, dynamic>),
      order: json['order'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.toJson(),
      'order': order,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// ============================================================================
// MEMBER SKILL STATUS
// ============================================================================

/// Member Skill Status Model
/// Represents the status of a specific skill for a specific member
class MemberSkillStatus {
  final int id;
  final LogbookSkillBasicInfo skill;
  final bool verified;
  final MemberBasicInfo? verifiedBy;
  final DateTime? verifiedAt;
  final TripBasicInfo? verifiedOnTrip;
  final String? comment;

  const MemberSkillStatus({
    required this.id,
    required this.skill,
    required this.verified,
    this.verifiedBy,
    this.verifiedAt,
    this.verifiedOnTrip,
    this.comment,
  });

  factory MemberSkillStatus.fromJson(Map<String, dynamic> json) {
    return MemberSkillStatus(
      id: json['id'] as int,
      skill: LogbookSkillBasicInfo.fromJson(json['skill'] as Map<String, dynamic>),
      verified: json['verified'] as bool? ?? false,
      verifiedBy: json['verifiedBy'] != null
          ? MemberBasicInfo.fromJson(json['verifiedBy'] as Map<String, dynamic>)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      verifiedOnTrip: json['verifiedOnTrip'] != null
          ? TripBasicInfo.fromJson(json['verifiedOnTrip'] as Map<String, dynamic>)
          : null,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill.toJson(),
      'verified': verified,
      if (verifiedBy != null) 'verifiedBy': verifiedBy!.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
      if (verifiedOnTrip != null) 'verifiedOnTrip': verifiedOnTrip!.toJson(),
      if (comment != null) 'comment': comment,
    };
  }
}

// ============================================================================
// LOGBOOK SKILL REFERENCE
// ============================================================================

/// Logbook Skill Reference Model
/// Links a member to a verified skill with trip and marshal information
class LogbookSkillReference {
  final int id;
  final MemberBasicInfo member;
  final LogbookSkillBasicInfo logbookSkill;
  final TripBasicInfo? trip;
  final MemberBasicInfo verifiedBy;
  final DateTime verifiedAt;
  final String? comment;

  const LogbookSkillReference({
    required this.id,
    required this.member,
    required this.logbookSkill,
    this.trip,
    required this.verifiedBy,
    required this.verifiedAt,
    this.comment,
  });

  factory LogbookSkillReference.fromJson(Map<String, dynamic> json) {
    return LogbookSkillReference(
      id: json['id'] as int,
      member: MemberBasicInfo.fromJson(json['member'] as Map<String, dynamic>),
      logbookSkill: LogbookSkillBasicInfo.fromJson(json['logbookSkill'] as Map<String, dynamic>),
      trip: json['trip'] != null
          ? TripBasicInfo.fromJson(json['trip'] as Map<String, dynamic>)
          : null,
      verifiedBy: MemberBasicInfo.fromJson(json['verifiedBy'] as Map<String, dynamic>),
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'logbookSkill': logbookSkill.toJson(),
      if (trip != null) 'trip': trip!.toJson(),
      'verifiedBy': verifiedBy.toJson(),
      'verifiedAt': verifiedAt.toIso8601String(),
      if (comment != null) 'comment': comment,
    };
  }
}

// ============================================================================
// TRIP REPORT
// ============================================================================

/// Trip Report Model
/// Detailed post-trip report created by marshals
class TripReport {
  final int id;
  final TripBasicInfo trip;
  final MemberBasicInfo createdBy;
  final String report;
  final String? safetyNotes;
  final String? weatherConditions;
  final String? terrainNotes;
  final int participantCount;
  final List<String>? issues;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TripReport({
    required this.id,
    required this.trip,
    required this.createdBy,
    required this.report,
    this.safetyNotes,
    this.weatherConditions,
    this.terrainNotes,
    required this.participantCount,
    this.issues,
    required this.createdAt,
    this.updatedAt,
  });

  factory TripReport.fromJson(Map<String, dynamic> json) {
    return TripReport(
      id: json['id'] as int,
      trip: TripBasicInfo.fromJson(json['trip'] as Map<String, dynamic>),
      createdBy: MemberBasicInfo.fromJson(json['createdBy'] as Map<String, dynamic>),
      report: json['report'] as String,
      safetyNotes: json['safetyNotes'] as String?,
      weatherConditions: json['weatherConditions'] as String?,
      terrainNotes: json['terrainNotes'] as String?,
      participantCount: json['participantCount'] as int? ?? 0,
      issues: (json['issues'] as List<dynamic>?)
          ?.map((i) => i as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': trip.toJson(),
      'createdBy': createdBy.toJson(),
      'report': report,
      if (safetyNotes != null) 'safetyNotes': safetyNotes,
      if (weatherConditions != null) 'weatherConditions': weatherConditions,
      if (terrainNotes != null) 'terrainNotes': terrainNotes,
      'participantCount': participantCount,
      if (issues != null) 'issues': issues,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// ============================================================================
// BASIC INFO CLASSES (for nested objects)
// ============================================================================

/// Member Basic Info (reused from user model)
class MemberBasicInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final LevelBasicInfo? level;

  const MemberBasicInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    this.level,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : 'Unknown';
  }

  factory MemberBasicInfo.fromJson(Map<String, dynamic> json) {
    return MemberBasicInfo(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      profilePicture: json['profilePicture'] as String? ?? json['profile_picture'] as String?,
      level: json['level'] != null
          ? LevelBasicInfo.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (level != null) 'level': level!.toJson(),
    };
  }
}

/// Trip Basic Info (simplified trip data for nested objects)
class TripBasicInfo {
  final int id;
  final String title;
  final DateTime startTime;
  final LevelBasicInfo? level;

  const TripBasicInfo({
    required this.id,
    required this.title,
    required this.startTime,
    this.level,
  });

  factory TripBasicInfo.fromJson(Map<String, dynamic> json) {
    return TripBasicInfo(
      id: json['id'] as int,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String? ?? json['start_time'] as String),
      level: json['level'] != null
          ? LevelBasicInfo.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      if (level != null) 'level': level!.toJson(),
    };
  }
}

/// Level Basic Info (simplified level data for nested objects)
class LevelBasicInfo {
  final int id;
  final String name;
  final int numericLevel;

  const LevelBasicInfo({
    required this.id,
    required this.name,
    required this.numericLevel,
  });

  factory LevelBasicInfo.fromJson(Map<String, dynamic> json) {
    return LevelBasicInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      numericLevel: json['numericLevel'] as int? ?? json['numeric_level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numericLevel': numericLevel,
    };
  }
}

/// Logbook Skill Basic Info (simplified skill data for nested objects)
class LogbookSkillBasicInfo {
  final int id;
  final String name;
  final String description;

  const LogbookSkillBasicInfo({
    required this.id,
    required this.name,
    required this.description,
  });

  factory LogbookSkillBasicInfo.fromJson(Map<String, dynamic> json) {
    return LogbookSkillBasicInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

// ============================================================================
// PAGINATED RESPONSE
// ============================================================================

/// Paginated Logbook Entries Response
class LogbookEntriesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<LogbookEntry> results;

  const LogbookEntriesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;
  int get currentPage {
    if (previous == null) return 1;
    final match = RegExp(r'page=(\d+)').firstMatch(previous ?? '');
    if (match != null) {
      return int.parse(match.group(1)!) + 1;
    }
    return 1;
  }

  factory LogbookEntriesResponse.fromJson(Map<String, dynamic> json) {
    return LogbookEntriesResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => LogbookEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Paginated Logbook Skills Response
class LogbookSkillsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<LogbookSkill> results;

  const LogbookSkillsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;

  factory LogbookSkillsResponse.fromJson(Map<String, dynamic> json) {
    return LogbookSkillsResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => LogbookSkill.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
