/// Vehicle Modifications Model
/// 
/// Tracks vehicle modifications for trip eligibility verification.
/// This is a production-ready model with mock cache storage using Hive.
/// 
/// Backend API Placeholder: When backend is ready, replace cache with API calls.
library;

class VehicleModifications {
  final String id; // Unique ID (UUID in cache, backend ID in production)
  final int vehicleId; // FK to Vehicle (or vehicle identifier)
  final int memberId; // FK to Member
  
  // ==================== SUSPENSION & TIRES ====================
  final LiftKitType liftKit;
  final ShocksType shocksType;
  final ArmsType arms;
  final TyreSizeType tyreSize;
  
  // ==================== ENGINE ====================
  final AirIntakeType airIntake;
  final CatbackType catback;
  final HorsepowerType horsepower;
  
  // ==================== EQUIPMENT ====================
  final OffRoadLightType offRoadLight;
  final WinchType winch;
  final ArmorType armor;
  
  // ==================== VERIFICATION ====================
  final VerificationStatus verificationStatus;
  final VerificationType verificationType;
  final int? verifiedByMarshalId; // Marshal who verified
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? verificationNotes;
  
  // ==================== TIMESTAMPS ====================
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModifications({
    required this.id,
    required this.vehicleId,
    required this.memberId,
    this.liftKit = LiftKitType.stock,
    this.shocksType = ShocksType.normal,
    this.arms = ArmsType.normal,
    this.tyreSize = TyreSizeType.size32,
    this.airIntake = AirIntakeType.normal,
    this.catback = CatbackType.normal,
    this.horsepower = HorsepowerType.hp100_200,
    this.offRoadLight = OffRoadLightType.no,
    this.winch = WinchType.no,
    this.armor = ArmorType.no,
    this.verificationStatus = VerificationStatus.pending,
    this.verificationType = VerificationType.onTrip,
    this.verifiedByMarshalId,
    this.verifiedAt,
    this.rejectionReason,
    this.verificationNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON (backend or cache)
  factory VehicleModifications.fromJson(Map<String, dynamic> json) {
    return VehicleModifications(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as int? ?? json['vehicleId'] as int,
      memberId: json['member_id'] as int? ?? json['memberId'] as int,
      liftKit: LiftKitType.fromString(json['lift_kit'] as String? ?? json['liftKit'] as String? ?? 'stock'),
      shocksType: ShocksType.fromString(json['shocks_type'] as String? ?? json['shocksType'] as String? ?? 'normal'),
      arms: ArmsType.fromString(json['arms'] as String? ?? 'normal'),
      tyreSize: TyreSizeType.fromString(json['tyre_size'] as String? ?? json['tyreSize'] as String? ?? '32'),
      airIntake: AirIntakeType.fromString(json['air_intake'] as String? ?? json['airIntake'] as String? ?? 'normal'),
      catback: CatbackType.fromString(json['catback'] as String? ?? 'normal'),
      horsepower: HorsepowerType.fromString(json['horsepower'] as String? ?? 'hp100_200'),
      offRoadLight: OffRoadLightType.fromString(json['off_road_light'] as String? ?? json['offRoadLight'] as String? ?? 'no'),
      winch: WinchType.fromString(json['winch'] as String? ?? 'no'),
      armor: ArmorType.fromString(json['armor'] as String? ?? 'no'),
      verificationStatus: VerificationStatus.fromString(json['verification_status'] as String? ?? json['verificationStatus'] as String? ?? 'pending'),
      verificationType: VerificationType.fromString(json['verification_type'] as String? ?? json['verificationType'] as String? ?? 'on_trip'),
      verifiedByMarshalId: json['verified_by_marshal_id'] as int? ?? json['verifiedByMarshalId'] as int?,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      rejectionReason: json['rejection_reason'] as String? ?? json['rejectionReason'] as String?,
      verificationNotes: json['verification_notes'] as String? ?? json['verificationNotes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON (for cache or backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'member_id': memberId,
      'lift_kit': liftKit.value,
      'shocks_type': shocksType.value,
      'arms': arms.value,
      'tyre_size': tyreSize.value,
      'air_intake': airIntake.value,
      'catback': catback.value,
      'horsepower': horsepower.value,
      'off_road_light': offRoadLight.value,
      'winch': winch.value,
      'armor': armor.value,
      'verification_status': verificationStatus.value,
      'verification_type': verificationType.value,
      'verified_by_marshal_id': verifiedByMarshalId,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'verification_notes': verificationNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  VehicleModifications copyWith({
    String? id,
    int? vehicleId,
    int? memberId,
    LiftKitType? liftKit,
    ShocksType? shocksType,
    ArmsType? arms,
    TyreSizeType? tyreSize,
    AirIntakeType? airIntake,
    CatbackType? catback,
    HorsepowerType? horsepower,
    OffRoadLightType? offRoadLight,
    WinchType? winch,
    ArmorType? armor,
    VerificationStatus? verificationStatus,
    VerificationType? verificationType,
    int? verifiedByMarshalId,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? verificationNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModifications(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      memberId: memberId ?? this.memberId,
      liftKit: liftKit ?? this.liftKit,
      shocksType: shocksType ?? this.shocksType,
      arms: arms ?? this.arms,
      tyreSize: tyreSize ?? this.tyreSize,
      airIntake: airIntake ?? this.airIntake,
      catback: catback ?? this.catback,
      horsepower: horsepower ?? this.horsepower,
      offRoadLight: offRoadLight ?? this.offRoadLight,
      winch: winch ?? this.winch,
      armor: armor ?? this.armor,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationType: verificationType ?? this.verificationType,
      verifiedByMarshalId: verifiedByMarshalId ?? this.verifiedByMarshalId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if modifications are verified
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Check if modifications are pending
  bool get isPending => verificationStatus == VerificationStatus.pending;

  /// Check if modifications were rejected
  bool get isRejected => verificationStatus == VerificationStatus.rejected;

  /// Get verification status display text
  String get verificationStatusText {
    switch (verificationStatus) {
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  /// Check if modifications meet trip requirements
  bool meetsRequirements(TripVehicleRequirements requirements) {
    // Only verified modifications count
    if (!isVerified) return false;

    // Check lift kit requirement
    if (requirements.minLiftKit != null) {
      if (liftKit.compareTo(requirements.minLiftKit!) < 0) return false;
    }

    // Check shocks requirement
    if (requirements.minShocksType != null) {
      if (shocksType.compareTo(requirements.minShocksType!) < 0) return false;
    }

    // Check arms requirement
    if (requirements.requireLongTravelArms == true) {
      if (arms != ArmsType.longTravel) return false;
    }

    // Check tyre size requirement
    if (requirements.minTyreSize != null) {
      if (tyreSize.compareTo(requirements.minTyreSize!) < 0) return false;
    }

    // Check horsepower requirement
    if (requirements.minHorsepower != null) {
      if (horsepower.compareTo(requirements.minHorsepower!) < 0) return false;
    }

    // Check air intake requirement
    if (requirements.requirePerformanceIntake == true) {
      if (airIntake != AirIntakeType.performance) return false;
    }

    // Check catback requirement
    if (requirements.requirePerformanceCatback == true) {
      if (catback != CatbackType.performance) return false;
    }

    // Check off-road light requirement
    if (requirements.requireOffRoadLight == true) {
      if (offRoadLight == OffRoadLightType.no) return false;
    }

    // Check winch requirement
    if (requirements.requireWinch == true) {
      if (winch == WinchType.no) return false;
    }

    // Check armor requirement
    if (requirements.requireArmor == true) {
      if (armor == ArmorType.no) return false;
    }

    return true;
  }
}

// ==================== ENUMS WITH COMPARISON SUPPORT ====================

enum LiftKitType {
  stock('stock', 'Stock Height', 0),
  inch1('1_inch', '1 Inch', 1),
  inch2('2_inch', '2 Inch', 2),
  inch2_5('2.5_inch', '2.5 Inch', 3),
  inch3('3_inch', '3 Inch', 4),
  inch3_5('3.5_inch', '3.5 Inch', 5),
  inch4Plus('4_inch_plus', '4 Inch+', 6);

  final String value;
  final String displayName;
  final int level;
  const LiftKitType(this.value, this.displayName, this.level);

  static LiftKitType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => stock);
  }

  int compareTo(LiftKitType other) => level.compareTo(other.level);
}

enum ShocksType {
  normal('normal', 'Normal', 0),
  bypass('bypass', 'Bypass', 1),
  tripleBypass('triple_bypass', 'Triple Bypass', 2);

  final String value;
  final String displayName;
  final int level;
  const ShocksType(this.value, this.displayName, this.level);

  static ShocksType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => normal);
  }

  int compareTo(ShocksType other) => level.compareTo(other.level);
}

enum ArmsType {
  normal('normal', 'Normal', 0),
  longTravel('long_travel', 'Long Travel', 1);

  final String value;
  final String displayName;
  final int level;
  const ArmsType(this.value, this.displayName, this.level);

  static ArmsType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => normal);
  }

  int compareTo(ArmsType other) => level.compareTo(other.level);
}

enum TyreSizeType {
  size32('32', '32"', 32),
  size33('33', '33"', 33),
  size34('34', '34"', 34),
  size35('35', '35"', 35),
  size37Plus('37_plus', '37"+', 37);

  final String value;
  final String displayName;
  final int level;
  const TyreSizeType(this.value, this.displayName, this.level);

  static TyreSizeType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => size32);
  }

  int compareTo(TyreSizeType other) => level.compareTo(other.level);
}

enum AirIntakeType {
  normal('normal', 'Normal', 0),
  performance('performance', 'Performance', 1);

  final String value;
  final String displayName;
  final int level;
  const AirIntakeType(this.value, this.displayName, this.level);

  static AirIntakeType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => normal);
  }

