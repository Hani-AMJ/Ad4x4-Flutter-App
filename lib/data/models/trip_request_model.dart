/// Trip Request Model
/// 
/// Model for member trip requests
class TripRequest {
  final int id;
  final String title;
  final String description;
  final String? suggestedLocation;
  final DateTime? suggestedDate;
  final String requestedBy;
  final String requestedByName;
  final TripRequestStatus status;
  final DateTime createdAt;
  final String? adminNotes;

  TripRequest({
    required this.id,
    required this.title,
    required this.description,
    this.suggestedLocation,
    this.suggestedDate,
    required this.requestedBy,
    required this.requestedByName,
    required this.status,
    required this.createdAt,
    this.adminNotes,
  });

  factory TripRequest.fromJson(Map<String, dynamic> json) {
    return TripRequest(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      suggestedLocation: json['suggested_location'] as String?,
      suggestedDate: json['suggested_date'] != null
          ? DateTime.parse(json['suggested_date'] as String)
          : null,
      requestedBy: json['requested_by'].toString(),
      requestedByName: json['requested_by_name'] as String? ?? 'Unknown Member',
      status: TripRequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      adminNotes: json['admin_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (suggestedLocation != null) 'suggested_location': suggestedLocation,
      if (suggestedDate != null)
        'suggested_date': suggestedDate!.toIso8601String().split('T')[0],
    };
  }

  TripRequest copyWith({
    int? id,
    String? title,
    String? description,
    String? suggestedLocation,
    DateTime? suggestedDate,
    String? requestedBy,
    String? requestedByName,
    TripRequestStatus? status,
    DateTime? createdAt,
    String? adminNotes,
  }) {
    return TripRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestedLocation: suggestedLocation ?? this.suggestedLocation,
      suggestedDate: suggestedDate ?? this.suggestedDate,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}

/// Trip request status
enum TripRequestStatus {
  pending,
  approved,
  declined,
  converted; // Converted to actual trip

  String get displayName {
    switch (this) {
      case TripRequestStatus.pending:
        return 'Pending Review';
      case TripRequestStatus.approved:
        return 'Approved';
      case TripRequestStatus.declined:
        return 'Declined';
      case TripRequestStatus.converted:
        return 'Converted to Trip';
    }
  }

  static TripRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TripRequestStatus.pending;
      case 'approved':
        return TripRequestStatus.approved;
      case 'declined':
        return TripRequestStatus.declined;
      case 'converted':
        return TripRequestStatus.converted;
      default:
        return TripRequestStatus.pending;
    }
  }

  String toApiString() {
    return toString().split('.').last;
  }
}
