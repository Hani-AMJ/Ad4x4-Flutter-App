/// Meeting Point Model
/// 
/// Model for trip meeting points (matches API structure)
class MeetingPoint {
  final int id;
  final String name;
  final String? area;       // Make nullable - API can return null
  final String? lat;        // API returns string, not double
  final String? lon;        // API returns string, not double
  final String? link;       // Google Maps link

  MeetingPoint({
    required this.id,
    required this.name,
    this.area,
    this.lat,
    this.lon,
    this.link,
  });

  factory MeetingPoint.fromJson(Map<String, dynamic> json) {
    return MeetingPoint(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Location',
      area: json['area'] as String?,  // Safe nullable casting
      lat: json['lat'] as String?,
      lon: json['lon'] as String?,
      link: json['link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (link != null) 'link': link,
    };
  }

  /// Display string for dropdown: "Name - Area"
  String get displayName => area != null ? '$name - $area' : name;

  MeetingPoint copyWith({
    int? id,
    String? name,
    String? area,
    String? lat,
    String? lon,
    String? link,
  }) {
    return MeetingPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      link: link ?? this.link,
    );
  }
}
