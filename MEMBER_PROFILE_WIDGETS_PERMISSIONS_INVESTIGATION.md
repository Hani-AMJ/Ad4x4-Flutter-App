# Member Profile Widgets - Permissions Investigation Report

**Investigation Date**: 2025-12-03  
**Scope**: Widgets 5-8 in Member Details Screen  
**Focus**: Permission requirements and admin panel access

---

## 🎯 Executive Summary

**FINDING**: Widgets 5-8 in the Member Profile screen are **PUBLICLY ACCESSIBLE** - they do NOT have proper permission checks and can be viewed by ANY authenticated user.

**RECOMMENDATION**: These widgets should be restricted to **Marshals, Board Members, and Admins only**.

---

## 📊 Widget Analysis

### Widget 5: 📊 Trip Statistics (`_TripStatisticsCard`)
**Location**: `lib/features/members/presentation/screens/member_details_screen.dart` (Lines 538-561, 942-1067)

**API Endpoint**: `GET /api/members/{id}/tripcounts`  
**Current Authentication**: `Optional JWT Authentication`  
**Data Displayed**:
- Total trips count
- Completion rate percentage
- Trips breakdown by level (Club Event, Newbie, Intermediate, Advanced, Expert, Marshal)

**Current Access Control**: ❌ NONE - Any authenticated user can view

**Admin Panel Access**: ❌ NOT AVAILABLE in admin reports

---

### Widget 6: ⬆️ Upgrade History (`_UpgradeHistoryCard`)
**Location**: `lib/features/members/presentation/screens/member_details_screen.dart` (Lines 564-599, 1069-1190)

**API Endpoint**: `GET /api/members/{id}/upgraderequests`  
**Current Authentication**: `JWT Authentication Required`  
**Data Displayed**:
- Level progression timeline (Current Level → Requested Level)
- Request dates
- Status badges (APPROVED, REJECTED, PENDING)

**Current Access Control**: ❌ NONE - Any authenticated user can view

**Admin Panel Access**: ❌ NOT AVAILABLE in admin reports

---

### Widget 7: 📝 Trip Requests (`_TripRequestCard`)
**Location**: `lib/features/members/presentation/screens/member_details_screen.dart` (Lines 602-644, 1192-1303)

**API Endpoint**: `GET /api/members/{id}/triprequests`  
**Current Authentication**: `JWT Authentication Required`  
**Data Displayed**:
- Trip requests made by member to marshals
- Level & Area (e.g., "Advanced • Al Qudra Desert")
- Request date and time of day
- Status badges (SCHEDULED, PENDING, REJECTED)

**Current Access Control**: ❌ NONE - Any authenticated user can view

**Admin Panel Access**: ✅ **YES** - Available in Admin Dashboard
- **Screen**: `AdminTripRequestsScreen`
- **Route**: `/admin/trip-requests`
- **File**: `lib/features/admin/presentation/screens/admin_trip_requests_screen.dart`
- **Features**: 
  - View all trip requests from all members
  - Filter by status (all, pending, approved, declined, converted)
  - Update request status
  - Add admin notes

---

### Widget 8: ⭐ Member Feedback (`_MemberFeedbackCard`)
**Location**: `lib/features/members/presentation/screens/member_details_screen.dart` (Lines 647-682, 1305-1409)

**API Endpoint**: `GET /api/members/{id}/feedback`  
**Current Authentication**: `JWT Authentication Required`  
**Data Displayed**:
- Star ratings (1-5 stars)
- Feedback comments
- Author names
- Feedback dates

**Current Access Control**: ❌ NONE - Any authenticated user can view

**Admin Panel Access**: ❌ NOT AVAILABLE in admin reports

---

## 🔍 API Documentation Findings

### Endpoint Permission Summary

