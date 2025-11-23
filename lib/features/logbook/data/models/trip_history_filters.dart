import 'package:flutter/material.dart';

/// Trip History Filters Model
/// 
/// Comprehensive filter state for trip history with logbook context
class TripHistoryFilters {
  // Date Range Filters
  final DateRangePreset dateRangePreset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  
  // Trip Filters
  final Set<int> selectedLevelIds; // Skill levels (1-4: beginner to expert)
  final TripAttendanceFilter attendanceFilter;
  final bool onlyTripsWithSkills; // Only show trips with verified skills
  
  // Search & Sort
  final String searchQuery;
  final TripHistorySortOption sortBy;
  final bool sortDescending;
  
  const TripHistoryFilters({
    this.dateRangePreset = DateRangePreset.all,
    this.customStartDate,
    this.customEndDate,
    this.selectedLevelIds = const {},
    this.attendanceFilter = TripAttendanceFilter.all,
    this.onlyTripsWithSkills = false,
    this.searchQuery = '',
    this.sortBy = TripHistorySortOption.dateNewest,
    this.sortDescending = true,
  });

  /// Get effective start date based on preset or custom date
  DateTime? get effectiveStartDate {
    if (customStartDate != null) return customStartDate;
    
    final now = DateTime.now();
    switch (dateRangePreset) {
      case DateRangePreset.lastMonth:
        return now.subtract(const Duration(days: 30));
      case DateRangePreset.last3Months:
        return now.subtract(const Duration(days: 90));
      case DateRangePreset.last6Months:
        return now.subtract(const Duration(days: 180));
      case DateRangePreset.lastYear:
        return now.subtract(const Duration(days: 365));
      case DateRangePreset.thisYear:
        return DateTime(now.year, 1, 1);
      case DateRangePreset.custom:
        return customStartDate;
      case DateRangePreset.all:
        return null;
    }
  }

  /// Get effective end date based on preset or custom date
  DateTime? get effectiveEndDate {
    if (customEndDate != null) return customEndDate;
    
    final now = DateTime.now();
    switch (dateRangePreset) {
      case DateRangePreset.thisYear:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case DateRangePreset.custom:
        return customEndDate;
      default:
        return null;
    }
  }

