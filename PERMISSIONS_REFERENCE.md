# AD4x4 Admin Panel - Permissions Reference Document

**Generated**: November 11, 2025  
**Source**: Live API data from Hani AMJ account (63 permissions)  
**Purpose**: Complete reference for all available permissions in the AD4x4 backend system

---

## Table of Contents

1. [Permission System Overview](#permission-system-overview)
2. [All Available Permissions (By Category)](#all-available-permissions-by-category)
3. [Permission ID Reference (Alphabetical)](#permission-id-reference-alphabetical)
4. [Permission Groups](#permission-groups)
5. [Usage in Flutter](#usage-in-flutter)

---

## Permission System Overview

### Architecture
- **Model**: "Open Door, Locked Rooms" - Sidebar shows Admin Panel link to all users, but individual sections are permission-gated
- **Backend Format**: Plural naming (e.g., `create_meeting_points`, `edit_trips`)
- **Flutter Format**: Must match backend exactly - use plural forms
- **API Endpoint**: `GET /api/auth/profile/` returns user object with `permissions` array

### Permission Object Structure
```json
{
  "id": 28,
  "action": "edit_meeting_points",
  "levels": [...]
}
```

### Flutter Permission Check
```dart
// In UserModel class
bool hasPermission(String permissionAction) {
  return permissions.any((p) => p.action == permissionAction);
}

// Usage
if (user?.hasPermission('create_meeting_points') ?? false) {
  // Show create button
}
```

---

## All Available Permissions (By Category)

### 📍 Meeting Points (8 permissions)

| ID | Permission Action | Description | Groups |
|----|------------------|-------------|---------|
| 3 | `create_meeting_points` | Create new meeting points | Explorers |
| 27 | `create_meeting_points` | Create new meeting points | Meeting point managers |
| 28 | `edit_meeting_points` | Edit existing meeting points | Meeting point managers |
| 29 | `delete_meeting_points` | Delete meeting points | Meeting point managers |
| 39 | `create_meeting_points` | Create new meeting points | Site admins |
| 40 | `edit_meeting_points` | Edit existing meeting points | Site admins |
| 41 | `delete_meeting_points` | Delete meeting points | Site admins |
| 57 | `create_meeting_points` | Create new meeting points | Marshals |

**Note**: Multiple IDs for same action indicate different permission groups granting the same capability.

---

### 🚗 Trips (24 permissions)

| ID | Permission Action | Description | Category |
|----|------------------|-------------|----------|
| 1 | `create_trip_with_approval` | Create trip requiring approval | Trip Creation |
| 2 | `create_trip` | Create trip without approval | Trip Creation |
| 4 | `create_trip` | Create trip without approval (duplicate) | Trip Creation |
| 24 | `create_trip` | Create trip without approval (duplicate) | Trip Creation |
| 30 | `create_trip` | Create trip without approval (duplicate) | Trip Creation |
| 31 | `create_trip_with_approval` | Create trip requiring approval (duplicate) | Trip Creation |
| 19 | `edit_trips` | Edit trip details | Trip Management |
| 34 | `edit_trips` | Edit trip details (duplicate) | Trip Management |
| 53 | `edit_trips` | Edit trip details (duplicate) | Trip Management |
| 54 | `edit_trips` | Edit trip details (duplicate) | Trip Management |
| 26 | `edit_trip_media` | Edit trip photos/videos | Trip Management |
| 35 | `edit_trip_media` | Edit trip photos/videos (duplicate) | Trip Management |
| 23 | `edit_trip_registrations` | Edit trip registrations | Trip Management |
| 36 | `edit_trip_registrations` | Edit trip registrations (duplicate) | Trip Management |
| 20 | `approve_trip` | Approve trip submissions | Trip Approval |
| 32 | `approve_trip` | Approve trip submissions (duplicate) | Trip Approval |
| 52 | `approve_trip` | Approve trip submissions (duplicate) | Trip Approval |
| 21 | `delete_trips` | Delete trips | Trip Management |
| 37 | `delete_trips` | Delete trips (duplicate) | Trip Management |
| 55 | `delete_trips` | Delete trips (duplicate) | Trip Management |
| 56 | `delete_trips` | Delete trips (duplicate) | Trip Management |
| 22 | `delete_trip_comments` | Delete trip comments | Trip Management |
| 38 | `delete_trip_comments` | Delete trip comments (duplicate) | Trip Management |
| 63 | `create_trip_report` | Create trip reports | Trip Reports |

---

### 👥 Members (1 permission)

| ID | Permission Action | Description |
|----|------------------|-------------|
| 51 | `edit_membership_payments` | Edit member payment records |

**Note**: Very limited member management permissions detected. Backend may have more member-related permissions not assigned to test account.

---

### ⬆️ Upgrade Requests (22 permissions)

| ID | Permission Action | Description | Scope |
|----|------------------|-------------|-------|
| 5 | `view_upgrade_req` | View upgrade requests | Basic |
| 8 | `view_upgrade_req` | View upgrade requests (duplicate) | Basic |
| 13 | `view_upgrade_req` | View upgrade requests (duplicate) | Basic |
| 47 | `view_upgrade_req` | View upgrade requests (duplicate) | Basic |
| 6 | `vote_upgrade_req` | Vote on upgrade requests | Voting |
| 9 | `vote_upgrade_req` | Vote on upgrade requests (duplicate) | Voting |
| 14 | `vote_upgrade_req` | Vote on upgrade requests (duplicate) | Voting |
| 48 | `vote_upgrade_req` | Vote on upgrade requests (duplicate) | Voting |
| 7 | `create_comment_upgrade_req` | Comment on upgrade requests | Comments |
| 10 | `create_comment_upgrade_req` | Comment on upgrade requests (duplicate) | Comments |
| 15 | `create_comment_upgrade_req` | Comment on upgrade requests (duplicate) | Comments |
| 49 | `create_comment_upgrade_req` | Comment on upgrade requests (duplicate) | Comments |
| 18 | `delete_comment_upgrade_req` | Delete upgrade request comments | Comments |
| 50 | `delete_comment_upgrade_req` | Delete upgrade request comments (duplicate) | Comments |
| 42 | `create_upgrade_req_for_self` | Create upgrade request for self | Creation |
| 43 | `create_upgrade_req_for_other` | Create upgrade request for others | Creation |
| 16 | `edit_upgrade_req` | Edit upgrade requests | Management |
| 44 | `edit_upgrade_req` | Edit upgrade requests (duplicate) | Management |
| 17 | `delete_upgrade_req` | Delete upgrade requests | Management |
| 46 | `delete_upgrade_req` | Delete upgrade requests (duplicate) | Management |
| 11 | `approve_upgrade_req` | Approve/decline upgrade requests | Approval |
| 45 | `approve_upgrade_req` | Approve/decline upgrade requests (duplicate) | Approval |

---

### 🔧 Other Permissions (8 permissions)

| ID | Permission Action | Description | Category |
|----|------------------|-------------|----------|
| 12 | `override_waitlist` | Override trip waitlist restrictions | Trip Management |
| 25 | `override_waitlist` | Override trip waitlist restrictions (duplicate) | Trip Management |
| 33 | `override_waitlist` | Override trip waitlist restrictions (duplicate) | Trip Management |
| 61 | `bypass_level_req` | Bypass level requirements | System |
| 62 | `access_marshal_panel` | Access marshal-specific features | Marshal |
| 63 | `create_trip_report` | Create detailed trip reports | Marshal |
| 64 | `create_logbook_entries` | Create logbook entries | Marshal |
| 65 | `sign_logbook_skills` | Sign off on member skills | Marshal |
| 66 | `create_logbook_entries_superuser` | Create logbook entries (superuser) | Marshal |

---

## Permission ID Reference (Alphabetical)

Complete list sorted by permission action name:

```
access_marshal_panel (62)
approve_trip (20, 32, 52)
approve_upgrade_req (11, 45)
bypass_level_req (61)
create_comment_upgrade_req (7, 10, 15, 49)
create_logbook_entries (64)
create_logbook_entries_superuser (66)
create_meeting_points (3, 27, 39, 57)
create_trip (2, 4, 24, 30)
create_trip_report (63)
create_trip_with_approval (1, 31)
create_upgrade_req_for_other (43)
create_upgrade_req_for_self (42)
delete_comment_upgrade_req (18, 50)
delete_meeting_points (29, 41)
delete_trip_comments (22, 38)
delete_trips (21, 37, 55, 56)
delete_upgrade_req (17, 46)
edit_meeting_points (28, 40)
edit_membership_payments (51)
edit_trip_media (26, 35)
edit_trip_registrations (23, 36)
edit_trips (19, 34, 53, 54)
edit_upgrade_req (16, 44)
override_waitlist (12, 25, 33)
sign_logbook_skills (65)
view_upgrade_req (5, 8, 13, 47)
vote_upgrade_req (6, 9, 14, 48)
```

---

## Permission Groups

Based on observed patterns, permissions are grouped by role:

### 🔰 Explorers
- `create_meeting_points` (3)

### 📍 Meeting Point Managers
- `create_meeting_points` (27)
- `edit_meeting_points` (28)
- `delete_meeting_points` (29)

### 🛡️ Site Admins
- `create_meeting_points` (39)
- `edit_meeting_points` (40)
- `delete_meeting_points` (41)
- Full trip management
- Full upgrade request management

### 🎖️ Marshals
- `create_meeting_points` (57)
- `access_marshal_panel` (62)
- `create_trip_report` (63)
- `create_logbook_entries` (64)
- `sign_logbook_skills` (65)
- `create_logbook_entries_superuser` (66)
- Trip approval and management

### 📊 Board Members (Level 800+)
- Typically granted most/all permissions
- Full access to all admin features

---

## Usage in Flutter

### 1. Check if Section Should be Visible

```dart
// In admin_dashboard_screen.dart sidebar

bool _hasMeetingPointPermissions(dynamic user) {
  return user.hasPermission('create_meeting_points') ||
         user.hasPermission('edit_meeting_points') ||
         user.hasPermission('delete_meeting_points');
}

bool _hasUpgradeRequestPermissions(dynamic user) {
  return user.hasPermission('view_upgrade_req') ||
         user.hasPermission('create_upgrade_req_for_self') ||
         user.hasPermission('approve_upgrade_req');
}

bool _hasMarshalPermissions(dynamic user) {
  return user.hasPermission('access_marshal_panel');
}
```

### 2. Check Before Showing Action Buttons

```dart
// In admin_meeting_points_screen.dart

final canCreate = user?.hasPermission('create_meeting_points') ?? false;
final canEdit = user?.hasPermission('edit_meeting_points') ?? false;
final canDelete = user?.hasPermission('delete_meeting_points') ?? false;

// Show create button only if user has permission
if (canCreate) {
  FloatingActionButton(
    onPressed: _navigateToCreateForm,
    child: Icon(Icons.add),
  )
}

// Show edit/delete buttons in list items
IconButton(
  icon: Icon(Icons.edit),
  onPressed: canEdit ? () => _editMeetingPoint(point) : null,
)
```

### 3. Handle Multiple Permission Scenarios

```dart
// Trip approval - check if user can approve trips
final canApprove = user?.hasPermission('approve_trip') ?? false;

// Upgrade requests - check specific capabilities
final canViewRequests = user?.hasPermission('view_upgrade_req') ?? false;
final canVote = user?.hasPermission('vote_upgrade_req') ?? false;
final canApproveRequests = user?.hasPermission('approve_upgrade_req') ?? false;
final canCreateForOthers = user?.hasPermission('create_upgrade_req_for_other') ?? false;
```

### 4. Combining Permissions with OR Logic

```dart
// User can edit trips if they have ANY trip edit permission
final canEditTrips = user?.hasPermission('edit_trips') ?? false;
final canEditMedia = user?.hasPermission('edit_trip_media') ?? false;
final canEditRegistrations = user?.hasPermission('edit_trip_registrations') ?? false;

final hasAnyEditPermission = canEditTrips || canEditMedia || canEditRegistrations;
```

---

## Common Patterns

### Pattern 1: Create/Edit/Delete Triple
Most resources follow this pattern:
- `create_[resource]` - Create new items
- `edit_[resource]` - Modify existing items  
- `delete_[resource]` - Remove items

**Examples**: 
- Meeting points: `create_meeting_points`, `edit_meeting_points`, `delete_meeting_points`
- Trips: `create_trip`, `edit_trips`, `delete_trips`

### Pattern 2: View/Vote/Comment/Approve Workflow
Upgrade requests follow a multi-stage workflow:
- `view_upgrade_req` - See requests
- `vote_upgrade_req` - Vote on requests
- `create_comment_upgrade_req` - Discuss requests
- `approve_upgrade_req` - Final approval

### Pattern 3: Self vs Others
Some actions have separate permissions for self vs others:
- `create_upgrade_req_for_self` - Create for yourself
- `create_upgrade_req_for_other` - Create for someone else

### Pattern 4: Regular vs Superuser
Some permissions have elevated versions:
- `create_logbook_entries` - Regular logbook access
- `create_logbook_entries_superuser` - Full logbook control

---

## Notes for Developers

### ⚠️ CRITICAL: Permission Name Format
- **Backend uses PLURAL forms**: `create_meeting_points` (with 's')
- **DO NOT use singular forms**: ~~`create_meeting_point`~~ (will fail)
- **Bug History**: Flutter app originally used singular forms, causing JavaScript errors and hidden UI sections

### 🚨 COMMON MISTAKES (Fixed November 11, 2025)

**❌ DO NOT USE these invented permission names:**
- ~~`manage_registrations`~~ → Use `edit_trip_registrations` ✅
- ~~`moderate_gallery`~~ → Use `edit_trip_media` ✅
- ~~`moderate_comments`~~ → Use `delete_trip_comments` ✅
- ~~`approve_trips`~~ → Use `approve_trip` ✅
- ~~`manage_trips`~~ → Use `edit_trips` ✅

**These names do NOT exist in backend API and will cause permission checks to always fail!**

**📖 For complete list of correct permissions, see:** `CORRECT_PERMISSIONS_REFERENCE.md`

### 🔍 Testing Permissions
1. Login with test account credentials
2. Call `GET /api/auth/profile/` to get user permissions
3. Extract `permissions` array from response
4. Check for required permission actions

### 📝 Adding New Permission Checks
When adding new admin features:

1. **Check backend permission availability** - Verify permission exists in backend
2. **Update this document** - Add new permission to appropriate category
3. **Add permission constant** - Document the exact permission action string
4. **Implement UI check** - Use `user?.hasPermission('action_name') ?? false`
5. **Test with multiple user roles** - Verify permission gating works correctly

### 🐛 Common Issues
1. **Sidebar not showing section** - Check if any permission in the section exists
2. **Action buttons not appearing** - Verify exact permission action name (plural vs singular)
3. **Permission check always fails** - Ensure user object is loaded from profile API
4. **Multiple permission IDs** - Normal! Users can belong to multiple groups with same permissions

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial document creation with all 63 permissions | Friday AI |

---

## References

- **API Base URL**: `https://ap.ad4x4.com`
- **Profile Endpoint**: `GET /api/auth/profile/`
- **Login Endpoint**: `POST /api/auth/login/`
- **User Model**: `/lib/data/models/user_model.dart`
- **Permission Model**: `/lib/data/models/permission_model.dart`
- **Admin Dashboard**: `/lib/presentation/screens/admin/admin_dashboard_screen.dart`
