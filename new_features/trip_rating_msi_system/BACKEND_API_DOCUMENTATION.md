# Trip Rating & MSI System - Backend API Documentation

## 📋 Overview

**Feature Name:** Trip Rating & Member Satisfaction Index (MSI) System

**Purpose:** Enable members to rate completed trips and provide comprehensive analytics for admins to track member satisfaction and trip leader performance.

**API Version:** 2.0

**Created:** November 16, 2025
**Updated:** January 17, 2025 - Added flexible backend configuration

---

## 🎨 Design Philosophy

**Flexibility First**: This system is designed for maximum backend configurability:
- ✅ **All rating thresholds configurable** via global settings
- ✅ **Rating scale ranges backend-controlled** (supports 1-5, 1-10, etc.)
- ✅ **Color coding thresholds dynamic** - no hardcoded values in Flutter
- ✅ **Comment length limits configurable** without database migration
- ✅ **Future-ready for custom rating categories** and localization

**Key Principle:** Admins can adjust rating behavior without app updates or code changes.

---

## 🎯 Business Requirements

### Core Functionality:
1. Members can rate trips they completed (trip quality + leader performance)
2. One rating per member per trip (cannot edit after submission)
3. Only trips (not events) can be rated
4. Trip owners cannot rate their own trips
5. Ratings become available after trip completion
6. Automatic notification creation for pending ratings
7. Admin analytics with color-coded performance indicators

### Rating System (Backend Configurable):
- **Trip Rating:** Configurable range (default: 1-5 stars, integer)
- **Leader Rating:** Configurable range (default: 1-5 stars, integer)
- **Comment:** Optional text (configurable max length, default: 1000 characters)
- **Overall Score:** (tripRating + leaderRating) / 2

### Color Coding (Backend Configurable):
- 🟢 **Green (Excellent):** Default: 4.5 - 5.0 (configurable threshold)
- 🟡 **Yellow (Good):** Default: 3.5 - 4.4 (configurable threshold)
- 🔴 **Red (Needs Improvement):** Default: 0 - 3.4 (configurable threshold)
- ⚪ **Gray (Insufficient Data):** No ratings available

**Note:** All thresholds and colors loaded from `global_settings` table - no hardcoded values in client apps.

---

## 🗄️ Database Schema

### 1. Rating Configuration Table (NEW)

**Purpose:** Store all configurable rating system parameters.

```sql
CREATE TABLE rating_configuration (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(50) UNIQUE NOT NULL,
    config_value_json TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT NOW(),
    updated_by INTEGER REFERENCES users(id)
);

-- Insert default configuration
INSERT INTO rating_configuration (config_key, config_value_json, description) VALUES
(
    'rating_system_config',
    '{
        "rating_scale": {
            "min": 1,
            "max": 5,
            "step": 1,
            "display_type": "stars"
        },
        "thresholds": {
            "excellent": 4.5,
            "good": 3.5,
            "needs_improvement": 0
        },
        "colors": {
            "excellent": "#4CAF50",
            "good": "#FFC107",
            "needs_improvement": "#F44336",
            "insufficient_data": "#9E9E9E"
        },
        "labels": {
            "excellent": "Excellent",
            "good": "Good",
            "needs_improvement": "Needs Improvement",
            "insufficient_data": "No Ratings"
        },
        "comment_max_length": 1000,
        "features": {
            "allow_comments": true,
            "require_comments_below_threshold": 3.0,
            "enable_anonymous_ratings": false
        }
    }',
    'Main rating system configuration - thresholds, colors, and behavior'
);

-- Index for fast lookups
CREATE INDEX idx_rating_config_key ON rating_configuration(config_key);
```

**Configuration Fields Explained:**

| Field | Type | Purpose | Example |
|-------|------|---------|----------|
| `rating_scale.min` | Integer | Minimum rating value | 1 |
| `rating_scale.max` | Integer | Maximum rating value | 5 |
| `rating_scale.step` | Decimal | Rating increment | 1 (whole stars) or 0.5 (half stars) |
| `thresholds.excellent` | Decimal | Minimum score for green | 4.5 |
| `thresholds.good` | Decimal | Minimum score for yellow | 3.5 |
| `colors.excellent` | Hex | Color for excellent ratings | #4CAF50 |
| `comment_max_length` | Integer | Max comment characters | 1000 |
| `features.allow_comments` | Boolean | Enable/disable comments | true |

**Why JSON Storage?**
- Flexible: Add new settings without ALTER TABLE
- Versioned: Easy to track configuration history
- Atomic: All settings load in one query
- Frontend-friendly: Direct JSON serialization

---

### 2. Alternative: Global Settings Table Extension

If you prefer extending existing `global_settings` table:

```sql
-- Add to existing global_settings table
ALTER TABLE global_settings ADD COLUMN rating_config_json TEXT;

-- Set default configuration
UPDATE global_settings SET rating_config_json = '{
    "rating_scale": {"min": 1, "max": 5, "step": 1},
    "thresholds": {"excellent": 4.5, "good": 3.5},
    "colors": {"excellent": "#4CAF50", "good": "#FFC107", "needs_improvement": "#F44336"},
    "comment_max_length": 1000
}' WHERE id = 1;
```

---

### 3. TripRating Table

```sql
CREATE TABLE trip_ratings (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_rating INTEGER NOT NULL,
    leader_rating INTEGER NOT NULL,
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT unique_user_trip_rating UNIQUE (trip_id, user_id)
    -- Note: Rating value validation now handled by application layer using config
    -- Comment length validation now handled by application layer using config
);

-- Indexes for performance
CREATE INDEX idx_trip_ratings_trip_id ON trip_ratings(trip_id);
CREATE INDEX idx_trip_ratings_user_id ON trip_ratings(user_id);
CREATE INDEX idx_trip_ratings_created_at ON trip_ratings(created_at DESC);
```

### Field Descriptions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | INTEGER | Yes | Primary key (auto-increment) |
| trip_id | INTEGER | Yes | Foreign key to trips table |
| user_id | INTEGER | Yes | Foreign key to users table (reviewer) |
| trip_rating | INTEGER | Yes | Trip quality rating (1-5 stars) |
| leader_rating | INTEGER | Yes | Leader performance rating (1-5 stars) |
| comment | TEXT | No | Optional feedback text (max 1000 chars) |
| created_at | TIMESTAMP | Yes | When rating was submitted |
| updated_at | TIMESTAMP | No | Last update timestamp (for future edits) |

