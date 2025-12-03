# Member Profile Page Enhancement Analysis

## Current Issues Identified

### 1. ❌ **Avatar, Name, and Rank Cropped at Bottom**

**Location**: Lines 144-213 in `member_details_screen.dart`

**Problem**: The `SliverAppBar` with `expandedHeight: 200` doesn't provide enough vertical space for:
- User avatar (radius: 50 = 100px diameter)
- Name text (headlineSmall)
- Level badge (with padding)
- Top SafeArea padding (40px)

**Current Layout**:
```dart
SliverAppBar(
  expandedHeight: 200,  // ❌ Too small - causes cropping
  flexibleSpace: FlexibleSpaceBar(
    background: Column(
      children: [
        SizedBox(height: 40),  // SafeArea
        UserAvatar(radius: 50),  // 100px
        SizedBox(height: 12),
        Text(memberName),  // ~30px
        SizedBox(height: 6),
        LevelBadge(),  // ~40px with padding
        // TOTAL: ~228px needed, but only 200px available!
      ],
    ),
  ),
)
```

**Fix Needed**: Increase `expandedHeight` to 250-280px

---

### 2. ❌ **Level Displayed as Numeric Value Instead of Name**

**Location**: Lines 232-238 in `member_details_screen.dart`

**Problem**: The "Level" stat card shows numeric value (`800`, `100`, etc.) instead of human-readable name:

```dart
_StatCard(
  icon: Icons.star,
  label: 'Level',
  value: '${member.level?.numericLevel ?? 0}',  // ❌ Shows "800" instead of "Board member"
  color: const Color(0xFFFFB74D),
)
```

**What User Sees**: "Level: 800" ❌  
**What User Should See**: "Level: Board member" ✅

**Data Available**:
- `member.level.name` - e.g., "Board member"
- `member.level.displayName` - e.g., "Board member" (preferred)
- `member.level.numericLevel` - e.g., 800

**Fix Needed**: Change to `member.level?.displayName ?? member.level?.name ?? 'Member'`

---

### 3. ❌ **Recent Trips Showing PENDING Trips Instead of COMPLETED**

**Location**: Lines 76-112 in `member_details_screen.dart`

**Problem**: The trip history API (`getMemberTripHistory`) returns ALL trips, but the code doesn't filter by status. Looking at the API response example:

```json
{
  "results": [
    {
      "id": 6295,
      "title": "Int Test Trip",
      "startTime": "2025-11-28T12:06:00",
      "endTime": "2025-11-28T13:06:00",
      "checkedIn": true  // ✅ This indicates completed trips
    }
  ]
}
```

**Current Code**:
```dart
Future<void> _loadTripHistory(int memberId) async {
  final response = await _repository.getMemberTripHistory(
    memberId: memberId,
    page: 1,
    pageSize: 10,
  );
  // ❌ No filtering - shows ALL trips including pending
}
```

**The Issue**: The API parameter `checkedIn` is available but not being used!

**API Documentation** (line 4926):
- `checkedIn` (query) - boolean - Optional - **Include only trips where member is checked in**

**Fix Options**:
1. **Option A**: Filter in API call using `checkedIn: true`
2. **Option B**: Filter in Flutter after fetching (check trip status)
3. **Option C**: Use both - fetch completed trips AND filter by `status == 'completed'`

**Recommended Fix**: Use `checkedIn: true` parameter + filter by end time

---

### 4. 🔍 **Additional Enhancements from API Documentation**

After reviewing `/docs/MAIN_API_DOCUMENTATION.md`, here are additional member profile enhancements we can implement:

#### **A. Member Statistics** (Not Currently Shown)

**API Available**: `GET /api/members/{id}/tripcounts`
```json
{
  "totalTrips": 41,
  "tripsByLevel": {
    "Newbie": 15,
    "Intermediate": 20,
    "Advanced": 6
  },
  "completionRate": 95.5
}
```

**Enhancement**: Add a "Trip Statistics" section showing:
- Trips by level breakdown
- Completion rate
- Recent activity

---

#### **B. Member Feedback/Ratings** (Not Currently Shown)

**API Available**: `GET /api/members/{id}/feedback`
```json
{
  "results": [
    {
      "rating": 5,
      "comment": "Great trip leader!",
      "created": "2024-11-13T14:25:00Z"
    }
  ]
}
```

**Enhancement**: Add "Member Feedback" section (if feedback exists)

---

#### **C. Upgrade History** (Not Currently Shown)

**API Available**: `GET /api/members/{id}/upgraderequests`
```json
{
  "results": [
    {
      "requestedLevel": "Expert",
      "currentLevel": "Advanced", 
      "status": "APPROVED",
      "created": "2024-11-13T10:30:00Z"
    }
  ]
}
```

**Enhancement**: Add "Level Progress" section showing upgrade history

---

#### **D. Trip Requests** (Not Currently Shown)

**API Available**: `GET /api/members/{id}/triprequests`

**Enhancement**: Show trips the member has requested (member requesting a marshal to publish a trip of a specific level)

---

#### **E. Membership Status** (Partially Shown)

**Current**: Only shows "Paid" vs "Free" in stat card

**Enhancement Ideas**:
- Show membership expiry date (if available)
- Show member since date (`dateJoined`)
- Show membership tier/benefits

---

## Recommended Enhancement Priority

### **Phase 1: Critical Fixes** (Fix Now)
1. ✅ **Fix avatar/name/badge cropping** - Increase expandedHeight to 280px
2. ✅ **Display level name instead of number** - Use displayName/name
3. ✅ **Show completed trips only** - Use `checkedIn: true` + status filter

