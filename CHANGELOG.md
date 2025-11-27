# Changelog

All notable changes to the AD4x4 Mobile App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added (In Development)
- Vehicle Modifications System v2.0 (Feature Request: November 11, 2025)
  - Backend API documentation with dynamic choices system (38.5 KB)
  - Flutter implementation guide with migration strategy (31.5 KB)
  - Complete GitHub issue tracking (18 issues: 11 backend, 7 Flutter)
  - Dynamic modification choices via API (no app updates needed)
  - Permission-based verification workflow
  - Level-flexible trip requirements system
- Gallery Integration feature documentation and specifications
- Trip Rating MSI System feature documentation
- Complete issue tracking system with GitHub integration
- Project management workflow (TODO.md, issue templates)

---

## [1.6.0] - 2025-11-27

### 🔒 Security - HERE Maps Backend Migration (CRITICAL)

**⚠️ SECURITY FIX**: Migrated HERE Maps geocoding from client-side to secure backend architecture

### Added
- **Backend-Driven HERE Maps Configuration** (Security & Flexibility Upgrade)
  - Configuration loading from Django Admin panel
  - Auto-refresh every 15 minutes from backend
  - Read-only admin screen displaying current backend configuration
  - New API endpoints:
    - `GET /api/settings/here-maps-config/` - Load configuration (public)
    - `POST /api/geocoding/reverse/` - Reverse geocode (authenticated)
  - New repository methods: `getHereMapsConfig()` and `reverseGeocode()`
  - Client-side cache (5 minutes) for performance
  - Backend cache (24 hours) for cost optimization

### Changed
- **HereMapsService - Backend API Integration** (Breaking Change)
  - Removed direct HERE Maps API calls
  - Now calls AD4x4 backend API exclusively
  - Simplified response parsing (backend returns pre-formatted strings)
  - JWT authentication required for geocoding requests
  - Graceful degradation if service unavailable
  
- **HereMapsSettings Model - Backend Configuration** (Breaking Change)
  - Removed `apiKey` field (now secured on backend)
  - Removed `defaultApiKey` constant (security risk eliminated)
  - Added `enabled` field (global toggle from backend)
  - Added `maxFields` field (configurable limit)
  - Added `availableFields` list (all field options)
  - Backend field parsing: `hereMapsEnabled`, `hereMapsSelectedFields`, etc.
  
- **HereMapsSettingsProvider - Auto-Refresh** (Architecture Change)
  - Changed from simple state to AsyncValue state management
  - Auto-loads configuration on provider initialization
  - Periodic refresh every 15 minutes
  - New methods: `refreshSettings()`, `isEnabled()`, `getSettingsOrDefault()`
  - Timer-based auto-refresh mechanism
  
- **Admin HERE Maps Settings Screen - Read-Only Display** (UI Change)
  - Converted from editable form to read-only information display
  - Shows current backend configuration
  - Manual refresh button to check for backend changes
  - Admin instructions for Django Admin panel access
  - Backend management notice prominently displayed

### Removed
- **⚠️ CRITICAL**: Exposed HERE Maps API key (`tLzdVrbRbvWpl_8Em4JbjHxzFMIvIRyMo9xyKn7fBW8`)
  - API key NO LONGER stored in Flutter app
  - API key secured in Django backend environment variables
  - **ACTION REQUIRED**: Backend team must rotate this key immediately
- Client-side API key management UI
- Direct HERE Maps API integration code
- Complex response parsing logic (now handled by backend)

### Security Improvements
- ✅ API key protected server-side (never exposed to clients)
- ✅ JWT authentication required for all geocoding requests
- ✅ Centralized rate limiting on backend
- ✅ Input validation and sanitization on backend
- ✅ Usage monitoring and analytics enabled
- ✅ Configuration changes require Django Admin access only

### Performance Improvements
- ✅ 70%+ cache hit rate expected (backend caching)
- ✅ Faster response times for cached locations
- ✅ Reduced client complexity (simplified parsing)
- ✅ Lower API costs (shared backend cache benefits all users)

