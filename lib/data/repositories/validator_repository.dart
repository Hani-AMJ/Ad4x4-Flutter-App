import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/validation_result.dart';

/// Repository for field validation API calls
/// 
/// Uses `/api/validators/` endpoint to check if username, email, or phone
/// is already taken before registration.
class ValidatorRepository {
  final ApiClient _apiClient;

  ValidatorRepository(this._apiClient);

  /// Validate username availability
  /// 
  /// Returns ValidationResult with:
  /// - valid: true if username is available
  /// - valid: false if username is already taken
  /// - error: error message if validation fails
  Future<ValidationResult> validateUsername(String username) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.validators,
        data: {'username': username},
      );

      if (response.data != null && response.data['username'] != null) {
        return ValidationResult.fromJson(response.data['username']);
      }

      return ValidationResult(
        value: username,
        valid: false,
        error: 'Validation failed',
      );
    } catch (e) {
      return ValidationResult(
        value: username,
        valid: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Validate email availability
  /// 
  /// Returns ValidationResult with:
  /// - valid: true if email is available
  /// - valid: false if email is already taken
  /// - error: error message if validation fails
  Future<ValidationResult> validateEmail(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.validators,
        data: {'email': email},
      );

      if (response.data != null && response.data['email'] != null) {
        return ValidationResult.fromJson(response.data['email']);
      }

      return ValidationResult(
        value: email,
        valid: false,
        error: 'Validation failed',
      );
    } catch (e) {
      return ValidationResult(
        value: email,
        valid: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Validate phone number format (backend doesn't check duplicates)
  /// 
  /// Returns ValidationResult with format validation only
  Future<ValidationResult> validatePhone(String phone) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.validators,
        data: {'phone': phone},
      );

      if (response.data != null && response.data['phone'] != null) {
        return ValidationResult.fromJson(response.data['phone']);
      }

      return ValidationResult(
        value: phone,
        valid: false,
        error: 'Validation failed',
      );
    } catch (e) {
      return ValidationResult(
        value: phone,
        valid: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Validate multiple fields at once
  /// 
  /// More efficient than calling individual validators separately.
  /// Returns map of field name to ValidationResult.
  Future<Map<String, ValidationResult>> validateMultiple({
    String? username,
    String? email,
    String? phone,
  }) async {
    final data = <String, String>{};
    if (username != null && username.isNotEmpty) data['username'] = username;
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;

    if (data.isEmpty) {
      return {};
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.validators,
        data: data,
      );

      final results = <String, ValidationResult>{};

      if (response.data != null) {
        if (username != null && response.data['username'] != null) {
          results['username'] = ValidationResult.fromJson(response.data['username']);
        }
        if (email != null && response.data['email'] != null) {
          results['email'] = ValidationResult.fromJson(response.data['email']);
        }
        if (phone != null && response.data['phone'] != null) {
          results['phone'] = ValidationResult.fromJson(response.data['phone']);
        }
      }

      return results;
    } catch (e) {
      // Return error results for all requested fields
      final results = <String, ValidationResult>{};
      if (username != null) {
        results['username'] = ValidationResult(
          value: username,
          valid: false,
          error: 'Network error',
        );
      }
      if (email != null) {
        results['email'] = ValidationResult(
          value: email,
          valid: false,
          error: 'Network error',
        );
      }
      if (phone != null) {
        results['phone'] = ValidationResult(
          value: phone,
          valid: false,
          error: 'Network error',
        );
      }
      return results;
    }
  }
}