### Business Logic Constraints:

```python
def validate_trip_rating(user_id, trip_id, trip_rating, leader_rating):
    """
    Validation rules before inserting rating:
    
    1. User must have attended the trip (registration status = 'completed')
    2. Trip end date must be in the past
    3. Trip must NOT be an event (trip.is_event = False)
    4. User cannot be the trip owner (user_id != trip.owner_id)
    5. User has not already rated this trip
    6. Both ratings must be 1-5 (enforced by CHECK constraint)
    7. Comment length <= 1000 characters (if provided)
    """
    pass
```

---

## 🔌 API Endpoints

### 0. Get Rating Configuration (NEW - HIGH PRIORITY)

**Endpoint:** `GET /api/settings/rating-config/`

**Description:** Get current rating system configuration. This endpoint MUST be called by Flutter app on startup to load dynamic thresholds and colors.

**Authentication:** Optional (public endpoint for transparency)

**Permissions:** Public

**Response (200 OK):**
```json
{
  "ratingScale": {
    "min": 1,
    "max": 5,
    "step": 1,
    "displayType": "stars"
  },
  "thresholds": {
    "excellent": 4.5,
    "good": 3.5,
    "needsImprovement": 0
  },
  "colors": {
    "excellent": "#4CAF50",
    "good": "#FFC107",
    "needsImprovement": "#F44336",
    "insufficientData": "#9E9E9E"
  },
  "labels": {
    "excellent": "Excellent",
    "good": "Good",
    "needsImprovement": "Needs Improvement",
    "insufficientData": "No Ratings"
  },
  "commentMaxLength": 1000,
  "features": {
    "allowComments": true,
    "requireCommentsBelowThreshold": 3.0,
    "enableAnonymousRatings": false
  }
}
```

**Backend Implementation:**
```python
from django.http import JsonResponse
from django.views.decorators.cache import cache_page
import json

@cache_page(60 * 15)  # Cache for 15 minutes
def get_rating_configuration(request):
    """
    Get rating system configuration.
    Cached for performance - invalidate cache when admin updates config.
    """
    try:
        # Option 1: Dedicated configuration table
        config_row = RatingConfiguration.objects.get(config_key='rating_system_config')
        config = json.loads(config_row.config_value_json)
        
        # Option 2: Global settings table
        # settings = GlobalSettings.objects.first()
        # config = json.loads(settings.rating_config_json)
        
        return JsonResponse(config, safe=False)
        
    except RatingConfiguration.DoesNotExist:
        # Return default configuration if not found
        return JsonResponse({
            'ratingScale': {'min': 1, 'max': 5, 'step': 1, 'displayType': 'stars'},
            'thresholds': {'excellent': 4.5, 'good': 3.5, 'needsImprovement': 0},
            'colors': {
                'excellent': '#4CAF50',
                'good': '#FFC107',
                'needsImprovement': '#F44336',
                'insufficientData': '#9E9E9E'
            },
            'commentMaxLength': 1000,
            'features': {'allowComments': True}
        })
```

**Flutter Integration Pattern:**
```dart
// Load on app startup (in main.dart)
class RatingConfig {
  final int minRating;
  final int maxRating;
  final double excellentThreshold;
  final double goodThreshold;
  final Map<String, Color> colors;
  final int commentMaxLength;
  
  static Future<RatingConfig> loadFromBackend() async {
    final response = await http.get('/api/settings/rating-config/');
    return RatingConfig.fromJson(jsonDecode(response.body));
  }
  
  String getColorCode(double score) {
    if (score >= excellentThreshold) return 'excellent';
    if (score >= goodThreshold) return 'good';
    return 'needsImprovement';
  }
  
  Color getColor(double score) {
    return colors[getColorCode(score)]!;
  }
}
```

**Caching Strategy:**
- Cache response for 15 minutes
- Invalidate cache when admin updates configuration
- Flutter app refreshes config daily or on app restart

---

## 1. Check Pending Ratings

**Endpoint:** `GET /api/trips/pending-ratings/`

**Description:** Get list of trips that current user has completed but not yet rated.

**Authentication:** Required (JWT token)

**Permissions:** Any authenticated user

**Query Parameters:** None

**Request Example:**
```http
GET /api/trips/pending-ratings/
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "pendingRatings": [
    {
      "tripId": 123,
      "tripName": "Al Maha Desert Adventure",
      "tripDate": "2025-11-15",
      "leaderId": 45,
      "leaderName": "John Doe",
      "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
      "completedAt": "2025-11-15T18:00:00Z"
    },
    {
      "tripId": 124,
      "tripName": "Wadi Shees Exploration",
      "tripDate": "2025-11-08",
      "leaderId": 46,
      "leaderName": "Sarah Smith",
      "leaderAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "completedAt": "2025-11-08T17:30:00Z"
    }
  ]
}
```

**Backend Logic:**
```sql
SELECT DISTINCT
    t.id as trip_id,
    t.name as trip_name,
    t.start_date as trip_date,
    t.owner_id as leader_id,
    u.first_name || ' ' || u.last_name as leader_name,
    u.avatar_url as leader_avatar,
    tr.updated_at as completed_at
FROM trips t
JOIN trip_registrations tr ON tr.trip_id = t.id
JOIN users u ON u.id = t.owner_id
LEFT JOIN trip_ratings rat ON rat.trip_id = t.id AND rat.user_id = :current_user_id
WHERE tr.user_id = :current_user_id
  AND tr.status = 'completed'
  AND t.end_date < NOW()
  AND t.is_event = FALSE
  AND t.owner_id != :current_user_id
  AND rat.id IS NULL
ORDER BY t.end_date ASC;
```

**Error Responses:**
```json
// 401 Unauthorized
{
  "error": "Authentication required"
}
```

---

## 2. Submit Trip Rating

**Endpoint:** `POST /api/trip-ratings/`

**Description:** Submit a rating for a completed trip.

**Authentication:** Required (JWT token)

**Permissions:** Any authenticated user (with validation)

**Request Body:**
```json
{
  "tripId": 123,
  "tripRating": 5,
  "leaderRating": 4,
  "comment": "Amazing experience! Great navigation skills. The leader was knowledgeable and ensured everyone's safety throughout the trip. Highly recommend!"
}
```

