# Vehicle Modifications System - Backend API Documentation

**Version:** 2.0  
**Feature Request Date:** November 11, 2025  
**Last Updated:** November 16, 2024  
**Author:** AD4x4 Development Team

---

## Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [API Endpoints](#api-endpoints)
4. [Choices API (Dynamic Options)](#choices-api-dynamic-options)
5. [Authentication & Permissions](#authentication--permissions)
6. [Error Responses](#error-responses)
7. [Migration from Cache](#migration-from-cache)
8. [Testing Checklist](#testing-checklist)

---

## Overview

The Vehicle Modifications System allows members to declare vehicle modifications and have them verified by authorized users. Authorized users can set minimum modification requirements for trips based on configurable level thresholds, and the system validates member eligibility during registration.

### Key Features
- Members can declare modifications for configurable number of vehicles (default: 3)
- Two verification methods: On-Trip (free) or Expedited (configurable duration)
- Permission-based verification workflow (not role-specific)
- Trip requirements configurable based on trip level settings
- Registration validation blocks unqualified members
- Backward compatible - works for members without modifications
- **NEW**: Dynamic modification choices via API (no hardcoded options)
- **NEW**: Flexible level-based requirements system

### System Philosophy

**Flexibility First**: This system is designed for maximum backend configurability:
- ✅ All modification options loaded from backend API
- ✅ Trip level requirements configurable via global settings
- ✅ Permission-based access (not hardcoded roles)
- ✅ Future-ready for localization and regional variations

---

## Database Schema

### Table: `vehicle_modifications`

Stores member vehicle modification declarations.

```sql
CREATE TABLE vehicle_modifications (
    id VARCHAR(36) PRIMARY KEY,
    member_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    
    -- Suspension & Tires (values from modification_choices table)
    lift_kit VARCHAR(50) DEFAULT 'stock',
    shocks_type VARCHAR(50) DEFAULT 'normal',
    arms_type VARCHAR(50) DEFAULT 'stock',
    tyre_size VARCHAR(10) DEFAULT '32',
    
    -- Engine (values from modification_choices table)
    air_intake VARCHAR(50) DEFAULT 'stock',
    catback VARCHAR(50) DEFAULT 'stock',
    horsepower VARCHAR(50) DEFAULT 'stock',
    
    -- Equipment (values from modification_choices table)
    off_road_light VARCHAR(50) DEFAULT 'none',
    winch VARCHAR(50) DEFAULT 'none',
    armor VARCHAR(50) DEFAULT 'none',
    
    -- Verification
    verification_status VARCHAR(20) DEFAULT 'pending',
    verification_type VARCHAR(20) DEFAULT 'on_trip',
    verified_by_user_id INTEGER NULL,  -- Changed from verified_by_marshal_id
    verified_at TIMESTAMP NULL,
    rejection_reason TEXT NULL,
    verifier_notes TEXT NULL,  -- Changed from marshal_notes
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_user_id) REFERENCES members(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_vehicle_mod (vehicle_id),
    INDEX idx_member_id (member_id),
    INDEX idx_verification_status (verification_status),
    INDEX idx_verified_by (verified_by_user_id)
);
```

**Field Value Sources:**
- All modification values (lift_kit, shocks_type, etc.) are loaded from `modification_choices` table
- Values must match `modification_choices.value` field
- Frontend loads choices dynamically via `/api/choices/` endpoints

**Verification Status Values:**
- `pending` - Awaiting verification
- `approved` - Verified and approved
- `rejected` - Rejected by verifier

**Verification Type Values:**
- `on_trip` - Free verification during next trip
- `expedited` - Fast-track verification (configurable duration)

---

### Table: `modification_choices`

Stores dynamic modification options for all categories.

```sql
CREATE TABLE modification_choices (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    choice_type VARCHAR(50) NOT NULL,  -- Category: 'liftkit', 'shockstype', etc.
    value VARCHAR(50) NOT NULL,        -- Internal value: 'stock', '1_inch', etc.
    display_name VARCHAR(100) NOT NULL,  -- Display text: "Stock Height", "1 Inch"
    display_name_ar VARCHAR(100),      -- Future: Arabic localization
    level INTEGER NOT NULL DEFAULT 0,  -- Comparison level (0-10, higher = more extreme)
    description TEXT,                  -- Optional: Help text for users
    active BOOLEAN DEFAULT TRUE,       -- Can be deactivated without deletion
    sort_order INTEGER DEFAULT 0,      -- Display order in dropdowns
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_choice (choice_type, value),
    INDEX idx_choice_type (choice_type),
    INDEX idx_active (active),
    INDEX idx_sort_order (sort_order)
);
```

**Choice Types:**
- `liftkit` - Lift kit modifications
- `shockstype` - Shock absorber types
- `arms` - Suspension arm types
- `tyresizemods` - Tyre size modifications
- `airintake` - Air intake types
- `catback` - Exhaust catback types
- `horsepower` - Horsepower ranges
- `offroadlight` - Off-road lighting types
- `winch` - Winch types
- `armor` - Armor/protection types

**Initial Data Seeding:**
See section [Initial Modification Choices Data](#initial-modification-choices-data) below.

---

### Table: `trip_vehicle_requirements`

Stores minimum vehicle requirements for trips.

```sql
CREATE TABLE trip_vehicle_requirements (
    id VARCHAR(36) PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    
    -- Suspension & Tires (nullable = not required)
    min_lift_kit VARCHAR(50) NULL,
    min_shocks_type VARCHAR(50) NULL,
    require_long_travel_arms BOOLEAN DEFAULT FALSE,
    min_tyre_size VARCHAR(10) NULL,
    
    -- Engine (nullable = not required)
    min_horsepower VARCHAR(50) NULL,
    require_performance_intake BOOLEAN DEFAULT FALSE,
    require_performance_catback BOOLEAN DEFAULT FALSE,
    
    -- Equipment (nullable = not required)
    require_off_road_light BOOLEAN DEFAULT FALSE,
    require_winch BOOLEAN DEFAULT FALSE,
    require_armor BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    UNIQUE KEY unique_trip_requirements (trip_id)
);
```

**Business Rule:**
- Requirements can only be set for trips with level >= `global_settings.min_level_for_requirements`
- This threshold is configurable (default: Advanced level)
- Validation enforced at API level

---

### Global Settings Updates

Add to existing `global_settings` table:

```sql
ALTER TABLE global_settings ADD COLUMN min_level_for_requirements INTEGER NULL;
ALTER TABLE global_settings ADD COLUMN vehicle_modification_limit INTEGER DEFAULT 3;
ALTER TABLE global_settings ADD COLUMN enable_modification_system BOOLEAN DEFAULT TRUE;

-- Foreign key to levels table
ALTER TABLE global_settings ADD FOREIGN KEY (min_level_for_requirements) 
    REFERENCES levels(id) ON DELETE SET NULL;
```

**New Settings:**
- `min_level_for_requirements` - Minimum trip level that can have vehicle requirements (FK to levels)
- `vehicle_modification_limit` - Default number of vehicles per member (default: 3)
- `enable_modification_system` - Master switch to enable/disable entire system

---

## API Endpoints

### 1. Member Endpoints

#### POST `/api/members/{memberId}/vehicles/{vehicleId}/modifications`

**Description:** Create or update vehicle modifications for a member's vehicle.

**Authentication:** Required (member must be authenticated)

**Permissions:** Member can only modify their own vehicles

**Request Body:**
```json
{
  "liftKit": "2_inch",
  "shocksType": "heavy_duty",
  "armsType": "upgraded",
  "tyreSize": "33",
  "airIntake": "cold_air",
  "catback": "sport",
  "horsepower": "stage1",
  "offRoadLight": "led_bar",
  "winch": "10000lb",
  "armor": "skid_plates",
  "verificationType": "expedited"
}
```

**Validation:**
- All values must exist in `modification_choices` table with `active=true`
- Example: `liftKit: "2_inch"` must match `modification_choices` where `choice_type='liftkit'` and `value='2_inch'`

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "memberId": 123,
    "vehicleId": 456,
    "liftKit": "2_inch",
    "shocksType": "heavy_duty",
    "armsType": "upgraded",
    "tyreSize": "33",
    "airIntake": "cold_air",
    "catback": "sport",
    "horsepower": "stage1",
    "offRoadLight": "led_bar",
    "winch": "10000lb",
    "armor": "skid_plates",
    "verificationStatus": "pending",
    "verificationType": "expedited",
    "verifiedByUserId": null,
    "verifiedAt": null,
    "rejectionReason": null,
    "verifierNotes": null,
    "createdAt": "2025-11-11T10:30:00Z",
    "updatedAt": "2025-11-11T10:30:00Z"
  }
}
```

---

#### GET `/api/members/{memberId}/vehicles/{vehicleId}/modifications`

**Description:** Get vehicle modifications for a specific vehicle.

**Authentication:** Required

**Permissions:** Member can view their own vehicles, users with `verify_vehicle_modifications` permission can view any

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "memberId": 123,
    "vehicleId": 456,
    "liftKit": "2_inch",
    "shocksType": "heavy_duty",
    "verificationStatus": "approved",
    "verifiedByUserId": 789,
    "verifiedByUsername": "john_verifier",
    "verifiedAt": "2025-11-13T14:20:00Z",
    "verifierNotes": "All modifications verified and meet specifications"
  }
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "error": "No modifications found for this vehicle"
}
```

---

#### GET `/api/members/{memberId}/modifications`

**Description:** Get all vehicle modifications for a member (all their vehicles).

**Authentication:** Required

**Permissions:** Member can view their own, users with `verify_vehicle_modifications` permission can view any

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "memberId": 123,
      "vehicleId": 456,
      "vehicleName": "Toyota Land Cruiser 2023",
      "verificationStatus": "approved",
      "verifiedAt": "2025-11-13T14:20:00Z"
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "memberId": 123,
      "vehicleId": 789,
      "vehicleName": "Nissan Patrol 2024",
      "verificationStatus": "pending",
      "verificationType": "expedited"
    }
  ]
}
```

---

### 2. Verification Endpoints (Permission-Based)

#### GET `/api/admin/modifications/pending`

**Description:** Get all pending vehicle modifications awaiting verification.

**Authentication:** Required

**Permissions:** `verify_vehicle_modifications` OR `admin_access`

**Query Parameters:**
- `verificationType` (optional): Filter by verification type (`on_trip`, `expedited`)
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "memberId": 123,
      "memberName": "John Doe",
      "memberUsername": "johndoe",
      "vehicleId": 456,
      "vehicleName": "Toyota Land Cruiser 2023",
      "liftKit": "2_inch",
      "liftKitDisplay": "2 Inch",
      "shocksType": "heavy_duty",
      "shocksTypeDisplay": "Heavy Duty",
      "tyreSize": "33",
      "tyreSizeDisplay": "33\"",
      "verificationStatus": "pending",
      "verificationType": "expedited",
      "createdAt": "2025-11-11T10:30:00Z",
      "submittedDaysAgo": 2
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

---

#### PATCH `/api/admin/modifications/{modificationId}/verify`

**Description:** Approve or reject vehicle modifications.

**Authentication:** Required

**Permissions:** `verify_vehicle_modifications` OR `admin_access`

**Request Body (Approve):**
```json
{
  "action": "approve",
  "verifierNotes": "All modifications verified. Excellent condition."
}
```

**Request Body (Reject):**
```json
{
  "action": "reject",
  "rejectionReason": "Lift kit height does not match declared specifications",
  "verifierNotes": "Member needs to update declaration to match actual setup"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "verificationStatus": "approved",
    "verifiedByUserId": 789,
    "verifiedByUsername": "john_verifier",
    "verifiedAt": "2025-11-14T11:00:00Z",
    "verifierNotes": "All modifications verified. Excellent condition."
  }
}
```

**Response (403 Forbidden):**
```json
{
  "success": false,
  "error": "You do not have permission to verify vehicle modifications",
  "code": "FORBIDDEN",
  "requiredPermission": "verify_vehicle_modifications"
}
```

---

### 3. Trip Requirements Endpoints

#### POST `/api/trips/{tripId}/requirements`

**Description:** Create or update vehicle requirements for a trip.

**Authentication:** Required

**Permissions:** `create_trips` OR `edit_trips` OR `admin_access`

**Validation:**
- Trip level must be >= `global_settings.min_level_for_requirements`
- Returns 400 error if trip level is too low

**Request Body:**
```json
{
  "minLiftKit": "2_inch",
  "minShocksType": "heavy_duty",
  "requireLongTravelArms": true,
  "minTyreSize": "33",
  "minHorsepower": "stage1",
  "requirePerformanceIntake": false,
  "requirePerformanceCatback": false,
  "requireOffRoadLight": true,
  "requireWinch": true,
  "requireArmor": false
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "tripId": 999,
    "tripLevel": "Advanced",
    "minLiftKit": "2_inch",
    "minShocksType": "heavy_duty",
    "requireLongTravelArms": true,
    "minTyreSize": "33",
    "minHorsepower": "stage1",
    "requirePerformanceIntake": false,
    "requirePerformanceCatback": false,
    "requireOffRoadLight": true,
    "requireWinch": true,
    "requireArmor": false,
    "createdAt": "2025-11-14T12:00:00Z"
  }
}
```

**Response (400 Bad Request - Level Too Low):**
```json
{
  "success": false,
  "error": "Vehicle requirements can only be set for trips of level 'Advanced' or higher",
  "code": "INVALID_TRIP_LEVEL",
  "details": {
    "tripLevel": "Intermediate",
    "minRequiredLevel": "Advanced",
    "tripLevelId": 2,
    "minRequiredLevelId": 3
  }
}
```

---

#### GET `/api/trips/{tripId}/requirements`

**Description:** Get vehicle requirements for a specific trip.

**Authentication:** Required

**Permissions:** Public (any authenticated user)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "tripId": 999,
    "minLiftKit": "2_inch",
    "minLiftKitDisplay": "2 Inch",
    "minShocksType": "heavy_duty",
    "minShocksTypeDisplay": "Heavy Duty",
    "requireLongTravelArms": true,
    "minTyreSize": "33",
    "minTyreSizeDisplay": "33\"",
    "minHorsepower": "stage1",
    "minHorsepowerDisplay": "Stage 1 (200-300 HP)",
    "requirePerformanceIntake": false,
    "requirePerformanceCatback": false,
    "requireOffRoadLight": true,
    "requireWinch": true,
    "requireArmor": false,
    "createdAt": "2025-11-14T12:00:00Z"
  }
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "error": "No vehicle requirements set for this trip"
}
```

