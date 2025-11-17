# Trip Rating & MSI System - Frontend Implementation Plan

## 📋 Feature Overview

**Feature Name:** Trip Rating & Member Satisfaction Index (MSI) System

**Purpose:** Enable members to rate completed trips and provide admins with comprehensive analytics on member satisfaction and trip leader performance.

**Version:** 2.0

**Created:** November 16, 2025
**Updated:** January 17, 2025 - Added flexible backend-driven configuration

---

## 🎨 Design Philosophy

**Backend-Driven Configuration**: This feature follows the same flexible design philosophy as the Vehicle Modifications System:

- ✅ **All rating thresholds loaded from backend API** - no hardcoded values
- ✅ **Color coding determined dynamically** from backend configuration
- ✅ **Rating scale ranges backend-controlled** (supports 1-5, 1-10, etc.)
- ✅ **Comment length limits from backend** - validation uses API values
- ✅ **Future-ready for custom categories** and localization

**Key Principle:** App loads configuration on startup. Admins can change rating behavior without app updates.

**CRITICAL REQUIREMENT:** Must call `GET /api/settings/rating-config/` on app startup and store configuration globally.

---

## 🎯 Business Requirements Summary

### Member Experience:
- Members can rate trips they completed (both trip quality and leader performance)
- Rating popup appears after login if pending ratings exist
- Notifications remind users to rate trips
- Ratings are permanent (cannot be edited after submission)
- Members cannot rate their own trips (if they are the trip owner)

### Admin Experience:
- View all trip ratings in card grid format
- Analyze leader performance with scoring system
- Track club-wide satisfaction metrics
- Color-coded performance indicators
- Dashboard widgets with key metrics

### Rating System (Backend Configurable):
- **Trip Rating:** Configurable range (default: 1-5 stars)
- **Leader Rating:** Configurable range (default: 1-5 stars)
- **Comment:** Optional text feedback (max length from backend)
- **Overall Score:** Average of trip rating + leader rating (used for color coding)

### Color Coding System (Backend Configurable):
- 🟢 **Green (Excellent):** Default: 4.5-5.0 (threshold from backend)
- 🟡 **Yellow (Good):** Default: 3.5-4.4 (threshold from backend)
- 🔴 **Red (Needs Improvement):** Default: 0-3.4 (threshold from backend)
- ⚪ **Gray (Insufficient Data):** No ratings available

**⚠️ IMPORTANT:** All thresholds and colors must be loaded from backend API - never hardcode these values!

---

## 📁 Project Structure

All new files will be created under the Flutter app structure:

```
lib/
├── data/
│   └── models/
│       ├── rating_config_model.dart            # NEW - Backend configuration
│       ├── trip_rating_model.dart              # NEW
│       ├── trip_rating_summary_model.dart      # NEW
│       ├── leader_performance_model.dart       # NEW
│       ├── msi_dashboard_stats_model.dart      # NEW
│       └── top_reviewer_model.dart             # NEW
│
├── core/
│   ├── config/
│   │   └── rating_config_provider.dart         # NEW - Global config state
│   ├── network/
│   │   └── main_api_endpoints.dart             # MODIFY (add rating endpoints)
│   ├── utils/
│   │   └── rating_helper.dart                  # NEW (dynamic color coding)
│   └── router/
│       └── app_router.dart                     # MODIFY (add new routes)
│
├── features/
│   ├── trips/
│   │   ├── presentation/
│   │   │   ├── widgets/
│   │   │   │   ├── trip_rating_dialog.dart              # NEW
│   │   │   │   ├── trip_rating_card_widget.dart         # NEW
│   │   │   │   └── trip_rating_summary_section.dart     # NEW
│   │   │   └── screens/
│   │   │       └── trip_details_screen.dart             # MODIFY (add rating section)
│   │   └── data/
│   │       └── repositories/
│   │           └── trip_rating_repository.dart          # NEW
│   │
│   ├── admin/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── msi_overview_screen.dart             # NEW
│   │       │   ├── trip_rating_details_screen.dart      # NEW
│   │       │   ├── leader_performance_screen.dart       # NEW
│   │       │   ├── leader_performance_details_screen.dart  # NEW
│   │       │   └── admin_dashboard_screen.dart          # MODIFY (add MSI widget)
│   │       ├── widgets/
│   │       │   ├── msi_dashboard_widget.dart            # NEW
│   │       │   ├── trip_rating_card.dart                # NEW
│   │       │   ├── leader_performance_card.dart         # NEW
│   │       │   └── rating_color_indicator.dart          # NEW
│   │       └── providers/
│   │           ├── trip_rating_provider.dart            # NEW
│   │           └── leader_performance_provider.dart     # NEW
│   │
│   └── notifications/
│       └── presentation/
│           └── screens/
│               └── notifications_screen.dart            # MODIFY (handle rate_trip action)
│
└── main.dart                                             # MODIFY (check pending ratings on launch)
```

---

## 🗂️ Data Models

### 0. RatingConfigModel (`lib/data/models/rating_config_model.dart`) - **NEW & CRITICAL**

**Purpose:** Store rating system configuration loaded from backend. This model is loaded once on app startup and used throughout the app for validation and display.

