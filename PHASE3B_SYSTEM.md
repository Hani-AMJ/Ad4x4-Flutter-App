# Phase 3B: Enhanced Trip Management System

## 📋 Overview

Phase 3B extends the admin panel with advanced trip management capabilities focused on three core areas:

1. **Trip Media Gallery Management** - Photo/video moderation and approval workflow
2. **Trip Comments Moderation** - Comment management with flagging and user banning
3. **Advanced Registration Management** - Analytics, bulk operations, and waitlist management

## 🎯 Feature Sets

### 1. Trip Media Gallery Management

**Purpose**: Enable admins/marshals to moderate user-uploaded trip photos and videos.

**Features**:
- Grid view of trip media with thumbnails
- Photo/video approval workflow (pending → approved/rejected)
- Reject with reason capability
- Delete functionality with confirmation
- Filter by approval status (pending/all)
- Infinite scroll pagination
- Pull-to-refresh
- Upload progress tracking

**Permission**: `moderate_gallery`

**Screens**:
- `AdminTripMediaScreen` - Main moderation interface

**State Management**:
- `TripMediaProvider` - Media list with pagination
- `PendingMediaProvider` - Moderation queue
- `MediaModerationActionsProvider` - Approve/reject/delete actions

---

### 2. Trip Comments Moderation

**Purpose**: Manage trip comments with approval workflow and user moderation tools.

**Features**:
- Multi-section view (Pending, Flagged, All Comments)
- Comment approval/rejection workflow
- Edit comment text capability
- User ban system with duration options (1 day, 7 days, 30 days, permanent)
- Flag display with count
- Moderation history tracking
- Filter by status and flagged state

**Permission**: `moderate_comments`

**Ban Durations**:
- 1 Day - Temporary cooling-off period
- 7 Days - Short-term suspension
- 30 Days - Long-term suspension
- Permanent - Permanent comment ban

**Screens**:
- `AdminCommentsModerationScreen` - Comment moderation interface

**State Management**:
- `AllCommentsProvider` - Complete comment list with filters
- `PendingCommentsProvider` - Approval queue
- `FlaggedCommentsProvider` - User-reported comments
- `CommentModerationActionsProvider` - Approve/reject/edit/ban actions

---

### 3. Advanced Registration Management

**Purpose**: Provide comprehensive tools for managing trip registrations and analytics.

#### 3.1 Registration Analytics Dashboard

**Features**:
- Trip selector dropdown
- 6 summary stat cards:
  - Total Registrations + available spots
  - Confirmed + fill percentage
  - Checked In + check-in rate
  - Checked Out count
  - Cancellations + cancellation rate
  - Waitlist count
- Registration breakdown by member level (progress bars)
- Quick action buttons:
  - Manage Registrations
  - Manage Waitlist
  - Notify All Registrants
- Export functionality (CSV/PDF)

**Screen**: `AdminRegistrationAnalyticsScreen`

---

#### 3.2 Bulk Registration Actions

**Features**:
- Registration list with checkbox selection
- Filter by status (all, confirmed, checked-in, pending, cancelled)
- Bulk action bar with:
  - Approve Selected
  - Reject Selected (with reason)
  - Check-in Selected
  - Send Notification
- Individual registration cards showing:
  - Member details (name, level, avatar)
  - Registration date
  - Vehicle information
  - Status badges
  - Analytics (trip count, days until trip, photo uploads)
- Select all / Deselect all functionality
- Infinite scroll pagination

**Screen**: `AdminBulkRegistrationsScreen`

---

#### 3.3 Waitlist Management

**Features**:
- Waitlist member list with position display
- Reorder positions (drag and drop functionality)
- Move to registered (individual or batch)
- Waitlist statistics:
  - Total waitlist count
  - Available spots
  - Confirmed registrations vs capacity
- Member info display:
  - Position number badge
  - Member details (name, level, avatar)
  - Join date
  - Waiting duration calculation
