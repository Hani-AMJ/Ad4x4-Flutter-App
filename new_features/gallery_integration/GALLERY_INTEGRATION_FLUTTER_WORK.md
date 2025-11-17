# Gallery Integration - Flutter Development Work

**Project:** AD4x4 Mobile App - Gallery Feature Completion  
**Date:** November 16, 2024  
**Updated:** January 17, 2025 - Added flexible backend configuration  
**Developer:** Flutter Team  
**Status:** Ready to Start (Pending Backend Integration)

---

## 🎨 Design Philosophy

**Backend-Driven Configuration**: Following the same flexible design philosophy as Vehicle Modifications and Rating Systems:

- ✅ **Gallery API URL loaded from backend** - no hardcoded URLs
- ✅ **Feature flags backend-controlled** (enable/disable gallery system)
- ✅ **Upload limits configurable** (max photo size, supported formats)
- ✅ **Auto-creation behavior from backend** - admins control when galleries are created
- ✅ **Future-ready for multi-region support** and custom gallery servers

**Key Principle:** App loads gallery configuration on startup. Admins can change gallery behavior without app updates.

**🔴 CRITICAL REQUIREMENT:** Must call `GET /api/settings/gallery-config/` on app startup and store configuration globally.

**📄 See Also:** `CRITICAL_FLUTTER_CHANGES_GALLERY.md` for detailed implementation requirements.

---

## 📋 Overview

This document outlines all Flutter development work required to complete the Gallery integration feature. The Gallery backend (Node.js at `https://media.ad4x4.com`) is fully operational and documented. We need to integrate it with the Trip management system and add user-facing features.

**Total Estimated Time:** 14-18 hours (includes configuration system)

---

## 🎯 Feature Requirements

### **User Story:**
> "As a trip owner, when I create a trip, I want a photo gallery to be automatically created for it. I should be able to manage the gallery from the trip details page, and participants should be able to upload photos directly from the trip. Users should also be able to view all their uploaded photos grouped by trip from their profile."

### **Acceptance Criteria:**
1. ✅ When trip is published → Gallery automatically created
2. ✅ Trip details page shows gallery section with upload button
3. ✅ Trip owners can access Gallery Admin tab in admin panel
4. ✅ Users can view "My Gallery" from profile (photos grouped by trip)
5. ✅ Users can delete their own photos
6. ✅ Trip deletion → Gallery soft-deleted with 30-day restore

---

## 🚨 Dependencies

### **CRITICAL: Backend Must Complete First**

Before starting Flutter work, the Django backend team must implement:

1. ✅ Add `gallery_id` field to Trip model responses
2. ✅ Call Gallery API webhooks when trips are created/updated/deleted
3. ✅ Store returned `gallery_id` from Gallery API

**Status Check:** Coordinate with backend team using `GALLERY_INTEGRATION_BACKEND_SPEC.md`

---

## 📦 Phase 1: Gallery Admin Tab in Trip Details (HIGH PRIORITY)

**Estimated Time:** 4-6 hours  
**Priority:** 🔴 High  
**Dependencies:** Backend Phase 1 complete  

### **Location:**
`lib/features/trips/presentation/screens/trip_details_screen.dart`

### **What to Build:**

#### **1.1. Add Gallery Tab to Admin Panel**

Currently the admin panel has tabs: Basic, Participants  
Add new tab: **Gallery**

```dart
// In _buildAdminSection() method around line 1350

TabBar(
  controller: _adminTabController,
  tabs: const [
    Tab(icon: Icon(Icons.edit), text: 'Basic'),
    Tab(icon: Icon(Icons.people), text: 'Participants'),
    Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),  // ADD THIS
  ],
)

// Add corresponding TabBarView page
TabBarView(
  controller: _adminTabController,
  children: [
    _buildBasicInfoTab(trip),
    _buildParticipantsTab(trip),
    _buildGalleryAdminTab(trip),  // ADD THIS
  ],
)
```

#### **1.2. Create Gallery Admin Tab Widget**

**File:** Create `lib/features/trips/presentation/widgets/gallery_admin_tab.dart`

**Features to Implement:**