```dart
import 'package:flutter/material.dart';

class RatingConfigModel {
  final RatingScale ratingScale;
  final RatingThresholds thresholds;
  final Map<String, Color> colors;
  final Map<String, String> labels;
  final int commentMaxLength;
  final RatingFeatures features;
  
  RatingConfigModel({
    required this.ratingScale,
    required this.thresholds,
    required this.colors,
    required this.labels,
    required this.commentMaxLength,
    required this.features,
  });
  
  /// Get color code for a given rating score
  String getColorCode(double score, {bool hasRatings = true}) {
    if (!hasRatings) return 'insufficientData';
    if (score >= thresholds.excellent) return 'excellent';
    if (score >= thresholds.good) return 'good';
    return 'needsImprovement';
  }
  
  /// Get color for a given rating score
  Color getColor(double score, {bool hasRatings = true}) {
    return colors[getColorCode(score, hasRatings: hasRatings)]!;
  }
  
  /// Get label for a given rating score
  String getLabel(double score, {bool hasRatings = true}) {
    return labels[getColorCode(score, hasRatings: hasRatings)]!;
  }
  
  /// Validate rating value against configured range
  bool isValidRating(int rating) {
    return rating >= ratingScale.min && rating <= ratingScale.max;
  }
  
  /// Validate comment length
  bool isValidComment(String? comment) {
    if (comment == null) return true;
    return comment.length <= commentMaxLength;
  }
  
  // JSON serialization
  factory RatingConfigModel.fromJson(Map<String, dynamic> json) {
    return RatingConfigModel(
      ratingScale: RatingScale.fromJson(json['ratingScale']),
      thresholds: RatingThresholds.fromJson(json['thresholds']),
      colors: (json['colors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, _parseColor(value as String)),
      ),
      labels: Map<String, String>.from(json['labels']),
      commentMaxLength: json['commentMaxLength'] as int,
      features: RatingFeatures.fromJson(json['features']),
    );
  }
  
  static Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ratingScale': ratingScale.toJson(),
      'thresholds': thresholds.toJson(),
      'colors': colors.map((key, value) => MapEntry(key, '#${value.value.toRadixString(16).substring(2)}')),
      'labels': labels,
      'commentMaxLength': commentMaxLength,
      'features': features.toJson(),
    };
  }
}

class RatingScale {
  final int min;
  final int max;
  final double step;
  final String displayType;
  
  RatingScale({
    required this.min,
    required this.max,
    required this.step,
    required this.displayType,
  });
  
  factory RatingScale.fromJson(Map<String, dynamic> json) {
    return RatingScale(
      min: json['min'] as int,
      max: json['max'] as int,
      step: (json['step'] as num).toDouble(),
      displayType: json['displayType'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'step': step,
      'displayType': displayType,
    };
  }
}

class RatingThresholds {
  final double excellent;
  final double good;
  final double needsImprovement;
  
  RatingThresholds({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
  });
  
  factory RatingThresholds.fromJson(Map<String, dynamic> json) {
    return RatingThresholds(
      excellent: (json['excellent'] as num).toDouble(),
      good: (json['good'] as num).toDouble(),
      needsImprovement: (json['needsImprovement'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'excellent': excellent,
      'good': good,
      'needsImprovement': needsImprovement,
    };
  }
}

class RatingFeatures {
  final bool allowComments;
  final double? requireCommentsBelowThreshold;
  final bool enableAnonymousRatings;
  
  RatingFeatures({
    required this.allowComments,
    this.requireCommentsBelowThreshold,
    required this.enableAnonymousRatings,
  });
  
  factory RatingFeatures.fromJson(Map<String, dynamic> json) {
    return RatingFeatures(
      allowComments: json['allowComments'] as bool,
      requireCommentsBelowThreshold: json['requireCommentsBelowThreshold'] != null
          ? (json['requireCommentsBelowThreshold'] as num).toDouble()
          : null,
      enableAnonymousRatings: json['enableAnonymousRatings'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'allowComments': allowComments,
      'requireCommentsBelowThreshold': requireCommentsBelowThreshold,
      'enableAnonymousRatings': enableAnonymousRatings,
    };
  }
}
```

---

### 1. TripRatingModel (`lib/data/models/trip_rating_model.dart`)

**Purpose:** Represents a single trip rating submitted by a member.

```dart
class TripRatingModel {
  final int id;
  final int tripId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int tripRating;        // 1-5 stars
  final int leaderRating;      // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  TripRatingModel({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.tripRating,
    required this.leaderRating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });
  
  // Calculated fields
  double get averageRating => (tripRating + leaderRating) / 2.0;
  
  String get colorCode {
    if (averageRating >= 4.5) return 'green';
    if (averageRating >= 3.5) return 'yellow';
    return 'red';
  }
  
  Color get color => RatingHelper.getColorFromCode(colorCode);
  
  // JSON serialization
  factory TripRatingModel.fromJson(Map<String, dynamic> json) {
    return TripRatingModel(
      id: json['id'] as int,
      tripId: json['tripId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      tripRating: json['tripRating'] as int,
      leaderRating: json['leaderRating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'tripRating': tripRating,
      'leaderRating': leaderRating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
```

---

### 2. TripRatingSummaryModel (`lib/data/models/trip_rating_summary_model.dart`)

**Purpose:** Aggregated rating data for a specific trip.