---

#### DELETE `/api/trips/{tripId}/requirements`

**Description:** Remove vehicle requirements from a trip.

**Authentication:** Required

**Permissions:** `edit_trips` OR `admin_access`

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Vehicle requirements removed from trip"
}
```

---

### 4. Validation Endpoints

#### GET `/api/trips/{tripId}/check-eligibility`

**Description:** Check if member's vehicle meets trip requirements.

**Authentication:** Required

**Permissions:** Any authenticated member

**Query Parameters:**
- `vehicleId` (required): The vehicle ID to check

**Response (200 OK - Eligible):**
```json
{
  "success": true,
  "data": {
    "eligible": true,
    "tripId": 999,
    "vehicleId": 456,
    "hasRequirements": true,
    "modificationsVerified": true,
    "meetsRequirements": true,
    "unmetRequirements": []
  }
}
```

**Response (200 OK - Not Eligible):**
```json
{
  "success": true,
  "data": {
    "eligible": false,
    "tripId": 999,
    "vehicleId": 456,
    "hasRequirements": true,
    "modificationsVerified": true,
    "meetsRequirements": false,
    "unmetRequirements": [
      "Lift Kit: Minimum 2\" (You have: 1\" ✅ Verified)",
      "Winch: Required (You have: None ✅ Verified)"
    ]
  }
}
```

**Response (200 OK - Pending Verification):**
```json
{
  "success": true,
  "data": {
    "eligible": false,
    "tripId": 999,
    "vehicleId": 456,
    "hasRequirements": true,
    "modificationsVerified": false,
    "verificationType": "expedited",
    "meetsRequirements": false,
    "unmetRequirements": [
      "Modifications pending verification (Expedited - expect response within 48 hours)"
    ]
  }
}
```

---

#### POST `/api/trips/{tripId}/validate-registration`

**Description:** Validate vehicle eligibility before allowing registration.

**Authentication:** Required

**Permissions:** Any authenticated member

**Request Body:**
```json
{
  "memberId": 123,
  "vehicleId": 456
}
```

**Response (200 OK - Can Register):**
```json
{
  "success": true,
  "canRegister": true,
  "message": "Vehicle meets all requirements"
}
```

**Response (403 Forbidden - Cannot Register):**
```json
{
  "success": false,
  "canRegister": false,
  "reason": "requirements_not_met",
  "unmetRequirements": [
    "Lift Kit: Minimum 2\" (You have: 1\" ✅ Verified)",
    "Winch: Required (You have: None ✅ Verified)"
  ]
}
```

---

## Choices API (Dynamic Options)

### Overview

All modification options are dynamically loaded from the backend via `/api/choices/` endpoints. This allows administrators to add, edit, or remove options without requiring app updates.

### Endpoints

#### GET `/api/choices/liftkit`

**Description:** Get all lift kit modification options.

**Authentication:** Optional (public choices)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "value": "stock",
      "displayName": "Stock Height",
      "level": 0,
      "description": "Factory original suspension height",
      "active": true
    },
    {
      "value": "1_inch",
      "displayName": "1 Inch",
      "level": 1,
      "description": "1 inch lift modification",
      "active": true
    },
    {
      "value": "2_inch",
      "displayName": "2 Inch",
      "level": 2,
      "active": true
    },
    {
      "value": "2.5_inch",
      "displayName": "2.5 Inch",
      "level": 3,
      "active": true
    },
    {
      "value": "3_inch",
      "displayName": "3 Inch",
      "level": 4,
      "active": true
    },
    {
      "value": "3.5_inch",
      "displayName": "3.5 Inch",
      "level": 5,
      "active": true
    },
    {
      "value": "4_inch_plus",
      "displayName": "4 Inch+",
      "level": 6,
      "description": "4 inches or more lift",
      "active": true
    }
  ]
}
```

