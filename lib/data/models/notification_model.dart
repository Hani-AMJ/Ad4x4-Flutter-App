class NotificationModel {
  final int id; // ✅ FIXED: API returns integer ID
  final String title;
  final String body; // ✅ FIXED: API uses 'body' not 'message'
  final String type; // e.g., 'NEW_TRIP', 'TRIP_UPDATE', 'MEMBER_REQUEST'
  final DateTime timestamp;
  final int? relatedObjectId; // ✅ ADDED: Related object ID from API
  final String? relatedObjectType; // ✅ ADDED: Related object type (Trip, Event, etc.)
  
  // Client-side fields (not from API)
  final bool isRead;
  final String? imageUrl;
  
  // Legacy fields (kept for backward compatibility)
  @Deprecated('Use body instead')
  String get message => body;
  
  @Deprecated('Use relatedObjectType/relatedObjectId instead')
  final String? actionType;
  
  @Deprecated('Use relatedObjectId instead')
  final String? actionId;
  
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.relatedObjectId,
    this.relatedObjectType,
    this.isRead = false,
    this.imageUrl,
    this.actionType,
    this.actionId,
    this.metadata,
  });

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    int? relatedObjectId,
    String? relatedObjectType,
    bool? isRead,
    String? imageUrl,
    String? actionType,
    String? actionId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      relatedObjectId: relatedObjectId ?? this.relatedObjectId,
      relatedObjectType: relatedObjectType ?? this.relatedObjectType,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      if (relatedObjectId != null) 'relatedObjectId': relatedObjectId,
      if (relatedObjectType != null) 'relatedObjectType': relatedObjectType,
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionId': actionId,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0, // ✅ FIXED: Handle integer ID
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '', // ✅ FIXED: Use 'body' field from API
      type: json['type'] as String? ?? 'SYSTEM',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      relatedObjectId: json['relatedObjectId'] as int?, // ✅ NEW: Related object ID
      relatedObjectType: json['relatedObjectType'] as String?, // ✅ NEW: Related object type
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      actionType: json['actionType'] as String?,
      actionId: json['actionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// Helper to get navigation target based on relatedObjectType
  String? get navigationRoute {
    if (relatedObjectType == null || relatedObjectId == null) return null;
    
    switch (relatedObjectType?.toLowerCase()) {
      case 'trip':
        return '/trips/$relatedObjectId';
      case 'event':
        return '/events/$relatedObjectId';
      case 'member':
        return '/members/$relatedObjectId';
      case 'upgrade_request':
        return '/upgrade-requests/$relatedObjectId';
      default:
        return null;
    }
  }
}
