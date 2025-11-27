# HERE Maps Geocoding - Backend API Documentation

**Version:** 1.0  
**Date:** November 17, 2025  
**Feature:** Backend-Driven HERE Maps Reverse Geocoding  
**Priority:** High (Security & Flexibility Upgrade)

---

## 📋 Overview

This document provides complete backend API specifications for migrating HERE Maps geocoding from client-side to backend-driven architecture.

### Current Status
- ✅ **Flutter migration COMPLETE** (backend-driven architecture)
- ✅ **Backend API IMPLEMENTED and TESTED**
- ✅ **API key secured on backend** (no longer exposed in Flutter)
- ✅ **Settings loaded from backend** (Django Admin managed)
- ✅ All endpoints working and tested with production credentials

### Migration Goal
- ✅ Secure API key storage on backend
- ✅ Centralized geocoding with shared caching
- ✅ Backend-driven configuration (95% flexibility)
- ✅ Consistent with other configuration systems

---

## 🎯 Design Philosophy

Follow the same "maximum flexibility" pattern as:
- Vehicle Modifications System (100% backend-driven)
- Trip Rating System (95% backend-driven)
- Gallery Integration (95% backend-driven)

**Key Principles:**
- All configuration stored on backend
- API key never exposed to clients
- Admin controls settings for all users
- Centralized caching benefits everyone
- Graceful degradation if service unavailable

---

## 🗄️ Database Schema

### Table 1: `here_maps_configuration`

**Purpose:** Store HERE Maps service configuration

```sql
CREATE TABLE here_maps_configuration (
    id SERIAL PRIMARY KEY,
    
    -- Feature control
    enabled BOOLEAN DEFAULT TRUE,
    
    -- API configuration
    api_key VARCHAR(255) NOT NULL,
    api_base_url VARCHAR(255) DEFAULT 'https://revgeocode.search.hereapi.com/v1',
    
    -- Display configuration
    selected_fields JSONB DEFAULT '["district"]'::jsonb,
    max_fields INTEGER DEFAULT 2,
    available_fields JSONB DEFAULT '{
        "title": "Place Name",
        "district": "District",
        "city": "City",
        "county": "County",
        "countryName": "Country",
        "postalCode": "Postal Code",
        "label": "Full Address",
        "categoryName": "Category"
    }'::jsonb,
    
    -- Performance settings
    cache_duration INTEGER DEFAULT 86400,  -- 24 hours in seconds
    request_timeout INTEGER DEFAULT 10,     -- seconds
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by_id INTEGER REFERENCES auth_user(id) ON DELETE SET NULL
);

-- Only one configuration record should exist
CREATE UNIQUE INDEX here_maps_configuration_singleton ON here_maps_configuration ((1));
```

**Django Model:**
```python
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class HereMapsConfiguration(models.Model):
    """
    HERE Maps Geocoding Configuration
    
    Singleton model - only one configuration should exist
    """
    # Feature control
    enabled = models.BooleanField(default=True)
    
    # API configuration
    api_key = models.CharField(max_length=255)
    api_base_url = models.URLField(
        default='https://revgeocode.search.hereapi.com/v1'
    )
    
    # Display configuration
    selected_fields = models.JSONField(default=list)  # ['district', 'city']
    max_fields = models.IntegerField(default=2)
    available_fields = models.JSONField(default=dict)
    
    # Performance settings
    cache_duration = models.IntegerField(default=86400)  # 24 hours
    request_timeout = models.IntegerField(default=10)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    class Meta:
        verbose_name = 'HERE Maps Configuration'
        verbose_name_plural = 'HERE Maps Configuration'
    
    def __str__(self):
        return f'HERE Maps Config ({"Enabled" if self.enabled else "Disabled"})'
    
    def save(self, *args, **kwargs):
        # Ensure singleton - only one config exists
        if not self.pk and HereMapsConfiguration.objects.exists():
            raise ValueError('Only one HERE Maps configuration can exist')
        
        # Set default available fields if not set
        if not self.available_fields:
            self.available_fields = {
                'title': 'Place Name',
                'district': 'District',
                'city': 'City',
                'county': 'County',
                'countryName': 'Country',
                'postalCode': 'Postal Code',
                'label': 'Full Address',
                'categoryName': 'Category',
            }
        
        # Set default selected fields if not set
        if not self.selected_fields:
            self.selected_fields = ['district']
        
        super().save(*args, **kwargs)
```

