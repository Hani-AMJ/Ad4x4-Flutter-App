/// Time of Day Choice Model
/// 
/// Represents time slot options fetched from backend API
/// Endpoint: GET /api/choices/timeofday
/// 
/// This enables pre-defined time slots for trip scheduling
/// (e.g., Early Morning, Morning, Afternoon, Evening, Night)
class TimeOfDayChoice {
  /// Backend time slot code (e.g., "early_morning", "morning", "afternoon")
  final String value;
  
  /// User-friendly display label
  final String label;
  
  /// Optional detailed description or time range
  final String? description;
  
  /// Sort order for display (lower = appears first)
  final int? order;
  
  /// Whether this time slot is currently active
  final bool active;
  
  /// Optional start hour (24-hour format, e.g., 6 for 6:00 AM)
  final int? startHour;
  
  /// Optional end hour (24-hour format, e.g., 12 for 12:00 PM)
  final int? endHour;
  
  const TimeOfDayChoice({
    required this.value,
    required this.label,
    this.description,
    this.order,
    this.active = true,
    this.startHour,
    this.endHour,
  });
  
  /// Create TimeOfDayChoice from backend JSON response
  factory TimeOfDayChoice.fromJson(Map<String, dynamic> json) {
    return TimeOfDayChoice(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      order: json['order'] as int?,
      active: json['active'] as bool? ?? true,
      startHour: json['start_hour'] as int? ?? json['startHour'] as int?,
      endHour: json['end_hour'] as int? ?? json['endHour'] as int?,
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
      if (startHour != null) 'start_hour': startHour,
      if (endHour != null) 'end_hour': endHour,
    };
  }
  
  /// Get suggested icon based on time of day
  String getIconName() {
    if (startHour != null) {
      if (startHour! < 6) return 'nightlight';
      if (startHour! < 12) return 'wb_sunny';
      if (startHour! < 18) return 'wb_twilight';
      return 'nights_stay';
    }
    
    // Fallback based on value
    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('morning') || lowerValue.contains('dawn')) {
      return 'wb_sunny';
    }
    if (lowerValue.contains('afternoon') || lowerValue.contains('noon')) {
      return 'wb_twilight';
    }
    if (lowerValue.contains('evening') || lowerValue.contains('dusk')) {
      return 'nights_stay';
    }
    if (lowerValue.contains('night')) return 'nightlight';
    
    return 'schedule'; // Default time icon
  }
  
  /// Get suggested color based on time of day
  String getColorHex() {
    if (startHour != null) {
      if (startHour! < 6) return '#3F51B5'; // Indigo - Night
      if (startHour! < 12) return '#FFC107'; // Amber - Morning
      if (startHour! < 18) return '#FF9800'; // Orange - Afternoon
      return '#673AB7'; // Deep Purple - Evening
    }
    
    return '#2196F3'; // Blue - Default
  }
  
  /// Get formatted time range string
  String? getTimeRangeString() {
    if (startHour != null && endHour != null) {
      return '${_formatHour(startHour!)} - ${_formatHour(endHour!)}';
    }
    return description;
  }
  
  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
  
  @override
  String toString() => 'TimeOfDayChoice(value: $value, label: $label)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDayChoice && other.value == value;
  }
  
  @override
  int get hashCode => value.hashCode;
}
