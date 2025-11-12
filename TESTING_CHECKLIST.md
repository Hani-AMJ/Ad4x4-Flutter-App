# Admin Panel Testing Checklist

**Quick Reference Guide for Testing All 23 Admin Screens**

---

## 🎯 TESTING SESSION SETUP

**Before You Start:**
1. ✅ Ensure you're logged in as admin (Hani)
2. ✅ Have backend API accessible: https://ap.ad4x4.com
3. ✅ Flutter app running (web or APK)
4. ✅ Notepad ready for documenting issues

**Estimated Time:** 3-4 hours for complete testing

---

## ✅ PHASE 1: AUTHENTICATION (10 min)

### [ ] 1. Login & Dashboard
- [ ] Login successfully
- [ ] Navigate to `/admin/dashboard`
- [ ] Verify all menu sections visible
- [ ] Check no error messages

**Expected:** Dashboard loads, all menu items show

---

## ✅ PHASE 2: TRIP MANAGEMENT (60 min)

### [ ] 2. All Trips (`/admin/trips/all`)
- [ ] Trips list loads
- [ ] Filters work (date, status, level)
- [ ] Sorting works
- [ ] Click trip → details load

### [ ] 3. Pending Trips (`/admin/trips/pending`)
- [ ] Pending trips show
- [ ] Approve button works
- [ ] Decline button works
- [ ] Status updates after action

### [ ] 4. Trip Edit (`/admin/trips/:id/edit`)
- [ ] Edit form loads with data
- [ ] Change title, description
- [ ] Save changes
- [ ] Changes persist

### [ ] 5. Registrants (`/admin/trips/:id/registrants`)
- [ ] Registrants list displays
- [ ] Check-in button works
- [ ] Check-out button works
- [ ] Remove member works
- [ ] Add from waitlist works

### [ ] 6. Analytics (`/admin/registration-analytics`)
- [ ] 6 stat cards display
- [ ] Level breakdown shows
- [ ] Export CSV works
- [ ] Export PDF works (if available)

### [ ] 7. Bulk Actions (`/admin/bulk-registrations`)
- [ ] Checkboxes work
- [ ] Select all/deselect all works
- [ ] Bulk approve works
- [ ] Bulk check-in works
- [ ] Send notification works

### [ ] 8. Waitlist (`/admin/waitlist-management`)
- [ ] Waitlist members display
- [ ] Position badges show
- [ ] Drag to reorder works
- [ ] Move to registered works
- [ ] Batch move works

### [ ] 9. Trip Reports (`/admin/trips/:id/reports`)
- [ ] Reports list loads
- [ ] Create report works
- [ ] Report saves successfully
- [ ] Edit report (if supported)

---

## ✅ PHASE 3: CONTENT MODERATION (30 min)

### [ ] 10. Trip Media (`/admin/trip-media`)
- [ ] Photos display in grid
- [ ] Pending tab shows pending photos
- [ ] Approve button works
- [ ] Reject button works
- [ ] Delete button works
- [ ] All tab shows all photos

### [ ] 11. Comments (`/admin/comments-moderation`)
- [ ] Pending comments section loads
- [ ] Flagged comments section loads
- [ ] Approve comment works
- [ ] Reject comment works
- [ ] Edit comment works
- [ ] Ban user works (test 1 day ban)
- [ ] Ban duration selector works

---

## ✅ PHASE 4: MEMBER MANAGEMENT (45 min)

### [ ] 12. Members List (`/admin/members`)
- [ ] Members list loads
- [ ] Search works
- [ ] Filter by level works
- [ ] Sorting works
- [ ] Click member → details load

### [ ] 13. Member Details (`/admin/members/:id`)
- [ ] Profile displays correctly
- [ ] Trip History tab works
- [ ] Logbook tab works
- [ ] Upgrade Requests tab works
- [ ] All tabs load data

### [ ] 14. Member Edit (`/admin/members/:id/edit`)
- [ ] Edit form loads
- [ ] Fields are editable
- [ ] Save works (or note if fails)
- [ ] Cancel works

### [ ] 15. Sign-Off Skills (`/admin/members/:id/sign-off`)
- [ ] Skills list displays
- [ ] Select skill works
- [ ] Sign-off button works
- [ ] Add notes works
- [ ] Status updates after sign-off

### [ ] 16. Create Logbook (`/admin/logbook/create`)
- [ ] Form loads
- [ ] Select member works
- [ ] Select trip works
- [ ] Select skills works
- [ ] Add notes works
- [ ] Save entry works
- [ ] Entry appears in logbook

---

## ✅ PHASE 5: MEETING POINTS (20 min)

### [ ] 17. Meeting Points List (`/admin/meeting-points`)
- [ ] All 20 meeting points load
- [ ] Map displays (if implemented)
- [ ] Click point → details show
- [ ] Quick actions accessible

### [ ] 18. Create/Edit Point (`/admin/meeting-points/new`)
- [ ] Create form loads
- [ ] Enter name and coordinates
- [ ] Map picker works (if implemented)
- [ ] Save new point works
- [ ] New point appears in list
- [ ] Edit works (or note if fails)
- [ ] Delete works (or note if fails)

---

## ✅ PHASE 6: UPGRADE REQUESTS (30 min)