```dart
class TripRatingSummaryModel {
  final int tripId;
  final String tripName;
  final DateTime tripDate;
  final String tripLevel;
  final int leaderId;
  final String leaderName;
  final String? leaderAvatar;
  final int totalReviews;
  final double averageTripRating;
  final double averageLeaderRating;
  final double overallScore;
  final List<TripRatingModel> reviews;
  final int? participantCount;      // For admin details view
  final int? completedCount;        // For admin details view
  final int? ratedCount;            // For admin details view
  final double? responseRate;       // For admin details view
  
  TripRatingSummaryModel({
    required this.tripId,
    required this.tripName,
    required this.tripDate,
    required this.tripLevel,
    required this.leaderId,
    required this.leaderName,
    this.leaderAvatar,
    required this.totalReviews,
    required this.averageTripRating,
    required this.averageLeaderRating,
    required this.overallScore,
    required this.reviews,
    this.participantCount,
    this.completedCount,
    this.ratedCount,
    this.responseRate,
  });
  
  // Calculated fields
  String get colorCode {
    if (totalReviews == 0) return 'gray';  // No ratings yet
    if (overallScore >= 4.5) return 'green';
    if (overallScore >= 3.5) return 'yellow';
    return 'red';
  }
  
  Color get color => RatingHelper.getColorFromCode(colorCode);
  
  String get scoreLabel {
    if (totalReviews == 0) return 'No ratings';
    return '${overallScore.toStringAsFixed(1)}/5';
  }
  
  // JSON serialization
  factory TripRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return TripRatingSummaryModel(
      tripId: json['tripId'] as int,
      tripName: json['tripName'] as String,
      tripDate: DateTime.parse(json['tripDate'] as String),
      tripLevel: json['tripLevel'] as String,
      leaderId: json['leaderId'] as int,
      leaderName: json['leaderName'] as String,
      leaderAvatar: json['leaderAvatar'] as String?,
      totalReviews: json['totalReviews'] as int,
      averageTripRating: (json['averageTripRating'] as num).toDouble(),
      averageLeaderRating: (json['averageLeaderRating'] as num).toDouble(),
      overallScore: (json['overallScore'] as num).toDouble(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((r) => TripRatingModel.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      participantCount: json['participantCount'] as int?,
      completedCount: json['completedCount'] as int?,
      ratedCount: json['ratedCount'] as int?,
      responseRate: (json['responseRate'] as num?)?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'tripDate': tripDate.toIso8601String(),
      'tripLevel': tripLevel,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'leaderAvatar': leaderAvatar,
      'totalReviews': totalReviews,
      'averageTripRating': averageTripRating,
      'averageLeaderRating': averageLeaderRating,
      'overallScore': overallScore,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'participantCount': participantCount,
      'completedCount': completedCount,
      'ratedCount': ratedCount,
      'responseRate': responseRate,
    };
  }
}
```

---

### 3. LeaderPerformanceModel (`lib/data/models/leader_performance_model.dart`)

**Purpose:** Performance metrics for a trip leader.

```dart
class LeaderPerformanceModel {
  final int leaderId;
  final String leaderName;
  final String? leaderAvatar;
  final int totalTrips;
  final int totalReviews;
  final double overallScore;
  final DateTime? memberSince;
  final List<TripRatingSummaryModel>? recentTrips;  // For detail view
  final List<TrendDataPoint>? trendData;            // For detail view
  
  LeaderPerformanceModel({
    required this.leaderId,
    required this.leaderName,
    this.leaderAvatar,
    required this.totalTrips,
    required this.totalReviews,
    required this.overallScore,
    this.memberSince,
    this.recentTrips,
    this.trendData,
  });
  
  // Calculated fields
  String get colorCode {
    if (totalReviews == 0) return 'gray';
    if (overallScore >= 4.5) return 'green';
    if (overallScore >= 3.5) return 'yellow';
    return 'red';
  }
  
  Color get color => RatingHelper.getColorFromCode(colorCode);
  
  String get scoreLabel {
    if (totalReviews == 0) return 'No ratings';
    return '${overallScore.toStringAsFixed(1)}/5';
  }
  
  // JSON serialization
  factory LeaderPerformanceModel.fromJson(Map<String, dynamic> json) {
    return LeaderPerformanceModel(
      leaderId: json['leaderId'] as int,
      leaderName: json['leaderName'] as String,
      leaderAvatar: json['leaderAvatar'] as String?,
      totalTrips: json['totalTrips'] as int,
      totalReviews: json['totalReviews'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
      memberSince: json['memberSince'] != null 
          ? DateTime.parse(json['memberSince'] as String) 
          : null,
      recentTrips: (json['trips'] as List<dynamic>?)
          ?.map((t) => TripRatingSummaryModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      trendData: (json['trendData'] as List<dynamic>?)
          ?.map((t) => TrendDataPoint.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrendDataPoint {
  final String month;
  final double averageScore;
  
  TrendDataPoint({
    required this.month,
    required this.averageScore,
  });
  
  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      month: json['month'] as String,
      averageScore: (json['averageScore'] as num).toDouble(),
    );
  }
}
```

---

### 4. MSIDashboardStatsModel (`lib/data/models/msi_dashboard_stats_model.dart`)

**Purpose:** Club-wide statistics for admin dashboard widget.

```dart
class MSIDashboardStatsModel {
  final double clubWideAverage;
  final int totalReviews;
  final double trendChange;
  final List<LeaderPerformanceModel> topLeaders;
  final List<TopReviewerModel> topReviewers;
  
  MSIDashboardStatsModel({
    required this.clubWideAverage,
    required this.totalReviews,
    required this.trendChange,
    required this.topLeaders,
    required this.topReviewers,
  });
  
  String get clubWideScoreLabel => '${clubWideAverage.toStringAsFixed(1)}/5';
  
  String get trendLabel {
    if (trendChange > 0) return '+${trendChange.toStringAsFixed(1)}';
    return trendChange.toStringAsFixed(1);
  }
  
  Color get clubWideColor => RatingHelper.getColorFromScore(clubWideAverage);
  
  factory MSIDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return MSIDashboardStatsModel(
      clubWideAverage: (json['clubWideAverage'] as num).toDouble(),
      totalReviews: json['totalReviews'] as int,
      trendChange: (json['trendChange'] as num).toDouble(),
      topLeaders: (json['topLeaders'] as List<dynamic>)
          .map((l) => LeaderPerformanceModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      topReviewers: (json['topReviewers'] as List<dynamic>)
          .map((r) => TopReviewerModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

---

### 5. TopReviewerModel (`lib/data/models/top_reviewer_model.dart`)

**Purpose:** Top contributing reviewers for dashboard.

```dart
class TopReviewerModel {
  final int userId;
  final String userName;
  final String? userAvatar;
  final int totalReviews;
  
  TopReviewerModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalReviews,
  });
  
  factory TopReviewerModel.fromJson(Map<String, dynamic> json) {
    return TopReviewerModel(
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      totalReviews: json['totalReviews'] as int,
    );
  }
}
```

---

### 6. PendingTripRatingModel (`lib/data/models/pending_trip_rating_model.dart`)

**Purpose:** Represents a trip that needs to be rated.

```dart
class PendingTripRatingModel {
  final int tripId;
  final String tripName;
  final DateTime tripDate;
  final int leaderId;
  final String leaderName;
  final String? leaderAvatar;
  final DateTime completedAt;
  
  PendingTripRatingModel({
    required this.tripId,
    required this.tripName,
    required this.tripDate,
    required this.leaderId,
    required this.leaderName,
    this.leaderAvatar,
    required this.completedAt,
  });
  
  factory PendingTripRatingModel.fromJson(Map<String, dynamic> json) {
    return PendingTripRatingModel(
      tripId: json['tripId'] as int,
      tripName: json['tripName'] as String,
      tripDate: DateTime.parse(json['tripDate'] as String),
      leaderId: json['leaderId'] as int,
      leaderName: json['leaderName'] as String,
      leaderAvatar: json['leaderAvatar'] as String?,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
```

---

## 🔌 API Endpoints Integration

### Update: `lib/core/network/main_api_endpoints.dart`

Add these endpoint definitions:

```dart
class MainApiEndpoints {
  // ... existing endpoints ...
  
  // ============================================================================
  // TRIP RATINGS
  // ============================================================================
  
  /// Check for pending trip ratings
  static const String pendingRatings = '/api/trips/pending-ratings/';
  
  /// Submit a trip rating
  static const String submitRating = '/api/trip-ratings/';
  
  /// Get trip ratings summary (public)
  static String tripRatingsSummary(int tripId) => '/api/trips/$tripId/ratings-summary/';
  
  // ============================================================================
  // ADMIN: TRIP RATINGS
  // ============================================================================
  
  /// List all trip ratings (admin)
  static const String adminTripRatings = '/api/admin/trip-ratings/';
  
  /// Get detailed trip ratings (admin)
  static String adminTripRatingDetails(int tripId) => '/api/admin/trip-ratings/$tripId/';
  
  // ============================================================================
  // ADMIN: LEADER PERFORMANCE
  // ============================================================================
  
  /// List leader performance (admin)
  static const String adminLeaderPerformance = '/api/admin/leader-performance/';
  
  /// Get leader performance details (admin)
  static String adminLeaderPerformanceDetails(int leaderId) => 
      '/api/admin/leader-performance/$leaderId/';
  
  // ============================================================================
  // ADMIN: MSI DASHBOARD
  // ============================================================================
  
  /// Get MSI dashboard statistics (admin)
  static const String adminMSIDashboardStats = '/api/admin/msi-dashboard-stats/';
}
```

---

## 🛠️ Core Utilities

### Create: `lib/core/utils/rating_helper.dart`

**Purpose:** Centralized rating color coding and formatting logic.

```dart
import 'package:flutter/material.dart';

class RatingHelper {
  RatingHelper._();
  
  /// Get color from color code string
  static Color getColorFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'green':
        return const Color(0xFF4CAF50);  // Green
      case 'yellow':
        return const Color(0xFFFBC02D);  // Amber
      case 'red':
        return const Color(0xFFE53935);  // Red
      case 'gray':
      default:
        return const Color(0xFFBDBDBD);  // Gray
    }
  }
  
  /// Get color from score value
  static Color getColorFromScore(double score) {
    if (score == 0) return const Color(0xFFBDBDBD);  // Gray
    if (score >= 4.5) return const Color(0xFF4CAF50);  // Green
    if (score >= 3.5) return const Color(0xFFFBC02D);  // Yellow
    return const Color(0xFFE53935);  // Red
  }
  
  /// Get background color (lighter version)
  static Color getBackgroundColor(String code) {
    switch (code.toLowerCase()) {
      case 'green':
        return const Color(0xFFE8F5E9);  // Light green
      case 'yellow':
        return const Color(0xFFFFF9C4);  // Light yellow
      case 'red':
        return const Color(0xFFFFEBEE);  // Light red
      case 'gray':
      default:
        return const Color(0xFFFAFAFA);  // Light gray
    }
  }
  
  /// Get background color from score
  static Color getBackgroundFromScore(double score) {
    if (score == 0) return const Color(0xFFFAFAFA);
    if (score >= 4.5) return const Color(0xFFE8F5E9);
    if (score >= 3.5) return const Color(0xFFFFF9C4);
    return const Color(0xFFFFEBEE);
  }
  
  /// Format score as string
  static String formatScore(double score) {
    return score.toStringAsFixed(1);
  }
  
  /// Get performance label
  static String getPerformanceLabel(double score) {
    if (score == 0) return 'No ratings';
    if (score >= 4.5) return 'Excellent';
    if (score >= 3.5) return 'Good';
    return 'Needs Improvement';
  }
  
  /// Get icon for rating
  static IconData getRatingIcon(double score) {
    if (score >= 4.5) return Icons.sentiment_very_satisfied;
    if (score >= 3.5) return Icons.sentiment_satisfied;
    if (score > 0) return Icons.sentiment_dissatisfied;
    return Icons.help_outline;
  }
  
  /// Validate rating value (1-5)
  static bool isValidRating(int rating) {
    return rating >= 1 && rating <= 5;
  }
  
  /// Calculate average of two ratings
  static double calculateAverage(int rating1, int rating2) {
    return (rating1 + rating2) / 2.0;
  }
}
```

---

## 📦 Repository Layer

### Create: `lib/features/trips/data/repositories/trip_rating_repository.dart`

**Purpose:** API calls for trip rating functionality.

```dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/main_api_endpoints.dart';
import '../../../../data/models/pending_trip_rating_model.dart';
import '../../../../data/models/trip_rating_model.dart';
import '../../../../data/models/trip_rating_summary_model.dart';
import '../../../../data/models/leader_performance_model.dart';
import '../../../../data/models/msi_dashboard_stats_model.dart';

class TripRatingRepository {
  final ApiClient _apiClient = ApiClient();
  
