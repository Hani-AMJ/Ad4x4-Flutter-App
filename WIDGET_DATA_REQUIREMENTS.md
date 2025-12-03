# 📋 Widget Data Requirements - Member Profile Enhancement

**Date**: 2025-01-28  
**Purpose**: Guide for adding test data to verify all new widgets display correctly  
**Target User**: User 259 (or any test user)

---

## 🎯 Overview

The member profile page now has **9 different widget sections**. Some are always visible, others appear only when data exists. This document lists what data needs to be added to test each widget.

---

## ✅ **ALWAYS VISIBLE WIDGETS** (No data needed)

### 1. **Profile Header** (SliverAppBar)
- **Location**: Top of screen
- **Displays**:
  - Avatar with first name initial
  - Full name: `firstName + lastName`
  - Level badge (e.g., "Board member")
  - "Member since" date (if `dateJoined` exists)

**✅ Already works** - Uses basic user profile data

---

### 2. **Stats Cards Row**
- **Location**: Below profile header
- **Displays**:
  - **Trips**: `member.tripCount` (total trips attended)
  - **Level**: `member.level.displayName` (e.g., "Board member")
  - **Status**: "Paid" or "Free" (`member.paidMember` boolean)

**✅ Already works** - Uses basic user profile data

---

### 3. **Recent Trips Section**
- **Location**: Bottom section
- **Displays**: List of trips the member participated in
- **Shows**: Trip title, date, status badge ("COMPLETED", "UPCOMING", etc.)
- **Empty State**: "No Trip History" if no trips

**✅ Already works** - Calls `/api/members/{id}/triphistory?checkedIn=true`

**🔧 FIX APPLIED**: Trip status now shows "COMPLETED" for past trips instead of "PENDING"

---

## ⚠️ **CONDITIONALLY VISIBLE WIDGETS** (Need data to test)

### 4. **Contact Information Section**
- **Location**: After stats cards
- **API Field Requirements**:
  - `email` (string, not null/empty)
  - `phone` (string, not null/empty)

**How to Test**:
```sql
-- Add contact info to user 259
UPDATE members 
SET email = 'user259@example.com',
    phone = '+971501234567'
WHERE id = 259;
```

**Widget Shows When**: At least one of `email` or `phone` is not null/empty

---

### 5. **Vehicle Information Section**
- **Location**: After contact info
- **API Field Requirements**:
  - `carBrand` (string, e.g., "Toyota")
  - `carModel` (string, e.g., "Land Cruiser")
  - `carYear` (integer, optional, e.g., 2020)
  - `carColor` (string, optional, e.g., "White")

**How to Test**:
```sql
-- Add vehicle info to user 259
UPDATE members 
SET car_brand = 'Toyota',
    car_model = 'Land Cruiser',
    car_year = 2020,
    car_color = 'White'
WHERE id = 259;
```

**Widget Shows When**: At least one of `carBrand` or `carModel` is not null

---

### 6. **Trip Statistics Section** ⭐ NEW
- **Location**: After vehicle info
- **API Endpoint**: `GET /api/members/{id}/tripcounts`
- **Widget Code**: `_TripStatisticsCard` (line 923)
- **Loading Method**: `_loadTripStatistics()` (line 145)

**Expected API Response Structure**:
```json
{
  "data": {
    "totalTrips": 42,
    "byLevel": {
      "Newbie": 10,
      "Intermediate": 15,
      "Advanced": 12,
      "Marshal": 5
    }
  }
}
```

**OR Simplified Structure**:
```json
{
  "totalTrips": 42,
  "newbie": 10,
  "intermediate": 15,
  "advanced": 12,
  "marshal": 5
}
```

**How to Test**:
1. Ensure the API endpoint returns trip-level breakdown data
2. Widget displays a card showing trips grouped by difficulty level
3. Shows total count + level-specific counts

**Widget Shows When**: `_tripStatistics != null` (API returns data)

**What Widget Displays**:
- Title: "Trip Statistics"
- Total trips count
- Breakdown by level (Newbie, Intermediate, Advanced, Marshal, etc.)
- Color-coded level badges

---