  int compareTo(AirIntakeType other) => level.compareTo(other.level);
}

enum CatbackType {
  normal('normal', 'Normal', 0),
  performance('performance', 'Performance', 1);

  final String value;
  final String displayName;
  final int level;
  const CatbackType(this.value, this.displayName, this.level);

  static CatbackType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => normal);
  }

  int compareTo(CatbackType other) => level.compareTo(other.level);
}

enum HorsepowerType {
  hp100_200('hp100_200', '100HP - 200HP', 0),
  hp200_300('hp200_300', '200HP - 300HP', 1),
  hp300_400('hp300_400', '300HP - 400HP', 2),
  hp500Plus('hp500_plus', '500+ HP', 3);

  final String value;
  final String displayName;
  final int level;
  const HorsepowerType(this.value, this.displayName, this.level);

  static HorsepowerType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => hp100_200);
  }

  int compareTo(HorsepowerType other) => level.compareTo(other.level);
}

enum OffRoadLightType {
  no('no', 'No', 0),
  yes('yes', 'Yes', 1),
  aLot('a_lot', 'A Lot!', 2);

  final String value;
  final String displayName;
  final int level;
  const OffRoadLightType(this.value, this.displayName, this.level);

  static OffRoadLightType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => no);
  }

  int compareTo(OffRoadLightType other) => level.compareTo(other.level);
}

