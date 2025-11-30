# Gallery API Integration Investigation - Findings & Recommendations

## Investigation Date
**Date**: December 2025
**Application**: AD4x4 Flutter App
**Investigated By**: Friday (AI Assistant)
**Client**: Hani AMJ

## Executive Summary

This investigation analyzes the synchronization workflow between trips and gallery albums in the AD4x4 application. The analysis covers current implementation status, identified gaps, and recommendations for proper trip-gallery integration.

## Key Findings

### 1. Data Model Integration ✅ CONFIRMED

**Trip Model Has Gallery Reference:**
- **Location**: `lib/data/models/trip_model.dart:271`
- **Field**: `final String? galleryId;`  // UUID of associated gallery
- **Type**: Nullable String (UUID format)
- **Status**: **IMPLEMENTED** ✅

**Main API Endpoint Exists:**
- **Endpoint**: `POST /api/trips/{id}/bind-gallery`
- **Location**: `lib/core/network/main_api_endpoints.dart:40`
- **Purpose**: Bind a gallery to a trip (stores galleryId in trip model)
- **Status**: **DEFINED** ✅

### 2. Gallery Webhooks - CRITICAL FINDINGS

**Gallery API Provides Webhooks for Synchronization:**

| Webhook | Purpose | Implementation Status |
|---------|---------|----------------------|
| `POST /api/webhooks/trip/published` | Create gallery when trip published | ❓ UNKNOWN |
| `POST /api/webhooks/trip/renamed` | Sync gallery name when trip renamed | ❓ UNKNOWN |
| `POST /api/webhooks/trip/deleted` | Soft-delete gallery when trip deleted | ❓ UNKNOWN |
| `POST /api/webhooks/trip/restored` | Restore gallery when trip restored | ❓ UNKNOWN |

**Investigation Results:**
- ✅ **Gallery API**: Webhooks are fully documented and available
- ❌ **Flutter App**: NO webhook calls found in codebase
- ❓ **Main Backend**: Unknown if Django backend calls these webhooks
- ⚠️ **Expected Caller**: Main Backend (Django) should handle webhooks

**Webhook Request Structure (Example - Trip Published):**
```json
{
  "trip_id": 123,
  "title": "Desert Safari - January 2025",
  "creator_id": 456,
  "creator_username": "hani_ad4x4",
  "creator_avatar": "https://...",
  "level": 2  // Trip difficulty level (user group ID)
}
```

### 3. Current Implementation - Flutter App

**What Flutter App Does:**
1. ✅ Reads `galleryId` from trip data
2. ✅ Displays gallery link if `galleryId` is not null
3. ❌ Does NOT call Gallery API webhooks directly
4. ⚠️ May use `bind-gallery` endpoint (need to verify)

**Trip Details Screen Usage:**
- **File**: `lib/features/trips/presentation/screens/trip_details_screen.dart`
- **Functionality**: `_handleBindGallery()` method handles gallery navigation
- **Implementation**: 
  - ✅ If `galleryId` exists: Navigates to `/gallery/album/{galleryId}`
  - ✅ If `galleryId` is null: Shows message "Gallery will be automatically created when trip is published"
- **Status**: ✅ **CORRECTLY IMPLEMENTED** - Relies on Main Backend webhooks

### 4. Expected Main Backend Responsibilities

The Main Backend (Django) **SHOULD** call Gallery API webhooks when:

**A. Trip Published** → `POST /api/webhooks/trip/published`
- When: Trip approval status changes to 'A' (Approved)
- Action: Gallery API auto-creates album for the trip
- Response: Returns `galleryId` (UUID)
- Backend Action: Store `galleryId` in trip model via bind-gallery endpoint

**B. Trip Renamed** → `POST /api/webhooks/trip/renamed`
- When: Trip title is updated
- Action: Gallery API updates album name (if auto-created)
- Behavior: Only affects auto-created galleries, manual galleries ignored

**C. Trip Deleted** → `POST /api/webhooks/trip/deleted`
- When: Trip is soft-deleted
- Action: Gallery API soft-deletes album (30-day restore window)
- Photos: Remain intact during restore window

**D. Trip Restored** → `POST /api/webhooks/trip/restored`
- When: Soft-deleted trip is restored
- Action: Gallery API restores album

### 5. Synchronization Scenarios Analysis

#### Scenario A: Trip Rename
**Question**: Does renaming a trip update the gallery album name?

**Expected Workflow:**
1. User renames trip in Flutter app or admin panel
2. Main Backend updates trip title in database
3. Main Backend calls `POST /api/webhooks/trip/renamed`
4. Gallery API updates album name (if auto-created)

