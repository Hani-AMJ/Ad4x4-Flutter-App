/// Feedback model for user feedback submissions and history
/// 
/// Corresponds to backend API endpoint: POST /api/feedback/
/// and GET /api/members/{id}/feedback
class Feedback {
  final int? id;
  final String feedbackType;
  final String message;
  final String? image;
  final String? status;
  final DateTime? created;
  final DateTime? updated;
  final int? memberId;
  final String? memberName;
  final String? adminResponse;
  final DateTime? respondedAt;

  const Feedback({
    this.id,
    required this.feedbackType,
    required this.message,
    this.image,
    this.status,
    this.created,
    this.updated,
    this.memberId,
    this.memberName,
    this.adminResponse,
    this.respondedAt,
  });

  /// Create Feedback from JSON response
  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as int?,
      feedbackType: json['feedbackType'] as String? ?? json['feedback_type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      image: json['image'] as String?,
      status: json['status'] as String?,
      created: json['created'] != null 
          ? DateTime.parse(json['created'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      memberId: json['member_id'] as int? ?? json['memberId'] as int?,
      memberName: json['member_name'] as String? ?? json['memberName'] as String?,
      adminResponse: json['admin_response'] as String? ?? json['adminResponse'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : json['respondedAt'] != null
              ? DateTime.parse(json['respondedAt'] as String)
              : null,
    );
  }

  /// Convert Feedback to JSON for submission
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'feedbackType': feedbackType,
      'message': message,
      if (image != null) 'image': image,
      if (status != null) 'status': status,
      if (created != null) 'created': created!.toIso8601String(),
      if (updated != null) 'updated': updated!.toIso8601String(),
      if (memberId != null) 'member_id': memberId,
      if (memberName != null) 'member_name': memberName,
      if (adminResponse != null) 'admin_response': adminResponse,
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Feedback copyWith({
    int? id,
    String? feedbackType,
    String? message,
    String? image,
    String? status,
    DateTime? created,
    DateTime? updated,
    int? memberId,
    String? memberName,
    String? adminResponse,
    DateTime? respondedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      feedbackType: feedbackType ?? this.feedbackType,
      message: message ?? this.message,
      image: image ?? this.image,
      status: status ?? this.status,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// Feedback type enum matching backend FeedbackTypeEnum
/// ✅ VERIFIED: Backend API testing (January 19, 2025)
/// Backend expects LOWERCASE values: bug, feature, general, support
class FeedbackType {
  static const String bug = 'bug';              // 🐛 Bug Report
  static const String feature = 'feature';      // ✨ Feature Request
  static const String general = 'general';      // 📝 General Feedback
  static const String support = 'support';      // 💬 Help/Support

  /// Get all feedback types for dropdown/selection
  /// ⚠️ ONLY includes types that backend actually accepts
  static List<String> get all => [
    bug,
    feature,
    general,
    support,
  ];

  /// Get user-friendly label for feedback type
  /// ✅ Labels match Django admin interface
  static String getLabel(String type) {
    switch (type) {
      case bug:
        return '🐛 Bug Report';
      case feature:
        return '✨ Feature Request';
      case general:
        return '📝 General Feedback';
      case support:
        return '💬 Help/Support';
      default:
        return type;
    }
  }

  /// Get icon for feedback type
  /// ✅ Icons match the feedback types
  static String getIcon(String type) {
    switch (type) {
      case bug:
        return '🐛';
      case feature:
        return '✨';
      case general:
        return '📝';
      case support:
        return '💬';
      default:
        return '📝';
    }
  }
}

/// Feedback status enum
class FeedbackStatus {
  static const String submitted = 'SUBMITTED';
  static const String inReview = 'IN_REVIEW';
  static const String resolved = 'RESOLVED';
  static const String closed = 'CLOSED';

  /// Get user-friendly label for status
  static String getLabel(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case inReview:
        return 'In Review';
      case resolved:
        return 'Resolved';
      case closed:
        return 'Closed';
      default:
        return status;
    }
  }
}
