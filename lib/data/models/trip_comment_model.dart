import 'trip_model.dart';

/// TripComment - Comment/chat message for a trip
class TripComment {
  final int id;
  final int tripId;
  final BasicMember member;
  final String comment;
  final DateTime created;
  final DateTime? modified;

  TripComment({
    required this.id,
    required this.tripId,
    required this.member,
    required this.comment,
    required this.created,
    this.modified,
  });

  /// Get author's display name
  String get authorName => member.displayName;

  /// Get author's avatar (first letter of name)
  String get authorAvatar {
    final name = authorName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Check if comment was edited
  bool get isEdited => modified != null && modified != created;

  factory TripComment.fromJson(Map<String, dynamic> json) {
    try {
      // Handle member field - can be either integer ID or full object
      BasicMember parsedMember;
      final memberData = json['member'];
      
      if (memberData == null) {
        // Null member - use default
        parsedMember = BasicMember(id: 0, username: 'Unknown');
      } else if (memberData is int) {
        // Member is just an ID (from /api/trips/{id}/comments)
        parsedMember = BasicMember(
          id: memberData,
          username: 'User $memberData',  // Default username
        );
      } else if (memberData is Map<String, dynamic>) {
        // Member is full object (from /api/tripcomments/)
        try {
          parsedMember = BasicMember.fromJson(memberData);
        } catch (memberError) {
          print('⚠️  Error parsing member data: $memberError');
          print('   Member JSON: $memberData');
          parsedMember = BasicMember(id: 0, username: 'Unknown');
        }
      } else {
        // Unexpected type - use default
        print('⚠️  Unexpected member type: ${memberData.runtimeType}');
        parsedMember = BasicMember(id: 0, username: 'Unknown');
      }
      
      // Parse ID with type safety
      int commentId = 0;
      final idData = json['id'];
      if (idData is int) {
        commentId = idData;
      } else if (idData is String) {
        commentId = int.tryParse(idData) ?? 0;
      }
      
      // Parse trip ID with type safety
      int tripIdValue = 0;
      final tripData = json['trip'];
      if (tripData is int) {
        tripIdValue = tripData;
      } else if (tripData is String) {
        tripIdValue = int.tryParse(tripData) ?? 0;
      }
      
      // Parse comment text
      String commentText = '';
      final commentData = json['comment'];
      if (commentData is String) {
        commentText = commentData;
      } else if (commentData != null) {
        commentText = commentData.toString();
      }
      
      return TripComment(
        id: commentId,
        tripId: tripIdValue,
        member: parsedMember,
        comment: commentText,
        created: json['created'] != null
            ? DateTime.parse(json['created'] as String)
            : DateTime.now(),  // Default to now if null
        modified: json['modified'] != null 
            ? DateTime.parse(json['modified'] as String)
            : null,
      );
    } catch (e, stackTrace) {
      print('❌ Fatal error parsing TripComment: $e');
      print('   JSON: $json');
      print('   Stack trace: $stackTrace');
      
      // Return a default comment to prevent app crash
      return TripComment(
        id: 0,
        tripId: 0,
        member: BasicMember(id: 0, username: 'Unknown'),
        comment: 'Error loading message',
        created: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip': tripId,
      'member': member.toJson(),
      'comment': comment,
      'created': created.toIso8601String(),
      if (modified != null) 'modified': modified!.toIso8601String(),
    };
  }
}