enum WinchType {
  no('no', 'No', 0),
  yes('yes', 'Yes', 1);

  final String value;
  final String displayName;
  final int level;
  const WinchType(this.value, this.displayName, this.level);

  static WinchType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => no);
  }

  int compareTo(WinchType other) => level.compareTo(other.level);
}

enum ArmorType {
  no('no', 'No', 0),
  steelBumpers('steel_bumpers', 'Steel Bumpers', 1);

  final String value;
  final String displayName;
  final int level;
  const ArmorType(this.value, this.displayName, this.level);

  static ArmorType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => no);
  }

  int compareTo(ArmorType other) => level.compareTo(other.level);
}

// ==================== VERIFICATION ENUMS ====================

enum VerificationStatus {
  pending('pending', 'Pending Verification'),
  approved('approved', 'Verified'),
  rejected('rejected', 'Rejected');

  final String value;
  final String displayName;
  const VerificationStatus(this.value, this.displayName);

  static VerificationStatus fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => pending);
  }
}

enum VerificationType {
  onTrip('on_trip', 'On-Trip Verification'),
  expedited('expedited', 'Expedited Online Verification');

  final String value;
  final String displayName;
  const VerificationType(this.value, this.displayName);

  static VerificationType fromString(String value) {
    return values.firstWhere((e) => e.value == value, orElse: () => onTrip);
  }
}

// ==================== TRIP REQUIREMENTS MODEL ====================

