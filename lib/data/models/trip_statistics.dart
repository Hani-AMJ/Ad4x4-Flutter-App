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
  factory TripStatistics.fromJson(Map<String, dynamic> json) {
    return TripStatistics(
      totalTrips: _parseInt(json['totalTrips'] ?? json['total_trips'] ?? json['total'] ?? 0),
      upcomingTrips: _parseInt(json['upcomingTrips'] ?? json['upcoming_trips'] ?? json['upcoming'] ?? 0),
      completedTrips: _parseInt(json['completedTrips'] ?? json['completed_trips'] ?? json['completed'] ?? 0),
      cancelledTrips: _parseInt(json['cancelledTrips'] ?? json['cancelled_trips'] ?? json['cancelled'] ?? 0),
      asLeadTrips: _parseInt(json['asLeadTrips'] ?? json['as_lead_trips'] ?? json['asLead'] ?? json['as_lead'] ?? 0),
      asMarshalTrips: _parseInt(json['asMarshalTrips'] ?? json['as_marshal_trips'] ?? json['asMarshal'] ?? json['as_marshal'] ?? 0),
      level1Trips: _parseInt(json['level1Trips'] ?? json['level_1_trips'] ?? json['level1'] ?? 0),
      level2Trips: _parseInt(json['level2Trips'] ?? json['level_2_trips'] ?? json['level2'] ?? 0),
      level3Trips: _parseInt(json['level3Trips'] ?? json['level_3_trips'] ?? json['level3'] ?? 0),
      level4Trips: _parseInt(json['level4Trips'] ?? json['level_4_trips'] ?? json['level4'] ?? 0),
      level5Trips: _parseInt(json['level5Trips'] ?? json['level_5_trips'] ?? json['level5'] ?? 0),
      mostFrequentArea: json['mostFrequentArea'] as String? ?? json['most_frequent_area'] as String?,
      checkedInCount: _parseInt(json['checkedInCount'] ?? json['checked_in_count'] ?? json['checkedIn'] ?? 0),
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
