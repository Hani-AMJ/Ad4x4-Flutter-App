# AD4x4 Mobile App

Abu Dhabi Off-Road Club official mobile application built with Flutter.

## 🎯 Project Status

**Current Implementation:** Phases 1-2 Complete, Phases 3-4 Partial

**✅ Production Ready:**
- Authentication system with JWT
- User profiles and settings
- Trip list and detail views
- Trip chat functionality
- Permission-based access control ✅ **FIXED Nov 11, 2025** (see CORRECT_PERMISSIONS_REFERENCE.md)

**🔄 In Progress:**
- Phase 3-4: Additional features (gallery, events, logbook)
- Admin tool integration (marshal features)

**📚 Important Documentation:**
- **CORRECT_PERMISSIONS_REFERENCE.md** - Official permission names reference (CRITICAL for development)
- **PERMISSION_FIX_SUMMARY.md** - History of permission name mismatch fix
- **ADMIN_MENU_PERMISSIONS_AUDIT.md** - Complete admin panel permission audit

---

## 📖 Development Timeline (Chronological)

### Phase 1: Foundation & Core Infrastructure ✅ **95% COMPLETE**

**Completed Components:**
- ✅ Project setup (Flutter 3.35.4, Dart 3.9.2, Java 17.0.2)
- ✅ Brand identity system (`brand_tokens.json`, dynamic theming with Material Design 3)
- ✅ Network layer (Dio HTTP client with interceptors for auth/errors)
- ✅ API client architecture (Main API + Gallery API separation)
- ✅ Routing system (GoRouter with authentication guards and redirects)
- ✅ Local storage (Hive + SharedPreferences for tokens and cache)
- ✅ Shared component library (15 widgets: buttons, cards, inputs, states)
- ✅ Error handling framework (error states, loading indicators, empty states)

**File Evidence:**
- `/lib/core/config/brand_tokens.dart` - Brand configuration
- `/lib/core/network/api_client.dart` (251 lines) - HTTP client
- `/lib/core/router/app_router.dart` - Routing with auth guards
- `/lib/core/storage/local_storage.dart` - Hive initialization
- `/lib/shared/widgets/` - 15 reusable components

**Missing:** Centralized app constants file (minor)

---

### Phase 2: Authentication & User Profile ✅ **100% COMPLETE**

**Completed Components:**
- ✅ Login screen with real API integration (`/api/auth/login/`)
- ✅ Registration screen with validation
- ✅ Forgot password screen with reset flow
- ✅ JWT authentication with bearer tokens
- ✅ Token storage in local storage (SharedPreferences)
- ✅ Session persistence (auto-login on app restart)
- ✅ User profile screen displaying real API data
- ✅ Edit profile screen with API updates
- ✅ Settings screen with logout functionality
- ✅ Router authentication guards (protected routes)

**File Evidence:**
- `/lib/features/auth/presentation/screens/login_screen.dart` (7708 bytes)
- `/lib/features/auth/presentation/screens/register_screen.dart` (8562 bytes)
- `/lib/features/auth/presentation/screens/forgot_password_screen.dart` (6433 bytes)
- `/lib/features/profile/presentation/screens/profile_screen.dart` - Real user data
- `/lib/core/providers/auth_provider_v2.dart` - Riverpod authentication state

**API Integration:**
- POST `/api/auth/login/` - User authentication
- GET `/api/auth/profile/` - User profile data
- POST `/api/auth/change-password/` - Password updates
- POST `/api/auth/send-reset-password-link/` - Password reset

**Notes:**
- Splash screen not implemented (router initializes at `/login`)
- Session automatically restored on app refresh
- Permission system fully integrated (string-based, not level IDs)

---

### Phase 3: Home Screen & Dashboard ⚠️ **80% COMPLETE**

**Completed Components:**
- ✅ Home screen layout with app bar and navigation
- ✅ Welcome section with club branding
- ✅ Quick actions grid (5 action cards: Trips, Events, Gallery, Members, Trip Requests)
- ✅ Recent activity feed (static examples)
- ✅ Bottom navigation bar (Home, Trips, Gallery, Profile)

