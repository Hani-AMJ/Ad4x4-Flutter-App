# Gallery Integration Investigation - Summary for Hani

**Date**: December 2025  
**Investigation**: Trip-Gallery Synchronization Workflow

---

## Quick Answer to Your Questions

### 1. ✅ **Trip Rename → Gallery Album Name?**
**Expected**: YES, should update
- Gallery API has `/api/webhooks/trip/renamed` webhook
- Only updates **auto-created** galleries (not manual ones)
- **Status**: Need Backend Team to confirm Django implementation

### 2. ⚠️ **Trip Level Change → Gallery Level?**
**Current**: NO webhook exists for this
- Gallery API has no `/api/webhooks/trip/level-changed` endpoint
- Album `trip_level` field may get out of sync
- **Recommendation**: Add this webhook to Gallery API

### 3. ✅ **Trip Owner Avatar/Username Change?**
**Answer**: By design, **NO sync needed**
- Gallery albums store **snapshot** of creator info at creation time
- This prevents breaking old albums if user changes profile
- **This is correct behavior** - historical data should be preserved

### 4. ⚠️ **Album Creation Date?**
**Current**: Uses Gallery creation timestamp, NOT trip creation date
- Album `created_at` = When webhook was called
- Trip `created` = When trip was originally created
- **Impact**: Old trips will have recent gallery dates
- **Recommendation**: Add `trip_created_at` field to webhook if needed

### 5. ❓ **Who Handles Webhooks?**
**Answer**: Main Backend (Django) **should** call them
- ✅ Flutter app does NOT call webhooks (correct architecture)
- ❓ Need Backend Team to verify Django implementation
- Gallery API provides all webhooks, just need to be called

---

## What We Found

### ✅ Good News - Architecture is Correct

**Flutter App** (Your Mobile App):
- ✅ Trip model has `galleryId` field (UUID)
- ✅ Shows "View Gallery" button when galleryId exists
- ✅ Navigates to `/gallery/album/{galleryId}` correctly
- ✅ Shows message when gallery doesn't exist yet
- ✅ Does NOT try to call webhooks (correct - that's backend's job)

**Gallery API** (Node.js Media Server):
- ✅ All webhooks are documented and available:
  - `/api/webhooks/trip/published` - Create gallery
  - `/api/webhooks/trip/renamed` - Rename gallery
  - `/api/webhooks/trip/deleted` - Delete gallery
  - `/api/webhooks/trip/restored` - Restore gallery
- ✅ Idempotent - safe to call multiple times
- ✅ Only updates auto-created galleries (protects manual ones)

**Main API** (Django Backend):
- ✅ Has `/api/trips/{id}/bind-gallery` endpoint
- ✅ Trip model has `galleryId` field
- ❓ **Unknown**: Are webhooks actually being called?

### ❓ Unknown - Need Backend Team to Verify

**Critical Questions for Your Backend Team:**

1. When trip is published (approval_status = 'A'), does Django call `/webhooks/trip/published`?
2. After gallery is created, does Django store the returned `galleryId` in trip model?
3. When trip is renamed, does Django call `/webhooks/trip/renamed`?
4. When trip is deleted, does Django call `/webhooks/trip/deleted`?

**These are the most important questions to answer.**

---

## Expected Workflow (How It Should Work)

### Scenario: Publishing a New Trip

```
USER APPROVES TRIP
       ↓
Django Backend detects approval_status → 'A'
       ↓
Django calls: POST /api/webhooks/trip/published
{
  "trip_id": 123,
  "title": "Desert Safari",
  "creator_id": 10613,
  "creator_username": "Hani AMJ",
  "creator_avatar": "https://...",
  "level": 2
}
       ↓
Gallery API creates album automatically
       ↓
Gallery API returns:
{
  "success": true,
  "gallery": {
    "id": "abc-123-uuid",  ← This is the galleryId
    "name": "Desert Safari",
    "auto_created": true
  }
}
       ↓
Django calls: POST /api/trips/123/bind-gallery
{
  "gallery_id": "abc-123-uuid"
}
       ↓
Django stores galleryId in trip model
       ↓
DONE - Trip now linked to gallery!
```

### Scenario: Renaming a Trip

```
USER RENAMES TRIP
       ↓
Django Backend updates trip title
       ↓
Django calls: POST /api/webhooks/trip/renamed
{
  "trip_id": 123,
  "new_title": "Desert Safari - Updated"
}
       ↓
Gallery API updates album name (if auto-created)
       ↓
Gallery API returns:
{
  "success": true,
  "updated": true,  ← true if renamed, false if manual gallery
  "gallery_id": "abc-123-uuid"
}
       ↓
DONE - Album name synced!
```