**Field Validation:**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| tripId | Integer | Yes | Must be valid trip ID |
| tripRating | Integer | Yes | Must be 1-5 |
| leaderRating | Integer | Yes | Must be 1-5 |
| comment | String | No | Max 1000 characters |

**Response (201 Created):**
```json
{
  "id": 456,
  "tripId": 123,
  "userId": 789,
  "userName": "Emily Brown",
  "userAvatar": "https://example.com/avatars/emilybrown.jpg",
  "tripRating": 5,
  "leaderRating": 4,
  "comment": "Amazing experience! Great navigation skills...",
  "averageRating": 4.5,
  "createdAt": "2025-11-16T10:30:00Z",
  "updatedAt": null
}
```

**Backend Validation Logic:**
```python
def validate_rating_submission(user_id, trip_id):
    """
    Validation steps:
    1. Check if trip exists
    2. Check if user attended trip (status = 'completed')
    3. Check if trip end date has passed
    4. Check if trip is not an event
    5. Check if user is not the trip owner
    6. Check if user has not already rated this trip
    7. Validate rating values (1-5)
    8. Validate comment length
    """
    
    # Get trip and registration info
    trip = Trip.objects.get(id=trip_id)
    registration = TripRegistration.objects.get(
        trip_id=trip_id,
        user_id=user_id
    )
    
    # Validation checks
    if registration.status != 'completed':
        raise ValidationError("Can only rate completed trips")
    
    if trip.end_date >= timezone.now():
        raise ValidationError("Trip has not ended yet")
    
    if trip.is_event:
        raise ValidationError("Events cannot be rated")
    
    if trip.owner_id == user_id:
        raise ValidationError("Cannot rate your own trip")
    
    existing_rating = TripRating.objects.filter(
        trip_id=trip_id,
        user_id=user_id
    ).exists()
    
    if existing_rating:
        raise ValidationError("You have already rated this trip")
    
    return True
```

**Error Responses:**
```json
// 400 Bad Request - Validation error
{
  "error": "Validation failed",
  "details": {
    "tripRating": "Must be between 1 and 5",
    "comment": "Maximum 1000 characters"
  }
}

// 403 Forbidden - Business rule violation
{
  "error": "Cannot rate this trip",
  "reason": "You have already rated this trip"
}

// 403 Forbidden - Owner cannot rate own trip
{
  "error": "Cannot rate this trip",
  "reason": "Trip owners cannot rate their own trips"
}

// 404 Not Found - Trip doesn't exist
{
  "error": "Trip not found",
  "tripId": 123
}
```

**After Successful Rating:**
```python
# Automatically mark rating notification as read/completed
Notification.objects.filter(
    user_id=user_id,
    action_type='rate_trip',
    action_id=str(trip_id)
).update(is_read=True)
```

---

## 3. Get Trip Ratings Summary (Public)

**Endpoint:** `GET /api/trips/{tripId}/ratings-summary/`

**Description:** Get aggregated rating summary for a specific trip. **Public endpoint** - anyone can view.

**Authentication:** Optional (but recommended for analytics)

**Permissions:** Public (no restrictions)

**URL Parameters:**
- `tripId` (integer, required): Trip ID

**Request Example:**
```http
GET /api/trips/123/ratings-summary/
Authorization: Bearer <token>  // Optional
```

**Response (200 OK):**
```json
{
  "tripId": 123,
  "tripName": "Al Maha Desert Adventure",
  "tripDate": "2025-11-15",
  "tripLevel": "Intermediate",
  "leaderId": 45,
  "leaderName": "John Doe",
  "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
  "totalReviews": 12,
  "averageTripRating": 4.6,
  "averageLeaderRating": 4.8,
  "overallScore": 4.7,
  "reviews": [
    {
      "id": 456,
      "userId": 789,
      "userName": "Sarah Smith",
      "userAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "tripRating": 5,
      "leaderRating": 4,
      "comment": "Amazing experience! Great navigation skills...",
      "averageRating": 4.5,
      "createdAt": "2025-11-16T10:30:00Z"
    },
    {
      "id": 457,
      "userId": 790,
      "userName": "Mike Johnson",
      "userAvatar": "https://example.com/avatars/mikejohnson.jpg",
      "tripRating": 4,
      "leaderRating": 5,
      "comment": "Perfect trip, excellent leader. Learned a lot!",
      "averageRating": 4.5,
      "createdAt": "2025-11-16T09:15:00Z"
    }
  ]
}
```

**Backend Calculation Logic:**
```sql
SELECT
    t.id as trip_id,
    t.name as trip_name,
    t.start_date as trip_date,
    l.name as trip_level,
    u.id as leader_id,
    u.first_name || ' ' || u.last_name as leader_name,
    u.avatar_url as leader_avatar,
    COUNT(r.id) as total_reviews,
    COALESCE(AVG(r.trip_rating), 0) as average_trip_rating,
    COALESCE(AVG(r.leader_rating), 0) as average_leader_rating,
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as overall_score
FROM trips t
LEFT JOIN trip_ratings r ON r.trip_id = t.id
JOIN users u ON u.id = t.owner_id
JOIN levels l ON l.id = t.level_id
WHERE t.id = :trip_id
GROUP BY t.id, t.name, t.start_date, l.name, u.id, u.first_name, u.last_name, u.avatar_url;
```

**Historic Data Handling:**
```python
# If no ratings exist for trip, return zeros (not errors)
if total_reviews == 0:
    return {
        "totalReviews": 0,
        "averageTripRating": 0.0,
        "averageLeaderRating": 0.0,
        "overallScore": 0.0,
        "reviews": []
    }
```

**Error Responses:**
```json
// 404 Not Found
{
  "error": "Trip not found",
  "tripId": 123
}
```

---

## 4. Admin: List All Trip Ratings

**Endpoint:** `GET /api/admin/trip-ratings/`

**Description:** Get paginated list of all trips with rating summaries. Admin only.

**Authentication:** Required (JWT token)

**Permissions:** `VIEW_TRIP_FEEDBACK`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | Integer | No | 1 | Page number |
| pageSize | Integer | No | 20 | Items per page |
| dateFrom | Date (YYYY-MM-DD) | No | null | Filter trips from this date |
| dateTo | Date (YYYY-MM-DD) | No | null | Filter trips until this date |
| levelId | Integer | No | null | Filter by trip level |
| leaderId | Integer | No | null | Filter by trip leader |
| scoreMin | Float | No | null | Minimum overall score (0-5) |
| scoreMax | Float | No | null | Maximum overall score (0-5) |
| sortBy | String | No | date | Sort field: date, score, reviews, name |
| sortOrder | String | No | desc | Sort direction: asc, desc |