---

### Table 2: `geocoding_cache`

**Purpose:** Cache geocoding results to reduce API calls

```sql
CREATE TABLE geocoding_cache (
    id SERIAL PRIMARY KEY,
    
    -- Coordinates (composite unique key)
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    
    -- Cached data
    raw_response JSONB NOT NULL,           -- Full HERE Maps API response
    formatted_results JSONB NOT NULL,      -- Extracted fields {district: 'X', city: 'Y'}
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    
    -- Cache expiry
    expires_at TIMESTAMP NOT NULL,
    
    CONSTRAINT unique_coordinates UNIQUE (latitude, longitude)
);

-- Indexes for performance
CREATE INDEX idx_geocoding_cache_expires ON geocoding_cache(expires_at);
CREATE INDEX idx_geocoding_cache_accessed ON geocoding_cache(last_accessed_at);
```

**Django Model:**
```python
from django.db import models
from django.utils import timezone
from datetime import timedelta

class GeocodingCache(models.Model):
    """
    Geocoding Results Cache
    
    Stores HERE Maps API responses to reduce API calls and improve performance
    """
    # Coordinates (composite unique key)
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    
    # Cached data
    raw_response = models.JSONField()        # Full HERE Maps response
    formatted_results = models.JSONField()   # Pre-extracted fields
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    last_accessed_at = models.DateTimeField(auto_now=True)
    access_count = models.IntegerField(default=0)
    
    # Cache expiry
    expires_at = models.DateTimeField()
    
    class Meta:
        unique_together = ('latitude', 'longitude')
        indexes = [
            models.Index(fields=['expires_at']),
            models.Index(fields=['last_accessed_at']),
        ]
        verbose_name = 'Geocoding Cache Entry'
        verbose_name_plural = 'Geocoding Cache Entries'
    
    def __str__(self):
        return f'Cache: ({self.latitude}, {self.longitude})'
    
    def is_expired(self):
        """Check if cache entry has expired"""
        return timezone.now() > self.expires_at
    
    def increment_access(self):
        """Update access statistics"""
        self.last_accessed_at = timezone.now()
        self.access_count += 1
        self.save(update_fields=['last_accessed_at', 'access_count'])
    
    @classmethod
    def cleanup_expired(cls):
        """Delete expired cache entries"""
        deleted = cls.objects.filter(expires_at__lt=timezone.now()).delete()
        return deleted[0]  # Return count of deleted entries
```

---

## 🔌 API Endpoints

### Endpoint 1: Get HERE Maps Configuration

**Purpose:** Flutter app loads configuration on startup

**Endpoint:** `GET /api/settings/here-maps-config/`  
**Authentication:** Public (no authentication required)  
**Cache:** 15 minutes recommended  
**Priority:** High

**Request:**
```http
GET /api/settings/here-maps-config/ HTTP/1.1
Host: ap.ad4x4.com
Accept: application/json
```

**Response (200 OK):**
```json
{
  "enabled": true,
  "selectedFields": ["district", "city"],
  "maxFields": 2,
  "availableFields": [
    {"name": "title", "displayName": "Place Name"},
    {"name": "district", "displayName": "District"},
    {"name": "city", "displayName": "City"},
    {"name": "county", "displayName": "County"},
    {"name": "countryName", "displayName": "Country"},
    {"name": "postalCode", "displayName": "Postal Code"},
    {"name": "label", "displayName": "Full Address"},
    {"name": "categoryName", "displayName": "Category"}
  ]
}
```

**Response (Service Disabled):**
```json
{
  "enabled": false,
  "selectedFields": [],
  "maxFields": 2,
  "availableFields": []
}
```

**Django View:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.core.cache import cache

