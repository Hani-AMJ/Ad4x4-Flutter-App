import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/main_api_repository.dart';

/// Firebase Authentication Service
/// 
/// Handles Firebase Authentication using custom tokens from your backend.
/// This allows users to authenticate with Firebase using their existing
/// AD4x4 account credentials without creating a separate Firebase account.
/// 
/// **HOW IT WORKS**:
/// 1. User logs in to AD4x4 backend (existing JWT auth flow)
/// 2. App requests a Firebase custom token from backend
/// 3. Backend generates custom token using Firebase Admin SDK
/// 4. App uses custom token to authenticate with Firebase
/// 5. User can now access Firestore and receive FCM notifications
/// 
/// **BACKEND ENDPOINT REQUIRED**:
/// ```python
/// # POST /api/firebase/custom-token
/// @api_view(['POST'])
/// @permission_classes([IsAuthenticated])
/// def get_firebase_custom_token(request):
///     try:
///         # User is already authenticated via JWT
///         user_id = request.user.id
///         
///         # Generate Firebase custom token
///         custom_token = auth.create_custom_token(str(user_id))
///         
///         return Response({
///             'token': custom_token.decode('utf-8'),
///             'userId': user_id
///         })
///     except Exception as e:
///         return Response({'error': str(e)}, status=500)
/// ```
/// 
/// **USAGE**:
/// ```dart
/// // After user logs in to AD4x4:
/// final firebaseUser = await FirebaseAuthService().signInWithCustomToken();
/// 
/// if (firebaseUser != null) {
///   print('✅ Firebase authenticated: ${firebaseUser.uid}');
///   // Now you can use Firestore and FCM
/// } else {
///   print('❌ Firebase authentication failed');
/// }
/// ```
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MainApiRepository _repository = MainApiRepository();
  
  // Singleton pattern
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();
  
  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is authenticated with Firebase
  bool get isAuthenticated => _auth.currentUser != null;
  
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign in with custom token from backend
  /// 
  /// This is the primary authentication method for AD4x4 app.
  /// It uses the custom token endpoint to authenticate the user.
  /// 
  /// **Requirements**:
  /// - User must be logged in to AD4x4 backend (JWT token must be valid)
  /// - Backend must have `/api/firebase/custom-token` endpoint implemented
  /// 
  /// **Returns**: Firebase User if successful, null if failed
  Future<User?> signInWithCustomToken() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 [FirebaseAuth] Requesting custom token from backend...');
      }
      
      // Get custom token from backend
      final customToken = await _repository.getFirebaseCustomToken();
      
      if (customToken == null) {
        if (kDebugMode) {
          debugPrint('❌ [FirebaseAuth] Backend returned null custom token');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('✅ [FirebaseAuth] Custom token received (length: ${customToken.length})');
        debugPrint('🔐 [FirebaseAuth] Signing in to Firebase...');
      }
      
      // Sign in to Firebase with custom token
      final credential = await _auth.signInWithCustomToken(customToken);
      
      if (kDebugMode) {
        debugPrint('✅ [FirebaseAuth] Signed in successfully');
        debugPrint('   User ID: ${credential.user?.uid}');
        debugPrint('   Email: ${credential.user?.email ?? "N/A"}');
      }
      
      return credential.user;
      
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Firebase error: ${e.code} - ${e.message}');
      }
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error signing in: $e');
      }
      return null;
    }
  }
  
  /// Sign out from Firebase
  /// 
  /// Call this when user logs out of AD4x4 app
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      if (kDebugMode) {
        debugPrint('✅ [FirebaseAuth] Signed out successfully');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error signing out: $e');
      }
    }
  }
  
  /// Refresh Firebase authentication
  /// 
  /// Call this if Firebase token expires or authentication fails.
  /// It will get a fresh custom token from backend and sign in again.
  Future<User?> refreshAuthentication() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [FirebaseAuth] Refreshing authentication...');
      }
      
      // Sign out first to clear old session
      await _auth.signOut();
      
      // Sign in with fresh custom token
      return await signInWithCustomToken();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error refreshing authentication: $e');
      }
      return null;
    }
  }
  
  /// Check if Firebase authentication is still valid
  /// 
  /// Returns true if user is authenticated and token is not expired
  Future<bool> isAuthenticationValid() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Get fresh ID token to check if it's still valid
      final token = await user.getIdToken(false);
      
      return token != null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [FirebaseAuth] Authentication may be invalid: $e');
      }
      return false;
    }
  }
  
  /// Get Firebase ID token
  /// 
  /// This token can be used to authenticate Firestore requests
  /// and verify user identity on backend.
  /// 
  /// **Parameters**:
  /// - `forceRefresh`: If true, always gets a fresh token from server
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [FirebaseAuth] No current user');
        }
        return null;
      }
      
      return await user.getIdToken(forceRefresh);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error getting ID token: $e');
      }
      return null;
    }
  }
  
  /// Auto-refresh Firebase authentication if needed
  /// 
  /// This method checks if authentication is valid and refreshes if needed.
  /// Call this periodically (e.g., on app resume) to maintain Firebase session.
  /// 
  /// **Returns**: true if authentication is valid or successfully refreshed
  Future<bool> ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (await isAuthenticationValid()) {
        if (kDebugMode) {
          debugPrint('✅ [FirebaseAuth] Authentication is valid');
        }
        return true;
      }
      
      if (kDebugMode) {
        debugPrint('⚠️ [FirebaseAuth] Authentication invalid, attempting refresh...');
      }
      
      // Try to refresh
      final user = await refreshAuthentication();
      
      if (user != null) {
        if (kDebugMode) {
          debugPrint('✅ [FirebaseAuth] Authentication refreshed successfully');
        }
        return true;
      }
      
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Failed to refresh authentication');
      }
      return false;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error ensuring authentication: $e');
      }
      return false;
    }
  }
}

/// Extension methods for MainApiRepository
/// 
/// These methods should be added to your MainApiRepository class
extension FirebaseAuthExtension on MainApiRepository {
  /// Get Firebase custom token from backend
  /// 
  /// **Backend endpoint**: POST /api/firebase/custom-token
  /// **Authentication**: JWT token required
  /// 
  /// **Returns**: Custom token string or null if failed
  Future<String?> getFirebaseCustomToken() async {
    try {
      // TODO: Implement this method in MainApiRepository
      // 
      // Example implementation:
      // final response = await _apiClient.post(
      //   '/firebase/custom-token',
      //   data: {},
      // );
      // 
      // return response.data['token'] as String?;
      
      if (kDebugMode) {
        debugPrint('⚠️ [FirebaseAuth] getFirebaseCustomToken() not implemented in MainApiRepository');
        debugPrint('   Backend must implement: POST /api/firebase/custom-token');
      }
      
      throw UnimplementedError(
        'getFirebaseCustomToken() must be implemented in MainApiRepository. '
        'Backend endpoint required: POST /api/firebase/custom-token'
      );
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FirebaseAuth] Error getting custom token: $e');
      }
      return null;
    }
  }
}
