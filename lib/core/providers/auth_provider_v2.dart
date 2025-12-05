import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/main_api_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/fcm_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 🔄 NEW: Clean Riverpod-based Authentication Provider
/// 
/// Single source of truth for authentication state.
/// No singletons, no sync issues, just clean reactive state.
/// 
/// Benefits:
/// - ✅ Single source of truth (no AuthService + AuthNotifier split)
/// - ✅ Automatic state updates (Riverpod handles everything)
/// - ✅ Works on all platforms (SharedPreferences is reliable)
/// - ✅ Simple debugging (one place to check)
/// - ✅ No manual synchronization needed

// Storage keys
const String _kAuthToken = 'auth_token';
const String _kUserId = 'user_id';
const String _kUsername = 'username';

/// Authentication State (Simple!)
class AuthStateV2 {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthStateV2({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthStateV2 copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthStateV2(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Clean Authentication Provider (Riverpod StateNotifier)
class AuthNotifierV2 extends StateNotifier<AuthStateV2> {
  final MainApiRepository _repository;

  AuthNotifierV2(this._repository) : super(const AuthStateV2(isLoading: true)) {
    _initialize();
  }

  /// Initialize - Restore session from SharedPreferences
  Future<void> _initialize() async {
    print('🔐 [AuthV2] Initializing...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kAuthToken);
      
      if (token != null) {
        print('✅ [AuthV2] Token found, validating...');
        
        try {
          // Validate token by fetching profile
          final profileData = await _repository.getProfile();
          final user = UserModel.fromJson(profileData);
          
          print('✅ [AuthV2] Session restored: ${user.username}');
          state = AuthStateV2(user: user, isLoading: false);
        } catch (e) {
          // Token invalid/expired - clear it
          print('❌ [AuthV2] Token invalid: $e');
          await prefs.remove(_kAuthToken);
          state = const AuthStateV2(isLoading: false);
        }
      } else {
        print('✅ [AuthV2] No token found (fresh start)');
        state = const AuthStateV2(isLoading: false);
      }
    } catch (e) {
      print('❌ [AuthV2] Initialization error: $e');
      state = AuthStateV2(
        isLoading: false,
        error: 'Failed to initialize authentication',
      );
    }
  }

  /// Login with username/email and password
  Future<bool> login({
    required String login,
    required String password,
  }) async {
    print('🔐 [AuthV2] Login attempt: $login');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Call login API
      final response = await _repository.login(
        login: login,
        password: password,
      );

      // Extract token
      final token = response['token'] as String?;
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid server response',
        );
        return false;
      }

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuthToken, token);
      print('✅ [AuthV2] Token saved to SharedPreferences');

      // Fetch user profile
      try {
        final profileData = await _repository.getProfile();
        final user = UserModel.fromJson(profileData);
        
        // Save user info for quick access
        await prefs.setString(_kUserId, user.id.toString());
        await prefs.setString(_kUsername, user.username);

        print('✅ [AuthV2] Login successful: ${user.username}');
        state = AuthStateV2(user: user, isLoading: false);
        
        // ✅ NEW: Authenticate with Firebase using custom token
        _authenticateWithFirebase();
        
        return true;
      } catch (e) {
        print('❌ [AuthV2] Failed to fetch profile: $e');
        await prefs.remove(_kAuthToken);
        state = AuthStateV2(
          isLoading: false,
          error: 'Failed to load user profile',
        );
        return false;
      }
    } catch (e) {
      print('❌ [AuthV2] Login error: $e');
      state = AuthStateV2(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Logout - Clear everything
  Future<void> logout() async {
    print('🔥 [AuthV2] Logout initiated');
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID before clearing (for deletion state cleanup)
      final userId = prefs.getString(_kUserId);
      
      // CRITICAL: Clear user-specific deletion state to prevent cross-user leakage
      // This must be imported at the top of the file
      if (userId != null) {
        await prefs.remove('deletion_requested_$userId');
        await prefs.remove('deletion_request_date_$userId');
        print('🧹 [AuthV2] Cleared deletion state for user: $userId');
      }
      // Also clear global keys (backward compatibility)
      await prefs.remove('deletion_requested');
      await prefs.remove('deletion_request_date');
      
      // Clear auth data
      await prefs.remove(_kAuthToken);
      await prefs.remove(_kUserId);
      await prefs.remove(_kUsername);
      
      print('✅ [AuthV2] Logout complete');
      state = const AuthStateV2(isLoading: false);
    } catch (e) {
      print('❌ [AuthV2] Logout error: $e');
      // Force clear state even if storage clear fails
      state = const AuthStateV2(isLoading: false);
    }
  }

  /// Register new user account
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    // Optional fields
    String? dob,
    String? gender,
    String? city,
    String? nationality,
    String? carBrand,
    String? carModel,
    String? carColor,
    int? carYear,
    String? iceName,
    String? icePhone,
    String? avatar,
  }) async {
    print('📝 [AuthV2] Registration attempt: $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        // Pass optional fields
        dob: dob,
        gender: gender,
        city: city,
        nationality: nationality,
        carBrand: carBrand,
        carModel: carModel,
        carColor: carColor,
        carYear: carYear,
        iceName: iceName,
        icePhone: icePhone,
        avatar: avatar,
      );

      print('✅ [AuthV2] Registration successful');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('❌ [AuthV2] Registration error: $e');
      state = AuthStateV2(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Request password reset email
  Future<bool> forgotPassword({required String email}) async {
    print('🔑 [AuthV2] Password reset request: $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.forgotPassword(email: email);
      print('✅ [AuthV2] Password reset email sent');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('❌ [AuthV2] Password reset error: $e');
      state = AuthStateV2(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;

    try {
      final profileData = await _repository.getProfile();
      final user = UserModel.fromJson(profileData);
      state = state.copyWith(user: user);
      print('✅ [AuthV2] Profile refreshed');
    } catch (e) {
      print('❌ [AuthV2] Profile refresh failed: $e');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('SocketException') || 
        errorString.contains('NetworkException') ||
        errorString.contains('Failed host lookup')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (errorString.contains('TimeoutException')) {
      return 'Connection timeout. Server took too long to respond.';
    } else if (errorString.contains('401')) {
      return 'Invalid username or password.';
    } else if (errorString.contains('403')) {
      return 'Access forbidden. Please contact support.';
    } else if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Server error. Please try again later.';
    } else {
      return 'Login failed. Please try again.';
    }
  }

  /// Authenticate with Firebase using custom token
  /// 
  /// Called after successful AD4x4 login to enable Firebase services
  /// (Firestore real-time chat, FCM push notifications).
  /// 
  /// This runs in the background and doesn't block the login flow.
  /// If Firebase auth fails, the app continues to work with REST API only.
  Future<void> _authenticateWithFirebase() async {
    try {
      print('🔥 [AuthV2] Authenticating with Firebase...');
      
      final firebaseUser = await FirebaseAuthService().signInWithCustomToken();
      
      if (firebaseUser != null) {
        print('✅ [AuthV2] Firebase authentication successful');
        print('   Firebase UID: ${firebaseUser.uid}');
        
        // ✅ Register FCM device token with backend
        await _registerFCMToken();
        
      } else {
        print('⚠️ [AuthV2] Firebase authentication failed - continuing without real-time features');
      }
      
    } catch (e) {
      print('❌ [AuthV2] Firebase authentication error: $e');
      // Don't throw - app should continue working with REST API
    }
  }
  
  /// Register FCM device token with backend
  /// 
  /// After Firebase Auth succeeds, get the FCM device token and register it
  /// with the AD4x4 backend so it can send push notifications to this device.
  Future<void> _registerFCMToken() async {
    try {
      // Skip FCM registration on web (not supported)
      if (kIsWeb) {
        print('ℹ️ [AuthV2] Skipping FCM registration (web platform)');
        return;
      }
      
      print('📱 [AuthV2] Registering FCM device token...');
      
      // Initialize FCM Service
      await FCMService.initialize();
      
      // Get device token
      final fcmService = FCMService();
      final deviceToken = await fcmService.getToken();
      
      if (deviceToken != null) {
        print('✅ [AuthV2] FCM token obtained: ${deviceToken.substring(0, 20)}...');
        
        // TODO: Register device token with backend
        // await _repository.registerFCMDevice(deviceToken);
        
        // For now, just log it - backend endpoint needs to be implemented
        print('⚠️ [AuthV2] FCM token ready, but backend registration endpoint not yet implemented');
        print('   Backend team needs to create: POST /api/notifications/device/');
        
      } else {
        print('⚠️ [AuthV2] Failed to obtain FCM token');
      }
      
    } catch (e) {
      print('❌ [AuthV2] FCM registration error: $e');
      // Don't throw - Firebase auth already succeeded
    }
  }
}

/// Auth Provider V2 - Single source of truth
final authProviderV2 = StateNotifierProvider<AuthNotifierV2, AuthStateV2>((ref) {
  print('🔧 [AuthV2] Creating AuthNotifierV2 instance');
  final repository = MainApiRepository();
  return AuthNotifierV2(repository);
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProviderV2 = Provider<bool>((ref) {
  final authState = ref.watch(authProviderV2);
  return authState.isAuthenticated;
});

/// Convenience provider to get current user
final currentUserProviderV2 = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProviderV2);
  return authState.user;
});

/// Helper to get auth token from SharedPreferences
/// Used by API interceptor
Future<String?> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kAuthToken);
}