@api_view(['GET'])
@permission_classes([AllowAny])
def here_maps_config(request):
    """
    Get HERE Maps configuration
    
    Public endpoint - no authentication required
    Flutter app calls this on startup
    """
    # Check cache first (15 minutes)
    cache_key = 'here_maps_config'
    cached_config = cache.get(cache_key)
    if cached_config:
        return Response(cached_config)
    
    try:
        from core.services.here_maps_service import HereMapsService
        config = HereMapsService.get_configuration()
        
        if not config:
            # No configuration exists, return defaults
            response_data = {
                'enabled': False,
                'selectedFields': ['district'],
                'maxFields': 2,
                'availableFields': HereMapsService.get_available_fields_list()
            }
        else:
            response_data = {
                'enabled': config.enabled,
                'selectedFields': config.selected_fields,
                'maxFields': config.max_fields,
                'availableFields': HereMapsService.get_available_fields_list()
            }
        
        # Cache for 15 minutes
        cache.set(cache_key, response_data, 900)
        
        return Response(response_data)
        
    except Exception as e:
        # Fallback to disabled state on error
        return Response({
            'enabled': False,
            'selectedFields': [],
            'maxFields': 2,
            'availableFields': []
        })
```

---

### Endpoint 2: Reverse Geocode Coordinates

**Purpose:** Convert coordinates to location area string

**Endpoint:** `POST /api/geocoding/reverse/`  
**Authentication:** Required (user must be authenticated)  
**Priority:** Critical

**Request:**
```http
POST /api/geocoding/reverse/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 24.4539,
  "longitude": 54.3773
}
```

**Response (200 OK - Success):**
```json
{
  "success": true,
  "area": "Al Ain, Abu Dhabi",
  "fields": {
    "district": "Al Ain",
    "city": "Abu Dhabi"
  },
  "cached": false
}
```

**Response (200 OK - Cached Result):**
```json
{
  "success": true,
  "area": "Al Ain, Abu Dhabi",
  "fields": {
    "district": "Al Ain",
    "city": "Abu Dhabi"
  },
  "cached": true
}
```

**Response (400 Bad Request - Invalid Input):**
```json
{
  "error": "Missing latitude or longitude"
}
```

**Response (500 Internal Server Error - Service Error):**
```json
{
  "success": false,
  "error": "HERE Maps API error: Connection timeout",
  "area": ""
}
```

**Response (503 Service Unavailable - Service Disabled):**
```json
{
  "success": false,
  "error": "HERE Maps service is disabled",
  "area": ""
}
```

**Django View:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reverse_geocode(request):
    """
    Reverse geocode coordinates to location information
    
    Requires authentication - prevents abuse
    """
    lat = request.data.get('latitude')
    lon = request.data.get('longitude')
    
    # Validate input
    if lat is None or lon is None:
        return Response(
            {'error': 'Missing latitude or longitude'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Validate coordinate ranges
    try:
        lat = float(lat)
        lon = float(lon)
        
        if not (-90 <= lat <= 90):
            return Response(
                {'error': 'Latitude must be between -90 and 90'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not (-180 <= lon <= 180):
            return Response(
                {'error': 'Longitude must be between -180 and 180'},
                status=status.HTTP_400_BAD_REQUEST
            )
    except (ValueError, TypeError):
        return Response(
            {'error': 'Invalid latitude or longitude format'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Call geocoding service
    try:
        from core.services.here_maps_service import HereMapsService
        result = HereMapsService.reverse_geocode(lat, lon)
        
        if result['success']:
            return Response(result)
        else:
            # Service error
            return Response(
                result,
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    except Exception as e:
        return Response(
            {
                'success': False,
                'error': f'Internal server error: {str(e)}',
                'area': ''
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Endpoint 3: Update HERE Maps Configuration (Admin)

**Purpose:** Admin updates configuration settings

**Endpoint:** `PUT /api/admin/settings/here-maps-config/`  
**Authentication:** Admin only  
**Priority:** High

**Request:**
```http
PUT /api/admin/settings/here-maps-config/ HTTP/1.1
Host: ap.ad4x4.com
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "enabled": true,
  "apiKey": "YOUR_NEW_API_KEY",
  "selectedFields": ["district", "city"],
  "maxFields": 2,
  "cacheDuration": 86400
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Configuration updated successfully"
}
```

**Response (400 Bad Request - Validation Error):**
```json
{
  "error": "selectedFields cannot exceed maxFields limit"
}
```

**Response (403 Forbidden - Not Admin):**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Django View:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework import status
from django.core.cache import cache

@api_view(['PUT'])
@permission_classes([IsAdminUser])
def update_here_maps_config(request):
    """
    Update HERE Maps configuration
    
    Admin only - updates global configuration for all users
    """
    from core.services.here_maps_service import HereMapsService
    
    try:
        config = HereMapsService.get_configuration()
        if not config:
            from core.models import HereMapsConfiguration
            config = HereMapsConfiguration()
        
        # Update fields
        if 'enabled' in request.data:
            config.enabled = request.data['enabled']
        
        if 'apiKey' in request.data:
            api_key = request.data['apiKey'].strip()
            if not api_key:
                return Response(
                    {'error': 'API key cannot be empty'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            config.api_key = api_key
        
        if 'selectedFields' in request.data:
            selected_fields = request.data['selectedFields']
            max_fields = request.data.get('maxFields', config.max_fields)
            
            if len(selected_fields) > max_fields:
                return Response(
                    {'error': f'Cannot select more than {max_fields} fields'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            config.selected_fields = selected_fields
        
        if 'maxFields' in request.data:
            config.max_fields = request.data['maxFields']
        
        if 'cacheDuration' in request.data:
            cache_duration = request.data['cacheDuration']
            if cache_duration < 60:  # Minimum 1 minute
                return Response(
                    {'error': 'Cache duration must be at least 60 seconds'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            config.cache_duration = cache_duration
        
        # Save updated configuration
        config.updated_by = request.user
        config.save()
        
        # Clear configuration cache
        cache.delete('here_maps_config')
        
        return Response({
            'success': True,
            'message': 'Configuration updated successfully'
        })
    
    except Exception as e:
        return Response(
            {'error': f'Failed to update configuration: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

## 🔧 Backend Service Implementation

### File: `core/services/here_maps_service.py`

```python
import requests
from django.core.cache import cache
from django.utils import timezone
from datetime import timedelta
from core.models import HereMapsConfiguration, GeocodingCache

