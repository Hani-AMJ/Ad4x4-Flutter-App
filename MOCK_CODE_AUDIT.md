# 🔍 Mock & Placeholder Code Audit Report
**Date:** Post-Cleanup Verification  
**Scope:** Login, Trips, Sign-Out, Profile Screens

---

## 📊 EXECUTIVE SUMMARY

**Status:** 🟡 **ISSUES FOUND** - Action Required

**Critical Issues:** 2 🔴  
**Medium Issues:** 2 🟡  
**Low Issues:** 2 🟢

---

## 🔴 CRITICAL ISSUES

### 1. **Profile Screen - Fake Logout Implementation**
**Location:** `lib/features/profile/presentation/screens/profile_screen.dart:287-291`

**Issue:** Logout button has TODO comment and fake implementation

**Current Code:**
```dart
onPressed: () {
  Navigator.pop(context);
  // TODO: Implement actual logout
  context.go('/login');
},
```

**Problem:**
- ❌ Does NOT call `authProviderV2.notifier.logout()`
- ❌ Just navigates to login without clearing auth state
- ❌ User remains authenticated in background
- ❌ Token stays in SharedPreferences
- ❌ Refresh page will auto-login user back in

**Impact:** HIGH - Users cannot actually log out from profile screen, only from settings screen

**Expected Code:**
```dart
onPressed: () async {
  Navigator.pop(context);
  await ref.read(authProviderV2.notifier).logout();
  // No need for navigation - router handles redirect
},
```

**Comparison with Settings Screen:** Settings screen (line 371) correctly implements logout with `authProviderV2.notifier.logout()`

---

### 2. **Profile Screen - Hard-Coded Stats**
**Location:** `lib/features/profile/presentation/screens/profile_screen.dart:123-150`

**Issue:** Stats section uses placeholder data instead of real API data

**Current Code:**
```dart
_StatItem(
  icon: Icons.directions_car,
  label: 'Trips',
  value: '24',  // ❌ Hard-coded
  colors: colors,
),
_StatItem(
  icon: Icons.photo_library,
  label: 'Photos',
  value: '156',  // ❌ Hard-coded
  colors: colors,
),
_StatItem(
  icon: Icons.local_fire_department,
  label: 'Points',
  value: '1,240',  // ❌ Hard-coded
  colors: colors,
),
```

**Problem:**
- ❌ Shows same fake numbers for all users
- ❌ Not connected to API data
- ❌ Misleading user experience

**Impact:** MEDIUM - Confusing but not breaking functionality

**Note:** This needs backend API support to fetch real user statistics

---

## 🟡 MEDIUM ISSUES

### 3. **Search Screen - Uses Sample Data**
**Location:** `lib/features/search/presentation/screens/global_search_screen.dart:3,69`

**Issue:** Search results use SampleTrips.getTrips() mock data

**Current Code:**
```dart
import '../../../../data/sample_data/sample_trips.dart';
...
_tripResults = SampleTrips.getTrips()
    .where((trip) => trip.title.toLowerCase().contains(query.toLowerCase()))
    .toList();
```

**Problem:**
- ❌ Searches against mock data, not production API
- ❌ Results don't match actual trips in system
- ⚠️ Comments say "mock data" for members, photos, news

**Impact:** MEDIUM - Search functionality doesn't work with real data

---

### 4. **Gallery Screen - Mock Data Banner**
**Location:** `lib/features/gallery/presentation/screens/gallery_screen.dart:61,72`

**Issue:** Uses mock data with banner notification

**Current Code:**
```dart
// Mock Data Banner
...
'🔄 Using Mock Data - Gallery API Integration Pending',
```

**Problem:**
- ⚠️ Acknowledged as mock data (good)
- ❌ Still using sample data instead of real API

**Impact:** LOW - Clearly labeled as pending integration

---

## 🟢 LOW ISSUES (Documentation/Future Work)

### 5. **Trips Provider - "My Trips" Returns Empty**
**Location:** `lib/features/trips/presentation/providers/trips_provider.dart:43-50`

**Issue:** getMyTrips always returns empty list

**Current Code:**
```dart
List<TripListItem> getMyTrips(int userId) => trips
    .where((trip) {
      // Since TripListItem doesn't have registered array,
      // we'll need to fetch full trip details or add a isRegistered flag
      // For now, return empty list - will need backend support
      return false;
    })
    .toList();
```

**Problem:**
- ⚠️ Acknowledged limitation (good)
- ❌ "My Trips" tab always shows empty

**Impact:** LOW - Documented limitation awaiting backend support

---

### 6. **Trip Card - isJoined Always False**
**Location:** `lib/features/trips/presentation/screens/trips_list_screen.dart:169,333`

**Issue:** isJoined flag hard-coded to false

**Current Code:**
```dart
isJoined: false, // Will need backend support for this
```