| Endpoint | Current Auth | Should Be |
|----------|-------------|-----------|
| `GET /api/members/{id}/tripcounts` | **Optional JWT** | **Marshals/Admins Only** |
| `GET /api/members/{id}/upgraderequests` | **JWT Required** | **Marshals/Admins Only** |
| `GET /api/members/{id}/triprequests` | **JWT Required** | **Marshals/Admins Only** |
| `GET /api/members/{id}/feedback` | **JWT Required** | **Marshals/Admins Only** |

**Source**: `/home/user/flutter_app/docs/MAIN_API_DOCUMENTATION.md`

---

## 🚨 Security Concerns

### **PRIVACY ISSUE**: Public Access to Sensitive Data

**Problem**: ANY authenticated user can view:
1. **Upgrade Request History**: See when members requested level upgrades and whether they were approved/rejected
2. **Trip Requests**: View all trip requests made by any member
3. **Member Feedback**: Read ratings and comments about any member
4. **Trip Statistics**: Access detailed trip participation data

**Example Scenario**:
```dart
// Current implementation (NO permission checks)
Future<void> _loadUpgradeHistory(int memberId) async {
  // ❌ ANY authenticated user can call this
  final response = await _repository.getMemberUpgradeRequests(
    memberId: memberId, 
    page: 1, 
    pageSize: 10
  );
  // Data is displayed without checking viewer's permissions
}
```

**Impact**: 
- Regular members can spy on other members' upgrade histories
- Members can see all feedback/ratings for any member
- No privacy for sensitive member data

---

## ✅ Recommended Solution

### **Option 1: Backend Permission Enforcement (RECOMMENDED)**

**Modify API endpoints** to enforce permission checks:

```python
# Backend: views.py
from rest_framework.permissions import IsAuthenticated
from .permissions import IsMarshalOrAdmin

class MemberUpgradeRequestsViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, IsMarshalOrAdmin]
    # Only marshals, board members, and admins can access
```

**Affected Endpoints**:
- `GET /api/members/{id}/tripcounts` → Add `IsMarshalOrAdmin` permission
- `GET /api/members/{id}/upgraderequests` → Add `IsMarshalOrAdmin` permission
- `GET /api/members/{id}/triprequests` → Add `IsMarshalOrAdmin` permission
- `GET /api/members/{id}/feedback` → Add `IsMarshalOrAdmin` permission

---

### **Option 2: Frontend Permission Checks (Additional Layer)**

**Modify `member_details_screen.dart`** to check user permissions before loading widgets:

```dart
// Check if current user has marshal/admin permissions
bool _canViewSensitiveData() {
  final currentUser = ref.read(authProvider).user;
  if (currentUser == null) return false;
  
  // Check if user is Marshal level (numeric level >= 600)
  if (currentUser.level?.numericLevel != null && 
      currentUser.level!.numericLevel >= 600) {
    return true;
  }
  
  // Check if user has admin/board member permissions
  final hasAdminPermission = currentUser.permissions.any((p) => 
    p.codename.contains('admin') || 
    p.codename.contains('board') ||
    p.codename.contains('view_all_members')
  );
  
  return hasAdminPermission;
}

// Conditionally load sensitive widgets
@override
void initState() {
  super.initState();
  _loadMemberData();
  
  // ✅ ONLY load sensitive data if user has permission
  if (_canViewSensitiveData()) {
    _loadTripStatistics(memberId);
    _loadUpgradeHistory(memberId);
    _loadTripRequests(memberId);
    _loadMemberFeedback(memberId);
  }
}

// Conditionally display widgets
if (_canViewSensitiveData() && !_isLoadingStats && _tripStatistics != null)
  SliverToBoxAdapter(
    child: _TripStatisticsCard(statistics: _tripStatistics!),
  ),
```

---

## 📋 Admin Panel Access Summary

### **Widget 7: Trip Requests** ✅ Available in Admin Panel

**Admin Screen**: `AdminTripRequestsScreen`
- **Route**: `/admin/trip-requests`
- **Access**: Admin panel → Trip Requests
- **Features**:
  - View ALL trip requests from ALL members
  - Filter by status (all, pending, approved, declined, converted)
  - Update request status (approve/decline)
  - Add admin notes to requests
  - Sort by created date (newest first)

