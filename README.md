# AD4x4 Mobile App

> ⚠️ **WORK IN PROGRESS** - This project is under active development. Not all features are fully tested and some are still being refined.

**Abu Dhabi Off-Road Club** official mobile application built with Flutter.

---

## 📊 Project Overview

**Technology Stack:**
- Flutter 3.35.4 (Dart 3.9.2)
- State Management: Riverpod 2.5.1
- Routing: GoRouter 13.2.0
- API Client: Dio 5.4.0 + Retrofit
- Local Storage: Hive 2.2.3 + SharedPreferences 2.2.2

**Codebase:**
- **214 Dart files** | **78,110 lines of code**
- **71 screens** across 15 feature modules
- **35 data models** with JSON serialization
- **58 admin panel components**

---

## 📌 Project Status & Quick Links

**Current Version:** 1.5.2 (November 2024)  
**Next Release:** v2.0 - Gallery Integration (Target: December 2024)

### 🔗 Essential Links
- **📋 Task Board:** [GitHub Issues](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues)
- **📊 Projects Board:** [GitHub Projects](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/projects)
- **📝 Todo List:** [TODO.md](TODO.md) - Quick reference of all planned work
- **📅 Changelog:** [CHANGELOG.md](CHANGELOG.md) - Release history and updates
- **🆕 New Features:** [/new_features/](new_features/) - Feature specifications and docs

### 🚀 Active Development

#### 🎨 Gallery Integration (In Progress)
**Status:** Documentation complete, ready for implementation  
**Timeline:** 17-25 hours (Backend: 6-8h, Flutter: 12-16h)  
**Docs:** [/new_features/gallery_integration/](new_features/gallery_integration/)

**Backend Tasks:** 
- Add `gallery_id` field to Trip model
- Implement Gallery API webhook integration
- Update trip responses with gallery data

**Flutter Tasks:**
- Gallery admin tab in trip details
- Upload photos from trip page  
- User's personal gallery view

#### ⭐ Trip Rating System (Planned)
**Status:** Planning phase  
**Docs:** [/new_features/trip_rating_msi_system/](new_features/trip_rating_msi_system/)

---

## 🎯 Implementation Status

### ✅ **Fully Implemented Features**

#### 1. **Authentication & Authorization**
- Login with JWT bearer tokens
- User registration with validation
- Password reset flow
- Session persistence with auto-login
- Permission-based access control (string-based, not level IDs)
- Profile management (view, edit)

**Files:** `lib/features/auth/` (3 screens)

---

#### 2. **Trip Management System**
- Trip discovery and listing with filters
- Detailed trip views with rich media
- Trip registration (join, waitlist, check-in/out)
- Trip creation wizard with step-by-step flow
- Trip editing and updates
- Trip comments/chat functionality
- Trip export (CSV, Excel, PDF)
- Trip area filtering and search

**Files:** `lib/features/trips/` (6 screens, 14 files)

**API Integration:** ✅ Complete
- List, create, update, delete trips
- Registration management
- Approval workflows
- Check-in/checkout system
- Comments/chat

---

#### 3. **Digital Logbook System**
- Logbook timeline view
- Skills matrix tracking
- Trip history with logbook context
- Logbook entry details
- Member upgrade request system
- Create and manage upgrade requests

**Files:** `lib/features/logbook/` (7 screens)

**API Integration:** ✅ Complete
- Logbook entries, skills, references
- Member skill tracking
- Trip history and counts

---

#### 4. **Admin Panel & Marshal Tools**
Comprehensive administrative dashboard with 29 screens covering:

**Trip Administration:**
- All trips management
- Pending trip approvals
- Trip search and filtering
- Registrant management
- Waitlist management
- Bulk registrations
- Registration analytics

**Member Management:**
- Member list and search
- Member profile editing
- Member details and history

**Logbook Administration:**
- Logbook entries management
- Skills sign-off interface
- Create logbook entries for members
- Upgrade request review and approval

**Content Management:**
- Trip reports moderation
- Comments moderation
- Feedback management
- Meeting points management

**Trip Request System:**
- Member trip request reviews
- Trip creation wizard
- Trip request analytics

**Files:** `lib/features/admin/` (29 screens, 58 files total)

---

#### 5. **Gallery System**
- Photo gallery discover view
- Album browsing
- Photo search
- Trip-based photo albums
- Photo upload (admin)

**Files:** `lib/features/gallery/` (5 screens)

**API Integration:** ✅ Gallery API connected

---

#### 6. **Member Directory**
- Member list and search
- Member profile views
- Member statistics