  // ============================================================================
  // MEMBER ENDPOINTS
  // ============================================================================
  
  /// Get pending trip ratings for current user
  Future<List<PendingTripRatingModel>> getPendingRatings() async {
    final response = await _apiClient.get(MainApiEndpoints.pendingRatings);
    
    final pendingList = response.data['pendingRatings'] as List<dynamic>;
    return pendingList
        .map((json) => PendingTripRatingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Submit a trip rating
  Future<TripRatingModel> submitRating({
    required int tripId,
    required int tripRating,
    required int leaderRating,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      MainApiEndpoints.submitRating,
      data: {
        'tripId': tripId,
        'tripRating': tripRating,
        'leaderRating': leaderRating,
        'comment': comment,
      },
    );
    
    return TripRatingModel.fromJson(response.data);
  }
  
  /// Get trip ratings summary (public)
  Future<TripRatingSummaryModel> getTripRatingsSummary(int tripId) async {
    final response = await _apiClient.get(
      MainApiEndpoints.tripRatingsSummary(tripId),
    );
    
    return TripRatingSummaryModel.fromJson(response.data);
  }
  
  // ============================================================================
  // ADMIN ENDPOINTS
  // ============================================================================
  
  /// List all trip ratings (admin)
  Future<Map<String, dynamic>> getAdminTripRatings({
    int page = 1,
    int pageSize = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? levelId,
    int? leaderId,
    double? scoreMin,
    double? scoreMax,
    String sortBy = 'date',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
    
    if (dateFrom != null) {
      queryParams['dateFrom'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['dateTo'] = dateTo.toIso8601String().split('T')[0];
    }
    if (levelId != null) queryParams['levelId'] = levelId;
    if (leaderId != null) queryParams['leaderId'] = leaderId;
    if (scoreMin != null) queryParams['scoreMin'] = scoreMin;
    if (scoreMax != null) queryParams['scoreMax'] = scoreMax;
    
    final response = await _apiClient.get(
      MainApiEndpoints.adminTripRatings,
      queryParameters: queryParams,
    );
    
    return response.data;
  }
  
  /// Get detailed trip ratings (admin)
  Future<TripRatingSummaryModel> getAdminTripRatingDetails(int tripId) async {
    final response = await _apiClient.get(
      MainApiEndpoints.adminTripRatingDetails(tripId),
    );
    
    return TripRatingSummaryModel.fromJson(response.data);
  }
  
  /// List leader performance (admin)
  Future<Map<String, dynamic>> getLeaderPerformance({
    int page = 1,
    int pageSize = 20,
    String period = 'ytd',
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minTrips,
    String sortBy = 'score',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'period': period,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
    
    if (period == 'custom') {
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String().split('T')[0];
      }
    }
    if (minTrips != null) queryParams['minTrips'] = minTrips;
    
    final response = await _apiClient.get(
      MainApiEndpoints.adminLeaderPerformance,
      queryParameters: queryParams,
    );
    
    return response.data;
  }
  
  /// Get leader performance details (admin)
  Future<LeaderPerformanceModel> getLeaderPerformanceDetails(
    int leaderId, {
    String period = 'ytd',
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{'period': period};
    
    if (period == 'custom') {
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String().split('T')[0];
      }
    }
    
    final response = await _apiClient.get(
      MainApiEndpoints.adminLeaderPerformanceDetails(leaderId),
      queryParameters: queryParams,
    );
    
    return LeaderPerformanceModel.fromJson(response.data);
  }
  
  /// Get MSI dashboard statistics (admin)
  Future<MSIDashboardStatsModel> getMSIDashboardStats({
    String period = 'ytd',
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{'period': period};
    
    if (period == 'custom') {
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String().split('T')[0];
      }
    }
    
    final response = await _apiClient.get(
      MainApiEndpoints.adminMSIDashboardStats,
      queryParameters: queryParams,
    );
    
    return MSIDashboardStatsModel.fromJson(response.data);
  }
}
```

---

## 🎨 UI Components - Member Experience

### 1. Trip Rating Dialog Widget

**File:** `lib/features/trips/presentation/widgets/trip_rating_dialog.dart`

**Purpose:** Modal dialog for submitting trip ratings.

**Features:**
- Interactive star rating (tap to select 1-5 stars)
- Trip and leader rating sections
- Optional comment text field
- Validation (both ratings required)
- Submit and skip buttons
- Loading state during submission

**Key Implementation Points:**
```dart
class TripRatingDialog extends StatefulWidget {
  final PendingTripRatingModel pendingTrip;
  final VoidCallback onSubmitted;
  final VoidCallback onSkipped;
  
  const TripRatingDialog({
    Key? key,
    required this.pendingTrip,
    required this.onSubmitted,
    required this.onSkipped,
  }) : super(key: key);
  
  @override
  State<TripRatingDialog> createState() => _TripRatingDialogState();
}

class _TripRatingDialogState extends State<TripRatingDialog> {
  int? _tripRating;
  int? _leaderRating;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  
  // Build star rating widget
  Widget _buildStarRating({
    required String label,
    required int? currentRating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              icon: Icon(
                starValue <= (currentRating ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                size: 40,
                color: Colors.amber,
              ),
              onPressed: () => onRatingChanged(starValue),
            );
          }),
        ),
      ],
    );
  }
  