### 7. **Upgrade History Section** ⭐ NEW
- **Location**: After trip statistics
- **API Endpoint**: `GET /api/members/{id}/upgraderequests`
- **Widget Code**: `_UpgradeHistoryCard` (line 1050)
- **Loading Method**: `_loadUpgradeHistory()` (line 175)

**Expected API Response Structure**:
```json
{
  "count": 3,
  "results": [
    {
      "id": 123,
      "currentLevel": {
        "id": 3,
        "name": "Newbie",
        "displayName": "Newbie"
      },
      "requestedLevel": {
        "id": 4,
        "name": "Intermediate",
        "displayName": "Intermediate"
      },
      "status": "APPROVED",
      "created": "2024-06-15T10:30:00Z"
    },
    {
      "id": 124,
      "currentLevel": {
        "id": 4,
        "name": "Intermediate",
        "displayName": "Intermediate"
      },
      "requestedLevel": {
        "id": 5,
        "name": "Advanced",
        "displayName": "Advanced"
      },
      "status": "APPROVED",
      "created": "2024-12-20T14:45:00Z"
    }
  ]
}
```

**How to Test**:
```sql
-- Add upgrade history for user 259
INSERT INTO member_upgrade_requests (member_id, current_level_id, requested_level_id, status, created)
VALUES 
  (259, 3, 4, 'APPROVED', '2024-06-15 10:30:00'),
  (259, 4, 5, 'APPROVED', '2024-12-20 14:45:00');
```

**Widget Shows When**: `_upgradeHistory.isNotEmpty` (API returns at least one record)

**What Widget Displays**:
- Title: "Upgrade History"
- Timeline of level progressions
- Each card shows: `currentLevel → requestedLevel`
- Status badge (APPROVED/PENDING/REJECTED)
- Date requested

---

### 8. **Trip Requests Section** ⭐ NEW
- **Location**: After upgrade history
- **API Endpoint**: `GET /api/members/{id}/triprequests`
- **Widget Code**: `_TripRequestCard` (line 1173)
- **Loading Method**: `_loadTripRequests()` (line 213)

**Expected API Response Structure**:
```json
{
  "count": 2,
  "results": [
    {
      "id": 456,
      "level": {
        "id": 5,
        "name": "Advanced",
        "displayName": "Advanced"
      },
      "area": "Liwa Desert",
      "date": "2025-02-15",
      "timeOfDay": "Morning",
      "status": "PENDING"
    },
    {
      "id": 457,
      "level": {
        "id": 4,
        "name": "Intermediate",
        "displayName": "Intermediate"
      },
      "area": "Al Ain Mountains",
      "date": "2025-03-01",
      "timeOfDay": "Afternoon",
      "status": "SCHEDULED"
    }
  ]
}
```

**How to Test**:
```sql
-- Add trip requests for user 259
INSERT INTO member_trip_requests (member_id, level_id, area, date, time_of_day, status, created)
VALUES 
  (259, 5, 'Liwa Desert', '2025-02-15', 'Morning', 'PENDING', NOW()),
  (259, 4, 'Al Ain Mountains', '2025-03-01', 'Afternoon', 'SCHEDULED', NOW());
```

**Widget Shows When**: `_tripRequests.isNotEmpty` (API returns at least one record)

**What Widget Displays**:
- Title: "Trip Requests"
- List of trips the member requested to organize/lead
- Each card shows: Level • Area
- Date and time of day
- Status badge (PENDING/SCHEDULED/APPROVED/REJECTED)

**📝 NOTE**: This is for a member requesting to **organize a trip**, not requesting to join one.

---

### 9. **Member Feedback Section** ⭐ NEW
- **Location**: After trip requests
- **API Endpoint**: `GET /api/members/{id}/feedback`
- **Widget Code**: `_MemberFeedbackCard` (line 1286)
- **Loading Method**: `_loadMemberFeedback()` (line 251)

