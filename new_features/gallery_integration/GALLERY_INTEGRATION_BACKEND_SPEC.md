# Gallery Integration - Backend Development Specification

**Project:** AD4x4 Main API (Django) - Gallery Integration  
**Date:** November 16, 2024  
**Updated:** January 17, 2025 - Added flexible backend configuration  
**Backend Team:** Django Developers  
**Priority:** 🔴 **CRITICAL** - Blocks Flutter Development

---

## 🎨 Design Philosophy

**Flexibility First**: Following the same philosophy as Vehicle Modifications and Rating Systems:

- ✅ **Gallery API URL configurable** via database settings
- ✅ **Feature flags backend-controlled** (enable/disable gallery system)
- ✅ **Timeout values configurable** without code changes
- ✅ **Auto-creation behavior configurable** (automatic vs manual)
- ✅ **Future-ready for multi-region support** and custom gallery servers

**Key Principle:** Gallery system behavior controlled by database settings, not hardcoded constants.

---

## 📋 Executive Summary

The AD4x4 mobile app needs the Main API (Django backend) to integrate with the Gallery API (Node.js service at `https://media.ad4x4.com`). When trips are created, updated, or deleted, the Main API must call Gallery API webhooks to automatically manage photo galleries.

**Estimated Time:** 8-10 hours (includes configuration system)  
**Impact:** Enables complete photo gallery feature for 120+ active users

---

## 🎯 Business Requirements

### **User Story:**
> "As a trip leader, when I create a trip, I want a photo gallery to be automatically created for it so that participants can upload and share photos from the trip."

### **Current Problem:**
- Trips are created in Main API (Django)
- Gallery API exists but is not connected to trips
- Users cannot upload trip photos because galleries don't exist
- Manual gallery creation is error-prone and requires coordination

### **Solution:**
Implement automatic gallery lifecycle management:
1. ✅ Create gallery when trip is published
2. ✅ Sync gallery name when trip is renamed
3. ✅ Delete gallery when trip is deleted
4. ✅ Store gallery ID in trip data

---

## 🔗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App (Flutter)                      │
└───────────────────────┬─────────────────────────────────────────┘
                        │
        ┌───────────────┴────────────────┐
        │                                │
┌───────▼────────┐              ┌────────▼────────┐
│   Main API     │   Webhooks   │   Gallery API   │
│   (Django)     ├──────────────►   (Node.js)     │
│ ap.ad4x4.com   │              │ media.ad4x4.com │
└───────┬────────┘              └────────┬────────┘
        │                                │
┌───────▼────────┐              ┌────────▼────────┐
│   PostgreSQL   │              │     SQLite      │
│   (Main DB)    │              │  (Gallery DB)   │
└────────────────┘              └─────────────────┘
```

**Integration Points:**
- Main API calls Gallery API webhooks (HTTP POST)
- Gallery API returns `gallery_id` (UUID string)
- Main API stores `gallery_id` in Trip model
- Main API returns `gallery_id` in trip responses

---

## 📊 Gallery API Details

### **Base URL:**
```
Production: https://media.ad4x4.com
```

### **Authentication:**
Gallery API accepts JWT tokens from Main API. No additional authentication needed - just pass the user's JWT token in the Authorization header.

### **Complete API Documentation:**
See `/home/user/flutter_app/docs/GALLERY-API-DOCUMENTATION.md` (2,319 lines)

---

## 🛠️ Implementation Requirements

### **1. Database Changes (HIGH PRIORITY)**

#### **1.1. Add Gallery Configuration to Global Settings (NEW)**

**File:** `global_settings/models.py` (or create new table)

```python
from django.db import models