  // Validation and submission
  Future<void> _submitRating() async {
    if (_tripRating == null || _leaderRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate both trip and leader')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final repository = TripRatingRepository();
      await repository.submitRating(
        tripId: widget.pendingTrip.tripId,
        tripRating: _tripRating!,
        leaderRating: _leaderRating!,
        comment: _commentController.text.isNotEmpty 
            ? _commentController.text 
            : null,
      );
      
      widget.onSubmitted();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rate Your Trip',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onSkipped,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Trip info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terrain, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.pendingTrip.tripName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(widget.pendingTrip.tripDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Led by ${widget.pendingTrip.leaderName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                // Trip rating
                _buildStarRating(
                  label: 'How was the trip overall?',
                  currentRating: _tripRating,
                  onRatingChanged: (rating) => setState(() => _tripRating = rating),
                ),
                
                const SizedBox(height: 24),
                
                // Leader rating
                _buildStarRating(
                  label: 'How was the trip leader?',
                  currentRating: _leaderRating,
                  onRatingChanged: (rating) => setState(() => _leaderRating = rating),
                ),
                
                const SizedBox(height: 24),
                
                // Comment field
                Text(
                  'Add a comment for the trip report:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : widget.onSkipped,
                        child: const Text('Skip for Now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Review'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
```

---

### 2. Trip Rating Card Widget

**File:** `lib/features/trips/presentation/widgets/trip_rating_card_widget.dart`

**Purpose:** Compact card showing trip rating summary (for trip details screen).

```dart
class TripRatingCardWidget extends StatelessWidget {
  final TripRatingSummaryModel summary;
  
  const TripRatingCardWidget({
    Key? key,
    required this.summary,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final color = summary.color;
    final backgroundColor = RatingHelper.getBackgroundFromScore(summary.overallScore);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Member Ratings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (summary.totalReviews == 0) ...[
              Text(
                'No ratings yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              // Overall score
              Row(
                children: [
                  Text(
                    summary.overallScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        RatingHelper.getPerformanceLabel(summary.overallScore),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${summary.totalReviews} reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildRatingBreakdown(
                      context,
                      'Trip',
                      summary.averageTripRating,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRatingBreakdown(
                      context,
                      'Leader',
                      summary.averageLeaderRating,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingBreakdown(BuildContext context, String label, double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 16, color: Colors.amber),
          ],
        ),
      ],
    );
  }
}
```

---

## 🎨 UI Components - Admin Experience

### 3. MSI Overview Screen (Admin Page 1)

**File:** `lib/features/admin/presentation/screens/msi_overview_screen.dart`

**Purpose:** Grid of trip cards with ratings and filters.

**Features:**
- Card grid layout
- Color-coded cards
- Filters (date range, level, leader, score range)
- Sorting options
- Pagination
- Navigation to details screen

### 4. Trip Rating Details Screen

**File:** `lib/features/admin/presentation/screens/trip_rating_details_screen.dart`

**Purpose:** Detailed view of all ratings for a specific trip.

**Features:**
- Trip information header
- List of individual reviews
- Clickable user profiles
- Response rate statistics
- Overall score breakdown

### 5. Leader Performance Screen (Admin Page 2)

**File:** `lib/features/admin/presentation/screens/leader_performance_screen.dart`

**Purpose:** List of trip leaders sorted by performance.

**Features:**
- Card list of leaders
- Color-coded performance indicators
- Filters (date period, minimum trips)
- Sorting options
- Navigation to leader details

### 6. Leader Performance Details Screen

**File:** `lib/features/admin/presentation/screens/leader_performance_details_screen.dart`

**Purpose:** Detailed performance analytics for a specific leader.

**Features:**
- Leader profile information
- Performance trend chart
- Recent trips list with scores
- Overall statistics

### 7. MSI Dashboard Widget

**File:** `lib/features/admin/presentation/widgets/msi_dashboard_widget.dart`

**Purpose:** Summary widget for admin dashboard.

**Features:**
- Club-wide average score
- Total reviews count
- Trend indicator
- Top 3 leaders
- Top 3 reviewers

---

## 🔄 State Management (Riverpod)

### Create Providers

**File:** `lib/features/admin/presentation/providers/trip_rating_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../trips/data/repositories/trip_rating_repository.dart';
import '../../../../data/models/trip_rating_summary_model.dart';

final tripRatingRepositoryProvider = Provider<TripRatingRepository>((ref) {
  return TripRatingRepository();
});

// Admin trip ratings list
final adminTripRatingsProvider = FutureProvider.autoDispose.family<
    Map<String, dynamic>,
    Map<String, dynamic>
>((ref, params) async {
  final repository = ref.watch(tripRatingRepositoryProvider);
  return repository.getAdminTripRatings(
    page: params['page'] as int? ?? 1,
    pageSize: params['pageSize'] as int? ?? 20,
    dateFrom: params['dateFrom'] as DateTime?,
    dateTo: params['dateTo'] as DateTime?,
    levelId: params['levelId'] as int?,
    leaderId: params['leaderId'] as int?,
    scoreMin: params['scoreMin'] as double?,
    scoreMax: params['scoreMax'] as double?,
    sortBy: params['sortBy'] as String? ?? 'date',
    sortOrder: params['sortOrder'] as String? ?? 'desc',
  );
});

// Trip rating details
final tripRatingDetailsProvider = FutureProvider.autoDispose.family<
    TripRatingSummaryModel,
    int
>((ref, tripId) async {
  final repository = ref.watch(tripRatingRepositoryProvider);
  return repository.getAdminTripRatingDetails(tripId);
});
```

---

## 🚀 Integration Points

### 1. Main App Entry Point

**File:** `lib/main.dart`

**Modification:** Add pending ratings check after authentication.

```dart
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    ref.listenManual(authProviderV2, (previous, next) {
      if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
        // User just logged in - check for pending ratings
        _checkPendingRatings();
      }
    });
  }
  
  Future<void> _checkPendingRatings() async {
    // Wait a moment for UI to settle
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final repository = TripRatingRepository();
      final pendingRatings = await repository.getPendingRatings();
      
      if (pendingRatings.isNotEmpty && mounted) {
        // Show rating dialog for each pending trip in sequence
        for (final pendingTrip in pendingRatings) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => TripRatingDialog(
              pendingTrip: pendingTrip,
              onSubmitted: () {
                // Rating submitted - dialog will close automatically
              },
              onSkipped: () {
                // User skipped - close dialog
                Navigator.of(context).pop();
              },
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      debugPrint('Error checking pending ratings: $e');
    }
  }
  
  // ... rest of MyApp implementation
}
```

---

### 2. Trip Details Screen Integration

**File:** `lib/features/trips/presentation/screens/trip_details_screen.dart`

**Modification:** Add rating summary section.

```dart
// In the trip details screen build method, add after trip information:

// Rating section (public - everyone can see)
FutureBuilder<TripRatingSummaryModel>(
  future: TripRatingRepository().getTripRatingsSummary(widget.tripId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TripRatingCardWidget(summary: snapshot.data!),
      );
    }
    
    if (snapshot.hasError) {
      return const SizedBox.shrink();  // Hide if error
    }
    
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  },
),
```

---

### 3. Notification Handler

**File:** `lib/features/notifications/presentation/screens/notifications_screen.dart`

**Modification:** Handle `rate_trip` action type.

```dart
void _handleNotificationTap(NotificationModel notification) {
  // ... existing action handlers ...
  
  if (notification.actionType == 'rate_trip' && notification.actionId != null) {
    // Fetch trip details and show rating dialog
    final tripId = int.parse(notification.actionId!);
    
    // Create pending trip model from notification metadata
    final pendingTrip = PendingTripRatingModel(
      tripId: tripId,
      tripName: notification.metadata?['tripName'] ?? 'Trip',
      tripDate: DateTime.parse(notification.metadata?['tripDate'] ?? DateTime.now().toIso8601String()),
      leaderId: notification.metadata?['leaderId'] ?? 0,
      leaderName: notification.metadata?['leaderName'] ?? 'Leader',
      leaderAvatar: notification.metadata?['leaderAvatar'],
      completedAt: notification.timestamp,
    );
    
    showDialog(
      context: context,
      builder: (context) => TripRatingDialog(
        pendingTrip: pendingTrip,
        onSubmitted: () {
          // Mark notification as read
          // Refresh notifications list
        },
        onSkipped: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
```

---

### 4. Admin Dashboard Integration

**File:** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`

**Modification:** Add MSI dashboard widget.

```dart
// In admin dashboard screen, add MSI widget:

// MSI Statistics
Consumer(
  builder: (context, ref, child) {
    final msiStats = ref.watch(msiDashboardStatsProvider);
    
    return msiStats.when(
      data: (stats) => MSIDashboardWidget(stats: stats),
      loading: () => const MSILoadingWidget(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  },
),
```

---

### 5. Admin Navigation

**File:** `lib/core/router/app_router.dart`

**Modification:** Add MSI section routes.

```dart
GoRoute(
  path: '/admin/msi',
  name: 'admin-msi-overview',
  builder: (context, state) {
    return const MSIOverviewScreen();
  },
),
GoRoute(
  path: '/admin/msi/trip/:id',
  name: 'admin-msi-trip-details',
  builder: (context, state) {
    final tripId = int.parse(state.pathParameters['id']!);
    return TripRatingDetailsScreen(tripId: tripId);
  },
),
GoRoute(
  path: '/admin/msi/leaders',
  name: 'admin-msi-leaders',
  builder: (context, state) {
    return const LeaderPerformanceScreen();
  },
),
GoRoute(
  path: '/admin/msi/leader/:id',
  name: 'admin-msi-leader-details',
  builder: (context, state) {
    final leaderId = int.parse(state.pathParameters['id']!);
    return LeaderPerformanceDetailsScreen(leaderId: leaderId);
  },
),
```

**Add to admin drawer/menu:**
```dart
if (user?.hasPermission('VIEW_TRIP_FEEDBACK') ?? false)
  ListTile(
    leading: const Icon(Icons.analytics),
    title: const Text('MSI - Member Satisfaction'),
    onTap: () => context.go('/admin/msi'),
  ),
```

---

## ✅ Implementation Checklist

### Phase 1: Core Models & Repository (Day 1-2)
- [ ] Create `TripRatingModel`
- [ ] Create `TripRatingSummaryModel`
- [ ] Create `LeaderPerformanceModel`
- [ ] Create `MSIDashboardStatsModel`
- [ ] Create `TopReviewerModel`
- [ ] Create `PendingTripRatingModel`
- [ ] Create `RatingHelper` utility class
- [ ] Update `main_api_endpoints.dart` with new endpoints
- [ ] Create `TripRatingRepository`
- [ ] Write unit tests for models

### Phase 2: Member Experience (Day 3-4)
- [ ] Create `TripRatingDialog` widget
- [ ] Create `TripRatingCardWidget`
- [ ] Integrate pending ratings check in `main.dart`
- [ ] Add rating section to `trip_details_screen.dart`
- [ ] Update notification handler for `rate_trip` action
- [ ] Test rating submission flow
- [ ] Test dialog sequence for multiple pending ratings

### Phase 3: Admin Overview Screens (Day 5-7)
- [ ] Create `MSIOverviewScreen` (trip ratings list)
- [ ] Create `TripRatingCard` widget
- [ ] Implement filters and sorting
- [ ] Add pagination
- [ ] Create `TripRatingDetailsScreen`
- [ ] Display individual reviews
- [ ] Add clickable user profiles
- [ ] Create Riverpod providers

### Phase 4: Leader Performance (Day 8-10)
- [ ] Create `LeaderPerformanceScreen`
- [ ] Create `LeaderPerformanceCard` widget
- [ ] Implement filters and sorting
- [ ] Create `LeaderPerformanceDetailsScreen`
- [ ] Add performance trend chart
- [ ] Display trip history with scores
- [ ] Create Riverpod providers

### Phase 5: Dashboard Integration (Day 11-12)
- [ ] Create `MSIDashboardWidget`
- [ ] Display club-wide statistics
- [ ] Show top leaders
- [ ] Show top reviewers
- [ ] Integrate into admin dashboard
- [ ] Create Riverpod provider for dashboard stats

### Phase 6: Navigation & Routes (Day 13)
- [ ] Add MSI routes to `app_router.dart`
- [ ] Add MSI section to admin drawer
- [ ] Test all navigation flows
- [ ] Implement permission checks on routes

### Phase 7: Polish & Testing (Day 14-15)
- [ ] Add loading states
- [ ] Add error handling
- [ ] Add empty states
- [ ] Implement color-coded indicators
- [ ] Test with historic data (zero ratings)
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Accessibility testing

---

## 🧪 Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Rating calculation logic
- Color coding logic
- Repository methods

### Widget Tests
- Trip rating dialog
- Rating card widgets
- Dashboard widgets
- Admin screens

### Integration Tests
- Full rating submission flow
- Pending ratings check on login
- Notification to rating dialog flow
- Admin filtering and sorting

---

## 📊 Success Criteria

### Member Experience:
- ✅ Users see rating popup immediately after login if pending ratings exist
- ✅ Rating submission completes without errors
- ✅ Users can skip rating and access via notification later
- ✅ Trip owners cannot rate their own trips
- ✅ Ratings are one-time only (cannot be edited)

### Admin Experience:
- ✅ MSI overview shows all trips with accurate ratings
- ✅ Color coding reflects actual performance levels
- ✅ Filters and sorting work correctly
- ✅ Leader performance metrics are accurate
- ✅ Dashboard widget displays correct statistics
- ✅ Permission system restricts access appropriately

### Technical:
- ✅ All API calls handle errors gracefully
- ✅ Historic data (zero ratings) displays correctly without errors
- ✅ UI remains responsive with large datasets
- ✅ Color-coded indicators are accessible
- ✅ No breaking changes to existing features

---

## 📝 Notes & Considerations

### Important Implementation Notes:

1. **Trip vs Event Filter:** Always filter out events when checking for rateable trips
2. **Owner Exclusion:** Check if current user is trip owner before showing rating dialog
3. **One-Time Rating:** Backend must enforce one rating per user per trip
4. **Historic Data:** Always handle zero ratings gracefully (no errors, display "No ratings")
5. **Notification Timing:** Backend sends notification when trip status changes to completed
6. **YTD Default:** Admin dashboard should default to Year-To-Date period

### Future Enhancements (Not in v1.0):
- Edit/delete ratings (admin only)
- Leader response to reviews
- Minimum review threshold warnings
- Rating reminder emails
- Export rating data to CSV
- Advanced analytics charts

---

## 🔗 Dependencies

### Required Flutter Packages (Already in project):
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `dio`: HTTP client
- `intl`: Date formatting

### No New Package Dependencies Required

---

## 📚 Reference Materials

- [Backend API Documentation](./BACKEND_API_DOCUMENTATION.md)
- Flutter Material Design 3 Guidelines
- Existing codebase patterns and conventions
- Permission system documentation

---

**End of Frontend Implementation Plan**

*This document will be the primary reference during implementation. All features should be built according to these specifications.*