- Batch selection with checkboxes
- Auto-fill configuration (coming soon)
- Notification on status change

**Screen**: `AdminWaitlistManagementScreen`

**Permission**: `manage_registrations` (applies to all registration management features)

---

## 📂 File Structure

```
lib/
├── data/
│   └── models/
│       ├── trip_media_model.dart             # Media gallery models
│       ├── comment_moderation_model.dart     # Comment moderation models
│       └── registration_analytics_model.dart # Analytics & registration models
│
├── data/
│   └── repositories/
│       └── main_api_repository.dart          # API methods (18 new endpoints)
│
├── features/
│   └── admin/
│       └── presentation/
│           ├── providers/
│           │   ├── trip_media_provider.dart              # Media gallery state
│           │   ├── comment_moderation_provider.dart      # Comment moderation state
│           │   └── registration_management_provider.dart # Registration state
│           │
│           └── screens/
│               ├── admin_trip_media_screen.dart              # Media moderation
│               ├── admin_comments_moderation_screen.dart     # Comment moderation
│               ├── admin_registration_analytics_screen.dart  # Analytics dashboard
│               ├── admin_bulk_registrations_screen.dart      # Bulk actions
│               └── admin_waitlist_management_screen.dart     # Waitlist management
│
└── core/
    └── router/
        └── app_router.dart                   # Route definitions (5 new routes)
```

---

## 🔧 Implementation Details

### Data Models

#### TripMedia
```dart
class TripMedia {
  final int id;
  final int tripId;
  final BasicMember uploadedBy;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime uploadDate;
  final bool approved;
  final BasicMember? moderatedBy;
  final DateTime? moderationDate;
  final String? moderationReason;
  final String fileType;
  final int fileSize;
  
  bool get isPending => !approved && moderatedBy == null;
  String get fileSizeFormatted { /* human-readable format */ }
}
```

#### TripCommentWithModeration
```dart
class TripCommentWithModeration extends TripComment {
  final bool approved;
  final BasicMember? moderatedBy;
  final DateTime? moderationDate;
  final String? moderationReason;
  final bool flagged;
  final int flagCount;
  final List<CommentFlag> flags;
  final ModerationStatus status;
  
  bool get isPending => status == ModerationStatus.pending;
  bool get isAutoFlagged => flagCount >= 3;
}
```

#### RegistrationAnalytics
```dart
class RegistrationAnalytics {
  final int tripId;
  final int totalRegistrations;
  final int confirmedRegistrations;
  final int checkedIn;
  final int checkedOut;
  final int cancelled;
  final int totalWaitlist;
  final int tripCapacity;
  final Map<String, int> registrationsByLevel;
  final double checkInRate;
  final double cancellationRate;
  
  int get availableSpots => tripCapacity - confirmedRegistrations;
  double get fillPercentage => (confirmedRegistrations / tripCapacity) * 100;
}
```

---

### API Endpoints

#### Trip Media APIs (6 endpoints)
```dart
GET  /api/trips/:tripId/media/              - Get trip media (paginated)
POST /api/trips/:tripId/media/upload/       - Upload photo/video
POST /api/media/:photoId/approve/           - Approve media
POST /api/media/:photoId/reject/            - Reject media
POST /api/media/:photoId/moderate/          - General moderation
DELETE /api/media/:photoId/                 - Delete media
```

#### Comment Moderation APIs (7 endpoints)
```dart
GET  /api/comments/                         - Get all comments (with filters)
POST /api/comments/:commentId/approve/      - Approve comment
POST /api/comments/:commentId/reject/       - Reject comment
PUT  /api/comments/:commentId/edit/         - Edit comment text
POST /api/comments/:commentId/flag/         - Flag comment
POST /api/users/:userId/ban/                - Ban user from commenting
GET  /api/users/:userId/ban-status/         - Check ban status
```