class GlobalSettings(models.Model):
    # ... existing fields ...
    
    # NEW FIELDS: Gallery system configuration
    gallery_api_url = models.CharField(
        max_length=255,
        default='https://media.ad4x4.com',
        help_text="Gallery API base URL - configurable for different environments"
    )
    gallery_api_timeout = models.IntegerField(
        default=30,
        help_text="Gallery API timeout in seconds"
    )
    enable_gallery_system = models.BooleanField(
        default=True,
        help_text="Master switch to enable/disable entire gallery system"
    )
    auto_create_trip_gallery = models.BooleanField(
        default=True,
        help_text="Automatically create galleries when trips are published"
    )
    allow_manual_gallery_creation = models.BooleanField(
        default=True,
        help_text="Allow admins to manually create galleries"
    )
```

**Migration:**
```sql
-- Add to existing global_settings table
ALTER TABLE global_settings ADD COLUMN gallery_api_url VARCHAR(255) DEFAULT 'https://media.ad4x4.com';
ALTER TABLE global_settings ADD COLUMN gallery_api_timeout INTEGER DEFAULT 30;
ALTER TABLE global_settings ADD COLUMN enable_gallery_system BOOLEAN DEFAULT TRUE;
ALTER TABLE global_settings ADD COLUMN auto_create_trip_gallery BOOLEAN DEFAULT TRUE;
ALTER TABLE global_settings ADD COLUMN allow_manual_gallery_creation BOOLEAN DEFAULT TRUE;

-- Set initial values
UPDATE global_settings SET 
    gallery_api_url = 'https://media.ad4x4.com',
    gallery_api_timeout = 30,
    enable_gallery_system = TRUE,
    auto_create_trip_gallery = TRUE,
    allow_manual_gallery_creation = TRUE
WHERE id = 1;
```

---

#### **1.2. Add `gallery_id` Field to Trip Model**

**File:** `trips/models.py` (or equivalent)

```python
from django.db import models

class Trip(models.Model):
    # ... existing fields ...
    
    # NEW FIELD: Gallery API UUID
    gallery_id = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        db_index=True,
        help_text="UUID of associated gallery from Gallery API (media.ad4x4.com)"
    )
    
    class Meta:
        db_table = 'trips'
        # ... existing meta ...
```

**Migration:**
```bash
python manage.py makemigrations
python manage.py migrate
```

**Database Column:**
- **Type:** VARCHAR(255)
- **Nullable:** YES (trips created before this feature won't have galleries)
- **Indexed:** YES (for faster lookups)
- **Example:** `"gallery-abc123-def456-ghi789"`

---

### **2. Gallery API Service (HIGH PRIORITY)**

Create a service to communicate with Gallery API.

#### **Create Gallery Service File**

**File:** `services/gallery_service.py` (create new file)

```python
"""
Gallery API Service
Handles communication with Gallery API (Node.js service at media.ad4x4.com)
"""

import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class GalleryAPIError(Exception):
    """Custom exception for Gallery API errors"""
    pass


