import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../lib/core/services/vehicle_modifications_cache_service.dart';
import '../lib/data/models/vehicle_modifications_model.dart';

/// Quick test script to add sample vehicle modifications to SharedPreferences
/// Run with: dart run scripts/add_test_vehicle_mods.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Adding test vehicle modifications...');
  
  final prefs = await SharedPreferences.getInstance();
  final service = VehicleModificationsCacheService(prefs);
  
  // Create 2 test vehicle modifications for member ID 1
  final testMod1 = VehicleModifications(
    id: 'test_mod_1',
    memberId: 1,
    vehicleId: 101,
    liftKit: LiftKitType.medium_2_3_inch,
    shocksType: ShocksType.fox,
    longTravelArms: true,
    tyreSize: TyreSizeType.size_35_inch,
    horsepower: HorsepowerType.hp_300_350,
    performanceIntake: true,
    performanceCatback: false,
    offRoadLight: LightType.pod_light,
    winch: true,
    armor: ArmorType.skid_plates,
    verificationStatus: VerificationStatus.approved,
    verificationType: VerificationType.on_trip,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final testMod2 = VehicleModifications(
    id: 'test_mod_2',
    memberId: 1,
    vehicleId: 102,
    liftKit: LiftKitType.heavy_6_plus_inch,
    shocksType: ShocksType.king,
    longTravelArms: true,
    tyreSize: TyreSizeType.size_37_inch,
    horsepower: HorsepowerType.hp_400_plus,
    performanceIntake: true,
    performanceCatback: true,
    offRoadLight: LightType.light_bar,
    winch: true,
    armor: ArmorType.full_armor,
    verificationStatus: VerificationStatus.pending,
    verificationType: VerificationType.expedited,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now(),
  );
  
  await service.saveModifications(testMod1);
  await service.saveModifications(testMod2);
  
  print('✅ Added 2 test vehicle modifications for member ID 1');
  print('   - Vehicle #101: Medium lift, Fox shocks, 35" tires (APPROVED)');
  print('   - Vehicle #102: Heavy lift, King shocks, 37" tires (PENDING)');
  print('');
  print('🔄 Now refresh the profile page to see the "Vehicle Modifications" section!');
  print('   Location: Between "Contact Information" and "Emergency Contact" sections');
  
  exit(0);
}