**Expected API Response Structure**:
```json
{
  "count": 2,
  "results": [
    {
      "id": 789,
      "rating": 5,
      "comment": "Great trip leader, very experienced and safety-conscious!",
      "created": "2024-12-28T16:20:00Z",
      "author": {
        "id": 10613,
        "username": "Hani AMJ",
        "firstName": "Hani",
        "lastName": "AMJ"
      }
    },
    {
      "id": 790,
      "rating": 4,
      "comment": "Excellent organization and communication throughout the trip.",
      "created": "2024-11-15T09:30:00Z",
      "author": {
        "id": 12345,
        "username": "john.doe",
        "firstName": "John",
        "lastName": "Doe"
      }
    }
  ]
}
```

**How to Test**:
```sql
-- Add feedback for user 259 (feedback FROM other members ABOUT user 259)
INSERT INTO member_feedback (member_id, author_id, rating, comment, created)
VALUES 
  (259, 10613, 5, 'Great trip leader, very experienced and safety-conscious!', '2024-12-28 16:20:00'),
  (259, 12345, 4, 'Excellent organization and communication throughout the trip.', '2024-11-15 09:30:00');
```

**Widget Shows When**: `_memberFeedback.isNotEmpty` (API returns at least one record)

**What Widget Displays**:
- Title: "Member Feedback"
- List of feedback/ratings received by the member
- Each card shows: Star rating (1-5 stars)
- Comment text
- Author name
- Date submitted

**📝 NOTE**: This is feedback **ABOUT** user 259 from other members, not feedback user 259 submitted.

---

## 🧪 **COMPREHENSIVE TEST DATA SETUP**

To test **ALL widgets** for user 259, run this complete setup:

### SQL Setup Script:
```sql
-- 1. Update basic profile (Contact + Vehicle)
UPDATE members 
SET 
  email = 'user259@ad4x4.com',
  phone = '+971501234567',
  car_brand = 'Toyota',
  car_model = 'Land Cruiser',
  car_year = 2020,
  car_color = 'White'
WHERE id = 259;

-- 2. Add upgrade history (2 approved upgrades)
INSERT INTO member_upgrade_requests (member_id, current_level_id, requested_level_id, status, created)
VALUES 
  (259, 3, 4, 'APPROVED', '2024-06-15 10:30:00'),
  (259, 4, 8, 'APPROVED', '2024-12-20 14:45:00');  -- 8 = Board member

-- 3. Add trip requests (2 requests to organize trips)
INSERT INTO member_trip_requests (member_id, level_id, area, date, time_of_day, status, created)
VALUES 
  (259, 5, 'Liwa Desert', '2025-02-15', 'Morning', 'PENDING', NOW()),
  (259, 4, 'Al Ain Mountains', '2025-03-01', 'Afternoon', 'SCHEDULED', NOW());

-- 4. Add feedback from other members ABOUT user 259
INSERT INTO member_feedback (member_id, author_id, rating, comment, created)
VALUES 
  (259, 10613, 5, 'Great trip leader, very experienced and safety-conscious!', '2024-12-28 16:20:00'),
  (259, 12345, 4, 'Excellent organization and communication throughout the trip.', '2024-11-15 09:30:00');

-- 5. Verify trip history exists (should already have data)
-- Check: SELECT * FROM trip_registrations WHERE member_id = 259 AND checked_in = TRUE;
```

### API Endpoint Verification:
After adding data, verify these endpoints return data:

```bash
# 1. Trip statistics
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://ap.ad4x4.com/api/members/259/tripcounts

# 2. Upgrade history
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://ap.ad4x4.com/api/members/259/upgraderequests

# 3. Trip requests
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://ap.ad4x4.com/api/members/259/triprequests

# 4. Member feedback
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://ap.ad4x4.com/api/members/259/feedback

# 5. Trip history (should already work)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://ap.ad4x4.com/api/members/259/triphistory?checkedIn=true
```

---

## 📊 **EXPECTED RESULTS AFTER DATA SETUP**

### For User 259 Profile, You Should See:

#### **Always Visible** ✅
1. Profile header with avatar, name, level badge
2. Stats cards: Trips (13), Level (Board member), Status
3. Recent trips list with "COMPLETED" badges for past trips

