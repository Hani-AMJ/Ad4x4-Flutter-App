/// Logbook Models
/// 
/// Models for logbook entries, skills, and skill references

import 'package:flutter/foundation.dart';
import '../../shared/constants/level_constants.dart';

// ============================================================================
// TRIP REPORT SERIALIZATION HELPERS
// ============================================================================

/// Helper class for serializing trip report data into structured reportText
class TripReportSerializer {
  /// Serialize structured trip report data into formatted reportText
  static String serialize({
    required String mainReport,
    String? safetyNotes,
    String? weatherConditions,
    String? terrainNotes,
    int? participantCount,
    List<String>? issues,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== TRIP REPORT ===');
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    // Main report section
    buffer.writeln('MAIN REPORT:');
    buffer.writeln(mainReport.trim());
    buffer.writeln();
    
    // Participant count
    if (participantCount != null && participantCount > 0) {
      buffer.writeln('PARTICIPANT COUNT: $participantCount');
      buffer.writeln();
    }
    
    // Safety notes
    if (safetyNotes != null && safetyNotes.trim().isNotEmpty) {
      buffer.writeln('SAFETY NOTES:');
      buffer.writeln(safetyNotes.trim());
      buffer.writeln();
    }
    
    // Weather conditions
    if (weatherConditions != null && weatherConditions.trim().isNotEmpty) {
      buffer.writeln('WEATHER CONDITIONS:');
      buffer.writeln(weatherConditions.trim());
      buffer.writeln();
    }
    
    // Terrain notes
    if (terrainNotes != null && terrainNotes.trim().isNotEmpty) {
      buffer.writeln('TERRAIN NOTES:');
      buffer.writeln(terrainNotes.trim());
      buffer.writeln();
    }
    
    // Issues/problems
    if (issues != null && issues.isNotEmpty) {
      buffer.writeln('ISSUES/PROBLEMS:');
      for (final issue in issues) {
        buffer.writeln('• ${issue.trim()}');
      }
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }
}

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
    // Handle member field - can be null, int (ID only), or Map (full object)
    final memberData = json['member'];
    final MemberBasicInfo member;
    
    if (memberData == null) {
      // ✅ FIX: API returned null/missing member - create placeholder
      // This happens when member field is not included in response
      member = MemberBasicInfo(
        id: 0,
        firstName: 'Member',
        lastName: 'Unknown',
      );
    } else if (memberData is int) {
      // API returned just member ID - create minimal MemberBasicInfo
      member = MemberBasicInfo(
        id: memberData,
        firstName: 'Member',
        lastName: '#$memberData',
      );
    } else if (memberData is Map<String, dynamic>) {
      // API returned full member object
      member = MemberBasicInfo.fromJson(memberData);
    } else {
      throw ArgumentError('Invalid member data type: ${memberData.runtimeType}');
    }
    
    // Handle signedBy field - can be int (ID only) or Map (full object)
    final signedByData = json['signedBy'];
    final MemberBasicInfo signedBy;
    
    if (signedByData is int) {
      // API returned just signedBy ID - create minimal MemberBasicInfo
      signedBy = MemberBasicInfo(
        id: signedByData,
        firstName: 'Marshal',
        lastName: '#$signedByData',
      );
    } else if (signedByData is Map<String, dynamic>) {
      // API returned full signedBy object
      signedBy = MemberBasicInfo.fromJson(signedByData);
    } else {
      throw ArgumentError('Invalid signedBy data type: ${signedByData.runtimeType}');
    }
    
    // Handle trip field - can be null, int (ID only), or Map (full object)
    final tripData = json['trip'];
    final TripBasicInfo? trip;
    
    if (tripData == null) {
      trip = null;
    } else if (tripData is int) {
      // API returned just trip ID - create minimal TripBasicInfo
      trip = TripBasicInfo(
        id: tripData,
        title: 'Trip #$tripData',
        startTime: DateTime.now(),
      );
    } else if (tripData is Map<String, dynamic>) {
      // API returned full trip object
      trip = TripBasicInfo.fromJson(tripData);
    } else {
      throw ArgumentError('Invalid trip data type: ${tripData.runtimeType}');
    }
    
    // Handle skillsVerified field - can be List<int> (IDs only) or List<Map> (full objects)
    final skillsData = json['skillsVerified'] as List<dynamic>? ?? [];
    final List<LogbookSkillBasicInfo> skillsVerified;
    
    if (skillsData.isEmpty) {
      skillsVerified = [];
    } else if (skillsData.first is int) {
      // API returned list of skill IDs only - create minimal skill objects
      skillsVerified = skillsData.map((id) => LogbookSkillBasicInfo(
        id: id as int,
        name: 'Skill #$id',
        description: '',
        level: const LevelBasicInfo(id: 1, name: 'Beginner', numericLevel: 1),
      )).toList();
    } else if (skillsData.first is Map<String, dynamic>) {
      // API returned full skill objects
      skillsVerified = skillsData
          .map((s) => LogbookSkillBasicInfo.fromJson(s as Map<String, dynamic>))
          .toList();
    } else {
      throw ArgumentError('Invalid skillsVerified data type: ${skillsData.first.runtimeType}');
    }
    
    // Safely parse dates with fallback
    DateTime? parseDateTimeNullable(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    return LogbookEntry(
      id: json['id'] as int,
      member: member,
      trip: trip,
      signedBy: signedBy,
      skillsVerified: skillsVerified,
      comment: json['comment'] as String?,
      createdAt: parseDateTimeNullable(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTimeNullable(json['updatedAt']),
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
    // Handle both API response formats:
    // 1. New format: { "levelRequirement": 2 }
    // 2. Old format: { "level": { "id": 2, "name": "Intermediate" } }
    LevelBasicInfo level;
    if (json.containsKey('levelRequirement')) {
      final levelId = json['levelRequirement'] as int;
      level = LevelBasicInfo(
        id: levelId,
        name: _getLevelNameFromId(levelId),
        numericLevel: levelId,
      );
    } else if (json.containsKey('level') && json['level'] is Map<String, dynamic>) {
      level = LevelBasicInfo.fromJson(json['level'] as Map<String, dynamic>);
    } else {
      // Default to Level 1 if no level info
      level = const LevelBasicInfo(id: 1, name: 'Beginner', numericLevel: 1);
    }
    
    // Safely parse dates
    DateTime? parseDateTimeNullable(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    return LogbookSkill(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Skill #${json['id']}',
      description: (json['description'] as String?) ?? '',
      level: level,
      order: json['order'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: parseDateTimeNullable(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTimeNullable(json['updatedAt']),
    );
  }
  
  /// Helper to convert level ID to level name
  /// Uses centralized LevelConstants for correct level name lookup
  static String _getLevelNameFromId(int levelId) {
    // Import required: import '../../shared/constants/level_constants.dart';
    final levelData = LevelConstants.getById(levelId);
    if (levelData != null) {
      return levelData.name;
    }
    // Fallback if level not found
    return 'Level $levelId';
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
    // Handle member field - can be int (ID only) or Map (full object)
    final memberData = json['member'];
    final MemberBasicInfo member;
    if (memberData is int) {
      member = MemberBasicInfo(id: memberData, firstName: 'Member', lastName: '#$memberData');
    } else if (memberData is Map<String, dynamic>) {
      member = MemberBasicInfo.fromJson(memberData);
    } else {
      throw ArgumentError('Invalid member data type: ${memberData.runtimeType}');
    }
    
    // Handle verifiedBy field - can be missing, null, int (ID only), or Map (full object)
    final verifiedByData = json['verifiedBy'];
    final MemberBasicInfo verifiedBy;
    if (verifiedByData == null) {
      // Field is missing or null - use member as fallback (self-verified or unknown marshal)
      verifiedBy = MemberBasicInfo(id: 0, firstName: 'Marshal', lastName: 'Unknown');
    } else if (verifiedByData is int) {
      verifiedBy = MemberBasicInfo(id: verifiedByData, firstName: 'Marshal', lastName: '#$verifiedByData');
    } else if (verifiedByData is Map<String, dynamic>) {
      verifiedBy = MemberBasicInfo.fromJson(verifiedByData);
    } else {
      throw ArgumentError('Invalid verifiedBy data type: ${verifiedByData.runtimeType}');
    }
    
    // Handle logbookSkill field - can be int (ID only) or Map (full object)
    final skillData = json['logbookSkill'];
    final LogbookSkillBasicInfo logbookSkill;
    if (skillData is int) {
      logbookSkill = LogbookSkillBasicInfo(
        id: skillData,
        name: 'Skill #$skillData',
        description: '',
        level: const LevelBasicInfo(id: 1, name: 'Beginner', numericLevel: 1),
      );
    } else if (skillData is Map<String, dynamic>) {
      logbookSkill = LogbookSkillBasicInfo.fromJson(skillData);
    } else {
      throw ArgumentError('Invalid logbookSkill data type: ${skillData.runtimeType}');
    }
    
    // Handle trip field - can be null, int (ID only), or Map (full object)
    final tripData = json['trip'];
    final TripBasicInfo? trip;
    if (tripData == null) {
      trip = null;
    } else if (tripData is int) {
      trip = TripBasicInfo(id: tripData, title: 'Trip #$tripData', startTime: DateTime.now());
    } else if (tripData is Map<String, dynamic>) {
      trip = TripBasicInfo.fromJson(tripData);
    } else {
      throw ArgumentError('Invalid trip data type: ${tripData.runtimeType}');
    }
    
    // Safely parse verifiedAt date
    DateTime? parseDateTimeNullable(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    return LogbookSkillReference(
      id: json['id'] as int,
      member: member,
      logbookSkill: logbookSkill,
      trip: trip,
      verifiedBy: verifiedBy,
      verifiedAt: parseDateTimeNullable(json['verifiedAt']) ?? DateTime.now(),
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
/// 
/// ⚠️ IMPORTANT: Backend API uses 'reportText' field, not 'report'
/// We serialize structured data into reportText for backend compatibility
class TripReport {
  final int id;
  final TripBasicInfo trip;
  final MemberBasicInfo createdBy;
  
  // Main report text (matches API field name)
  final String reportText;
  
  // Optional tracking info (parsed from reportText or stored separately)
  final String? title;
  final String? trackFile;
  final String? trackImage;
  final List<String>? imageFiles;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TripReport({
    required this.id,
    required this.trip,
    required this.createdBy,
    required this.reportText,
    this.title,
    this.trackFile,
    this.trackImage,
    this.imageFiles,
    required this.createdAt,
    this.updatedAt,
  });

  factory TripReport.fromJson(Map<String, dynamic> json) {
    // 🔍 DEBUG: Log raw JSON to identify type mismatches
    if (kDebugMode) {
      debugPrint('🔍 TripReport.fromJson - Raw JSON: $json');
      debugPrint('🔍 trip type: ${json['trip']?.runtimeType ?? 'null'}');
      debugPrint('🔍 createdBy type: ${json['createdBy']?.runtimeType ?? 'null'}');
    }
    
    // Handle trip field - can be null, int (trip ID), or full object
    final tripData = json['trip'];
    final TripBasicInfo trip;
    
    if (tripData == null) {
      // API returned null - create placeholder
      trip = TripBasicInfo(
        id: 0,
        title: 'Unknown Trip',
        startTime: DateTime.now(),
      );
    } else if (tripData is int) {
      // API returned just trip ID - create minimal TripBasicInfo
      trip = TripBasicInfo(
        id: tripData,
        title: 'Trip #$tripData',
        startTime: DateTime.now(),
      );
    } else if (tripData is Map<String, dynamic>) {
      // API returned full trip object
      trip = TripBasicInfo.fromJson(tripData);
    } else {
      throw ArgumentError('Invalid trip data type: ${tripData.runtimeType}');
    }
    
    // Handle createdBy/member field - API uses 'member' in detail, 'createdBy' in list
    // Can be null, int (member ID), or full object
    final createdByData = json['createdBy'] ?? json['member'];
    final MemberBasicInfo createdBy;
    
    if (createdByData == null) {
      // API returned null - create placeholder
      createdBy = MemberBasicInfo(
        id: 0,
        firstName: 'Unknown',
        lastName: 'User',
      );
    } else if (createdByData is int) {
      // API returned just member ID - create minimal MemberBasicInfo
      createdBy = MemberBasicInfo(
        id: createdByData,
        firstName: 'Member',
        lastName: '#$createdByData',
      );
    } else if (createdByData is Map<String, dynamic>) {
      // API returned full member object
      createdBy = MemberBasicInfo.fromJson(createdByData);
    } else {
      throw ArgumentError('Invalid createdBy data type: ${createdByData.runtimeType}');
    }
    
    return TripReport(
      id: json['id'] as int,
      trip: trip,
      createdBy: createdBy,
      
      // ✅ FIXED: Use 'reportText' to match API response
      reportText: json['reportText'] as String? ?? json['report_text'] as String? ?? json['report'] as String? ?? '',
      
      title: json['title'] as String?,
      trackFile: json['trackFile'] as String? ?? json['track_file'] as String?,
      trackImage: json['trackImage'] as String? ?? json['track_image'] as String?,
      imageFiles: (json['imageFiles'] as List<dynamic>?)
          ?.map((i) => i as String)
          .toList() ?? (json['image_files'] as List<dynamic>?)
          ?.map((i) => i as String)
          .toList(),
      
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse((json['updatedAt'] as String?) ?? (json['updated_at'] as String?) ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': trip.toJson(),
      'createdBy': createdBy.toJson(),
      
      // ✅ FIXED: Use 'reportText' to match API schema
      'reportText': reportText,
      
      if (title != null) 'title': title,
      if (trackFile != null) 'trackFile': trackFile,
      if (trackImage != null) 'trackImage': trackImage,
      if (imageFiles != null) 'imageFiles': imageFiles,
      
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
  
  /// Parse structured report data from reportText
  /// Returns a map with parsed sections: mainReport, safetyNotes, weather, terrain, participantCount, issues
  Map<String, dynamic> parseStructuredReport() {
    final result = <String, dynamic>{
      'mainReport': '',
      'safetyNotes': null,
      'weatherConditions': null,
      'terrainNotes': null,
      'participantCount': null,
      'issues': <String>[],
    };
    
    if (reportText.isEmpty) return result;
    
    // Try to parse structured format
    final lines = reportText.split('\n');
    String? currentSection;
    final sectionContent = <String, StringBuffer>{};
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Check for section headers
      if (trimmed.toUpperCase().contains('MAIN REPORT:')) {
        currentSection = 'mainReport';
        sectionContent[currentSection] = StringBuffer();
      } else if (trimmed.toUpperCase().contains('SAFETY NOTES:')) {
        currentSection = 'safetyNotes';
        sectionContent[currentSection] = StringBuffer();
      } else if (trimmed.toUpperCase().contains('WEATHER CONDITIONS:') || 
                 trimmed.toUpperCase().contains('WEATHER:')) {
        currentSection = 'weatherConditions';
        sectionContent[currentSection] = StringBuffer();
      } else if (trimmed.toUpperCase().contains('TERRAIN NOTES:') ||
                 trimmed.toUpperCase().contains('TERRAIN:')) {
        currentSection = 'terrainNotes';
        sectionContent[currentSection] = StringBuffer();
      } else if (trimmed.toUpperCase().contains('PARTICIPANT COUNT:')) {
        // Extract number from line
        final match = RegExp(r'(\d+)').firstMatch(trimmed);
        if (match != null) {
          result['participantCount'] = int.tryParse(match.group(1)!);
        }
        currentSection = null;
      } else if (trimmed.toUpperCase().contains('ISSUES/PROBLEMS:') ||
                 trimmed.toUpperCase().contains('ISSUES:')) {
        currentSection = 'issues';
        sectionContent[currentSection] = StringBuffer();
      } else if (currentSection != null && trimmed.isNotEmpty && 
                 !trimmed.startsWith('===') && !trimmed.startsWith('━')) {
        // Add content to current section
        if (currentSection == 'issues' && trimmed.startsWith('-') || trimmed.startsWith('•')) {
          (result['issues'] as List<String>).add(trimmed.replaceFirst(RegExp(r'^[\-•]\s*'), ''));
        } else if (sectionContent[currentSection]!.isNotEmpty) {
          sectionContent[currentSection]!.write('\n');
        }
        sectionContent[currentSection]!.write(trimmed);
      }
    }
    
    // Populate result from section content
    sectionContent.forEach((key, buffer) {
      if (key != 'issues' && buffer.isNotEmpty) {
        result[key] = buffer.toString().trim();
      }
    });
    
    // If no structured format found, put everything in mainReport
    if (result['mainReport'].isEmpty && sectionContent.isEmpty) {
      result['mainReport'] = reportText.trim();
    }
    
    return result;
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
    // Handle firstName/first_name with proper null checks
    String firstName = '';
    if (json['firstName'] != null && json['firstName'] is String) {
      firstName = json['firstName'] as String;
    } else if (json['first_name'] != null && json['first_name'] is String) {
      firstName = json['first_name'] as String;
    }
    
    // Handle lastName/last_name with proper null checks
    String lastName = '';
    if (json['lastName'] != null && json['lastName'] is String) {
      lastName = json['lastName'] as String;
    } else if (json['last_name'] != null && json['last_name'] is String) {
      lastName = json['last_name'] as String;
    }
    
    return MemberBasicInfo(
      id: json['id'] as int,
      firstName: firstName,
      lastName: lastName,
      profilePicture: json['profilePicture'] as String? ?? json['profile_picture'] as String?,
      level: json['level'] != null && json['level'] is Map<String, dynamic>
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
    // Safely parse ID - CRITICAL: Must have an ID
    final id = json['id'] as int?;
    if (id == null) {
      throw Exception('Trip ID is required but was null. JSON: $json');
    }
    
    // Safely parse startTime
    DateTime startTime;
    try {
      final timeStr = json['startTime'] as String? ?? json['start_time'] as String?;
      startTime = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();
    } catch (e) {
      startTime = DateTime.now();
    }
    
    return TripBasicInfo(
      id: id,
      title: (json['title'] as String?) ?? 'Trip #$id',
      startTime: startTime,
      level: json['level'] != null && json['level'] is Map<String, dynamic>
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
    // CRITICAL: Handle null ID gracefully
    final id = json['id'] as int?;
    if (id == null) {
      throw Exception('Level ID is required but was null. JSON: $json');
    }
    
    return LevelBasicInfo(
      id: id,
      name: (json['name'] as String?) ?? 'Unknown Level',
      numericLevel: json['numericLevel'] as int? ?? json['numeric_level'] as int? ?? id,
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
  final LevelBasicInfo level;

  const LogbookSkillBasicInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
  });

  factory LogbookSkillBasicInfo.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats (same as LogbookSkill)
    LevelBasicInfo level;
    if (json.containsKey('levelRequirement')) {
      final levelId = json['levelRequirement'] as int;
      level = LevelBasicInfo(
        id: levelId,
        name: _getLevelNameFromId(levelId),
        numericLevel: levelId,
      );
    } else if (json.containsKey('level')) {
      level = LevelBasicInfo.fromJson(json['level'] as Map<String, dynamic>);
    } else {
      // Default to Level 1 if no level info
      level = const LevelBasicInfo(id: 1, name: 'Beginner', numericLevel: 1);
    }
    
    return LogbookSkillBasicInfo(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Skill #${json['id']}',
      description: (json['description'] as String?) ?? '',
      level: level,
    );
  }

  /// Helper to convert level ID to level name
  /// Uses centralized LevelConstants for correct level name lookup
  static String _getLevelNameFromId(int levelId) {
    final levelData = LevelConstants.getById(levelId);
    if (levelData != null) {
      return levelData.name;
    }
    // Fallback if level not found
    return 'Level $levelId';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level.toJson(),
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