class GalleryService:
    """Service for interacting with Gallery API with dynamic configuration"""
    
    def __init__(self):
        """
        Initialize Gallery Service with configuration from database.
        Configuration is loaded once and cached for performance.
        """
        # Load configuration from database (cached)
        self._load_configuration()
    
    def _load_configuration(self):
        """Load gallery configuration from global settings"""
        try:
            settings = GlobalSettings.objects.first()
            
            # Load from database instead of hardcoding
            self.base_url = settings.gallery_api_url or "https://media.ad4x4.com"
            self.timeout = settings.gallery_api_timeout or 30
            self.enabled = settings.enable_gallery_system
            self.auto_create = settings.auto_create_trip_gallery
            self.allow_manual = settings.allow_manual_gallery_creation
            
            logger.info(f"Gallery Service configured: URL={self.base_url}, Timeout={self.timeout}s, Enabled={self.enabled}")
            
        except Exception as e:
            # Fallback to defaults if settings not available
            logger.warning(f"Failed to load gallery settings, using defaults: {e}")
            self.base_url = "https://media.ad4x4.com"
            self.timeout = 30
            self.enabled = True
            self.auto_create = True
            self.allow_manual = True
    
    def _make_request(self, method, endpoint, data=None, headers=None):
        """
        Make HTTP request to Gallery API
        
        Args:
            method: HTTP method (GET, POST, DELETE, etc.)
            endpoint: API endpoint (e.g., '/api/webhooks/trip/published')
            data: Request payload (dict)
            headers: Additional headers (dict)
            
        Returns:
            Response data (dict)
            
        Raises:
            GalleryAPIError: If request fails
        """
        url = f"{self.base_url}{endpoint}"
        
        default_headers = {
            'Content-Type': 'application/json',
        }
        
        if headers:
            default_headers.update(headers)
        
        try:
            logger.info(f"Gallery API Request: {method} {url}")
            
            response = requests.request(
                method=method,
                url=url,
                json=data,
                headers=default_headers,
                timeout=self.timeout
            )
            
            # Log response
            logger.info(f"Gallery API Response: {response.status_code}")
            
            # Check for errors
            response.raise_for_status()
            
            return response.json()
            
        except requests.exceptions.Timeout:
            error_msg = f"Gallery API timeout after {self.timeout}s: {url}"
            logger.error(error_msg)
            raise GalleryAPIError(error_msg)
            
        except requests.exceptions.HTTPError as e:
            error_msg = f"Gallery API HTTP error: {e.response.status_code} - {e.response.text}"
            logger.error(error_msg)
            raise GalleryAPIError(error_msg)
            
        except requests.exceptions.RequestException as e:
            error_msg = f"Gallery API request failed: {str(e)}"
            logger.error(error_msg)
            raise GalleryAPIError(error_msg)
    
    # ========================================================================
    # WEBHOOK METHODS (Called by Main API)
    # ========================================================================
    
    def notify_trip_published(self, trip_id, title, creator_id, creator_username, 
                             creator_avatar, level):
        """
        Notify Gallery API that a trip has been published
        This creates a new gallery for the trip
        
        Args:
            trip_id: Trip ID (integer or string)
            title: Trip title
            creator_id: User ID who created the trip
            creator_username: Username of creator
            creator_avatar: Avatar URL of creator
            level: Trip difficulty level (1-4)
            
        Returns:
            dict: {
                'success': True,
                'gallery': {
                    'id': 'gallery-uuid',
                    'name': 'Trip Title',
                    'source_trip_id': 'trip-123',
                    'auto_created': True
                },
                'created': True
            }
            
        Raises:
            GalleryAPIError: If creation fails
        """
        # Check if gallery system is enabled
        if not self.enabled:
            logger.info(f"Gallery system disabled - skipping gallery creation for trip {trip_id}")
            return {'success': False, 'reason': 'gallery_system_disabled'}
        
        # Check if auto-creation is enabled
        if not self.auto_create:
            logger.info(f"Auto-creation disabled - skipping gallery creation for trip {trip_id}")
            return {'success': False, 'reason': 'auto_creation_disabled', 'allow_manual': self.allow_manual}
        
        endpoint = "/api/webhooks/trip/published"
        
        payload = {
            "trip_id": str(trip_id),
            "title": title,
            "creator_id": creator_id,
            "creator_username": creator_username,
            "creator_avatar": creator_avatar or "",
            "level": level
        }
        
        logger.info(f"Creating gallery for trip {trip_id}: {title}")
        
        try:
            response = self._make_request('POST', endpoint, data=payload)
            
            # Extract gallery ID
            gallery_id = response.get('gallery', {}).get('id')
            
            if not gallery_id:
                raise GalleryAPIError("Gallery API did not return gallery ID")
            
            logger.info(f"✅ Gallery created: {gallery_id} for trip {trip_id}")
            
            return response
            
        except GalleryAPIError as e:
            logger.error(f"❌ Failed to create gallery for trip {trip_id}: {e}")
            raise
    
    def notify_trip_renamed(self, trip_id, new_title):
        """
        Notify Gallery API that a trip has been renamed
        This syncs the gallery name with the trip name
        
        Args:
            trip_id: Trip ID
            new_title: New trip title
            
        Returns:
            dict: {
                'success': True,
                'gallery_id': 'gallery-uuid',
                'updated': True,
                'new_name': 'New Trip Title'
            }
            
        Raises:
            GalleryAPIError: If rename fails
        """
        endpoint = "/api/webhooks/trip/renamed"
        
        payload = {
            "trip_id": str(trip_id),
            "new_title": new_title
        }
        
        logger.info(f"Renaming gallery for trip {trip_id}: {new_title}")
        
        try:
            response = self._make_request('POST', endpoint, data=payload)
            logger.info(f"✅ Gallery renamed for trip {trip_id}")
            return response
            
        except GalleryAPIError as e:
            # Non-critical error - log but don't fail
            logger.warning(f"⚠️ Failed to rename gallery for trip {trip_id}: {e}")
            return {'success': False, 'error': str(e)}
    
    def notify_trip_deleted(self, trip_id):
        """
        Notify Gallery API that a trip has been deleted
        This soft-deletes the gallery (30-day restore window)
        
        Args:
            trip_id: Trip ID
            
        Returns:
            dict: {
                'success': True,
                'gallery_id': 'gallery-uuid',
                'deleted': True,
                'soft_deleted_at': '2025-01-07T16:00:00'
            }
            
        Raises:
            GalleryAPIError: If deletion fails
        """
        endpoint = "/api/webhooks/trip/deleted"
        
        payload = {
            "trip_id": str(trip_id)
        }
        
        logger.info(f"Deleting gallery for trip {trip_id}")
        
        try:
            response = self._make_request('POST', endpoint, data=payload)
            logger.info(f"✅ Gallery deleted for trip {trip_id}")
            return response
            
        except GalleryAPIError as e:
            # Non-critical error - log but don't fail
            logger.warning(f"⚠️ Failed to delete gallery for trip {trip_id}: {e}")
            return {'success': False, 'error': str(e)}
    
    def notify_trip_restored(self, trip_id):
        """
        Notify Gallery API that a deleted trip has been restored
        This restores the associated gallery
        
        Args:
            trip_id: Trip ID
            
        Returns:
            dict: {
                'success': True,
                'gallery_id': 'gallery-uuid',
                'restored': True
            }
            
        Raises:
            GalleryAPIError: If restoration fails
        """
        endpoint = "/api/webhooks/trip/restored"
        
        payload = {
            "trip_id": str(trip_id)
        }
        
        logger.info(f"Restoring gallery for trip {trip_id}")
        
        try:
            response = self._make_request('POST', endpoint, data=payload)
            logger.info(f"✅ Gallery restored for trip {trip_id}")
            return response
            
        except GalleryAPIError as e:
            logger.error(f"❌ Failed to restore gallery for trip {trip_id}: {e}")
            raise