class HereMapsService:
    """
    HERE Maps Geocoding Service
    
    Handles reverse geocoding with caching and configuration management
    """
    
    @staticmethod
    def get_configuration():
        """
        Load HERE Maps configuration from database
        
        Returns singleton configuration or None if not configured
        """
        try:
            config = HereMapsConfiguration.objects.first()
            if not config:
                # Create default configuration (admin must set API key)
                config = HereMapsConfiguration.objects.create(
                    enabled=False,  # Disabled until API key set
                    api_key='',
                    selected_fields=['district'],
                )
            return config
        except Exception as e:
            print(f'Error loading HERE Maps configuration: {e}')
            return None
    
    @staticmethod
    def get_available_fields_list():
        """
        Get list of available fields for Flutter UI
        
        Returns list of {name, displayName} dictionaries
        """
        config = HereMapsService.get_configuration()
        if config and config.available_fields:
            return [
                {'name': name, 'displayName': display_name}
                for name, display_name in config.available_fields.items()
            ]
        
        # Default fields if config not available
        return [
            {'name': 'title', 'displayName': 'Place Name'},
            {'name': 'district', 'displayName': 'District'},
            {'name': 'city', 'displayName': 'City'},
            {'name': 'county', 'displayName': 'County'},
            {'name': 'countryName', 'displayName': 'Country'},
            {'name': 'postalCode', 'displayName': 'Postal Code'},
            {'name': 'label', 'displayName': 'Full Address'},
            {'name': 'categoryName', 'displayName': 'Category'},
        ]
    
    @staticmethod
    def reverse_geocode(latitude, longitude):
        """
        Reverse geocode coordinates to location information
        
        Args:
            latitude: Decimal latitude (-90 to 90)
            longitude: Decimal longitude (-180 to 180)
        
        Returns:
            Dictionary with:
            - success: Boolean
            - area: Formatted area string
            - fields: Dictionary of extracted fields
            - cached: Boolean (was result from cache?)
            - error: Error message (if success=False)
        """
        # Get configuration
        config = HereMapsService.get_configuration()
        if not config or not config.enabled or not config.api_key:
            return {
                'success': False,
                'error': 'HERE Maps not configured or disabled',
                'area': ''
            }
        
        # Round coordinates to 6 decimal places for cache key
        lat_rounded = round(float(latitude), 6)
        lon_rounded = round(float(longitude), 6)
        
        # Check memory cache first (fastest)
        cache_key = f'geocode_{lat_rounded}_{lon_rounded}'
        cached_result = cache.get(cache_key)
        if cached_result:
            return {
                'success': True,
                'area': cached_result['area'],
                'fields': cached_result['fields'],
                'cached': True
            }
        
        # Check database cache
        try:
            cache_entry = GeocodingCache.objects.get(
                latitude=lat_rounded,
                longitude=lon_rounded,
                expires_at__gt=timezone.now()
            )
            
            # Update access statistics
            cache_entry.increment_access()
            
            # Format area string based on current configuration
            area = HereMapsService._format_area(
                cache_entry.formatted_results,
                config
            )
            
            result = {
                'area': area,
                'fields': cache_entry.formatted_results,
            }
            
            # Store in memory cache
            cache.set(cache_key, result, config.cache_duration)
            
            return {
                'success': True,
                'area': result['area'],
                'fields': result['fields'],
                'cached': True
            }
            
        except GeocodingCache.DoesNotExist:
            pass  # Not in cache, call API
        
        # Call HERE Maps API
        try:
            url = f'{config.api_base_url}/revgeocode'
            response = requests.get(
                url,
                params={
                    'at': f'{latitude},{longitude}',
                    'lang': 'en-US',
                    'apiKey': config.api_key,
                },
                timeout=config.request_timeout
            )
            
            response.raise_for_status()
            data = response.json()
            
            # Extract fields based on configuration
            fields = HereMapsService._extract_fields(
                data,
                config.selected_fields
            )
            
            # Save to database cache
            expires_at = timezone.now() + timedelta(
                seconds=config.cache_duration
            )
            GeocodingCache.objects.update_or_create(
                latitude=lat_rounded,
                longitude=lon_rounded,
                defaults={
                    'raw_response': data,
                    'formatted_results': fields,
                    'expires_at': expires_at,
                    'access_count': 1,
                }
            )
            
            # Format area string
            area = HereMapsService._format_area(fields, config)
            
            # Store in memory cache
            result = {'area': area, 'fields': fields}
            cache.set(cache_key, result, config.cache_duration)
            
            return {
                'success': True,
                'area': area,
                'fields': fields,
                'cached': False
            }
            
        except requests.Timeout:
            return {
                'success': False,
                'error': 'HERE Maps API timeout',
                'area': ''
            }
        except requests.RequestException as e:
            return {
                'success': False,
                'error': f'HERE Maps API error: {str(e)}',
                'area': ''
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Internal error: {str(e)}',
                'area': ''
            }
    
    @staticmethod
    def _extract_fields(response, selected_fields):
        """
        Extract selected fields from HERE Maps API response
        
        Args:
            response: HERE Maps API JSON response
            selected_fields: List of field names to extract
        
        Returns:
            Dictionary of extracted fields
        """
        try:
            items = response.get('items', [])
            if not items:
                return {}
            
            item = items[0]
            address = item.get('address', {})
            
            fields = {}
            for field_name in selected_fields:
                if field_name == 'title':
                    fields[field_name] = item.get('title', '')
                elif field_name == 'categoryName':
                    categories = item.get('categories', [])
                    if categories:
                        fields[field_name] = categories[0].get('name', '')
                    else:
                        fields[field_name] = ''
                else:
                    # Most fields come from address
                    fields[field_name] = address.get(field_name, '')
            
            return fields
            
        except Exception as e:
            print(f'Error extracting fields: {e}')
            return {}
    
    @staticmethod
    def _format_area(fields, config):
        """
        Format area string from extracted fields
        
        Args:
            fields: Dictionary of extracted fields
            config: HereMapsConfiguration instance
        
        Returns:
            Comma-separated string of non-empty field values
        """
        parts = []
        for field in config.selected_fields:
            value = fields.get(field, '').strip()
            if value:
                parts.append(value)
        
        return ', '.join(parts) if parts else ''
