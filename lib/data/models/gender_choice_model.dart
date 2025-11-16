/// Gender Choice Model
/// 
/// Represents gender options fetched from backend API
/// Endpoint: GET /api/choices/gender
/// 
/// This enables inclusive gender selection for member demographics
/// with backend-controlled options.
class GenderChoice {
  /// Backend gender code (e.g., "male", "female", "other", "prefer_not_say")
  final String value;
  
  /// User-friendly display label
  final String label;
  
  /// Optional description or notes
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this gender option is currently active
  final bool active;
  
  const GenderChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
  });
  
  /// Create GenderChoice from backend JSON response
  factory GenderChoice.fromJson(Map<String, dynamic> json) {
    return GenderChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
    );
  }
  
  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      if (description != null) 'description': description,
      if (order != null) 'order': order,
      'active': active,
    };
  }
  
  @override
  String toString() => 'GenderChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenderChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
