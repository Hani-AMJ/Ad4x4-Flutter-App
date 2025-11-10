# 🧪 Comprehensive Validation Test Plan
**Date:** Post Clean Auth V2 & Profile Fix  
**Scope:** Complete System Validation  
**Status:** READY FOR TESTING

---

## 📋 TEST CATEGORIES

1. **Authentication System (Clean V2)**
2. **Profile Screen Logout Fix**
3. **Trips Integration**
4. **Session Persistence**
5. **Router & Navigation**

---

## 🔐 PART 1: AUTHENTICATION SYSTEM TESTS

### **Test 1.1: Fresh Login (No Prior Session)**

**Steps:**
1. Open preview URL in **Incognito/Private window**
2. Should auto-redirect to login screen
3. Enter credentials: `Hani amj` / `3213Plugin?`
4. Click "Sign In" button
5. Wait for loading animation

**Expected Results:**
- ✅ Loading animation shows for minimum 800ms
- ✅ Success message: "Welcome back, Hani amj!"
- ✅ Auto-redirect to home screen
- ✅ Bottom navigation visible

**Check Browser Console (F12):**
```
✅ 🔐 [AuthV2] Initializing...
✅ ✅ [AuthV2] No token found (fresh start)
✅ 🔐 [AuthV2] Login attempt: Hani amj
✅ 🔐 [ApiClient] Adding token to POST /login/
✅ ✅ [AuthV2] Token saved to SharedPreferences
✅ ✅ [AuthV2] Login successful: Hani amj
```

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 1.2: Session Persistence (Auto-Login)**

**Prerequisites:** Complete Test 1.1 (logged in)

**Steps:**
1. After successful login, press **F5** to refresh page
2. Observe behavior

**Expected Results:**
- ✅ Page refreshes
- ✅ **NO redirect to login screen**
- ✅ User stays logged in
- ✅ Home screen displayed immediately

**Check Browser Console (F12):**
```
✅ 🔐 [AuthV2] Initializing...
✅ ✅ [AuthV2] Token found, validating...
✅ ✅ [AuthV2] Session restored: Hani amj
```

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 1.3: Invalid Credentials**

**Prerequisites:** Logged out

**Steps:**
1. Navigate to login screen
2. Enter: `wrong_user` / `wrong_password`
3. Click "Sign In"

**Expected Results:**
- ✅ Loading animation shows
- ✅ Error message displayed (red snackbar)
- ✅ Message: "Invalid username or password." or similar
- ✅ User remains on login screen
- ✅ Can try again

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 🚪 PART 2: LOGOUT TESTS (Critical Fix Validation)

### **Test 2.1: Settings Screen Logout**

**Prerequisites:** Logged in

**Steps:**
1. Navigate to **Settings** screen (bottom nav → gear icon)
2. Scroll down to "Danger Zone"
3. Click **"Sign Out"** button
4. Confirm logout in dialog

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ After confirming, redirect to login screen
- ✅ **Press F5 to refresh**
- ✅ User stays logged out (no auto-login)

**Check Browser Console:**
```
✅ 🔥 [AuthV2] Logout initiated
✅ ✅ [AuthV2] Logout complete
✅ 🔐 [AuthV2] Initializing...
✅ ✅ [AuthV2] No token found (fresh start)
```

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 2.2: Profile Screen Logout (THE CRITICAL FIX)**

**Prerequisites:** Logged in

**Steps:**
1. Navigate to **Profile** screen (bottom nav → person icon)
2. Scroll down to "Account Actions"
3. Click **"Sign Out"** card
4. Confirm logout in dialog
5. **CRITICAL:** Press **F5** to refresh page

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ After confirming, redirect to login screen
- ✅ **CRITICAL:** Press F5 - user STAYS logged out
- ✅ No automatic re-login
- ✅ Behavior MATCHES settings screen logout

**Check Browser Console:**
```
✅ 🔥 [AuthV2] Logout initiated
✅ ✅ [AuthV2] Logout complete
✅ 🔐 [AuthV2] Initializing...
✅ ✅ [AuthV2] No token found (fresh start)
```