**File Evidence:**
- `/lib/features/home/presentation/screens/home_screen.dart` (8162 bytes)

**Missing from Master Plan:**
- ❌ Upcoming trips carousel (dynamic data from API)
- ❌ Member upgrade progress widget (level progression tracking)
- ❌ Gallery spotlight widget (featured photos)

**Notes:**
- Current home screen uses simplified layout
- Activity feed shows static examples, not real data
- Quick actions navigate to feature screens

---

### Phase 4: Trips Discovery & Management ⚠️ **60% COMPLETE**

**Completed Components:**
- ✅ Trip list screen with real API integration (`/api/trips/`)
- ✅ Trip filters bar (difficulty levels, dates, status)
- ✅ Trip detail screen with rich UI (images, description, participants)
- ✅ Trip chat screen with real-time comments (`/api/trips/{id}/comments`)
- ✅ Trip registration actions (join, waitlist) - API integrated
- ✅ Trip requests screen (member trip creation requests)
- ✅ Manage registrants screen (marshal admin tool)
- ⚠️ Trip admin ribbon (UI exists, needs full integration)

**File Evidence:**
- `/lib/features/trips/presentation/screens/trips_list_screen.dart` (17391 bytes)
- `/lib/features/trips/presentation/screens/trip_details_screen.dart` (43988 bytes)
- `/lib/features/trips/presentation/screens/trip_chat_screen.dart` (24333 bytes)
- `/lib/features/trips/presentation/screens/trip_requests_screen.dart` (30510 bytes)
- `/lib/features/trips/presentation/screens/manage_registrants_screen.dart` (12930 bytes)
- `/lib/shared/widgets/admin/trip_admin_ribbon.dart` - Admin controls

**Not Implemented:**
- ❌ Trip creation screen (placeholder only - 20 lines)
- ❌ Trip editing functionality

**API Integration (Working):**
- GET `/api/trips/` - List trips with filters
- GET `/api/trips/{id}/` - Trip details
- POST `/api/trips/{id}/register` - Join trip
- POST `/api/trips/{id}/waitlist` - Join waitlist
- GET `/api/trips/{id}/comments` - Trip chat messages
- POST `/api/tripcomments/` - Post chat message

**API Defined (Not UI Implemented):**
- POST `/api/trips/` - Create trip
- PATCH `/api/trips/{id}/` - Update trip
- POST `/api/trips/{id}/approve` - Approve pending trip
- POST `/api/trips/{id}/decline` - Decline pending trip
- POST `/api/trips/{id}/checkin` - Check-in member
- POST `/api/trips/{id}/checkout` - Check-out member

**Notes:**
- Trip list and details fully functional with real data
- Create trip screen is placeholder (says "Under Development")
- Admin features have UI but need backend workflow integration

---

### Phase 5: Gallery & Photo Management 🔄 **40% COMPLETE** (Mock Data)

**Completed Components:**
- ⚠️ Gallery discover screen (UI complete, using sample data)
- ⚠️ Album screen (UI complete, using sample data)

**File Evidence:**
- `/lib/features/gallery/presentation/screens/gallery_screen.dart` (7927 bytes)
- `/lib/features/gallery/presentation/screens/album_screen.dart` (10868 bytes)
- `/lib/data/sample_data/sample_gallery.dart` - Mock data source

**Not Implemented:**
- ❌ Photo upload screen
- ❌ Full-screen photo viewer
- ❌ Gallery API integration

**API Status:**
- ✅ Gallery API repository exists (`gallery_api_repository.dart` - 134 lines)
- ✅ Gallery API endpoints defined (`https://gallery-api.ad4x4.com`)
- ❌ Screens still using `SampleGallery.getAlbums()` instead of API

**Notes:**
- Screens show orange banner: "🔄 Using Mock Data - Gallery API Integration Pending"
- Backend gallery API exists and is documented
- Integration pending (Phase 3B work)

---

### Phase 6: Digital Logbook ❌ **NOT STARTED**

