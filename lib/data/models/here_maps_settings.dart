/// Here Maps Settings Model
/// 
/// Configuration for Here Maps reverse geocoding integration
/// ✅ MIGRATED TO BACKEND-DRIVEN ARCHITECTURE
/// - API key now secured on backend (not exposed in Flutter)
/// - Configuration loaded from Django Admin panel
/// - Auto-refresh every 15 minutes
class HereMapsSettings {
  final bool enabled;  // Backend: hereMapsEnabled
  final int maxFields;  // Backend: hereMapsMaxFields
  final List<String> availableFields;  // Backend: hereMapsAvailableFields
  final List<HereMapsDisplayField> selectedFields;  // Backend: hereMapsSelectedFields

  const HereMapsSettings({
    required this.enabled,
    required this.maxFields,
    required this.availableFields,
    required this.selectedFields,
  });

  /// Default settings (used as fallback if backend unavailable)
  factory HereMapsSettings.defaultSettings() {
    return const HereMapsSettings(
      enabled: true,
      maxFields: 2,
      availableFields: [
        'Place Name',
        'District',
        'City',
        'County',
        'Country',
        'Postal Code',
        'Full Address',
        'Category',
      ],
      selectedFields: [HereMapsDisplayField.city, HereMapsDisplayField.district],
    );
  }

  HereMapsSettings copyWith({
    bool? enabled,
    int? maxFields,
    List<String>? availableFields,
    List<HereMapsDisplayField>? selectedFields,
  }) {
    return HereMapsSettings(
      enabled: enabled ?? this.enabled,
      maxFields: maxFields ?? this.maxFields,
      availableFields: availableFields ?? this.availableFields,
      selectedFields: selectedFields ?? this.selectedFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'maxFields': maxFields,
      'availableFields': availableFields,
      'selectedFields': selectedFields.map((f) => f.displayName).toList(),
    };
  }

  /// Parse backend configuration response
  /// Backend field names: hereMapsEnabled, hereMapsSelectedFields, hereMapsMaxFields, hereMapsAvailableFields
  factory HereMapsSettings.fromJson(Map<String, dynamic> json) {
    return HereMapsSettings(
      enabled: json['hereMapsEnabled'] as bool? ?? true,
      maxFields: json['hereMapsMaxFields'] as int? ?? 2,
      availableFields: (json['hereMapsAvailableFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [
            'Place Name',
            'District',
            'City',
            'County',
            'Country',
            'Postal Code',
            'Full Address',
            'Category',
          ],
      selectedFields: _parseSelectedFields(json['hereMapsSelectedFields']),
    );
  }

  /// Convert backend field names to Flutter enum
  /// Backend returns: ["city", "district"]
  /// Flutter needs: [HereMapsDisplayField.city, HereMapsDisplayField.district]
  static List<HereMapsDisplayField> _parseSelectedFields(dynamic fields) {
    if (fields == null) {
      return [HereMapsDisplayField.city, HereMapsDisplayField.district];
    }

    final fieldList = fields is List ? fields : [];
    return fieldList.map((field) {
      final fieldStr = field.toString().toLowerCase().trim();
      switch (fieldStr) {
        case 'city':
          return HereMapsDisplayField.city;
        case 'district':
          return HereMapsDisplayField.district;
        case 'place name':
        case 'title':
          return HereMapsDisplayField.title;
        case 'county':
          return HereMapsDisplayField.county;
        case 'country':
          return HereMapsDisplayField.countryName;
        case 'postal code':
          return HereMapsDisplayField.postalCode;
        case 'full address':
        case 'label':
          return HereMapsDisplayField.label;
        case 'category':
          return HereMapsDisplayField.categoryName;
        default:
          return HereMapsDisplayField.city;  // Fallback
      }
    }).toList();
  }
}

/// Available display fields from Here Maps reverse geocoding response
enum HereMapsDisplayField {
  title('Place Name', 'title'),
  district('District', 'district'),
  city('City', 'city'),
  county('County', 'county'),
  countryName('Country', 'countryName'),
  postalCode('Postal Code', 'postalCode'),
  label('Full Address', 'label'),
  categoryName('Category', 'categoryName');

  final String displayName;
  final String jsonKey;

  const HereMapsDisplayField(this.displayName, this.jsonKey);
}