### **Phase 2: UI Improvements** (Recommended)
4. ✅ **Add trip statistics section** - Show trips by level breakdown
5. ✅ **Show member since date** - Display join date prominently
6. ✅ **Improve vehicle display** - Show car image if available

### **Phase 3: Advanced Features** (Approved - Implement Now)
7. ✅ **Member feedback section** - Show ratings and reviews
8. ✅ **Upgrade history timeline** - Visual level progression
9. ✅ **Trip requests section** - Show trips member has requested from marshals

---

## Implementation Plan

### **Fix #1: Avatar Cropping**
```dart
SliverAppBar(
  expandedHeight: 280,  // ✅ Increased from 200
  pinned: true,
  // ... rest stays the same
)
```

### **Fix #2: Level Name Display**
```dart
_StatCard(
  icon: Icons.star,
  label: 'Level',
  value: member.level?.displayName ?? member.level?.name ?? 'Member',  // ✅ Show name
  color: LevelDisplayHelper.getLevelColor(member.level?.numericLevel ?? 0),  // ✅ Dynamic color
)
```

### **Fix #3: Completed Trips Only**
```dart
Future<void> _loadTripHistory(int memberId) async {
  final response = await _repository.getMemberTripHistory(
    memberId: memberId,
    checkedIn: true,  // ✅ Only checked-in trips
    page: 1,
    pageSize: 10,
  );

  // ✅ Additional filter: Only show completed trips
  final trips = [];
  for (var item in data) {
    final trip = TripListItem.fromJson(item);
    if (trip.status == 'completed' || DateTime.now().isAfter(trip.endTime)) {
      trips.add(trip);
    }
  }
}
```

### **Enhancement #1: Trip Statistics Section**

Add new API call:
```dart
Future<Map<String, dynamic>> _loadTripStatistics(int memberId) async {
  final response = await _repository.getMemberTripCounts(memberId);
  return response['data'] ?? response;
}
```

Add new UI section:
```dart
// Trip Statistics Section
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trip Statistics', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        // Trips by level breakdown
        _TripStatisticsCard(statistics: _tripStats),
      ],
    ),
  ),
)
```

### **Enhancement #2: Member Since Date**

Add to header area:
```dart
Text(
  'Member since ${_formatMemberSinceDate(member.dateJoined)}',
  style: TextStyle(
    color: Colors.grey[400],
    fontSize: 13,
  ),
)
```

---

## API Endpoints Summary

| Endpoint | Purpose | Status |
|----------|---------|--------|
| `GET /api/members/{id}` | Member profile | ✅ Currently used |
| `GET /api/members/{id}/triphistory` | Trip history | ✅ Currently used (needs filter fix) |
| `GET /api/members/{id}/tripcounts` | Trip statistics | ❌ Not used (recommended) |
| `GET /api/members/{id}/feedback` | Member ratings | ❌ Not used (optional) |
| `GET /api/members/{id}/upgraderequests` | Upgrade history | ❌ Not used (optional) |
| `GET /api/members/{id}/triprequests` | Trip requests | ❌ Not used (optional) |

---

## Files to Modify

### **Primary Files**:
1. `/lib/features/members/presentation/screens/member_details_screen.dart` - Main member profile UI
2. `/lib/data/repositories/main_api_repository.dart` - Add `getMemberTripCounts()` method

### **Helper Files**:
3. `/lib/core/utils/level_display_helper.dart` - Already has color/icon helpers (no changes needed)
4. `/lib/data/models/user_model.dart` - Already has UserLevel model (no changes needed)
5. `/lib/data/models/trip_model.dart` - Already has TripListItem model (no changes needed)

---

## Design Mockup (Text-Based)

```
┌────────────────────────────────────┐
│  ← [Back]              Member Profile │
├────────────────────────────────────┤
│                                    │
│         [Profile Picture]          │  ← 280px height (fixed cropping)
│                                    │
│        Salah Shahaltogh           │
│      [Board member badge]         │  ← Not cropped anymore
│                                    │
├────────────────────────────────────┤
│  [🚗 54 Trips] [⭐ Board] [💎 Free]│  ← Shows "Board member" not "800"
├────────────────────────────────────┤
│  Vehicle Information               │
│  🚗 Jeep RUBICON (2013)           │
├────────────────────────────────────┤
│  Trip Statistics                   │  ← NEW SECTION
│  📊 Newbie: 20 | Intermediate: 15 │
│     Advanced: 10 | Expert: 9      │
├────────────────────────────────────┤
│  Recent Trips (Completed Only)    │  ← FILTERED
│  ✅ Newbie @ Khaznah              │
│     Mar 19, 2022   [COMPLETED]    │  ← Only completed trips shown
├────────────────────────────────────┤
│  Member Since                      │  ← NEW
│  Joined: January 15, 2020         │
└────────────────────────────────────┘
```

---

## Summary

**Critical Issues Found**: 3  
**Enhancement Opportunities**: 6  
**APIs to Utilize**: 6 total (1 currently used correctly, 1 needs filter fix, 4 not used)

**Recommended Implementation Time**:
- Phase 1 (Critical Fixes): 20-30 minutes
- Phase 2 (UI Improvements): 30-45 minutes
- Phase 3 (Advanced Features): 60-90 minutes

**Total Estimated Time**: 2-3 hours for complete enhancement

---

## Next Steps

1. **Review this analysis** with stakeholders
2. **Prioritize fixes** (recommend Phase 1 + Phase 2)
3. **Approve implementation plan**
4. **Begin coding** after approval

**Ready to implement pending your approval!** ✅
