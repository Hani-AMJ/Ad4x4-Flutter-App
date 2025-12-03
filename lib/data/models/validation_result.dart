/// Result of a field validation check from the API
/// 
/// Used with `/api/validators/` endpoint to check if username/email/phone
/// is already taken before registration.
class ValidationResult {
  final String value;
  final bool valid;
  final String error;

  const ValidationResult({
    required this.value,
    required this.valid,
    required this.error,
  });

  /// Parse from API response
  /// 
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "value": "john_doe",
  ///   "valid": false,
  ///   "error": "Username is already taken"
  /// }
  /// ```
  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      value: json['value']?.toString() ?? '',
      valid: json['valid'] == true,
      error: json['error']?.toString() ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'valid': valid,
      'error': error,
    };
  }

  /// Check if validation passed
  bool get isValid => valid;

  /// Check if validation failed
  bool get isInvalid => !valid;

  /// Check if there's an error message
  bool get hasError => error.isNotEmpty;

  @override
  String toString() {
    return 'ValidationResult(value: $value, valid: $valid, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.value == value &&
        other.valid == valid &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(value, valid, error);
}