/// Trip Vehicle Requirements Model
/// 
/// Defines minimum vehicle modifications required for a trip.
/// Marshals set these when creating Advanced/Expert trips.
class TripVehicleRequirements {
  final String id;
  final int tripId;
  
  // Suspension & Tires (nullable = not required)
  final LiftKitType? minLiftKit;
  final ShocksType? minShocksType;
  final bool? requireLongTravelArms;
  final TyreSizeType? minTyreSize;
  
  // Engine (nullable = not required)
  final HorsepowerType? minHorsepower;
  final bool? requirePerformanceIntake;
  final bool? requirePerformanceCatback;
  
  // Equipment (nullable = not required)
  final bool? requireOffRoadLight;
  final bool? requireWinch;
  final bool? requireArmor;
  
  final DateTime createdAt;

  const TripVehicleRequirements({
    required this.id,
    required this.tripId,
    this.minLiftKit,
    this.minShocksType,
    this.requireLongTravelArms,
    this.minTyreSize,
    this.minHorsepower,
    this.requirePerformanceIntake,
    this.requirePerformanceCatback,
    this.requireOffRoadLight,
    this.requireWinch,
    this.requireArmor,
    required this.createdAt,
  });

  factory TripVehicleRequirements.fromJson(Map<String, dynamic> json) {
    return TripVehicleRequirements(
      id: json['id'] as String,
      tripId: json['trip_id'] as int? ?? json['tripId'] as int,
      minLiftKit: json['min_lift_kit'] != null ? LiftKitType.fromString(json['min_lift_kit'] as String) : null,
      minShocksType: json['min_shocks_type'] != null ? ShocksType.fromString(json['min_shocks_type'] as String) : null,
      requireLongTravelArms: json['require_long_travel_arms'] as bool?,
      minTyreSize: json['min_tyre_size'] != null ? TyreSizeType.fromString(json['min_tyre_size'] as String) : null,
      minHorsepower: json['min_horsepower'] != null ? HorsepowerType.fromString(json['min_horsepower'] as String) : null,
      requirePerformanceIntake: json['require_performance_intake'] as bool?,
      requirePerformanceCatback: json['require_performance_catback'] as bool?,
      requireOffRoadLight: json['require_off_road_light'] as bool?,
      requireWinch: json['require_winch'] as bool?,
      requireArmor: json['require_armor'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'min_lift_kit': minLiftKit?.value,
      'min_shocks_type': minShocksType?.value,
      'require_long_travel_arms': requireLongTravelArms,
      'min_tyre_size': minTyreSize?.value,
      'min_horsepower': minHorsepower?.value,
      'require_performance_intake': requirePerformanceIntake,
      'require_performance_catback': requirePerformanceCatback,
      'require_off_road_light': requireOffRoadLight,
      'require_winch': requireWinch,
      'require_armor': requireArmor,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if any requirements are set
  bool get hasRequirements {
    return minLiftKit != null ||
        minShocksType != null ||
        requireLongTravelArms == true ||
        minTyreSize != null ||
        minHorsepower != null ||
        requirePerformanceIntake == true ||
        requirePerformanceCatback == true ||
        requireOffRoadLight == true ||
        requireWinch == true ||
        requireArmor == true;
  }

  /// Get human-readable requirements list
  List<String> getRequirementsList() {
    final List<String> requirements = [];
    
    if (minLiftKit != null) requirements.add('Lift Kit: Minimum ${minLiftKit!.displayName}');
    if (minShocksType != null) requirements.add('Shocks: Minimum ${minShocksType!.displayName}');
    if (requireLongTravelArms == true) requirements.add('Arms: Long Travel Required');
    if (minTyreSize != null) requirements.add('Tyre Size: Minimum ${minTyreSize!.displayName}');
    if (minHorsepower != null) requirements.add('Horsepower: Minimum ${minHorsepower!.displayName}');
    if (requirePerformanceIntake == true) requirements.add('Air Intake: Performance Required');
    if (requirePerformanceCatback == true) requirements.add('Catback: Performance Required');
    if (requireOffRoadLight == true) requirements.add('Off-Road Light: Required');
    if (requireWinch == true) requirements.add('Winch: Required');
    if (requireArmor == true) requirements.add('Armor: Steel Bumpers Required');
    
    return requirements;
  }
}