#### GET `/api/choices/shockstype`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "normal", "displayName": "Normal", "level": 0, "active": true},
    {"value": "bypass", "displayName": "Bypass", "level": 1, "active": true},
    {"value": "triple_bypass", "displayName": "Triple Bypass", "level": 2, "active": true}
  ]
}
```

#### GET `/api/choices/arms`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "normal", "displayName": "Normal", "level": 0, "active": true},
    {"value": "long_travel", "displayName": "Long Travel", "level": 1, "active": true}
  ]
}
```

#### GET `/api/choices/tyresizemods`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "32", "displayName": "32\"", "level": 32, "active": true},
    {"value": "33", "displayName": "33\"", "level": 33, "active": true},
    {"value": "34", "displayName": "34\"", "level": 34, "active": true},
    {"value": "35", "displayName": "35\"", "level": 35, "active": true},
    {"value": "37_plus", "displayName": "37\"+", "level": 37, "active": true}
  ]
}
```

#### GET `/api/choices/airintake`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "normal", "displayName": "Normal", "level": 0, "active": true},
    {"value": "performance", "displayName": "Performance", "level": 1, "active": true}
  ]
}
```

#### GET `/api/choices/catback`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "normal", "displayName": "Normal", "level": 0, "active": true},
    {"value": "performance", "displayName": "Performance", "level": 1, "active": true}
  ]
}
```

#### GET `/api/choices/horsepower`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "hp100_200", "displayName": "100HP - 200HP", "level": 0, "active": true},
    {"value": "hp200_300", "displayName": "200HP - 300HP", "level": 1, "active": true},
    {"value": "hp300_400", "displayName": "300HP - 400HP", "level": 2, "active": true},
    {"value": "hp500_plus", "displayName": "500+ HP", "level": 3, "active": true}
  ]
}
```

