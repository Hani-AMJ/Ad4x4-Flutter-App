import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// API Client with Dio and authentication interceptor
class ApiClient {
  late final Dio _dio;

  // API Base URLs
  static const String mainApiUrl = 'https://ap.ad4x4.com'; // Django API
  static const String galleryApiUrl = 'https://media.ad4x4.com'; // Node.js Gallery API (CORRECTED)

  ApiClient({
    String? baseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? mainApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token directly from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 [ApiClient] Adding token to ${options.method} ${options.path}');
          }

          developer.log(
            '🌐 REQUEST: ${options.method} ${options.baseUrl}${options.path}',
            name: 'ApiClient',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
            name: 'ApiClient',
          );
          
          // 🔍 DEBUG: Log response data structure
          if (kDebugMode) {
            print('📦 [ApiClient] Response received:');
            print('   Status: ${response.statusCode}');
            print('   Path: ${response.requestOptions.path}');
            print('   Data type: ${response.data.runtimeType}');
            if (response.data is Map) {
              print('   Data keys: ${(response.data as Map).keys.toList()}');
            }
            print('   Data: ${response.data}');
          }
          
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ [ApiClient] ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          
          // 🔍 DEBUG: Enhanced error logging
          if (kDebugMode) {
            print('❌ [ApiClient] Detailed Error:');
            print('   Type: ${error.type}');
            print('   Status Code: ${error.response?.statusCode}');
            print('   Path: ${error.requestOptions.path}');
            print('   Message: ${error.message}');
            print('   Response data: ${error.response?.data}');
            print('   Response data type: ${error.response?.data.runtimeType}');
          }
          
          developer.log(
            '❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}',
            name: 'ApiClient',
          );

          // Handle 401 Unauthorized - token expired/invalid
          if (error.response?.statusCode == 401) {
            print('🚨 [ApiClient] 401 Unauthorized - Token invalid');
            // Clear token from SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            // Error will propagate and user will be redirected to login
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      // Note: Django JWT doesn't support refresh tokens the same way
      // This API uses single long-lived tokens
      developer.log('Token refresh not implemented (Django JWT uses long-lived tokens)', name: 'ApiClient');
      return false;
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'ApiClient');
    }
    return false;
  }

  /// Retry failed request after token refresh
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: error.response?.data['message'] ?? 'Something went wrong',
          statusCode: error.response?.statusCode ?? 500,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: 0,
        );
      default:
        return ApiException(
          message: 'Network error. Please check your internet connection.',
          statusCode: 0,
        );
    }
  }

  /// Change base URL (for switching between main API and gallery API)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Get current Dio instance for advanced usage
  Dio get dio => _dio;
}

/// Custom API Exception with enhanced error handling
/// 
/// Provides helper methods for common HTTP status codes and user-friendly messages
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  /// Helper methods for common status codes
  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;
  bool get isBadRequest => statusCode == 400;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// User-friendly error messages based on status code
  String get userFriendlyMessage {
    if (isNotFound) return 'This content is no longer available';
    if (isForbidden) return 'You don\'t have permission to access this';
    if (isUnauthorized) return 'Please log in again';
    if (isBadRequest) return 'Invalid request';
    if (isServerError) return 'Server error, please try again later';
    return message;
  }

  /// Action guidance for users based on error type
  String get actionGuidance {
    if (isNotFound) return 'The content may have been deleted or is no longer accessible.';
    if (isForbidden) return 'Contact an administrator if you believe this is an error.';
    if (isUnauthorized) return 'Your session has expired. Please log in again.';
    if (isBadRequest) return 'Please check your input and try again.';
    if (isServerError) return 'Our servers are experiencing issues. Please try again in a few moments.';
    return 'Please try again or contact support if the problem persists.';
  }

  @override
  String toString() => message;
}
