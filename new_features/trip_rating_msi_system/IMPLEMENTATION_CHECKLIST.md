# Trip Rating & MSI System - Implementation Checklist

## 📋 Backend Team Checklist

### Phase 1: Database Setup
- [ ] Create `trip_ratings` table migration
- [ ] Add indexes for performance (`trip_id`, `user_id`, `created_at`)
- [ ] Add unique constraint (`trip_id`, `user_id`)
- [ ] Add CHECK constraints for rating values (1-5)
- [ ] Test migration on development database

### Phase 2: Core Models & Validation
- [ ] Create `TripRating` model
- [ ] Implement validation logic:
  - [ ] User must have completed trip
  - [ ] Trip end date must be past
  - [ ] Trip must not be event
  - [ ] User cannot be trip owner
  - [ ] User has not already rated trip
- [ ] Write unit tests for validation

### Phase 3: Member Endpoints
- [ ] `GET /api/trips/pending-ratings/`
  - [ ] Query for unrated completed trips
  - [ ] Exclude events
  - [ ] Exclude trips owned by user
  - [ ] Test with sample data
- [ ] `POST /api/trip-ratings/`
  - [ ] Implement submission logic
  - [ ] Add validation
  - [ ] Test error cases
  - [ ] Test successful submission
- [ ] `GET /api/trips/{id}/ratings-summary/`
  - [ ] Calculate averages
  - [ ] Handle zero ratings (return 0, not error)
  - [ ] Include review list
  - [ ] Test public access

### Phase 4: Admin Endpoints
- [ ] `GET /api/admin/trip-ratings/`
  - [ ] Implement filtering (date, level, leader, score)
  - [ ] Implement sorting
  - [ ] Add pagination
  - [ ] Test with various filters
- [ ] `GET /api/admin/trip-ratings/{id}/`
  - [ ] Add participation statistics
  - [ ] Calculate response rate
  - [ ] Test permission check
- [ ] `GET /api/admin/leader-performance/`
  - [ ] Calculate leader metrics
  - [ ] Implement period filters (YTD, last6months, custom)
  - [ ] Add sorting
  - [ ] Test with sample data
- [ ] `GET /api/admin/leader-performance/{id}/`
  - [ ] Get leader details
  - [ ] Calculate trend data
  - [ ] List recent trips
  - [ ] Test with various periods
- [ ] `GET /api/admin/msi-dashboard-stats/`
  - [ ] Calculate club-wide average
  - [ ] Calculate trend change
  - [ ] Get top 3 leaders
  - [ ] Get top 3 reviewers
  - [ ] Test with YTD period

### Phase 5: Permissions
- [ ] Add `VIEW_TRIP_FEEDBACK` permission
- [ ] Add `VIEW_TRIP_FEEDBACK_DETAILS` permission
- [ ] Add `VIEW_LEADER_PERFORMANCE` permission
- [ ] Test permission checks on admin endpoints
- [ ] Assign permissions to Admin role
- [ ] Assign detail permissions to Board Member role

### Phase 6: Notifications
- [ ] Implement notification creation signal
  - [ ] Trigger on trip completion
  - [ ] Check eligibility
  - [ ] Create notification with metadata
- [ ] Create daily scheduled job
  - [ ] Find pending ratings
  - [ ] Create missing notifications
- [ ] Test notification creation
- [ ] Verify notification appears in app

### Phase 7: Testing
- [ ] Unit tests for all models
- [ ] Unit tests for validation logic
- [ ] Integration tests for all endpoints
- [ ] Test historic data handling (zero ratings)
- [ ] Test permission enforcement
- [ ] Load testing for admin endpoints
- [ ] Test notification creation

### Phase 8: Documentation & Handoff
- [ ] Create Postman collection for all endpoints
- [ ] Add sample requests/responses
- [ ] Document any deviations from spec
- [ ] Create test user accounts
- [ ] Add sample data to staging
- [ ] Notify frontend team

---

## 📋 Frontend Team Checklist