**Status:**
- ❌ Logbook timeline screen (not implemented)
- ❌ Skills matrix screen (not implemented)
- ❌ Marshal logbook tool (not implemented)

**API Status:**
- ✅ All logbook endpoints are defined and documented:
  - GET `/api/logbookentries/` - List logbook entries
  - GET `/api/logbookskills/` - Available skills
  - GET `/api/logbookskillreferences` - Skill reference materials
  - GET `/api/members/{id}/logbookskills` - Member skill timeline
  - GET `/api/members/{id}/triphistory` - Trip history with logbook context
  - GET `/api/members/{id}/tripcounts` - Level progression tracking
  - POST `/api/trips/{id}/logbook-entries` - Marshal sign-off (Admin Tool)

**File Evidence:**
- `/lib/features/logbook/` - Empty directory (data/, domain/, presentation/ folders exist but no Dart files)
- `/lib/core/network/main_api_endpoints.dart` - Lines 55-59 (endpoints defined)
- `/home/user/docs/LOGBOOK_API_SPEC.md` - Complete API documentation

**Notes:**
- Directory structure created but no implementation
- API documentation complete (see LOGBOOK_API_SPEC.md)
- Marshal logbook tool planned for Admin Tool Phase 2
- Estimated 3-4 weeks implementation (UI + API integration)

---

### Phase 7: Notifications & Search 🔄 **50% COMPLETE** (Mock Data)

**Completed Components:**
- ⚠️ Notifications screen (UI complete, using sample data)
- ⚠️ Global search screen (UI complete, using sample data)

**File Evidence:**
- `/lib/features/notifications/presentation/screens/notifications_screen.dart` (10980 bytes)
- `/lib/features/search/presentation/screens/global_search_screen.dart` (14327 bytes)
- `/lib/data/sample_data/sample_notifications.dart` - Mock data

**Not Implemented:**
- ❌ Firebase Cloud Messaging (FCM) integration
- ❌ Push notifications
- ❌ Real-time notification updates
- ❌ Search API integration

**API Status:**
- ✅ Notification endpoints defined (`/api/notifications/`)
- ✅ Device registration endpoints defined (`/api/device/fcm/`, `/api/device/apns/`)
- ❌ Firebase packages commented out in `pubspec.yaml`

**Notes:**
- Notification screen has mark-as-read functionality (UI only)
- Search screen has tab-based filtering (All/Trips/Members/Photos/News)
- FCM integration requires Firebase configuration

---

### Phase 8: Polish, Testing & Optimization ⚠️ **IN PLANNING**

**Status:**
- Admin tool architecture documented (7 planning documents)
- Validation test plan created
- Performance optimization pending
- Comprehensive testing pending

**Documentation:**
- `/home/user/flutter_app/ADMIN_TOOL_START_HERE.md`
- `/home/user/flutter_app/VALIDATION_TEST_PLAN.md`
- `/home/user/flutter_app/ADMIN_ARCHITECTURE_DIAGRAM.md`

---

### Phase 9: Android APK Build & Deployment 📝 **PLANNED**

**Status:**
- Android configuration exists (`/android/` directory)
- Build tooling ready (Gradle, Java 17)
- APK compilation workflow pending
- Deployment strategy pending

---

## 📊 Implementation Statistics

### Codebase Metrics:
```
Total Dart Files: 80
- Core Infrastructure: 17 files (network, routing, providers)
- Shared Widgets: 15 files (buttons, cards, inputs, states)
- Feature Modules: 48 files (13 feature folders)

Feature Implementation:
- Auth: 3 screens ✅ Real API
- Trips: 7 screens ⚠️ 6 working, 1 placeholder
- Gallery: 2 screens 🔄 Mock data
- Profile: 2 screens ✅ Real API
- Events: 2 screens 🔄 Mock data
- Notifications: 1 screen 🔄 Mock data
- Search: 1 screen 🔄 Mock data
- Members: 2 screens 🔄 Mock data
- Vehicles: 2 screens 🔄 Stub/Mock
- Settings: 1 screen ✅ Working
- Logbook: 0 files ❌ Not started
- Debug: 1 screen (Dev tool)

API Integration:
- Repository Files: 2 (main_api + gallery_api)
- Network Layer: 6 files (1,134 lines total)
- Endpoints Defined: ~40 endpoints
- Endpoints Integrated: ~15 endpoints (auth + trips + chat)
- Endpoints Pending: ~25 endpoints (gallery, events, members, notifications, logbook)
```

