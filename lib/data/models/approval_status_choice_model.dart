/// Approval Status Choice Model
/// 
/// Represents approval status options fetched from backend API
/// Endpoint: GET /api/choices/approvalstatus
/// 
/// This model replaces hardcoded ApprovalStatus enum with dynamic choices
/// from the backend, allowing the workflow to be controlled server-side.
class ApprovalStatusChoice {
  /// Backend status code (e.g., "A", "P", "D")
  final String value;
  
  /// User-friendly display label (e.g., "Approved", "Pending", "Declined")
  final String label;
  
  /// Optional detailed description
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this status is currently active
  final bool active;
  
  const ApprovalStatusChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
  });
  
  /// Create ApprovalStatusChoice from backend JSON response
  factory ApprovalStatusChoice.fromJson(Map<String, dynamic> json) {
    return ApprovalStatusChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
    );
  }
  
  /// Convert to JSON for API requests (if needed)
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      if (description != null) 'description': description,
      if (order != null) 'order': order,
      'active': active,
    };
  }
  
  /// Get color for UI display based on status value
  /// This provides consistent color coding across the app
  static String getColorHex(String value) {
    switch (value.toUpperCase()) {
      case 'A':
        return '#4CAF50'; // Green - Approved
      case 'P':
        return '#FF9800'; // Orange - Pending
      case 'D':
        return '#F44336'; // Red - Declined
      default:
        return '#9E9E9E'; // Gray - Unknown
    }
  }
  
  /// Get icon name for UI display based on status value
  static String getIconName(String value) {
    switch (value.toUpperCase()) {
      case 'A':
        return 'check_circle';
      case 'P':
        return 'schedule';
      case 'D':
        return 'cancel';
      default:
        return 'help';
    }
  }
  
  @override
  String toString() => 'ApprovalStatusChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalStatusChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