### Testing
- ✅ Tested with production credentials (Hani amj / 3213Plugin?)
- ✅ Configuration endpoint verified working
- ✅ Reverse geocoding endpoint verified working
- ✅ Test location: Abu Dhabi (24.4539, 54.3773) → "Abu Dhabi, Al Karamah"
- ✅ Response time: < 1 second
- ✅ All Flutter analyze checks passed

### Documentation
- ✅ Updated `BACKEND_API_DOCUMENTATION.md` with migration completion status
- ✅ Added Flutter migration summary with test results
- ✅ Documented all modified files and changes
- ✅ Backend integration test results documented

### Migration Notes
**Files Modified:**
- `lib/data/models/here_maps_settings.dart` - Backend-driven model
- `lib/core/services/here_maps_service.dart` - Backend API integration
- `lib/core/providers/here_maps_settings_provider.dart` - Auto-refresh provider
- `lib/data/repositories/main_api_repository.dart` - HERE Maps endpoints
- `lib/core/network/main_api_endpoints.dart` - Endpoint constants
- `lib/features/admin/presentation/screens/admin_here_maps_settings_screen.dart` - Read-only UI
- `lib/features/admin/presentation/screens/admin_meeting_point_form_screen.dart` - AsyncValue handling

**Backend Requirements:**
- ✅ Backend API already implemented and operational
- ⚠️ **CRITICAL**: Rotate exposed HERE Maps API key immediately
- Configuration managed via Django Admin panel
- Cache cleanup cron job recommended (daily)

**Next Steps:**
1. Deploy updated Flutter app to TestFlight/Internal Testing
2. Monitor backend API usage and cache hit rates
3. Update any external documentation referencing old implementation
4. Consider implementing rate limiting alerts for abuse prevention

---

## [1.5.3] - 2025-11-27

### Added
- **Certificate Platform Utilities** (Phase 7 Enhancement)
  - Platform-specific certificate generation for mobile and web
  - `certificate_mobile_utils.dart` - Native mobile PDF generation utilities
  - `certificate_web_utils.dart` - Web-compatible PDF generation utilities
  - Improved certificate service architecture with better platform support

### Changed
- **Skills Matrix Progress Card Optimization** (UI/UX Improvement)
  - Reduced overall card height by ~25% for better space efficiency
  - Proportionally reduced padding: 16px → 12px
  - Optimized font sizes for cleaner appearance:
    - "Overall Progress" title: 16px → 13px
    - Progress count: 32px → 24px
    - Percentage text: 14px → 12px
  - Reduced progress bar height: 8px → 6px
  - Reduced border radius: 8px → 6px
  - Maintained visual hierarchy and readability
  - More compact design allows better content visibility

- **Login Logo Animation Simplification** (Performance & Stability)
  - Simplified animation from 483 lines to 130 lines (70% code reduction)
  - Replaced complex multi-controller system with single unified controller
  - New subtle animation features:
    - Gentle pulse/glow effect (opacity: 0.3 → 0.6 → 0.3)
    - Smooth scale breathing animation (size: 1.0 → 1.05 → 1.0)
    - 2-second animation cycle with ease-in-out curves
  - Removed complex features that caused rendering issues:
    - 8 AnimationControllers (corona, float, rotation, entrance, shimmer, sparkle)
    - Multiple pulsing corona rings system
    - Particle shimmer effects
    - 3D rotation and floating animations
    - Color shifting effects
    - Sparkle system with random positioning
  - Fixed: Animation now stays centered on all screen sizes (no more breaking on wider screens)
  - Result: Professional appearance, better performance, more stable rendering

- **Level Configuration Service Enhancements** (Phase 7 Backend Integration)
  - Improved async provider with `levelConfigurationReadyProvider`
  - Better cache readiness detection before rendering
  - Enhanced error handling with loading and error states
  - Proper async/await patterns for level data fetching

### Fixed
- **CORS Image Loading for APK Builds** (Build Optimization)
  - Removed custom `CorsImageProvider` (web-only workaround)
  - Removed `ImageProxy` utility (ineffective due to server redirects)
  - Restored simple `Image.network()` throughout the app
  - Cleaned up CORS-related imports and dependencies
  - Rationale: Backend server (`ap.ad4x4.com`) redirects HTTP→HTTPS automatically
  - CORS issues only affect web preview, not production APK builds
  - APK builds work perfectly with standard Flutter image loading
  - Result: Cleaner, simpler codebase with better maintainability