**Request Example:**
```http
GET /api/admin/trip-ratings/?page=1&pageSize=20&dateFrom=2025-01-01&sortBy=score&sortOrder=desc
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "count": 45,
  "next": "https://api.example.com/api/admin/trip-ratings/?page=2",
  "previous": null,
  "results": [
    {
      "tripId": 123,
      "tripName": "Al Maha Desert Adventure",
      "tripDate": "2025-11-15",
      "tripLevel": "Intermediate",
      "leaderId": 45,
      "leaderName": "John Doe",
      "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
      "totalReviews": 12,
      "averageTripRating": 4.6,
      "averageLeaderRating": 4.8,
      "overallScore": 4.7
    },
    {
      "tripId": 124,
      "tripName": "Wadi Shees Exploration",
      "tripDate": "2025-11-08",
      "tripLevel": "Advanced",
      "leaderId": 46,
      "leaderName": "Sarah Smith",
      "leaderAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "totalReviews": 8,
      "averageTripRating": 4.4,
      "averageLeaderRating": 4.6,
      "overallScore": 4.5
    }
  ]
}
```

**Backend SQL Query:**
```sql
SELECT
    t.id as trip_id,
    t.name as trip_name,
    t.start_date as trip_date,
    l.name as trip_level,
    u.id as leader_id,
    u.first_name || ' ' || u.last_name as leader_name,
    u.avatar_url as leader_avatar,
    COUNT(r.id) as total_reviews,
    COALESCE(AVG(r.trip_rating), 0) as average_trip_rating,
    COALESCE(AVG(r.leader_rating), 0) as average_leader_rating,
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as overall_score
FROM trips t
LEFT JOIN trip_ratings r ON r.trip_id = t.id
JOIN users u ON u.id = t.owner_id
JOIN levels l ON l.id = t.level_id
WHERE 
    t.is_event = FALSE
    AND (:date_from IS NULL OR t.start_date >= :date_from)
    AND (:date_to IS NULL OR t.start_date <= :date_to)
    AND (:level_id IS NULL OR t.level_id = :level_id)
    AND (:leader_id IS NULL OR t.owner_id = :leader_id)
GROUP BY t.id, t.name, t.start_date, l.name, u.id, u.first_name, u.last_name, u.avatar_url
HAVING
    (:score_min IS NULL OR overall_score >= :score_min)
    AND (:score_max IS NULL OR overall_score <= :score_max)
ORDER BY
    CASE WHEN :sort_by = 'date' THEN t.start_date END DESC,
    CASE WHEN :sort_by = 'score' THEN overall_score END DESC,
    CASE WHEN :sort_by = 'reviews' THEN total_reviews END DESC,
    CASE WHEN :sort_by = 'name' THEN t.name END ASC
LIMIT :page_size OFFSET :offset;
```

**Error Responses:**
```json
// 403 Forbidden - No permission
{
  "error": "Permission denied",
  "required": "VIEW_TRIP_FEEDBACK"
}
```

---

## 5. Admin: Get Trip Rating Details

**Endpoint:** `GET /api/admin/trip-ratings/{tripId}/`

**Description:** Get detailed rating information for a specific trip, including all individual reviews.

**Authentication:** Required (JWT token)

**Permissions:** `VIEW_TRIP_FEEDBACK_DETAILS`

**URL Parameters:**
- `tripId` (integer, required): Trip ID

**Request Example:**
```http
GET /api/admin/trip-ratings/123/
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "tripId": 123,
  "tripName": "Al Maha Desert Adventure",
  "tripDate": "2025-11-15",
  "tripLevel": "Intermediate",
  "leaderId": 45,
  "leaderName": "John Doe",
  "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
  "totalReviews": 12,
  "averageTripRating": 4.6,
  "averageLeaderRating": 4.8,
  "overallScore": 4.7,
  "participantCount": 15,
  "completedCount": 13,
  "ratedCount": 12,
  "responseRate": 0.92,
  "reviews": [
    {
      "id": 456,
      "userId": 789,
      "userName": "Sarah Smith",
      "userAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "tripRating": 5,
      "leaderRating": 4,
      "comment": "Amazing experience! Great navigation skills. Would join again.",
      "averageRating": 4.5,
      "createdAt": "2025-11-16T10:30:00Z"
    },
    {
      "id": 457,
      "userId": 790,
      "userName": "Mike Johnson",
      "userAvatar": "https://example.com/avatars/mikejohnson.jpg",
      "tripRating": 4,
      "leaderRating": 5,
      "comment": "Perfect trip, excellent leader. Learned a lot about desert navigation.",
      "averageRating": 4.5,
      "createdAt": "2025-11-16T09:15:00Z"
    }
  ]
}
```

**Additional Fields for Admin View:**
- `participantCount`: Total registered participants
- `completedCount`: Participants who completed the trip
- `ratedCount`: Participants who submitted ratings
- `responseRate`: ratedCount / completedCount (percentage as decimal 0-1)

**Backend Calculation:**
```python
# Calculate participation statistics
participant_count = TripRegistration.objects.filter(
    trip_id=trip_id
).count()

completed_count = TripRegistration.objects.filter(
    trip_id=trip_id,
    status='completed'
).count()

rated_count = TripRating.objects.filter(
    trip_id=trip_id
).count()

response_rate = rated_count / completed_count if completed_count > 0 else 0
```

**Error Responses:**
```json
// 403 Forbidden
{
  "error": "Permission denied",
  "required": "VIEW_TRIP_FEEDBACK_DETAILS"
}

// 404 Not Found
{
  "error": "Trip not found",
  "tripId": 123
}
```

---

## 6. Admin: List Leader Performance

**Endpoint:** `GET /api/admin/leader-performance/`

**Description:** Get paginated list of trip leaders with performance metrics.

**Authentication:** Required (JWT token)

**Permissions:** `VIEW_LEADER_PERFORMANCE`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | Integer | No | 1 | Page number |
| pageSize | Integer | No | 20 | Items per page |
| period | String | No | ytd | Filter period: all, ytd, last6months, custom |
| dateFrom | Date (YYYY-MM-DD) | No | null | Start date (if period=custom) |
| dateTo | Date (YYYY-MM-DD) | No | null | End date (if period=custom) |
| minTrips | Integer | No | null | Filter leaders with minimum trips led |
| sortBy | String | No | score | Sort field: score, trips, name |
| sortOrder | String | No | desc | Sort direction: asc, desc |

