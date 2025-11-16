# Backend Integration Guide

## 📖 For Backend Developers

This guide explains how the Flutter mobile app integrates with your backend APIs and what you need to know for successful collaboration.

---

## 🌐 API Configuration

### Production APIs

The Flutter app connects to two backend services:

```dart
// lib/core/config/api_config.dart
Main API (Django):    https://ap.ad4x4.com
Gallery API (Node.js): https://media.ad4x4.com
```

### Environment Configuration

API URLs are configurable via environment variables:

```bash
# Development environment
flutter run --dart-define=MAIN_API_BASE=https://dev-api.ad4x4.com

# Staging environment
flutter run --dart-define=MAIN_API_BASE=https://staging-api.ad4x4.com

# Production (default)
flutter run --dart-define=MAIN_API_BASE=https://ap.ad4x4.com
```

**Configuration file:** `lib/core/config/api_config.dart`

### API Client Settings

```dart
// Timeouts
Connect Timeout:  30 seconds
Receive Timeout:  30 seconds
Send Timeout:     30 seconds

// Retry Configuration
Max Retries:      3 attempts
Retry Delay:      2 seconds

// Upload Limits
Max Batch Size:   95 MB
Max Photo Size:   10 MB
```

---

## 🔗 API Integration Status

### ✅ Fully Integrated (25 screens using real API)

**Authentication:**
- Login, logout, password reset
- Profile management
- Session persistence with JWT tokens

**Trip Management:**
- List, create, update, delete trips
- Registration workflow (join, waitlist, check-in/out)
- Trip approval system (approve/decline)
- Trip comments/chat
- Export registrants (CSV/Excel/PDF)

**Logbook System:**
- Logbook entries and skills tracking
- Member trip history and counts
- Upgrade request system

**Admin Panel:**
- Member management
- Trip administration
- Logbook sign-off
- Meeting points management
- Feedback system

**See README.md for complete list of 134 API endpoints**

---

## 🔐 Authentication & Security

### JWT Bearer Token Authentication

The app uses JWT tokens for API authentication:

```dart
// Token storage: SharedPreferences
Headers: {
  'Authorization': 'Bearer <token>',
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}
```

**Token Management:**
- Tokens stored securely in SharedPreferences
- Auto-refresh on app restart
- Automatic logout on 401 responses
- Token included in all authenticated requests

**Auth Provider:** `lib/core/providers/auth_provider_v2.dart`

---

## 🛡️ Permission System

### String-Based Permissions (Not Level IDs!)

**CRITICAL:** The app uses **string-based permission checks**, not numeric level IDs.

### Implementation Example

```dart
// ✅ CORRECT - String-based permission check
if (user.hasPermission('can_approve_trips')) {
  // Show admin functionality
}

// ❌ WRONG - Don't use level IDs
if (user.level >= 8) {  // DON'T DO THIS
  // This breaks when backend changes level IDs
}
```

### Key Permissions Used in App

**Trip Management:**
- `can_approve_trips` - Approve/decline trips (Board)
- `can_manage_registrants` - Manage registrations (Marshal)
- `can_checkin_members` - Check-in/out members (Marshal)

**Member Management:**
- `can_view_members` - View member directory (Board)
- `can_edit_members` - Edit member profiles (Board)

**Content Management:**
- `can_manage_logbook` - Create logbook entries (Marshal)
- `can_manage_news` - Manage club news (Admin)
- `can_send_notifications` - Send notifications (Admin)

**Benefit:** You can modify level IDs on the backend without breaking the Flutter app!

**Documentation:** `/docs/MEMBER_LEVELS_AND_PERMISSIONS.md`

---

## 📊 API Response Format

### Expected Response Structure

**Success Response:**
```json
{
  "id": 123,
  "name": "Trip Name",
  "status": "approved",
  ...
}
```

**List Response (with pagination):**
```json
{
  "count": 50,
  "next": "https://api.ad4x4.com/api/trips/?page=2",
  "previous": null,
  "results": [...]
}
```

**Error Response:**
```json
{
  "detail": "Error message",
  "errors": {
    "field_name": ["Error description"]
  }
}
```

### Important API Conventions

**Django Trailing Slash Rules:**
```
✅ GET  /api/trips/         (list - HAS trailing slash)
✅ POST /api/trips          (create - NO trailing slash)
✅ GET  /api/trips/123/     (detail - HAS trailing slash)
✅ PUT  /api/trips/123      (update - NO trailing slash)
```

**See:** `lib/core/network/main_api_endpoints.dart` for all endpoint definitions

---

## 🔄 Data Models

### JSON Serialization

All data models use JSON serialization with `json_serializable`:

```dart
// Example: Trip model
class TripModel {
  final int id;
  final String name;
  final String status;
  
  factory TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);
  Map<String, dynamic> toJson() => _$TripModelToJson(this);
}
```

