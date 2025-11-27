/// Geocoding Result Model
/// 
/// Structured response from HERE Maps reverse geocoding API
/// Contains detailed location information for smart area code detection
class GeocodingResult {
  /// Full formatted address (e.g., "Dubai, Al Barsha")
  final String area;
  
  /// City name (e.g., "Dubai", "Abu Dhabi")
  final String city;
  
  /// District/neighborhood name (e.g., "Al Barsha", "Al Karamah")
  final String district;
  
  /// Whether this result came from backend cache
  final bool cached;

  const GeocodingResult({
    required this.area,
    required this.city,
    required this.district,
    this.cached = false,
  });

  /// Parse from backend API response
  /// 
  /// Expected response format:
  /// ```json
  /// {
  ///   "success": true,
  ///   "area": "Dubai, Al Barsha",
  ///   "city": "Dubai",
  ///   "district": "Al Barsha",
  ///   "cached": false
  /// }
  /// ```
  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      cached: json['cached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'city': city,
      'district': district,
      'cached': cached,
    };
  }

  /// Empty result for error cases
  factory GeocodingResult.empty() {
    return const GeocodingResult(
      area: '',
      city: '',
      district: '',
      cached: false,
    );
  }

  /// Check if result has valid data
  bool get isValid => area.isNotEmpty || city.isNotEmpty || district.isNotEmpty;

  @override
  String toString() {
    return 'GeocodingResult(area: $area, city: $city, district: $district, cached: $cached)';
  }
}
