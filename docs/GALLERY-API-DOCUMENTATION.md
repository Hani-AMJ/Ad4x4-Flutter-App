# AD4x4 Photo Gallery - Complete API Documentation v1.4.0

**Base URL:** `https://media.ad4x4.com`

**Last Updated:** January 7, 2025

**Authentication:** Most endpoints require JWT Bearer token from main backend (`https://ap.ad4x4.com`)

---

## Table of Contents

1. [Overview & Quick Start](#overview--quick-start)
2. [Authentication](#authentication)
3. [Image File Access](#image-file-access)
4. [Core Features](#core-features)
   - [Home & Dashboard](#home--dashboard)
   - [Galleries Management](#galleries-management)
   - [Photos Management](#photos-management)
   - [Favorites](#favorites)
   - [Search & Filter](#search--filter)
5. [Upload System](#upload-system)
6. [Batch Operations](#batch-operations)
7. [Trip Integration Webhooks](#trip-integration-webhooks)
8. [Themes & Personalization](#themes--personalization)
9. [Admin Panel](#admin-panel)
   - [Statistics & Analytics](#statistics--analytics)
   - [Content Management](#content-management)
   - [Maintenance Tools](#maintenance-tools)
   - [Audit Logs](#audit-logs)
   - [Permissions Management](#permissions-management)
   - [System Settings](#system-settings)
   - [Backup & Export](#backup--export)
10. [Error Handling](#error-handling)
11. [Response Codes](#response-codes)
12. [Rate Limiting](#rate-limiting)
13. [Best Practices](#best-practices)

---

## Overview & Quick Start

### What is AD4x4 Gallery?

AD4x4 Gallery is a photo management system for the Abu Dhabi Off-road Club. It provides:

- **Gallery Management**: Create, organize, and share photo albums from trips
- **Photo Uploads**: Batch upload with EXIF extraction and automatic thumbnail generation
- **Favorites**: Personal photo collections
- **Trip Integration**: Auto-create galleries when trips are published
- **Search**: Full-text search across photos and galleries
- **Admin Tools**: Comprehensive management, analytics, and maintenance

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App / Web Client                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴──────────┐
                │                      │
        ┌───────▼───────┐      ┌──────▼──────┐
        │  AD4x4 Main   │      │  AD4x4      │
        │  Backend      │◄─────│  Gallery    │
        │  (Auth)       │      │  Backend    │
        │ ap.ad4x4.com  │      │ media.ad4x4 │
        └───────────────┘      └──────┬──────┘
                                      │
                               ┌──────▼──────┐
                               │   SQLite    │
                               │   Database  │
                               └─────────────┘
```

### Quick Start Example

```javascript
// 1. Login (get token from main backend)
const loginResponse = await fetch('https://media.ad4x4.com/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    login: 'username',
    password: 'password'
  })
});
const { token } = await loginResponse.json();

// 2. Fetch galleries
const galleriesResponse = await fetch('https://media.ad4x4.com/api/galleries', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const galleries = await galleriesResponse.json();

// 3. Get photos from a gallery
const photosResponse = await fetch(`https://media.ad4x4.com/api/photos/gallery/${galleryId}`, {
  headers: { 'Authorization': `Bearer ${token}` }
});
const photos = await photosResponse.json();

// 4. Display photo (no auth needed for images!)
const imageUrl = `https://media.ad4x4.com/thumbs/grid/${photo.filename}`;
// Use in <img src={imageUrl} />
```

---

## Authentication

### Overview

AD4x4 Gallery uses **JWT Bearer tokens** from the main AD4x4 backend for authentication. 

**Authentication Flow:**
1. User provides credentials
2. Gallery API forwards to main backend
3. Main backend validates and returns JWT token
4. Client uses token for subsequent requests

**Important:** 
- ✅ API endpoints require `Authorization: Bearer {token}` header
- ❌ Image/file URLs do NOT require authentication

---

### POST `/api/auth/login`

Login with username/email and password.

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "login": "hani@example.com",
  "password": "your_password"
}
```

**Response (Success):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Failure):**
```json
{
  "success": false,
  "error": "Invalid credentials"
}
```

**Status Codes:**
- `200` - Login successful
- `401` - Invalid credentials
- `500` - Server error

**Notes:**
- Credentials are forwarded to `https://ap.ad4x4.com/api/auth/login/`
- Login attempts are logged to audit system
- Token expires based on main backend configuration

**Example (JavaScript):**
```javascript
async function login(username, password) {
  const response = await fetch('https://media.ad4x4.com/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ login: username, password })
  });
  
  const data = await response.json();
  
  if (data.success) {
    localStorage.setItem('authToken', data.token);
    return data.token;
  } else {
    throw new Error(data.error);
  }
}
```

---

### GET `/api/auth/profile`

Get current user's profile information.

**Request:**
```http
GET /api/auth/profile
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 123,
    "username": "hani_ad4x4",
    "email": "hani@example.com",
    "name": "Hani AMJ",
    "avatar": "https://ap.ad4x4.com/uploads/avatars/hani.jpg",
    "level": "board member",
    "created_at": "2023-01-01T00:00:00Z",
    "gallery_stats": {
      "albums_created": 15,
      "photos_uploaded": 450
    }
  }
}
```

**Status Codes:**
- `200` - Success
- `401` - Invalid or expired token

**Notes:**
- User data comes from main backend
- `gallery_stats` are added by gallery backend
- Avatar URL points to main backend

---

### GET `/health`

Health check endpoint (no authentication required).

**Request:**
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-07T12:00:00Z"
}
```

---

## Image File Access

### ⚠️ CRITICAL: Understanding Image URLs

When you fetch photos from the API, you receive metadata including a `filename` field. **The API does NOT return full image URLs** - you must construct them yourself.

### Image URL Structure

**Base URL:** `https://media.ad4x4.com`

### 1. Full Resolution Images

**URL Pattern:**
```
https://media.ad4x4.com/uploads/{filename}
```

**Example:**
```
https://media.ad4x4.com/uploads/photo-1704636000000-abc123.jpg
```

**Use Cases:**
- Full-screen viewing
- Image downloads
- Lightbox/modal displays
- Print quality
- Detail views

**File Characteristics:**
- Original uploaded image (may be resized based on upload resolution setting)
- Maximum quality preservation
- Original aspect ratio maintained
- EXIF metadata preserved in database (not in file)

---

### 2. Grid View Thumbnails (400x400)

**URL Pattern:**
```
https://media.ad4x4.com/thumbs/grid/{filename}
```

**Example:**
```
https://media.ad4x4.com/thumbs/grid/photo-1704636000000-abc123.jpg
```

**Specifications:**
- **Dimensions:** 400x400 pixels (square)
- **Aspect Ratio:** 1:1 (cropped)
- **Crop Method:** Center crop with cover fit
- **Format:** JPEG
- **Quality:** 80%
- **File Size:** ~20-50KB

**Use Cases:**
- Gallery grid layouts
- Thumbnail browsing
- Image galleries
- Photo selection interfaces

**Mobile Optimization:**
- Recommended for gallery views
- Loads faster than full images
- Reduces bandwidth usage
- Good balance of quality and performance

---

### 3. Card View Thumbnails (1200x675)

**URL Pattern:**
```
https://media.ad4x4.com/thumbs/card/{filename}
```

**Example:**
```
https://media.ad4x4.com/thumbs/card/photo-1704636000000-abc123.jpg
```

**Specifications:**
- **Dimensions:** 1200x675 pixels (landscape)
- **Aspect Ratio:** 16:9
- **Crop Method:** Smart crop using Sharp's attention strategy
  - Automatically detects faces
  - Falls back to areas of visual interest
  - Uses center crop as final fallback
- **Format:** JPEG
- **Quality:** 85%
- **File Size:** ~100-200KB

**Use Cases:**
- Card-style layouts
- Featured images
- Preview images
- Social media sharing
- Blog/article headers

**Smart Cropping:**
The card thumbnail uses intelligent cropping that:
1. Detects faces and keeps them in frame
2. Identifies areas of high visual interest (entropy)
3. Ensures the most important part of the image is visible

---

### 4. List View Thumbnails (120x120)

**URL Pattern:**
```
https://media.ad4x4.com/thumbs/list/{filename}
```

**Example:**
```
https://media.ad4x4.com/thumbs/list/photo-1704636000000-abc123.jpg
```

**Specifications:**
- **Dimensions:** 120x120 pixels (tiny square)
- **Aspect Ratio:** 1:1 (cropped)
- **Crop Method:** Center crop with cover fit
- **Format:** JPEG
- **Quality:** 75%
- **File Size:** ~5-15KB

**Use Cases:**
- List view rows
- Search results
- Activity feeds
- User avatars (for uploaded photos)
- Quick previews

**Mobile Optimization:**
- Extremely fast loading
- Minimal bandwidth usage
- Perfect for infinite scroll lists

---

### Complete Image Helper Function

```javascript
/**
 * Generate all image URLs for a photo object
 * @param {Object} photo - Photo object from API
 * @param {string} photo.filename - Filename from API response
 * @returns {Object} All available image URLs
 */
function getImageUrls(photo) {
  const BASE_URL = 'https://media.ad4x4.com';
  const filename = photo.filename;
  
  return {
    // Full resolution image
    full: `${BASE_URL}/uploads/${filename}`,
    
    // Thumbnail URLs
    thumbnails: {
      grid: `${BASE_URL}/thumbs/grid/${filename}`,    // 400x400
      card: `${BASE_URL}/thumbs/card/${filename}`,    // 1200x675
      list: `${BASE_URL}/thumbs/list/${filename}`     // 120x120
    },
    
    // Metadata
    filename: filename,
    originalName: photo.original_filename,
    size: photo.file_size,
    dimensions: {
      width: photo.width,
      height: photo.height
    }
  };
}

// Usage example
const photo = apiResponse.photos[0];
const urls = getImageUrls(photo);

console.log('Full image:', urls.full);
console.log('Grid thumbnail:', urls.thumbnails.grid);
console.log('Card thumbnail:', urls.thumbnails.card);
console.log('List thumbnail:', urls.thumbnails.list);
```

---

### Mobile App Recommendations

#### Gallery Grid View
```javascript
// Use grid thumbnails for memory efficiency
<FlatList
  data={photos}
  renderItem={({ item }) => (
    <Image 
      source={{ uri: `https://media.ad4x4.com/thumbs/grid/${item.filename}` }}
      style={{ width: 150, height: 150 }}
    />
  )}
/>
```

#### Gallery Card/Feed View
```javascript
// Use card thumbnails for better quality
<ScrollView>
  {photos.map(photo => (
    <Image 
      source={{ uri: `https://media.ad4x4.com/thumbs/card/${photo.filename}` }}
      style={{ width: '100%', aspectRatio: 16/9 }}
      resizeMode="cover"
    />
  ))}
</ScrollView>
```

#### Photo Detail View
```javascript
// Use full resolution for detail
<Modal>
  <Image 
    source={{ uri: `https://media.ad4x4.com/uploads/${photo.filename}` }}
    style={{ width: '100%', height: '100%' }}
    resizeMode="contain"
  />
</Modal>
```

#### List/Search Results
```javascript
// Use list thumbnails for performance
<FlatList
  data={searchResults}
  renderItem={({ item }) => (
    <View style={styles.row}>
      <Image 
        source={{ uri: `https://media.ad4x4.com/thumbs/list/${item.filename}` }}
        style={{ width: 60, height: 60 }}
      />
      <Text>{item.original_filename}</Text>
    </View>
  )}
/>
```

---

### Thumbnail Generation

**Automatic Generation:**
- Thumbnails are automatically generated when photos are uploaded
- All three sizes are created simultaneously
- Generation happens server-side using Sharp library
- If thumbnail generation fails, the upload still succeeds

**Regeneration:**
- Thumbnails can be regenerated via admin maintenance tools
- Rotation operations regenerate thumbnails automatically
- Original images are never modified

---

### Authentication for Images

**⚠️ Important:** Image URLs do NOT require authentication.

```javascript
// ✅ CORRECT - No auth header needed
<img src="https://media.ad4x4.com/uploads/photo-123.jpg" />

// ✅ CORRECT - Direct URL access works
window.open('https://media.ad4x4.com/uploads/photo-123.jpg');

// ❌ WRONG - Don't add Authorization header to images
fetch('https://media.ad4x4.com/uploads/photo-123.jpg', {
  headers: { Authorization: 'Bearer token' }  // Not needed!
});
```

**Why No Authentication?**
- Images are served as static files
- CDN-friendly for performance
- Simplifies mobile app implementation
- Gallery-level access control handled by API

---

### Image Download Endpoint

For programmatic downloads with proper headers:

#### GET `/api/photos/:photoId/download`

**Request:**
```http
GET /api/photos/abc123/download
Authorization: Bearer {token}
```

**Response:**
- Binary image data
- Proper Content-Disposition header for download
- Original filename preserved

**Use Cases:**
- Forcing browser download (not inline display)
- Tracking download statistics
- Mobile app "Save to Gallery" feature

---

### Bandwidth Optimization Tips

**For Mobile Apps:**

1. **Always use thumbnails for lists/grids**
   ```javascript
   // ✅ Good - Uses 20KB thumbnail
   imageUrl = `thumbs/grid/${filename}`;
   
   // ❌ Bad - Loads 2MB full image
   imageUrl = `uploads/${filename}`;
   ```

2. **Progressive loading**
   ```javascript
   // Show thumbnail first, load full image on tap
   <Image 
     source={{ uri: thumbnailUrl }}
     onPress={() => showFullImage(fullUrl)}
   />
   ```

3. **Lazy loading**
   ```javascript
   // Only load images when visible
   <FlatList
     data={photos}
     windowSize={5}  // Only render nearby items
     removeClippedSubviews={true}
   />
   ```

4. **Cache aggressively**
   ```javascript
   // Use image caching library
   import FastImage from 'react-native-fast-image';
   
   <FastImage
     source={{ 
       uri: imageUrl,
       priority: FastImage.priority.normal,
       cache: FastImage.cacheControl.immutable
     }}
   />
   ```

---

### Image URL Summary Table

| Type | Size | Quality | URL Pattern | Use Case |
|------|------|---------|-------------|----------|
| **Full** | Original | 100% | `/uploads/{filename}` | Full screen, download |
| **Grid** | 400x400 | 80% | `/thumbs/grid/{filename}` | Gallery grids |
| **Card** | 1200x675 | 85% | `/thumbs/card/{filename}` | Featured previews |
| **List** | 120x120 | 75% | `/thumbs/list/{filename}` | Lists, search results |

---

## Core Features

### Home & Dashboard

#### GET `/api/home`

Get homepage data including stats, recent photos, top uploaders, and activity feed.

**Request:**
```http
GET /api/home
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "quick_stats": {
      "total_photos": 1250,
      "total_galleries": 45,
      "total_users": 120
    },
    "recent_photos": [
      {
        "id": "photo-123",
        "filename": "photo-1704636000000-abc.jpg",
        "gallery_name": "Desert Safari 2025",
        "gallery_id": "gallery-abc",
        "uploaded_by_username": "hani_ad4x4",
        "uploaded_by_avatar": "https://...",
        "created_at": "2025-01-07T10:30:00"
      }
    ],
    "top_uploaders": [
      {
        "uploaded_by": 123,
        "username": "hani_ad4x4",
        "avatar": "https://...",
        "photo_count": 89
      }
    ],
    "top_downloads": [
      {
        "id": "photo-456",
        "filename": "best-shot.jpg",
        "download_count": 25,
        "uploaded_by_username": "ahmed"
      }
    ],
    "photo_locations": [
      {
        "id": "photo-789",
        "latitude": 25.1234,
        "longitude": 56.5678,
        "location_name": "Wadi Bih"
      }
    ],
    "featured_galleries": [
      {
        "id": "gallery-xyz",
        "name": "Season Opening 2025",
        "photo_count": 120,
        "latest_photo_url": "photo-latest.jpg"
      }
    ],
    "recent_activity": [
      {
        "username": "redbeard",
        "avatar": "https://...",
        "photo_count": 4,
        "gallery_name": "Season Opening 2025",
        "activity_time": "2025-01-07T14:30:00"
      }
    ]
  },
  "settings": {
    "recent_photos_count": 10,
    "top_downloads_count": 5,
    "top_uploaders_count": 5
  }
}
```

**Notes:**
- Counts may return `null` if data hasn't been aggregated
- Activity timestamps are in UTC (convert to local time in frontend)
- Settings control number of items returned

---

### Galleries Management

#### GET `/api/galleries`

Get list of all galleries with optional filtering and sorting.

**Request:**
```http
GET /api/galleries?sort_by=recent-photo&trip_level=moderate&limit=50&page=1
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sort_by` | string | `recent-photo` | Sorting: `recent-photo`, `name`, `newest`, `oldest`, `photo-count` |
| `trip_level` | string | `all` | Filter by trip level: `all`, `easy`, `moderate`, `hard`, `extreme` |
| `limit` | integer | `50` | Items per page (max: 100) |
| `page` | integer | `1` | Page number |

**Response:**
```json
{
  "success": true,
  "galleries": [
    {
      "id": "gallery-abc123",
      "name": "Desert Safari January 2025",
      "description": "Amazing day in the desert",
      "created_by": 123,
      "created_by_username": "hani_ad4x4",
      "created_by_avatar": "https://ap.ad4x4.com/uploads/avatars/hani.jpg",
      "trip_level": 2,
      "trip_level_name": "Moderate",
      "is_public": true,
      "created_at": "2025-01-05T08:00:00",
      "updated_at": "2025-01-07T14:30:00",
      "photo_count": 45,
      "latest_photo_date": "2025-01-07T14:30:00",
      "sample_photos": [
        {
          "id": "photo-1",
          "filename": "photo-170463600-1.jpg"
        },
        {
          "id": "photo-2",
          "filename": "photo-170463600-2.jpg"
        },
        {
          "id": "photo-3",
          "filename": "photo-170463600-3.jpg"
        }
      ],
      "soft_deleted_at": null,
      "source_trip_id": null,
      "auto_created": false
    }
  ],
  "gallery_count": 45,
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 45,
    "has_more": false
  }
}
```

**Sorting Options:**
- `recent-photo` - Galleries with most recent photo uploads
- `name` - Alphabetical by gallery name
- `newest` - Most recently created galleries
- `oldest` - Oldest galleries first
- `photo-count` - Galleries with most photos

**Trip Levels:**
- `1` - Easy
- `2` - Moderate
- `3` - Hard
- `4` - Extreme
- `null` - No trip level assigned

**Notes:**
- Only non-deleted galleries returned (`soft_deleted_at IS NULL`)
- `sample_photos` limited to 3 photos for preview
- Use `photo_count` for displaying gallery size

---

#### POST `/api/galleries`

Create a new gallery.

**Request:**
```http
POST /api/galleries
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Sunset Drive February 2025",
  "description": "Beautiful sunset in the dunes",
  "trip_level": 2,
  "is_public": true
}
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Gallery name (max: 255 chars) |
| `description` | string | No | Gallery description |
| `trip_level` | integer | No | Trip difficulty level (1-4) |
| `is_public` | boolean | No | Public visibility (default: true) |

**Response (Success):**
```json
{
  "success": true,
  "gallery": {
    "id": "gallery-new123",
    "name": "Sunset Drive February 2025",
    "description": "Beautiful sunset in the dunes",
    "created_by": 123,
    "created_by_username": "hani_ad4x4",
    "created_by_avatar": "https://...",
    "trip_level": 2,
    "is_public": true,
    "created_at": "2025-01-07T15:00:00",
    "updated_at": "2025-01-07T15:00:00"
  }
}
```

**Status Codes:**
- `200` - Gallery created successfully
- `400` - Invalid input (name too long, invalid trip_level)
- `401` - Not authenticated
- `500` - Server error

**Notes:**
- Gallery creator is automatically set from authenticated user
- `trip_level` should match user's permission level or below
- Gallery ID is auto-generated UUID

---

#### GET `/api/galleries/:galleryId/stats`

Get statistics for a specific gallery.

**Request:**
```http
GET /api/galleries/gallery-abc123/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "photo_count": 156,
  "last_upload_at": "2025-01-07T14:30:00",
  "top_uploaders": [
    {
      "user_id": 123,
      "username": "hani_ad4x4",
      "count": 89
    },
    {
      "user_id": 456,
      "username": "ahmed_offroad",
      "count": 45
    },
    {
      "user_id": 789,
      "username": "sara_4x4",
      "count": 22
    }
  ]
}
```

**Performance:**
- Target response time: <200ms
- Uses cached `gallery_stats` table
- Cache updated on photo upload
- Top uploaders limited to 10 users

**Notes:**
- `photo_count` includes only non-deleted photos
- `last_upload_at` is UTC timestamp
- `top_uploaders` sorted by photo count descending

---

#### POST `/api/galleries/:galleryId/rename`

Rename a gallery. Requires ownership or Board member permission.

**Request:**
```http
POST /api/galleries/gallery-abc123/rename
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Desert Safari January 2025 - Updated"
}
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | New gallery name (max: 255 chars) |

**Response:**
```json
{
  "success": true,
  "gallery": {
    "id": "gallery-abc123",
    "name": "Desert Safari January 2025 - Updated",
    "updated_at": "2025-01-07T15:30:00"
  }
}
```

**Permissions:**
- Gallery owner can rename
- Board members can rename any gallery
- Other users get 403 Forbidden

**Status Codes:**
- `200` - Gallery renamed successfully
- `400` - Name is empty or too long
- `401` - Not authenticated
- `403` - Permission denied
- `404` - Gallery not found

---

#### DELETE `/api/galleries/:galleryId`

Soft delete a gallery (30-day restore window). Requires ownership or Board member permission.

**Request:**
```http
DELETE /api/galleries/gallery-abc123
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Gallery deleted successfully (30-day restore window)",
  "deleted_at": "2025-01-07T15:45:00",
  "restore_until": "2025-02-06T15:45:00"
}
```

**Soft Delete Details:**
- Gallery marked as deleted (not permanently removed)
- 30-day restore window before permanent deletion
- Photos remain intact during restore window
- Gallery hidden from normal listings

**Permissions:**
- Gallery owner can delete
- Board members can delete any gallery

**Notes:**
- After 30 days, cleanup job permanently deletes gallery and photos
- Use admin restore feature to recover within 30 days

---

## Photos Management

#### GET `/api/photos/gallery/:galleryId`

Get all photos from a specific gallery with optional sorting.

**Request:**
```http
GET /api/photos/gallery/gallery-abc123?sort_by=newest&page=1&limit=50
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sort_by` | string | `newest` | Sort: `newest`, `oldest`, `recently-uploaded`, `camera`, `file-size` |
| `page` | integer | `1` | Page number |
| `limit` | integer | `50` | Items per page (max: 200) |

**Response:**
```json
{
  "success": true,
  "photos": [
    {
      "id": "photo-abc123",
      "gallery_id": "gallery-abc123",
      "filename": "photo-1704636000000-abc.jpg",
      "original_filename": "IMG_2025.jpg",
      "file_size": 2500000,
      "width": 4000,
      "height": 3000,
      "uploaded_by": 123,
      "uploaded_by_username": "hani_ad4x4",
      "uploaded_by_avatar": "https://ap.ad4x4.com/uploads/avatars/hani.jpg",
      "created_at": "2025-01-07T14:30:00",
      "date_taken": "2025-01-07T10:15:30",
      "camera_make": "Canon",
      "camera_model": "EOS R5",
      "focal_length": "50mm",
      "aperture": "f/2.8",
      "iso": "ISO 400",
      "shutter_speed": "1/250",
      "latitude": 25.1234,
      "longitude": 56.5678,
      "location_name": "Wadi Bih",
      "download_count": 5,
      "view_count": 25,
      "is_favorited": true,
      "favorite_count": 3
    }
  ],
  "gallery": {
    "id": "gallery-abc123",
    "name": "Desert Safari January 2025",
    "created_by": 123,
    "trip_level": 2
  },
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 156,
    "total_pages": 4,
    "has_more": true
  }
}
```

**Sorting Options:**
- `newest` - Most recent date_taken (EXIF), fallback to upload date
- `oldest` - Oldest date_taken first
- `recently-uploaded` - Most recently uploaded (ignores EXIF date)
- `camera` - Grouped by camera model
- `file-size` - Largest files first

**EXIF Data Fields:**
| Field | Description | Example |
|-------|-------------|---------|
| `date_taken` | When photo was captured | `2025-01-07T10:15:30` |
| `camera_make` | Camera manufacturer | `Canon`, `Nikon`, `Sony` |
| `camera_model` | Camera model | `EOS R5`, `D850` |
| `focal_length` | Lens focal length | `50mm`, `24-70mm` |
| `aperture` | Lens aperture | `f/2.8`, `f/4.0` |
| `iso` | ISO sensitivity | `ISO 400`, `ISO 1600` |
| `shutter_speed` | Shutter speed | `1/250`, `1/1000` |
| `latitude` | GPS latitude | `25.1234` |
| `longitude` | GPS longitude | `56.5678` |
| `location_name` | Reverse geocoded location | `Wadi Bih` |

**Notes:**
- All EXIF fields are optional (may be `null`)
- GPS coordinates are decimal degrees
- `is_favorited` is user-specific (current user's favorite status)
- `favorite_count` is total favorites from all users

---

This is getting very long. Let me continue creating the complete documentation systematically...

#### DELETE `/api/photos/:photoId`

Delete a photo permanently.

**Request:**
```http
DELETE /api/photos/photo-abc123
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Photo deleted successfully"
}
```

**Permissions:**
- Photo uploader can delete their own photos
- Gallery owner can delete any photo in their gallery
- Board members can delete any photo

**Status Codes:**
- `200` - Photo deleted
- `401` - Not authenticated
- `403` - Permission denied
- `404` - Photo not found

---

#### PATCH `/api/photos/:photoId/rotate`

Rotate a photo 90 degrees clockwise or counterclockwise.

**Request:**
```http
PATCH /api/photos/photo-abc123/rotate
Authorization: Bearer {token}
Content-Type: application/json

{
  "direction": "right"
}
```

**Request Body:**
| Field | Type | Required | Values | Description |
|-------|------|----------|--------|-------------|
| `direction` | string | Yes | `left`, `right` | Rotation direction |

**Response:**
```json
{
  "success": true,
  "photo": {
    "id": "photo-abc123",
    "width": 3000,
    "height": 4000,
    "rotation_applied": true
  }
}
```

**Notes:**
- Rotation is permanent (modifies original file)
- Thumbnails are automatically regenerated
- Width and height are swapped for 90° rotations
- Uses lossless JPEG rotation when possible

**Permissions:**
- Photo uploader can rotate
- Gallery owner can rotate photos in their gallery
- Board members can rotate any photo

---

#### POST `/api/photos/:photoId/favorite`

Add a photo to current user's favorites.

**Request:**
```http
POST /api/photos/photo-abc123/favorite
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Photo added to favorites",
  "is_favorited": true
}
```

**Status Codes:**
- `200` - Added to favorites
- `400` - Already favorited
- `401` - Not authenticated
- `404` - Photo not found

---

#### DELETE `/api/photos/:photoId/favorite`

Remove a photo from current user's favorites.

**Request:**
```http
DELETE /api/photos/photo-abc123/favorite
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Photo removed from favorites",
  "is_favorited": false
}
```

---

#### GET `/api/photos/favorites`

Get current user's favorite photos with optional trip level filtering.

**Request:**
```http
GET /api/photos/favorites?trip_level=moderate&limit=50&offset=0
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `trip_level` | string | `all` | Filter: `all`, `easy`, `moderate`, `hard`, `extreme` |
| `limit` | integer | `50` | Items per page |
| `offset` | integer | `0` | Offset for pagination |

**Response:**
```json
{
  "success": true,
  "photos": [
    {
      "id": "photo-abc123",
      "filename": "photo-1704636000000-abc.jpg",
      "gallery_name": "Desert Safari",
      "gallery_id": "gallery-abc",
      "gallery_trip_level": 2,
      "gallery_created_by": 123,
      "uploaded_by_username": "hani_ad4x4",
      "favorited_at": "2025-01-07T15:00:00",
      "is_favorited": true
    }
  ],
  "total": 25,
  "has_more": false
}
```

**Notes:**
- Favorites are user-specific
- Access control based on gallery trip_level
- `favorited_at` shows when user added to favorites

---

#### GET `/api/photos/favorites/random`

Get a random favorite photo for current user.

**Request:**
```http
GET /api/photos/favorites/random
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "photo": {
    "id": "photo-random123",
    "filename": "photo-1704636000000-xyz.jpg",
    "original_filename": "IMG_5678.jpg",
    "gallery_name": "Sunset Drive",
    "uploaded_by_username": "ahmed"
  }
}
```

**Use Cases:**
- Featured favorite on dashboard
- Random photo widget
- Slideshow randomization

---

#### GET `/api/photos/:photoId/download`

Download a photo with proper headers and filename.

**Request:**
```http
GET /api/photos/photo-abc123/download
Authorization: Bearer {token}
```

**Response:**
- Binary image data
- `Content-Disposition: attachment; filename="IMG_2025.jpg"`
- `Content-Type: image/jpeg`

**Use Cases:**
- Mobile app "Save to Gallery"
- Desktop "Download" button
- Batch download scripts

**Notes:**
- Forces browser download (not inline display)
- Uses original filename from upload
- Tracks download count in database

---

#### GET `/api/photos/:photoId/thumbnail/:size`

Get a specific thumbnail size for a photo.

**Request:**
```http
GET /api/photos/photo-abc123/thumbnail/grid
Authorization: Bearer {token}
```

**Path Parameters:**
| Parameter | Values | Description |
|-----------|--------|-------------|
| `size` | `grid`, `card`, `list` | Thumbnail size |

**Response:**
- Binary image data
- `Content-Type: image/jpeg`

**Notes:**
- Alternative to direct `/thumbs/{size}/{filename}` URL
- Useful if you only have photo ID (not filename)
- Redirects to actual thumbnail file

---

## Search & Filter

#### GET `/api/photos/search`

Search photos across all accessible galleries.

**Request:**
```http
GET /api/photos/search?query=sunset&trip_level=moderate&camera=Canon&limit=50
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `query` | string | Search term (searches filename, gallery name) |
| `trip_level` | string | Filter by trip level |
| `camera` | string | Filter by camera make or model |
| `limit` | integer | Results limit (default: 50, max: 200) |
| `offset` | integer | Offset for pagination |

**Response:**
```json
{
  "success": true,
  "photos": [
    {
      "id": "photo-abc123",
      "filename": "sunset-dune.jpg",
      "gallery_name": "Evening Drive",
      "gallery_id": "gallery-xyz",
      "uploaded_by_username": "sara",
      "camera_make": "Canon",
      "camera_model": "EOS R5",
      "created_at": "2025-01-05T18:30:00"
    }
  ],
  "total": 15,
  "query": "sunset",
  "filters_applied": {
    "trip_level": "moderate",
    "camera": "Canon"
  }
}
```

**Search Behavior:**
- Case-insensitive
- Searches photo filenames and original filenames
- Searches gallery names
- Respects user's access permissions
- Results sorted by relevance, then date

**Performance:**
- Indexed search for fast queries
- Maximum 200 results per request
- Use pagination for large result sets

---

## Upload System

### Overview

The upload system supports batch uploads with session management, EXIF extraction, automatic thumbnail generation, and flexible file size limits.

**Key Features:**
- Batch uploads up to 95MB per session (Cloudflare Free compatible)
- Automatic EXIF metadata extraction
- Three thumbnail sizes generated automatically
- Progress tracking via sessions
- Configurable image resolution (1920px, 2560px, 3840px)
- Support for JPEG, PNG, HEIC, WebP, TIFF formats

---

#### POST `/api/photos/upload/session`

Create an upload session before uploading photos.

**Request:**
```http
POST /api/photos/upload/session
Authorization: Bearer {token}
Content-Type: application/json

{
  "gallery_id": "gallery-abc123"
}
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `gallery_id` | string | Yes | Target gallery ID |

**Response:**
```json
{
  "success": true,
  "session_id": "session-xyz789",
  "max_batch_bytes": 99614720,
  "max_batch_size_mb": 95,
  "max_files_per_batch": 500,
  "expires_at": "2025-01-07T16:00:00"
}
```

**Session Details:**
- **Expires:** 1 hour after creation
- **Max Batch Size:** 95MB (99614720 bytes)
- **Max Files:** 500 files per batch
- **Multiple Batches:** You can upload multiple batches within same session

**Use Cases:**
- Mobile apps with large photo galleries
- Progressive upload with retry logic
- Background sync operations

---

#### POST `/api/photos/upload`

Upload photos to a gallery.

**Request:**
```http
POST /api/photos/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

FormData:
- photos: [File, File, File, ...]
- gallery_id: "gallery-abc123"
- resolution: "3840"
- session_id: "session-xyz789" (optional)
```

**Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `photos` | File[] | Yes | Array of image files |
| `gallery_id` | string | Yes | Target gallery ID |
| `resolution` | string | No | Max resolution: `1920`, `2560`, `3840` (default: 3840) |
| `session_id` | string | No | Upload session ID (recommended) |

**Response:**
```json
{
  "success": true,
  "message": "Uploaded 3 photos successfully",
  "uploaded": [
    {
      "id": "photo-new1",
      "filename": "photo-1704639000000-abc.jpg",
      "original_filename": "IMG_2025.jpg",
      "file_size": 2500000,
      "width": 3840,
      "height": 2560
    },
    {
      "id": "photo-new2",
      "filename": "photo-1704639000001-def.jpg",
      "original_filename": "IMG_2026.jpg",
      "file_size": 3100000,
      "width": 3840,
      "height": 2560
    }
  ],
  "failed": [],
  "total_uploaded": 3,
  "total_failed": 0
}
```

**Upload Process:**
1. Files validated (type, size)
2. Images resized to specified resolution (if larger)
3. EXIF metadata extracted
4. Thumbnails generated (grid, card, list)
5. Files saved to `/uploads/` directory
6. Database records created

**Supported Formats:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC/HEIF (.heic, .heif) - iPhone photos
- WebP (.webp)
- TIFF (.tiff, .tif)
- GIF (.gif)

**File Size Limits:**
- **Per Photo:** 500MB hard limit
- **Per Batch (with session):** 95MB recommended for Cloudflare Free
- **Per Batch (without session):** 500MB total

**EXIF Extraction:**
Automatically extracts:
- Date/time taken
- Camera make and model
- Focal length
- Aperture (f-stop)
- ISO sensitivity
- Shutter speed
- GPS coordinates (latitude/longitude)

**Error Handling:**
- Partial success supported (some photos upload, some fail)
- Each failed photo includes error reason
- Successful photos are saved even if others fail

**Example (JavaScript):**
```javascript
async function uploadPhotos(galleryId, files) {
  // 1. Create session
  const sessionResponse = await fetch('https://media.ad4x4.com/api/photos/upload/session', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ gallery_id: galleryId })
  });
  const { session_id, max_batch_bytes } = await sessionResponse.json();
  
  // 2. Split files into batches (if needed)
  const batches = splitIntoBatches(files, max_batch_bytes);
  
  // 3. Upload each batch
  for (const batch of batches) {
    const formData = new FormData();
    batch.forEach(file => formData.append('photos', file));
    formData.append('gallery_id', galleryId);
    formData.append('session_id', session_id);
    formData.append('resolution', '3840');
    
    const uploadResponse = await fetch('https://media.ad4x4.com/api/photos/upload', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` },
      body: formData
    });
    
    const result = await uploadResponse.json();
    console.log(`Uploaded ${result.total_uploaded} photos`);
  }
}

function splitIntoBatches(files, maxBytes) {
  const batches = [];
  let currentBatch = [];
  let currentSize = 0;
  
  for (const file of files) {
    if (currentSize + file.size > maxBytes && currentBatch.length > 0) {
      batches.push(currentBatch);
      currentBatch = [];
      currentSize = 0;
    }
    currentBatch.push(file);
    currentSize += file.size;
  }
  
  if (currentBatch.length > 0) {
    batches.push(currentBatch);
  }
  
  return batches;
}
```

---

## Batch Operations

### Batch Delete

#### POST `/api/photos/batch/delete`

Delete multiple photos at once.

**Request:**
```http
POST /api/photos/batch/delete
Authorization: Bearer {token}
Content-Type: application/json

{
  "photo_ids": ["photo-1", "photo-2", "photo-3"]
}
```

**Response:**
```json
{
  "success": true,
  "deleted_count": 3,
  "failed_count": 0,
  "results": [
    { "id": "photo-1", "success": true },
    { "id": "photo-2", "success": true },
    { "id": "photo-3", "success": true }
  ]
}
```

**Permissions:**
- User must have delete permission for each photo
- Partial success supported (some may fail)

---

### Batch Favorite

#### POST `/api/photos/batch/favorite`

Add multiple photos to favorites at once.

**Request:**
```http
POST /api/photos/batch/favorite
Authorization: Bearer {token}
Content-Type: application/json

{
  "photo_ids": ["photo-1", "photo-2", "photo-3"]
}
```

**Response:**
```json
{
  "success": true,
  "added_count": 3,
  "skipped_count": 0,
  "results": [
    { "id": "photo-1", "success": true, "already_favorited": false },
    { "id": "photo-2", "success": true, "already_favorited": false },
    { "id": "photo-3", "success": true, "already_favorited": false }
  ]
}
```

---

### Batch Rotate

#### POST `/api/photos/batch/rotate`

Rotate multiple photos at once.

**Request:**
```http
POST /api/photos/batch/rotate
Authorization: Bearer {token}
Content-Type: application/json

{
  "photo_ids": ["photo-1", "photo-2"],
  "direction": "right"
}
```

**Response:**
```json
{
  "success": true,
  "rotated_count": 2,
  "failed_count": 0,
  "results": [
    { "id": "photo-1", "success": true },
    { "id": "photo-2", "success": true }
  ]
}
```

**Notes:**
- All photos rotated in same direction
- Thumbnails regenerated for all
- Operation may take several seconds for large batches

---

## Trip Integration Webhooks

### Overview

These webhooks allow the main AD4x4 backend to synchronize trip data with the gallery system. When trips are published, renamed, or deleted, galleries are automatically managed.

**Idempotency:** All webhook endpoints are idempotent - safe to call multiple times.

---

#### POST `/api/webhooks/trip/published`

Called when a trip is published on the main backend. Automatically creates a gallery for the trip.

**Request:**
```http
POST /api/webhooks/trip/published
Content-Type: application/json

{
  "trip_id": "trip-abc123",
  "title": "Desert Safari - January 2025",
  "creator_id": 123,
  "creator_username": "hani_ad4x4",
  "creator_avatar": "https://...",
  "level": 2
}
```

**Response:**
```json
{
  "success": true,
  "gallery": {
    "id": "gallery-xyz789",
    "name": "Desert Safari - January 2025",
    "source_trip_id": "trip-abc123",
    "auto_created": true
  },
  "created": true
}
```

**Idempotency:**
- If gallery already exists for trip_id, returns existing gallery
- `created: false` indicates gallery already existed

---

#### POST `/api/webhooks/trip/renamed`

Called when a trip is renamed. Syncs the gallery name if it was auto-created.

**Request:**
```http
POST /api/webhooks/trip/renamed
Content-Type: application/json

{
  "trip_id": "trip-abc123",
  "new_title": "Desert Safari - January 2025 (Updated)"
}
```

**Response:**
```json
{
  "success": true,
  "gallery_id": "gallery-xyz789",
  "updated": true,
  "new_name": "Desert Safari - January 2025 (Updated)"
}
```

**Behavior:**
- Only renames auto-created galleries
- Manually created galleries are not affected
- Returns `updated: false` if gallery was manually created

---

#### POST `/api/webhooks/trip/deleted`

Called when a trip is deleted. Soft-deletes the associated gallery.

**Request:**
```http
POST /api/webhooks/trip/deleted
Content-Type: application/json

{
  "trip_id": "trip-abc123"
}
```

**Response:**
```json
{
  "success": true,
  "gallery_id": "gallery-xyz789",
  "deleted": true,
  "soft_deleted_at": "2025-01-07T16:00:00"
}
```

**Behavior:**
- Soft deletes gallery (30-day restore window)
- Photos remain intact during restore window
- Idempotent - safe to call on already deleted galleries

---

#### POST `/api/webhooks/trip/restored`

Called when a deleted trip is restored. Restores the associated gallery.

**Request:**
```http
POST /api/webhooks/trip/restored
Content-Type: application/json

{
  "trip_id": "trip-abc123"
}
```

**Response:**
```json
{
  "success": true,
  "gallery_id": "gallery-xyz789",
  "restored": true
}
```

---


## Themes & Personalization

#### GET `/api/theme/current`

Get current user's active theme.

**Request:**
```http
GET /api/theme/current
Authorization: Bearer {token}
```

**Response:**
```json
{
  "theme_mode": "dark",
  "theme": {
    "id": 1,
    "name": "Dark Mode",
    "primary_color": "#ffa500",
    "background_color": "#202124",
    "card_color": "#292a2d",
    "text_color": "#e8eaed",
    "border_color": "#3c4043",
    "hover_color": "#35363a",
    "secondary_color": "#9aa0a6"
  },
  "dark_theme": {...},
  "light_theme": {...}
}
```

---

#### PUT `/api/user/theme`

Update current user's theme preferences.

**Request:**
```http
PUT /api/user/theme
Authorization: Bearer {token}
Content-Type: application/json

{
  "theme": "dark"
}
```

---

## Admin Panel (Board Members Only)

### Statistics & Analytics

#### GET `/api/admin/stats`

Get system statistics.

**Requires:** Board member permission

**Response:**
```json
{
  "success": true,
  "stats": {
    "total_photos": 1250,
    "total_galleries": 45,
    "total_users": 120,
    "total_favorites": 340,
    "storage_used_mb": 15420
  }
}
```

---

#### GET `/api/admin/analytics`

Get detailed analytics data.

**Response includes:**
- Photos by date
- Uploads by user
- Top cameras
- Popular galleries
- Activity trends

---

### Content Management

#### GET `/api/admin/content/galleries`

Get all galleries for admin management (includes soft-deleted).

---

### Maintenance Tools

#### POST `/api/admin/maintenance/cleanup-galleries`

Permanently delete galleries soft-deleted 30+ days ago.

---

#### GET `/api/admin/maintenance/orphaned-photos`

Find photos without galleries.

---

#### POST `/api/admin/maintenance/optimize`

Optimize database and regenerate thumbnails.

---

#### GET `/api/admin/maintenance/orphaned-files`

Find orphaned files in uploads directory.

---

#### POST `/api/admin/maintenance/cleanup-orphaned-files`

Delete orphaned files.

---

### Audit Logs

#### GET `/api/audit-logs`

Get audit log entries with filtering.

**Query Parameters:**
- `action`: Filter by action type (login, upload, delete, etc.)
- `user_id`: Filter by user
- `status`: success/failure
- `start_date`, `end_date`: Date range
- `limit`, `offset`: Pagination

**Response:**
```json
{
  "success": true,
  "logs": [
    {
      "id": 123,
      "user_id": 456,
      "username": "hani_ad4x4",
      "action": "upload",
      "resource_type": "photo",
      "resource_id": "photo-abc",
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "status": "success",
      "created_at": "2025-01-07T16:00:00"
    }
  ],
  "total": 1500,
  "pagination": {...}
}
```

---

#### GET `/api/audit-logs/export`

Export audit logs as CSV.

---

#### DELETE `/api/audit-logs/range`

Delete audit logs within date range.

---

#### GET `/api/audit-logs/stats`

Get audit log statistics.

---

### Permissions Management

#### GET `/api/admin/permissions`

Get all user groups and permissions.

---

#### PUT `/api/admin/permissions/:groupId`

Update permissions for a user group.

---

### System Settings

#### GET `/api/admin/settings`

Get all system settings.

---

#### PUT `/api/admin/settings`

Update multiple settings.

---

#### PUT `/api/admin/settings/:key`

Update a single setting.

---

### Backup & Export

#### GET `/api/admin/backup/database`

Download database backup.

---

#### GET `/api/admin/backup/photos`

Get photo backup information.

---

#### GET `/api/admin/backup/settings`

Export system settings as JSON.

---

## Error Handling

### Standard Error Response

```json
{
  "success": false,
  "error": "Error message description"
}
```

### Common Errors

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 413 | Payload Too Large | File/batch size exceeds limit |
| 500 | Internal Server Error | Server-side error |

---

## Response Codes

### Success Codes
- `200 OK` - Request successful
- `201 Created` - Resource created successfully

### Client Error Codes
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `413 Payload Too Large` - Upload size exceeded

### Server Error Codes
- `500 Internal Server Error` - Server malfunction
- `503 Service Unavailable` - Server temporarily unavailable

---

## Rate Limiting

Currently, there are **no rate limits** enforced on the Gallery API. However, best practices include:

- Reasonable request intervals
- Batch operations when possible
- Avoid unnecessary polling

Future versions may implement rate limiting.

---

## Best Practices

### Authentication
- Store JWT tokens securely
- Refresh tokens before expiration
- Handle 401 errors gracefully

### Image Loading
- Always use thumbnails for lists/grids
- Progressive loading (thumbnail → full image)
- Implement caching strategies
- Use lazy loading for performance

### Uploads
- Create upload sessions for batches
- Split large batches (95MB limit)
- Handle partial success scenarios
- Implement retry logic for failed uploads

### Error Handling
- Check `success` field in responses
- Display user-friendly error messages
- Implement exponential backoff for retries
- Log errors for debugging

### Performance
- Use pagination for large datasets
- Implement infinite scroll for mobile
- Cache API responses when appropriate
- Minimize API calls with batch operations

---

## Changelog

### v1.4.0 (2025-01-07)
- ✅ Added trip-gallery integration webhooks
- ✅ Added upload session management
- ✅ Added gallery stats endpoint
- ✅ Added soft delete for galleries (30-day restore)
- ✅ Added gallery rename endpoint
- ✅ Added batch operations (delete, favorite, rotate)
- ✅ Improved EXIF extraction
- ✅ Added audit logging system

### v1.3.0 (Previous)
- Gallery and photo management
- Favorites system
- Search functionality
- Admin panel
- Theme customization

---

## Support

For API questions or issues:
- **GitHub:** https://github.com/Hani-AMJ/AD4x4-Gallery
- **Main Backend:** https://ap.ad4x4.com

---

## Appendix: Complete Endpoint List

### Authentication
- `POST /api/auth/login`
- `GET /api/auth/profile`
- `GET /health`

### Galleries
- `GET /api/galleries`
- `POST /api/galleries`
- `GET /api/galleries/:id/stats`
- `POST /api/galleries/:id/rename`
- `DELETE /api/galleries/:id`

### Photos
- `GET /api/photos/gallery/:galleryId`
- `POST /api/photos/upload/session`
- `POST /api/photos/upload`
- `DELETE /api/photos/:photoId`
- `PATCH /api/photos/:photoId/rotate`
- `POST /api/photos/:photoId/favorite`
- `DELETE /api/photos/:photoId/favorite`
- `GET /api/photos/favorites`
- `GET /api/photos/favorites/random`
- `GET /api/photos/:photoId/download`
- `GET /api/photos/:photoId/thumbnail/:size`
- `GET /api/photos/search`

### Batch Operations
- `POST /api/photos/batch/delete`
- `POST /api/photos/batch/favorite`
- `POST /api/photos/batch/rotate`

### Trip Webhooks
- `POST /api/webhooks/trip/published`
- `POST /api/webhooks/trip/renamed`
- `POST /api/webhooks/trip/deleted`
- `POST /api/webhooks/trip/restored`

### Themes
- `GET /api/theme/current`
- `PUT /api/user/theme`
- `GET /api/admin/themes`
- `PUT /api/admin/themes/:id`
- `POST /api/admin/themes/:id/activate`

### Admin - Statistics
- `GET /api/admin/stats`
- `GET /api/admin/analytics`
- `GET /api/admin/activity`

### Admin - Content
- `GET /api/admin/content/galleries`

### Admin - Maintenance
- `POST /api/admin/maintenance/cleanup-galleries`
- `GET /api/admin/maintenance/orphaned-photos`
- `POST /api/admin/maintenance/optimize`
- `GET /api/admin/maintenance/orphaned-files`
- `POST /api/admin/maintenance/cleanup-orphaned-files`

### Admin - Audit Logs
- `GET /api/audit-logs`
- `GET /api/audit-logs/export`
- `DELETE /api/audit-logs/range`
- `GET /api/audit-logs/stats`

### Admin - Permissions
- `GET /api/admin/permissions`
- `PUT /api/admin/permissions/:groupId`

### Admin - Settings
- `GET /api/admin/settings`
- `PUT /api/admin/settings`
- `POST /api/admin/settings`
- `PUT /api/admin/settings/:key`
- `GET /api/settings/public`

### Admin - Backup
- `GET /api/admin/backup/database`
- `GET /api/admin/backup/photos`
- `GET /api/admin/backup/settings`

### Other
- `GET /api/home`
- `GET /`
- `GET /admin/settings`
- `GET /api-docs`

**Total Endpoints:** 61

---

**End of Documentation**

