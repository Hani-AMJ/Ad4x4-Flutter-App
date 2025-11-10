import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// API Client with Dio and authentication interceptor
class ApiClient {
  late final Dio _dio;

  // API Base URLs
  static const String mainApiUrl = 'https://ap.ad4x4.com'; // Django API
  static const String galleryApiUrl = 'https://gallery-api.ad4x4.com'; // Node.js Gallery API

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
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ [ApiClient] ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          
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

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}
