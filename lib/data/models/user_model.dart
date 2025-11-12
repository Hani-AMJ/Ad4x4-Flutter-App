/// User Model - Represents authenticated user data from API
class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserLevel? level;
  final List<Permission> permissions;
  final int tripCount;
  final String? dateJoined;
  final String? profileImage;
  final String? phoneNumber;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.level,
    this.permissions = const [],
    this.tripCount = 0,
    this.dateJoined,
    this.profileImage,
    this.phoneNumber,
    this.isActive = true,
  });

  /// Display name: "First Last" or username if empty
  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : username;
  }

  /// Check if user has specific permission
  bool hasPermission(String permissionAction) {
    return permissions.any((p) => p.action == permissionAction);
  }

  /// Factory constructor from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? 'user_${json['id']}',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      level: json['level'] != null 
          ? (json['level'] is Map<String, dynamic> 
              ? UserLevel.fromJson(json['level'] as Map<String, dynamic>)
              : null) // If level is a String, ignore it for now
          : null,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => Permission.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      tripCount: json['trip_count'] as int? ?? json['tripCount'] as int? ?? 0,
      dateJoined: json['date_joined'] as String? ?? json['dateJoined'] as String?,
      profileImage: json['profile_image'] as String? ?? json['profileImage'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'level': level?.toJson(),
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'trip_count': tripCount,
      'date_joined': dateJoined,
      'profile_image': profileImage,
      'phone_number': phoneNumber,
      'is_active': isActive,
    };
  }
}

/// User Level - Member level/rank in the club
class UserLevel {
  final int id;
  final String name;
  final int numericLevel;
  final String? displayName;
  final String? description;

  UserLevel({
    required this.id,
    required this.name,
    required this.numericLevel,
    this.displayName,
    this.description,
  });

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      numericLevel: json['numeric_level'] as int? ?? json['numericLevel'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numeric_level': numericLevel,
      'display_name': displayName,
      'description': description,
    };
  }
}

/// Permission - User permission for specific actions
class Permission {
  final int id;
  final String action;
  final List<PermissionLevel> levels;

  Permission({
    required this.id,
    required this.action,
    this.levels = const [],
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      action: json['action'] as String? ?? '',
      levels: (json['levels'] as List<dynamic>?)
              ?.map((level) => PermissionLevel.fromJson(level as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'levels': levels.map((l) => l.toJson()).toList(),
    };
  }
}

/// Permission Level - Level associated with a permission
class PermissionLevel {
  final int id;
  final String name;
  final int numericLevel;

  PermissionLevel({
    required this.id,
    required this.name,
    required this.numericLevel,
  });

  factory PermissionLevel.fromJson(Map<String, dynamic> json) {
    return PermissionLevel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      numericLevel: json['numeric_level'] as int? ?? json['numericLevel'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numeric_level': numericLevel,
    };
  }
}
