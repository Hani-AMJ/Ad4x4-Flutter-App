import 'package:flutter/material.dart';

/// Trip Filters Model
/// 
/// Holds filter state for trips list
class TripFilters {
  final TripViewMode view;
  final TripDateRange dateRange;
  final TripStatus status;
  final int? levelId;
  final String? area;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String ordering;

  const TripFilters({
    this.view = TripViewMode.list,
    this.dateRange = TripDateRange.all,  // Changed from thisWeek to all
    this.status = TripStatus.all,        // Changed from upcoming to all
    this.levelId,
    this.area,
    this.customStartDate,
    this.customEndDate,
    this.ordering = '-start_time',  // Descending order (newest first) directly from API
  });

  TripFilters copyWith({
    TripViewMode? view,
    TripDateRange? dateRange,
    TripStatus? status,
    int? levelId,
    String? area,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? ordering,
  }) {
    return TripFilters(
      view: view ?? this.view,
      dateRange: dateRange ?? this.dateRange,
      status: status ?? this.status,
      levelId: levelId ?? this.levelId,
      area: area ?? this.area,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      ordering: ordering ?? this.ordering,
    );
  }

  /// Get start date based on filter
  DateTime? get startDate {
    if (dateRange == TripDateRange.custom && customStartDate != null) {
      return customStartDate;
    }

    final now = DateTime.now();
    switch (dateRange) {
      case TripDateRange.thisWeek:
        return now;
      case TripDateRange.nextWeek:
        return now.add(const Duration(days: 7));
      case TripDateRange.thisMonth:
        return now;
      case TripDateRange.custom:
        return customStartDate;
      case TripDateRange.all:
        return null;
    }
  }

  /// Get end date based on filter
  DateTime? get endDate {
    if (dateRange == TripDateRange.custom && customEndDate != null) {
      return customEndDate;
    }

    final now = DateTime.now();
    switch (dateRange) {
      case TripDateRange.thisWeek:
        return now.add(const Duration(days: 7));
      case TripDateRange.nextWeek:
        return now.add(const Duration(days: 14));
      case TripDateRange.thisMonth:
        return DateTime(now.year, now.month + 1, 0);
      case TripDateRange.custom:
        return customEndDate;
      case TripDateRange.all:
        return null;
    }
  }

  /// Check if filters are default
  bool get isDefault {
    return view == TripViewMode.list &&
        dateRange == TripDateRange.all &&
        status == TripStatus.all &&
        levelId == null &&
        area == null &&
        ordering == '-start_time';
  }

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (dateRange != TripDateRange.all) count++;
    if (status != TripStatus.all) count++;
    if (levelId != null) count++;
    if (area != null) count++;
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'view': view.name,
      'dateRange': dateRange.name,
      'status': status.name,
      'levelId': levelId,
      'area': area,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'ordering': ordering,
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
  thisMonth,
  custom,
  all,
}

enum TripStatus {
  upcoming,
  ongoing,
  completed,
  all,
}

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
      case TripDateRange.thisMonth:
        return 'This Month';
      case TripDateRange.custom:
        return 'Custom Range';
      case TripDateRange.all:
        return 'All Time';
    }
  }
}

extension TripStatusExtension on TripStatus {
  String get displayName {
    switch (this) {
      case TripStatus.upcoming:
        return 'Upcoming';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.all:
        return 'All';
    }
  }
}
