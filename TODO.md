# AD4x4 Mobile App - Todo List

> **Note:** This file is synchronized with GitHub Issues  
> For latest updates and discussions, see: https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues

**Last Updated:** November 16, 2024

---

## 🔥 In Progress

*Currently being actively worked on*

### Gallery Integration
- ✅ Documentation complete (Nov 16)
- ✅ GitHub issues created (14 issues, Nov 16)
- 🔄 Awaiting backend team to begin implementation

### Vehicle Modifications System
- ✅ Documentation complete (Nov 16)
- ✅ GitHub issues created (18 issues, Nov 16)
- 🔄 Ready for implementation

---

## 📋 Planned Features - High Priority

### 🚗 Vehicle Modifications System (v2.2)
**Status:** Documentation complete, GitHub issues created  
**Feature Request Date:** November 11, 2025  
**Docs:** `/new_features/vehicle_modifications/`  
**GitHub Issues:** [#15-#32](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues)  
**Estimated:** 44-62 hours total (Backend: 26-36h, Flutter: 18-26h)

#### Key Features
- Dynamic modification choices (backend-driven, no app updates needed)
- Member vehicle modification declarations
- Permission-based verification workflow
- Trip-level vehicle requirements
- Registration validation against requirements
- Level-flexible requirements system

#### Backend Tasks (Django) - 🔴 CRITICAL
- [ ] Create modification_choices table and seed data ([#15](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/15))
- [ ] Add min_level_for_requirements to global_settings ([#16](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/16))
- [ ] Create vehicle_modifications table ([#17](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/17))
- [ ] Create trip_vehicle_requirements table ([#18](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/18))
- [ ] Implement /api/choices/ endpoints (10 types) ([#19](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/19))
- [ ] Implement vehicle modifications CRUD ([#20](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/20))
- [ ] Implement verification queue endpoint ([#21](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/21))
- [ ] Implement verification approve/reject ([#22](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/22))
- [ ] Implement trip requirements CRUD ([#23](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/23))
- [ ] Implement eligibility validation ([#24](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/24))
- [ ] Create permissions setup ([#25](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/25))

**Reference:** `BACKEND_API_DOCUMENTATION.md` (v2.0)  
**Estimated:** 26-36 hours  
**Blocks:** All Flutter vehicle modification features

#### Flutter Tasks (Mobile App) - 🟡 HIGH
- [ ] Create ModificationChoice model ([#26](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/26))
- [ ] Update VehicleModifications model (enums → strings) ([#27](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/27))
- [ ] Create VehicleModificationsApiRepository ([#28](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/28))
- [ ] Create ModificationChoicesProvider (Riverpod) ([#29](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/29))
- [ ] Update UI components to use dynamic choices ([#30](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/30))
- [ ] Migrate from cache service to API ([#31](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/31))
- [ ] Write comprehensive tests ([#32](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/32))

**Reference:** `FLUTTER_IMPLEMENTATION_GUIDE.md` (v2.0)  
**Estimated:** 18-26 hours  
**Dependencies:** Backend tasks must complete first

---

### 🎨 Gallery Integration (v2.0)
**Status:** Documentation complete, ready for implementation  
**Docs:** `/new_features/gallery_integration/`  
**Estimated:** 17-25 hours total

#### Backend Tasks (Django) - 🔴 CRITICAL
- [ ] Add `gallery_id` field to Trip model ([#1](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/1))
- [ ] Create Gallery API service ([#2](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/2))
- [ ] Implement trip lifecycle webhooks ([#3](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/3))
- [ ] Update trip API responses to include `gallery_id` ([#4](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/4))
- [ ] Write unit and integration tests
- [ ] Deploy to staging and production

**Reference:** `GALLERY_INTEGRATION_BACKEND_SPEC.md`  
**GitHub Issues:** [#1](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/1), [#2](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/2), [#3](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/3), [#4](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/4)  
**Estimated:** 6-8 hours  
**Blocks:** All Flutter gallery features

#### Flutter Tasks (Mobile App) - 🟡 HIGH
- [ ] Implement Gallery Admin Tab in trip details ([#5](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/5))
  - Gallery status card
  - Gallery statistics (photo count, uploaders)
  - Action buttons (upload, view, rename, delete)
- [ ] Add upload photos from trip details page ([#6](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/6))
  - Upload button in gallery section
  - Photo picker integration
  - Progress tracking
- [ ] Create "My Gallery" screen ([#7](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/7))
  - Show user's photos grouped by trip
  - View/delete own photos
  - Filter by trip level
- [ ] Add gallery preview section in Trip Details ([#8](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/8))

**Reference:** `GALLERY_INTEGRATION_FLUTTER_WORK.md`  
**GitHub Issues:** [#5](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/5), [#6](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/6), [#7](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/7), [#8](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/8)  
**Estimated:** 12-16 hours  
**Dependencies:** Backend tasks must complete first

---

### ⭐ Trip Rating & MSI System (v2.1)
**Status:** GitHub issues created, ready for planning  
**Docs:** `/new_features/trip_rating_msi_system/`

#### Backend Tasks
- [ ] Create rating and MSI database models ([#9](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/9))
- [ ] Implement MSI calculation engine ([#10](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/10))
- [ ] Create rating submission and retrieval APIs ([#11](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/11))

#### Flutter Tasks
- [ ] Create Trip Rating UI components ([#12](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/12))
- [ ] Implement MSI badge and display system ([#13](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/13))
- [ ] Create MSI Leaderboard screen ([#14](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/14))

**GitHub Issues:** [#9](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/9), [#10](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/10), [#11](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/11), [#12](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/12), [#13](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/13), [#14](https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/14)  
**Reference:** See documentation in `/new_features/trip_rating_msi_system/`

---

## 📋 Backlog - Medium Priority

### Features
- [ ] Photo editing in gallery (crop, rotate, filters)
- [ ] Batch photo operations (multi-select, bulk delete)
- [ ] Gallery analytics dashboard
- [ ] Push notifications for trip updates
- [ ] Offline mode support
- [ ] Export trip data (PDF, Excel)

### Improvements
- [ ] Optimize image loading performance
- [ ] Improve search functionality
- [ ] Add more filter options
- [ ] Enhance error messages
- [ ] Add loading skeletons

---

## 📋 Backlog - Low Priority

### Nice to Have
- [ ] Dark mode customization
- [ ] Multiple language support (Arabic, etc.)
- [ ] Trip templates
- [ ] Calendar integration
- [ ] Weather information
- [ ] Route mapping

---

## 🐛 Known Bugs

*Bugs will be tracked as GitHub Issues*

To report a bug: https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/new?template=bug_report.yml

---

## ✅ Recently Completed

### November 2024
- ✅ Vehicle Modifications System documentation and GitHub issues (18 issues) (Nov 16)
  - Backend API documentation v2.0 with dynamic choices system
  - Flutter implementation guide with migration strategy
  - Complete issue tracking with dependencies
- ✅ GitHub issues created for Gallery Integration and Trip Rating (14 issues) (Nov 16)
- ✅ Complete issue tracking system setup (Nov 16)
  - Issue templates (bug, feature, backend)
  - GitHub labels (19 labels)
  - TODO.md sync with GitHub
  - CHANGELOG.md maintenance
- ✅ Complete Gallery Integration documentation (Nov 16)
  - Backend specification (28 KB)
  - Flutter implementation guide (34 KB)
  - Integration workflow
- ✅ Trip Rating MSI System documentation (Nov 16)
- ✅ Gallery authentication provider (Nov 15)
- ✅ Gallery API repository implementation (Nov 15)
- ✅ Gallery screens (browse, album, upload, favorites, search) (Nov 14)

### October 2024
- ✅ Trip management system
- ✅ User profile and authentication
- ✅ Logbook vehicle tracking
- ✅ Admin panel

---

## 📊 Project Statistics

**Current Version:** 1.5.2  
**Next Release:** v2.0 - Gallery Integration (Target: December 2024)

**Codebase:**
- 214 files
- 78,110 lines of code
- 71 screens
- 15 feature modules

**API Integration:**
- Main API: 134 endpoints (Django)
- Gallery API: 50+ endpoints (Node.js)

---

## 🎯 Milestones

### v2.0 - Gallery Integration (December 2024)
Focus: Complete trip-gallery integration, enable photo sharing

### v2.1 - Trip Rating System (January 2025)
Focus: Member ratings, MSI scoring, leaderboards

### v2.2 - Vehicle Modifications System (February 2025)
Focus: Dynamic modification choices, verification workflow, trip requirements

### v2.3 - Performance & Polish (March 2025)
Focus: Bug fixes, performance optimization, UX improvements

---

## 📞 Contributing

### For Developers

**Backend Tasks:** Check issues labeled `backend`  
**Flutter Tasks:** Check issues labeled `flutter`  
**Documentation:** Check issues labeled `documentation`

**Before starting:**
1. Check if issue already exists
2. Read related documentation in `/new_features/`
3. Comment on issue to claim it
4. Create feature branch: `feature/issue-number-description`
5. Reference issue in commits: `Implements #123`
6. Create PR when ready

**Issue Labels:**
- `bug` - Something broken
- `feature` - New functionality
- `enhancement` - Improvement to existing feature
- `backend` - Django API work
- `flutter` - Mobile app work
- `documentation` - Docs updates
- `priority: critical` - Urgent, blocks other work
- `priority: high` - Important for next release
- `priority: medium` - Should be done soon
- `priority: low` - Nice to have

---

## 🔗 Quick Links

- **GitHub Issues:** https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues
- **GitHub Projects:** https://github.com/Hani-AMJ/Ad4x4-Flutter-App/projects
- **API Documentation:** `/docs/MAIN_API_DOCUMENTATION.md`, `/docs/GALLERY-API-DOCUMENTATION.md`
- **Feature Specs:** `/new_features/`
- **Backend Integration Guide:** `/BACKEND_INTEGRATION.md`

---

**Legend:**
- 🔥 In Progress - Actively being worked on
- 🔴 Critical - Urgent, blocks other work
- 🟡 High - Important for next release
- 🟢 Medium - Should be done soon
- ⚪ Low - Nice to have
- 🐛 Bug - Something broken
- ✨ Feature - New functionality
- 🔧 Backend - Django/API work
- 📱 Flutter - Mobile app work

---

*This TODO list is maintained automatically. For detailed task discussions, use GitHub Issues.*
