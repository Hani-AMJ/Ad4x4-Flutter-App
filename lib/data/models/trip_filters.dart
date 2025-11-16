import 'package:flutter/material.dart';

/// Trip Filters Model
/// 
/// Holds filter state for trips list
class TripFilters {
  final TripViewMode view;
  final TripDateRange dateRange;
  // Status filter removed - redundant without Past Trips tab
  final int? levelId;
  final String? area;
  final String ordering;
  
  // ✅ NEW: Advanced filters (Phase A Task #4)
  final int? meetingPointId;
  final int? leadId;
  final DateTime? endTimeAfter;
  final DateTime? endTimeBefore;

  const TripFilters({
    this.view = TripViewMode.list,
    this.dateRange = TripDateRange.all,
    this.levelId,
    this.area,
    this.ordering = 'start_time',  // ✅ Ascending order (soonest first) for upcoming trips
    this.meetingPointId,
    this.leadId,
    this.endTimeAfter,
    this.endTimeBefore,
  });

  TripFilters copyWith({
    TripViewMode? view,
    TripDateRange? dateRange,
    int? levelId,
    String? area,
    String? ordering,
    int? meetingPointId,
    int? leadId,
    DateTime? endTimeAfter,
    DateTime? endTimeBefore,
  }) {
    return TripFilters(
      view: view ?? this.view,
      dateRange: dateRange ?? this.dateRange,
      levelId: levelId ?? this.levelId,
      area: area ?? this.area,
      ordering: ordering ?? this.ordering,
      meetingPointId: meetingPointId ?? this.meetingPointId,
      leadId: leadId ?? this.leadId,
      endTimeAfter: endTimeAfter ?? this.endTimeAfter,
      endTimeBefore: endTimeBefore ?? this.endTimeBefore,
    );
  }

  /// Get start date based on filter (calendar week logic: Monday to Sunday)
  DateTime? get startDate {
    final now = DateTime.now();
    
    switch (dateRange) {
      case TripDateRange.thisWeek:
        // Start of this week (Monday)
        final daysFromMonday = (now.weekday - DateTime.monday) % 7;
        return now.subtract(Duration(days: daysFromMonday)).copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0,
        );
        
      case TripDateRange.nextWeek:
        // Start of next week (Monday)
        final daysFromMonday = (now.weekday - DateTime.monday) % 7;
        final thisMonday = now.subtract(Duration(days: daysFromMonday));
        return thisMonday.add(const Duration(days: 7)).copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0,
        );
        
      case TripDateRange.all:
        return null;
    }
  }

  /// Get end date based on filter (calendar week logic: Monday to Sunday)
  DateTime? get endDate {
    final now = DateTime.now();
    
    switch (dateRange) {
      case TripDateRange.thisWeek:
        // End of this week (Sunday 23:59:59)
        final daysFromMonday = (now.weekday - DateTime.monday) % 7;
        final thisMonday = now.subtract(Duration(days: daysFromMonday));
        return thisMonday.add(const Duration(days: 6)).copyWith(
          hour: 23, minute: 59, second: 59, millisecond: 999,
        );
        
      case TripDateRange.nextWeek:
        // End of next week (Sunday 23:59:59)
        final daysFromMonday = (now.weekday - DateTime.monday) % 7;
        final thisMonday = now.subtract(Duration(days: daysFromMonday));
        final nextMonday = thisMonday.add(const Duration(days: 7));
        return nextMonday.add(const Duration(days: 6)).copyWith(
          hour: 23, minute: 59, second: 59, millisecond: 999,
        );
        
      case TripDateRange.all:
        return null;
    }
  }

  /// Check if filters are default
  bool get isDefault {
    return view == TripViewMode.list &&
        dateRange == TripDateRange.all &&
        levelId == null &&
        area == null &&
        meetingPointId == null &&
        leadId == null &&
        endTimeAfter == null &&
        endTimeBefore == null &&
        ordering == 'start_time';
  }

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (dateRange != TripDateRange.all) count++;
    if (levelId != null) count++;
    if (area != null) count++;
    if (meetingPointId != null) count++;
    if (leadId != null) count++;
    if (endTimeAfter != null || endTimeBefore != null) count++;
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'view': view.name,
      'dateRange': dateRange.name,
      'levelId': levelId,
      'area': area,
      'ordering': ordering,
      'meetingPointId': meetingPointId,
      'leadId': leadId,
      'endTimeAfter': endTimeAfter?.toIso8601String(),
      'endTimeBefore': endTimeBefore?.toIso8601String(),
    };
  }
}

enum TripViewMode {
  list,
  map,
}

enum TripDateRange {
  thisWeek,
  nextWeek,
  all,
}

// Status filter removed - redundant without Past Trips tab
// enum TripStatus {
//   upcoming,
//   ongoing,
//   completed,
//   all,
// }

extension TripViewModeExtension on TripViewMode {
  String get displayName {
    switch (this) {
      case TripViewMode.list:
        return 'List';
      case TripViewMode.map:
        return 'Map';
    }
  }

  IconData get icon {
    switch (this) {
      case TripViewMode.list:
        return Icons.list;
      case TripViewMode.map:
        return Icons.map;
    }
  }
}

extension TripDateRangeExtension on TripDateRange {
  String get displayName {
    switch (this) {
      case TripDateRange.thisWeek:
        return 'This Week';
      case TripDateRange.nextWeek:
        return 'Next Week';
      case TripDateRange.all:
        return 'All';
    }
  }
}

// Status extension removed - redundant without Past Trips tab