**Period Calculation:**
- `ytd`: Year-to-date (January 1 of current year to today)
- `last6months`: Last 6 months from today
- `custom`: Use dateFrom and dateTo parameters
- `all`: All time (no date filter)

**Request Example:**
```http
GET /api/admin/leader-performance/?period=ytd&sortBy=score&sortOrder=desc
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "count": 24,
  "next": "https://api.example.com/api/admin/leader-performance/?page=2",
  "previous": null,
  "results": [
    {
      "leaderId": 45,
      "leaderName": "John Doe",
      "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
      "totalTrips": 24,
      "totalReviews": 156,
      "overallScore": 4.8,
      "memberSince": "2023-01-15"
    },
    {
      "leaderId": 46,
      "leaderName": "Sarah Smith",
      "leaderAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "totalTrips": 18,
      "totalReviews": 102,
      "overallScore": 4.7,
      "memberSince": "2023-03-20"
    }
  ]
}
```

**Backend SQL Query:**
```sql
SELECT
    u.id as leader_id,
    u.first_name || ' ' || u.last_name as leader_name,
    u.avatar_url as leader_avatar,
    COUNT(DISTINCT t.id) as total_trips,
    COUNT(r.id) as total_reviews,
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as overall_score,
    u.created_at as member_since
FROM users u
JOIN trips t ON t.owner_id = u.id
LEFT JOIN trip_ratings r ON r.trip_id = t.id
WHERE 
    t.is_event = FALSE
    AND (:period = 'all' OR (
        CASE 
            WHEN :period = 'ytd' THEN t.start_date >= DATE_TRUNC('year', NOW())
            WHEN :period = 'last6months' THEN t.start_date >= NOW() - INTERVAL '6 months'
            WHEN :period = 'custom' THEN t.start_date BETWEEN :date_from AND :date_to
        END
    ))
GROUP BY u.id, u.first_name, u.last_name, u.avatar_url, u.created_at
HAVING 
    (:min_trips IS NULL OR COUNT(DISTINCT t.id) >= :min_trips)
ORDER BY
    CASE WHEN :sort_by = 'score' THEN overall_score END DESC,
    CASE WHEN :sort_by = 'trips' THEN COUNT(DISTINCT t.id) END DESC,
    CASE WHEN :sort_by = 'name' THEN u.first_name || ' ' || u.last_name END ASC
LIMIT :page_size OFFSET :offset;
```

**Error Responses:**
```json
// 403 Forbidden
{
  "error": "Permission denied",
  "required": "VIEW_LEADER_PERFORMANCE"
}
```

---

## 7. Admin: Get Leader Performance Details

**Endpoint:** `GET /api/admin/leader-performance/{leaderId}/`

**Description:** Get detailed performance metrics for a specific trip leader.

**Authentication:** Required (JWT token)

**Permissions:** `VIEW_LEADER_PERFORMANCE`

**URL Parameters:**
- `leaderId` (integer, required): User ID of the trip leader

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| period | String | No | ytd | Filter period: all, ytd, last6months, custom |
| dateFrom | Date (YYYY-MM-DD) | No | null | Start date (if period=custom) |
| dateTo | Date (YYYY-MM-DD) | No | null | End date (if period=custom) |

**Request Example:**
```http
GET /api/admin/leader-performance/45/?period=ytd
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "leaderId": 45,
  "leaderName": "John Doe",
  "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
  "totalTrips": 24,
  "totalReviews": 156,
  "overallScore": 4.8,
  "memberSince": "2023-01-15",
  "trips": [
    {
      "tripId": 123,
      "tripName": "Al Maha Desert Adventure",
      "tripDate": "2025-11-15",
      "tripLevel": "Intermediate",
      "totalReviews": 12,
      "averageTripRating": 4.6,
      "averageLeaderRating": 4.8,
      "overallScore": 4.7
    },
    {
      "tripId": 122,
      "tripName": "Jebel Hafeet Challenge",
      "tripDate": "2025-11-01",
      "tripLevel": "Advanced",
      "totalReviews": 10,
      "averageTripRating": 4.8,
      "averageLeaderRating": 4.9,
      "overallScore": 4.85
    }
  ],
  "trendData": [
    {"month": "2025-01", "averageScore": 4.6},
    {"month": "2025-02", "averageScore": 4.7},
    {"month": "2025-03", "averageScore": 4.8},
    {"month": "2025-04", "averageScore": 4.7},
    {"month": "2025-05", "averageScore": 4.8},
    {"month": "2025-06", "averageScore": 4.9}
  ]
}
```

**Trend Data Calculation:**
```sql
SELECT
    TO_CHAR(t.start_date, 'YYYY-MM') as month,
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as average_score
FROM trips t
LEFT JOIN trip_ratings r ON r.trip_id = t.id
WHERE 
    t.owner_id = :leader_id
    AND t.is_event = FALSE
    AND t.start_date BETWEEN :date_from AND :date_to
GROUP BY TO_CHAR(t.start_date, 'YYYY-MM')
ORDER BY month ASC;
```

**Error Responses:**
```json
// 403 Forbidden
{
  "error": "Permission denied",
  "required": "VIEW_LEADER_PERFORMANCE"
}

// 404 Not Found
{
  "error": "Leader not found",
  "leaderId": 45
}
```

---

## 8. Admin: Get MSI Dashboard Stats

**Endpoint:** `GET /api/admin/msi-dashboard-stats/`

**Description:** Get club-wide statistics for MSI dashboard widget.

**Authentication:** Required (JWT token)

**Permissions:** `VIEW_ADMIN_DASHBOARD`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| period | String | No | ytd | Period: ytd, last6months, custom |
| dateFrom | Date (YYYY-MM-DD) | No | null | Start date (if period=custom) |
| dateTo | Date (YYYY-MM-DD) | No | null | End date (if period=custom) |