---

## What's Missing

### 🔴 HIGH PRIORITY

**Trip Level Change Synchronization**
- **Problem**: No webhook exists for level changes
- **Impact**: Album `trip_level` field gets out of sync
- **Example**: 
  - Trip changes from "Intermediate" (level 2) to "Advanced" (level 3)
  - Gallery album still shows trip_level = 2
- **Recommendation**: Add new webhook to Gallery API

### 🟡 MEDIUM PRIORITY

**Album Creation Date Mismatch**
- **Problem**: Album uses current date, not trip creation date
- **Impact**: Old migrated trips have recent album dates
- **Example**:
  - Trip created: 2018-10-10
  - Album created: 2025-11-29 (when webhook first called)
- **Recommendation**: Add `trip_created_at` field to webhook

---

## Recommendations

### For Backend Team (Django)

**VERIFY these webhook calls are implemented:**

```python
# 1. When trip is published
def on_trip_published(trip):
    response = requests.post(
        'https://media.ad4x4.com/api/webhooks/trip/published',
        json={
            'trip_id': trip.id,
            'title': trip.title,
            'creator_id': trip.lead.id,
            'creator_username': trip.lead.username,
            'creator_avatar': trip.lead.profile_image,
            'level': trip.level.id
        }
    )
    if response.ok:
        gallery_id = response.json()['gallery']['id']
        trip.gallery_id = gallery_id
        trip.save()

# 2. When trip is renamed
def on_trip_renamed(trip):
    if trip.gallery_id:
        requests.post(
            'https://media.ad4x4.com/api/webhooks/trip/renamed',
            json={'trip_id': trip.id, 'new_title': trip.title}
        )

# 3. When trip is deleted
def on_trip_deleted(trip):
    if trip.gallery_id:
        requests.post(
            'https://media.ad4x4.com/api/webhooks/trip/deleted',
            json={'trip_id': trip.id}
        )
```

### For Gallery Backend Team (Node.js)

**OPTIONAL: Add new webhook for level changes:**

```javascript
// POST /api/webhooks/trip/level-changed
router.post('/webhooks/trip/level-changed', async (req, res) => {
  const { trip_id, new_level } = req.body;
  
  const gallery = await db.galleries.findOne({
    where: { source_trip_id: trip_id, auto_created: 1 }
  });
  
  if (gallery) {
    gallery.trip_level = new_level;
    await gallery.save();
    return res.json({ success: true, updated: true });
  }
  
  return res.json({ success: true, updated: false });
});
```

---

## Testing Plan

### For Backend Team

**Test 1: Trip Publication**
1. Create a new trip
2. Approve it (set approval_status = 'A')
3. **Expected**: Gallery album auto-created
4. **Verify**: trip.gallery_id is populated
5. **Verify**: Album name matches trip title

**Test 2: Trip Rename**
1. Approve a trip (now has gallery)
2. Rename the trip title
3. **Expected**: Gallery album name updated
4. **Verify**: Album name matches new trip title

**Test 3: Trip Level Change**
1. Approve a trip (now has gallery)
2. Change trip difficulty level
3. **Current**: Album trip_level NOT updated (no webhook)
4. **Action**: Decide if this needs fixing

**Test 4: Trip Deletion**
1. Approve a trip (now has gallery)
2. Delete the trip
3. **Expected**: Gallery album soft-deleted
4. **Verify**: Album has `soft_deleted_at` timestamp

---

## Summary

### ✅ What's Working
- Flutter app correctly reads and displays gallery links
- Gallery API has all necessary webhooks
- Architecture design is correct

### ❓ What's Unknown
- Are Django webhooks actually implemented?
- Need backend team to verify

### ⚠️ What's Missing
- Webhook for trip level changes
- Album creation date doesn't match trip creation date

### 🎯 Next Steps
1. **URGENT**: Ask backend team to verify webhook implementation
2. **HIGH**: Test trip publication → gallery creation
3. **MEDIUM**: Consider adding trip level change webhook
4. **LOW**: Decide if album creation date mismatch matters

---

**Bottom Line**: The integration **design is perfect**, but we need to verify the Django backend is actually calling the webhooks. All the pieces are in place - we just need confirmation they're being used.

**Action Required**: Share this with your backend team and ask them to verify the webhook calls in their Django code.

---

**Investigator**: Friday  
**Client**: Hani AMJ  
**Report Date**: December 2025