### [ ] 19. Requests List (`/admin/upgrade-requests`)
- [ ] Requests list loads
- [ ] Filter by status works
- [ ] Click request → details load
- [ ] Vote button accessible

### [ ] 20. Request Details (`/admin/upgrade-requests/:id`)
- [ ] Full details display
- [ ] Voting history shows
- [ ] Comments section loads
- [ ] Vote button works
- [ ] Vote records successfully
- [ ] Approve button works
- [ ] Decline button works
- [ ] Add comment works

### [ ] 21. Create Request (`/admin/upgrade-requests/create`)
- [ ] Form loads
- [ ] Select member works
- [ ] Select target level works
- [ ] Add justification works
- [ ] Form validation works
- [ ] Submit works (test mode only)

---

## ✅ PHASE 7: LOGBOOK (15 min)

### [ ] 22. Logbook List (`/admin/logbook`)
- [ ] Entries list loads
- [ ] Filter by member works
- [ ] Filter by skill works
- [ ] Filter by date works
- [ ] Click entry → details show
- [ ] All filters work together

### [ ] 23. Dashboard Quick Stats
- [ ] Return to dashboard
- [ ] Check if stats updated
- [ ] Verify recent activity shows
- [ ] All sections load

---

## 📊 RESULTS SUMMARY

### Test Coverage:
- **Screens Tested:** [ ] / 23
- **Features Working:** [ ] / ~150
- **Issues Found:** [ ]

### Status by Category:
- [ ] Trip Management: ⬜⬜⬜⬜⬜⬜⬜⬜ (8 screens)
- [ ] Content Moderation: ⬜⬜ (2 screens)
- [ ] Member Management: ⬜⬜⬜⬜⬜ (5 screens)
- [ ] Meeting Points: ⬜⬜ (2 screens)
- [ ] Upgrade Requests: ⬜⬜⬜ (3 screens)
- [ ] Logbook: ⬜⬜ (2 screens)
- [ ] Dashboard: ⬜ (1 screen)

---

## 🐛 ISSUES LOG

### Critical Issues (Blocking):
1. _____________________________________
2. _____________________________________

### Major Issues (Important):
1. _____________________________________
2. _____________________________________

### Minor Issues (Nice to fix):
1. _____________________________________
2. _____________________________________

---

## 🔍 BACKEND VERIFICATION

### Endpoints Confirmed Working:
- [ ] `GET /api/trips/` - Get trips
- [ ] `POST /api/trips/:id/approve/` - Approve trip
- [ ] `POST /api/trips/:id/checkin/:memberId/` - Check-in
- [ ] `GET /api/members/` - Get members
- [ ] `GET /api/upgrade-requests/` - Get requests
- [ ] `POST /api/upgrade-requests/:id/vote/` - Vote
- [ ] `GET /api/logbook/` - Get logbook
- [ ] `POST /api/logbook/sign-off/` - Sign off skill
- [ ] `GET /api/comments/all/` - Get comments
- [ ] `POST /api/comments/:id/approve/` - Approve comment
- [ ] `GET /api/media/pending/` - Get pending media
- [ ] `POST /api/media/:id/moderate/` - Moderate photo
- [ ] `GET /api/trips/:id/registration-analytics/` - Analytics
- [ ] `POST /api/trips/:id/bulk-approve/` - Bulk approve
- [ ] `POST /api/trips/:id/waitlist/reorder/` - Reorder waitlist

### Endpoints Needing Backend Implementation:
- [ ] `GET /api/admin/stats/` - Dashboard stats
- [ ] `PATCH /api/members/:id/` - Update member
- [ ] `PATCH /api/meetingpoints/:id/` - Update meeting point
- [ ] `DELETE /api/meetingpoints/:id/` - Delete meeting point
- [ ] `PATCH /api/trips/:id/reports/:reportId/` - Edit report
- [ ] `DELETE /api/trips/:id/reports/:reportId/` - Delete report

---

## 💡 TESTING TIPS

### Good Practices:
✅ Test one feature at a time  
✅ Document exact steps that cause errors  
✅ Take screenshots of issues  
✅ Note the exact error messages  
✅ Test with real data when possible  
✅ Verify data persists after refresh

### Caution Areas:
⚠️ Don't delete real trips (use test data)  
⚠️ Be careful with user bans (use short durations)  
⚠️ Don't approve/decline real upgrade requests  
⚠️ Test member edits on test accounts first  
⚠️ Back up data before bulk operations

---

## 🎯 QUICK TEST MODE

**If you have limited time (30 minutes), test these critical features:**

1. ✅ Login & Dashboard (2 min)
2. ✅ Pending Trips → Approve (5 min)
3. ✅ Trip Registrants → Check-in (5 min)
4. ✅ Bulk Actions → Select & Approve (5 min)
5. ✅ Comments Moderation → Approve (5 min)
6. ✅ Trip Media → Approve (5 min)
7. ✅ Members List → View Details (3 min)

**This covers the most used admin functions.**

---

## 📝 FINAL REPORT

### Overall Assessment:
- **Status:** [ ] Ready for Production / [ ] Needs Fixes / [ ] Major Issues
- **Completion:** ____ %
- **Recommended Action:** _________________________

### Sign-Off:
- **Tested By:** Hani
- **Date:** __________
- **Time Spent:** __________
- **Next Steps:** _________________________

---

**Save this file and mark checkboxes as you test!**