#### GET `/api/choices/offroadlight`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "no", "displayName": "No", "level": 0, "active": true},
    {"value": "yes", "displayName": "Yes", "level": 1, "active": true},
    {"value": "a_lot", "displayName": "A Lot!", "level": 2, "active": true}
  ]
}
```

#### GET `/api/choices/winch`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "no", "displayName": "No", "level": 0, "active": true},
    {"value": "yes", "displayName": "Yes", "level": 1, "active": true}
  ]
}
```

#### GET `/api/choices/armor`

**Response:**
```json
{
  "success": true,
  "data": [
    {"value": "no", "displayName": "No", "level": 0, "active": true},
    {"value": "steel_bumpers", "displayName": "Steel Bumpers", "level": 1, "active": true}
  ]
}
```

---

### Initial Modification Choices Data

**Database Seed Script** (Python/Django example):

```python
INITIAL_CHOICES = {
    'liftkit': [
        {'value': 'stock', 'display_name': 'Stock Height', 'level': 0, 'description': 'Factory original'},
        {'value': '1_inch', 'display_name': '1 Inch', 'level': 1},
        {'value': '2_inch', 'display_name': '2 Inch', 'level': 2},
        {'value': '2.5_inch', 'display_name': '2.5 Inch', 'level': 3},
        {'value': '3_inch', 'display_name': '3 Inch', 'level': 4},
        {'value': '3.5_inch', 'display_name': '3.5 Inch', 'level': 5},
        {'value': '4_inch_plus', 'display_name': '4 Inch+', 'level': 6},
    ],
    'shockstype': [
        {'value': 'normal', 'display_name': 'Normal', 'level': 0},
        {'value': 'bypass', 'display_name': 'Bypass', 'level': 1},
        {'value': 'triple_bypass', 'display_name': 'Triple Bypass', 'level': 2},
    ],
    'arms': [
        {'value': 'normal', 'display_name': 'Normal', 'level': 0},
        {'value': 'long_travel', 'display_name': 'Long Travel', 'level': 1},
    ],
    'tyresizemods': [
        {'value': '32', 'display_name': '32"', 'level': 32},
        {'value': '33', 'display_name': '33"', 'level': 33},
        {'value': '34', 'display_name': '34"', 'level': 34},
        {'value': '35', 'display_name': '35"', 'level': 35},
        {'value': '37_plus', 'display_name': '37"+', 'level': 37},
    ],
    'airintake': [
        {'value': 'normal', 'display_name': 'Normal', 'level': 0},
        {'value': 'performance', 'display_name': 'Performance', 'level': 1},
    ],
    'catback': [
        {'value': 'normal', 'display_name': 'Normal', 'level': 0},
        {'value': 'performance', 'display_name': 'Performance', 'level': 1},
    ],
    'horsepower': [
        {'value': 'hp100_200', 'display_name': '100HP - 200HP', 'level': 0},
        {'value': 'hp200_300', 'display_name': '200HP - 300HP', 'level': 1},
        {'value': 'hp300_400', 'display_name': '300HP - 400HP', 'level': 2},
        {'value': 'hp500_plus', 'display_name': '500+ HP', 'level': 3},
    ],
    'offroadlight': [
        {'value': 'no', 'display_name': 'No', 'level': 0},
        {'value': 'yes', 'display_name': 'Yes', 'level': 1},
        {'value': 'a_lot', 'display_name': 'A Lot!', 'level': 2},
    ],
    'winch': [
        {'value': 'no', 'display_name': 'No', 'level': 0},
        {'value': 'yes', 'display_name': 'Yes', 'level': 1},
    ],
    'armor': [
        {'value': 'no', 'display_name': 'No', 'level': 0},
        {'value': 'steel_bumpers', 'display_name': 'Steel Bumpers', 'level': 1},
    ],
}

# Seed database
for choice_type, options in INITIAL_CHOICES.items():
    for idx, option in enumerate(options):
        ModificationChoice.objects.create(
            choice_type=choice_type,
            value=option['value'],
            display_name=option['display_name'],
            level=option['level'],
            description=option.get('description', ''),
            sort_order=idx,
            active=True
        )
```

