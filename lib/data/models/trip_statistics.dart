/// Trip statistics model for detailed member trip stats
/// 
/// Corresponds to backend API endpoint: GET /api/members/{id}/tripcounts
/// Returns DetailedTripStatsOverview schema
class TripStatistics {
  final int totalTrips;
  final int upcomingTrips;
  final int completedTrips;
  final int cancelledTrips;
  final int asLeadTrips;
  final int asMarshalTrips;
  final int level1Trips;
  final int level2Trips;
  final int level3Trips;
  final int level4Trips;
  final int level5Trips;
  final String? mostFrequentArea;
  final int checkedInCount;
  final double attendanceRate; // Percentage

  const TripStatistics({
    required this.totalTrips,
    this.upcomingTrips = 0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.asLeadTrips = 0,
    this.asMarshalTrips = 0,
    this.level1Trips = 0,
    this.level2Trips = 0,
    this.level3Trips = 0,
    this.level4Trips = 0,
    this.level5Trips = 0,
    this.mostFrequentArea,
    this.checkedInCount = 0,
    this.attendanceRate = 0.0,
  });

  /// Create TripStatistics from JSON response
  /// 
  /// Backend returns:
  /// {
  ///   "member": {"id": 123, "username": "John Doe"},
  ///   "tripStats": [
  ///     {"levelName": "ANIT", "levelNumeric": 10, "count": 11},
  ///     {"levelName": "Newbie", "levelNumeric": 10, "count": 7},
  ///     {"levelName": "Intermediate", "levelNumeric": 100, "count": 2},
  ///     {"levelName": "Advanced", "levelNumeric": 200, "count": 6},
  ///     {"levelName": "Expert", "levelNumeric": 300, "count": 2},
  ///     {"levelName": "Club Event", "levelNumeric": 5, "count": 22}
  ///   ]
  /// }
  factory TripStatistics.fromJson(Map<String, dynamic> json) {
    // Parse tripStats array if present
    final tripStatsArray = json['tripStats'] as List<dynamic>?;
    
    int totalTripsCount = 0;
    // Map to UI display order (as per LevelDisplayHelper.getTripLevelLabel):
    // Level 1 in UI = Club Event (levelNumeric: 5)
    // Level 2 in UI = Newbie/ANIT (levelNumeric: 10)
    // Level 3 in UI = Intermediate (levelNumeric: 100)
    // Level 4 in UI = Advanced (levelNumeric: 200)
    // Level 5 in UI = Expert (levelNumeric: 300)
    int level1Count = 0;  // Club Event (levelNumeric: 5)
    int level2Count = 0;  // Newbie/ANIT (levelNumeric: 10)
    int level3Count = 0;  // Intermediate (levelNumeric: 100)
    int level4Count = 0;  // Advanced (levelNumeric: 200)
    int level5Count = 0;  // Expert (levelNumeric: 300)
    
    if (tripStatsArray != null) {
      for (final stat in tripStatsArray) {
        if (stat is Map<String, dynamic>) {
          final levelNumeric = _parseInt(stat['levelNumeric']);
          final count = _parseInt(stat['count']);
          
          // Map levelNumeric to UI levels (matching LevelDisplayHelper)
          if (levelNumeric == 5) {
            level1Count += count; // Club Event
          } else if (levelNumeric == 10) {
            level2Count += count; // Newbie/ANIT
          } else if (levelNumeric == 100) {
            level3Count += count; // Intermediate
          } else if (levelNumeric == 200) {
            level4Count += count; // Advanced
          } else if (levelNumeric == 300) {
            level5Count += count; // Expert
          }
          
          // Count total trips (including club events)
          totalTripsCount += count;
        }
      }
    }
    
    return TripStatistics(
      totalTrips: totalTripsCount,
      upcomingTrips: _parseInt(json['upcomingTrips'] ?? json['upcoming_trips'] ?? json['upcoming'] ?? 0),
      completedTrips: totalTripsCount, // All trips in tripStats are completed (checked-in)
      cancelledTrips: _parseInt(json['cancelledTrips'] ?? json['cancelled_trips'] ?? json['cancelled'] ?? 0),
      asLeadTrips: _parseInt(json['asLeadTrips'] ?? json['as_lead_trips'] ?? json['asLead'] ?? json['as_lead'] ?? 0),
      asMarshalTrips: _parseInt(json['asMarshalTrips'] ?? json['as_marshal_trips'] ?? json['asMarshal'] ?? json['as_marshal'] ?? 0),
      level1Trips: level1Count, // Club Event
      level2Trips: level2Count, // Newbie
      level3Trips: level3Count, // Intermediate
      level4Trips: level4Count, // Advanced
      level5Trips: level5Count, // Expert
      mostFrequentArea: json['mostFrequentArea'] as String? ?? json['most_frequent_area'] as String?,
      checkedInCount: totalTripsCount, // All trips in tripStats represent checked-in trips
      attendanceRate: _parseDouble(json['attendanceRate'] ?? json['attendance_rate'] ?? 0.0),
    );
  }

  /// Helper to parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper to parse double from dynamic value
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get trip count by level number
  int getTripCountByLevel(int level) {
    switch (level) {
      case 1:
        return level1Trips;
      case 2:
        return level2Trips;
      case 3:
        return level3Trips;
      case 4:
        return level4Trips;
      case 5:
        return level5Trips;
      default:
        return 0;
    }
  }

  /// Get total leadership roles (lead + marshal)
  int get totalLeadershipRoles => asLeadTrips + asMarshalTrips;

  /// Check if member has leadership experience
  bool get hasLeadershipExperience => totalLeadershipRoles > 0;

  /// Get most participated level
  int? get mostParticipatedLevel {
    int maxCount = 0;
    int? maxLevel;

    for (int i = 1; i <= 5; i++) {
      final count = getTripCountByLevel(i);
      if (count > maxCount) {
        maxCount = count;
        maxLevel = i;
      }
    }

    return maxLevel;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalTrips': totalTrips,
      'upcomingTrips': upcomingTrips,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'asLeadTrips': asLeadTrips,
      'asMarshalTrips': asMarshalTrips,
      'level1Trips': level1Trips,
      'level2Trips': level2Trips,
      'level3Trips': level3Trips,
      'level4Trips': level4Trips,
      'level5Trips': level5Trips,
      'mostFrequentArea': mostFrequentArea,
      'checkedInCount': checkedInCount,
      'attendanceRate': attendanceRate,
    };
  }

  /// Create a copy with updated fields
  TripStatistics copyWith({
    int? totalTrips,
    int? upcomingTrips,
    int? completedTrips,
    int? cancelledTrips,
    int? asLeadTrips,
    int? asMarshalTrips,
    int? level1Trips,
    int? level2Trips,
    int? level3Trips,
    int? level4Trips,
    int? level5Trips,
    String? mostFrequentArea,
    int? checkedInCount,
    double? attendanceRate,
  }) {
    return TripStatistics(
      totalTrips: totalTrips ?? this.totalTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      asLeadTrips: asLeadTrips ?? this.asLeadTrips,
      asMarshalTrips: asMarshalTrips ?? this.asMarshalTrips,
      level1Trips: level1Trips ?? this.level1Trips,
      level2Trips: level2Trips ?? this.level2Trips,
      level3Trips: level3Trips ?? this.level3Trips,
      level4Trips: level4Trips ?? this.level4Trips,
      level5Trips: level5Trips ?? this.level5Trips,
      mostFrequentArea: mostFrequentArea ?? this.mostFrequentArea,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      attendanceRate: attendanceRate ?? this.attendanceRate,
    );
  }
}