  /// Check if filters are at default state
  bool get isDefault {
    return dateRangePreset == DateRangePreset.all &&
        selectedLevelIds.isEmpty &&
        attendanceFilter == TripAttendanceFilter.all &&
        !onlyTripsWithSkills &&
        searchQuery.isEmpty &&
        sortBy == TripHistorySortOption.dateNewest &&
        sortDescending;
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (dateRangePreset != DateRangePreset.all) count++;
    if (selectedLevelIds.isNotEmpty) count++;
    if (attendanceFilter != TripAttendanceFilter.all) count++;
    if (onlyTripsWithSkills) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  /// Get human-readable filter summary
  String get filterSummary {
    final parts = <String>[];
    
    if (dateRangePreset != DateRangePreset.all) {
      parts.add(dateRangePreset.displayName);
    }
    if (selectedLevelIds.isNotEmpty) {
      parts.add('${selectedLevelIds.length} level${selectedLevelIds.length > 1 ? 's' : ''}');
    }
    if (attendanceFilter != TripAttendanceFilter.all) {
      parts.add(attendanceFilter.displayName);
    }
    if (onlyTripsWithSkills) {
      parts.add('With skills');
    }
    if (searchQuery.isNotEmpty) {
      parts.add('Search: "$searchQuery"');
    }
    
    return parts.isEmpty ? 'All trips' : parts.join(' • ');
  }

  TripHistoryFilters copyWith({
    DateRangePreset? dateRangePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<int>? selectedLevelIds,
    TripAttendanceFilter? attendanceFilter,
    bool? onlyTripsWithSkills,
    String? searchQuery,
    TripHistorySortOption? sortBy,
    bool? sortDescending,
  }) {
    return TripHistoryFilters(
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      selectedLevelIds: selectedLevelIds ?? this.selectedLevelIds,
      attendanceFilter: attendanceFilter ?? this.attendanceFilter,
      onlyTripsWithSkills: onlyTripsWithSkills ?? this.onlyTripsWithSkills,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Reset to default filters
  TripHistoryFilters reset() {
    return const TripHistoryFilters();
  }

  Map<String, dynamic> toJson() {
    return {
      'dateRangePreset': dateRangePreset.name,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'selectedLevelIds': selectedLevelIds.toList(),
      'attendanceFilter': attendanceFilter.name,
      'onlyTripsWithSkills': onlyTripsWithSkills,
      'searchQuery': searchQuery,
      'sortBy': sortBy.name,
      'sortDescending': sortDescending,
    };
  }
}

/// Date Range Presets for quick selection
enum DateRangePreset {
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  thisYear,
  custom,
  all,
}

/// Trip Attendance Filter Options
enum TripAttendanceFilter {
  all,
  attended,
  registered,
  upcoming,
  completed,
}

/// Sort Options for Trip History
enum TripHistorySortOption {
  dateNewest,
  dateOldest,
  skillsVerified,
  tripLevel,
  title,
}

// Extensions for display names and icons

extension DateRangePresetExtension on DateRangePreset {
  String get displayName {
    switch (this) {
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.last3Months:
        return 'Last 3 Months';
      case DateRangePreset.last6Months:
        return 'Last 6 Months';
      case DateRangePreset.lastYear:
        return 'Last Year';
      case DateRangePreset.thisYear:
        return 'This Year';
      case DateRangePreset.custom:
        return 'Custom Range';
      case DateRangePreset.all:
        return 'All Time';
    }
  }

  IconData get icon {
    switch (this) {
      case DateRangePreset.lastMonth:
        return Icons.calendar_month;
      case DateRangePreset.last3Months:
      case DateRangePreset.last6Months:
        return Icons.date_range;
      case DateRangePreset.lastYear:
      case DateRangePreset.thisYear:
        return Icons.calendar_today;
      case DateRangePreset.custom:
        return Icons.edit_calendar;
      case DateRangePreset.all:
        return Icons.all_inclusive;
    }
  }
}

extension TripAttendanceFilterExtension on TripAttendanceFilter {
  String get displayName {
    switch (this) {
      case TripAttendanceFilter.all:
        return 'All Trips';
      case TripAttendanceFilter.attended:
        return 'Attended';
      case TripAttendanceFilter.registered:
        return 'Registered';
      case TripAttendanceFilter.upcoming:
        return 'Upcoming';
      case TripAttendanceFilter.completed:
        return 'Completed';
    }
  }

  IconData get icon {
    switch (this) {
      case TripAttendanceFilter.all:
        return Icons.list;
      case TripAttendanceFilter.attended:
        return Icons.check_circle;
      case TripAttendanceFilter.registered:
        return Icons.how_to_reg;
      case TripAttendanceFilter.upcoming:
        return Icons.schedule;
      case TripAttendanceFilter.completed:
        return Icons.done_all;
    }
  }
}

extension TripHistorySortOptionExtension on TripHistorySortOption {
  String get displayName {
    switch (this) {
      case TripHistorySortOption.dateNewest:
        return 'Date (Newest First)';
      case TripHistorySortOption.dateOldest:
        return 'Date (Oldest First)';
      case TripHistorySortOption.skillsVerified:
        return 'Skills Verified';
      case TripHistorySortOption.tripLevel:
        return 'Trip Level';
      case TripHistorySortOption.title:
        return 'Trip Title';
    }
  }

  IconData get icon {
    switch (this) {
      case TripHistorySortOption.dateNewest:
      case TripHistorySortOption.dateOldest:
        return Icons.event;
      case TripHistorySortOption.skillsVerified:
        return Icons.star;
      case TripHistorySortOption.tripLevel:
        return Icons.signal_cellular_alt;
      case TripHistorySortOption.title:
        return Icons.sort_by_alpha;
    }
  }
}

/// Filter Statistics for display
class TripHistoryFilterStats {
  final int totalTrips;
  final int filteredTrips;
  final int totalSkillsVerified;
  final int tripsWithSkills;
  final List<String> levelBreakdown; // e.g., ["Beginner: 5", "Intermediate: 10"]

  const TripHistoryFilterStats({
    required this.totalTrips,
    required this.filteredTrips,
    required this.totalSkillsVerified,
    required this.tripsWithSkills,
    required this.levelBreakdown,
  });

  double get filterEfficiency {
    if (totalTrips == 0) return 0.0;
    return filteredTrips / totalTrips;
  }

  String get summary {
    if (totalTrips == 0) return 'No trips found';
    if (filteredTrips == totalTrips) return 'Showing all $totalTrips trips';
    return 'Showing $filteredTrips of $totalTrips trips';
  }
}