# Singleton instance
_gallery_service = None

def get_gallery_service():
    """Get singleton Gallery Service instance"""
    global _gallery_service
    if _gallery_service is None:
        _gallery_service = GalleryService()
    return _gallery_service
```

---

### **3. Trip Lifecycle Integration (HIGH PRIORITY)**

Integrate gallery creation/deletion with trip lifecycle.

#### **3.1. Trip Creation/Publishing**

**Location:** `trips/views.py` or `trips/serializers.py` (wherever trip creation happens)

**When to call:** After trip is approved/published (not on draft creation)

```python
from services.gallery_service import get_gallery_service, GalleryAPIError

class TripViewSet(viewsets.ModelViewSet):
    """Trip ViewSet"""
    
    def create(self, request, *args, **kwargs):
        """Create a new trip"""
        # ... existing trip creation logic ...
        response = super().create(request, *args, **kwargs)
        trip = self.get_object()
        
        # If trip is auto-approved (no approval required)
        if trip.approval_status == 'A':  # Approved
            self._create_gallery_for_trip(trip)
        
        return response
    
    def _create_gallery_for_trip(self, trip):
        """
        Create gallery for trip via Gallery API
        
        Args:
            trip: Trip instance
        """
        try:
            gallery_service = get_gallery_service()
            
            # Call Gallery API webhook
            result = gallery_service.notify_trip_published(
                trip_id=trip.id,
                title=trip.title,
                creator_id=trip.lead.id,
                creator_username=trip.lead.username,
                creator_avatar=trip.lead.avatar.url if trip.lead.avatar else None,
                level=trip.level.numeric_level if trip.level else 2
            )
            
            # Store gallery_id in trip
            gallery_id = result.get('gallery', {}).get('id')
            if gallery_id:
                trip.gallery_id = gallery_id
                trip.save(update_fields=['gallery_id'])
                
                logger.info(f"✅ Gallery {gallery_id} linked to trip {trip.id}")
            else:
                logger.warning(f"⚠️ Gallery API did not return gallery ID for trip {trip.id}")
                
        except GalleryAPIError as e:
            # Log error but don't fail trip creation
            logger.error(f"❌ Failed to create gallery for trip {trip.id}: {e}")
            # Optional: Send notification to admins


