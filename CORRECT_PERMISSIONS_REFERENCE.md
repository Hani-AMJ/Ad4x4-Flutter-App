# AD4x4 Correct Permissions Reference - OFFICIAL

**Last Updated:** November 11, 2025  
**Purpose:** Single source of truth for all correct permission names  
**Status:** ✅ All permissions verified against live backend API

---

## 🚨 CRITICAL: Permission Name Format Rules

### ✅ ALWAYS Use These Exact Names

The backend API uses **PLURAL forms** for resource names. **DO NOT improvise or guess permission names.**

### ❌ Common Mistakes to AVOID

| ❌ WRONG (Frontend Assumption) | ✅ CORRECT (Backend API) | Category |
|-------------------------------|-------------------------|----------|
| `manage_registrations` | `edit_trip_registrations` | Registrations |
| `moderate_gallery` | `edit_trip_media` | Trip Media |
| `moderate_comments` | `delete_trip_comments` | Comments |
| `create_meeting_point` | `create_meeting_points` | Meeting Points |
| `edit_meeting_point` | `edit_meeting_points` | Meeting Points |
| `delete_meeting_point` | `delete_meeting_points` | Meeting Points |
| `approve_trips` | `approve_trip` | Trip Approval |
| `manage_trips` | `edit_trips` | Trip Management |

---

## 📍 All Backend Permissions (63 Total)

### 🚗 TRIP MANAGEMENT (24 permissions)

#### Trip Creation
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `create_trip` | 2, 4, 24, 30 | Create trip without approval | ✅ YES |
| `create_trip_with_approval` | 1, 31 | Create trip requiring approval | ✅ YES |

#### Trip Editing & Management
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `edit_trips` | 19, 34, 53, 54 | Edit trip details | ✅ YES |
| `edit_trip_media` | 26, 35 | Edit trip photos/videos | ✅ YES |
| `edit_trip_registrations` | 23, 36 | Edit trip registrations | ✅ YES |

#### Trip Approval & Deletion
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `approve_trip` | 20, 32, 52 | Approve trip submissions | ✅ YES |
| `delete_trips` | 21, 37, 55, 56 | Delete trips | ✅ YES |
| `delete_trip_comments` | 22, 38 | Delete trip comments | ✅ YES |

#### Trip Reports
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `create_trip_report` | 63 | Create trip reports | ✅ YES |

---

### 📍 MEETING POINTS (8 permissions)

| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `create_meeting_points` | 3, 27, 39, 57 | Create new meeting points | ✅ YES |
| `edit_meeting_points` | 28, 40 | Edit existing meeting points | ✅ YES |
| `delete_meeting_points` | 29, 41 | Delete meeting points | ✅ YES |

**⚠️ NOTE:** Backend uses **PLURAL** form (`meeting_points` with 's')

---

### 👥 MEMBER MANAGEMENT (1 permission)

| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `view_members` | Unknown | View member list and details | ✅ YES |
| `edit_membership_payments` | 51 | Edit member payment records | ❌ NO (feature not built) |

**⚠️ NOTE:** `edit_members` does NOT exist in backend - use `edit_membership_payments` or wait for backend to add it

---

### ⬆️ UPGRADE REQUESTS (22 permissions)

#### View & Voting
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `view_upgrade_req` | 5, 8, 13, 47 | View upgrade requests | ✅ YES |
| `vote_upgrade_req` | 6, 9, 14, 48 | Vote on upgrade requests | ✅ YES |

#### Comments
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `create_comment_upgrade_req` | 7, 10, 15, 49 | Comment on upgrade requests | ✅ YES |
| `delete_comment_upgrade_req` | 18, 50 | Delete upgrade request comments | ✅ YES |

#### Creation & Management
| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `create_upgrade_req_for_self` | 42 | Create upgrade request for self | ✅ YES |
| `create_upgrade_req_for_other` | 43 | Create upgrade request for others | ✅ YES |
| `edit_upgrade_req` | 16, 44 | Edit upgrade requests | ✅ YES |
| `delete_upgrade_req` | 17, 46 | Delete upgrade requests | ✅ YES |
| `approve_upgrade_req` | 11, 45 | Approve/decline upgrade requests | ✅ YES |

---

### 🎖️ MARSHAL PANEL (8 permissions)

| Permission | IDs | Description | Used In Code |
|------------|-----|-------------|--------------|
| `access_marshal_panel` | 62 | Access marshal-specific features | ✅ YES |
| `create_trip_report` | 63 | Create detailed trip reports | ✅ YES |
| `create_logbook_entries` | 64 | Create logbook entries | ✅ YES |
| `sign_logbook_skills` | 65 | Sign off on member skills | ✅ YES |
| `create_logbook_entries_superuser` | 66 | Create logbook entries (superuser) | ❌ NO |
| `override_waitlist` | 12, 25, 33 | Override trip waitlist restrictions | ❌ NO |
| `bypass_level_req` | 61 | Bypass level requirements | ❌ NO |