**Files:** `lib/features/members/` (2 screens)

---

#### 7. **Events & Activities**
- Event calendar
- Event details and registration
- Event participation tracking

**Files:** `lib/features/events/` (2 screens)

---

#### 8. **Vehicle Management**
- Vehicle profiles
- Vehicle modifications tracking
- Verification system

**Files:** `lib/features/vehicles/` (3 screens)

---

#### 9. **Meeting Points System**
- Meeting point locations
- Map integration (flutter_map)
- Meeting point details
- Admin: Create/edit meeting points

**Files:** `lib/features/meeting_points/` (2 screens)

---

#### 10. **Notifications**
- In-app notification center
- Notification history
- Mark as read functionality
- Notification action handling

**Files:** `lib/features/notifications/` (1 screen)

**Note:** Firebase Cloud Messaging (FCM) integration pending

---

#### 11. **Global Search**
- Unified search across trips, members, photos
- Tab-based filtering
- Search history

**Files:** `lib/features/search/` (1 screen)

---

#### 12. **Settings & Support**
- App settings management
- Help & Support
- Privacy Policy
- Terms & Conditions

**Files:** `lib/features/settings/` (4 screens)

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/                          # Core infrastructure (33 files)
│   ├── config/                    # API config, brand tokens
│   ├── network/                   # Dio client, endpoints, interceptors
│   ├── providers/                 # Riverpod providers (11 providers)
│   ├── router/                    # GoRouter with auth guards
│   ├── services/                  # Business services (5 services)
│   ├── storage/                   # Hive + SharedPreferences
│   └── utils/                     # Utility functions (6 utilities)
│
├── data/                          # Data layer (43 files)
│   ├── models/                    # 35 data models with JSON serialization
│   ├── repositories/              # API repositories (Main + Gallery)
│   └── sample_data/               # Reference data (levels, sample data)
│
├── features/                      # 15 feature modules (135 files)
│   ├── admin/                     # Admin panel (58 files)
│   ├── auth/                      # Authentication (3 screens)
│   ├── debug/                     # Debug tools (2 screens)
│   ├── events/                    # Events (2 screens)
│   ├── gallery/                   # Photo gallery (6 files)
│   ├── home/                      # Home dashboard (1 screen)
│   ├── logbook/                   # Digital logbook (7 screens)
│   ├── meeting_points/            # Meeting points (2 screens)
│   ├── members/                   # Member directory (2 screens)
│   ├── notifications/             # Notifications (1 screen)
│   ├── profile/                   # User profile (2 screens)
│   ├── search/                    # Global search (1 screen)
│   ├── settings/                  # Settings (4 screens)
│   ├── splash/                    # Splash screen (1 screen)
│   ├── trips/                     # Trip management (14 files)
│   └── vehicles/                  # Vehicle management (3 screens)
│
└── shared/                        # Shared components (29 files)
    ├── constants/                 # Level constants
    ├── theme/                     # Material Design 3 theme
    └── widgets/                   # 28 reusable widgets
        ├── admin/                 # Admin-specific widgets
        ├── badges/                # Badge components
        ├── buttons/               # Button variants
        ├── cards/                 # Card components
        ├── common/                # Common widgets (8 files)
        ├── dialogs/               # Dialog components
        ├── error/                 # Error states
        ├── filters/               # Filter components
        ├── home/                  # Home widgets
        ├── inputs/                # Input fields
        └── loading/               # Loading indicators
```

---

## 🔗 API Integration

### Production APIs
- **Main API (Django):** `https://ap.ad4x4.com`
- **Gallery API (Node.js):** `https://media.ad4x4.com`

### API Endpoints (134 endpoints defined)

**Authentication:**
- POST `/api/auth/login/`
- GET `/api/auth/profile/`
- POST `/api/auth/change-password/`
- POST `/api/auth/send-reset-password-link/`
- POST `/api/auth/reset-password/`

**Trips (20 endpoints):**
- GET `/api/trips/` - List trips
- POST `/api/trips` - Create trip
- GET `/api/trips/{id}/` - Trip details
- PUT `/api/trips/{id}` - Update trip
- POST `/api/trips/{id}/register` - Register for trip
- POST `/api/trips/{id}/unregister` - Cancel registration
- POST `/api/trips/{id}/waitlist` - Join waitlist
- POST `/api/trips/{id}/approve` - Approve trip (admin)
- POST `/api/trips/{id}/decline` - Decline trip (admin)
- POST `/api/trips/{id}/forceregister` - Force register (admin)
- POST `/api/trips/{id}/removemember` - Remove member (admin)
- POST `/api/trips/{id}/addfromwaitlist` - Add from waitlist (admin)
- POST `/api/trips/{id}/checkin` - Check-in member
- POST `/api/trips/{id}/checkout` - Check-out member
- GET `/api/trips/{id}/exportregistrants` - Export registrants (CSV/Excel/PDF)
- POST `/api/trips/{id}/bind-gallery` - Bind gallery album
- GET `/api/trips/{id}/comments` - Trip chat
- POST `/api/tripcomments/` - Post comment