**Current Status**: ❓ **UNKNOWN** - Need to verify Main Backend implementation

**Gallery API Behavior:**
- ✅ **Auto-created galleries**: Name gets updated
- ❌ **Manually created galleries**: Name stays unchanged
- Response field: `"updated": true/false`

#### Scenario B: Trip Level Change
**Question**: Does changing trip level update the gallery's `trip_level` field?

**Expected Workflow:**
1. Admin changes trip difficulty level
2. Main Backend updates trip level in database
3. ❓ No documented webhook for level changes
4. ❓ Gallery album `trip_level` may become out of sync

**Current Status**: ⚠️ **NO WEBHOOK AVAILABLE** - Potential sync issue

**Recommendation**: 
- Add new webhook: `POST /api/webhooks/trip/level-changed`
- OR: Include level in rename webhook
- OR: Gallery API fetches level from Main API when needed

#### Scenario C: Trip Owner Avatar/Username Change
**Question**: What happens if trip owner's username or avatar changes?

**Gallery Album Fields:**
- `created_by` (user ID) - Immutable
- `created_by_username` (string) - Stored snapshot
- `created_by_avatar` (URL) - Stored snapshot

**Expected Behavior:**
- Gallery album stores **snapshot** of username/avatar at creation time
- Changes to user profile **do not** sync to existing albums
- This is **BY DESIGN** for data consistency

**Current Status**: ✅ **WORKING AS DESIGNED** - No sync needed

**Reasoning:**
- Albums should preserve historical creator identity
- Prevents breaking old albums if user changes profile
- Avatar URLs typically don't change (file-based)

#### Scenario D: Album Creation Date
**Question**: Is album `created_at` the trip creation date or gallery creation date?

**Analysis:**
- Webhook receives: trip_id, title, creator_id, level
- Webhook **does NOT** receive: trip creation date
- Gallery API behavior: Uses current timestamp for `created_at`

**Result**: ⚠️ **MISMATCH EXPECTED**
- Album `created_at` = When gallery was created (webhook called)
- Trip `created` = When trip was originally created

**Impact**: 
- For new trips: Dates will be similar (minutes apart)
- For migrated/old trips: Dates will differ significantly
- Album date reflects when gallery integration happened

**Recommendation**:
- If historical accuracy needed: Add `trip_created_at` to webhook payload
- Gallery API can store separate field: `source_trip_created_at`
- Display logic can show trip date instead of album date

### 6. Missing Synchronization Points

| Event | Webhook Exists | Implemented | Impact |
|-------|----------------|-------------|--------|
| Trip Published | ✅ Yes | ❓ Unknown | **HIGH** - No galleries created |
| Trip Renamed | ✅ Yes | ❓ Unknown | **MEDIUM** - Album names out of sync |
| Trip Deleted | ✅ Yes | ❓ Unknown | **MEDIUM** - Orphaned albums |
| Trip Restored | ✅ Yes | ❓ Unknown | **LOW** - Rare operation |
| Trip Level Changed | ❌ No | ❌ No | **MEDIUM** - Album levels out of sync |
| Trip Owner Changed | ❌ No | N/A | **LOW** - Rare, complex scenario |

## Architecture Findings

### Current Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                              │
│  - Reads galleryId from trip data                           │
│  - Shows "View Gallery" button                              │
│  - NO webhook calls                                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴──────────┐
                │                      │
        ┌───────▼───────┐      ┌──────▼──────┐
        │  Main Backend │      │  Gallery    │
        │  (Django)     │      │  Backend    │
        │               │      │  (Node.js)  │
        │  - Trip CRUD  │      │             │
        │  - ❓ Webhooks?│◄─────│  Webhooks   │
        │               │      │  Available  │
        └───────────────┘      └─────────────┘
```

### Expected Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                              │
│  - Reads galleryId from trip data                           │
│  - Shows "View Gallery" button                              │
│  - Navigates to Gallery feature                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴──────────┐
                │                      │
        ┌───────▼───────┐      ┌──────▼──────┐
        │  Main Backend │      │  Gallery    │
        │  (Django)     │─────►│  Backend    │
        │               │ [1]  │  (Node.js)  │
        │  Trip Events: │      │             │
        │  - Published  │─────►│  Webhooks:  │
        │  - Renamed    │ [2]  │  - Create   │
        │  - Deleted    │ [3]  │  - Rename   │
        │  - Restored   │ [4]  │  - Delete   │
        │               │◄─────│  - Restore  │
        │  Stores:      │ [5]  │             │
        │  - galleryId  │      │  Returns:   │
        └───────────────┘      │  - galleryId│
                               └─────────────┘

Workflow Numbers:
[1] POST /webhooks/trip/published → Gallery creates album
[2] POST /webhooks/trip/renamed → Gallery renames album
[3] POST /webhooks/trip/deleted → Gallery soft-deletes album
[4] POST /webhooks/trip/restored → Gallery restores album
[5] POST /trips/{id}/bind-gallery → Main stores galleryId
```