# Alternative: If using approval workflow
class TripApprovalView(APIView):
    """Approve pending trip"""
    
    def post(self, request, trip_id):
        """Approve trip and create gallery"""
        trip = get_object_or_404(Trip, id=trip_id)
        
        # Update approval status
        trip.approval_status = 'A'
        trip.save()
        
        # Create gallery after approval
        self._create_gallery_for_trip(trip)
        
        return Response({'success': True})
```

---

#### **3.2. Trip Update/Rename**

**Location:** `trips/views.py` (update method)

**When to call:** When trip title changes

```python
class TripViewSet(viewsets.ModelViewSet):
    """Trip ViewSet"""
    
    def update(self, request, *args, **kwargs):
        """Update trip"""
        trip = self.get_object()
        old_title = trip.title
        
        # Perform update
        response = super().update(request, *args, **kwargs)
        
        # Get updated trip
        trip.refresh_from_db()
        new_title = trip.title
        
        # If title changed and gallery exists, sync with Gallery API
        if old_title != new_title and trip.gallery_id:
            self._sync_gallery_name(trip)
        
        return response
    
    def _sync_gallery_name(self, trip):
        """
        Sync gallery name when trip title changes
        
        Args:
            trip: Trip instance
        """
        try:
            gallery_service = get_gallery_service()
            
            gallery_service.notify_trip_renamed(
                trip_id=trip.id,
                new_title=trip.title
            )
            
            logger.info(f"✅ Gallery name synced for trip {trip.id}")
            
        except GalleryAPIError as e:
            # Log error but don't fail trip update
            logger.warning(f"⚠️ Failed to sync gallery name for trip {trip.id}: {e}")
```

---

#### **3.3. Trip Deletion**

**Location:** `trips/views.py` (destroy method)

**When to call:** When trip is deleted

```python
class TripViewSet(viewsets.ModelViewSet):
    """Trip ViewSet"""
    
    def destroy(self, request, *args, **kwargs):
        """Delete trip and associated gallery"""
        trip = self.get_object()
        
        # Delete gallery first (if exists)
        if trip.gallery_id:
            self._delete_gallery(trip)
        
        # Delete trip
        return super().destroy(request, *args, **kwargs)
    
    def _delete_gallery(self, trip):
        """
        Delete gallery when trip is deleted
        
        Args:
            trip: Trip instance
        """
        try:
            gallery_service = get_gallery_service()
            
            gallery_service.notify_trip_deleted(trip_id=trip.id)
            
            logger.info(f"✅ Gallery deleted for trip {trip.id}")
            
        except GalleryAPIError as e:
            # Log error but don't fail trip deletion
            logger.warning(f"⚠️ Failed to delete gallery for trip {trip.id}: {e}")
```

---

### **4. API Response Updates (HIGH PRIORITY)**

Add `gallery_id` to trip responses.

#### **4.1. Update Trip Serializer**

**File:** `trips/serializers.py`

```python
from rest_framework import serializers

