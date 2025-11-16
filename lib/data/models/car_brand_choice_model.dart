/// Car Brand Choice Model
/// 
/// Represents vehicle brand options fetched from backend API
/// Endpoint: GET /api/choices/carbrand
/// 
/// This enables structured vehicle brand selection for member profiles
/// and vehicle management features.
class CarBrandChoice {
  /// Backend brand code (e.g., "toyota", "nissan", "landcruiser")
  final String value;
  
  /// User-friendly display label (e.g., "Toyota", "Nissan Patrol")
  final String label;
  
  /// Optional brand description or notes
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this brand is currently active
  final bool active;
  
  /// Optional brand logo URL
  final String? logoUrl;
  
  /// Optional brand category (e.g., "4x4", "SUV", "Truck")
  final String? category;
  
  const CarBrandChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.logoUrl,
    this.category,
  });
  
  /// Create CarBrandChoice from backend JSON response
  factory CarBrandChoice.fromJson(Map<String, dynamic> json) {
    return CarBrandChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      category: json['category'] as String?,
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
      if (logoUrl != null) 'logo_url': logoUrl,
      if (category != null) 'category': category,
    };
  }
  
  @override
  String toString() => 'CarBrandChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarBrandChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