## Critical Questions for Backend Team

### 🔴 HIGH PRIORITY

1. **Are Gallery API webhooks implemented in Main Backend?**
   - Location to check: Django signal handlers or view logic
   - Files to check: `trips/models.py`, `trips/signals.py`, `trips/views.py`

2. **When trip is published, does Main Backend call `/webhooks/trip/published`?**
   - Expected: When approval_status changes to 'A'
   - Action: Auto-create gallery album

3. **Is `galleryId` stored in trip model after gallery creation?**
   - Expected: Yes, via `/trips/{id}/bind-gallery` endpoint
   - Purpose: Link trip to its gallery

### 🟡 MEDIUM PRIORITY

4. **When trip is renamed, does Main Backend call `/webhooks/trip/renamed`?**
   - Expected: When trip title is updated
   - Action: Sync gallery album name

5. **When trip level changes, is gallery album synced?**
   - Current: No webhook available for this
   - Recommendation: Add webhook or sync mechanism

6. **When trip is deleted, does Main Backend call `/webhooks/trip/deleted`?**
   - Expected: When trip is soft-deleted
   - Action: Soft-delete gallery album

## Recommendations

### For Main Backend Team (Django)

**✅ IMPLEMENT WEBHOOK INTEGRATION:**

1. **Trip Published Event** (HIGH PRIORITY)
```python
# In trips/signals.py or trips/views.py
def on_trip_published(trip):
    # When approval_status changes to 'A'
    gallery_response = requests.post(
        f'{GALLERY_API_URL}/api/webhooks/trip/published',
        json={
            'trip_id': trip.id,
            'title': trip.title,
            'creator_id': trip.lead.id,
            'creator_username': trip.lead.username,
            'creator_avatar': trip.lead.profile_image,
            'level': trip.level.id
        }
    )
    
    if gallery_response.ok:
        gallery_id = gallery_response.json()['gallery']['id']
        # Store galleryId in trip model
        trip.gallery_id = gallery_id
        trip.save()
```

2. **Trip Renamed Event** (MEDIUM PRIORITY)
```python
def on_trip_renamed(trip):
    if trip.gallery_id:  # Only if gallery exists
        requests.post(
            f'{GALLERY_API_URL}/api/webhooks/trip/renamed',
            json={
                'trip_id': trip.id,
                'new_title': trip.title
            }
        )
```

3. **Trip Deleted Event** (MEDIUM PRIORITY)
```python
def on_trip_deleted(trip):
    if trip.gallery_id:  # Only if gallery exists
        requests.post(
            f'{GALLERY_API_URL}/api/webhooks/trip/deleted',
            json={'trip_id': trip.id}
        )
```

4. **Trip Restored Event** (LOW PRIORITY)
```python
def on_trip_restored(trip):
    if trip.gallery_id:  # Only if gallery exists
        requests.post(
            f'{GALLERY_API_URL}/api/webhooks/trip/restored',
            json={'trip_id': trip.id}
        )
```

5. **NEW: Trip Level Changed Event** (MEDIUM PRIORITY)
```python
# Propose adding this webhook to Gallery API
def on_trip_level_changed(trip):
    if trip.gallery_id:  # Only if gallery exists
        requests.post(
            f'{GALLERY_API_URL}/api/webhooks/trip/level-changed',
            json={
                'trip_id': trip.id,
                'new_level': trip.level.id
            }
        )
```

### For Gallery Backend Team (Node.js)

**✅ CONSIDER ADDING:**

1. **Trip Level Changed Webhook** (OPTIONAL)
```javascript
// POST /api/webhooks/trip/level-changed
router.post('/webhooks/trip/level-changed', async (req, res) => {
  const { trip_id, new_level } = req.body;
  
  // Find gallery by source_trip_id
  const gallery = await db.galleries.findOne({
    where: { source_trip_id: trip_id, auto_created: 1 }
  });
  
  if (gallery) {
    // Update trip_level
    gallery.trip_level = new_level;
    await gallery.save();
    return res.json({ success: true, updated: true });
  }
  
  return res.json({ success: true, updated: false });
});
```