### Real API vs Mock Data:
```
✅ Real API Integration:
- Authentication (login, profile, logout, password reset)
- Trip list and filtering
- Trip details and registration
- Trip chat (comments)
- Trip requests

🔄 Mock Data (Pending Integration):
- Gallery albums and photos
- Events list and details
- Members list and profiles
- Notifications
- Global search
- Vehicles

❌ Not Implemented:
- Trip creation/editing
- Digital logbook (timeline, skills)
- Push notifications (FCM)
- Photo upload
- Marshal admin tools (logbook sign-off)
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.35.4 (locked version)
- Dart 3.9.2 (locked version)
- Java 17.0.2 (for Android builds)

### Installation
```bash
# Clone repository
git clone <repository-url>
cd flutter_app

# Install dependencies
flutter pub get

# Run on web (recommended for development)
flutter run -d chrome --web-port=5060
```

### Test Credentials
- Username: `Hani amj`
- Password: `3213Plugin?`

---

## 🏗️ Architecture

### Technology Stack
- **Framework:** Flutter 3.35.4
- **State Management:** Riverpod 2.5.1
- **Routing:** GoRouter 13.2.0 with auth guards
- **API Client:** Dio 5.4.0 with interceptors
- **Local Storage:** Hive 2.2.3 + SharedPreferences 2.2.2
- **Authentication:** JWT Bearer tokens
- **Image Caching:** CachedNetworkImage 3.3.1
- **UI Animation:** Flutter Animate 4.5.0

### Project Structure
```
lib/
├── core/                       # Core functionality
│   ├── config/                 # App configuration, brand tokens
│   ├── network/                # API clients & endpoints
│   ├── providers/              # Riverpod providers (auth, repos)
│   ├── router/                 # GoRouter configuration
│   ├── services/               # Business services
│   ├── storage/                # Local storage (Hive)
│   └── utils/                  # Utility functions
├── data/                       # Data layer
│   ├── models/                 # Data models (10 models)
│   ├── repositories/           # API repositories (2 repos)
│   └── sample_data/            # Mock data (7 files - Phase 3B will remove)
├── features/                   # Feature modules (13 features)
│   ├── auth/                   # Authentication (3 screens) ✅
│   ├── trips/                  # Trip management (7 screens) ⚠️
│   ├── events/                 # Events (2 screens) 🔄
│   ├── gallery/                # Photo gallery (2 screens) 🔄
│   ├── logbook/                # Digital logbook (0 files) ❌
│   ├── members/                # Club members (2 screens) 🔄
│   ├── notifications/          # Notifications (1 screen) 🔄
│   ├── profile/                # User profile (2 screens) ✅
│   ├── search/                 # Global search (1 screen) 🔄
│   ├── settings/               # App settings (1 screen) ✅
│   └── vehicles/               # Vehicle management (2 screens) 🔄
└── shared/                     # Shared widgets & theme
    ├── theme/                  # App theme (Material Design 3)
    └── widgets/                # Reusable widgets (15 components)
```

---

## 🔗 API Endpoints

### Production APIs
- **Main API (Django):** https://ap.ad4x4.com
- **Gallery API (Node.js):** https://gallery-api.ad4x4.com

### Endpoint Summary
```
Authentication (✅ Integrated):
  POST   /api/auth/login/
  GET    /api/auth/profile/
  POST   /api/auth/change-password/
  POST   /api/auth/send-reset-password-link/