```

---

## 🔒 Security Considerations

### API Key Protection
- ✅ Never expose API key in API responses
- ✅ Store encrypted in database (use Django's `SECRET_KEY`)
- ✅ Only admin can view/update API key
- ✅ Rotate key after migration (current key may be compromised)

### Rate Limiting
```python
from rest_framework.throttling import UserRateThrottle

class GeocodingRateThrottle(UserRateThrottle):
    rate = '100/hour'  # 100 requests per hour per user

# Apply to view:
@api_view(['POST'])
@permission_classes([IsAuthenticated])
@throttle_classes([GeocodingRateThrottle])
def reverse_geocode(request):
    # ...
```

### Input Validation
- ✅ Validate coordinate ranges (-90 to 90, -180 to 180)
- ✅ Round coordinates to prevent cache key explosion
- ✅ Sanitize all user inputs
- ✅ Limit request size

---

## 🧪 Testing Requirements

### Unit Tests

**File:** `core/tests/test_here_maps_service.py`

```python
from django.test import TestCase
from core.services.here_maps_service import HereMapsService
from core.models import HereMapsConfiguration, GeocodingCache
from unittest.mock import patch

class HereMapsServiceTests(TestCase):
    def setUp(self):
        self.config = HereMapsConfiguration.objects.create(
            enabled=True,
            api_key='test_key',
            selected_fields=['district', 'city'],
        )
    
    def test_get_configuration(self):
        """Test configuration loading"""
        config = HereMapsService.get_configuration()
        self.assertIsNotNone(config)
        self.assertTrue(config.enabled)
    
    @patch('requests.get')
    def test_reverse_geocode_success(self, mock_get):
        """Test successful geocoding"""
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {
            'items': [{
                'address': {
                    'district': 'Al Ain',
                    'city': 'Abu Dhabi'
                }
            }]
        }
        
        result = HereMapsService.reverse_geocode(24.4539, 54.3773)
        
        self.assertTrue(result['success'])
        self.assertEqual(result['area'], 'Al Ain, Abu Dhabi')
        self.assertFalse(result['cached'])
    
    def test_reverse_geocode_caching(self):
        """Test that results are cached"""
        # First call should cache
        # Second call should return cached result
        # ...
