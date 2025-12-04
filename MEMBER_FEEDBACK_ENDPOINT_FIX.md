# ✅ Member Feedback Endpoint Fix

## 🔍 Problem Identified

**Widget 8 (Member Feedback)** was using the wrong API endpoint to view another member's feedback.

---

## 🚨 Root Cause

**Incorrect Endpoint Used:**
```
GET /api/members/{id}/feedback
```

**Issue:**
- This endpoint is designed for **authenticated users to view THEIR OWN feedback only**
- Backend enforces permission check: `request.user.id == member.id`
- Even admin users get `403 Forbidden` when trying to view another member's feedback

**Error Message:**
```
Auth Error: GET /api/members/11932/feedback - Access forbidden. 
You don't have permission to perform this action.
```

---

## ✅ Solution Applied

**Changed to Admin Feedback Endpoint:**
```
GET /api/feedback/?user={memberId}&page=1&pageSize=20
```

**Benefits:**
- ✅ Admin/Marshal users can view any member's feedback
- ✅ Proper permission checks handled by backend
- ✅ Uses the same endpoint as admin feedback management
- ✅ Filters feedback by user ID

---

## 📝 Code Changes

### **File: `lib/data/repositories/main_api_repository.dart`**

**Before (Line 1083-1093):**
```dart
Future<Map<String, dynamic>> getMemberFeedback({
  required int memberId,
  int page = 1,
  int pageSize = 20,
}) async {
  final response = await _apiClient.get(
    MainApiEndpoints.memberFeedback(memberId),  // ❌ Self-only endpoint
    queryParameters: {'page': page, 'pageSize': pageSize},
  );
  return response.data;
}
```

**After (Fixed):**
```dart
Future<Map<String, dynamic>> getMemberFeedback({
  required int memberId,
  int page = 1,
  int pageSize = 20,
}) async {
  // ✅ FIXED: Use admin feedback endpoint with user filter
  // The /api/members/{id}/feedback endpoint is for self-only access
  // Use /api/feedback/?user={id} to view another member's feedback (admin/marshal)
  final response = await _apiClient.get(
    MainApiEndpoints.feedback,  // ✅ Admin endpoint
    queryParameters: {
      'page': page,
      'pageSize': pageSize,
      'user': memberId,  // ✅ Filter by user ID
    },
  );
  return response.data;
}
```

---

## 🎯 Expected Behavior After Fix

### **Admin/Marshal Users:**
- ✅ Can view any member's feedback through Member Details screen
- ✅ Feedback widget will display properly (no 403 error)
- ✅ Empty state shown if member has no feedback

### **Regular Users:**
- If backend permissions allow: Can view other members' feedback
- If backend denies: Will see "Access Restricted" error card (correct behavior)

---

## 📊 API Endpoint Reference

| Endpoint | Purpose | Permission | Query Params |
|----------|---------|------------|--------------|
| `GET /api/members/{id}/feedback` | View **own** feedback | JWT (self only) | page, pageSize |
| `GET /api/feedback/` | View **all/filtered** feedback | JWT (admin/marshal) | page, pageSize, user, status, feedbackType |
| `POST /api/feedback/` | Submit feedback | JWT Required | - |
| `PATCH /api/feedback/{id}` | Update feedback | Admin Only | - |
| `DELETE /api/feedback/{id}` | Delete feedback | Admin Only | - |

---

## 🧪 Testing Checklist

After rebuild and deployment:

- [ ] **Admin User** - View another member's profile → Feedback widget should load
- [ ] **Admin User** - View member with feedback → Should display feedback cards
- [ ] **Admin User** - View member without feedback → Should show empty state
- [ ] **Regular User** - View another member → Should see appropriate permission handling
- [ ] **Error Logs** - No more 403 errors for feedback widget

---

## 🔗 Related Files

- `/home/user/flutter_app/lib/data/repositories/main_api_repository.dart` - Fixed method
- `/home/user/flutter_app/lib/core/network/main_api_endpoints.dart` - Endpoint constants
- `/home/user/flutter_app/lib/features/members/presentation/screens/member_details_screen.dart` - UI implementation
- `/home/user/flutter_app/docs/MAIN_API_DOCUMENTATION.md` - API documentation

---

## 📚 Background Context

This fix was identified while implementing comprehensive error handling for member profile widgets. The error logging system correctly identified the 403 Forbidden error, which led to discovering the incorrect endpoint usage.

**Error Detection Flow:**
1. User viewed member profile (Member ID: 11932)
2. Widget 8 (Member Feedback) attempted to load data
3. Backend returned `403 Forbidden`
4. Error logged to ErrorLogService with context
5. EnhancedErrorState displayed "Access Restricted" message
6. Investigation revealed endpoint mismatch

---

## ✅ Fix Status

**Status:** ✅ **COMPLETE**

**Next Step:** Clear cache, rebuild, and test the fix

**Expected Result:** Member Feedback widget should now load successfully for admin/marshal users viewing other members' profiles.
