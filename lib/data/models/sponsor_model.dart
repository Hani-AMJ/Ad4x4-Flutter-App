/// Sponsor model for club sponsors/partners
/// 
/// Represents a sponsorship entity with logo, description, and priority ordering
class Sponsor {
  final int id;
  final String title;
  final String description;
  final int priority;
  final String image;

  const Sponsor({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.image,
  });

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as int,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'image': image,
    };
  }

  @override
  String toString() {
    return 'Sponsor(id: $id, title: $title, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sponsor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