**Request Example:**
```http
GET /api/admin/msi-dashboard-stats/?period=ytd
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "clubWideAverage": 4.6,
  "totalReviews": 342,
  "trendChange": 0.3,
  "topLeaders": [
    {
      "leaderId": 45,
      "leaderName": "John Doe",
      "leaderAvatar": "https://example.com/avatars/johndoe.jpg",
      "overallScore": 4.9,
      "totalTrips": 24
    },
    {
      "leaderId": 46,
      "leaderName": "Sarah Smith",
      "leaderAvatar": "https://example.com/avatars/sarahsmith.jpg",
      "overallScore": 4.8,
      "totalTrips": 18
    },
    {
      "leaderId": 47,
      "leaderName": "Mike Johnson",
      "leaderAvatar": "https://example.com/avatars/mikejohnson.jpg",
      "overallScore": 4.7,
      "totalTrips": 21
    }
  ],
  "topReviewers": [
    {
      "userId": 789,
      "userName": "Emily Brown",
      "userAvatar": "https://example.com/avatars/emilybrown.jpg",
      "totalReviews": 47
    },
    {
      "userId": 790,
      "userName": "David Lee",
      "userAvatar": "https://example.com/avatars/davidlee.jpg",
      "totalReviews": 39
    },
    {
      "userId": 791,
      "userName": "Lisa Chen",
      "userAvatar": "https://example.com/avatars/lisachen.jpg",
      "totalReviews": 34
    }
  ]
}
```

**Backend Calculation:**

```python
# Club-wide average for current period
current_average = calculate_club_average(date_from, date_to)

# Club-wide average for previous period (same duration)
period_duration = date_to - date_from
previous_date_from = date_from - period_duration
previous_date_to = date_from
previous_average = calculate_club_average(previous_date_from, previous_date_to)

# Trend change
trend_change = current_average - previous_average

# Top 3 leaders by score
top_leaders = get_top_leaders(date_from, date_to, limit=3)

# Top 3 reviewers by review count
top_reviewers = get_top_reviewers(date_from, date_to, limit=3)
```

**SQL Queries:**
```sql
-- Club-wide average
SELECT
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as club_average
FROM trip_ratings r
JOIN trips t ON t.id = r.trip_id
WHERE 
    t.is_event = FALSE
    AND t.start_date BETWEEN :date_from AND :date_to;

-- Top leaders
SELECT
    u.id as leader_id,
    u.first_name || ' ' || u.last_name as leader_name,
    u.avatar_url as leader_avatar,
    COUNT(DISTINCT t.id) as total_trips,
    COALESCE((AVG(r.trip_rating) + AVG(r.leader_rating)) / 2, 0) as overall_score
FROM users u
JOIN trips t ON t.owner_id = u.id
LEFT JOIN trip_ratings r ON r.trip_id = t.id
WHERE 
    t.is_event = FALSE
    AND t.start_date BETWEEN :date_from AND :date_to
GROUP BY u.id, u.first_name, u.last_name, u.avatar_url
ORDER BY overall_score DESC
LIMIT 3;

-- Top reviewers
SELECT
    u.id as user_id,
    u.first_name || ' ' || u.last_name as user_name,
    u.avatar_url as user_avatar,
    COUNT(r.id) as total_reviews
FROM users u
JOIN trip_ratings r ON r.user_id = u.id
JOIN trips t ON t.id = r.trip_id
WHERE t.start_date BETWEEN :date_from AND :date_to
GROUP BY u.id, u.first_name, u.last_name, u.avatar_url
ORDER BY total_reviews DESC
LIMIT 3;
```

**Error Responses:**
```json
// 403 Forbidden
{
  "error": "Permission denied",
  "required": "VIEW_ADMIN_DASHBOARD"
}
```

---

## 9. Automatic Notification Creation

**Description:** Backend automatically creates a notification when a trip is completed.

**Trigger:** When trip registration status changes to "completed" OR when trip end date passes.

**Background Job/Signal:**
```python
@receiver(post_save, sender=TripRegistration)
def create_rating_notification(sender, instance, created, **kwargs):
    """
    Create rating notification when:
    - Registration status changes to 'completed'
    - Trip end date has passed
    - Trip is not an event
    - User is not the trip owner
    - User has not already rated this trip
    """
    
    if instance.status != 'completed':
        return
    
    trip = instance.trip
    user = instance.user
    
    # Skip if trip is an event
    if trip.is_event:
        return
    
    # Skip if user is trip owner
    if trip.owner_id == user.id:
        return
    
    # Skip if trip hasn't ended yet
    if trip.end_date >= timezone.now():
        return
    
    # Skip if user already rated this trip
    if TripRating.objects.filter(trip_id=trip.id, user_id=user.id).exists():
        return
    
    # Skip if notification already exists
    if Notification.objects.filter(
        user_id=user.id,
        action_type='rate_trip',
        action_id=str(trip.id)
    ).exists():
        return
    
    # Create notification
    Notification.objects.create(
        user_id=user.id,
        type='trip',
        action_type='rate_trip',
        action_id=str(trip.id),
        title='Rate your recent trip',
        message=f'How was your experience on {trip.name}?',
        metadata={
            'tripName': trip.name,
            'tripDate': trip.start_date.isoformat(),
            'leaderId': trip.owner_id,
            'leaderName': f'{trip.owner.first_name} {trip.owner.last_name}',
            'leaderAvatar': trip.owner.avatar_url,
        }
    )
```

**Scheduled Job (Daily Cleanup):**
```python
@scheduled_task(cron='0 2 * * *')  # Run at 2 AM daily
def create_pending_rating_notifications():
    """
    Daily job to create notifications for completed trips
    that haven't been rated yet.
    """
    
    # Get all completed registrations for trips that ended
    completed_registrations = TripRegistration.objects.filter(
        status='completed',
        trip__end_date__lt=timezone.now(),
        trip__is_event=False
    ).exclude(
        trip__owner_id=F('user_id')
    )
    
    for registration in completed_registrations:
        # Check if already rated
        if TripRating.objects.filter(
            trip_id=registration.trip_id,
            user_id=registration.user_id
        ).exists():
            continue
        
        # Check if notification already exists
        if Notification.objects.filter(
            user_id=registration.user_id,
            action_type='rate_trip',
            action_id=str(registration.trip_id)
        ).exists():
            continue
        
        # Create notification (same logic as signal above)
        create_notification_for_registration(registration)
```

---

## 🔐 Permissions

### Required Permissions:

| Permission | Description | Typical Roles |
|------------|-------------|---------------|
| `VIEW_TRIP_FEEDBACK` | View MSI overview screen (trip ratings list) | Admin |
| `VIEW_TRIP_FEEDBACK_DETAILS` | View detailed trip ratings and individual reviews | Admin, Board Members |
| `VIEW_LEADER_PERFORMANCE` | View leader performance metrics | Admin, Board Members |
| `VIEW_ADMIN_DASHBOARD` | View MSI dashboard widget | Admin |