### Phase 1: Setup & Models (Week 1)
- [ ] Review backend API documentation
- [ ] Test all endpoints with Postman
- [ ] Create `TripRatingModel`
- [ ] Create `TripRatingSummaryModel`
- [ ] Create `LeaderPerformanceModel`
- [ ] Create `MSIDashboardStatsModel`
- [ ] Create `TopReviewerModel`
- [ ] Create `PendingTripRatingModel`
- [ ] Write unit tests for models
- [ ] Create `RatingHelper` utility class
- [ ] Update `main_api_endpoints.dart`

### Phase 2: Repository (Week 1)
- [ ] Create `TripRatingRepository`
- [ ] Implement `getPendingRatings()`
- [ ] Implement `submitRating()`
- [ ] Implement `getTripRatingsSummary()`
- [ ] Implement admin methods
- [ ] Test all repository methods
- [ ] Add error handling

### Phase 3: Member Experience (Week 2)
- [ ] Create `TripRatingDialog` widget
  - [ ] Build star rating widget
  - [ ] Add trip info display
  - [ ] Add comment text field
  - [ ] Implement validation
  - [ ] Add loading state
  - [ ] Test submission flow
- [ ] Create `TripRatingCardWidget`
  - [ ] Display rating summary
  - [ ] Color-coded indicator
  - [ ] Show breakdown
- [ ] Update `main.dart`
  - [ ] Add pending ratings check
  - [ ] Show rating dialog sequence
  - [ ] Test on login
- [ ] Update `trip_details_screen.dart`
  - [ ] Add rating summary section
  - [ ] Test rating display
- [ ] Update notification handler
  - [ ] Handle `rate_trip` action
  - [ ] Open rating dialog
  - [ ] Test notification tap

### Phase 4: Admin Overview (Week 3)
- [ ] Create `MSIOverviewScreen`
  - [ ] Build card grid layout
  - [ ] Implement filters
  - [ ] Add sorting dropdown
  - [ ] Add pagination
  - [ ] Test with various filters
- [ ] Create `TripRatingCard` widget
  - [ ] Color-coded background
  - [ ] Display trip info
  - [ ] Show overall score
  - [ ] Add tap navigation
- [ ] Create `TripRatingDetailsScreen`
  - [ ] Build header with trip info
  - [ ] List individual reviews
  - [ ] Make usernames clickable
  - [ ] Show participation stats
  - [ ] Test permission check
- [ ] Create Riverpod providers
  - [ ] `adminTripRatingsProvider`
  - [ ] `tripRatingDetailsProvider`
  - [ ] Test state management

### Phase 5: Leader Performance (Week 4)
- [ ] Create `LeaderPerformanceScreen`
  - [ ] Build card list layout
  - [ ] Implement filters (period, minTrips)
  - [ ] Add sorting
  - [ ] Add pagination
  - [ ] Test with sample data
- [ ] Create `LeaderPerformanceCard` widget
  - [ ] Display leader info
  - [ ] Show performance metrics
  - [ ] Color-coded indicator
  - [ ] Add tap navigation
- [ ] Create `LeaderPerformanceDetailsScreen`
  - [ ] Build header with leader info
  - [ ] Add performance trend chart
  - [ ] List recent trips
  - [ ] Show statistics
  - [ ] Test with various periods
- [ ] Create Riverpod providers
  - [ ] `leaderPerformanceProvider`
  - [ ] `leaderPerformanceDetailsProvider`

### Phase 6: Dashboard Integration (Week 4)
- [ ] Create `MSIDashboardWidget`
  - [ ] Display club-wide average
  - [ ] Show trend indicator
  - [ ] List top 3 leaders
  - [ ] List top 3 reviewers
  - [ ] Add navigation links
- [ ] Update `admin_dashboard_screen.dart`
  - [ ] Add MSI widget
  - [ ] Test data loading
- [ ] Create `msiDashboardStatsProvider`
  - [ ] Test with YTD period