---

## Authentication & Permissions

### Required Permissions

**Member Actions:**
- View own modifications: No special permission (authenticated member)
- Create/update own modifications: No special permission (authenticated member)
- View trip requirements: No special permission (authenticated member)
- Check eligibility: No special permission (authenticated member)

**Verification Actions:**
- View pending modifications: `verify_vehicle_modifications` OR `admin_access`
- Approve/reject modifications: `verify_vehicle_modifications` OR `admin_access`

**Trip Requirements Management:**
- Create trip requirements: `create_trips` OR `edit_trips` OR `admin_access`
- Delete trip requirements: `edit_trips` OR `admin_access`

### Permission Assignment Recommendations

**Board Members:**
- `verify_vehicle_modifications` - Can verify modifications
- `create_trips` - Can set requirements for trips
- `edit_trips` - Can modify/delete requirements
- `admin_access` - Full system access

**Trip Leaders/Marshals:**
- `verify_vehicle_modifications` - Can verify on-trip modifications
- Can set requirements only for trips they create (via `create_trips`)

**Admins:**
- `admin_access` - Full system access

### Authentication Header

All requests must include JWT token:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## Error Responses

### Standard Error Format

```json
{
  "success": false,
  "error": "Error message describing what went wrong",
  "code": "ERROR_CODE",
  "details": {}
}
```