### Permission Check Example:
```python
from rest_framework.permissions import BasePermission

class CanViewTripFeedback(BasePermission):
    def has_permission(self, request, view):
        return request.user.has_permission('VIEW_TRIP_FEEDBACK')

class CanViewTripFeedbackDetails(BasePermission):
    def has_permission(self, request, view):
        return request.user.has_permission('VIEW_TRIP_FEEDBACK_DETAILS')

class CanViewLeaderPerformance(BasePermission):
    def has_permission(self, request, view):
        return request.user.has_permission('VIEW_LEADER_PERFORMANCE')
```

---

## 🚨 Error Handling

### Standard Error Response Format:
```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {
    "field": "Specific error details"
  }
}
```

### Common Error Codes:

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | VALIDATION_ERROR | Invalid request data |
| 401 | UNAUTHORIZED | Authentication required |
| 403 | PERMISSION_DENIED | User lacks required permission |
| 403 | ALREADY_RATED | User has already rated this trip |
| 403 | CANNOT_RATE_OWN_TRIP | Trip owners cannot rate their own trips |
| 403 | TRIP_NOT_COMPLETED | Can only rate completed trips |
| 404 | TRIP_NOT_FOUND | Trip does not exist |
| 404 | USER_NOT_FOUND | User does not exist |
| 500 | INTERNAL_ERROR | Server error |

### Historic Data Handling:

**CRITICAL:** When calculating averages and counts:
- Always use `COALESCE()` to return 0 instead of NULL
- Return empty arrays `[]` instead of failing
- Never throw errors for trips with zero ratings
- Display "No ratings" or "Insufficient data" in UI

```python
# Good - Handles zero ratings
average = avg_func() or 0.0

# Bad - Will error on NULL
average = avg_func()
```

---

## 📊 Performance Considerations

### Database Indexes:
```sql
-- Critical indexes for performance
CREATE INDEX idx_trip_ratings_trip_id ON trip_ratings(trip_id);
CREATE INDEX idx_trip_ratings_user_id ON trip_ratings(user_id);
CREATE INDEX idx_trip_ratings_created_at ON trip_ratings(created_at DESC);
CREATE INDEX idx_trips_owner_id ON trips(owner_id);
CREATE INDEX idx_trips_start_date ON trips(start_date DESC);
CREATE INDEX idx_trips_is_event ON trips(is_event);
```

### Query Optimization:
- Use aggregation queries instead of multiple queries
- Implement pagination (limit/offset)
- Cache club-wide statistics (update hourly)
- Use database views for complex calculations

### Caching Strategy:
```python
# Cache club-wide stats for 1 hour
@cache_result(timeout=3600)
def get_club_wide_average(period):
    # ... calculation
    pass

# Invalidate cache when new rating is submitted
@receiver(post_save, sender=TripRating)
def invalidate_stats_cache(sender, instance, **kwargs):
    cache.delete('club_wide_average_*')
```

---

## 🔧 Admin: Update Rating Configuration (NEW)

**Endpoint:** `PUT /api/admin/settings/rating-config/`

**Description:** Update rating system configuration. Requires admin permissions.

**Authentication:** Required (JWT token)

**Permissions:** `ADMIN_ACCESS` or `MANAGE_SYSTEM_SETTINGS`

**Request Body:**
```json
{
  "ratingScale": {
    "min": 1,
    "max": 10,
    "step": 0.5,
    "displayType": "stars"
  },
  "thresholds": {
    "excellent": 8.5,
    "good": 6.5,
    "needsImprovement": 0
  },
  "colors": {
    "excellent": "#00C853",
    "good": "#FFD600",
    "needsImprovement": "#D50000",
    "insufficientData": "#616161"
  },
  "commentMaxLength": 2000,
  "features": {
    "allowComments": true,
    "requireCommentsBelowThreshold": 5.0,
    "enableAnonymousRatings": false
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Rating configuration updated successfully",
  "config": {
    "ratingScale": {...},
    "thresholds": {...},
    "colors": {...},
    "commentMaxLength": 2000,
    "features": {...}
  },
  "updatedAt": "2025-01-17T10:30:00Z",
  "updatedBy": {
    "id": 1,
    "username": "admin_user"
  }
}
```

**Backend Implementation:**
```python
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.contrib.auth.decorators import login_required
from django.core.cache import cache
import json

@require_http_methods(["PUT"])
@login_required
def update_rating_configuration(request):
    """
    Update rating system configuration.
    Requires admin permissions.
    """
    # Check admin permission
    if not request.user.has_permission('MANAGE_SYSTEM_SETTINGS'):
        return JsonResponse({
            'success': False,
            'error': 'Permission denied',
            'required': 'MANAGE_SYSTEM_SETTINGS'
        }, status=403)
    
    try:
        new_config = json.loads(request.body)
        
        # Validate configuration structure
        validate_rating_config(new_config)
        
        # Update database
        config_row, created = RatingConfiguration.objects.update_or_create(
            config_key='rating_system_config',
            defaults={
                'config_value_json': json.dumps(new_config),
                'updated_by': request.user,
                'updated_at': timezone.now()
            }
        )
        
        # Invalidate cache to force reload
        cache.delete('rating_configuration')
        
        return JsonResponse({
            'success': True,
            'message': 'Rating configuration updated successfully',
            'config': new_config,
            'updatedAt': config_row.updated_at.isoformat(),
            'updatedBy': {
                'id': request.user.id,
                'username': request.user.username
            }
        })
        
    except json.JSONDecodeError:
        return JsonResponse({
            'success': False,
            'error': 'Invalid JSON in request body'
        }, status=400)
    except ValidationError as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=400)

def validate_rating_config(config):
    """Validate rating configuration structure"""
    required_keys = ['ratingScale', 'thresholds', 'colors', 'commentMaxLength']
    for key in required_keys:
        if key not in config:
            raise ValidationError(f"Missing required key: {key}")
    
    # Validate rating scale
    scale = config['ratingScale']
    if scale['min'] >= scale['max']:
        raise ValidationError("Rating min must be less than max")
    
    # Validate thresholds
    thresholds = config['thresholds']
    if thresholds['excellent'] <= thresholds['good']:
        raise ValidationError("Excellent threshold must be greater than good threshold")
    
    return True
```