**API Method**: `getAllTripRequests()` (different from member-specific endpoint)

---

### **Widgets 5, 6, 8**: ❌ NOT Available in Admin Panel

These widgets are **ONLY accessible** through the Member Details Screen:
- **Widget 5**: Trip Statistics (tripcounts)
- **Widget 6**: Upgrade History (upgraderequests)
- **Widget 8**: Member Feedback (feedback)

**Recommendation**: Consider adding these to admin reports for comprehensive member analytics.

---

## 🎯 Implementation Priority

### **HIGH PRIORITY** (Security Fix):
1. ✅ Add backend permission checks to 4 endpoints
2. ✅ Enforce `IsMarshalOrAdmin` permission class
3. ✅ Update API documentation to reflect new permissions

### **MEDIUM PRIORITY** (User Experience):
4. ✅ Add frontend permission checks in `member_details_screen.dart`
5. ✅ Hide widgets 5-8 for regular members
6. ✅ Show "Permission Required" message if accessed by regular users

### **LOW PRIORITY** (Feature Enhancement):
7. 🔲 Add Trip Statistics to admin dashboard
8. 🔲 Add Upgrade History report to admin panel
9. 🔲 Add Member Feedback management to admin panel

---

## 📊 Comparison Table

| Feature | Regular Member | Marshal | Board Member | Admin |
|---------|---------------|---------|--------------|-------|
| **Widget 1-4** (Basic Info) | ✅ View All | ✅ View All | ✅ View All | ✅ View All |
| **Widget 5** (Trip Statistics) | ❌ Should Hide | ✅ Can View | ✅ Can View | ✅ Can View |
| **Widget 6** (Upgrade History) | ❌ Should Hide | ✅ Can View | ✅ Can View | ✅ Can View |
| **Widget 7** (Trip Requests) | ❌ Should Hide | ✅ Can View | ✅ Can View | ✅ Can View |
| **Widget 8** (Member Feedback) | ❌ Should Hide | ✅ Can View | ✅ Can View | ✅ Can View |
| **Widget 9** (Recent Trips) | ✅ View All | ✅ View All | ✅ View All | ✅ View All |

---

## 🔧 Technical Implementation Details

### Current User Model Structure

```dart
class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserLevel? level;  // ✅ Contains numeric level for Marshal check
  final List<Permission> permissions;  // ✅ Contains permission objects
  final int tripCount;
  // ... other fields
}

class Permission {
  final String codename;  // e.g., 'view_all_members', 'create_trip_report'
  final String name;
  // ... other fields
}
```

### Permission Check Implementation

```dart
// Extension method for easy permission checking
extension UserPermissions on UserModel {
  bool get isMarshal => level?.numericLevel != null && level!.numericLevel >= 600;
  
  bool get isBoardMember => level?.displayName?.toLowerCase().contains('board') ?? false;
  
  bool get isAdmin => permissions.any((p) => 
    p.codename.contains('admin') || 
    p.codename == 'view_all_members'
  );
  
  bool get canViewSensitiveMemberData => isMarshal || isBoardMember || isAdmin;
}
```

---

## 📝 Conclusion

**Current State**: Widgets 5-8 are **publicly accessible** to all authenticated users - this is a **privacy/security issue**.

**Recommendation**: 
1. **IMMEDIATE**: Add backend permission checks to restrict access to Marshals/Admins
2. **SHORT-TERM**: Add frontend permission checks as additional security layer
3. **LONG-TERM**: Consider adding these widgets to admin panel reports for better oversight

**Next Steps**:
1. Confirm with backend team: Should these endpoints be restricted?
2. Implement backend permission classes
3. Update Flutter app to check permissions before loading widgets
4. Test with different user roles (Regular Member, Marshal, Admin)
5. Update API documentation with new permission requirements

---

**Report Generated**: 2025-12-03  
**Investigation Complete** ✅