#### Registration Management APIs (9 endpoints)
```dart
GET  /api/trips/:tripId/registration-analytics/     - Get analytics
POST /api/registrations/bulk-approve/               - Bulk approve
POST /api/registrations/bulk-reject/                - Bulk reject
POST /api/registrations/bulk-checkin/               - Bulk check-in
POST /api/trips/:tripId/notify-registrants/         - Send notification
POST /api/trips/:tripId/waitlist/move-to-registered/ - Move from waitlist
POST /api/trips/:tripId/waitlist/reorder/           - Reorder waitlist
GET  /api/trips/:tripId/detailed-registrations/     - Get detailed list
POST /api/trips/:tripId/export-registrations/       - Export data
```

---

### State Management Architecture

#### Trip Media State
```dart
class TripMediaState {
  final List<TripMedia> media;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final int? tripFilter;
  final bool? approvedFilter;
  
  List<TripMedia> get pendingMedia => media.where((m) => m.isPending).toList();
  int get pendingCount => pendingMedia.length;
}
```

#### Comment Moderation State
```dart
class AllCommentsState {
  final List<TripCommentWithModeration> comments;
  final int pendingCount;
  final int flaggedCount;
  final ModerationStatus? statusFilter;
  final bool flaggedOnly;
  
  List<TripCommentWithModeration> get pendingComments => 
      comments.where((c) => c.isPending).toList();
  List<TripCommentWithModeration> get flaggedComments => 
      comments.where((c) => c.flagged).toList();
}
```

#### Registration List State
```dart
class RegistrationListState {
  final List<TripRegistrationWithAnalytics> registrations;
  final List<int> selectedIds;
  
  bool get hasSelection => selectedIds.isNotEmpty;
  List<TripRegistrationWithAnalytics> get selectedRegistrations => 
      registrations.where((r) => selectedIds.contains(r.registration.id)).toList();
}
```

---

## 🎨 UI Components

### Media Card (Trip Media Screen)
```
┌─────────────────────────────────┐
│  [Photo Thumbnail]              │
│  └─ Status Badge: PENDING       │
├─────────────────────────────────┤
│  Uploaded by: John Doe          │
│  Date: 2024-01-15               │
│  Caption: Amazing sunset!       │
│  File size: 2.5 MB              │
├─────────────────────────────────┤
│  [Approve]  [Reject]            │ (if pending)
│  [Delete]                       │ (if approved/rejected)
└─────────────────────────────────┘
```

### Comment Card (Comments Moderation Screen)
```
┌─────────────────────────────────┐
│  [Avatar] John Doe   [PENDING]  │
│  2024-01-15 10:30 AM            │
├─────────────────────────────────┤
│  Great trip! Looking forward... │
│                                 │
│  ⚠️ Flagged: 2 reports          │ (if flagged)
├─────────────────────────────────┤
│  [Approve]  [Reject]            │
│  [Edit]     [Ban User]          │
└─────────────────────────────────┘
```

### Registration Card (Bulk Actions Screen)
```
┌─────────────────────────────────┐
│ [ ] [Avatar] John Doe           │
│     Level: Intermediate         │  [CONFIRMED]
│     Registered: 2024-01-10      │
│     Vehicle: Toyota 4Runner     │
│     ─────────────────────────   │
│     🚗 25 trips  ⏱️ 5 days       │
│     📷 Photos uploaded          │
└─────────────────────────────────┘
```

### Waitlist Card (Waitlist Management Screen)
```
┌─────────────────────────────────┐
│ ≡ [ ] (#1) [Avatar] John Doe    │  [→]
│          Level: Intermediate     │
│          Joined: 2024-01-10     │
│          Waiting: 5 days        │
└─────────────────────────────────┘
```

---

## 🔐 Permission System

### New Permissions

1. **`moderate_gallery`** - Trip Media Moderation
   - View all uploaded media
   - Approve/reject photos and videos
   - Delete media
   - Access media moderation screen

