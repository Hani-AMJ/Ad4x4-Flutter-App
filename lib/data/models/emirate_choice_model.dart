/// Emirate Choice Model
/// 
/// Represents UAE emirate options fetched from backend API
/// Endpoint: GET /api/choices/emirates
/// 
/// This enables UAE-specific location selection for trips,
/// members, and meeting points.
class EmirateChoice {
  /// Backend emirate code (e.g., "abudhabi", "dubai", "sharjah")
  final String value;
  
  /// User-friendly display label (e.g., "Abu Dhabi", "Dubai")
  final String label;
  
  /// Optional emirate description or notes
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this emirate is currently active
  final bool active;
  
  /// Optional emirate abbreviation (e.g., "AD", "DXB")
  final String? abbreviation;
  
  const EmirateChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.abbreviation,
  });
  
  /// Create EmirateChoice from backend JSON response
  factory EmirateChoice.fromJson(Map<String, dynamic> json) {
    return EmirateChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      abbreviation: json['abbreviation'] as String?,
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
      if (abbreviation != null) 'abbreviation': abbreviation,
    };
  }
  
  @override
  String toString() => 'EmirateChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmirateChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
