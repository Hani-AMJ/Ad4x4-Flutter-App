/// Registration Analytics Models - Advanced registration management and statistics
/// 
/// Models for tracking registration statistics, analytics, export data,
/// and bulk operation requests for trip registration management.

import 'trip_model.dart';

/// RegistrationAnalytics - Comprehensive statistics for trip registrations
class RegistrationAnalytics {
  final int tripId;
  final int totalRegistrations;
  final int confirmedRegistrations;
  final int checkedIn;
  final int checkedOut;
  final int cancelled;
  final int totalWaitlist;
  final int tripCapacity;
  final Map<String, int> registrationsByLevel;  // Level name -> count
  final List<RegistrationTimelinePoint> registrationTimeline;
  final int vehiclesOffered;
  final int totalVehicleCapacity;
  final double checkInRate;  // Percentage
  final double cancellationRate;  // Percentage

  RegistrationAnalytics({
    required this.tripId,
    required this.totalRegistrations,
    required this.confirmedRegistrations,
    required this.checkedIn,
    required this.checkedOut,
    required this.cancelled,
    required this.totalWaitlist,
    required this.tripCapacity,
    required this.registrationsByLevel,
    required this.registrationTimeline,
    required this.vehiclesOffered,
    required this.totalVehicleCapacity,
    required this.checkInRate,
    required this.cancellationRate,
  });

  /// Get available spots
  int get availableSpots => tripCapacity - confirmedRegistrations;

  /// Check if trip is full
  bool get isFull => availableSpots <= 0;

  /// Get fill percentage
  double get fillPercentage => 
      tripCapacity > 0 ? (confirmedRegistrations / tripCapacity) * 100 : 0;

  /// Get pending check-ins (confirmed but not checked in)
  int get pendingCheckIns => confirmedRegistrations - checkedIn;