Trips (✅ Integrated):
  GET    /api/trips/                    # List with filters
  GET    /api/trips/{id}/               # Trip details
  POST   /api/trips/{id}/register       # Register for trip
  POST   /api/trips/{id}/waitlist       # Join waitlist
  GET    /api/trips/{id}/comments       # Trip chat
  POST   /api/tripcomments/             # Post chat message

Trips (📝 Defined, Not Integrated):
  POST   /api/trips/                    # Create trip
  PATCH  /api/trips/{id}/               # Update trip
  POST   /api/trips/{id}/approve        # Approve trip (admin)
  POST   /api/trips/{id}/decline        # Decline trip (admin)
  POST   /api/trips/{id}/checkin        # Check-in member (marshal)

Logbook (📝 Defined, Not Implemented):
  GET    /api/logbookentries/
  GET    /api/logbookskills/
  GET    /api/logbookskillreferences
  GET    /api/members/{id}/logbookskills
  POST   /api/trips/{id}/logbook-entries  # Marshal sign-off

Members (📝 Defined, Not Integrated):
  GET    /api/members/                  # List members
  GET    /api/members/{id}/             # Member details
  GET    /api/members/{id}/triphistory  # Trip history

Gallery (📝 Defined, Not Integrated):
  GET    /api/galleries                 # List albums
  GET    /api/galleries/{id}            # Album details
  GET    /api/photos/gallery/{id}       # Photos in album

Notifications (📝 Defined, Not Integrated):
  GET    /api/notifications/
  POST   /api/device/fcm/               # Register FCM token
```

**Complete API Documentation:**
- `/home/user/docs/AD4X4_COMPONENT_API_MAPPING.md` - UI-to-API mapping
- `/home/user/docs/LOGBOOK_API_SPEC.md` - Logbook endpoints
- `/home/user/docs/WAITLIST_API_SPEC.md` - Waitlist endpoints
- `/home/user/docs/TRIP_APPROVAL_WORKFLOW.md` - Trip approval system
- `ADMIN_TOOL_DETAILED_PLAN.md` - Admin endpoints analysis

---

## 🔐 Permission System

The app uses a **permission-based access control** system that checks action strings, not numeric level IDs.

### Implementation:
```dart
// Check user permissions
if (user.hasPermission('can_approve_trips')) {
  showAdminButton();
}
```

### Key Permissions:
```dart
// Trip Management
'can_view_all_trips'
'can_approve_trips'       // Board level
'can_manage_registrants'  // Marshal level
'can_checkin_members'     // Marshal level

// Member Management
'can_view_members'        // Board level
'can_edit_members'        // Board level

// Content Management
'can_manage_news'
'can_send_notifications'