2. **`moderate_comments`** - Comment Moderation
   - View all comments
   - Approve/reject comments
   - Edit comment text
   - Ban users from commenting
   - View flagged comments
   - Access comment moderation screen

3. **`manage_registrations`** - Advanced Registration Management
   - View registration analytics
   - Perform bulk operations (approve, reject, check-in)
   - Send notifications to registrants
   - Manage waitlist (reorder, move to registered)
   - Export registration data
   - Access all registration management screens

---

## 🚀 Navigation

### Admin Sidebar Structure

```
ADMIN PANEL
├── Dashboard
│
├── TRIP MANAGEMENT
│   ├── Approval Queue
│   ├── All Trips
│   └── Create Trip
│
├── MEMBER MANAGEMENT
│   └── All Members
│
├── UPGRADE REQUESTS
│   └── Upgrade Requests
│
├── MARSHAL PANEL
│   ├── Logbook Entries
│   ├── Sign Off Skills
│   └── Trip Reports
│
├── CONTENT MODERATION        ← Phase 3B (New)
│   ├── Trip Media
│   └── Comments
│
└── REGISTRATION TOOLS        ← Phase 3B (New)
    ├── Analytics
    ├── Bulk Actions
    └── Waitlist
```

### Routes

```dart
// Content Moderation
/admin/trip-media                   - Trip media moderation
/admin/comments-moderation          - Comments moderation

// Registration Management
/admin/registration-analytics       - Analytics dashboard
/admin/bulk-registrations           - Bulk registration actions
/admin/waitlist-management          - Waitlist management
```

---

## 📊 Usage Scenarios

### Scenario 1: Moderating Trip Photos

1. Admin navigates to **Content Moderation → Trip Media**
2. System displays pending photos in grid view
3. Admin reviews photo, clicks **Approve** or **Reject**
4. If rejecting, admin provides reason in dialog
5. System updates photo status and notifies uploader
6. Photo appears in approved gallery or is hidden

### Scenario 2: Handling Flagged Comments

1. Admin navigates to **Content Moderation → Comments**
2. System displays flagged comments section with flag count
3. Admin reviews flagged comment and flag reasons
4. Admin decides on action:
   - **Approve**: Comment is valid, dismiss flags
   - **Reject**: Comment violates rules, remove with reason
   - **Edit**: Modify comment text to remove offensive content
   - **Ban User**: Temporarily or permanently ban user from commenting
5. System updates comment status and records moderation action

### Scenario 3: Bulk Check-In Registrants

1. Marshal navigates to **Registration Tools → Bulk Actions**
2. Selects trip from dropdown
3. Filters registrations by "Confirmed" status
4. Uses checkboxes to select attendees present at meeting point
5. Clicks **Check-in** button in bulk action bar
6. System marks all selected registrations as checked-in
7. Analytics dashboard updates with new check-in rate

### Scenario 4: Managing Waitlist

1. Admin navigates to **Registration Tools → Waitlist**
2. Selects trip from dropdown
3. Reviews waitlist with position numbers
4. Drags and drops members to reorder priority
5. Selects top 3 members using checkboxes
6. Clicks **Move to Registered** button
7. System confirms action in dialog
8. Members are moved to registered list and notified
9. Analytics updates with new available spots

---

## 🔄 Workflow Diagrams

### Photo Approval Workflow
```
User Uploads Photo
       ↓
  [PENDING]
       ↓
  ┌────┴────┐
  │         │
Approve   Reject
  │         │
  ↓         ↓
[APPROVED] [REJECTED]
  │         │
  ↓         └→ User notified (with reason)
Visible      Hidden
in Gallery
```

### Comment Moderation Workflow
```
User Posts Comment
       ↓
  [PENDING]
       ↓
  ┌────┴────┐
  │         │
Approve   Reject ← Flagged by users (auto-flag at 3 reports)
  │         │
  ↓         ↓
[APPROVED] [REJECTED]
  │         │
  ↓         └→ User notified (with reason)
Visible      Hidden
  │
  └→ Can be edited by moderator
```