class TripSerializer(serializers.ModelSerializer):
    """Trip Serializer"""
    
    # ... existing fields ...
    
    gallery_id = serializers.CharField(
        read_only=True,
        help_text="UUID of associated gallery from Gallery API",
        allow_null=True
    )
    
    class Meta:
        model = Trip
        fields = [
            'id',
            'title',
            'description',
            'level',
            'lead',
            'start_time',
            'end_time',
            # ... other existing fields ...
            'gallery_id',  # ADD THIS
        ]
```

---

#### **4.2. Example API Response**

**GET `/api/trips/123/`**

```json
{
  "id": 123,
  "title": "Desert Safari - January 2025",
  "description": "Amazing desert adventure",
  "level": {
    "id": 2,
    "name": "Moderate",
    "numeric_level": 2
  },
  "lead": {
    "id": 456,
    "username": "hani_ad4x4",
    "full_name": "Hani AMJ"
  },
  "start_time": "2025-01-20T08:00:00Z",
  "end_time": "2025-01-20T18:00:00Z",
  "gallery_id": "gallery-abc123-def456-ghi789",  // ← NEW FIELD
  "participants": [],
  "approval_status": "A",
  "created_at": "2025-01-07T10:00:00Z"
}
```

---

## 🧪 Testing Requirements

### **Unit Tests**

Create tests for gallery service:

**File:** `tests/test_gallery_service.py`

```python
from django.test import TestCase
from unittest.mock import patch, Mock
from services.gallery_service import GalleryService, GalleryAPIError

