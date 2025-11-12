# Marshal Panel System Documentation

## Overview

The **Marshal Panel** is a specialized administrative system designed for AD4X4 club marshals to manage member training records, verify skills, and document trip details. This system provides comprehensive tools for tracking member progression through the club's skill development program.

**Version:** 1.0.0  
**Date:** January 2025  
**Phase:** Phase 3A Complete

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Features Overview](#features-overview)
3. [Permission System](#permission-system)
4. [User Workflows](#user-workflows)
5. [API Documentation](#api-documentation)
6. [Testing Guide](#testing-guide)
7. [Troubleshooting](#troubleshooting)

---

## System Architecture

### Component Structure

```
lib/
├── data/
│   ├── models/
│   │   └── logbook_model.dart          # Data models for logbook system
│   └── repositories/
│       └── main_api_repository.dart    # API methods (7 new endpoints)
├── features/
│   └── admin/
│       └── presentation/
│           ├── providers/
│           │   └── logbook_provider.dart      # State management (4 providers)
│           └── screens/
│               ├── admin_logbook_entries_screen.dart        # View entries
│               ├── admin_create_logbook_entry_screen.dart   # Create entries
│               ├── admin_sign_off_skills_screen.dart        # Sign off skills
│               └── admin_trip_reports_screen.dart           # Create reports
└── core/
    └── router/
        └── app_router.dart             # Routes configuration
```

### State Management Architecture

**Provider Pattern with Riverpod:**

1. **LogbookEntriesProvider** - Manages list of logbook entries with pagination
2. **LogbookSkillsProvider** - Manages skills catalog grouped by level
3. **MemberSkillsStatusProvider** - Family provider for individual member progress
4. **LogbookActionsProvider** - Handles all create/update operations

### Data Models

**Core Models:**
- `LogbookEntry` - Records marshal verification of member skills
- `LogbookSkill` - Defines available skills by level
- `MemberSkillStatus` - Tracks individual member progress
- `TripReport` - Post-trip documentation by marshals

**Supporting Models:**
- `MemberBasicInfo` - Compact member information
- `TripBasicInfo` - Essential trip details
- `LevelBasicInfo` - Club level information
- `LogbookSkillBasicInfo` - Skill summary

---

## Features Overview

### 1. Logbook Entries Management

**Purpose:** View and manage all logbook entries recording skill verifications.

**Key Features:**
- Paginated list of all logbook entries
- Filter by member or trip
- View skills verified per entry
- See marshal signatures
- Pull-to-refresh for latest data
- Infinite scroll pagination

**User Interface:**
- Entry cards showing:
  - Member avatar, name, and level
  - Date of verification
  - Associated trip (if applicable)
  - Skills verified (chips)
  - Marshal signature
  - Optional comments
- Filter chips at top for active filters
- FAB for creating new entries

**Navigation:** Admin Panel → Marshal Panel → Logbook Entries

---

### 2. Create Logbook Entry

**Purpose:** Create new logbook entries to record skill verifications after trips.

**Key Features:**
- Select member from dropdown
- Select trip from recent trips
- Multi-select skills to verify (grouped by level)
- Optional comment field
- Form validation
- Success/error feedback

**Form Fields:**
1. **Member Selection** (Required)
   - Dropdown of active members
   - Shows display name
   
2. **Trip Selection** (Required)
   - Dropdown of recent trips (last 50)
   - Shows trip title and date
   
3. **Skills Selection** (Required, min 1)
   - Grouped by level in expansion tiles
   - Checkboxes for multi-select
   - Shows skill name and description
   
4. **Comment** (Optional)
   - Text area, max 500 characters
   - Additional notes about verification

**Validation Rules:**
- Must select a member
- Must select a trip
- Must select at least one skill
- Comment must not exceed 500 characters

**Navigation:** Admin Panel → Marshal Panel → Logbook Entries → FAB (Create Entry)

---

### 3. Sign Off Skills

**Purpose:** Dedicated interface for marshals to sign off individual skills with detailed tracking.

**Key Features:**
- Member selection with auto-load of skills
- Optional trip association
- View current skill status (verified/unverified)
- Batch sign-off support
- Individual comments per skill
- Real-time status updates

**User Interface:**
1. **Member Selection Section**
   - Dropdown to select member
   - Automatically loads member's skill status
   
2. **Trip Association** (Optional)
   - Dropdown to link verification to specific trip
   
3. **Skills List**
   - **Unverified Skills Section** (default expanded)
     - Checkboxes for batch selection
     - Individual comment fields
     - Skill name and description
   
   - **Verified Skills Section** (default collapsed)
     - Shows verification date
     - Shows verifying marshal
     - Associated trip (if any)
     - Historical comments

**Workflow:**
1. Select member → Skills auto-load
2. Optionally select trip
3. Check skills to sign off
4. Add individual comments (optional)
5. Click "Sign Off Selected Skills"
6. Confirmation and status update

**Navigation:** Admin Panel → Marshal Panel → Sign Off Skills

---

### 4. Trip Reports

**Purpose:** Create comprehensive post-trip reports documenting trip execution and outcomes.

**Key Features:**
- Select trip from recent trips
- Rich text report entry
- Optional supplementary fields
- Dynamic issues list management
- Form validation
- Success feedback with form reset

**Form Fields:**

1. **Trip Selection** (Required)
   - Dropdown of recent trips (last 50)
   
2. **Main Report** (Required)
   - Text area, 50-2000 characters
   - Comprehensive trip overview
   
3. **Safety Notes** (Optional)
   - Text area
   - Safety incidents or observations
   
4. **Weather Conditions** (Optional)
   - Text area
   - Weather during trip
   
5. **Terrain Notes** (Optional)
   - Text area
   - Trail conditions and difficulty
   
6. **Participant Count** (Optional)
   - Numeric input
   - Total participants including marshals
   
7. **Issues List** (Optional)
   - Dynamic list
   - Add/remove individual issues
   - Text fields for each issue

**Validation Rules:**
- Must select a trip
- Main report must be 50-2000 characters
- Participant count must be positive integer
- All fields validated before submission

**Navigation:** Admin Panel → Marshal Panel → Trip Reports

---

## Permission System

### Marshal Permissions

The Marshal Panel uses 5 specific permissions to control access:

| Permission ID | Permission Name | Bit Value | Access Control |
|--------------|-----------------|-----------|----------------|
| 63 | `create_trip_report` | 2^63 | Trip Reports screen |
| 64 | `create_logbook_entries` | 2^64 | Logbook Entries screen + Create |
| 65 | `sign_logbook_skills` | 2^65 | Sign Off Skills screen |
| 66 | `create_logbook_entries_superuser` | 2^66 | Enhanced logbook capabilities |
| - | `access_marshal_panel` | - | Base marshal access (any of above) |

### Permission Checking

**In Code:**
```dart
// Check single permission
if (user.hasPermission('create_logbook_entries')) {
  // Show feature
}

// Check if user has any marshal permissions
bool _hasMarshalPermissions(dynamic user) {
  return user.hasPermission('create_logbook_entries') ||
         user.hasPermission('sign_logbook_skills') ||
         user.hasPermission('create_trip_report');
}
```

**Permission Model:**
```dart
class UserPermissionModel {
  final int permissions;
  
  bool hasPermission(String permissionName) {
    final bit = _permissionBits[permissionName];
    if (bit == null) return false;
    return (permissions & (1 << bit)) != 0;
  }
  
  static const Map<String, int> _permissionBits = {
    'create_trip_report': 63,
    'create_logbook_entries': 64,
    'sign_logbook_skills': 65,
    'create_logbook_entries_superuser': 66,
  };
}
```

### UI Permission Integration

**Sidebar Navigation:**
```dart
// Marshal Panel Section only visible if user has any marshal permissions
if (_hasMarshalPermissions(user)) ...[
  _SectionHeader(label: 'MARSHAL PANEL', isExpanded: expanded),
  
  // Individual menu items check specific permissions
  if (user.hasPermission('create_logbook_entries'))
    _NavItem(
      icon: Icons.book_outlined,
      label: 'Logbook Entries',
      onTap: () => context.go('/admin/logbook/entries'),
    ),
    
  // ... other menu items
]
```

**Screen-Level Guards:**
```dart
class AdminLogbookEntriesScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProviderV2).user;
    
    // Permission check
    if (!(user?.hasPermission('create_logbook_entries') ?? false)) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to access this feature.'),
        ),
      );
    }
    
    // ... screen content
  }
}
```

---

## User Workflows

### Workflow 1: Create Logbook Entry After Trip

**Scenario:** Marshal wants to record skills verified during a trip.

**Steps:**
1. Navigate to **Admin Panel** → **Marshal Panel** → **Logbook Entries**
2. Tap **Create Entry** FAB button
3. Select **Member** from dropdown
4. Select **Trip** from dropdown
5. Expand level sections and check **Skills** verified during trip
6. Add optional **Comment** about the verification
7. Tap **Create Logbook Entry** button
8. Success message appears
9. Navigated back to logbook entries list
10. New entry appears at top of list

**Validation:**
- All required fields selected
- At least one skill checked
- Comment within 500 character limit

---

### Workflow 2: Sign Off Individual Skills

**Scenario:** Marshal wants to verify specific skills for a member outside of trip context.

**Steps:**
1. Navigate to **Admin Panel** → **Marshal Panel** → **Sign Off Skills**
2. Select **Member** from dropdown
3. Member's skill status loads automatically
4. Optionally select **Trip** to associate verification
5. Review **Unverified Skills** section
6. Check skills to sign off
7. Add individual **Comments** for each skill (optional)
8. Tap **Sign Off Selected Skills** button
9. Each skill is signed off sequentially
10. Success message appears
11. Skills move to **Verified Skills** section
12. Member's skill status refreshes

**Use Cases:**
- Verifying skills demonstrated on multiple trips
- Correcting missing verifications
- Batch verification for experienced members
- Skills verified in training sessions

---

### Workflow 3: Create Trip Report

**Scenario:** Lead marshal documents trip execution and outcomes.

**Steps:**
1. Navigate to **Admin Panel** → **Marshal Panel** → **Trip Reports**
2. Select **Trip** from dropdown
3. Enter **Main Report** (required, 50-2000 characters)
   - Trip execution summary
   - Highlights and challenges
   - Overall assessment
4. Fill optional supplementary fields:
   - **Safety Notes** - Incidents, near-misses, observations
   - **Weather Conditions** - Weather impact on trip
   - **Terrain Notes** - Trail conditions and difficulty
   - **Participant Count** - Total attendees
5. Add **Issues** (optional):
   - Tap "Add Issue" button
   - Enter issue description
   - Repeat for multiple issues
   - Remove unwanted issues with delete icon
6. Tap **Create Trip Report** button
7. Success message appears
8. Form resets for next report

**Best Practices:**
- Create report within 24-48 hours of trip completion
- Include specific safety observations
- Document unusual terrain or weather conditions
- List all significant issues encountered

---

### Workflow 4: View Logbook Entries with Filters

**Scenario:** Marshal wants to review all entries for a specific member or trip.

**Steps:**
1. Navigate to **Admin Panel** → **Marshal Panel** → **Logbook Entries**
2. Initial view shows all entries (paginated, 20 per page)
3. To filter by **Member**:
   - Tap member filter chip at top
   - Select member from dropdown
   - Entries filtered to selected member only
4. To filter by **Trip**:
   - Tap trip filter chip at top
   - Select trip from dropdown
   - Entries filtered to selected trip only
5. To clear filters:
   - Tap "Clear Filters" chip
   - View returns to showing all entries
6. To refresh data:
   - Pull down on the list (pull-to-refresh)
7. To load more entries:
   - Scroll to bottom of list
   - Next page loads automatically

**Filter Combinations:**
- No filters: All entries (default)
- Member only: All entries for specific member
- Trip only: All entries for specific trip
- Both filters: Entries for member on specific trip

---

## API Documentation

### Base Configuration

**API Base URL:** `https://ap.ad4x4.com`  
**Authentication:** Bearer token in Authorization header  
**Content Type:** application/json

### Endpoints

#### 1. Get Logbook Entries

**Endpoint:** `GET /api/logbook/entries/`

**Purpose:** Retrieve paginated list of logbook entries with optional filters.

**Query Parameters:**
- `page` (integer, optional, default: 1) - Page number
- `limit` (integer, optional, default: 20) - Items per page
- `member` (integer, optional) - Filter by member ID
- `trip` (integer, optional) - Filter by trip ID

**Request Example:**
```http
GET /api/logbook/entries/?page=1&limit=20&member=123 HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
```

**Response Example:**
```json
{
  "count": 45,
  "next": "https://ap.ad4x4.com/api/logbook/entries/?page=2&limit=20&member=123",
  "previous": null,
  "results": [
    {
      "id": 1,
      "member": {
        "id": 123,
        "firstName": "John",
        "lastName": "Smith",
        "displayName": "John Smith",
        "avatarUrl": "https://...",
        "level": {
          "id": 2,
          "name": "Level 2",
          "numericLevel": 2
        }
      },
      "trip": {
        "id": 456,
        "title": "Wadi Adventure 2025",
        "startTime": "2025-01-15T08:00:00Z"
      },
      "signedBy": {
        "id": 789,
        "firstName": "Jane",
        "lastName": "Doe",
        "displayName": "Jane Doe"
      },
      "skillsVerified": [
        {
          "id": 10,
          "name": "Hill Descent",
          "level": {
            "id": 2,
            "name": "Level 2"
          }
        }
      ],
      "comment": "Excellent control on steep descent",
      "createdAt": "2025-01-15T16:30:00Z",
      "updatedAt": null
    }
  ]
}
```

**Response Codes:**
- `200 OK` - Success
- `401 Unauthorized` - Invalid or missing token
- `403 Forbidden` - No permission to view entries
- `500 Internal Server Error` - Server error

---

#### 2. Create Logbook Entry

**Endpoint:** `POST /api/logbook/entries/`

**Purpose:** Create new logbook entry recording skill verifications.

**Request Body:**
```json
{
  "trip": 456,
  "member": 123,
  "skills": [10, 11, 12],
  "comment": "Excellent control on steep descent"
}
```

**Request Example:**
```http
POST /api/logbook/entries/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
Content-Type: application/json

{
  "trip": 456,
  "member": 123,
  "skills": [10, 11, 12],
  "comment": "Great performance throughout"
}
```

**Response Example:**
```json
{
  "id": 2,
  "member": {...},
  "trip": {...},
  "signedBy": {...},
  "skillsVerified": [...],
  "comment": "Great performance throughout",
  "createdAt": "2025-01-20T14:30:00Z",
  "updatedAt": null
}
```

**Validation:**
- `trip` - Required, must be valid trip ID
- `member` - Required, must be valid member ID
- `skills` - Required, must be array of valid skill IDs (min 1)
- `comment` - Optional, max 500 characters

**Response Codes:**
- `201 Created` - Entry created successfully
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Invalid token
- `403 Forbidden` - No permission to create entries
- `500 Internal Server Error` - Server error

---

#### 3. Get Logbook Skills

**Endpoint:** `GET /api/logbook/skills/`

**Purpose:** Retrieve catalog of available skills grouped by level.

**Query Parameters:**
- `page` (integer, optional, default: 1) - Page number
- `limit` (integer, optional, default: 100) - Items per page
- `level` (integer, optional) - Filter by level ID

**Request Example:**
```http
GET /api/logbook/skills/?page=1&limit=100 HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
```

**Response Example:**
```json
{
  "count": 45,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 10,
      "name": "Hill Descent",
      "description": "Controlled descent on steep terrain using proper techniques",
      "level": {
        "id": 2,
        "name": "Level 2",
        "numericLevel": 2
      },
      "order": 1,
      "active": true,
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Response Codes:**
- `200 OK` - Success
- `401 Unauthorized` - Invalid token
- `500 Internal Server Error` - Server error

---

#### 4. Get Member Logbook Skills

**Endpoint:** `GET /api/members/<member_id>/logbook-skills/`

**Purpose:** Retrieve member's skill status showing verified and unverified skills.

**Request Example:**
```http
GET /api/members/123/logbook-skills/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
```

**Response Example:**
```json
{
  "results": [
    {
      "id": 1,
      "skill": {
        "id": 10,
        "name": "Hill Descent",
        "level": {
          "id": 2,
          "name": "Level 2"
        }
      },
      "verified": true,
      "verifiedBy": {
        "id": 789,
        "displayName": "Jane Doe"
      },
      "verifiedAt": "2025-01-15T16:30:00Z",
      "verifiedOnTrip": {
        "id": 456,
        "title": "Wadi Adventure 2025"
      },
      "comment": "Excellent control"
    },
    {
      "id": 2,
      "skill": {
        "id": 11,
        "name": "Water Crossing"
      },
      "verified": false,
      "verifiedBy": null,
      "verifiedAt": null,
      "verifiedOnTrip": null,
      "comment": null
    }
  ]
}
```

**Response Codes:**
- `200 OK` - Success
- `401 Unauthorized` - Invalid token
- `404 Not Found` - Member not found
- `500 Internal Server Error` - Server error

---

#### 5. Sign Off Skill

**Endpoint:** `POST /api/logbook/sign-off/`

**Purpose:** Sign off individual skill for a member.

**Request Body:**
```json
{
  "member": 123,
  "skill": 10,
  "trip": 456,
  "comment": "Demonstrated excellent technique"
}
```

**Request Example:**
```http
POST /api/logbook/sign-off/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
Content-Type: application/json

{
  "member": 123,
  "skill": 10,
  "trip": 456,
  "comment": "Demonstrated excellent technique"
}
```

**Response Example:**
```json
{
  "id": 3,
  "skill": {...},
  "verified": true,
  "verifiedBy": {...},
  "verifiedAt": "2025-01-20T15:00:00Z",
  "verifiedOnTrip": {...},
  "comment": "Demonstrated excellent technique"
}
```

**Validation:**
- `member` - Required, valid member ID
- `skill` - Required, valid skill ID
- `trip` - Optional, valid trip ID
- `comment` - Optional, max 500 characters

**Response Codes:**
- `201 Created` - Skill signed off successfully
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Invalid token
- `403 Forbidden` - No permission to sign off skills
- `409 Conflict` - Skill already verified
- `500 Internal Server Error` - Server error

---

#### 6. Create Trip Report

**Endpoint:** `POST /api/trip-reports/`

**Purpose:** Create comprehensive post-trip report.

**Request Body:**
```json
{
  "trip": 456,
  "report": "Trip executed successfully with all objectives met. Participants demonstrated good skills progression.",
  "safetyNotes": "One minor incident with tire puncture, handled appropriately.",
  "weatherConditions": "Clear skies, temperature 25-30°C, excellent conditions.",
  "terrainNotes": "Mixed terrain with sandy sections and rocky climbs. Trail conditions good.",
  "participantCount": 12,
  "issues": [
    "Vehicle #3 experienced tire puncture at checkpoint 2",
    "Slight delay at lunch due to location change"
  ]
}
```

**Request Example:**
```http
POST /api/trip-reports/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
Content-Type: application/json

{
  "trip": 456,
  "report": "Successful trip with excellent participation...",
  "participantCount": 12
}
```

**Response Example:**
```json
{
  "id": 5,
  "trip": {
    "id": 456,
    "title": "Wadi Adventure 2025"
  },
  "createdBy": {
    "id": 789,
    "displayName": "Jane Doe"
  },
  "report": "Successful trip with excellent participation...",
  "safetyNotes": null,
  "weatherConditions": null,
  "terrainNotes": null,
  "participantCount": 12,
  "issues": null,
  "createdAt": "2025-01-20T18:00:00Z"
}
```

**Validation:**
- `trip` - Required, valid trip ID
- `report` - Required, 50-2000 characters
- `safetyNotes` - Optional, max 1000 characters
- `weatherConditions` - Optional, max 500 characters
- `terrainNotes` - Optional, max 1000 characters
- `participantCount` - Optional, positive integer
- `issues` - Optional, array of strings (max 10 items)

**Response Codes:**
- `201 Created` - Report created successfully
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Invalid token
- `403 Forbidden` - No permission to create reports
- `500 Internal Server Error` - Server error

---

#### 7. Get Trip Reports

**Endpoint:** `GET /api/trip-reports/`

**Purpose:** Retrieve paginated list of trip reports.

**Query Parameters:**
- `page` (integer, optional, default: 1) - Page number
- `limit` (integer, optional, default: 20) - Items per page
- `trip` (integer, optional) - Filter by trip ID

**Request Example:**
```http
GET /api/trip-reports/?page=1&limit=20&trip=456 HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
```

**Response Example:**
```json
{
  "count": 8,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 5,
      "trip": {...},
      "createdBy": {...},
      "report": "Successful trip...",
      "safetyNotes": "...",
      "weatherConditions": "...",
      "terrainNotes": "...",
      "participantCount": 12,
      "issues": ["..."],
      "createdAt": "2025-01-20T18:00:00Z"
    }
  ]
}
```

**Response Codes:**
- `200 OK` - Success
- `401 Unauthorized` - Invalid token
- `500 Internal Server Error` - Server error

---

## Testing Guide

### Pre-Testing Checklist

**Backend Requirements:**
- ✅ API endpoints deployed and accessible
- ✅ Database migrations applied
- ✅ Test data created (members, trips, skills)
- ✅ Marshal user accounts created with appropriate permissions

**Frontend Requirements:**
- ✅ Flutter app built successfully
- ✅ No compilation errors
- ✅ Authentication working
- ✅ User has marshal permissions

### Test Scenarios

#### Test 1: View Logbook Entries

**Objective:** Verify logbook entries display correctly with all information.

**Prerequisites:**
- At least 5 logbook entries exist in database
- User has `create_logbook_entries` permission

**Steps:**
1. Log in as marshal user
2. Navigate to Admin Panel → Marshal Panel → Logbook Entries
3. Verify entries list loads successfully
4. Check each entry card displays:
   - Member avatar and name
   - Member level badge
   - Date of verification
   - Trip title (if associated)
   - Skills verified as chips
   - Marshal signature
   - Comment (if present)
5. Scroll to bottom to trigger pagination
6. Verify next page loads automatically
7. Pull down to trigger refresh
8. Verify data refreshes successfully

**Expected Results:**
- ✅ All entries display with correct information
- ✅ Pagination works smoothly
- ✅ Pull-to-refresh updates data
- ✅ No errors or crashes

---

#### Test 2: Filter Logbook Entries

**Objective:** Verify filtering by member and trip works correctly.

**Prerequisites:**
- Multiple logbook entries for different members and trips
- User has `create_logbook_entries` permission

**Steps:**
1. Navigate to Logbook Entries screen
2. Tap "Filter by Member" chip
3. Select a member from dropdown
4. Verify only entries for selected member display
5. Note member filter chip shows selected member
6. Tap "Filter by Trip" chip
7. Select a trip from dropdown
8. Verify only entries for selected member on selected trip display
9. Tap "Clear Filters" chip
10. Verify all entries display again

**Expected Results:**
- ✅ Member filter correctly filters entries
- ✅ Trip filter correctly filters entries
- ✅ Combined filters work correctly
- ✅ Clear filters resets view
- ✅ Filter chips display correctly

---

#### Test 3: Create Logbook Entry

**Objective:** Verify creating new logbook entry with skill verifications.

**Prerequisites:**
- Active members exist
- Recent trips exist
- Skills defined in system
- User has `create_logbook_entries` permission

**Steps:**
1. Navigate to Logbook Entries screen
2. Tap FAB "Create Entry" button
3. Verify navigation to create form
4. Tap "Select Member" dropdown
5. Select a member from list
6. Tap "Select Trip" dropdown
7. Select a trip from list
8. Expand a level section (e.g., "Level 2")
9. Check 2-3 skills in that level
10. Enter optional comment: "Test entry - excellent performance"
11. Tap "Create Logbook Entry" button
12. Verify success message appears
13. Verify navigation back to entries list
14. Verify new entry appears at top of list

**Expected Results:**
- ✅ Form loads with all dropdowns populated
- ✅ Skills grouped correctly by level
- ✅ Entry creates successfully
- ✅ Success message displays
- ✅ Navigation returns to list
- ✅ New entry visible in list

**Validation Tests:**
1. Try submitting without member → Error message
2. Try submitting without trip → Error message
3. Try submitting without skills → Error message
4. Try comment over 500 chars → Error message

---

#### Test 4: Sign Off Skills

**Objective:** Verify signing off individual skills for a member.

**Prerequisites:**
- Member exists with unverified skills
- User has `sign_logbook_skills` permission

**Steps:**
1. Navigate to Admin Panel → Marshal Panel → Sign Off Skills
2. Tap "Select Member" dropdown
3. Select a member
4. Verify member's skills load automatically
5. Verify Unverified Skills section shows unverified skills
6. Verify Verified Skills section shows previously verified skills
7. Check 2 unverified skills
8. Enter comment for first skill: "Demonstrated on training day"
9. Optionally select a trip
10. Tap "Sign Off Selected Skills" button
11. Verify loading indicators appear
12. Verify success message appears
13. Verify skills move to Verified Skills section
14. Verify verified skills show:
    - Verification date
    - Verifying marshal
    - Associated trip (if selected)
    - Comment

**Expected Results:**
- ✅ Member skills load correctly
- ✅ Skills categorized as verified/unverified
- ✅ Batch sign-off works
- ✅ Individual comments saved
- ✅ Status updates in real-time
- ✅ Verified skills display complete information

**Edge Cases:**
1. Member with no unverified skills → Message displayed
2. Sign off without trip → Works (trip optional)
3. Sign off without comments → Works (comments optional)

---

#### Test 5: Create Trip Report

**Objective:** Verify creating comprehensive post-trip report.

**Prerequisites:**
- Recent trips exist
- User has `create_trip_report` permission

**Steps:**
1. Navigate to Admin Panel → Marshal Panel → Trip Reports
2. Tap "Select Trip" dropdown
3. Select a trip
4. Enter main report (100 chars): "Successful trip with excellent participation. All objectives met."
5. Enter safety notes: "One minor tire puncture handled appropriately."
6. Enter weather: "Clear skies, 25-30°C"
7. Enter terrain: "Mixed sandy and rocky terrain"
8. Enter participant count: "12"
9. Tap "Add Issue" button
10. Enter issue: "Vehicle #3 tire puncture at checkpoint 2"
11. Tap "Add Issue" again
12. Enter issue: "Slight delay at lunch"
13. Tap "Create Trip Report" button
14. Verify success message appears
15. Verify form resets for next report

**Expected Results:**
- ✅ Form loads with trip dropdown populated
- ✅ All fields accept input correctly
- ✅ Issues can be added/removed dynamically
- ✅ Report creates successfully
- ✅ Success message displays
- ✅ Form resets after submission

**Validation Tests:**
1. Submit without trip → Error
2. Submit with <50 char report → Error
3. Submit with >2000 char report → Error
4. Submit with negative participant count → Error
5. Submit with only required fields → Success

---

### Performance Testing

**Pagination Performance:**
- Load first page of entries → Should complete in <2s
- Scroll to trigger next page → Should load in <1s
- Measure with 100+ entries → Smooth scrolling

**Filter Performance:**
- Apply member filter → Results update in <500ms
- Apply trip filter → Results update in <500ms
- Clear filters → View resets in <500ms

**Form Submission:**
- Create logbook entry → Completes in <2s
- Sign off skills (batch) → Each skill <1s
- Create trip report → Completes in <2s

### Accessibility Testing

**Screen Reader Compatibility:**
- All buttons have semantic labels
- Form fields have descriptive labels
- Error messages are announced
- Success messages are announced

**Keyboard Navigation:**
- Tab through all form fields
- Enter key submits forms
- Escape key closes dialogs

**Visual Accessibility:**
- Color contrast meets WCAG 2.1 AA standards
- Text sizes readable at default zoom
- Touch targets minimum 48x48dp

---

## Troubleshooting

### Common Issues

#### Issue 1: "You do not have permission to access this feature"

**Symptoms:**
- Screen shows permission denied message
- Unable to access Marshal Panel sections

**Causes:**
- User account missing required permissions
- Permission bits not set correctly in database
- Authentication token expired

**Solutions:**
1. **Verify Permissions:**
   ```sql
   SELECT id, username, permissions FROM users WHERE id = <user_id>;
   ```
   
2. **Check Permission Bits:**
   - `create_logbook_entries`: Bit 64 (value: 2^64)
   - `sign_logbook_skills`: Bit 65 (value: 2^65)
   - `create_trip_report`: Bit 63 (value: 2^63)

3. **Grant Permission (Backend):**
   ```python
   user.permissions |= (1 << 64)  # Grant create_logbook_entries
   user.save()
   ```

4. **Refresh Token:**
   - Log out and log back in
   - Verify new token includes updated permissions

---

#### Issue 2: Logbook Entries Not Loading

**Symptoms:**
- Blank screen or loading spinner indefinitely
- Error message displayed

**Causes:**
- API endpoint not responding
- Network connectivity issues
- Invalid authentication token
- Backend error

**Debugging Steps:**
1. **Check Network:**
   ```dart
   // Check console logs for API errors
   flutter logs | grep "logbook/entries"
   ```

2. **Verify API Response:**
   ```bash
   curl -H "Authorization: Bearer <token>" \
        https://ap.ad4x4.com/api/logbook/entries/
   ```

3. **Check Provider State:**
   ```dart
   // In code, add debug logging
   print('Logbook state: ${ref.watch(logbookEntriesProvider)}');
   ```

**Solutions:**
- Ensure API server is running
- Verify token is valid and not expired
- Check backend logs for errors
- Refresh data with pull-to-refresh

---

#### Issue 3: Skills Not Loading for Member

**Symptoms:**
- Member selected but skills section empty
- Loading indicator stuck

**Causes:**
- Member has no skills defined for their level
- API endpoint error
- Network timeout

**Debugging Steps:**
1. **Check Member Level:**
   - Verify member has a level assigned
   - Verify skills exist for that level

2. **Check API Response:**
   ```bash
   curl -H "Authorization: Bearer <token>" \
        https://ap.ad4x4.com/api/members/<id>/logbook-skills/
   ```

3. **Check Provider:**
   ```dart
   // In code
   ref.listen(memberSkillsStatusProvider(memberId), (prev, next) {
     print('Member skills state: $next');
   });
   ```

**Solutions:**
- Ensure skills are defined for member's level in database
- Verify member ID is correct
- Check API response format matches expected structure
- Retry selection with different member

---

#### Issue 4: Form Submission Fails

**Symptoms:**
- Submit button pressed but no response
- Error message displayed
- Form doesn't clear

**Causes:**
- Validation errors
- API endpoint error
- Network timeout
- Missing required fields

**Debugging Steps:**
1. **Check Validation:**
   ```dart
   if (!_formKey.currentState!.validate()) {
     print('Form validation failed');
     return;
   }
   ```

2. **Check API Request:**
   ```dart
   // Add try-catch in provider
   try {
     await repository.createLogbookEntry(...);
   } catch (e) {
     print('API error: $e');
   }
   ```

3. **Check Network Tab:**
   - Open Flutter DevTools
   - Check Network tab for API requests
   - Inspect request/response

**Solutions:**
- Fill all required fields
- Ensure selections are valid (member, trip, skills)
- Check comment length (<500 chars)
- Verify API endpoint is accessible
- Check backend logs for validation errors

---

#### Issue 5: Pagination Not Working

**Symptoms:**
- Scroll to bottom but no more entries load
- Loading indicator appears but nothing happens

**Causes:**
- No more data to load
- API pagination broken
- Network error during load

**Debugging Steps:**
1. **Check State:**
   ```dart
   final state = ref.watch(logbookEntriesProvider);
   print('Has more: ${state.hasMore}');
   print('Current page: ${state.currentPage}');
   print('Total count: ${state.totalCount}');
   ```

2. **Check API Response:**
   - Verify `next` field in response
   - Check `count` vs number of items loaded

3. **Check Scroll Detection:**
   - Ensure ScrollController attached
   - Verify _onScroll callback firing

**Solutions:**
- If hasMore is false, no more data exists (expected)
- If API returns error, check backend logs
- If network error, retry with pull-to-refresh
- Clear filters if applied

---

### Debug Mode

**Enable Detailed Logging:**

1. **In Provider:**
   ```dart
   Future<void> loadEntries({bool loadMore = false}) async {
     print('[LogbookProvider] Loading entries, page: $_currentPage');
     
     try {
       final response = await _repository.getLogbookEntries(
         page: _currentPage,
         limit: _pageSize,
       );
       print('[LogbookProvider] Response: ${response['count']} total');
       
       // ... rest of logic
     } catch (e, stack) {
       print('[LogbookProvider] Error: $e');
       print('[LogbookProvider] Stack: $stack');
     }
   }
   ```

2. **In Repository:**
   ```dart
   Future<Map<String, dynamic>> getLogbookEntries({...}) async {
     print('[Repository] GET /api/logbook/entries/');
     
     final response = await _apiClient.get(
       MainApiEndpoints.logbookEntries,
       queryParameters: queryParams,
     );
     
     print('[Repository] Response: ${response.data}');
     return response.data;
   }
   ```

3. **Flutter Logs:**
   ```bash
   flutter logs --verbose
   ```

---

### Backend Debugging

**Check Django Logs:**
```bash
# Production logs
tail -f /var/log/django/access.log
tail -f /var/log/django/error.log

# Development logs
python manage.py runserver --verbosity 2
```

**Check Database:**
```sql
-- Count logbook entries
SELECT COUNT(*) FROM logbook_entries;

-- Check recent entries
SELECT * FROM logbook_entries ORDER BY created_at DESC LIMIT 10;

-- Check skills
SELECT * FROM logbook_skills;

-- Check member skills status
SELECT * FROM member_skills_status WHERE member_id = <id>;
```

**Check Permissions:**
```sql
-- User permissions
SELECT id, username, permissions FROM users WHERE id = <user_id>;

-- Decode permission bits
SELECT (permissions & (1 << 64)) != 0 AS has_create_logbook FROM users WHERE id = <user_id>;
```

---

### Performance Issues

**Slow Loading:**
1. Check API response time
2. Verify database indexes exist
3. Optimize queries (add indexes if needed)
4. Reduce page size if timeout occurs

**UI Lag:**
1. Profile widget rebuilds
2. Optimize list rendering (use const constructors)
3. Implement proper keys for list items
4. Consider virtualization for very long lists

**Memory Issues:**
1. Check for memory leaks (unused subscriptions)
2. Dispose controllers properly
3. Limit cache size in providers
4. Use pagination to reduce data in memory

---

## Maintenance

### Regular Tasks

**Weekly:**
- Review error logs
- Check API performance metrics
- Verify permissions still working correctly

**Monthly:**
- Review and clean test data
- Update documentation if API changes
- Performance testing with production data

**Quarterly:**
- Review user feedback
- Plan feature enhancements
- Update dependencies (carefully)

### Future Enhancements

**Planned Features:**
1. **Entry Details Screen** - View full entry with edit capability
2. **Skill Progress Charts** - Visual representation of member progress
3. **Bulk Import** - Import multiple entries from CSV
4. **Export Reports** - Export logbook data to PDF/Excel
5. **Advanced Filters** - Date range, skill-specific filters
6. **Offline Support** - Queue entries when offline
7. **Photo Attachments** - Add photos to entries and reports
8. **Marshal Analytics** - Dashboard showing marshal activity

---

## Appendix

### Related Documentation

- [AD4X4 Development Master Plan](./AD4X4_DEVELOPMENT_MASTER_PLAN.md)
- [Phase 3A Progress Tracking](./PHASE3A_PROGRESS.md)
- [API Documentation](https://ap.ad4x4.com/api/docs/)
- [Permission System Design](./docs/permissions.md)

### Contact & Support

**Development Team:**
- Lead Developer: [Your Name]
- Backend API: https://ap.ad4x4.com
- Issue Tracking: [GitHub Issues Link]

**Version History:**
- v1.0.0 (January 2025) - Initial release with all features
  - Logbook Entries Management
  - Skills Sign-off System
  - Trip Reports
  - Permission-based access control

---

**Document Version:** 1.0.0  
**Last Updated:** January 20, 2025  
**Status:** Phase 3A Complete ✅