### Common Error Codes

| HTTP Status | Code | Description |
|-------------|------|-------------|
| 400 | `INVALID_REQUEST` | Missing or invalid request parameters |
| 400 | `INVALID_CHOICE_VALUE` | Modification value not found in choices table |
| 400 | `INVALID_TRIP_LEVEL` | Trip level too low for requirements |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication token |
| 403 | `FORBIDDEN` | User lacks required permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource already exists or state conflict |
| 422 | `VALIDATION_ERROR` | Request validation failed |
| 500 | `INTERNAL_ERROR` | Server error |

### Example Error Responses

**Missing Authentication:**
```json
{
  "success": false,
  "error": "Authentication required",
  "code": "UNAUTHORIZED"
}
```

**Insufficient Permissions:**
```json
{
  "success": false,
  "error": "You do not have permission to verify vehicle modifications",
  "code": "FORBIDDEN",
  "requiredPermission": "verify_vehicle_modifications"
}
```

**Invalid Choice Value:**
```json
{
  "success": false,
  "error": "Invalid lift kit value",
  "code": "INVALID_CHOICE_VALUE",
  "details": {
    "field": "liftKit",
    "value": "invalid_option",
    "availableValues": ["stock", "1_inch", "2_inch", "2.5_inch", "3_inch", "3.5_inch", "4_inch_plus"]
  }
}
```

**Trip Level Too Low:**
```json
{
  "success": false,
  "error": "Vehicle requirements can only be set for trips of level 'Advanced' or higher",
  "code": "INVALID_TRIP_LEVEL",
  "details": {
    "tripLevel": "Intermediate",
    "minRequiredLevel": "Advanced"
  }
}
```

---

## Migration from Cache

The Flutter app currently uses `VehicleModificationsCacheService` with `SharedPreferences` for local storage. To migrate to production API:

### Step 1: Create API Service

