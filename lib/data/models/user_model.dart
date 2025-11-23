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
  final String? avatar;  // Avatar URL from API
  final String? phoneNumber;
  final String? phone;  // Alternative phone field name
  final bool isActive;
  final bool paidMember;
  
  // Vehicle Information
  final String? carBrand;
  final String? carModel;
  final int? carYear;
  final String? carColor;
  final String? carImage;
  
  // Additional Profile Fields
  final String? dob;  // Date of birth
  final String? iceName;  // In Case of Emergency contact name
  final String? icePhone;  // In Case of Emergency contact phone
  final String? city;
  final String? gender;
  final String? nationality;
  final String? title;

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
    this.avatar,
    this.phoneNumber,
    this.phone,
    this.isActive = true,
    this.paidMember = false,
    this.carBrand,
    this.carModel,
    this.carYear,
    this.carColor,
    this.carImage,
    this.dob,
    this.iceName,
    this.icePhone,
    this.city,
    this.gender,
    this.nationality,
    this.title,
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

  /// Check if mandatory profile fields are complete
  /// Mandatory fields: firstName, lastName, phone, dob, gender, nationality
  /// Emergency contact: iceName, icePhone
  /// Vehicle: carBrand, carModel
  bool get isProfileComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        (phone?.isNotEmpty ?? phoneNumber?.isNotEmpty ?? false) &&
        dob != null && dob!.isNotEmpty &&
        gender != null && gender!.isNotEmpty &&
        nationality != null && nationality!.isNotEmpty &&
        iceName != null && iceName!.isNotEmpty &&
        icePhone != null && icePhone!.isNotEmpty &&
        carBrand != null && carBrand!.isNotEmpty &&
        carModel != null && carModel!.isNotEmpty;
  }

  /// Get list of missing mandatory fields
  List<String> get missingFields {
    final missing = <String>[];
    
    if (firstName.isEmpty) missing.add('First Name');
    if (lastName.isEmpty) missing.add('Last Name');
    if (!(phone?.isNotEmpty ?? phoneNumber?.isNotEmpty ?? false)) {
      missing.add('Phone Number');
    }
    if (dob == null || dob!.isEmpty) missing.add('Date of Birth');
    if (gender == null || gender!.isEmpty) missing.add('Gender');
    if (nationality == null || nationality!.isEmpty) missing.add('Nationality');
    if (iceName == null || iceName!.isEmpty) missing.add('Emergency Contact Name');
    if (icePhone == null || icePhone!.isEmpty) missing.add('Emergency Contact Phone');
    if (carBrand == null || carBrand!.isEmpty) missing.add('Car Brand');
    if (carModel == null || carModel!.isEmpty) missing.add('Car Model');
    
    return missing;
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
      avatar: json['avatar'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      paidMember: json['paid_member'] as bool? ?? json['paidMember'] as bool? ?? false,
      carBrand: json['car_brand'] as String? ?? json['carBrand'] as String?,
      carModel: json['car_model'] as String? ?? json['carModel'] as String?,
      carYear: json['car_year'] as int? ?? json['carYear'] as int?,
      carColor: json['car_color'] as String? ?? json['carColor'] as String?,
      carImage: json['car_image'] as String? ?? json['carImage'] as String?,
      dob: json['dob'] as String?,
      iceName: json['ice_name'] as String? ?? json['iceName'] as String?,
      icePhone: json['ice_phone'] as String? ?? json['icePhone'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] != null
          ? (json['gender'] is Map ? json['gender']['name'] as String? : json['gender'] as String?)
          : null,
      nationality: json['nationality'] != null
          ? (json['nationality'] is Map ? json['nationality']['name'] as String? : json['nationality'] as String?)
          : null,
      title: json['title'] as String?,
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
      'avatar': avatar,
      'phone_number': phoneNumber,
      'phone': phone,
      'is_active': isActive,
      'paid_member': paidMember,
      'car_brand': carBrand,
      'car_model': carModel,
      'car_year': carYear,
      'car_color': carColor,
      'car_image': carImage,
      'dob': dob,
      'ice_name': iceName,
      'ice_phone': icePhone,
      'city': city,
      'gender': gender,
      'nationality': nationality,
      'title': title,
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