- **Skills Matrix Rendering Performance** (Phase 7 Fix)
  - Fixed level section rendering to wait for cache initialization
  - Improved loading states with proper CircularProgressIndicator
  - Better error states with retry functionality
  - Eliminated race conditions in level configuration loading

### Technical Improvements
- Enhanced certificate generation with platform-specific utilities
- Improved progress tracking widgets with better state management
- Better async/await patterns in level configuration providers
- Optimized widget rebuilds in skills matrix and dashboard screens
- Cleaner code structure with reduced complexity in animation systems

### Changed
- **Trip Reports feature temporarily hidden from UI** (under development)
  - Admin menu items and navigation routes commented out with TODO markers
  - Trip details page report section disabled
  - Admin trips list report badges/buttons hidden
  - All code preserved for easy restoration when ready
  - Feature will be rolled out once end-to-end testing is complete
- Improved documentation structure with `/new_features/` directory
- Enhanced GitHub collaboration setup

### Fixed
- **Trip Reports data loading improvements**
  - Enhanced TripReport model with field name flexibility (supports both `createdBy` and `member` field names)
  - Improved type safety for nested API responses (handles int, Map, and null values correctly)
  - Implemented detail endpoint fetching for complete trip report data
  - Added trip data enrichment in logbook provider for admin list view
  - Fixed "Unknown User" display issue by handling multiple field name formats
  - Fixed empty report content by fetching from detail endpoint
  - Resolved type casting errors with defensive null checking

---

## [1.5.2] - 2024-11-16

### Added
- Complete Gallery API integration documentation (70 KB)
  - Backend specification for Django team
  - Flutter implementation guide with code templates
  - Integration workflow and testing requirements
- Gallery authentication provider with auto-token sync
- Gallery API repository with full CRUD operations
- 6 gallery screens: browse, album, upload, viewer, favorites, search
- Image upload service with progress tracking
- Trip model includes `galleryId` field (ready for backend integration)

### Documentation
- Added `GALLERY_INTEGRATION_BACKEND_SPEC.md` (982 lines)
- Added `GALLERY_INTEGRATION_FLUTTER_WORK.md` (1,155 lines)
- Added Gallery API documentation (2,319 lines)
- Added Main API documentation (5,051 lines)
- Created comprehensive README with architecture overview

---

## [1.5.0] - 2024-11-15

### Added
- Gallery feature infrastructure
  - Gallery auth provider with JWT token management
  - Gallery API repository with 50+ endpoints
  - Auto-authentication sync between Main API and Gallery API
  - Album models and photo models
  - Image URL helper functions

### Changed
- Improved authentication flow with multi-API support
- Enhanced error handling for network operations

---

## [1.4.0] - 2024-11-10

### Added
- Admin panel features
  - Trip management and editing
  - User management
  - Participant management
  - Trip approval workflow
- Admin ribbon component for trip details
- Permission-based UI visibility

### Fixed
- Trip creation approval workflow
- Admin tab controller initialization
- Permission checking in trip edit screen

---

## [1.3.0] - 2024-11-05

### Added
- Logbook feature (7 screens)
  - Vehicle management
  - Modification tracking
  - Upgrade requests
  - Service history
- Vehicle mods test script
- Sample data for development

### Changed
- Improved navigation structure
- Enhanced state management with Riverpod

---

## [1.2.0] - 2024-10-30

### Added
- Trip details screen with comprehensive information display
- Trip participants management
- Trip comments and reports
- Wait list functionality
- Trip check-in system

### Fixed
- Trip details loading issues
- Participant list refresh
- Navigation deep linking

---

## [1.1.0] - 2024-10-20

### Added
- Trip management system
  - Create, view, edit trips
  - Trip filtering and search
  - Trip level system (Easy, Moderate, Hard, Extreme)
  - Meeting point selection
- User profile management
  - Profile viewing and editing
  - Avatar upload
  - User statistics

### Changed
- Improved trip list performance
- Enhanced search functionality
- Better error messages

---

## [1.0.0] - 2024-10-01