**Admin UI Considerations:**
- Provide form in admin panel to update these settings
- Show preview of color coding changes
- Warn about impact on existing ratings display
- Include "Reset to Default" button

---

## 🧪 Testing Requirements

### Unit Tests:
- [ ] Rating validation logic with dynamic config
- [ ] Average calculation
- [ ] Color code determination using backend thresholds
- [ ] Permission checks
- [ ] Historic data handling (zero ratings)
- [ ] **NEW**: Configuration endpoint validation
- [ ] **NEW**: Config caching behavior

### Integration Tests:
- [ ] Submit rating flow
- [ ] Prevent duplicate ratings
- [ ] Prevent owner self-rating
- [ ] Notification creation
- [ ] Admin filtering and sorting

### Test Data:
```python
# Test cases to cover:
1. Trip with 0 ratings (historic data)
2. Trip with 1 rating
3. Trip with 10+ ratings
4. Leader with multiple trips
5. User attempts to rate own trip (should fail)
6. User attempts to rate twice (should fail)
7. User attempts to rate event (should fail)
8. User attempts to rate before trip ends (should fail)
```

---

## 📅 Implementation Timeline

### Phase 0: Configuration System (NEW - 2 hours)
- **CRITICAL**: Must be completed before Phase 1
- Create `rating_configuration` table (or extend `global_settings`)
- Implement `GET /api/settings/rating-config/` endpoint
- Implement `PUT /api/admin/settings/rating-config/` endpoint
- Add caching layer (15-minute cache)
- Insert default configuration values
- Test configuration loading and updates

### Phase 1: Database & Core API (Week 1)
- Day 1: Create `trip_ratings` table and indexes (remove hardcoded constraints)
- Day 2-3: Implement submit rating endpoint with dynamic validation
- Day 4: Implement pending ratings endpoint
- Day 5: Update validation logic to use configuration

### Phase 2: Public & Admin List APIs (Week 2)
- Day 1-2: Implement trip ratings summary endpoint (public)
- Day 3-4: Implement admin trip ratings list endpoint
- Day 5: Implement admin trip rating details endpoint

### Phase 3: Leader Performance (Week 3)
- Day 1-2: Implement leader performance list endpoint
- Day 3-4: Implement leader performance details endpoint
- Day 5: Implement MSI dashboard stats endpoint

### Phase 4: Notifications & Testing (Week 4)
- Day 1-2: Implement automatic notification creation
- Day 3-4: Unit and integration testing
- Day 5: Performance optimization and final review

**⚠️ IMPORTANT:** Configuration system (Phase 0) must be deployed before Flutter app can load rating UI correctly.

---

## 📋 Deployment Checklist

### Pre-Deployment:
- [ ] **Configuration table migration** created and tested (CRITICAL)
- [ ] **Default configuration** inserted into database
- [ ] **GET /api/settings/rating-config/** endpoint deployed and tested
- [ ] **PUT /api/admin/settings/rating-config/** endpoint deployed (admin only)
- [ ] Database migration for `trip_ratings` table created (without hardcoded constraints)
- [ ] All indexes created
- [ ] Permissions added (`MANAGE_SYSTEM_SETTINGS`)
- [ ] Validation logic updated to use dynamic config
- [ ] Error handling verified
- [ ] Historic data handling tested
- [ ] Configuration caching tested (15-minute cache)
- [ ] Performance benchmarks met

### Deployment:
- [ ] **STEP 1**: Deploy configuration endpoints FIRST
- [ ] **STEP 2**: Insert default configuration into production database
- [ ] **STEP 3**: Verify configuration endpoint returns valid JSON
- [ ] Run trip_ratings table migration
- [ ] Deploy all rating API endpoints
- [ ] Configure scheduled jobs
- [ ] Set up monitoring and alerts
- [ ] Verify permissions in admin panel

### Post-Deployment:
- [ ] **Verify configuration API works**: `curl https://ap.ad4x4.com/api/settings/rating-config/`
- [ ] Test admin configuration update endpoint
- [ ] Verify cache invalidation works when config updated
- [ ] Create initial test ratings
- [ ] Verify notification creation
- [ ] Test admin dashboards
- [ ] Monitor error rates
- [ ] Check query performance
- [ ] **Document configuration changes** in admin guide

---

## 🔗 Related Documentation

- Frontend Implementation Plan
- Permission System Documentation
- Notification System Documentation
- Database Schema Documentation

---

## 📞 Support & Questions

For questions or clarifications about this API specification, contact:
- Backend Team Lead
- Product Manager
- Frontend Team Lead

---

## 📝 Version History & Changes

### Version 2.0 (January 17, 2025) - **Flexible Configuration Update**

**Major Changes:**
- ✅ **NEW**: `rating_configuration` table for backend-controlled settings
- ✅ **NEW**: `GET /api/settings/rating-config/` endpoint (public)
- ✅ **NEW**: `PUT /api/admin/settings/rating-config/` endpoint (admin only)
- ✅ **REMOVED**: Hardcoded CHECK constraints from `trip_ratings` table
- ✅ **CHANGED**: Validation logic moved to application layer using dynamic config
- ✅ **CHANGED**: Color thresholds now configurable (was hardcoded 4.5, 3.5)
- ✅ **CHANGED**: Rating scale ranges now configurable (supports 1-5, 1-10, etc.)
- ✅ **CHANGED**: Comment length limits now configurable (was hardcoded 1000)

**Why These Changes?**
Following the design philosophy of the Vehicle Modifications System, all rating behavior is now controlled by the backend. Admins can adjust thresholds, colors, and validation rules without requiring app updates or code changes.

**Migration Impact:**
- **Database**: ALTER TABLE to remove CHECK constraints, add configuration table
- **Existing Data**: No changes to existing ratings - only validation rules change
- **Client Apps**: Must call configuration endpoint on startup to load settings
- **Backward Compatibility**: Default values match previous hardcoded values

---

**End of Backend API Documentation**

*This specification should be used as the authoritative reference for backend implementation. All endpoints must be implemented exactly as documented to ensure proper frontend integration.*

**🔴 CRITICAL FOR FLUTTER TEAM:** Configuration endpoint (`GET /api/settings/rating-config/`) must be called on app startup to load dynamic thresholds. Do not hardcode any rating values in Flutter code.