  factory RegistrationAnalytics.fromJson(Map<String, dynamic> json) {
    return RegistrationAnalytics(
      tripId: json['trip_id'] as int? ?? json['trip'] as int,
      totalRegistrations: json['total_registrations'] as int? ?? 0,
      confirmedRegistrations: json['confirmed_registrations'] as int? ?? 0,
      checkedIn: json['checked_in'] as int? ?? 0,
      checkedOut: json['checked_out'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      totalWaitlist: json['total_waitlist'] as int? ?? 0,
      tripCapacity: json['trip_capacity'] as int? ?? json['capacity'] as int? ?? 0,
      registrationsByLevel: Map<String, int>.from(
        json['registrations_by_level'] as Map<String, dynamic>? ?? {},
      ),
      registrationTimeline: (json['registration_timeline'] as List<dynamic>? ?? [])
          .map((item) => RegistrationTimelinePoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      vehiclesOffered: json['vehicles_offered'] as int? ?? 0,
      totalVehicleCapacity: json['total_vehicle_capacity'] as int? ?? 0,
      checkInRate: (json['check_in_rate'] as num? ?? 0).toDouble(),
      cancellationRate: (json['cancellation_rate'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'total_registrations': totalRegistrations,
      'confirmed_registrations': confirmedRegistrations,
      'checked_in': checkedIn,
      'checked_out': checkedOut,
      'cancelled': cancelled,
      'total_waitlist': totalWaitlist,
      'trip_capacity': tripCapacity,
      'registrations_by_level': registrationsByLevel,
      'registration_timeline': registrationTimeline.map((p) => p.toJson()).toList(),
      'vehicles_offered': vehiclesOffered,
      'total_vehicle_capacity': totalVehicleCapacity,
      'check_in_rate': checkInRate,
      'cancellation_rate': cancellationRate,
    };
  }
}

/// RegistrationTimelinePoint - Point in registration timeline
class RegistrationTimelinePoint {
  final DateTime date;
  final int count;

  RegistrationTimelinePoint({
    required this.date,
    required this.count,
  });

  factory RegistrationTimelinePoint.fromJson(Map<String, dynamic> json) {
    return RegistrationTimelinePoint(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'count': count,
    };
  }
}

/// BulkRegistrationRequest - Request for bulk registration operations
class BulkRegistrationRequest {
  final List<int> registrationIds;
  final BulkAction action;
  final String? reason;  // For reject operations

  BulkRegistrationRequest({
    required this.registrationIds,
    required this.action,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'registration_ids': registrationIds,
      'action': action.name,
      if (reason != null) 'reason': reason,
    };
  }
}

/// BulkAction - Type of bulk operation
enum BulkAction {
  approve,
  reject,
  checkin,
  checkout,
  cancel,
  notify,
}

/// RegistrationExportRequest - Request to export registration data
class RegistrationExportRequest {
  final int tripId;
  final ExportFormat format;
  final List<String>? fields;  // Optional: specific fields to export
  final List<String>? statuses;  // Optional: filter by status

  RegistrationExportRequest({
    required this.tripId,
    required this.format,
    this.fields,
    this.statuses,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'format': format.name,
      if (fields != null) 'fields': fields,
      if (statuses != null) 'statuses': statuses,
    };
  }
}

/// ExportFormat - Format for registration export
enum ExportFormat {
  csv,
  pdf,
  excel,
}

/// RegistrationExportResponse - Response from export request
class RegistrationExportResponse {
  final String downloadUrl;
  final String filename;
  final int fileSize;
  final DateTime expiresAt;

  RegistrationExportResponse({
    required this.downloadUrl,
    required this.filename,
    required this.fileSize,
    required this.expiresAt,
  });

  factory RegistrationExportResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationExportResponse(
      downloadUrl: json['download_url'] as String,
      filename: json['filename'] as String,
      fileSize: json['file_size'] as int,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'download_url': downloadUrl,
      'filename': filename,
      'file_size': fileSize,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// NotificationRequest - Request to send notification to registrants
class NotificationRequest {
  final int tripId;
  final String message;
  final List<int>? memberIds;  // Optional: specific members (null = all)
  final NotificationType type;
  final bool pushNotification;
  final bool emailNotification;

  NotificationRequest({
    required this.tripId,
    required this.message,
    this.memberIds,
    required this.type,
    this.pushNotification = true,
    this.emailNotification = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'message': message,
      if (memberIds != null) 'member_ids': memberIds,
      'type': type.name,
      'push_notification': pushNotification,
      'email_notification': emailNotification,
    };
  }
}

/// NotificationType - Type of notification
enum NotificationType {
  general,
  tripUpdate,
  cancellation,
  reminder,
  waitlistUpdate,
}

/// WaitlistManagementRequest - Request for waitlist operations
class WaitlistManagementRequest {
  final int tripId;
  final List<int> memberIds;
  final WaitlistAction action;
  final bool notifyMembers;

  WaitlistManagementRequest({
    required this.tripId,
    required this.memberIds,
    required this.action,
    this.notifyMembers = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'member_ids': memberIds,
      'action': action.name,
      'notify_members': notifyMembers,
    };
  }
}

/// WaitlistAction - Type of waitlist operation
enum WaitlistAction {
  moveToRegistered,
  remove,
  reorder,
}

/// WaitlistPosition - Updated position in waitlist
class WaitlistPosition {
  final int memberId;
  final int oldPosition;
  final int newPosition;

  WaitlistPosition({
    required this.memberId,
    required this.oldPosition,
    required this.newPosition,
  });

  factory WaitlistPosition.fromJson(Map<String, dynamic> json) {
    return WaitlistPosition(
      memberId: json['member_id'] as int,
      oldPosition: json['old_position'] as int,
      newPosition: json['new_position'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'old_position': oldPosition,
      'new_position': newPosition,
    };
  }
}

/// Extended TripRegistration with additional analytics fields
class TripRegistrationWithAnalytics {
  final TripRegistration registration;
  final int daysUntilTrip;
  final bool hasUploadedPhotos;
  final int tripCount;  // Member's total trips
  final String? emergencyContact;

  TripRegistrationWithAnalytics({
    required this.registration,
    required this.daysUntilTrip,
    required this.hasUploadedPhotos,
    required this.tripCount,
    this.emergencyContact,
  });

  factory TripRegistrationWithAnalytics.fromJson(Map<String, dynamic> json) {
    return TripRegistrationWithAnalytics(
      registration: TripRegistration.fromJson(json['registration'] as Map<String, dynamic>? ?? json),
      daysUntilTrip: json['days_until_trip'] as int? ?? 0,
      hasUploadedPhotos: json['has_uploaded_photos'] as bool? ?? false,
      tripCount: json['trip_count'] as int? ?? 0,
      emergencyContact: json['emergency_contact'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registration': registration.toJson(),
      'days_until_trip': daysUntilTrip,
      'has_uploaded_photos': hasUploadedPhotos,
      'trip_count': tripCount,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
    };
  }
}
