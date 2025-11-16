import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/vehicle_modifications_model.dart';

/// Vehicle Modifications Cache Service
/// 
/// Mock storage using SharedPreferences for development.
/// Ready for production - just replace with API calls when backend is ready.
/// 
/// PRODUCTION NOTE: Replace all cache methods with HTTP calls to backend API.
/// See BACKEND_API_DOCUMENTATION.md for endpoint specifications.

class VehicleModificationsCacheService {
  static const String _cacheKeyPrefix = 'vehicle_mods_';
  static const String _requirementsCachePrefix = 'trip_requirements_';
  static const String _verificationQueueKey = 'verification_queue';
  
  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  VehicleModificationsCacheService(this._prefs);

  // ==================== VEHICLE MODIFICATIONS CRUD ====================

  /// Save vehicle modifications (member submits modifications)
  /// 
  /// PRODUCTION: Replace with POST /api/members/{memberId}/vehicles/{vehicleId}/modifications
  Future<VehicleModifications> saveModifications(VehicleModifications mods) async {
    final modWithId = VehicleModifications(
      id: mods.id.isEmpty ? _uuid.v4() : mods.id,
      vehicleId: mods.vehicleId,
      memberId: mods.memberId,
      liftKit: mods.liftKit,
      shocksType: mods.shocksType,
      arms: mods.arms,
      tyreSize: mods.tyreSize,
      airIntake: mods.airIntake,
      catback: mods.catback,
      horsepower: mods.horsepower,
      offRoadLight: mods.offRoadLight,
      winch: mods.winch,
      armor: mods.armor,
      verificationStatus: mods.verificationStatus,
      verificationType: mods.verificationType,
      verifiedByMarshalId: mods.verifiedByMarshalId,
      verifiedAt: mods.verifiedAt,
      rejectionReason: mods.rejectionReason,
      verificationNotes: mods.verificationNotes,
      createdAt: mods.id.isEmpty ? DateTime.now() : mods.createdAt,
      updatedAt: DateTime.now(),
    );

    final key = '$_cacheKeyPrefix${modWithId.vehicleId}';
    final json = jsonEncode(modWithId.toJson());
    await _prefs.setString(key, json);

    // Add to verification queue if pending
    if (modWithId.isPending) {
      await _addToVerificationQueue(modWithId);
    }

    return modWithId;
  }

  /// Get vehicle modifications by vehicle ID
  /// 
  /// PRODUCTION: Replace with GET /api/members/{memberId}/vehicles/{vehicleId}/modifications
  Future<VehicleModifications?> getModificationsByVehicleId(int vehicleId) async {
    final key = '$_cacheKeyPrefix$vehicleId';
    final json = _prefs.getString(key);
    if (json == null) return null;

    final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;
    return VehicleModifications.fromJson(data);
  }

