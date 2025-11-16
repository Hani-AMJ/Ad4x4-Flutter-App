/// Trip Request Area Choice Model
/// 
/// Represents trip request area/category options fetched from backend API
/// Endpoint: GET /api/choices/triprequestarea
/// 
/// This enables categorization of trip requests by geographic area or terrain type
/// (e.g., Desert, Mountain, Beach, Wadi, etc.)
class TripRequestAreaChoice {
  /// Backend area code (e.g., "desert", "mountain", "beach", "wadi")
  final String value;
  
  /// User-friendly display label
  final String label;
  
  /// Optional detailed description
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this area option is currently active
  final bool active;
  
  /// Optional icon identifier for UI display
  final String? icon;
  
  const TripRequestAreaChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.icon,
  });
  
  /// Create TripRequestAreaChoice from backend JSON response
  factory TripRequestAreaChoice.fromJson(Map<String, dynamic> json) {
    return TripRequestAreaChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      icon: json['icon'] as String?,
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
      if (icon != null) 'icon': icon,
    };
  }
  
  /// Get suggested icon based on area type
  String getIconName() {
    if (icon != null) return icon!;
    
    // Fallback icon suggestions based on common area names
    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('desert')) return 'wb_sunny';
    if (lowerValue.contains('mountain')) return 'terrain';
    if (lowerValue.contains('beach')) return 'beach_access';
    if (lowerValue.contains('wadi')) return 'water';
    if (lowerValue.contains('dune')) return 'landscape';
    if (lowerValue.contains('rock')) return 'landscape';
    return 'place'; // Default location icon
  }
  
  /// Get suggested color based on area type
  String getColorHex() {
    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('desert')) return '#FF9800'; // Orange
    if (lowerValue.contains('mountain')) return '#795548'; // Brown
    if (lowerValue.contains('beach')) return '#03A9F4'; // Light Blue
    if (lowerValue.contains('wadi')) return '#00BCD4'; // Cyan
    if (lowerValue.contains('dune')) return '#FFC107'; // Amber
    if (lowerValue.contains('rock')) return '#9E9E9E'; // Gray
    return '#4CAF50'; // Green - Default
  }
  
  @override
  String toString() => 'TripRequestAreaChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripRequestAreaChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
