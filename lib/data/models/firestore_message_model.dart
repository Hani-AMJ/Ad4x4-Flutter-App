import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Message Model for real-time chat
/// 
/// This model represents a chat message stored in Firestore.
/// It supports real-time updates and is optimized for the Firestore data structure.
class FirestoreMessage {
  final String id;
  final int tripId;
  final int authorId;
  final String authorName;
  final String authorUsername;
  final String? authorAvatar;
  final String text;
  final DateTime timestamp;
  final bool edited;
  final DateTime? editedAt;
  final bool deleted;
  final DateTime? deletedAt;
  final Map<String, int>? reactions;

  const FirestoreMessage({
    required this.id,
    required this.tripId,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatar,
    required this.text,
    required this.timestamp,
    this.edited = false,
    this.editedAt,
    this.deleted = false,
    this.deletedAt,
    this.reactions,
  });

  /// Get author's display name
  String get displayName => authorName.isNotEmpty ? authorName : authorUsername;

  /// Get author's avatar (first letter of name)
  String get avatarInitial {
    final name = displayName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Check if message was edited
  bool get isEdited => edited && editedAt != null;

  /// Check if message is deleted
  bool get isDeleted => deleted;

  /// Create from Firestore DocumentSnapshot
  factory FirestoreMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirestoreMessage(
      id: doc.id,
      tripId: data['tripId'] as int? ?? 0,
      authorId: data['authorId'] as int? ?? 0,
      authorName: data['authorName'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      authorAvatar: data['authorAvatar'] as String?,
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      edited: data['edited'] as bool? ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      reactions: data['reactions'] != null 
          ? Map<String, int>.from(data['reactions'] as Map)
          : null,
    );
  }

  /// Create from Firestore QueryDocumentSnapshot
  factory FirestoreMessage.fromQuerySnapshot(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirestoreMessage(
      id: doc.id,
      tripId: data['tripId'] as int? ?? 0,
      authorId: data['authorId'] as int? ?? 0,
      authorName: data['authorName'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      authorAvatar: data['authorAvatar'] as String?,
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      edited: data['edited'] as bool? ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      reactions: data['reactions'] != null 
          ? Map<String, int>.from(data['reactions'] as Map)
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'authorId': authorId,
      'authorName': authorName,
      'authorUsername': authorUsername,
      if (authorAvatar != null) 'authorAvatar': authorAvatar,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'edited': edited,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      'deleted': deleted,
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      if (reactions != null) 'reactions': reactions,
    };
  }

  /// Create a copy with modified fields
  FirestoreMessage copyWith({
    String? id,
    int? tripId,
    int? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? text,
    DateTime? timestamp,
    bool? edited,
    DateTime? editedAt,
    bool? deleted,
    DateTime? deletedAt,
    Map<String, int>? reactions,
  }) {
    return FirestoreMessage(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  String toString() {
    return 'FirestoreMessage(id: $id, tripId: $tripId, author: $authorName, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FirestoreMessage &&
      other.id == id &&
      other.tripId == tripId &&
      other.authorId == authorId &&
      other.text == text &&
      other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tripId,
      authorId,
      text,
      timestamp,
    );
  }
}
