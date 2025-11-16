/// Here Maps Settings Model
/// 
/// Configuration for Here Maps reverse geocoding integration
class HereMapsSettings {
  final String apiKey;
  final List<HereMapsDisplayField> selectedFields;
  final bool enableReverseGeocode;

  static const int maxFields = 2;
  static const String defaultApiKey = 'tLzdVrbRbvWpl_8Em4JbjHxzFMIvIRyMo9xyKn7fBW8';

  const HereMapsSettings({
    required this.apiKey,
    required this.selectedFields,
    this.enableReverseGeocode = true,
  });

  /// Default settings with district field selected
  factory HereMapsSettings.defaultSettings() {
    return const HereMapsSettings(
      apiKey: defaultApiKey,
      selectedFields: [HereMapsDisplayField.district],
      enableReverseGeocode: true,
    );
  }

  HereMapsSettings copyWith({
    String? apiKey,
    List<HereMapsDisplayField>? selectedFields,
    bool? enableReverseGeocode,
  }) {
    return HereMapsSettings(
      apiKey: apiKey ?? this.apiKey,
      selectedFields: selectedFields ?? this.selectedFields,
      enableReverseGeocode: enableReverseGeocode ?? this.enableReverseGeocode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'selectedFields': selectedFields.map((f) => f.name).toList(),
      'enableReverseGeocode': enableReverseGeocode,
    };
  }

  factory HereMapsSettings.fromJson(Map<String, dynamic> json) {
    return HereMapsSettings(
      apiKey: json['apiKey'] as String? ?? defaultApiKey,
      selectedFields: (json['selectedFields'] as List<dynamic>?)
              ?.map((name) => HereMapsDisplayField.values.firstWhere(
                    (f) => f.name == name,
                    orElse: () => HereMapsDisplayField.district,
                  ))
              .toList() ??
          [HereMapsDisplayField.district],
      enableReverseGeocode: json['enableReverseGeocode'] as bool? ?? true,
    );
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