**THIS IS THE CRITICAL FIX!**
- **Before Fix:** Would auto-login on refresh ❌
- **After Fix:** Stays logged out on refresh ✅

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 2.3: Logout Consistency Verification**

**Steps:**
1. Login
2. Logout from **Profile** screen
3. Login again
4. Logout from **Settings** screen
5. Compare behavior

**Expected Results:**
- ✅ Both logout buttons work identically
- ✅ Both clear token from storage
- ✅ Both redirect to login
- ✅ Both prevent auto-login on refresh
- ✅ **NO DIFFERENCE** between the two

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 🚗 PART 3: TRIPS INTEGRATION TESTS

### **Test 3.1: Trips List Loads Real Data**

**Prerequisites:** Logged in

**Steps:**
1. Navigate to **Trips** screen (bottom nav)
2. Wait for data to load
3. Observe trips displayed

**Expected Results:**
- ✅ Loading indicator shows briefly
- ✅ Real trips from API displayed
- ✅ **NO "sample" or "mock" labels**
- ✅ Trip cards show real dates
- ✅ Trip cards clickable

**Check Browser Console:**
```
✅ 🔄 Loading trips from API...
✅ ✅ API Response received
✅ 📊 Found [X] trips in response
✅ ✅ Successfully parsed [X] trips
```

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 3.2: Trips Tabs Work**

**Steps:**
1. On Trips screen, click **"All Trips"** tab
2. Click **"Upcoming"** tab
3. Click **"My Trips"** tab

**Expected Results:**
- ✅ All Trips: Shows all trips from API
- ✅ Upcoming: Filters to upcoming trips
- ⚠️ My Trips: Shows empty (known limitation - needs backend)

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 🔄 PART 4: SESSION MANAGEMENT TESTS

### **Test 4.1: Token Expiration Handling**

**Note:** This test requires waiting or manual token deletion

**Steps:**
1. Login successfully
2. Open browser DevTools (F12)
3. Go to **Application → Local Storage**
4. Find `auth_token` key
5. **Delete it manually**
6. Try to navigate to different screens

**Expected Results:**
- ✅ App detects missing token
- ✅ Auto-redirect to login screen
- ✅ No crashes or errors

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 4.2: Multiple Tab Session Sync**

**Steps:**
1. Login in Tab 1
2. Open same preview URL in **Tab 2**
3. Tab 2 should auto-login (session restored)
4. Logout from **Tab 1**
5. Refresh **Tab 2**

**Expected Results:**
- ✅ Tab 2 initially shows logged in state
- ✅ After Tab 1 logout + Tab 2 refresh: Tab 2 shows login screen
- ✅ Shared token cleared affects both tabs

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 🧭 PART 5: ROUTER & NAVIGATION TESTS

### **Test 5.1: Protected Routes**

**Prerequisites:** Logged out

**Steps:**
1. While logged out, try to access:
   - `/trips`
   - `/profile`
   - `/settings`
2. Try typing URL directly in browser

**Expected Results:**
- ✅ All protected routes redirect to `/login`
- ✅ Cannot access authenticated pages while logged out

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 5.2: Auth Routes Redirect When Logged In**

**Prerequisites:** Logged in

**Steps:**
1. While logged in, try to access:
   - `/login`
   - `/register`
   - `/forgot-password`

**Expected Results:**
- ✅ All auth routes redirect to `/` (home)
- ✅ Cannot access login screen while logged in

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 5.3: Debug Page Access (No Auth Required)**

**Steps:**
1. While **logged out**, navigate to `/debug/auth-debug`
2. Should show debug page without redirect

**Expected Results:**
- ✅ Debug page loads without requiring login
- ✅ Shows auth state information
- ✅ Can access debug tools while logged out

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 👤 PART 6: PROFILE SCREEN VALIDATION

### **Test 6.1: Profile Data Displays Real User**

**Prerequisites:** Logged in as "Hani amj"

