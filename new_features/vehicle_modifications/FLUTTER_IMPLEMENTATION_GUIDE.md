# Vehicle Modifications System - Flutter Implementation Guide

**Version:** 2.0  
**Feature Request Date:** November 11, 2025  
**Last Updated:** November 16, 2024  
**Target:** Flutter Mobile App (AD4x4)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Changes](#architecture-changes)
3. [Model Updates](#model-updates)
4. [API Service Implementation](#api-service-implementation)
5. [UI Components](#ui-components)
6. [State Management](#state-management)
7. [Migration Strategy](#migration-strategy)
8. [Testing Requirements](#testing-requirements)

---

## Overview

### Current State (v1.0 - Development)
- ✅ Complete data models with hardcoded enums
- ✅ Cache service using SharedPreferences
- ✅ UI dialogs for validation
- ✅ Permission-based access checks
- ⚠️ All modification options hardcoded in Flutter

### Target State (v2.0 - Production)
- 🎯 Dynamic modification choices from backend API
- 🎯 Real API integration replacing cache service
- 🎯 Level-flexible requirements system
- 🎯 Permission-based verification (marshal → verifier)
- 🎯 Backward compatible migration

---

## Architecture Changes

### Phase 1: Add Dynamic Choices Support (2-3 hours)

#### **1. Create ModificationChoice Model**

**File:** `lib/data/models/modification_choice_model.dart`

```dart
/// Dynamic Modification Choice Model
/// 
/// Loaded from backend /api/choices/ endpoints
class ModificationChoice {
  final String value;           // Internal value: 'stock', '1_inch'
  final String displayName;     // Display text: "Stock Height", "1 Inch"
  final int level;             // Comparison level (0-10)
  final String? description;   // Optional help text
  final bool active;           // Can be deactivated
  
  const ModificationChoice({
    required this.value,
    required this.displayName,
    required this.level,
    this.description,
    this.active = true,
  });
  
  factory ModificationChoice.fromJson(Map<String, dynamic> json) {
    return ModificationChoice(
      value: json['value'] as String,
      displayName: json['displayName'] as String? ?? json['display_name'] as String,
      level: json['level'] as int,
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'displayName': displayName,
      'level': level,
      'description': description,
      'active': active,
    };
  }
  
  /// Compare with another choice (for requirement validation)
  int compareTo(ModificationChoice other) => level.compareTo(other.level);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationChoice &&
          runtimeType == other.runtimeType &&
          value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}
```

#### **2. Create Choices Provider (Riverpod)**

**File:** `lib/features/vehicles/presentation/providers/modification_choices_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/modification_choice_model.dart';
import '../../../../data/repositories/vehicle_modifications_api_repository.dart';

/// Provider for modification choices
/// Loads all choices on app start and caches them
class ModificationChoicesNotifier extends StateNotifier<AsyncValue<Map<String, List<ModificationChoice>>>> {
  final VehicleModificationsApiRepository _repository;
  
  ModificationChoicesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAllChoices();
  }
  
  /// Load all modification choices from backend
  Future<void> loadAllChoices() async {
    state = const AsyncValue.loading();
    
    try {
      final choiceTypes = [
        'liftkit', 'shockstype', 'arms', 'tyresizemods',
        'airintake', 'catback', 'horsepower', 'offroadlight',
        'winch', 'armor'
      ];
      
      final Map<String, List<ModificationChoice>> allChoices = {};
      
      for (final type in choiceTypes) {
        allChoices[type] = await _repository.getChoices(type);
      }
      
      state = AsyncValue.data(allChoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Get choices for a specific type
  List<ModificationChoice> getChoices(String type) {
    return state.whenData((choices) => choices[type] ?? []).value ?? [];
  }
  
  /// Get choice by value
  ModificationChoice? getChoice(String type, String value) {
    final choices = getChoices(type);
    try {
      return choices.firstWhere((c) => c.value == value);
    } catch (e) {
      return null;
    }
  }
  
  /// Refresh choices (e.g., after admin updates)
  Future<void> refresh() => loadAllChoices();
}

// Provider instance
final modificationChoicesProvider = StateNotifierProvider<ModificationChoicesNotifier, AsyncValue<Map<String, List<ModificationChoice>>>>((ref) {
  final repository = ref.watch(vehicleModificationsApiRepositoryProvider);
  return ModificationChoicesNotifier(repository);
});

// Helper providers for specific choice types
final liftKitChoicesProvider = Provider<List<ModificationChoice>>((ref) {
  return ref.watch(modificationChoicesProvider).whenData((choices) => choices['liftkit'] ?? []).value ?? [];
});

final shocksTypeChoicesProvider = Provider<List<ModificationChoice>>((ref) {
  return ref.watch(modificationChoicesProvider).whenData((choices) => choices['shockstype'] ?? []).value ?? [];
});

// ... similar providers for other types
```

---

### Phase 2: Update Existing Models (1-2 hours)

#### **3. Update VehicleModifications Model**

**File:** `lib/data/models/vehicle_modifications_model.dart`

**Changes Required:**

1. **Replace enum fields with String + ModificationChoice**
2. **Update field names (marshal → verifier)**
3. **Add backward compatibility**

```dart
class VehicleModifications {
  final String id;
  final int vehicleId;
  final int memberId;
  
  // ==================== MODIFICATIONS (Now String values) ====================
  final String liftKit;         // Changed from LiftKitType to String
  final String shocksType;      // Changed from ShocksType to String
  final String arms;            // Changed from ArmsType to String
  final String tyreSize;        // Changed from TyreSizeType to String
  final String airIntake;       // Changed from AirIntakeType to String
  final String catback;         // Changed from CatbackType to String
  final String horsepower;      // Changed from HorsepowerType to String
  final String offRoadLight;    // Changed from OffRoadLightType to String
  final String winch;           // Changed from WinchType to String
  final String armor;           // Changed from ArmorType to String
  
  // ==================== VERIFICATION ====================
  final VerificationStatus verificationStatus;
  final VerificationType verificationType;
  final int? verifiedByUserId;  // Changed from verifiedByMarshalId
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? verifierNotes;  // Changed from marshalNotes/verificationNotes
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModifications({
    required this.id,
    required this.vehicleId,
    required this.memberId,
    this.liftKit = 'stock',
    this.shocksType = 'normal',
    this.arms = 'stock',
    this.tyreSize = '32',
    this.airIntake = 'stock',
    this.catback = 'stock',
    this.horsepower = 'stock',
    this.offRoadLight = 'none',
    this.winch = 'none',
    this.armor = 'none',
    this.verificationStatus = VerificationStatus.pending,
    this.verificationType = VerificationType.onTrip,
    this.verifiedByUserId,
    this.verifiedAt,
    this.rejectionReason,
    this.verifierNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON with backward compatibility
  factory VehicleModifications.fromJson(Map<String, dynamic> json) {
    return VehicleModifications(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as int? ?? json['vehicleId'] as int,
      memberId: json['member_id'] as int? ?? json['memberId'] as int,
      
      // Parse as String directly (backend sends strings)
      liftKit: json['lift_kit'] as String? ?? json['liftKit'] as String? ?? 'stock',
      shocksType: json['shocks_type'] as String? ?? json['shocksType'] as String? ?? 'normal',
      arms: json['arms_type'] as String? ?? json['arms'] as String? ?? 'stock',
      tyreSize: json['tyre_size'] as String? ?? json['tyreSize'] as String? ?? '32',
      airIntake: json['air_intake'] as String? ?? json['airIntake'] as String? ?? 'stock',
      catback: json['catback'] as String? ?? 'stock',
      horsepower: json['horsepower'] as String? ?? 'stock',
      offRoadLight: json['off_road_light'] as String? ?? json['offRoadLight'] as String? ?? 'none',
      winch: json['winch'] as String? ?? 'none',
      armor: json['armor'] as String? ?? 'none',
      
      verificationStatus: VerificationStatus.fromString(
        json['verification_status'] as String? ?? json['verificationStatus'] as String? ?? 'pending'
      ),
      verificationType: VerificationType.fromString(
        json['verification_type'] as String? ?? json['verificationType'] as String? ?? 'on_trip'
      ),
      
      // Support both old and new field names
      verifiedByUserId: json['verified_by_user_id'] as int? ?? 
                       json['verified_by_marshal_id'] as int? ?? 
                       json['verifiedByUserId'] as int? ??
                       json['verifiedByMarshalId'] as int?,
      
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      rejectionReason: json['rejection_reason'] as String? ?? json['rejectionReason'] as String?,
      
      // Support multiple field name variations
      verifierNotes: json['verifier_notes'] as String? ?? 
                    json['marshal_notes'] as String? ?? 
                    json['verification_notes'] as String? ??
                    json['verifierNotes'] as String?,
      
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'memberId': memberId,
      'liftKit': liftKit,
      'shocksType': shocksType,
      'armsType': arms,
      'tyreSize': tyreSize,
      'airIntake': airIntake,
      'catback': catback,
      'horsepower': horsepower,
      'offRoadLight': offRoadLight,
      'winch': winch,
      'armor': armor,
      'verificationStatus': verificationStatus.value,
      'verificationType': verificationType.value,
      'verifiedByUserId': verifiedByUserId,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'verifierNotes': verifierNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Check if modifications meet trip requirements (using dynamic choices)
  bool meetsRequirements(
    TripVehicleRequirements requirements,
    Map<String, List<ModificationChoice>> allChoices,
  ) {
    // Only verified modifications count
    if (!isVerified) return false;

    // Helper to compare values using choice levels
    bool meetsMinimum(String currentValue, String? requiredValue, String choiceType) {
      if (requiredValue == null) return true;
      
      final currentChoice = allChoices[choiceType]?.firstWhere((c) => c.value == currentValue, orElse: () => ModificationChoice(value: '', displayName: '', level: 0));
      final requiredChoice = allChoices[choiceType]?.firstWhere((c) => c.value == requiredValue, orElse: () => ModificationChoice(value: '', displayName: '', level: 0));
      
      return (currentChoice?.level ?? 0) >= (requiredChoice?.level ?? 0);
    }

    // Check all requirements
    if (!meetsMinimum(liftKit, requirements.minLiftKit, 'liftkit')) return false;
    if (!meetsMinimum(shocksType, requirements.minShocksType, 'shockstype')) return false;
    if (!meetsMinimum(tyreSize, requirements.minTyreSize, 'tyresizemods')) return false;
    if (!meetsMinimum(horsepower, requirements.minHorsepower, 'horsepower')) return false;
    
    // Check boolean requirements
    if (requirements.requireLongTravelArms == true && arms != 'long_travel') return false;
    if (requirements.requirePerformanceIntake == true && airIntake != 'performance') return false;
    if (requirements.requirePerformanceCatback == true && catback != 'performance') return false;
    if (requirements.requireOffRoadLight == true && offRoadLight == 'none') return false;
    if (requirements.requireWinch == true && winch == 'none') return false;
    if (requirements.requireArmor == true && armor == 'none') return false;

    return true;
  }
  
  // ... other methods remain similar
}
```

---

### Phase 3: API Repository Implementation (3-4 hours)

#### **4. Create API Repository**

**File:** `lib/data/repositories/vehicle_modifications_api_repository.dart`

```dart
import 'package:dio/dio.dart';
import '../models/vehicle_modifications_model.dart';
import '../models/modification_choice_model.dart';
import '../models/trip_vehicle_requirements_model.dart';
import '../../core/network/api_client.dart';

class VehicleModificationsApiRepository {
  final ApiClient _apiClient;
  
  VehicleModificationsApiRepository(this._apiClient);
  
  // ==================== CHOICES API ====================
  
  /// Get modification choices for a specific type
  Future<List<ModificationChoice>> getChoices(String choiceType) async {
    try {
      final response = await _apiClient.get('/api/choices/$choiceType');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ModificationChoice.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      throw Exception('Failed to load choices');
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== VEHICLE MODIFICATIONS CRUD ====================
  
  /// Save vehicle modifications
  Future<VehicleModifications> saveModifications(VehicleModifications mods) async {
    try {
      final response = await _apiClient.post(
        '/api/members/${mods.memberId}/vehicles/${mods.vehicleId}/modifications',
        data: mods.toJson(),
      );
      
      if (response.data['success'] == true) {
        return VehicleModifications.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to save modifications');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get modifications by vehicle ID
  Future<VehicleModifications?> getModificationsByVehicleId(int vehicleId, int memberId) async {
    try {
      final response = await _apiClient.get(
        '/api/members/$memberId/vehicles/$vehicleId/modifications',
      );
      
      if (response.data['success'] == true) {
        return VehicleModifications.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No modifications found
      }
      rethrow;
    }
  }
  
  /// Get all modifications for a member
  Future<List<VehicleModifications>> getModificationsByMemberId(int memberId) async {
    try {
      final response = await _apiClient.get('/api/members/$memberId/modifications');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VehicleModifications.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== VERIFICATION QUEUE ====================
  
  /// Get pending modifications (for verifiers)
  Future<List<VehicleModifications>> getVerificationQueue({
    String? verificationType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (verificationType != null) 'verificationType': verificationType,
      };
      
      final response = await _apiClient.get(
        '/api/admin/modifications/pending',
        queryParameters: queryParams,
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VehicleModifications.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }
  
  /// Approve modifications
  Future<VehicleModifications> approveModifications({
    required String modificationId,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/api/admin/modifications/$modificationId/verify',
        data: {
          'action': 'approve',
          if (notes != null) 'verifierNotes': notes,
        },
      );
      
      if (response.data['success'] == true) {
        return VehicleModifications.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to approve modifications');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reject modifications
  Future<VehicleModifications> rejectModifications({
    required String modificationId,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/api/admin/modifications/$modificationId/verify',
        data: {
          'action': 'reject',
          'rejectionReason': reason,
          if (notes != null) 'verifierNotes': notes,
        },
      );
      
      if (response.data['success'] == true) {
        return VehicleModifications.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to reject modifications');
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== TRIP REQUIREMENTS ====================
  
  /// Get trip requirements
  Future<TripVehicleRequirements?> getRequirementsByTripId(int tripId) async {
    try {
      final response = await _apiClient.get('/api/trips/$tripId/requirements');
      
      if (response.data['success'] == true) {
        return TripVehicleRequirements.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No requirements set
      }
      rethrow;
    }
  }
  
  /// Save trip requirements
  Future<TripVehicleRequirements> saveRequirements(TripVehicleRequirements requirements) async {
    try {
      final response = await _apiClient.post(
        '/api/trips/${requirements.tripId}/requirements',
        data: requirements.toJson(),
      );
      
      if (response.data['success'] == true) {
        return TripVehicleRequirements.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to save requirements');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete trip requirements
  Future<void> deleteRequirements(int tripId) async {
    try {
      await _apiClient.delete('/api/trips/$tripId/requirements');
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== ELIGIBILITY VALIDATION ====================
  
  /// Check if vehicle meets trip requirements
  Future<Map<String, dynamic>> checkEligibility({
    required int tripId,
    required int vehicleId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/trips/$tripId/check-eligibility',
        queryParameters: {'vehicleId': vehicleId},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      
      throw Exception('Failed to check eligibility');
    } catch (e) {
      rethrow;
    }
  }
}

// Provider
final vehicleModificationsApiRepositoryProvider = Provider<VehicleModificationsApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VehicleModificationsApiRepository(apiClient);
});
```

---

### Phase 4: UI Updates (2-3 hours)

#### **5. Update Dropdown Widgets to Use Dynamic Choices**

**Example: Lift Kit Dropdown**

**Before (Hardcoded Enum):**
```dart
DropdownButton<LiftKitType>(
  value: selectedLiftKit,
  items: LiftKitType.values.map((type) => 
    DropdownMenuItem(
      value: type,
      child: Text(type.displayName),
    )
  ).toList(),
  onChanged: (value) => setState(() => selectedLiftKit = value!),
)
```

**After (Dynamic Choices):**
```dart
Consumer(
  builder: (context, ref, child) {
    final choices = ref.watch(liftKitChoicesProvider);
    
    return DropdownButton<String>(
      value: selectedLiftKit,
      items: choices.map((choice) => 
        DropdownMenuItem(
          value: choice.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(choice.displayName),
              if (choice.description != null)
                Text(
                  choice.description!,
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        )
      ).toList(),
      onChanged: (value) => setState(() => selectedLiftKit = value!),
    );
  },
)
```

#### **6. Update Dialog Text References**

**File:** `lib/shared/widgets/dialogs/vehicle_requirement_dialogs.dart`

**Changes:**
- Replace "marshal" with "verifier" or "authorized user"
- Update verification time references (use backend config if available)

```dart
// BEFORE
'Your vehicle modifications are awaiting marshal verification.'

// AFTER
'Your vehicle modifications are awaiting verification.'

// BEFORE
'Expedited Verification: A marshal will contact you within 48 hours'

// AFTER
'Expedited Verification: You will receive a response within 48 hours'
```

---

## State Management

### Riverpod Providers Summary

```dart
// Choices providers
final modificationChoicesProvider = StateNotifierProvider<...>
final liftKitChoicesProvider = Provider<List<ModificationChoice>>
final shocksTypeChoicesProvider = Provider<List<ModificationChoice>>
// ... other choice providers

// API repository provider
final vehicleModificationsApiRepositoryProvider = Provider<VehicleModificationsApiRepository>

// User's modifications provider
final userModificationsProvider = FutureProvider.family<List<VehicleModifications>, int>((ref, memberId) async {
  final repository = ref.watch(vehicleModificationsApiRepositoryProvider);
  return repository.getModificationsByMemberId(memberId);
});

// Trip requirements provider
final tripRequirementsProvider = FutureProvider.family<TripVehicleRequirements?, int>((ref, tripId) async {
  final repository = ref.watch(vehicleModificationsApiRepositoryProvider);
  return repository.getRequirementsByTripId(tripId);
});

// Verification queue provider (for verifiers)
final verificationQueueProvider = FutureProvider<List<VehicleModifications>>((ref) async {
  final repository = ref.watch(vehicleModificationsApiRepositoryProvider);
  return repository.getVerificationQueue();
});
```

---

## Migration Strategy

### Step 1: Add API Service (No Breaking Changes)

1. Create `ModificationChoice` model
2. Create `VehicleModificationsApiRepository`
3. Add Riverpod providers for choices
4. Test API connectivity in isolation

**Timeline:** 1-2 hours  
**Risk:** Low (additive only)

### Step 2: Update Models (Backward Compatible)

1. Change enum fields to String in `VehicleModifications`
2. Add backward compatibility in `fromJson()` (support both field names)
3. Keep old enum types available as fallback
4. Update `toJson()` to use new field names

**Timeline:** 1-2 hours  
**Risk:** Low (backward compatible)

### Step 3: Update UI Components

1. Replace enum dropdowns with dynamic choice dropdowns
2. Update dialog text (marshal → verifier)
3. Add loading states for choices
4. Add error handling for missing choices

**Timeline:** 2-3 hours  
**Risk:** Medium (UI changes visible to users)

### Step 4: Switch from Cache to API

1. Update dependency injection to use API service instead of cache
2. Add migration logic to transfer cached data to API (if needed)
3. Remove cache service dependency
4. Test complete flows

**Timeline:** 1-2 hours  
**Risk:** Medium (data migration needed)

### Step 5: Testing & Rollout

1. Unit tests for new models
2. Widget tests for updated UI
3. Integration tests for API flows
4. Beta testing with small user group
5. Gradual rollout

**Timeline:** 4-6 hours  
**Risk:** Low (thorough testing)

**Total Estimated Time:** 12-16 hours

---

## Testing Requirements

### Unit Tests

**File:** `test/models/modification_choice_test.dart`
```dart
void main() {
  group('ModificationChoice', () {
    test('compareTo works correctly', () {
      final stock = ModificationChoice(value: 'stock', displayName: 'Stock', level: 0);
      final inch2 = ModificationChoice(value: '2_inch', displayName: '2 Inch', level: 2);
      
      expect(stock.compareTo(inch2), lessThan(0));
      expect(inch2.compareTo(stock), greaterThan(0));
    });
    
    test('fromJson parses correctly', () {
      final json = {'value': 'stock', 'displayName': 'Stock Height', 'level': 0};
      final choice = ModificationChoice.fromJson(json);
      
      expect(choice.value, 'stock');
      expect(choice.displayName, 'Stock Height');
      expect(choice.level, 0);
    });
  });
}
```

### Widget Tests

**File:** `test/widgets/vehicle_modification_dropdown_test.dart`
```dart
void main() {
  testWidgets('Dropdown shows dynamic choices', (tester) async {
    // Mock provider with test data
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liftKitChoicesProvider.overrideWith((ref) => [
            ModificationChoice(value: 'stock', displayName: 'Stock', level: 0),
            ModificationChoice(value: '2_inch', displayName: '2 Inch', level: 2),
          ]),
        ],
        child: MaterialApp(home: VehicleModificationScreen()),
      ),
    );
    
    // Find dropdown
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('2 Inch'), findsOneWidget);
  });
}
```

### Integration Tests

**File:** `integration_test/vehicle_modifications_flow_test.dart`
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete modification submission flow', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // 1. Navigate to vehicle modifications
    // 2. Select modifications from dropdowns
    // 3. Submit for verification
    // 4. Verify success message
    // 5. Check modifications appear in list
  });
}
```

---

## Error Handling

### Common Scenarios

**1. Choices API Failure**
```dart
Consumer(
  builder: (context, ref, child) {
    final choicesAsync = ref.watch(modificationChoicesProvider);
    
    return choicesAsync.when(
      data: (choices) => BuildDropdowns(choices),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Column(
        children: [
          Text('Failed to load modification options'),
          ElevatedButton(
            onPressed: () => ref.refresh(modificationChoicesProvider),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  },
)
```

**2. Invalid Choice Value**
```dart
try {
  await repository.saveModifications(mods);
} on DioException catch (e) {
  if (e.response?.data['code'] == 'INVALID_CHOICE_VALUE') {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invalid Option'),
        content: Text('The selected option is no longer available. Please refresh and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              ref.refresh(modificationChoicesProvider);
              Navigator.pop(context);
            },
            child: Text('Refresh Options'),
          ),
        ],
      ),
    );
  }
}
```

**3. Permission Denied**
```dart
try {
  await repository.approveModifications(modificationId: id);
} on DioException catch (e) {
  if (e.response?.statusCode == 403) {
    showSnackBar('You do not have permission to verify modifications');
  }
}
```

---

## Performance Optimization

### 1. Cache Choices Locally

After loading choices from API, cache them in SharedPreferences:

```dart
Future<void> loadAllChoices() async {
  // Try loading from cache first
  final cachedChoices = await _loadFromCache();
  if (cachedChoices != null) {
    state = AsyncValue.data(cachedChoices);
  }
  
  // Load from API and update cache
  try {
    final freshChoices = await _loadFromApi();
    state = AsyncValue.data(freshChoices);
    await _saveToCache(freshChoices);
  } catch (e) {
    if (cachedChoices == null) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

### 2. Lazy Load Choices

Only load choices when user opens modification screen:

```dart
class VehicleModificationScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    // Load choices on screen open (not app start)
    Future.microtask(() => ref.read(modificationChoicesProvider.notifier).loadAllChoices());
  }
}
```

### 3. Debounce API Calls

When validating eligibility, debounce rapid changes:

```dart
Timer? _debounce;

void checkEligibility(int vehicleId) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 500), () async {
    final result = await repository.checkEligibility(tripId: tripId, vehicleId: vehicleId);
    // Handle result
  });
}
```

---

## Rollout Plan

### Phase 1: Development (Week 1)
- ✅ Create all new models and providers
- ✅ Implement API repository
- ✅ Unit tests for models
- ✅ Test API connectivity

### Phase 2: UI Updates (Week 2)
- ✅ Update all dropdowns to use dynamic choices
- ✅ Update dialog text
- ✅ Widget tests
- ✅ Internal testing

### Phase 3: Integration (Week 3)
- ✅ Switch from cache to API service
- ✅ Data migration logic (if needed)
- ✅ Integration tests
- ✅ Staging environment testing

### Phase 4: Beta Release (Week 4)
- ✅ Beta testing with 10-20 users
- ✅ Monitor errors and API performance
- ✅ Fix critical bugs

### Phase 5: Production Rollout (Week 5)
- ✅ Gradual rollout to 10% → 50% → 100%
- ✅ Monitor crash reports
- ✅ Performance metrics
- ✅ User feedback collection

---

## Backward Compatibility Notes

### Supporting Old App Versions

If older app versions are still in use:

1. **Backend must support both field names:**
   - `verifiedByMarshalId` AND `verifiedByUserId`
   - `marshalNotes` AND `verifierNotes`

2. **API responses should include both:**
```json
{
  "verifiedByUserId": 789,
  "verifiedByMarshalId": 789,  // Deprecated but included for old apps
  "verifierNotes": "Verified",
  "marshalNotes": "Verified"   // Deprecated but included for old apps
}
```

3. **Flutter app should accept both:**
```dart
verifiedByUserId: json['verified_by_user_id'] ?? json['verified_by_marshal_id'],
```

---

**End of Implementation Guide**

**Next Steps:**
1. Review this guide with Flutter team
2. Create GitHub issues for each phase
3. Assign tasks to developers
4. Begin Phase 1 implementation

**Estimated Total Time:** 12-16 hours for complete implementation