  /// Get modifications by member ID (all vehicles)
  /// 
  /// PRODUCTION: Replace with GET /api/members/{memberId}/vehicles/modifications
  Future<List<VehicleModifications>> getModificationsByMemberId(int memberId) async {
    final List<VehicleModifications> allMods = [];
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));

    for (final key in keys) {
      final json = _prefs.getString(key);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final mods = VehicleModifications.fromJson(data);
        if (mods.memberId == memberId) {
          allMods.add(mods);
        }
      }
    }

    return allMods;
  }

  /// Delete vehicle modifications
  /// 
  /// PRODUCTION: Replace with DELETE /api/members/{memberId}/vehicles/{vehicleId}/modifications
  Future<void> deleteModifications(int vehicleId) async {
    final key = '$_cacheKeyPrefix$vehicleId';
    await _prefs.remove(key);
  }

  // ==================== VERIFICATION QUEUE (MARSHAL PANEL) ====================

  /// Add modifications to verification queue
  Future<void> _addToVerificationQueue(VehicleModifications mods) async {
    final queueJson = _prefs.getString(_verificationQueueKey);
    final List<dynamic> queue = queueJson != null ? jsonDecode(queueJson) as List<dynamic> : [];
    
    // Remove existing entry if already in queue
    queue.removeWhere((item) => item['vehicle_id'] == mods.vehicleId);
    
    // Add to queue
    queue.add(mods.toJson());
    
    await _prefs.setString(_verificationQueueKey, jsonEncode(queue));
  }

  /// Get verification queue (pending modifications for marshals)
  /// 
  /// PRODUCTION: Replace with GET /api/admin/vehicle-modifications/verification-queue
  Future<List<VehicleModifications>> getVerificationQueue() async {
    final queueJson = _prefs.getString(_verificationQueueKey);
    if (queueJson == null) return [];

    final List<dynamic> queue = jsonDecode(queueJson) as List<dynamic>;
    return queue.map((item) => VehicleModifications.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Approve vehicle modifications (marshal action)
  /// 
  /// PRODUCTION: Replace with POST /api/admin/vehicle-modifications/{id}/approve
  Future<VehicleModifications> approveModifications({
    required String modificationId,
    required int marshalId,
    String? notes,
  }) async {
    // Find modification by ID
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
    for (final key in keys) {
      final json = _prefs.getString(key);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final mods = VehicleModifications.fromJson(data);
        
        if (mods.id == modificationId) {
          final approved = mods.copyWith(
            verificationStatus: VerificationStatus.approved,
            verifiedByMarshalId: marshalId,
            verifiedAt: DateTime.now(),
            verificationNotes: notes,
            updatedAt: DateTime.now(),
          );
          
          await _prefs.setString(key, jsonEncode(approved.toJson()));
          await _removeFromVerificationQueue(modificationId);
          
          return approved;
        }
      }
    }

    throw Exception('Modification not found: $modificationId');
  }

  /// Reject vehicle modifications (marshal action)
  /// 
  /// PRODUCTION: Replace with POST /api/admin/vehicle-modifications/{id}/reject
  Future<VehicleModifications> rejectModifications({
    required String modificationId,
    required int marshalId,
    required String reason,
  }) async {
    // Find modification by ID
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
    for (final key in keys) {
      final json = _prefs.getString(key);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final mods = VehicleModifications.fromJson(data);
        
        if (mods.id == modificationId) {
          final rejected = mods.copyWith(
            verificationStatus: VerificationStatus.rejected,
            verifiedByMarshalId: marshalId,
            verifiedAt: DateTime.now(),
            rejectionReason: reason,
            updatedAt: DateTime.now(),
          );
          
          await _prefs.setString(key, jsonEncode(rejected.toJson()));
          await _removeFromVerificationQueue(modificationId);
          
          return rejected;
        }
      }
    }

    throw Exception('Modification not found: $modificationId');
  }

  /// Remove from verification queue
  Future<void> _removeFromVerificationQueue(String modificationId) async {
    final queueJson = _prefs.getString(_verificationQueueKey);
    if (queueJson == null) return;

    final List<dynamic> queue = jsonDecode(queueJson) as List<dynamic>;
    queue.removeWhere((item) => item['id'] == modificationId);
    
    await _prefs.setString(_verificationQueueKey, jsonEncode(queue));
  }

  // ==================== TRIP REQUIREMENTS CRUD ====================

  /// Save trip vehicle requirements
  /// 
  /// PRODUCTION: Replace with POST /api/trips/{tripId}/vehicle-requirements
  Future<TripVehicleRequirements> saveRequirements(TripVehicleRequirements requirements) async {
    final reqWithId = TripVehicleRequirements(
      id: requirements.id.isEmpty ? _uuid.v4() : requirements.id,
      tripId: requirements.tripId,
      minLiftKit: requirements.minLiftKit,
      minShocksType: requirements.minShocksType,
      requireLongTravelArms: requirements.requireLongTravelArms,
      minTyreSize: requirements.minTyreSize,
      minHorsepower: requirements.minHorsepower,
      requirePerformanceIntake: requirements.requirePerformanceIntake,
      requirePerformanceCatback: requirements.requirePerformanceCatback,
      requireOffRoadLight: requirements.requireOffRoadLight,
      requireWinch: requirements.requireWinch,
      requireArmor: requirements.requireArmor,
      createdAt: requirements.id.isEmpty ? DateTime.now() : requirements.createdAt,
    );

    final key = '$_requirementsCachePrefix${reqWithId.tripId}';
    final json = jsonEncode(reqWithId.toJson());
    await _prefs.setString(key, json);

    return reqWithId;
  }

  /// Get trip vehicle requirements by trip ID
  /// 
  /// PRODUCTION: Replace with GET /api/trips/{tripId}/vehicle-requirements
  Future<TripVehicleRequirements?> getRequirementsByTripId(int tripId) async {
    final key = '$_requirementsCachePrefix$tripId';
    final json = _prefs.getString(key);
    if (json == null) return null;

    final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;
    return TripVehicleRequirements.fromJson(data);
  }

  /// Delete trip vehicle requirements
  /// 
  /// PRODUCTION: Replace with DELETE /api/trips/{tripId}/vehicle-requirements
  Future<void> deleteRequirements(int tripId) async {
    final key = '$_requirementsCachePrefix$tripId';
    await _prefs.remove(key);
  }

  // ==================== VALIDATION ====================

  /// Check if member's vehicle meets trip requirements
  /// 
  /// PRODUCTION: Replace with GET /api/trips/{tripId}/check-eligibility?memberId={memberId}&vehicleId={vehicleId}
  Future<bool> checkEligibility({
    required int tripId,
    required int vehicleId,
  }) async {
    final requirements = await getRequirementsByTripId(tripId);
    if (requirements == null || !requirements.hasRequirements) {
      return true; // No requirements = always eligible
    }

    final modifications = await getModificationsByVehicleId(vehicleId);
    if (modifications == null) {
      return false; // No modifications = not eligible if requirements exist
    }

    return modifications.meetsRequirements(requirements);
  }

  /// Get unmet requirements for a vehicle (for warning messages)
  /// 
  /// PRODUCTION: Replace with GET /api/trips/{tripId}/unmet-requirements?memberId={memberId}&vehicleId={vehicleId}
  Future<List<String>> getUnmetRequirements({
    required int tripId,
    required int vehicleId,
  }) async {
    final requirements = await getRequirementsByTripId(tripId);
    if (requirements == null || !requirements.hasRequirements) {
      return [];
    }

    final modifications = await getModificationsByVehicleId(vehicleId);
    if (modifications == null) {
      return requirements.getRequirementsList();
    }

    final List<String> unmet = [];

    if (requirements.minLiftKit != null) {
      if (!modifications.isVerified || modifications.liftKit.compareTo(requirements.minLiftKit!) < 0) {
        unmet.add('Lift Kit: Minimum ${requirements.minLiftKit!.displayName} (You have: ${modifications.liftKit.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.minShocksType != null) {
      if (!modifications.isVerified || modifications.shocksType.compareTo(requirements.minShocksType!) < 0) {
        unmet.add('Shocks: Minimum ${requirements.minShocksType!.displayName} (You have: ${modifications.shocksType.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requireLongTravelArms == true) {
      if (!modifications.isVerified || modifications.arms != ArmsType.longTravel) {
        unmet.add('Arms: Long Travel Required (You have: ${modifications.arms.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.minTyreSize != null) {
      if (!modifications.isVerified || modifications.tyreSize.compareTo(requirements.minTyreSize!) < 0) {
        unmet.add('Tyre Size: Minimum ${requirements.minTyreSize!.displayName} (You have: ${modifications.tyreSize.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.minHorsepower != null) {
      if (!modifications.isVerified || modifications.horsepower.compareTo(requirements.minHorsepower!) < 0) {
        unmet.add('Horsepower: Minimum ${requirements.minHorsepower!.displayName} (You have: ${modifications.horsepower.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requirePerformanceIntake == true) {
      if (!modifications.isVerified || modifications.airIntake != AirIntakeType.performance) {
        unmet.add('Air Intake: Performance Required (You have: ${modifications.airIntake.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requirePerformanceCatback == true) {
      if (!modifications.isVerified || modifications.catback != CatbackType.performance) {
        unmet.add('Catback: Performance Required (You have: ${modifications.catback.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requireOffRoadLight == true) {
      if (!modifications.isVerified || modifications.offRoadLight == OffRoadLightType.no) {
        unmet.add('Off-Road Light: Required (You have: ${modifications.offRoadLight.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requireWinch == true) {
      if (!modifications.isVerified || modifications.winch == WinchType.no) {
        unmet.add('Winch: Required (You have: ${modifications.winch.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    if (requirements.requireArmor == true) {
      if (!modifications.isVerified || modifications.armor == ArmorType.no) {
        unmet.add('Armor: Steel Bumpers Required (You have: ${modifications.armor.displayName}${modifications.isVerified ? ' ✅' : ' ⏳ Pending'})');
      }
    }

    return unmet;
  }

  // ==================== UTILITY ====================

  /// Clear all cached data (for testing/development)
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys().where((k) => 
      k.startsWith(_cacheKeyPrefix) || 
      k.startsWith(_requirementsCachePrefix) ||
      k == _verificationQueueKey
    );
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
