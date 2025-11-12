/// Level Model
/// 
/// Model for trip difficulty levels
class Level {
  final int id;
  final String name;
  final int numericLevel;
  final bool active;
  final String? description;
  final String? modifications;

  Level({
    required this.id,
    required this.name,
    required this.numericLevel,
    this.active = true,
    this.description,
    this.modifications,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? 'Unknown',
      numericLevel: json['numeric_level'] as int? ?? json['numericLevel'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      description: json['description'] as String?,
      modifications: json['modifications'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numericLevel': numericLevel,
      'active': active,
      if (description != null) 'description': description,
      if (modifications != null) 'modifications': modifications,
    };
  }

  /// Display string for dropdown: "Level X - Name"
  String get displayName => 'Level $numericLevel - $name';

  /// Short display for chips: "L X"
  String get shortName => 'L$numericLevel';

  Level copyWith({
    int? id,
    String? name,
    int? numericLevel,
    bool? active,
    String? description,
    String? modifications,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      numericLevel: numericLevel ?? this.numericLevel,
      active: active ?? this.active,
      description: description ?? this.description,
      modifications: modifications ?? this.modifications,
    );
  }
}
