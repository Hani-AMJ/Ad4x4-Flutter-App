/// Password validation utility
/// 
/// Validates password strength based on Django's default password requirements:
/// - Minimum 8 characters
/// - Contains uppercase letter
/// - Contains lowercase letter  
/// - Contains digit
/// - Contains special character (recommended)
/// - Not too similar to username/email
class PasswordValidator {
  /// Validate password strength
  /// 
  /// Returns list of validation errors. Empty list means password is valid.
  static List<String> validate(String password, {String? username, String? email}) {
    final errors = <String>[];

    // Check minimum length
    if (password.length < 8) {
      errors.add('At least 8 characters');
    }

    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('One uppercase letter');
    }

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('One lowercase letter');
    }

    // Check for digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('One number');
    }

    // Check for special character (recommended)
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('One special character');
    }

    // Check similarity to username
    if (username != null && username.isNotEmpty) {
      if (password.toLowerCase().contains(username.toLowerCase()) ||
          username.toLowerCase().contains(password.toLowerCase())) {
        errors.add('Too similar to username');
      }
    }

    // Check similarity to email
    if (email != null && email.isNotEmpty) {
      final emailUsername = email.split('@').first;
      if (password.toLowerCase().contains(emailUsername.toLowerCase()) ||
          emailUsername.toLowerCase().contains(password.toLowerCase())) {
        errors.add('Too similar to email');
      }
    }

    // Check if password is entirely numeric
    if (RegExp(r'^\d+$').hasMatch(password)) {
      errors.add('Cannot be entirely numeric');
    }

    return errors;
  }

  /// Check if password is valid
  static bool isValid(String password, {String? username, String? email}) {
    return validate(password, username: username, email: email).isEmpty;
  }

  /// Get password strength (0-5)
  /// 
  /// Returns strength score:
  /// - 0: Very weak (< 8 chars)
  /// - 1: Weak (8+ chars, missing requirements)
  /// - 2: Fair (8+ chars, has some requirements)
  /// - 3: Good (8+ chars, has most requirements)
  /// - 4: Strong (8+ chars, has all basic requirements)
  /// - 5: Very strong (8+ chars, has all requirements + special chars)
  static int getStrength(String password, {String? username, String? email}) {
    if (password.length < 8) return 0;

    int score = 1;
    final errors = validate(password, username: username, email: email);

    // Award points for meeting requirements
    final totalRequirements = 5; // uppercase, lowercase, digit, special, not similar
    final metRequirements = totalRequirements - errors.length;

    if (metRequirements >= 1) score = 2;
    if (metRequirements >= 3) score = 3;
    if (metRequirements >= 4) score = 4;
    if (metRequirements == totalRequirements) score = 5;

    return score;
  }

  /// Get strength label
  static String getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  /// Get requirement display text
  static String getRequirementText(String error) {
    // Map internal errors to user-friendly text
    switch (error) {
      case 'At least 8 characters':
        return 'At least 8 characters';
      case 'One uppercase letter':
        return 'Contains uppercase letter (A-Z)';
      case 'One lowercase letter':
        return 'Contains lowercase letter (a-z)';
      case 'One number':
        return 'Contains number (0-9)';
      case 'One special character':
        return 'Contains special character (!@#\$%^&*)';
      case 'Too similar to username':
        return 'Not similar to username';
      case 'Too similar to email':
        return 'Not similar to email';
      case 'Cannot be entirely numeric':
        return 'Cannot be only numbers';
      default:
        return error;
    }
  }
}