---

## 🎯 Quick Permission Lookup by Feature

### Registration Management
**Correct Permission:** `edit_trip_registrations`
- Registration Analytics screen
- Bulk Registration Actions screen
- Waitlist Management screen

**❌ DO NOT USE:** `manage_registrations` (does not exist)

### Trip Media Management
**Correct Permission:** `edit_trip_media`
- Trip Media moderation screen

**❌ DO NOT USE:** `moderate_gallery` (does not exist)

### Comment Moderation
**Correct Permission:** `delete_trip_comments`
- Comments moderation screen

**❌ DO NOT USE:** `moderate_comments` (does not exist)

### Meeting Points
**Correct Permissions:** 
- `create_meeting_points` (with 's')
- `edit_meeting_points` (with 's')
- `delete_meeting_points` (with 's')

**❌ DO NOT USE:** Singular forms without 's'

---

## 📝 Flutter Implementation Guidelines

### 1. Always Check User Object Has Permission

```dart
final user = ref.watch(authProviderV2).user;
final hasPermission = user?.hasPermission('exact_permission_name') ?? false;

if (hasPermission) {
  // Show feature
}
```

### 2. Use Exact Backend Names

```dart
// ✅ CORRECT
user?.hasPermission('edit_trip_registrations')
user?.hasPermission('edit_trip_media')
user?.hasPermission('delete_trip_comments')
user?.hasPermission('create_meeting_points')

// ❌ WRONG
user?.hasPermission('manage_registrations')
user?.hasPermission('moderate_gallery')
user?.hasPermission('moderate_comments')
user?.hasPermission('create_meeting_point')
```

### 3. Handle Missing Permissions Gracefully

```dart
if (!hasPermission) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(
          'Access Denied',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You need the "${requiredPermission}" permission',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

### 4. Use Helper Functions for Multiple Permissions

```dart
bool _hasTripPermissions(dynamic user) {
  return user.hasPermission('create_trip') ||
         user.hasPermission('create_trip_with_approval') ||
         user.hasPermission('edit_trips') ||
         user.hasPermission('delete_trips') ||
         user.hasPermission('approve_trip') ||
         user.hasPermission('edit_trip_registrations');
}

bool _hasContentModerationPermissions(dynamic user) {
  return user.hasPermission('edit_trip_media') ||
         user.hasPermission('delete_trip_comments');
}
```

---

## 🔍 How to Verify Permission Names

### Method 1: Check Backend API Response
```bash
curl -X GET "https://ap.ad4x4.com/api/auth/profile/" \
  -H "Authorization: Token YOUR_TOKEN" | jq '.permissions'
```

### Method 2: Check PERMISSIONS_REFERENCE.md
See `/home/user/flutter_app/PERMISSIONS_REFERENCE.md` for the complete list extracted from live API.

### Method 3: Debug Logging
Add debug logging to see all available permissions:

```dart
print('🔍 [Permission Debug] User: ${user.displayName}');
print('🔍 [Permission Debug] Total permissions: ${user.permissions.length}');
for (var perm in user.permissions) {
  print('🔍 [Permission Debug]   - ${perm.action}');
}
```

---

## ⚠️ Common Developer Mistakes

### Mistake 1: Using Frontend-Invented Names
**Problem:** Developer creates logical permission name without checking backend
**Example:** `manage_registrations`, `moderate_gallery`, `moderate_comments`
**Solution:** Always reference this document or backend API

### Mistake 2: Using Singular Forms
**Problem:** Developer uses singular form instead of plural
**Example:** `create_meeting_point` instead of `create_meeting_points`
**Solution:** Backend uses **PLURAL** forms for resources

### Mistake 3: Not Updating Documentation After Fixes
**Problem:** Old documentation shows wrong permission names
**Solution:** Update ALL documentation when permission names are corrected

### Mistake 4: Hardcoding Permission Checks
**Problem:** Permission names scattered across multiple files
**Solution:** Create helper functions and use constants

---

## 📚 Related Documentation

- **PERMISSIONS_REFERENCE.md** - Complete list of all 63 permissions from backend API
- **ADMIN_MENU_PERMISSIONS_AUDIT.md** - Menu structure with correct permission requirements
- **APP_WIDE_PERMISSION_FIXES.md** - History of permission fixes across the app
- **PERMISSION_AUDIT_REPORT.md** - Original permission audit findings

---

## 🔄 Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 2.0 | Fixed permission name mismatches after user bug report | Friday AI |
| 2025-11-11 | 1.0 | Initial document creation | Friday AI |

---

## 📞 Questions?

**When in doubt:**
1. Check this document first
2. Verify against live backend API
3. Check PERMISSIONS_REFERENCE.md
4. Add debug logging to see actual permission names

**DO NOT:**
- Guess permission names
- Use plural/singular forms inconsistently
- Create new permission names without backend confirmation

---

**✅ This document is the OFFICIAL reference for all permission names in the AD4x4 Flutter application.**
