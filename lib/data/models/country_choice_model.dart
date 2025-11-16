/// Country Choice Model
/// 
/// Represents country options fetched from backend API
/// Endpoint: GET /api/choices/countries
/// 
/// This enables standardized country selection for member profiles,
/// trip destinations, and international expansion.
class CountryChoice {
  /// Backend country code (e.g., "AE", "SA", "OM" - ISO 3166-1 alpha-2)
  final String value;
  
  /// User-friendly display label (e.g., "United Arab Emirates")
  final String label;
  
  /// Optional country description or notes
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this country is currently active
  final bool active;
  
  /// Optional flag emoji or icon code
  final String? flagEmoji;
  
  /// Optional country calling code (e.g., "+971")
  final String? callingCode;
  
  const CountryChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.flagEmoji,
    this.callingCode,
  });
  
  /// Create CountryChoice from backend JSON response
  factory CountryChoice.fromJson(Map<String, dynamic> json) {
    return CountryChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      flagEmoji: json['flag_emoji'] as String? ?? json['flagEmoji'] as String?,
      callingCode: json['calling_code'] as String? ?? json['callingCode'] as String?,
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
      if (flagEmoji != null) 'flag_emoji': flagEmoji,
      if (callingCode != null) 'calling_code': callingCode,
    };
  }
  
  @override
  String toString() => 'CountryChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