```dart
class VehicleModificationsApiService {
  final ApiClient _apiClient;
  
  VehicleModificationsApiService(this._apiClient);
  
  // Fetch modification choices from backend
  Future<List<ModificationChoice>> getChoices(String choiceType) async {
    final response = await _apiClient.get('/api/choices/$choiceType');
    return (response.data['data'] as List)
        .map((json) => ModificationChoice.fromJson(json))
        .toList();
  }
  
  // Same method signatures as cache service
  Future<VehicleModifications> saveModifications(VehicleModifications mods) async {
    final response = await _apiClient.post(
      '/api/members/${mods.memberId}/vehicles/${mods.vehicleId}/modifications',
      data: mods.toJson(),
    );
    return VehicleModifications.fromJson(response.data['data']);
  }
  
  // ... implement all other methods matching cache service interface
}
```

### Step 2: Update Flutter Models

Replace hardcoded enums with dynamic choices:

```dart
// BEFORE (Hardcoded)
enum LiftKitType {
  stock, inch1, inch2, ...
}

// AFTER (Dynamic)
class ModificationChoice {
  final String value;
  final String displayName;
  final int level;
  final String? description;
  
  ModificationChoice({
    required this.value,
    required this.displayName,
    required this.level,
    this.description,
  });
  
  factory ModificationChoice.fromJson(Map<String, dynamic> json) {
    return ModificationChoice(
      value: json['value'] as String,
      displayName: json['displayName'] as String,
      level: json['level'] as int,
      description: json['description'] as String?,
    );
  }
  
  // Comparison method
  int compareTo(ModificationChoice other) => level.compareTo(other.level);
}
```

### Step 3: Load Choices on App Start

```dart
class ModificationChoicesProvider extends ChangeNotifier {
  Map<String, List<ModificationChoice>> _choices = {};
  bool _loaded = false;
  
  Future<void> loadAllChoices() async {
    final choiceTypes = [
      'liftkit', 'shockstype', 'arms', 'tyresizemods',
      'airintake', 'catback', 'horsepower', 'offroadlight',
      'winch', 'armor'
    ];
    
    for (final type in choiceTypes) {
      _choices[type] = await apiService.getChoices(type);
    }
    
    _loaded = true;
    notifyListeners();
  }
  
  List<ModificationChoice> getChoices(String type) => _choices[type] ?? [];
}
```

### Step 4: Update Dependency Injection

```dart
// Before (development)
final vehicleModsService = VehicleModificationsCacheService(prefs);

// After (production)
final vehicleModsService = VehicleModificationsApiService(apiClient);
```

### Step 5: No Major UI Changes Required

UI dropdowns can use dynamic choices instead of hardcoded enums:

```dart
// BEFORE
DropdownButton<LiftKitType>(
  items: LiftKitType.values.map((type) => 
    DropdownMenuItem(value: type, child: Text(type.displayName))
  ).toList(),
)

// AFTER
DropdownButton<ModificationChoice>(
  items: provider.getChoices('liftkit').map((choice) => 
    DropdownMenuItem(value: choice, child: Text(choice.displayName))
  ).toList(),
)
```

---

## Testing Checklist

### Unit Tests

- [ ] Choice comparison operators work correctly with dynamic levels
- [ ] `meetsRequirements()` validation logic handles all cases
- [ ] JSON serialization/deserialization works for all models
- [ ] Edge cases (null values, empty lists, inactive choices) handled

### Integration Tests

- [ ] Member can create modifications
- [ ] Member can update existing modifications
- [ ] Invalid choice values are rejected with proper error
- [ ] Choices API returns correct data
- [ ] User with permission can view pending queue
- [ ] User with permission can approve modifications
- [ ] User with permission can reject modifications with reason
- [ ] Trip requirements can be created for valid trip levels
- [ ] Trip requirements creation fails for invalid trip levels
- [ ] Trip requirements can be updated
- [ ] Trip requirements can be deleted
- [ ] Eligibility checking works for all scenarios
- [ ] Registration validation blocks unqualified members
- [ ] Global settings control trip level requirements

### API Tests

- [ ] All endpoints return correct status codes
- [ ] Authentication required for protected endpoints
- [ ] Permission checks work correctly
- [ ] Choice values validated against modification_choices table
- [ ] Trip level validation enforced at API level
- [ ] Error responses match specification
- [ ] Pagination works correctly
- [ ] Query parameters filter correctly

### End-to-End Tests

- [ ] Complete member flow: declare → wait → verify → register
- [ ] Complete verifier flow: view queue → verify → approve/reject
- [ ] Complete trip creation flow with requirements
- [ ] Registration validation with various scenarios
- [ ] Warning dialogs show correct messages
- [ ] Navigation flows work correctly
- [ ] Dynamic choices load and display correctly
- [ ] Level-based requirements work across all levels

