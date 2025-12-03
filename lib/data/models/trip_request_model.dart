import 'level_model.dart';
import 'concise_member_model.dart';

/// Trip Request Model
///
/// Model for member trip requests (matches OpenAPI schema)
class TripRequest {
  final int id;
  final String area; // Required - DXB/NOR/AUH/AAN/LIW
  final Level level; // Required - Trip difficulty level
  final ConciseMember member; // Required - Member who made request
  final String? timeOfDay; // Optional - MOR/MID/AFT/EVE/ANY
  final DateTime date; // Required - Requested trip date
  final TripRequestStatus status; // Request status
  final DateTime createdAt; // When request was created
  final String? adminNotes; // Optional admin notes

  TripRequest({
    required this.id,
    required this.area,
    required this.level,
    required this.member,
    this.timeOfDay,
    required this.date,
    required this.status,
    required this.createdAt,
    this.adminNotes,
  });

  factory TripRequest.fromJson(Map<String, dynamic> json) {
    // 🔧 DEFENSIVE: Handle different level response formats from backend
    Level parsedLevel;
    final levelData = json['level'];

    if (levelData is Map<String, dynamic>) {
      // ✅ Correct: Backend returned nested Level object
      parsedLevel = Level.fromJson(levelData);
    } else if (levelData is int) {
      // ⚠️ Backend bug: Returned level ID instead of object
      // Create a placeholder Level with just the ID
      parsedLevel = Level(
        id: levelData,
        name: 'Level $levelData',
        numericLevel: levelData,
        description: 'Trip level',
      );
    } else if (levelData is String) {
      // ⚠️ Backend bug: Returned level name string instead of object
      // Try to extract numeric level from name (e.g., "Intermediate-100" -> 3)
      int numericLevel = 0;
      String displayName = levelData;

      if (levelData.toLowerCase().contains('beginner')) {
        numericLevel = 1;
      } else if (levelData.toLowerCase().contains('easy'))
        numericLevel = 2;
      else if (levelData.toLowerCase().contains('intermediate'))
        numericLevel = 3;
      else if (levelData.toLowerCase().contains('difficult'))
        numericLevel = 4;
      else if (levelData.toLowerCase().contains('extreme'))
        numericLevel = 5;

      parsedLevel = Level(
        id: numericLevel,
        name: displayName,
        numericLevel: numericLevel,
        description: '',
      );
    } else {
      // Fallback: Create default level
      parsedLevel = Level(
        id: 0,
        name: 'Unknown',
        numericLevel: 0,
        description: '',
      );
    }

    // 🔧 DEFENSIVE: Handle NULL or invalid member field from backend
    ConciseMember parsedMember;
    final memberData = json['member'];

    if (memberData is Map<String, dynamic>) {
      // ✅ Correct: Backend returned nested Member object
      parsedMember = ConciseMember.fromJson(memberData);
    } else if (memberData is String) {
      // ⚠️ Backend bug: Returned member username string instead of object
      parsedMember = ConciseMember(id: 0, username: memberData);
    } else if (memberData == null) {
      // ⚠️ Backend bug: Member field is NULL
      parsedMember = ConciseMember(id: 0, username: 'Unknown Member');
    } else {
      // Fallback: Create default member
      parsedMember = ConciseMember(id: 0, username: 'Unknown');
    }

    return TripRequest(
      id: json['id'] as int,
      area:
          (json['area'] as String?) ??
          'Unknown', // 🔧 Handle null area gracefully
      level: parsedLevel,
      member: parsedMember,
      timeOfDay: json['timeOfDay'] as String?,
      date: DateTime.parse(json['date'] as String),
      status: TripRequestStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['date'] != null
          ? DateTime.parse(
              json['date'] as String,
            ) // Fallback to date if createdAt missing
          : DateTime.now(),
      adminNotes: json['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      if (timeOfDay != null) 'timeOfDay': timeOfDay,
      'level': level.id,
      'area': area,
    };
  }

  TripRequest copyWith({
    int? id,
    String? area,
    Level? level,
    ConciseMember? member,
    String? timeOfDay,
    DateTime? date,
    TripRequestStatus? status,
    DateTime? createdAt,
    String? adminNotes,
  }) {
    return TripRequest(
      id: id ?? this.id,
      area: area ?? this.area,
      level: level ?? this.level,
      member: member ?? this.member,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  /// Get display name for area
  String get areaDisplayName {
    switch (area.toUpperCase()) {
      case 'DXB':
        return 'Dubai';
      case 'NOR':
        return 'Northern Emirates';
      case 'AUH':
        return 'Abu Dhabi';
      case 'AAN':
        return 'Al Ain';
      case 'LIW':
        return 'Liwa';
      default:
        return area;
    }
  }

  /// Get display name for time of day
  String? get timeOfDayDisplayName {
    if (timeOfDay == null) return null;
    switch (timeOfDay!.toUpperCase()) {
      case 'MOR':
        return 'Morning';
      case 'MID':
        return 'Mid-day';
      case 'AFT':
        return 'Afternoon';
      case 'EVE':
        return 'Evening';
      case 'ANY':
        return 'Any Time';
      default:
        return timeOfDay;
    }
  }

  /// Get member name
  String get memberName => member.username;
}

/// Trip request status
enum TripRequestStatus {
  pending,
  approved,
  declined,
  converted; // Converted to actual trip

  String get displayName {
    switch (this) {
      case TripRequestStatus.pending:
        return 'Pending Review';
      case TripRequestStatus.approved:
        return 'Approved';
      case TripRequestStatus.declined:
        return 'Declined';
      case TripRequestStatus.converted:
        return 'Converted to Trip';
    }
  }

  static TripRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TripRequestStatus.pending;
      case 'approved':
        return TripRequestStatus.approved;
      case 'declined':
        return TripRequestStatus.declined;
      case 'converted':
        return TripRequestStatus.converted;
      default:
        return TripRequestStatus.pending;
    }
  }

  String toApiString() {
    return toString().split('.').last;
  }
}