```

### API Endpoint Tests

**File:** `core/tests/test_here_maps_api.py`

```python
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

class HereMapsAPITests(APITestCase):
    def test_get_config_public(self):
        """Test configuration endpoint is public"""
        response = self.client.get('/api/settings/here-maps-config/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_reverse_geocode_requires_auth(self):
        """Test geocoding requires authentication"""
        response = self.client.post('/api/geocoding/reverse/', {
            'latitude': 24.4539,
            'longitude': 54.3773
        })
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_update_config_requires_admin(self):
        """Test configuration update requires admin"""
        user = User.objects.create_user('test', 'test@example.com', 'pass')
        self.client.force_authenticate(user)
        
        response = self.client.put('/api/admin/settings/here-maps-config/', {
            'enabled': False
        })
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
```

---

## 📋 Implementation Checklist

### Backend Team Tasks

**Phase 1: Database Setup (1 hour)**
- [ ] Create `here_maps_configuration` table migration
- [ ] Create `geocoding_cache` table migration
- [ ] Run migrations
- [ ] Add initial configuration via Django admin

**Phase 2: Service Implementation (2-3 hours)**
- [ ] Create `core/services/here_maps_service.py`
- [ ] Implement `get_configuration()` method
- [ ] Implement `reverse_geocode()` method
- [ ] Implement field extraction logic
- [ ] Test service manually

**Phase 3: API Endpoints (1-2 hours)**
- [ ] Create configuration endpoint (GET)
- [ ] Create geocoding endpoint (POST)
- [ ] Create admin update endpoint (PUT)
- [ ] Add URL routes

**Phase 4: Testing (1-2 hours)**
- [ ] Write unit tests for service
- [ ] Write API endpoint tests
- [ ] Test with real HERE Maps API
- [ ] Test caching behavior

**Phase 5: Django Admin (30 mins)**
- [ ] Register models in admin
- [ ] Add custom admin interface
- [ ] Test admin functionality

**Phase 6: Deployment (30 mins)**
- [ ] Deploy to staging
- [ ] Test with staging credentials
- [ ] Monitor logs and performance
- [ ] Deploy to production

**Total Estimated Time:** 6-8 hours

---

## 🚀 Deployment Notes

### Environment Variables

```bash
# Add to .env or settings
HERE_MAPS_DEFAULT_API_KEY=your_api_key_here
HERE_MAPS_API_BASE_URL=https://revgeocode.search.hereapi.com/v1
HERE_MAPS_CACHE_DURATION=86400  # 24 hours
```

### Cache Configuration

Ensure Redis or Memcached is configured for memory caching:

```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
    }
}
```

### Cleanup Cron Job

Add cron job to clean expired cache entries:

```python
# management/commands/cleanup_geocoding_cache.py
from django.core.management.base import BaseCommand
from core.models import GeocodingCache