#### **After Adding Data** ✅
4. Contact Information section (email + phone)
5. Vehicle Information section (Toyota Land Cruiser 2020, White)
6. Trip Statistics section (breakdown by level)
7. Upgrade History section (2 approved upgrades timeline)
8. Trip Requests section (2 trip requests: Pending + Scheduled)
9. Member Feedback section (2 feedback ratings with comments)

---

## 🐛 **TROUBLESHOOTING**

### Widget Not Showing?

**Check these common issues**:

1. **API Endpoint Not Found (404)**
   - Verify the endpoint exists in Django backend
   - Check API URL paths in `MainApiEndpoints` class

2. **Empty API Response**
   - Run SQL queries to verify data exists in database
   - Check API response structure matches expected format
   - Look for backend errors in Django logs

3. **Data Structure Mismatch**
   - Check browser console for parsing errors
   - Verify JSON field names match code expectations
   - Add debug logging in `_loadXxx()` methods

4. **Widget Loading Forever**
   - Check for errors in browser console
   - Verify API authentication is working
   - Check for network errors (CORS, timeouts)

### Debug Logging:

To see why a widget isn't appearing, check browser console for these logs:

```
📊 [TripStats] Fetching trip statistics for member 259...
✅ [TripStats] Loaded trip statistics
⬆️ [UpgradeHistory] Fetching upgrade history for member 259...
✅ [UpgradeHistory] Loaded 2 upgrade requests
📝 [TripRequests] Fetching trip requests for member 259...
✅ [TripRequests] Loaded 2 trip requests
💬 [Feedback] Fetching member feedback for member 259...
✅ [Feedback] Loaded 2 feedback records
```

If you see ❌ errors instead, check the error message for details.

---

## 🎯 **QUICK REFERENCE: Widget Visibility Rules**

| Widget | Shows When | API Endpoint | Data Required |
|--------|-----------|--------------|---------------|
| Profile Header | Always | `/api/members/{id}` | Basic profile |
| Stats Cards | Always | `/api/members/{id}` | Basic profile |
| Recent Trips | Always | `/api/members/{id}/triphistory` | Trip registrations |
| Contact Info | If email OR phone exists | `/api/members/{id}` | email, phone |
| Vehicle Info | If carBrand OR carModel exists | `/api/members/{id}` | carBrand, carModel |
| **Trip Statistics** | If API returns data | `/api/members/{id}/tripcounts` | Trip level breakdown |
| **Upgrade History** | If array not empty | `/api/members/{id}/upgraderequests` | Upgrade records |
| **Trip Requests** | If array not empty | `/api/members/{id}/triprequests` | Trip request records |
| **Member Feedback** | If array not empty | `/api/members/{id}/feedback` | Feedback records |

---

## ✅ **FIXES APPLIED IN THIS BUILD**

### Fix #1: Trip Status Badge ✅
- **Issue**: Past trips showed "PENDING" instead of "COMPLETED"
- **Root Cause**: Status logic checked approval_status before dates
- **Fix**: Reordered status logic to check dates FIRST
- **File Changed**: `lib/data/models/trip_model.dart` (line 583-595)
- **Result**: Past trips now show "COMPLETED" badge correctly

### Fix #2: UI Label (Pending)
- **Issue**: "Text Advance" label too long, causes overflow
- **Status**: Unable to locate in current code (may be in API response)
- **Action Required**: Will fix once we identify the exact location

---

## 📝 **SUMMARY**

**Total Widgets**: 9 sections  
**Always Visible**: 3 sections (profile, stats, trips)  
**Conditionally Visible**: 6 sections (contact, vehicle, statistics, upgrades, requests, feedback)  

**To test all widgets**, add:
- ✅ Contact info (email + phone)
- ✅ Vehicle info (car brand/model/year/color)
- ✅ Trip statistics data (backend API must return level breakdown)
- ✅ Upgrade history (2+ upgrade request records)
- ✅ Trip requests (2+ trip request records)
- ✅ Member feedback (2+ feedback records)

**Testing URL**: https://5060-irq33n4be81tpb3bh5d3b-de59bda9.sandbox.novita.ai  
**Target User**: 259 (or any test user ID)

---

**Document Generated**: 2025-01-28  
**Author**: Friday AI Assistant  
**Status**: Ready for testing
