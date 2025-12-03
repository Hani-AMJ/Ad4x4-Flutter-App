import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/validation_result.dart';
import '../../data/repositories/validator_repository.dart';
import '../network/api_provider.dart';

/// Provider for validator repository
final validatorRepositoryProvider = Provider<ValidatorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ValidatorRepository(apiClient);
});

/// State for field validation
class ValidationState {
  final bool isValidating;
  final ValidationResult? result;

  const ValidationState({
    this.isValidating = false,
    this.result,
  });

  ValidationState copyWith({
    bool? isValidating,
    ValidationResult? result,
  }) {
    return ValidationState(
      isValidating: isValidating ?? this.isValidating,
      result: result ?? this.result,
    );
  }

  /// Check if field is valid and ready
  bool get isValid => result != null && result!.isValid && !isValidating;

  /// Check if field is invalid
  bool get isInvalid => result != null && result!.isInvalid && !isValidating;

  /// Check if we should show error message
  bool get shouldShowError => isInvalid && result!.hasError;
}

/// Username validation notifier with debouncing
class UsernameValidationNotifier extends StateNotifier<ValidationState> {
  final ValidatorRepository _repository;
  Timer? _debounce;

  UsernameValidationNotifier(this._repository) : super(const ValidationState());

  /// Validate username with 500ms debounce
  void validate(String username) {
    // Cancel previous timer
    _debounce?.cancel();

    // Reset if username is empty
    if (username.trim().isEmpty) {
      state = const ValidationState();
      return;
    }

    // Set validating state
    state = const ValidationState(isValidating: true);

    // Start new timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await _repository.validateUsername(username.trim());
        state = ValidationState(
          isValidating: false,
          result: result,
        );
      } catch (e) {
        state = ValidationState(
          isValidating: false,
          result: ValidationResult(
            value: username,
            valid: false,
            error: 'Validation failed',
          ),
        );
      }
    });
  }

  /// Clear validation state
  void clear() {
    _debounce?.cancel();
    state = const ValidationState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Email validation notifier with debouncing
class EmailValidationNotifier extends StateNotifier<ValidationState> {
  final ValidatorRepository _repository;
  Timer? _debounce;

  EmailValidationNotifier(this._repository) : super(const ValidationState());

  /// Validate email with 500ms debounce
  void validate(String email) {
    // Cancel previous timer
    _debounce?.cancel();

    // Reset if email is empty
    if (email.trim().isEmpty) {
      state = const ValidationState();
      return;
    }

    // Set validating state
    state = const ValidationState(isValidating: true);

    // Start new timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await _repository.validateEmail(email.trim());
        state = ValidationState(
          isValidating: false,
          result: result,
        );
      } catch (e) {
        state = ValidationState(
          isValidating: false,
          result: ValidationResult(
            value: email,
            valid: false,
            error: 'Validation failed',
          ),
        );
      }
    });
  }

  /// Clear validation state
  void clear() {
    _debounce?.cancel();
    state = const ValidationState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Provider for username validation
final usernameValidationProvider =
    StateNotifierProvider<UsernameValidationNotifier, ValidationState>((ref) {
  final repository = ref.watch(validatorRepositoryProvider);
  return UsernameValidationNotifier(repository);
});

/// Provider for email validation
final emailValidationProvider =
    StateNotifierProvider<EmailValidationNotifier, ValidationState>((ref) {
  final repository = ref.watch(validatorRepositoryProvider);
  return EmailValidationNotifier(repository);
});