**Trip Requests:**
- GET `/api/triprequests/` - List trip requests
- POST `/api/triprequests/` - Create trip request
- GET/PATCH `/api/triprequests/{id}/` - Update/view request

**Logbook (8 endpoints):**
- GET `/api/logbookentries/`
- GET `/api/logbookskills/`
- GET `/api/logbookskillreferences`
- GET `/api/members/{id}/logbookentries`
- GET `/api/members/{id}/logbookskills`
- GET `/api/members/{id}/tripcounts`
- GET `/api/members/{id}/triphistory`

**Members (8 endpoints):**
- GET `/api/members/`
- GET `/api/members/{id}/`
- GET `/api/members/{id}/feedback`
- GET `/api/members/{id}/triprequests`
- GET `/api/members/{id}/upgraderequests`
- GET `/api/members/{id}/payments`

**Upgrade Requests (5 endpoints):**
- GET `/api/upgraderequests/`
- POST `/api/upgraderequests/`
- GET `/api/upgraderequests/{id}/`
- POST `/api/upgraderequests/{id}/vote`
- POST `/api/upgraderequests/{id}/approve`
- POST `/api/upgraderequests/{id}/decline`
- POST `/api/upgraderequestcomments/`
- DELETE `/api/upgraderequestcomments/{id}/`

**Meeting Points:**
- GET `/api/meetingpoints/`
- GET/POST/PUT/DELETE `/api/meetingpoints/{id}/`

**Feedback:**
- GET `/api/feedback/` - List feedback (admin)
- POST `/api/feedback/` - Submit feedback
- GET/PATCH `/api/feedback/{id}/` - View/update feedback

**Trip Reports:**
- GET `/api/tripreports/`
- GET/PATCH `/api/tripreports/{id}/`

**Dynamic Choices (11 endpoints):**
- `/api/choices/approvalstatus`
- `/api/choices/carbrand`
- `/api/choices/countries`
- `/api/choices/emirates`
- `/api/choices/gender`
- `/api/choices/permissionmatrixaction`
- `/api/choices/timeofday`
- `/api/choices/triprequestarea`
- `/api/choices/upgraderequeststatus`
- `/api/choices/upgraderequestvote`

**Other:**
- GET `/api/levels/` - Member levels
- GET `/api/clubnews/` - Club news
- GET `/api/sponsors/` - Sponsors
- GET `/api/faqs/` - FAQs
- GET `/api/globalsettings/` - Global settings
- GET `/api/groups/` - Groups
- GET `/api/permissionmatrix/` - Permission matrix
- GET `/api/notifications/` - Notifications
- POST `/api/device/fcm/` - Register FCM token
- POST `/api/device/apns/` - Register APNS token

**Gallery API:**
- GET `/api/galleries` - List albums
- GET `/api/galleries/{id}` - Album details
- GET `/api/photos/gallery/{id}` - Photos in album

---

## 🔐 Permission System

The app uses **string-based permissions** (not numeric level IDs) for access control.

### Implementation Example:
```dart
// Check user permissions
if (user.hasPermission('can_approve_trips')) {
  // Show admin functionality
}
```

### Key Permissions:
- `can_approve_trips` - Approve/decline trips (Board)
- `can_manage_registrants` - Manage trip registrations (Marshal)
- `can_checkin_members` - Check-in/out members (Marshal)
- `can_view_members` - View member directory (Board)
- `can_edit_members` - Edit member profiles (Board)
- `can_manage_logbook` - Create logbook entries (Marshal)
- `can_manage_news` - Manage club news (Admin)
- `can_send_notifications` - Send push notifications (Admin)

**Benefit:** Backend can modify level IDs without breaking the app.

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.35.4
- Dart 3.9.2
- Java 17.0.2 (for Android builds)

### Installation
```bash
# Clone repository
git clone <repository-url>
cd flutter_app

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome --web-port=5060

# Run on Android
flutter run
```

### Environment Configuration

**API URLs are configurable via environment variables:**