---

## Appendix: Database Migration Scripts

### Migration 1: Create Base Tables

```sql
-- Create modification_choices table
CREATE TABLE modification_choices (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    choice_type VARCHAR(50) NOT NULL,
    value VARCHAR(50) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    display_name_ar VARCHAR(100),
    level INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_choice (choice_type, value),
    INDEX idx_choice_type (choice_type),
    INDEX idx_active (active),
    INDEX idx_sort_order (sort_order)
);

-- Create vehicle_modifications table
CREATE TABLE vehicle_modifications (
    id VARCHAR(36) PRIMARY KEY,
    member_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    
    lift_kit VARCHAR(50) DEFAULT 'stock',
    shocks_type VARCHAR(50) DEFAULT 'normal',
    arms_type VARCHAR(50) DEFAULT 'stock',
    tyre_size VARCHAR(10) DEFAULT '32',
    air_intake VARCHAR(50) DEFAULT 'stock',
    catback VARCHAR(50) DEFAULT 'stock',
    horsepower VARCHAR(50) DEFAULT 'stock',
    off_road_light VARCHAR(50) DEFAULT 'none',
    winch VARCHAR(50) DEFAULT 'none',
    armor VARCHAR(50) DEFAULT 'none',
    
    verification_status VARCHAR(20) DEFAULT 'pending',
    verification_type VARCHAR(20) DEFAULT 'on_trip',
    verified_by_user_id INTEGER NULL,
    verified_at TIMESTAMP NULL,
    rejection_reason TEXT NULL,
    verifier_notes TEXT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_user_id) REFERENCES members(id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_vehicle_mod (vehicle_id),
    INDEX idx_member_id (member_id),
    INDEX idx_verification_status (verification_status),
    INDEX idx_verified_by (verified_by_user_id)
);

-- Create trip_vehicle_requirements table
CREATE TABLE trip_vehicle_requirements (
    id VARCHAR(36) PRIMARY KEY,
    trip_id INTEGER NOT NULL,
    
    min_lift_kit VARCHAR(50) NULL,
    min_shocks_type VARCHAR(50) NULL,
    require_long_travel_arms BOOLEAN DEFAULT FALSE,
    min_tyre_size VARCHAR(10) NULL,
    min_horsepower VARCHAR(50) NULL,
    require_performance_intake BOOLEAN DEFAULT FALSE,
    require_performance_catback BOOLEAN DEFAULT FALSE,
    require_off_road_light BOOLEAN DEFAULT FALSE,
    require_winch BOOLEAN DEFAULT FALSE,
    require_armor BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    UNIQUE KEY unique_trip_requirements (trip_id)
);
```

### Migration 2: Update Global Settings

```sql
-- Add new settings fields
ALTER TABLE global_settings 
ADD COLUMN min_level_for_requirements INTEGER NULL,
ADD COLUMN vehicle_modification_limit INTEGER DEFAULT 3,
ADD COLUMN enable_modification_system BOOLEAN DEFAULT TRUE;

-- Add foreign key
ALTER TABLE global_settings 
ADD FOREIGN KEY (min_level_for_requirements) 
    REFERENCES levels(id) ON DELETE SET NULL;

-- Set default value (assuming Advanced is level ID 3)
UPDATE global_settings SET min_level_for_requirements = 3 WHERE id = 1;
```

### Migration 3: Seed Initial Choices Data

```sql
-- Insert lift kit choices
INSERT INTO modification_choices (choice_type, value, display_name, level, sort_order) VALUES
('liftkit', 'stock', 'Stock Height', 0, 0),
('liftkit', '1_inch', '1 Inch', 1, 1),
('liftkit', '2_inch', '2 Inch', 2, 2),
('liftkit', '2.5_inch', '2.5 Inch', 3, 3),
('liftkit', '3_inch', '3 Inch', 4, 4),
('liftkit', '3.5_inch', '3.5 Inch', 5, 5),
('liftkit', '4_inch_plus', '4 Inch+', 6, 6);

-- Insert other choices (shockstype, arms, tyresizemods, etc.)
-- See Initial Modification Choices Data section for full list
```

---

**End of Document**

**Version History:**
- v1.0 (2024-01-14): Initial version with hardcoded options
- v2.0 (2024-11-16): Complete refactor for maximum flexibility
  - Added dynamic choices API
  - Removed role-based hardcoding
  - Added level-based requirements configuration
  - Updated field names (marshal → verifier)
  - Added comprehensive testing checklist