// Logbook Management
'can_manage_logbook'      // Marshal level
```

**Key Benefit:** Backend can change level IDs freely without breaking the app.

**Documentation:** `/home/user/docs/MEMBER_LEVELS_AND_PERMISSIONS.md`

---

## 📚 Documentation

### 📖 Start Here
1. **This README** - Project overview and phase status
2. **PHASE_3A_COMPLETE.md** - Current implementation details
3. **DOCUMENTATION_AUDIT.md** - Documentation organization guide

### 🎯 Planning Documents
- **ADMIN_TOOL_START_HERE.md** - Admin tool planning overview
- **ADMIN_TOOL_EXECUTIVE_SUMMARY.md** - Admin tool roadmap (4-week plan)
- **REMAINING_FEATURES_IMPACT_ANALYSIS.md** - Feature integration analysis
- **VALIDATION_TEST_PLAN.md** - Comprehensive testing checklist

### 🛠️ Implementation Guides
- **ADMIN_IMPLEMENTATION_CHANGES.md** - Code changes for admin tool
- **ADMIN_TOOL_DETAILED_PLAN.md** - Complete API endpoint analysis
- **ADMIN_TOOL_QUICK_REFERENCE.md** - Developer API reference

### 🏗️ Architecture & API Specs
- **ADMIN_ARCHITECTURE_DIAGRAM.md** - Visual system architecture
- **AD4X4_COMPONENT_API_MAPPING.md** (in `/docs/`) - UI-to-API traceability
- **LOGBOOK_API_SPEC.md** (in `/docs/`) - Digital logbook endpoints
- **WAITLIST_API_SPEC.md** (in `/docs/`) - Trip waitlist system
- **TRIP_APPROVAL_WORKFLOW.md** (in `/docs/`) - Trip approval flow

### 📋 Master Plan Reference
- **AD4X4_DEVELOPMENT_MASTER_PLAN.md** (in `/docs/`) - Original 9-phase plan

---

## 📱 Platforms

### Current Status
- ✅ **Web:** Deployed and tested
- ✅ **Android APK:** Ready for build
- ⏸️ **iOS:** Pending (future phase)

### Web Preview
- Development: `flutter run -d chrome --web-port=5060`
- Production: Deployed to sandbox environment

---

## 🧪 Testing

### Manual Testing
See **VALIDATION_TEST_PLAN.md** for comprehensive test checklist.

### Test Coverage
- ✅ Authentication flow (login, logout, session persistence)
- ✅ Protected routes and auth guards
- ✅ Trip list loading and filtering
- ✅ Trip details display
- ✅ Trip chat functionality
- ✅ Profile data display and editing
- ⏸️ Gallery API integration (Phase 3B)
- ⏸️ Events API integration (Phase 3B)
- ⏸️ Admin actions (Phase 4)
- ⏸️ Digital logbook (Phase 6)

---

## 🚧 Current Limitations

### Phase 1-2 (Complete):
- ✅ No limitations - foundation and auth fully functional

### Phase 3-4 (Partial):
- ⚠️ Trip creation screen is placeholder (just shows "Under Development")
- ⚠️ Trip editing not implemented
- ⚠️ Admin ribbon UI exists but needs backend workflow integration

### Phase 5-7 (Mock Data):
- ⚠️ Gallery shows sample data (screens show orange banner)
- ⚠️ Events show sample data
- ⚠️ Members list shows sample data
- ⚠️ Notifications show sample data
- ⚠️ Search uses mock data
- ⚠️ No photo upload functionality

### Phase 6 (Not Started):
- ❌ Digital logbook completely missing (directory structure only)
- ❌ Marshal logbook tool not implemented

### Phase 7-9:
- ❌ FCM push notifications not configured
- ❌ Polish and optimization pending
- ❌ APK build workflow pending

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Implement changes following code standards
3. Test thoroughly (see VALIDATION_TEST_PLAN.md)
4. Submit pull request

### Code Standards
- Follow Flutter/Dart conventions
- Use Riverpod for state management
- Implement proper error handling with try-catch
- Add loading states for async operations
- Use permission checks for admin features (`user.hasPermission('action')`)
- Add mock data banners for unintegrated features

---

## 📝 Version History

### Phase 1-2 (Complete - November 2024) ✅
- Foundation infrastructure (network, routing, storage, theme)
- Authentication system (login, register, profile, session)
- Permission-based access control
- Router auth guards

### Phase 3-4 (Partial - November 2024) ⚠️
- Home screen with basic layout
- Trip list and details (real API)
- Trip chat (real API)
- Trip requests and management screens
- Admin ribbon UI (partial integration)

### Phase 5-7 (UI Only - November 2024) 🔄
- Gallery screens (mock data)
- Events screens (mock data)
- Notifications screen (mock data)
- Search screen (mock data)
- Members screens (mock data)

### Phase 6 (Not Started) ❌
- Digital logbook (API documented, UI not implemented)

### Next: Phase 3B-4 API Integration (Planned)
- Remove all mock data
- Integrate gallery, events, members, notifications APIs
- Implement trip creation
- Complete admin tool integration

---

## 📞 Support

For questions or issues:
1. Check this README for phase status
2. Review `/home/user/docs/` for API specifications
3. See project planning documents in `/home/user/flutter_app/`

---

**Project maintained by AD4x4 Development Team**  
**Last updated:** November 2024  
**Flutter Version:** 3.35.4 (locked)  
**Dart Version:** 3.9.2 (locked)