```bash
# Development
flutter run --dart-define=MAIN_API_BASE=https://ap.ad4x4.com

# Production (default)
flutter run --dart-define=MAIN_API_BASE=https://ap.ad4x4.com
```

**Default values** (see `lib/core/config/api_config.dart`):
- Main API: `https://ap.ad4x4.com`
- Gallery API: `https://media.ad4x4.com`

---

## 📦 Dependencies

### Core
- **flutter_riverpod** 2.5.1 - State management
- **go_router** 13.2.0 - Navigation with auth guards
- **dio** 5.4.0 - HTTP client
- **retrofit** 4.1.0 - Type-safe REST client

### Storage
- **shared_preferences** 2.2.2 - Simple key-value storage
- **hive** 2.2.3 + **hive_flutter** 1.1.0 - NoSQL local database

### Media
- **image_picker** 1.0.7 - Photo selection
- **image_cropper** 8.0.2 - Image editing
- **cached_network_image** 3.3.1 - Image caching

### UI/Animation
- **flutter_animate** 4.5.0 - Animations
- **shimmer** 3.0.0 - Loading shimmer effects
- **flutter_staggered_grid_view** 0.7.0 - Grid layouts

### Maps
- **flutter_map** 7.0.2 - OpenStreetMap integration
- **latlong2** 0.9.1 - Coordinate handling

### Export & Utilities
- **csv** 6.0.0 - CSV generation
- **syncfusion_flutter_xlsio** 27.2.5 - Excel generation
- **pdf** 3.11.1 - PDF generation
- **printing** 5.13.2 - PDF preview/download
- **url_launcher** 6.2.4 - Launch URLs/email/phone
- **permission_handler** 11.2.0 - Runtime permissions
- **share_plus** 10.1.2 - Share functionality
- **intl** 0.18.1 - Internationalization
- **timeago** 3.6.0 - Relative timestamps
- **uuid** 4.5.1 - UUID generation

**Firebase (Commented - Ready to Enable):**
- firebase_core
- firebase_messaging

---

## 🧪 Testing Status

### Manual Testing Coverage
- ✅ Authentication flows
- ✅ Trip management (list, details, registration)
- ✅ Trip creation and editing
- ✅ Logbook system
- ✅ Admin panel functionality
- ✅ Permission-based access control
- ⏸️ Automated test suites (pending)

---

## 📱 Supported Platforms

- ✅ **Web** - Primary development platform
- ✅ **Android** - Production target (APK builds ready)
- ⏸️ **iOS** - Future phase

---

## ⚠️ Known Limitations

1. **Firebase Cloud Messaging** - Not yet integrated (commented in pubspec.yaml)
2. **Automated Tests** - Test files exist but comprehensive suite pending
3. **iOS Support** - Android-focused; iOS configuration pending
4. **Offline Mode** - Limited offline functionality (planned enhancement)

---

## 🔄 Development Workflow

### Code Standards
- Follow Flutter/Dart conventions
- Use Riverpod for state management
- Implement proper error handling
- Add loading states for async operations
- Use permission checks: `user.hasPermission('action')`
- Add comments for complex business logic

### Git Workflow
1. Create feature branch from `main`
2. Implement changes following standards
3. Test thoroughly
4. Commit with descriptive messages
5. Submit pull request

---

## 📚 Additional Documentation

**Located in `/docs/` directory:**

- **[MAIN_API_DOCUMENTATION.md](docs/MAIN_API_DOCUMENTATION.md)** - Complete Main API documentation (Django backend at `https://ap.ad4x4.com`)
  - Authentication & authorization endpoints
  - User management and profiles
  - Trip management system
  - Logbook and vehicle tracking
  - Admin panel operations
  - 5,051 lines of comprehensive API specifications

- **[GALLERY_API_DOCUMENTATION.md](docs/GALLERY-API-DOCUMENTATION.md)** - Complete Gallery API documentation (Node.js backend at `https://media.ad4x4.com`)
  - Photo gallery management
  - Image upload and processing
  - Favorites and collections
  - Search and filtering
  - Batch operations
  - Admin statistics and analytics
  - 2,319 lines of detailed endpoint documentation

**Note:** Both API documentation files have been updated with the latest endpoints and specifications (17 Nov 2025).


---

## 📞 Support

For technical questions or integration support:
- Review this README for project structure
- Check `/docs/` for API specifications
- Review code comments for implementation details

---

## 📝 License

[License Type To Be Determined]

---

**Project:** Abu Dhabi Off-Road Club Mobile App  
**Technology:** Flutter 3.35.4 / Dart 3.9.2  
**Status:** Active Development  
**Last Updated:** November 2024
