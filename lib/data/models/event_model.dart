class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String type; // 'meeting', 'social', 'training', 'competition'
  final int attendees;
  final int? maxAttendees;
  final String organizer;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final String? imageUrl;
  final List<String> tags;
  final bool isRsvpRequired;
  final bool isRsvped;
  final String? meetingPoint;
  final String? agenda;
  final Map<String, dynamic>? additionalInfo;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.type,
    required this.attendees,
    this.maxAttendees,
    required this.organizer,
    required this.status,
    this.imageUrl,
    this.tags = const [],
    required this.isRsvpRequired,
    this.isRsvped = false,
    this.meetingPoint,
    this.agenda,
    this.additionalInfo,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? type,
    int? attendees,
    int? maxAttendees,
    String? organizer,
    String? status,
    String? imageUrl,
    List<String>? tags,
    bool? isRsvpRequired,
    bool? isRsvped,
    String? meetingPoint,
    String? agenda,
    Map<String, dynamic>? additionalInfo,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      type: type ?? this.type,
      attendees: attendees ?? this.attendees,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      organizer: organizer ?? this.organizer,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isRsvpRequired: isRsvpRequired ?? this.isRsvpRequired,
      isRsvped: isRsvped ?? this.isRsvped,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      agenda: agenda ?? this.agenda,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'type': type,
      'attendees': attendees,
      'maxAttendees': maxAttendees,
      'organizer': organizer,
      'status': status,
      'imageUrl': imageUrl,
      'tags': tags,
      'isRsvpRequired': isRsvpRequired,
      'isRsvped': isRsvped,
      'meetingPoint': meetingPoint,
      'agenda': agenda,
      'additionalInfo': additionalInfo,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      location: json['location'] as String,
      type: json['type'] as String,
      attendees: json['attendees'] as int,
      maxAttendees: json['maxAttendees'] as int?,
      organizer: json['organizer'] as String,
      status: json['status'] as String,
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isRsvpRequired: json['isRsvpRequired'] as bool,
      isRsvped: json['isRsvped'] as bool? ?? false,
      meetingPoint: json['meetingPoint'] as String?,
      agenda: json['agenda'] as String?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }
}
