/// Upgrade Request Status Choice Model
/// 
/// Represents upgrade request status options fetched from backend API
/// Endpoint: GET /api/choices/upgraderequeststatus
/// 
/// This model replaces hardcoded string comparisons with dynamic choices
/// from the backend, allowing the workflow to be controlled server-side.
class UpgradeStatusChoice {
  /// Backend status code (e.g., "pending", "approved", "declined")
  final String value;
  
  /// User-friendly display label
  final String label;
  
  /// Optional detailed description
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this status is currently active
  final bool active;
  
  const UpgradeStatusChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
  });
  
  /// Create UpgradeStatusChoice from backend JSON response
  factory UpgradeStatusChoice.fromJson(Map<String, dynamic> json) {
    return UpgradeStatusChoice(
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
  
  /// Common status checks
  bool get isPending => value.toLowerCase() == 'pending';
  bool get isApproved => value.toLowerCase() == 'approved';
  bool get isDeclined => value.toLowerCase() == 'declined';
  
  /// Get color for UI display based on status value
  String getColorHex() {
    if (isApproved) return '#4CAF50'; // Green
    if (isPending) return '#FF9800'; // Orange
    if (isDeclined) return '#F44336'; // Red
    return '#9E9E9E'; // Gray - Unknown
  }
  
  /// Get icon name for UI display based on status value
  String getIconName() {
    if (isApproved) return 'check_circle';
    if (isPending) return 'schedule';
    if (isDeclined) return 'cancel';
    return 'help';
  }
  
  @override
  String toString() => 'UpgradeStatusChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpgradeStatusChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