1. **Gallery Status Card**
   - If no gallery: Show "Gallery will be auto-created when trip is published"
   - If gallery exists: Show "Gallery Linked" with gallery ID
   - If manual creation needed: Show "Create Gallery Now" button

2. **Gallery Statistics**
   - Fetch from: `GET /api/galleries/:galleryId/stats`
   - Display:
     - Total photos count
     - Last upload timestamp
     - Top uploaders (username list)
   - Use `FutureBuilder` with `galleryApiRepository.getGalleryStats()`

3. **Action Buttons**
   - **Upload Photos** → Opens photo picker, uploads to gallery
   - **View Gallery** → Navigate to `/gallery/album/${trip.galleryId}`
   - **Rename Gallery** → Shows dialog to rename (calls Gallery API)
   - **Delete Gallery** → Confirmation dialog, soft-deletes gallery

#### **1.3. Implementation Code Template**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/gallery_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';

class GalleryAdminTab extends ConsumerStatefulWidget {
  final dynamic trip;

  const GalleryAdminTab({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<GalleryAdminTab> createState() => _GalleryAdminTabState();
}

class _GalleryAdminTabState extends ConsumerState<GalleryAdminTab> {
  bool _isLoading = false;
  Map<String, dynamic>? _galleryStats;

  @override
  void initState() {
    super.initState();
    if (widget.trip.galleryId != null) {
      _loadGalleryStats();
    }
  }

  Future<void> _loadGalleryStats() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(galleryApiRepositoryProvider);
      final stats = await repo.getGalleryStats(widget.trip.galleryId!);
      setState(() {
        _galleryStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load gallery stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildGalleryStatusCard(colors),
        SizedBox(height: 16),
        if (widget.trip.galleryId != null) ...[
          _buildGalleryStatsCard(colors),
          SizedBox(height: 16),
          _buildActionsSection(colors),
        ],
      ],
    );
  }

  Widget _buildGalleryStatusCard(ColorScheme colors) {
    if (widget.trip.galleryId == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary),
                  SizedBox(width: 8),
                  Text(
                    'No Gallery Created',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Gallery will be automatically created when trip is published by the backend system.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createGalleryManually,
                icon: Icon(Icons.add),
                label: Text('Create Gallery Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Gallery Linked',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Gallery ID: ${widget.trip.galleryId}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryStatsCard(ColorScheme colors) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_galleryStats == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 48),
              SizedBox(height: 8),
              Text('Unable to load gallery statistics'),
              TextButton(
                onPressed: _loadGalleryStats,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final photoCount = _galleryStats!['photo_count'] ?? 0;
    final lastUpload = _galleryStats!['last_upload_at'];
    final topUploaders = _galleryStats!['top_uploaders'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gallery Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 24),
            _buildStatRow(
              Icons.photo_library,
              'Total Photos',
              '$photoCount',
              colors,
            ),
            SizedBox(height: 12),
            _buildStatRow(
              Icons.upload,
              'Last Upload',
              lastUpload != null
                  ? _formatDateTime(lastUpload)
                  : 'No uploads yet',
              colors,
            ),
            SizedBox(height: 12),
            if (topUploaders.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.people, size: 20, color: colors.primary),
                  SizedBox(width: 8),
                  Text('Top Uploaders:', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              SizedBox(height: 8),
              ...topUploaders.take(3).map((uploader) {
                return Padding(
                  padding: EdgeInsets.only(left: 28, bottom: 4),
                  child: Text(
                    '${uploader['username']} (${uploader['count']} photos)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, ColorScheme colors) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _uploadPhotos,
          icon: Icon(Icons.upload),
          label: Text('Upload Photos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _viewGallery,
          icon: Icon(Icons.photo_library),
          label: Text('View Gallery'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _renameGallery,
          icon: Icon(Icons.edit),
          label: Text('Rename Gallery'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _deleteGallery,
          icon: Icon(Icons.delete_outline),
          label: Text('Delete Gallery'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes} minutes ago';
        }
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _createGalleryManually() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Gallery'),
        content: Text(
          'Create a gallery for this trip manually? This is normally done automatically when trips are published.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(galleryApiRepositoryProvider);
      final result = await repo.createGallery({
        'name': widget.trip.title,
        'trip_level': widget.trip.level?.numericLevel ?? 2,
        'is_public': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery created successfully')),
        );
        // TODO: Update trip with gallery_id via Main API
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create gallery: $e')),
        );
      }
    }
  }

  void _uploadPhotos() {
    context.push(
      '/gallery/upload',
      extra: {
        'galleryId': widget.trip.galleryId,
        'tripTitle': widget.trip.title,
      },
    );
  }

  void _viewGallery() {
    context.push('/gallery/album/${widget.trip.galleryId}');
  }

  Future<void> _renameGallery() async {
    final controller = TextEditingController(text: widget.trip.title);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Gallery'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Gallery Name',
            border: OutlineInputBorder(),
          ),
          maxLength: 255,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == widget.trip.title) return;

    try {
      final repo = ref.read(galleryApiRepositoryProvider);
      await repo.renameGallery(widget.trip.galleryId!, newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery renamed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename gallery: $e')),
        );
      }
    }
  }

  Future<void> _deleteGallery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Gallery?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will soft-delete the gallery and all its photos.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '30-day restore window available',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(galleryApiRepositoryProvider);
      await repo.deleteGallery(widget.trip.galleryId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery deleted (30-day restore window)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete gallery: $e')),
        );
      }
    }
  }
}
```

#### **1.4. Update Trip Details Screen**

**File:** `lib/features/trips/presentation/screens/trip_details_screen.dart`

**Changes needed:**
1. Add `TabController` for admin tabs (change from 2 to 3 tabs)
2. Import the new `GalleryAdminTab` widget
3. Add tab to `TabBar` and `TabBarView`

```dart
// Around line 140 - Update TabController initialization
_adminTabController = TabController(length: 3, vsync: this);  // Change from 2 to 3

// Around line 1350 - Update TabBar
TabBar(
  controller: _adminTabController,
  tabs: const [
    Tab(icon: Icon(Icons.edit), text: 'Basic'),
    Tab(icon: Icon(Icons.people), text: 'Participants'),
    Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),  // ADD
  ],
)

// Around line 1370 - Update TabBarView
TabBarView(
  controller: _adminTabController,
  children: [
    _buildBasicInfoTab(trip),
    _buildParticipantsTab(trip),
    GalleryAdminTab(trip: trip),  // ADD
  ],
)
```

---

## 📦 Phase 2: Upload Photos from Trip Details (HIGH PRIORITY)

**Estimated Time:** 2-3 hours  
**Priority:** 🔴 High  
**Dependencies:** Backend Phase 1 complete

### **Location:**
`lib/features/trips/presentation/screens/trip_details_screen.dart`

### **What to Build:**

#### **2.1. Update Gallery Section in Trip Details**

Currently around line 875, the `_buildGallerySection()` method shows the gallery but doesn't have an upload button for regular users.

**Replace existing section with:**

```dart
Widget _buildGallerySection(BuildContext context, dynamic trip, ColorScheme colors) {
  if (trip.galleryId == null) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No Gallery Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Gallery will be created when trip is published',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: colors.primary),
              SizedBox(width: 8),
              Text(
                'Trip Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Gallery Preview (show first few photos)
          FutureBuilder(
            future: ref.read(galleryApiRepositoryProvider).getGalleryPhotos(
              galleryId: trip.galleryId!,
              limit: 6,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Text(
                  'Unable to load gallery preview',
                  style: TextStyle(color: Colors.grey),
                );
              }

              final photos = snapshot.data!['photos'] as List<dynamic>;
              
              if (photos.isEmpty) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          'No photos yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => context.push('/gallery/album/${trip.galleryId}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://media.ad4x4.com/thumbs/grid/${photo['filename']}',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/gallery/album/${trip.galleryId}'),
                  icon: Icon(Icons.photo_library),
                  label: Text('View All'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _uploadPhotosToTrip(context, trip),
                  icon: Icon(Icons.upload),
                  label: Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

#### **2.2. Implement Upload Photos Method**

Add this method to `TripDetailsScreenState`:

```dart
/// Upload photos to trip gallery
Future<void> _uploadPhotosToTrip(BuildContext context, dynamic trip) async {
  if (trip.galleryId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No gallery linked to this trip')),
    );
    return;
  }

  // Navigate to photo upload screen with trip context
  final result = await context.push<bool>(
    '/gallery/upload',
    extra: {
      'galleryId': trip.galleryId,
      'tripTitle': trip.title,
      'returnToTrip': true,  // Flag to return to trip details after upload
    },
  );

  if (result == true && mounted) {
    // Refresh trip details to show new photos
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photos uploaded successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

#### **2.3. Update Photo Upload Screen**

**File:** `lib/features/gallery/presentation/screens/photo_upload_screen.dart`

**Add support for trip context:**

Around line 46-65, update the widget to accept trip context:

```dart
@override
Widget build(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  
  // Get trip context from navigation extras
  final extras = GoRouterState.of(context).extra as Map<String, dynamic>?;
  final tripTitle = extras?['tripTitle'] as String?;
  final returnToTrip = extras?['returnToTrip'] as bool? ?? false;

  return Scaffold(
    appBar: AppBar(
      title: Text(tripTitle != null ? 'Upload to $tripTitle' : 'Upload Photos'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          if (returnToTrip) {
            context.pop(true);  // Return true to indicate upload completed
          } else {
            context.pop();
          }
        },
      ),
    ),
    // ... rest of widget
  );
}
```

---

## 📦 Phase 3: User's Personal Gallery ("My Gallery") (MEDIUM PRIORITY)

**Estimated Time:** 3-4 hours  
**Priority:** 🟡 Medium  
**Dependencies:** None (uses existing Gallery API)

### **What to Build:**

#### **3.1. Create My Gallery Screen**

**File:** Create `lib/features/gallery/presentation/screens/my_gallery_screen.dart`

This screen shows:
1. All photos uploaded by the current user
2. Photos grouped by trip/gallery
3. Ability to view full gallery
4. Ability to delete own photos

**Full implementation in the code template above (Phase 1, section 3)**

#### **3.2. Update App Router**

**File:** `lib/core/router/app_router.dart`

Around line 271-288, update the gallery route:

```dart
// Change from '/gallery' to '/gallery/browse'
GoRoute(
  path: '/gallery/browse',
  name: RouteNames.galleryBrowse,
  builder: (context, state) => const GalleryScreen(),
),

// Add My Gallery route
GoRoute(
  path: '/gallery/my',
  name: RouteNames.myGallery,
  builder: (context, state) => const MyGalleryScreen(),
),
```

#### **3.3. Update Profile Screen**

**File:** `lib/features/profile/presentation/screens/profile_screen.dart`

Around line 569-572, update the route:

```dart
ListTile(
  leading: Icon(Icons.photo_library),
  title: 'My Gallery',
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push('/gallery/my'),  // Change from '/gallery'
),
```

#### **3.4. Update Photo Count in Profile**

Around line 423, add real photo count from Gallery API:

```dart
// Replace static '0' with FutureBuilder
FutureBuilder(
  future: ref.read(galleryApiRepositoryProvider).getFavoritePhotos(limit: 1),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Text('0');
    final total = snapshot.data!['total'] ?? 0;
    return Text('$total');
  },
)
```

---

## 🧪 Testing Checklist

### **Phase 1: Gallery Admin Tab**
- [ ] Admin tab appears for trip owners
- [ ] Gallery status shows correctly (no gallery vs linked)
- [ ] Statistics load correctly (photo count, last upload, top uploaders)
- [ ] Manual gallery creation works
- [ ] View Gallery button navigates correctly
- [ ] Rename Gallery updates Gallery API and refreshes
- [ ] Delete Gallery shows confirmation and soft-deletes
- [ ] Error states handle API failures gracefully

### **Phase 2: Upload from Trip Details**
- [ ] Upload button appears for all users when gallery exists
- [ ] Photo picker opens correctly
- [ ] Upload progress shows (use Gallery API session)
- [ ] Photos appear in gallery preview after upload
- [ ] Upload from trip details navigates back correctly
- [ ] Error handling for upload failures

### **Phase 3: My Gallery**
- [ ] My Gallery opens from profile
- [ ] Photos grouped by trip correctly
- [ ] Photo count per trip accurate
- [ ] Tap on trip opens full gallery
- [ ] Tap on photo opens full-screen viewer
- [ ] Delete own photo works
- [ ] Empty state shows when no photos
- [ ] Loading states work correctly

---

## 📝 API Integration Reference

### **Gallery API Endpoints to Use:**

```dart
// Get gallery statistics
GET /api/galleries/:galleryId/stats
Response: {
  photo_count: 156,
  last_upload_at: "2025-01-07T14:30:00",
  top_uploaders: [{user_id: 123, username: "hani", count: 89}]
}

// Get gallery photos
GET /api/photos/gallery/:galleryId?limit=6
Response: {
  photos: [{id, filename, gallery_id, uploaded_by_username, ...}],
  pagination: {page, limit, total}
}

// Create gallery manually
POST /api/galleries
Body: {name: "Trip Title", trip_level: 2, is_public: true}
Response: {gallery: {id, name, created_by, ...}}

// Rename gallery
POST /api/galleries/:galleryId/rename
Body: {name: "New Gallery Name"}
Response: {gallery: {id, name, updated_at}}

// Delete gallery (soft delete)
DELETE /api/galleries/:galleryId
Response: {message: "Gallery deleted (30-day restore window)"}

// Get user's favorite photos (for My Gallery)
GET /api/photos/favorites?limit=100
Response: {
  photos: [{id, filename, gallery_name, gallery_id, ...}],
  total: 25
}

// Upload photos
POST /api/photos/upload/session
Body: {gallery_id: "gallery-abc"}
Response: {session_id, max_batch_bytes, expires_at}

POST /api/photos/upload
FormData: photos, gallery_id, session_id
Response: {uploaded: [{id, filename, ...}], failed: []}

// Delete photo
DELETE /api/photos/:photoId
Response: {message: "Photo deleted"}
```

---

## 🎨 UI/UX Guidelines

### **Design Principles:**
1. **Consistent with existing app design** - Use Material Design 3
2. **Loading states** - Always show CircularProgressIndicator during API calls
3. **Error handling** - Show user-friendly error messages with retry option
4. **Empty states** - Clear messaging when no data (no photos, no gallery)
5. **Confirmation dialogs** - Always confirm destructive actions (delete)

### **Color Usage:**
- Primary color for main actions (Upload, View)
- Orange for warnings (30-day restore window)
- Red for destructive actions (Delete)
- Green for success states (Gallery Linked)
- Grey for informational text

### **Icons:**
- `photo_library` - Gallery
- `upload` - Upload photos
- `photo_camera` - Camera/Take photo
- `delete_outline` - Delete
- `edit` - Rename
- `info_outline` - Information
- `check_circle` - Success

---

## 🚀 Deployment Steps

1. **Complete Backend Integration First**
   - Verify backend team completed webhook implementation
   - Test that `gallery_id` appears in trip responses

2. **Implement Features in Order**
   - Phase 1: Gallery Admin Tab (4-6 hours)
   - Phase 2: Upload from Trip Details (2-3 hours)
   - Phase 3: My Gallery (3-4 hours)

3. **Test Each Phase**
   - Unit tests for state management
   - Widget tests for UI components
   - Integration tests for API calls
   - Manual testing on real device

4. **Code Review**
   - Review by senior developer
   - Check error handling
   - Verify API integration
   - Test edge cases

5. **Deploy to Staging**
   - Test with staging Gallery API
   - Verify webhook flow end-to-end
   - Test with real photos

6. **Production Deployment**
   - Deploy to production
   - Monitor error logs
   - Collect user feedback

---

## 📞 Support Contacts

**Backend Team:** For webhook implementation questions  
**Gallery API Docs:** `/home/user/flutter_app/docs/GALLERY-API-DOCUMENTATION.md`  
**Main API Docs:** `/home/user/flutter_app/docs/MAIN_API_DOCUMENTATION.md`  

**Questions?** Check `GALLERY_INTEGRATION_BACKEND_SPEC.md` for backend requirements.

---

**Last Updated:** November 16, 2024  
**Document Version:** 1.0