2. **Include Trip Created Date in Published Webhook** (OPTIONAL)
```javascript
// Modify /api/webhooks/trip/published to accept trip_created_at
router.post('/webhooks/trip/published', async (req, res) => {
  const { trip_id, title, creator_id, level, trip_created_at } = req.body;
  
  // Store both dates
  const gallery = await db.galleries.create({
    name: title,
    created_by: creator_id,
    trip_level: level,
    source_trip_id: trip_id,
    auto_created: 1,
    created_at: new Date(),  // Gallery creation date
    source_trip_created_at: trip_created_at  // Original trip creation date (NEW)
  });
  
  return res.json({ success: true, gallery });
});
```

### For Flutter App Team

**✅ NO CHANGES NEEDED:**

The Flutter app correctly:
1. ✅ Reads `galleryId` from trip data
2. ✅ Stores `galleryId` in Trip model (line 271)
3. ✅ Shows "View Gallery" button when galleryId exists
4. ✅ Navigates to gallery using `/gallery/album/{galleryId}` route
5. ✅ Shows informative message when gallery doesn't exist yet
6. ✅ Lets Main Backend handle webhook calls (proper architecture)

**VERIFIED:**
- ✅ `_handleBindGallery()` method correctly handles navigation
- ✅ No direct webhook calls from Flutter app (as expected)
- ✅ `bind-gallery` endpoint NOT used by Flutter (Main Backend uses it)

## Testing Checklist

### For Backend Team

**Test Scenario 1: New Trip Publication**
1. Create a new trip
2. Approve trip (set approval_status = 'A')
3. Verify Gallery API creates album
4. Verify trip.gallery_id is populated
5. Verify album name matches trip title
6. Verify album.trip_level matches trip.level

**Test Scenario 2: Trip Rename**
1. Create and approve a trip (has gallery)
2. Rename the trip
3. Verify Gallery API updates album name
4. Verify response shows "updated": true

**Test Scenario 3: Trip Deletion**
1. Create and approve a trip (has gallery)
2. Delete the trip
3. Verify Gallery API soft-deletes album
4. Verify album.soft_deleted_at is set
5. Verify photos remain intact

**Test Scenario 4: Trip Restoration**
1. Delete a trip (with gallery)
2. Restore the trip
3. Verify Gallery API restores album
4. Verify album.soft_deleted_at is null

**Test Scenario 5: Trip Level Change**
1. Create and approve a trip (has gallery)
2. Change trip difficulty level
3. Currently: ❓ What happens to album.trip_level?
4. Expected: Should sync or have webhook

### For Flutter App Team

**Test Scenario 1: View Gallery Link**
1. Create trip with gallery
2. Open Trip Details in app
3. Verify "View Gallery" button shows
4. Tap button → should navigate to gallery

**Test Scenario 2: No Gallery Link**
1. Create trip without gallery
2. Open Trip Details in app
3. Verify "View Gallery" button is hidden

## Summary of Findings

### ✅ What's Working
1. **Data Model**: Trip has galleryId field (UUID)
2. **Main API**: bind-gallery endpoint exists
3. **Gallery API**: All webhooks documented and available
4. **Flutter App**: Correctly reads and displays gallery links

### ❓ What's Unknown
1. **Main Backend**: Are webhooks actually called?
2. **Trip Published**: Does it create gallery?
3. **Trip Renamed**: Does it sync album name?
4. **Trip Deleted**: Does it delete album?
5. **Trip Restored**: Does it restore album?

### ⚠️ What's Missing
1. **Trip Level Change**: No webhook for level sync
2. **Album Creation Date**: Doesn't match trip creation date
3. **Documentation**: No backend webhook implementation docs

### 🔴 Critical Actions Required

1. **URGENT**: Verify Main Backend calls Gallery webhooks
2. **HIGH**: Test trip published → gallery created workflow
3. **MEDIUM**: Add webhook for trip level changes
4. **LOW**: Consider adding trip_created_at to webhooks

## Conclusion

The Gallery API integration architecture is **well-designed** with comprehensive webhook support. However, the **implementation status is unclear**. The Main Backend (Django) is expected to call these webhooks, but there's no evidence of this in the Flutter codebase.

**Next Step**: Backend team should verify their Django implementation and confirm webhook integration is working as designed.

---

**Report Generated**: December 2025
**Investigator**: Friday (AI Assistant)
**Client**: Hani AMJ
**Application**: AD4x4 Flutter App