### Added
- Initial release
- User authentication (login, register, password reset)
- Home screen with trip listings
- Basic navigation structure
- Material Design 3 theming with brand colors
- JWT authentication with token management
- API client with Dio + Retrofit
- State management with Riverpod
- Routing with GoRouter

### Features
- User registration and login
- Trip browsing
- Basic profile viewing
- Notifications screen (placeholder)
- Settings screen

---

## Version History Summary

| Version | Release Date | Key Features |
|---------|--------------|--------------|
| **1.5.3** | 2025-11-27 | UI optimization, logo animation fix, CORS cleanup |
| **1.5.2** | 2024-11-16 | Gallery integration docs, issue tracking |
| **1.5.0** | 2024-11-15 | Gallery infrastructure, multi-API auth |
| **1.4.0** | 2024-11-10 | Admin panel, permission system |
| **1.3.0** | 2024-11-05 | Logbook feature, vehicle management |
| **1.2.0** | 2024-10-30 | Trip details, participants management |
| **1.1.0** | 2024-10-20 | Trip management, user profiles |
| **1.0.0** | 2024-10-01 | Initial release, authentication |

---

## Upcoming Releases

### [2.0.0] - Planned December 2024
**Theme:** Gallery Integration

#### Planned Features
- Backend gallery webhook integration
- Gallery admin tab in trip details
- Upload photos from trip page
- User's personal gallery view
- Gallery statistics and analytics
- Photo management (delete, rotate)

#### Expected Impact
- Enable photo sharing for all trips
- Improve user engagement
- Streamline trip photo management
- Better content organization

---

### [2.1.0] - Planned January 2025
**Theme:** Trip Rating & Member Scoring

#### Planned Features
- Post-trip rating system
- MSI (Member Score Index) calculation
- Rating history and trends
- Leaderboard system
- Badge achievements

#### Expected Impact
- Gamification of club participation
- Better member engagement tracking
- Recognition of active members
- Improved trip quality through feedback

---

### [2.2.0] - Planned February 2025
**Theme:** Vehicle Modifications System (Feature Request: Nov 11, 2025)

#### Planned Features
- Dynamic modification choices (backend-driven)
  - 10 modification types: lift kit, shocks, arms, tyre size, air intake, catback, horsepower, lights, winch, armor
  - Admin can add/edit/remove options without app updates
  - Supports future localization (Arabic, etc.)
- Member vehicle modification declarations
  - Declare modifications for up to 3 vehicles (configurable)
  - Two verification methods: On-Trip (free) or Expedited (48hrs)
  - Permission-based verification workflow
- Trip vehicle requirements
  - Trip leaders set minimum modification requirements
  - Level-flexible system (configurable threshold)
  - Registration validation against requirements
- Verification queue for authorized users
  - Approve/reject modifications with notes
  - Filter by verification type
  - Bulk processing support

#### Expected Impact
- Maximum backend flexibility (no hardcoded options)
- Future-proof for level system changes
- Better trip safety through requirement validation
- Streamlined verification workflow
- Reduced app update dependencies

#### Technical Highlights
- Extends existing `/api/choices/` API pattern
- Backward compatible migration (enums → strings)
- Permission-based access control (not role-based)
- Comprehensive testing (unit, widget, integration)
- 44-62 hours estimated implementation time

---

## Release Process

### Version Numbering
- **Major (X.0.0):** Breaking changes, major new features
- **Minor (1.X.0):** New features, backward compatible
- **Patch (1.1.X):** Bug fixes, small improvements

### Release Checklist
- [ ] All planned features implemented
- [ ] Unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Flutter analyze with no errors
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in pubspec.yaml
- [ ] Git tag created
- [ ] APK/AAB built and tested
- [ ] Released to production
- [ ] Release notes published

---

## Contributing

See [TODO.md](TODO.md) for current work in progress.

Report bugs: https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/new?template=bug_report.yml

Request features: https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues/new?template=feature_request.yml

---

## Links

- **Repository:** https://github.com/Hani-AMJ/Ad4x4-Flutter-App
- **Issues:** https://github.com/Hani-AMJ/Ad4x4-Flutter-App/issues
- **Documentation:** `/docs/` and `/new_features/`

---

*This changelog is maintained manually. For detailed commit history, see GitHub commits.*