class GalleryServiceTestCase(TestCase):
    """Test Gallery Service"""
    
    def setUp(self):
        self.service = GalleryService()
    
    @patch('requests.request')
    def test_notify_trip_published_success(self, mock_request):
        """Test successful gallery creation"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'success': True,
            'gallery': {
                'id': 'gallery-test-123',
                'name': 'Test Trip',
                'source_trip_id': '123'
            }
        }
        mock_request.return_value = mock_response
        
        result = self.service.notify_trip_published(
            trip_id=123,
            title='Test Trip',
            creator_id=1,
            creator_username='testuser',
            creator_avatar='https://example.com/avatar.jpg',
            level=2
        )
        
        self.assertEqual(result['gallery']['id'], 'gallery-test-123')
    
    @patch('requests.request')
    def test_notify_trip_published_timeout(self, mock_request):
        """Test gallery creation timeout"""
        mock_request.side_effect = requests.exceptions.Timeout()
        
        with self.assertRaises(GalleryAPIError):
            self.service.notify_trip_published(
                trip_id=123,
                title='Test Trip',
                creator_id=1,
                creator_username='testuser',
                creator_avatar='',
                level=2
            )
```

### **Integration Tests**

Test trip-gallery lifecycle:

**File:** `tests/test_trip_gallery_integration.py`

```python
from django.test import TestCase
from unittest.mock import patch
from trips.models import Trip

class TripGalleryIntegrationTestCase(TestCase):
    """Test trip-gallery integration"""
    
    @patch('services.gallery_service.GalleryService.notify_trip_published')
    def test_trip_creation_creates_gallery(self, mock_notify):
        """Test that creating approved trip creates gallery"""
        mock_notify.return_value = {
            'gallery': {'id': 'gallery-test-123'}
        }
        
        # Create approved trip
        trip = Trip.objects.create(
            title='Test Trip',
            approval_status='A',
            # ... other required fields ...
        )
        
        # Verify gallery creation was called
        mock_notify.assert_called_once()
        
        # Verify gallery_id stored
        trip.refresh_from_db()
        self.assertEqual(trip.gallery_id, 'gallery-test-123')
```

---

## 📝 Error Handling Guidelines

### **Error Scenarios:**

1. **Gallery API Timeout (30s)**
   - Log error
   - Continue with trip operation
   - Set gallery_id to None
   - Admin notification (optional)

2. **Gallery API Returns Error**
   - Log error with response details
   - Continue with trip operation
   - Retry mechanism (optional)

3. **Network Failure**
   - Log error
   - Continue with trip operation
   - Queue for retry (optional)

4. **Invalid Response (no gallery_id)**
   - Log warning
   - Continue with trip operation
   - Set gallery_id to None

### **Logging Best Practices:**

```python
import logging

logger = logging.getLogger(__name__)

# Success
logger.info(f"✅ Gallery {gallery_id} created for trip {trip_id}")

# Warning (non-critical)
logger.warning(f"⚠️ Failed to sync gallery name for trip {trip_id}: {error}")

# Error (requires attention)
logger.error(f"❌ Gallery API error for trip {trip_id}: {error}")
```

---

## 🔧 Configuration API Endpoints (NEW - HIGH PRIORITY)

### GET `/api/settings/gallery-config/`

**Description:** Get current gallery system configuration for Flutter app.

**Authentication:** Optional (public endpoint)

**Response (200 OK):**
```json
{
  "enabled": true,
  "autoCreate": true,
  "allowManualCreation": true,
  "apiUrl": "https://media.ad4x4.com",
  "timeout": 30,
  "features": {
    "allowUserUploads": true,
    "allowUserDeletes": true,
    "maxPhotoSize": 10485760,
    "supportedFormats": ["jpg", "jpeg", "png", "heic"]
  }
}
```

**Backend Implementation:**
```python
from django.http import JsonResponse
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # Cache for 15 minutes
def get_gallery_configuration(request):
    """Get gallery system configuration"""
    try:
        settings = GlobalSettings.objects.first()
        
        return JsonResponse({
            'enabled': settings.enable_gallery_system,
            'autoCreate': settings.auto_create_trip_gallery,
            'allowManualCreation': settings.allow_manual_gallery_creation,
            'apiUrl': settings.gallery_api_url,
            'timeout': settings.gallery_api_timeout,
            'features': {
                'allowUserUploads': True,
                'allowUserDeletes': True,
                'maxPhotoSize': 10485760,  # 10MB
                'supportedFormats': ['jpg', 'jpeg', 'png', 'heic']
            }
        })
    except Exception as e:
        # Return defaults if settings not found
        return JsonResponse({
            'enabled': True,
            'autoCreate': True,
            'allowManualCreation': True,
            'apiUrl': 'https://media.ad4x4.com',
            'timeout': 30,
            'features': {
                'allowUserUploads': True,
                'allowUserDeletes': True,
                'maxPhotoSize': 10485760,
                'supportedFormats': ['jpg', 'jpeg', 'png', 'heic']
            }
        })
```

---

## 🚀 Deployment Checklist

### **Pre-Deployment:**
- [ ] **Gallery configuration migration** created and tested (NEW - CRITICAL)
- [ ] **Default configuration** values set in global_settings (NEW)
- [ ] **GET /api/settings/gallery-config/** endpoint deployed (NEW)
- [ ] Database migration created and reviewed
- [ ] Gallery service updated to load from database (MODIFIED)
- [ ] Gallery service code reviewed
- [ ] Unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Configuration caching tested (NEW)
- [ ] Logging configured correctly
- [ ] Error handling tested

### **Deployment Steps:**

1. **Database Migration**
   ```bash
   # Run on staging first
   python manage.py migrate
   
   # Verify column added
   python manage.py dbshell
   \d trips  # Check gallery_id column exists
   ```

2. **Deploy Code**
   - Deploy gallery_service.py
   - Deploy updated views
   - Deploy updated serializers

3. **Verification**
   - Create test trip → Verify gallery created
   - Update trip title → Verify gallery renamed
   - Delete trip → Verify gallery deleted
   - Check logs for errors

4. **Monitor**
   - Watch error logs for Gallery API failures
   - Monitor response times
   - Check database for gallery_id population

---

## 📊 API Endpoint Summary

### **Gallery API Webhooks (You Will Call These):**

| Endpoint | Method | Purpose | When to Call |
|----------|--------|---------|--------------|
| `/api/webhooks/trip/published` | POST | Create gallery | Trip approved/published |
| `/api/webhooks/trip/renamed` | POST | Rename gallery | Trip title updated |
| `/api/webhooks/trip/deleted` | POST | Delete gallery | Trip deleted |
| `/api/webhooks/trip/restored` | POST | Restore gallery | Trip restored (if soft delete) |

### **Request/Response Examples:**

**Create Gallery:**
```http
POST https://media.ad4x4.com/api/webhooks/trip/published
Content-Type: application/json

{
  "trip_id": "123",
  "title": "Desert Safari - January 2025",
  "creator_id": 456,
  "creator_username": "hani_ad4x4",
  "creator_avatar": "https://ap.ad4x4.com/media/avatars/hani.jpg",
  "level": 2
}

Response 200:
{
  "success": true,
  "gallery": {
    "id": "gallery-abc123-def456-ghi789",
    "name": "Desert Safari - January 2025",
    "source_trip_id": "123",
    "auto_created": true,
    "created_at": "2025-01-07T10:00:00Z"
  },
  "created": true
}
```

**Rename Gallery:**
```http
POST https://media.ad4x4.com/api/webhooks/trip/renamed
Content-Type: application/json

{
  "trip_id": "123",
  "new_title": "Desert Safari - January 2025 (Updated)"
}

Response 200:
{
  "success": true,
  "gallery_id": "gallery-abc123-def456-ghi789",
  "updated": true,
  "new_name": "Desert Safari - January 2025 (Updated)"
}
```

**Delete Gallery:**
```http
POST https://media.ad4x4.com/api/webhooks/trip/deleted
Content-Type: application/json

{
  "trip_id": "123"
}

Response 200:
{
  "success": true,
  "gallery_id": "gallery-abc123-def456-ghi789",
  "deleted": true,
  "soft_deleted_at": "2025-01-07T16:00:00Z"
}
```

---

## 🔍 Troubleshooting

### **Common Issues:**

**1. "Gallery API not responding"**
- Check network connectivity: `curl https://media.ad4x4.com/health`
- Verify Gallery API is running
- Check firewall rules

**2. "Gallery ID not stored in trip"**
- Check Gallery API response includes `gallery.id`
- Verify `trip.save()` called after setting gallery_id
- Check database migration applied

**3. "Gallery created but not visible in app"**
- Verify trip serializer includes `gallery_id` field
- Check API response includes gallery_id
- Verify Flutter app reading `gallery_id` field

**4. "Duplicate galleries created"**
- Gallery API is idempotent - calling multiple times won't create duplicates
- Check `source_trip_id` in Gallery API to find existing gallery

---

## 📞 Support

**Gallery API Documentation:**  
`/home/user/flutter_app/docs/GALLERY-API-DOCUMENTATION.md` (2,319 lines)

**Gallery API Endpoints:**  
Lines 1730-1865: Trip Integration Webhooks

**Questions?**
- Review Gallery API documentation
- Check logs for error details
- Test with staging environment first

**Flutter Team Contact:**  
See `GALLERY_INTEGRATION_FLUTTER_WORK.md` for Flutter implementation details

---

## ✅ Acceptance Criteria

### **Definition of Done:**

- [ ] Database migration adds `gallery_id` field
- [ ] Gallery service created with webhook methods
- [ ] Trip creation calls `notify_trip_published`
- [ ] Trip update calls `notify_trip_renamed` (if title changed)
- [ ] Trip deletion calls `notify_trip_deleted`
- [ ] Trip API responses include `gallery_id` field
- [ ] Unit tests passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Logging implemented correctly
- [ ] Error handling graceful (doesn't break trip operations)
- [ ] Deployed to staging and verified
- [ ] Code reviewed and approved

---

**Timeline:** 6-8 hours  
**Priority:** 🔴 CRITICAL (blocks Flutter development)  
**Last Updated:** November 16, 2024  
**Document Version:** 1.0