**Steps:**
1. Navigate to Profile screen
2. Check displayed information

**Expected Results:**
- ✅ Shows real username: "Hani amj"
- ✅ Shows real email from API
- ✅ Shows real user level/role
- ✅ "Member since" displays real date
- ⚠️ Stats show placeholder (24, 156, 1,240) - known issue

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 6.2: Profile Quick Actions Work**

**Steps:**
1. On Profile screen, click each quick action:
   - My Vehicles
   - My Trips
   - My Events
   - My Gallery

**Expected Results:**
- ✅ Each button navigates to correct screen
- ✅ No errors or crashes

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 🐛 PART 7: ERROR HANDLING TESTS

### **Test 7.1: Network Error Handling**

**Steps:**
1. While logged in, disconnect internet
2. Try to load Trips screen
3. Reconnect internet
4. Click retry button

**Expected Results:**
- ✅ Error message displayed
- ✅ Retry button available
- ✅ After reconnect + retry: Data loads successfully

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

### **Test 7.2: API Error Response**

**Prerequisites:** Login with invalid session (expired token)

**Steps:**
1. Manually corrupt token in localStorage
2. Try to load Trips or navigate

**Expected Results:**
- ✅ App detects invalid token
- ✅ Clears corrupted token
- ✅ Redirects to login
- ✅ No infinite loops or crashes

**Status:** ⬜ Not Tested | ✅ Pass | ❌ Fail

---

## 📊 VALIDATION SUMMARY

### **Critical Tests (Must Pass):**
- [ ] Test 1.1: Fresh Login
- [ ] Test 1.2: Session Persistence
- [ ] Test 2.1: Settings Logout
- [ ] **Test 2.2: Profile Logout (THE FIX)** ⭐
- [ ] Test 2.3: Logout Consistency
- [ ] Test 3.1: Trips Real Data

### **Important Tests (Should Pass):**
- [ ] Test 1.3: Invalid Credentials
- [ ] Test 4.1: Token Expiration
- [ ] Test 5.1: Protected Routes
- [ ] Test 6.1: Profile Real Data

### **Optional Tests (Nice to Have):**
- [ ] Test 3.2: Trips Tabs
- [ ] Test 4.2: Multiple Tabs
- [ ] Test 5.2: Auth Routes Redirect
- [ ] Test 7.1: Network Errors

---

## 🎯 ACCEPTANCE CRITERIA

**Minimum Requirements to Pass Validation:**
1. ✅ Login works with real API credentials
2. ✅ Session persists across page refresh
3. ✅ **Profile logout ACTUALLY logs out** (doesn't auto-login on refresh)
4. ✅ Settings logout works same as profile logout
5. ✅ Trips load real data from API
6. ✅ Protected routes redirect to login when logged out

**Known Acceptable Issues:**
- ⚠️ Profile stats show placeholders (documented)
- ⚠️ My Trips tab empty (documented limitation)
- ⚠️ Search uses mock data (lower priority)

---

## 📝 TEST REPORTING

**For Each Test, Record:**
- ✅ **Pass** - Works as expected
- ❌ **Fail** - Does not work, describe issue
- ⚠️ **Partial** - Works with caveats
- ⬜ **Not Tested** - Skipped

**Report Issues With:**
1. Test number and name
2. Steps to reproduce
3. Expected vs actual behavior
4. Browser console errors (if any)
5. Screenshots (if helpful)

---

## 🔗 PREVIEW URL FOR TESTING

**Production Preview:**
https://5060-itvkzz7cz3cmn61dhwbxr-2e77fc33.sandbox.novita.ai

**Test Credentials:**
- Username: `Hani amj`
- Password: `3213Plugin?`

---

**Ready for Validation:** ✅  
**Estimated Test Time:** 15-20 minutes for critical tests  
**Status:** AWAITING USER TESTING

---

**Generated:** Comprehensive Validation Test Plan  
**Critical Tests:** 6  
**Total Tests:** 19  
**Focus:** Authentication V2 & Profile Logout Fix