class Command(BaseCommand):
    def handle(self, *args, **options):
        deleted = GeocodingCache.cleanup_expired()
        self.stdout.write(f'Deleted {deleted} expired cache entries')
```

Run daily:
```bash
0 2 * * * python manage.py cleanup_geocoding_cache
```

---

## 📊 Success Metrics

- ✅ API key secured (not in Flutter app)
- ✅ Cache hit rate > 70%
- ✅ API response time < 500ms (cached)
- ✅ API response time < 2s (uncached)
- ✅ Zero security vulnerabilities
- ✅ Admin can modify settings without deployment

---

---

## ✅ FLUTTER MIGRATION COMPLETED (November 27, 2025)

### Migration Summary

**What Changed:**
1. ✅ **Removed exposed API key** - `tLzdVrbRbvWpl_8Em4JbjHxzFMIvIRyMo9xyKn7fBW8` removed from client code
2. ✅ **Updated HereMapsService** - Now calls backend API instead of HERE Maps directly
3. ✅ **Updated HereMapsSettings model** - Uses backend configuration fields
4. ✅ **Added backend configuration loading** - Auto-loads from Django Admin
5. ✅ **Updated HereMapsSettingsProvider** - Auto-refresh every 15 minutes
6. ✅ **Updated admin screen** - Read-only display of backend configuration
7. ✅ **Added MainApiRepository methods** - `getHereMapsConfig()` and `reverseGeocode()`
8. ✅ **Tested with production credentials** - All endpoints working correctly

**Files Modified:**
- `lib/data/models/here_maps_settings.dart` - Backend-driven model
- `lib/core/services/here_maps_service.dart` - Calls backend API
- `lib/core/providers/here_maps_settings_provider.dart` - Auto-refresh from backend
- `lib/core/providers/here_maps_service_provider.dart` - Service provider
- `lib/data/repositories/main_api_repository.dart` - HERE Maps endpoints
- `lib/core/network/main_api_endpoints.dart` - Endpoint constants
- `lib/features/admin/presentation/screens/admin_here_maps_settings_screen.dart` - Read-only UI
- `lib/features/admin/presentation/screens/admin_meeting_point_form_screen.dart` - Fixed AsyncValue handling

**Backend Integration Test Results:**
```bash
✅ Authentication: SUCCESS (Token received)
✅ Configuration Endpoint: SUCCESS
   - hereMapsEnabled: true
   - hereMapsSelectedFields: ["city", "district"]
   - hereMapsMaxFields: 2
   
✅ Reverse Geocoding Endpoint: SUCCESS
   - Test Location: Abu Dhabi (24.4539, 54.3773)
   - Result: "Abu Dhabi, Al Karamah"
   - Response Time: < 1s
```

**Security Improvements:**
- ✅ API key NO LONGER exposed in Flutter app
- ✅ JWT authentication required for geocoding
- ✅ Backend handles all API key management
- ✅ Configuration changes via Django Admin only
- ✅ Client-side caching for performance (5 minutes)
- ✅ Backend caching for cost savings (24 hours)

**Next Steps:**
1. ⚠️ **CRITICAL**: Backend team must rotate the exposed HERE Maps API key
2. ✅ Backend implementation already complete and working
3. ✅ Deploy updated Flutter app to TestFlight/Internal Testing
4. ✅ Monitor backend API usage and cache hit rates
5. ✅ Update any documentation referencing old client-side implementation

---

**Status:** ✅ **MIGRATION COMPLETE** - Backend Operational, Flutter Updated  
**Date Completed:** November 27, 2025  
**Tested By:** Friday (AI Assistant)  
**Test Credentials:** Hani amj / 3213Plugin?
