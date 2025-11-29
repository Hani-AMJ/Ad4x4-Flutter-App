import 'user_model.dart';
import 'meeting_point_model.dart' as mp;
import '../../core/utils/status_helpers.dart';

/// BasicMember - Simplified member data used in trip responses
/// 
/// Note: Different endpoints return different fields:
/// - List endpoint: Only id, username
/// - Detail endpoint: All fields including tripCount, phone, etc.
class BasicMember {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? profileImage;
  final String? level;
  final int? tripCount;
  final String? carBrand;
  final String? carModel;
  final String? carColor;
  final String? carImage;
  final bool? paidMember;

  BasicMember({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.profileImage,
    this.level,
    this.tripCount,
    this.carBrand,
    this.carModel,
    this.carColor,
    this.carImage,
    this.paidMember,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) return fullName;
    }
    return username;
  }

  factory BasicMember.fromJson(Map<String, dynamic> json) {
    final memberId = json['id'] as int? ?? 0;
    
    // Handle level field - can be String or Object
    String? levelValue;
    final levelData = json['level'];
    if (levelData is String) {
      levelValue = levelData;
    } else if (levelData is Map<String, dynamic>) {
      // Level is an object with {id, name, numericLevel}
      levelValue = levelData['name'] as String?;
    }
    
    return BasicMember(
      id: memberId,
      username: json['username'] as String? ?? 'user_$memberId',
      firstName: json['first_name'] as String? ?? json['firstName'] as String?,
      lastName: json['last_name'] as String? ?? json['lastName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String? ?? json['profileImage'] as String?,
      level: levelValue,
      tripCount: json['trip_count'] as int? ?? json['tripCount'] as int?,
      carBrand: json['car_brand'] as String? ?? json['carBrand'] as String?,
      carModel: json['car_model'] as String? ?? json['carModel'] as String?,
      carColor: json['car_color'] as String? ?? json['carColor'] as String?,
      carImage: json['car_image'] as String? ?? json['carImage'] as String?,
      paidMember: json['paid_member'] as bool? ?? json['paidMember'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (profileImage != null) 'profile_image': profileImage,
      if (level != null) 'level': level,
      if (tripCount != null) 'trip_count': tripCount,
      if (carBrand != null) 'car_brand': carBrand,
      if (carModel != null) 'car_model': carModel,
      if (carColor != null) 'car_color': carColor,
      if (carImage != null) 'car_image': carImage,
      if (paidMember != null) 'paid_member': paidMember,
    };
  }
}

// Using existing MeetingPoint from meeting_point_model.dart

/// TripLevel - Difficulty/level information for trip
class TripLevel {
  final int id;
  final String name;
  final int numericLevel;
  final String? displayName;
  final String? description;
  final String? color;

  TripLevel({
    required this.id,
    required this.name,
    required this.numericLevel,
    this.displayName,
    this.description,
    this.color,
  });

  factory TripLevel.fromJson(Map<String, dynamic> json) {
    return TripLevel(
      id: json['id'] as int? ?? 0,  // Handle null id
      name: json['name'] as String? ?? 'Unknown',
      numericLevel: json['numeric_level'] as int? ?? json['numericLevel'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numeric_level': numericLevel,
      'display_name': displayName,
      'description': description,
      'color': color,
    };
  }
}

/// TripRegistration - Member registration for a trip
class TripRegistration {
  final int id;
  final BasicMember member;
  final DateTime registrationDate;
  final String? status; // confirmed, checked_in, checked_out, cancelled - API can return null
  final bool? hasVehicle;
  final int? vehicleCapacity;
  final String? notes;

  TripRegistration({
    required this.id,
    required this.member,
    required this.registrationDate,
    required this.status,
    this.hasVehicle,
    this.vehicleCapacity,
    this.notes,
  });

  factory TripRegistration.fromJson(Map<String, dynamic> json) {
    // Handle registration_date field safely
    final dateStr = json['registration_date'] as String? ?? json['registrationDate'] as String? ?? DateTime.now().toIso8601String();
    
    // Map checkedIn boolean to status string
    String determineStatus() {
      // If API provides explicit status field, use it
      if (json['status'] != null) {
        return json['status'] as String;
      }
      // Otherwise, derive from checkedIn boolean
      final checkedIn = json['checkedIn'] as bool? ?? json['checked_in'] as bool?;
      if (checkedIn == true) {
        return 'confirmed';  // Checked in = confirmed status
      } else {
        return 'registered';  // Not checked in = registered status
      }
    }
    
    return TripRegistration(
      id: json['id'] as int? ?? 0,  // Handle null id
      member: BasicMember.fromJson(json['member'] as Map<String, dynamic>),
      registrationDate: DateTime.parse(dateStr),
      status: determineStatus(),
      hasVehicle: json['has_vehicle'] as bool? ?? json['hasVehicle'] as bool?,
      vehicleCapacity: json['vehicle_capacity'] as int? ?? json['vehicleCapacity'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'has_vehicle': hasVehicle,
      'vehicle_capacity': vehicleCapacity,
      'notes': notes,
    };
  }
}

/// TripWaitlist - Member on trip waitlist
class TripWaitlist {
  final int id;
  final BasicMember member;
  final DateTime joinedDate;
  final int position;

  TripWaitlist({
    required this.id,
    required this.member,
    required this.joinedDate,
    required this.position,
  });

  factory TripWaitlist.fromJson(Map<String, dynamic> json) {
    // Handle joined_date field safely
    final dateStr = json['joined_date'] as String? ?? json['joinedDate'] as String? ?? DateTime.now().toIso8601String();
    
    return TripWaitlist(
      id: json['id'] as int? ?? 0,
      member: BasicMember.fromJson(json['member'] as Map<String, dynamic>),
      joinedDate: DateTime.parse(dateStr),
      position: json['position'] as int? ?? 1,  // Default to position 1 if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'joined_date': joinedDate.toIso8601String(),
      'position': position,
    };
  }
}

/// Trip model - Full trip details from API
class Trip {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? cutOff;
  final String? location;  // Nullable - API doesn't always return location field
  final TripLevel level;
  final int capacity;
  final int registeredCount;
  final int waitlistCount;
  final String? imageUrl;
  final BasicMember lead;
  final List<BasicMember> deputyLeads;
  final mp.MeetingPoint? meetingPoint;  // Nullable - API can return null
  final String approvalStatus; // pending, approved, declined
  final BasicMember? approvedBy;
  final DateTime? approvedAt;
  final bool allowWaitlist;
  final DateTime created;
  final List<TripRegistration> registered;
  final List<TripWaitlist> waitlist;
  final List<String> requirements;
  final bool isRegistered;  // Read-only: User registration status from API
  final bool isWaitlisted;  // Read-only: User waitlist status from API
  final String? galleryId;  // UUID of associated gallery from Gallery API

  Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.cutOff,
    this.location,
    required this.level,
    required this.capacity,
    required this.registeredCount,
    required this.waitlistCount,
    this.imageUrl,
    required this.lead,
    this.deputyLeads = const [],
    required this.meetingPoint,
    this.approvalStatus = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.allowWaitlist = true,
    required this.created,
    this.registered = const [],
    this.waitlist = const [],
    this.requirements = const [],
    this.isRegistered = false,
    this.isWaitlisted = false,
    this.galleryId,
  });

  // Computed properties for backward compatibility
  String get organizer => lead.displayName;
  int get participants => registeredCount;
  int get maxParticipants => capacity;
  String get difficulty => level.name;
  
  // Status based on dates and approval
  // ✅ FIXED: Use status helpers to correctly check backend codes (A, P, D)
  String get status {
    final now = DateTime.now();
    if (isDeclined(approvalStatus)) return 'cancelled';
    if (isPending(approvalStatus)) return 'pending';
    if (now.isBefore(startTime)) return 'upcoming';
    if (now.isAfter(endTime)) return 'completed';
    return 'ongoing';
  }
  
  // Check if current user is registered (requires user ID)
  bool isUserJoined(int userId) {
    return registered.any((reg) => reg.member.id == userId);
  }
  
  // Check if current user is on waitlist
  bool isUserOnWaitlist(int userId) {
    return waitlist.any((wait) => wait.member.id == userId);
  }
  
  // Check if trip is full
  bool get isFull => registeredCount >= capacity;

  /// Helper to parse level field which can be String or Map
  static TripLevel _parseTripLevel(dynamic levelData) {
    if (levelData is Map<String, dynamic>) {
      return TripLevel.fromJson(levelData);
    } else if (levelData is String) {
      // Backend returned just a string name - create a basic TripLevel
      // Map common level names to numeric values
      int numericLevel = 0;
      switch (levelData) {
        case 'Club Event':
        case 'CLUB EVENT':
          numericLevel = 5;
          break;
        case 'Newbie':
        case 'NEWBIE':
        case 'ANIT':
          numericLevel = 10;
          break;
        case 'Intermediate':
        case 'INTERMEDIATE':
          numericLevel = 100;
          break;
        case 'Advanced':
        case 'ADVANCED':
        case 'Advance':  // Backend variation without 'd'
        case 'ADVANCE':
          numericLevel = 200;
          break;
        case 'Expert':
        case 'EXPERT':
          numericLevel = 300;
          break;
      }
      
      return TripLevel(
        id: 0, // Unknown ID
        name: levelData,
        numericLevel: numericLevel,
      );
    } else {
      // Fallback for unexpected data types
      return TripLevel(
        id: 0,
        name: 'Unknown',
        numericLevel: 0,
      );
    }
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Handle date fields safely
    final startTimeStr = json['start_time'] as String? ?? json['startTime'] as String? ?? DateTime.now().toIso8601String();
    final endTimeStr = json['end_time'] as String? ?? json['endTime'] as String? ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String();
    final createdStr = json['created'] as String? ?? DateTime.now().toIso8601String();
    
    return Trip(
      id: json['id'] as int? ?? 0,  // Handle null id
      title: json['title'] as String? ?? 'Untitled Trip',
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(startTimeStr),
      endTime: DateTime.parse(endTimeStr),
      cutOff: (json['cut_off'] ?? json['cutOff']) != null
          ? DateTime.parse((json['cut_off'] ?? json['cutOff']) as String)
          : null,
      location: json['location'] as String? ?? 
                (json['meetingPoint'] != null ? (json['meetingPoint'] as Map<String, dynamic>)['name'] as String? : null) ?? 
                (json['meeting_point'] != null ? (json['meeting_point'] as Map<String, dynamic>)['name'] as String? : null) ?? 
                'TBA',
      level: _parseTripLevel(json['level']),
      capacity: json['capacity'] as int? ?? 0,  // Handle null capacity
      registeredCount: json['registered_count'] as int? ?? json['registeredCount'] as int? ?? 0,
      waitlistCount: json['waitlist_count'] as int? ?? json['waitlistCount'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? json['image'] as String?,
      lead: BasicMember.fromJson(json['lead'] as Map<String, dynamic>),
      deputyLeads: (json['deputy_leads'] as List<dynamic>? ?? json['deputyLeads'] as List<dynamic>?)
              ?.map((m) => BasicMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      meetingPoint: (json['meeting_point'] ?? json['meetingPoint']) != null
          ? mp.MeetingPoint.fromJson((json['meeting_point'] ?? json['meetingPoint']) as Map<String, dynamic>)
          : null,
      approvalStatus: json['approval_status'] as String? ?? json['approvalStatus'] as String? ?? 'pending',
      approvedBy: (json['approved_by'] ?? json['approvedBy']) != null
          ? BasicMember.fromJson((json['approved_by'] ?? json['approvedBy']) as Map<String, dynamic>)
          : null,
      approvedAt: (json['approved_at'] ?? json['approvedAt']) != null
          ? DateTime.parse((json['approved_at'] ?? json['approvedAt']) as String)
          : null,
      allowWaitlist: json['allow_waitlist'] as bool? ?? json['allowWaitlist'] as bool? ?? true,
      created: DateTime.parse(createdStr),
      registered: (json['registered'] as List<dynamic>?)
              ?.map((r) => TripRegistration.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      waitlist: (json['waitlist'] as List<dynamic>?)
              ?.map((w) => TripWaitlist.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isRegistered: json['is_registered'] as bool? ?? json['isRegistered'] as bool? ?? false,
      isWaitlisted: json['is_waitlisted'] as bool? ?? json['isWaitlisted'] as bool? ?? false,
      galleryId: json['gallery_id'] as String? ?? json['galleryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'cut_off': cutOff?.toIso8601String(),
      'location': location,
      'level': level.toJson(),
      'capacity': capacity,
      'registered_count': registeredCount,
      'waitlist_count': waitlistCount,
      'image_url': imageUrl,
      'lead': lead.toJson(),
      'deputy_leads': deputyLeads.map((m) => m.toJson()).toList(),
      if (meetingPoint != null) 'meeting_point': meetingPoint!.toJson(),
      'approval_status': approvalStatus,
      'approved_by': approvedBy?.toJson(),
      'approved_at': approvedAt?.toIso8601String(),
      'allow_waitlist': allowWaitlist,
      'created': created.toIso8601String(),
      'registered': registered.map((r) => r.toJson()).toList(),
      'waitlist': waitlist.map((w) => w.toJson()).toList(),
      'requirements': requirements,
      'is_registered': isRegistered,
      'is_waitlisted': isWaitlisted,
      if (galleryId != null) 'gallery_id': galleryId,
    };
  }

  Trip copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? cutOff,
    String? location,
    TripLevel? level,
    int? capacity,
    int? registeredCount,
    int? waitlistCount,
    String? imageUrl,
    BasicMember? lead,
    List<BasicMember>? deputyLeads,
    mp.MeetingPoint? meetingPoint,
    String? approvalStatus,
    BasicMember? approvedBy,
    DateTime? approvedAt,
    bool? allowWaitlist,
    DateTime? created,
    List<TripRegistration>? registered,
    List<TripWaitlist>? waitlist,
    List<String>? requirements,
    bool? isRegistered,
    bool? isWaitlisted,
    String? galleryId,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      cutOff: cutOff ?? this.cutOff,
      location: location ?? this.location,
      level: level ?? this.level,
      capacity: capacity ?? this.capacity,
      registeredCount: registeredCount ?? this.registeredCount,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      imageUrl: imageUrl ?? this.imageUrl,
      lead: lead ?? this.lead,
      deputyLeads: deputyLeads ?? this.deputyLeads,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      allowWaitlist: allowWaitlist ?? this.allowWaitlist,
      created: created ?? this.created,
      registered: registered ?? this.registered,
      waitlist: waitlist ?? this.waitlist,
      requirements: requirements ?? this.requirements,
      isRegistered: isRegistered ?? this.isRegistered,
      isWaitlisted: isWaitlisted ?? this.isWaitlisted,
      galleryId: galleryId ?? this.galleryId,
    );
  }
}

/// TripListItem - Simplified trip data for list view (from GET /api/trips/)
class TripListItem {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? cutOff;
  final String? location;  // Nullable - API doesn't always return location field
  final TripLevel level;
  final int capacity;
  final int registeredCount;
  final int waitlistCount;
  final String? imageUrl;
  final BasicMember lead;
  final mp.MeetingPoint? meetingPoint;  // Nullable - API can return null
  final String approvalStatus;
  final bool allowWaitlist;
  final DateTime created;
  final bool isRegistered;  // Read-only: User registration status from API
  final bool isWaitlisted;  // Read-only: User waitlist status from API
  final String? galleryId;  // UUID of associated gallery from Gallery API

  TripListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.cutOff,
    this.location,
    required this.level,
    required this.capacity,
    required this.registeredCount,
    required this.waitlistCount,
    this.imageUrl,
    required this.lead,
    required this.meetingPoint,
    this.approvalStatus = 'pending',
    this.allowWaitlist = true,
    required this.created,
    this.isRegistered = false,
    this.isWaitlisted = false,
    this.galleryId,
  });

  // Computed properties
  String get organizer => lead.displayName;
  int get participants => registeredCount;
  int get maxParticipants => capacity;
  String get difficulty => level.name;
  bool get isFull => registeredCount >= capacity;
  
  // ✅ FIXED: Use status helpers to correctly check backend codes (A, P, D)
  String get status {
    final now = DateTime.now();
    if (isDeclined(approvalStatus)) return 'cancelled';
    if (isPending(approvalStatus)) return 'pending';
    if (now.isBefore(startTime)) return 'upcoming';
    if (now.isAfter(endTime)) return 'completed';
    return 'ongoing';
  }

  factory TripListItem.fromJson(Map<String, dynamic> json) {
    // Handle date fields safely
    final startTimeStr = json['start_time'] as String? ?? json['startTime'] as String? ?? DateTime.now().toIso8601String();
    final endTimeStr = json['end_time'] as String? ?? json['endTime'] as String? ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String();
    final createdStr = json['created'] as String? ?? DateTime.now().toIso8601String();
    
    // ✅ FIXED: Handle level as both String and Map
    TripLevel parseTripLevel(dynamic levelData) {
      if (levelData == null) {
        return TripLevel(id: 0, name: 'Unknown', numericLevel: 0);
      }
      
      if (levelData is String) {
        // Level is just a string name - create a TripLevel from it
        return TripLevel(
          id: 0,
          name: levelData,
          numericLevel: _getLevelNumericValue(levelData),
          displayName: levelData,
        );
      }
      
      if (levelData is Map<String, dynamic>) {
        // Level is a full object
        return TripLevel.fromJson(levelData);
      }
      
      // Fallback
      return TripLevel(id: 0, name: 'Unknown', numericLevel: 0);
    }
    
    return TripListItem(
      id: json['id'] as int? ?? 0,  // Handle null id
      title: json['title'] as String? ?? 'Untitled Trip',
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(startTimeStr),
      endTime: DateTime.parse(endTimeStr),
      cutOff: (json['cut_off'] ?? json['cutOff']) != null
          ? DateTime.parse((json['cut_off'] ?? json['cutOff']) as String)
          : null,
      location: json['location'] as String? ?? 
                (json['meetingPoint'] != null ? (json['meetingPoint'] as Map<String, dynamic>)['name'] as String? : null) ?? 
                (json['meeting_point'] != null ? (json['meeting_point'] as Map<String, dynamic>)['name'] as String? : null) ?? 
                'TBA',
      level: parseTripLevel(json['level']),
      capacity: json['capacity'] as int? ?? 0,  // Handle null capacity
      registeredCount: json['registered_count'] as int? ?? json['registeredCount'] as int? ?? 0,
      waitlistCount: json['waitlist_count'] as int? ?? json['waitlistCount'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? json['image'] as String?,
      lead: json['lead'] != null 
          ? BasicMember.fromJson(json['lead'] as Map<String, dynamic>)
          : BasicMember(id: 0, username: 'Unknown'),
      meetingPoint: (json['meeting_point'] ?? json['meetingPoint']) != null
          ? mp.MeetingPoint.fromJson((json['meeting_point'] ?? json['meetingPoint']) as Map<String, dynamic>)
          : null,
      approvalStatus: json['approval_status'] as String? ?? json['approvalStatus'] as String? ?? 'pending',
      allowWaitlist: json['allow_waitlist'] as bool? ?? json['allowWaitlist'] as bool? ?? true,
      created: DateTime.parse(createdStr),
      isRegistered: json['is_registered'] as bool? ?? json['isRegistered'] as bool? ?? false,
      isWaitlisted: json['is_waitlisted'] as bool? ?? json['isWaitlisted'] as bool? ?? false,
      galleryId: json['gallery_id'] as String? ?? json['galleryId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'cut_off': cutOff?.toIso8601String(),
      'location': location,
      'level': level.toJson(),
      'capacity': capacity,
      'registered_count': registeredCount,
      'waitlist_count': waitlistCount,
      'image_url': imageUrl,
      'lead': lead.toJson(),
      if (meetingPoint != null) 'meeting_point': meetingPoint!.toJson(),
      'approval_status': approvalStatus,
      'allow_waitlist': allowWaitlist,
      'created': created.toIso8601String(),
      'is_registered': isRegistered,
      'is_waitlisted': isWaitlisted,
      if (galleryId != null) 'gallery_id': galleryId,
    };
  }
  
  // Helper to convert level name strings to numeric values
  static int _getLevelNumericValue(String levelName) {
    final normalized = levelName.toLowerCase().trim();
    switch (normalized) {
      case 'newbie':
      case 'beginner':
        return 1;
      case 'member':
      case 'intermediate':
        return 2;
      case 'anit':
      case 'advanced':
        return 3;
      case 'expert':
      case 'explorer':
        return 4;
      case 'master':
      case 'marshal':
        return 5;
      default:
        return 0;
    }
  }
}
