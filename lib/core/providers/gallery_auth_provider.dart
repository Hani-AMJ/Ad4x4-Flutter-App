import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

/// 📸 Gallery API Authentication Provider
/// 
/// Manages separate JWT authentication for Gallery API (Node.js service)
/// Gallery API uses email + password authentication, separate from main API

// Storage keys for Gallery API token
const String _kGalleryToken = 'gallery_auth_token';
const String _kGalleryEmail = 'gallery_user_email';

/// Gallery Authentication State
class GalleryAuthState {
  final String? token;
  final String? email;
  final bool isLoading;
  final String? error;

  const GalleryAuthState({
    this.token,
    this.email,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  GalleryAuthState copyWith({
    String? token,
    String? email,
    bool? isLoading,
    String? error,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return GalleryAuthState(
      token: clearToken ? null : (token ?? this.token),
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Gallery Authentication Notifier
class GalleryAuthNotifier extends StateNotifier<GalleryAuthState> {
  final ApiClient _apiClient;

  GalleryAuthNotifier(this._apiClient) : super(const GalleryAuthState(isLoading: true)) {
    _initialize();
  }

  /// Initialize - Restore Gallery API session
  Future<void> _initialize() async {
    print('📸 [GalleryAuth] Initializing...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kGalleryToken);
      final email = prefs.getString(_kGalleryEmail);
      
      if (token != null && token.isNotEmpty) {
        print('✅ [GalleryAuth] Token found for $email');
        
        // Validate token by attempting a simple API call
        try {
          _apiClient.setBaseUrl(ApiClient.galleryApiUrl);
          
          // Add token to request headers
          await _apiClient.get('/api/galleries', 
            queryParameters: {'page': 1, 'limit': 1},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          
          print('✅ [GalleryAuth] Token valid, session restored');
          state = GalleryAuthState(token: token, email: email, isLoading: false);
        } catch (e) {
          // Token invalid - clear it
          print('❌ [GalleryAuth] Token invalid: $e');
          await prefs.remove(_kGalleryToken);
          await prefs.remove(_kGalleryEmail);
          state = const GalleryAuthState(isLoading: false);
        }
      } else {
        print('✅ [GalleryAuth] No token found (fresh start)');
        state = const GalleryAuthState(isLoading: false);
      }
    } catch (e) {
      print('❌ [GalleryAuth] Initialization error: $e');
      state = GalleryAuthState(
        isLoading: false,
        error: 'Failed to initialize Gallery authentication',
      );
    }
  }

  /// Login to Gallery API with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    print('📸 [GalleryAuth] Login attempt: $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Set Gallery API base URL
      _apiClient.setBaseUrl(ApiClient.galleryApiUrl);
      
      // Call Gallery API login endpoint
      final response = await _apiClient.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Extract token from response
      final token = response.data['token'] as String?;
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid server response',
        );
        return false;
      }

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGalleryToken, token);
      await prefs.setString(_kGalleryEmail, email);
      print('✅ [GalleryAuth] Gallery token saved');

      state = GalleryAuthState(
        token: token,
        email: email,
        isLoading: false,
      );
      
      print('✅ [GalleryAuth] Login successful: $email');
      return true;
    } catch (e) {
      print('❌ [GalleryAuth] Login error: $e');
      state = GalleryAuthState(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Use main API token for Gallery API (if Gallery API accepts it)
  /// This is a convenience method in case Gallery API can validate main API tokens
  Future<bool> useMainApiToken(String mainToken) async {
    print('📸 [GalleryAuth] Attempting to use main API token...');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Try using main API token with Gallery API
      _apiClient.setBaseUrl(ApiClient.galleryApiUrl);
      
      // Test token validity
      await _apiClient.get('/api/galleries',
        queryParameters: {'page': 1, 'limit': 1},
        options: Options(headers: {'Authorization': 'Bearer $mainToken'}),
      );

      // Token works! Save it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGalleryToken, mainToken);
      await prefs.setString(_kGalleryEmail, 'via_main_api');
      
      print('✅ [GalleryAuth] Main API token accepted by Gallery API');
      state = GalleryAuthState(
        token: mainToken,
        email: 'via_main_api',
        isLoading: false,
      );
      return true;
    } catch (e) {
      print('❌ [GalleryAuth] Main API token not accepted: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Main API token not valid for Gallery API',
      );
      return false;
    }
  }

  /// Logout from Gallery API
  Future<void> logout() async {
    print('🔥 [GalleryAuth] Gallery logout initiated');
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGalleryToken);
      await prefs.remove(_kGalleryEmail);
      
      print('✅ [GalleryAuth] Gallery logout complete');
      state = const GalleryAuthState(isLoading: false);
    } catch (e) {
      print('❌ [GalleryAuth] Logout error: $e');
      state = const GalleryAuthState(isLoading: false);
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('SocketException') || 
        errorString.contains('NetworkException') ||
        errorString.contains('Failed host lookup')) {
      return 'Cannot connect to Gallery API. Please check your internet connection.';
    } else if (errorString.contains('TimeoutException')) {
      return 'Connection timeout. Gallery API took too long to respond.';
    } else if (errorString.contains('401')) {
      return 'Invalid email or password for Gallery API.';
    } else if (errorString.contains('403')) {
      return 'Access forbidden. Please contact support.';
    } else if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Gallery API error. Please try again later.';
    } else {
      return 'Gallery login failed. Please try again.';
    }
  }
}

/// Gallery Auth Provider - for Gallery API authentication
final galleryAuthProvider = StateNotifierProvider<GalleryAuthNotifier, GalleryAuthState>((ref) {
  print('🔧 [GalleryAuth] Creating GalleryAuthNotifier instance');
  final apiClient = ApiClient(baseUrl: ApiClient.galleryApiUrl);
  return GalleryAuthNotifier(apiClient);
});

/// Convenience provider to check Gallery API authentication
final isGalleryAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(galleryAuthProvider);
  return authState.isAuthenticated;
});

/// Helper to get Gallery API token from SharedPreferences
Future<String?> getGalleryAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kGalleryToken);
}