### Phase 7: Navigation & Routes (Week 5)
- [ ] Update `app_router.dart`
  - [ ] Add `/admin/msi` route
  - [ ] Add `/admin/msi/trip/:id` route
  - [ ] Add `/admin/msi/leaders` route
  - [ ] Add `/admin/msi/leader/:id` route
- [ ] Update admin drawer/menu
  - [ ] Add MSI section
  - [ ] Check permission
  - [ ] Test navigation
- [ ] Test all navigation flows

### Phase 8: Polish & Testing (Week 5)
- [ ] Add loading states to all screens
- [ ] Add error handling
- [ ] Add empty states
- [ ] Implement color-coded indicators
- [ ] Test with historic data (zero ratings)
- [ ] Write widget tests
- [ ] Write integration tests
- [ ] Accessibility testing
- [ ] Performance optimization
- [ ] Code review
- [ ] Final QA

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] Model serialization/deserialization
- [ ] Rating calculation logic
- [ ] Color coding logic
- [ ] Validation logic
- [ ] Repository methods

### Widget Tests
- [ ] Trip rating dialog
- [ ] Rating card widgets
- [ ] Dashboard widgets
- [ ] Admin list screens

### Integration Tests
- [ ] Full rating submission flow
- [ ] Pending ratings check on login
- [ ] Notification to rating dialog
- [ ] Admin filtering and sorting
- [ ] Permission enforcement

### Manual Testing
- [ ] Test on Android device
- [ ] Test on web browser
- [ ] Test with multiple pending ratings
- [ ] Test as different user roles
- [ ] Test error scenarios
- [ ] Test with zero ratings (historic data)

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Staging environment tested
- [ ] Performance benchmarks met

### Backend Deployment
- [ ] Run database migration
- [ ] Deploy API to production
- [ ] Verify all endpoints accessible
- [ ] Configure scheduled jobs
- [ ] Set up monitoring

### Frontend Deployment
- [ ] Build production release
- [ ] Deploy to production
- [ ] Verify app loads correctly
- [ ] Test rating submission
- [ ] Test admin screens

### Post-Deployment
- [ ] Monitor error rates
- [ ] Check notification creation
- [ ] Verify permissions work
- [ ] Test performance
- [ ] Gather user feedback

---

## ✅ Definition of Done

### Backend
- ✅ All 9 endpoints implemented and tested
- ✅ Database migration created and run
- ✅ Permissions added to system
- ✅ Notifications created automatically
- ✅ Postman collection provided
- ✅ Unit tests >80% coverage
- ✅ Integration tests passing
- ✅ Deployed to staging
- ✅ Frontend team notified

### Frontend
- ✅ All 6 data models created
- ✅ Repository layer implemented
- ✅ Rating dialog functional
- ✅ Admin screens complete
- ✅ Navigation working
- ✅ All integrations complete
- ✅ Tests passing
- ✅ Code reviewed
- ✅ Deployed to production

### QA
- ✅ All user flows tested
- ✅ Error scenarios handled
- ✅ Performance acceptable
- ✅ No critical bugs
- ✅ Accessibility verified
- ✅ Cross-platform tested

---

## 📊 Progress Tracking

Use this table to track overall progress:

| Phase | Backend Status | Frontend Status | Notes |
|-------|----------------|-----------------|-------|
| Database Setup | ⬜ Not Started | N/A | |
| Core Models | ⬜ Not Started | ⬜ Not Started | |
| Member Endpoints | ⬜ Not Started | N/A | |
| Member UI | N/A | ⬜ Not Started | |
| Admin Endpoints | ⬜ Not Started | N/A | |
| Admin UI | N/A | ⬜ Not Started | |
| Permissions | ⬜ Not Started | N/A | |
| Notifications | ⬜ Not Started | ⬜ Not Started | |
| Testing | ⬜ Not Started | ⬜ Not Started | |
| Deployment | ⬜ Not Started | ⬜ Not Started | |

**Legend:**
- ⬜ Not Started
- 🟡 In Progress
- ✅ Completed
- ❌ Blocked

---

**Update this checklist as you progress through implementation!**
