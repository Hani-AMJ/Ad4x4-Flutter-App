import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/firestore_message_model.dart';

/// Firestore Service for Real-Time Chat
/// 
/// This service manages real-time messaging using Firestore.
/// It requires Firebase Authentication to be configured first.
/// 
/// **SETUP REQUIREMENTS**:
/// 1. Firebase Auth must be initialized
/// 2. User must be authenticated with Firebase custom token
/// 3. Firestore security rules must allow authenticated access
/// 
/// **COLLECTION STRUCTURE**:
/// - trips/{tripId}/messages/{messageId}
/// 
/// **SECURITY RULES EXAMPLE**:
/// ```
/// rules_version = '2';
/// service cloud.firestore {
///   match /databases/{database}/documents {
///     match /trips/{tripId}/messages/{messageId} {
///       allow read: if request.auth != null;
///       allow create: if request.auth != null 
///                     && request.resource.data.authorId == int(request.auth.uid);
///       allow update, delete: if request.auth != null 
///                             && resource.data.authorId == int(request.auth.uid);
///     }
///   }
/// }
/// ```
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();
  
  /// Get messages collection reference for a specific trip
  CollectionReference<Map<String, dynamic>> _getMessagesCollection(int tripId) {
    return _firestore.collection('trips').doc(tripId.toString()).collection('messages');
  }
  
  /// Stream of real-time messages for a trip
  /// 
  /// Returns a stream of messages ordered by timestamp (newest first).
  /// Automatically updates when new messages are added or existing ones are modified.
  /// 
  /// **Usage**:
  /// ```dart
  /// StreamBuilder<List<FirestoreMessage>>(
  ///   stream: FirestoreService().getMessagesStream(tripId: 123),
  ///   builder: (context, snapshot) {
  ///     if (snapshot.hasError) return Text('Error: ${snapshot.error}');
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     
  ///     final messages = snapshot.data!;
  ///     return ListView.builder(
  ///       itemCount: messages.length,
  ///       itemBuilder: (context, index) => MessageTile(messages[index]),
  ///     );
  ///   },
  /// )
  /// ```
  Stream<List<FirestoreMessage>> getMessagesStream({
    required int tripId,
    int limit = 50,
  }) {
    try {
      return _getMessagesCollection(tripId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => FirestoreMessage.fromQuerySnapshot(doc))
                .toList();
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error getting messages stream: $e');
      }
      // Return empty stream on error
      return Stream.value([]);
    }
  }
  
  /// Send a new message to a trip chat
  /// 
  /// **Parameters**:
  /// - `tripId`: The trip ID
  /// - `authorId`: The author's user ID
  /// - `authorName`: The author's display name
  /// - `authorUsername`: The author's username
  /// - `authorAvatar`: The author's avatar URL (optional)
  /// - `text`: The message text
  /// 
  /// **Returns**: The message ID if successful, null if failed
  /// 
  /// **Usage**:
  /// ```dart
  /// final messageId = await FirestoreService().sendMessage(
  ///   tripId: 123,
  ///   authorId: 456,
  ///   authorName: 'Hani Amj',
  ///   authorUsername: 'HaniAMJ',
  ///   text: 'Looking forward to this trip!',
  /// );
  /// ```
  Future<String?> sendMessage({
    required int tripId,
    required int authorId,
    required String authorName,
    required String authorUsername,
    String? authorAvatar,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ [FirestoreService] Cannot send empty message');
        }
        return null;
      }
      
      final docRef = await _getMessagesCollection(tripId).add({
        'tripId': tripId,
        'authorId': authorId,
        'authorName': authorName,
        'authorUsername': authorUsername,
        if (authorAvatar != null) 'authorAvatar': authorAvatar,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
        'deleted': false,
      });
      
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Message sent: ${docRef.id}');
      }
      
      return docRef.id;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error sending message: $e');
      }
      rethrow;
    }
  }
  
  /// Edit an existing message
  /// 
  /// **Returns**: true if successful, false if failed
  Future<bool> editMessage({
    required int tripId,
    required String messageId,
    required String newText,
  }) async {
    try {
      if (newText.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ [FirestoreService] Cannot edit message to empty text');
        }
        return false;
      }
      
      await _getMessagesCollection(tripId).doc(messageId).update({
        'text': newText.trim(),
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Message edited: $messageId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error editing message: $e');
      }
      return false;
    }
  }
  
  /// Delete a message (soft delete)
  /// 
  /// **Returns**: true if successful, false if failed
  Future<bool> deleteMessage({
    required int tripId,
    required String messageId,
  }) async {
    try {
      await _getMessagesCollection(tripId).doc(messageId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Message deleted: $messageId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error deleting message: $e');
      }
      return false;
    }
  }
  
  /// Get paginated messages (for loading older messages)
  /// 
  /// **Usage**:
  /// ```dart
  /// final olderMessages = await FirestoreService().getMessagesPaginated(
  ///   tripId: 123,
  ///   startAfter: lastVisibleMessage.timestamp,
  ///   limit: 20,
  /// );
  /// ```
  Future<List<FirestoreMessage>> getMessagesPaginated({
    required int tripId,
    DateTime? startAfter,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _getMessagesCollection(tripId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => FirestoreMessage.fromQuerySnapshot(doc))
          .toList();
          
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error getting paginated messages: $e');
      }
      return [];
    }
  }
  
  /// Get single message by ID
  Future<FirestoreMessage?> getMessage({
    required int tripId,
    required String messageId,
  }) async {
    try {
      final doc = await _getMessagesCollection(tripId).doc(messageId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ [FirestoreService] Message not found: $messageId');
        }
        return null;
      }
      
      return FirestoreMessage.fromFirestore(doc);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error getting message: $e');
      }
      return null;
    }
  }
  
  /// Add reaction to a message
  /// 
  /// **Reactions format**: {'👍': 5, '❤️': 3, '😂': 2}
  Future<bool> addReaction({
    required int tripId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _getMessagesCollection(tripId).doc(messageId).update({
        'reactions.$emoji': FieldValue.increment(1),
      });
      
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Reaction added: $emoji to $messageId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error adding reaction: $e');
      }
      return false;
    }
  }
  
  /// Remove reaction from a message
  Future<bool> removeReaction({
    required int tripId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _getMessagesCollection(tripId).doc(messageId).update({
        'reactions.$emoji': FieldValue.increment(-1),
      });
      
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Reaction removed: $emoji from $messageId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error removing reaction: $e');
      }
      return false;
    }
  }
  
  /// Get message count for a trip
  Future<int> getMessageCount({required int tripId}) async {
    try {
      final snapshot = await _getMessagesCollection(tripId)
          .where('deleted', isEqualTo: false)
          .count()
          .get();
          
      return snapshot.count ?? 0;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Error getting message count: $e');
      }
      return 0;
    }
  }
  
  /// Check Firestore connectivity
  /// 
  /// Useful for debugging and health checks
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_health_check').doc('test').get();
      if (kDebugMode) {
        debugPrint('✅ [FirestoreService] Connection OK');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirestoreService] Connection FAILED: $e');
      }
      return false;
    }
  }
}