### Waitlist to Registered Flow
```
User Joins Waitlist
       ↓
  [Position #N]
       ↓
  ┌────┴────┐
  │         │
Spot      Manual
Available  Move
  │         │
  ↓         ↓
Auto-Fill  Admin
Enabled?   Action
  │         │
  ↓         ↓
[REGISTERED]
  │
  └→ User notified
```

---

## 🧪 Testing Checklist

### Trip Media Moderation
- [ ] Upload photo and see it in pending queue
- [ ] Approve photo - verify it appears in gallery
- [ ] Reject photo with reason - verify user receives notification
- [ ] Delete approved photo - verify it's removed from gallery
- [ ] Filter by pending/all - verify correct media displayed
- [ ] Test infinite scroll pagination
- [ ] Test pull-to-refresh functionality

### Comment Moderation
- [ ] Post comment and see it in pending queue
- [ ] Approve comment - verify it appears in trip discussion
- [ ] Reject comment with reason - verify it's hidden
- [ ] Edit comment text - verify changes saved
- [ ] Ban user for 1 day - verify they can't comment
- [ ] Ban user permanently - verify permanent ban status
- [ ] Flag comment 3 times - verify auto-flag behavior
- [ ] Filter by status and flagged state

### Registration Analytics
- [ ] View analytics for trip with registrations
- [ ] Verify all 6 stat cards show correct values
- [ ] Check registration breakdown by level accuracy
- [ ] Export registrations as CSV - verify file download
- [ ] Export registrations as PDF - verify file download
- [ ] Send notification to all registrants - verify push sent
- [ ] Navigate to Bulk Actions from quick action button
- [ ] Navigate to Waitlist Management from quick action button

### Bulk Registration Actions
- [ ] Select multiple registrations using checkboxes
- [ ] Bulk approve - verify status changes
- [ ] Bulk reject with reason - verify status and notification
- [ ] Bulk check-in - verify check-in timestamps
- [ ] Send notification to selected members - verify push sent
- [ ] Filter by status - verify correct registrations displayed
- [ ] Select all / Deselect all - verify selection state
- [ ] Test infinite scroll pagination

### Waitlist Management
- [ ] View waitlist with position numbers
- [ ] Reorder members using drag-and-drop - verify position updates
- [ ] Move single member to registered - verify promotion
- [ ] Move multiple members to registered - verify batch promotion
- [ ] Verify members receive notification when promoted
- [ ] Check analytics updates after moving members
- [ ] Select all / Deselect all - verify selection state

---

## 📝 Notes

### Performance Considerations
- Media gallery uses pagination to handle large photo collections
- Comment list supports filtering to reduce data load
- Registration list implements infinite scroll for smooth UX
- Analytics calculations are server-side to avoid client overhead

### Security
- All moderation actions are logged with moderator ID and timestamp
- Ban system prevents abuse through duration options
- Bulk operations require confirmation dialogs for safety
- Export functionality respects permission checks

### Future Enhancements
- Auto-fill waitlist configuration UI
- Advanced filtering for media (date range, file type, uploader)
- Comment reply moderation
- Registration timeline visualization
- Email notification integration
- Batch photo upload capability
- Video thumbnail generation
- Media compression options

---

## 🤝 Related Systems

- **Phase 3A: Marshal Panel** - Trip reports, logbook management, skill sign-offs
- **Trip Management** - Core trip CRUD operations
- **Member Management** - Member profiles and permissions
- **Notification System** - Push notifications for moderation actions

---

## 📚 References

- **Django REST API Documentation**: https://ap.ad4x4.com/api/docs/
- **Permission System**: See `AUTH_SYSTEM.md`
- **Marshal Panel**: See `MARSHAL_PANEL_SYSTEM.md`
- **State Management**: See `STATE_MANAGEMENT.md`

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0  
**Status**: ✅ Implementation Complete