**Problem:**
- ⚠️ Acknowledged limitation (good)
- ❌ Can't show joined status on trip cards

**Impact:** LOW - Documented limitation awaiting backend support

---

## ✅ VERIFIED CLEAN AREAS

### Login Screen
- ✅ **NO mock login code** found
- ✅ **NO hardcoded credentials** found
- ✅ **NO simulation logic** found
- ✅ Uses `authProviderV2.notifier.login()` correctly
- ✅ Minimum 800ms delay is UX enhancement, not mock simulation

### Settings Screen Logout
- ✅ Correctly implements logout: `authProviderV2.notifier.logout()`
- ✅ No fake navigation
- ✅ No mock logic

### Trips List Screen
- ✅ **NO sample data usage** in main trips list
- ✅ Uses `tripsProvider` (connects to real API)
- ✅ Loads data via `ref.read(tripsProvider.notifier).loadTrips()`

### Trips Provider
- ✅ **NO mock data** - connects to `mainApiRepositoryProvider`
- ✅ Calls real API: `repository.getTrips()`
- ✅ Proper error handling and state management

---

## 📋 ACTION ITEMS

### CRITICAL (Must Fix Before Production)

1. **🔴 Fix Profile Screen Logout (HIGH PRIORITY)**
   ```dart
   // File: lib/features/profile/presentation/screens/profile_screen.dart
   // Line: 287-291
   
   // REPLACE:
   onPressed: () {
     Navigator.pop(context);
     // TODO: Implement actual logout
     context.go('/login');
   },
   
   // WITH (same as settings screen):
   onPressed: () async {
     Navigator.pop(context);
     await ref.read(authProviderV2.notifier).logout();
   },
   ```

2. **🔴 Fix Profile Stats (API Integration Needed)**
   - Option A: Connect to backend statistics API
   - Option B: Hide stats section until API ready
   - Option C: Add "Coming Soon" label

### MEDIUM (Should Fix Before Phase 3B)

3. **🟡 Search Screen - Replace Sample Data**
   - Connect to trips API for search
   - Add search endpoint integration
   - Remove SampleTrips import

4. **🟡 Gallery Screen - Complete API Integration**
   - Already acknowledged as pending
   - Lower priority if gallery isn't Phase 3B focus

### LOW (Future Enhancement)

5. **🟢 "My Trips" Logic** - Requires backend API enhancement
6. **🟢 Trip "isJoined" Status** - Requires backend API enhancement

---

## 🎯 INTERFERENCE ANALYSIS

### Fake vs Real - Are They Interfering?

**Profile Screen Logout:**
- ❌ **YES - INTERFERENCE DETECTED**
- Fake logout (profile) coexists with real logout (settings)
- User confusion: Which logout button actually works?
- **Resolution:** Fix profile logout to match settings

**Profile Stats:**
- ⚠️ **PARTIAL INTERFERENCE**
- Shows fake data alongside real user data (name, email, level)
- **Resolution:** Either fetch real stats or hide section

**Search Results:**
- ⚠️ **ISOLATED MOCK**
- Mock data in search doesn't interfere with trips list
- Search is separate feature using sample data
- **Resolution:** Can be fixed independently

**Trips List:**
- ✅ **NO INTERFERENCE**
- Main trips list uses 100% real API data
- No mock data found

---

## 🔍 SIMULATION CODE CHECK

**Early Development Simulation:**
- ✅ **NO simulated login found**
- ✅ **NO simulated logout found** (except profile screen bug)
- ✅ **NO test users/passwords hardcoded**
- ✅ **NO mock authentication logic**

**Login Screen:**
- ✅ 800ms delay is UX enhancement (show loading animation)
- ✅ NOT a simulation - real API call happens immediately

---

## ✅ SUMMARY

**Authentication:**
- ✅ Login screen: CLEAN (real API)
- ❌ Profile logout: BROKEN (fake implementation)
- ✅ Settings logout: CLEAN (real API)

**Trips:**
- ✅ Trips list: CLEAN (real API)
- ❌ Search results: MOCK DATA
- ⚠️ My Trips tab: Empty (documented limitation)

**Profile:**
- ✅ User data: REAL (from auth API)
- ❌ Stats: FAKE (hard-coded numbers)
- ❌ Logout: FAKE (doesn't work)

**Overall Status:**
- **Critical Fixes:** 2 (Profile logout, Profile stats)
- **Medium Fixes:** 2 (Search, Gallery)
- **Low Priority:** 2 (My Trips, isJoined flag)

---

**Recommendation:** Fix critical issues (especially profile logout) before proceeding with Phase 3B.

---

**Report Generated:** Post-Cleanup Mock Code Audit  
**Files Analyzed:** 7 screen files  
**Critical Issues Found:** 2 (Profile screen)  
**Status:** 🟡 **ACTION REQUIRED**
