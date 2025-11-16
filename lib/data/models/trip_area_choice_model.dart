/// Trip Area Choice Model
/// 
/// Represents a trip area option from the backend API.
/// Example areas: desert, mountain, wadi, beach, mixed
class TripAreaChoice {
  final String value;
  final String label;
  final String? description;
  final int? order;
  final bool active;
  final String? icon;
  final String? color;

  const TripAreaChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.icon,
    this.color,
  });

  factory TripAreaChoice.fromJson(Map<String, dynamic> json) {
    return TripAreaChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      if (description != null) 'description': description,
      if (order != null) 'order': order,
      'active': active,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
    };
  }

  @override
  String toString() => 'TripAreaChoice(value: $value, label: $label, order: $order)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAreaChoice &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