**Models location:** `lib/data/models/` (35 models)

### Field Naming Convention

**Backend (Python):** `snake_case`  
**Flutter (Dart):** `camelCase`

**JSON serialization handles conversion automatically:**

```dart
// Backend sends: "trip_name"
// Flutter uses: tripName

@JsonKey(name: 'trip_name')
final String tripName;
```

---

## 📂 Project Structure (Relevant for Backend Team)

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart          # API URLs and timeouts
│   ├── network/
│   │   ├── api_client.dart          # Dio HTTP client
│   │   ├── main_api_endpoints.dart  # All 134 endpoints defined
│   │   └── gallery_api_endpoints.dart
│   └── providers/
│       └── auth_provider_v2.dart    # Authentication state
│
├── data/
│   ├── models/                      # 35 JSON models
│   └── repositories/
│       ├── main_api_repository.dart # Main API calls
│       └── gallery_api_repository.dart
│
└── features/                        # 15 feature modules
    ├── auth/                        # Login, register, etc.
    ├── trips/                       # Trip management
    ├── admin/                       # Admin panel (58 files)
    └── ...
```

---

## 🧪 Testing with the App

### How to Test Backend Changes

1. **Point app to your dev environment:**
   ```bash
   flutter run --dart-define=MAIN_API_BASE=https://your-dev-api.com
   ```

2. **Check API logs:**
   - App has verbose logging enabled
   - Check Flutter console for request/response details
   - All API calls logged with timestamps

3. **Test authentication:**
   - Login screen is the entry point
   - Use test credentials to verify token flow
   - Check token in SharedPreferences

4. **Test permissions:**
   - Different user levels see different features
   - Permission checks happen client-side
   - Backend must return correct permissions array

### Debug Tools

**Debug Screen Available:**
- Location: `lib/features/debug/`
- Shows API status, cache, tokens
- Available in development builds

---

## 🚨 Common Integration Issues

### Issue 1: CORS Errors (Web Platform)

**Problem:** "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solution:** Backend must include CORS headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

### Issue 2: 401 Unauthorized

**Problem:** App constantly logging out

**Causes:**
- Token expired (backend not accepting token)
- Token format incorrect (should be `Bearer <token>`)
- Backend not returning valid token on login

### Issue 3: Permission Denied

**Problem:** Features not visible to users

**Causes:**
- Backend not returning permissions array in profile response
- Permission strings don't match app expectations
- Check: `GET /api/auth/profile/` returns `permissions: [...]`

### Issue 4: Trailing Slash Issues

**Problem:** 404 errors on some endpoints

**Solution:** Check Django's `APPEND_SLASH` setting and follow conventions in `main_api_endpoints.dart`

---

## 📝 API Documentation Files

Complete API specifications are in `/docs/`:

- `AD4X4_COMPONENT_API_MAPPING.md` - UI to API mapping
- `LOGBOOK_API_SPEC.md` - Logbook endpoints
- `WAITLIST_API_SPEC.md` - Waitlist system
- `TRIP_APPROVAL_WORKFLOW.md` - Trip approval flow
- `MEMBER_LEVELS_AND_PERMISSIONS.md` - Permission system
- `Backend_Integration_Instructions_for_Mikkle.md` - Original backend guide

---

## 🔄 Dynamic Choices System

The app fetches dropdown options from backend:

**Endpoints:**
- `/api/choices/approvalstatus`
- `/api/choices/carbrand`
- `/api/choices/countries`
- `/api/choices/emirates`
- `/api/choices/gender`
- `/api/choices/timeofday`
- `/api/choices/triprequestarea`
- `/api/choices/upgraderequeststatus`
- `/api/choices/upgraderequestvote`

**Expected Format:**
```json
[
  {"id": 1, "name": "Approved"},
  {"id": 2, "name": "Pending"},
  {"id": 3, "name": "Declined"}
]
```

---

## 📞 Contact & Support

**For Backend Integration Questions:**

1. Check this guide first
2. Review README.md for API endpoints
3. Check `/docs/` for detailed specifications
4. Review code in `lib/core/network/` for endpoint definitions

**Project Contact:**
- Abu Dhabi Off-Road Club
- Project Owner: Hani (Sales Manager at Eastern Motors)

---

## ✅ Integration Checklist

Before going live, verify:

- [ ] All API endpoints return correct JSON format
- [ ] CORS headers configured for web platform
- [ ] JWT authentication working correctly
- [ ] Permissions array returned in profile endpoint
- [ ] Permission strings match app expectations
- [ ] Trailing slashes follow Django conventions
- [ ] Error responses include meaningful messages
- [ ] File upload endpoints accept multipart/form-data
- [ ] Pagination works for list endpoints
- [ ] Dynamic choices endpoints return id/name format

---

**Last Updated:** November 2024  
**Flutter Version:** 3.35.4  
**Dart Version:** 3.9.2
