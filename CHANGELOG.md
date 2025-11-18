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
