import 'package:shelf/shelf.dart';

/// Base abstract class for all custom JWT validators.
///
/// Developers extend this class to create specific validators
/// with full control over the JWT structure and validation logic.
abstract class JWTValidatorBase {
  /// Const constructor to allow const validators in annotations
  const JWTValidatorBase();

  /// Mandatory method that implements the validation logic
  ///
  /// [request] - The current HTTP request
  /// [jwtPayload] - The decoded payload of the JWT
  ///
  /// Returns [ValidationResult] indicating success or failure with a message
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload);

  /// Default error message when validation fails
  ///
  /// This message is used if [ValidationResult.invalid()] is called without a specific message
  String get defaultErrorMessage;

  /// Optional callback executed when validation is successful
  ///
  /// Useful for logging, auditing, or additional business logic
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    // Optional implementation by the developer
  }

  /// Optional callback executed when validation fails
  ///
  /// [reason] - The specific message why the validation failed
  ///
  /// Useful for logging failures, security auditing, or alerts
  void onValidationFailed(
    Request request,
    Map<String, dynamic> jwtPayload,
    String reason,
  ) {
    // Optional implementation by the developer
  }
}

/// Validation result using the Result Pattern
///
/// Provides clear responses about the success or failure of the validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult._(this.isValid, this.errorMessage);

  /// Creates a successful result
  ///
  /// Indicates that the validation passed successfully
  static ValidationResult valid() => ValidationResult._(true, null);

  /// Creates a failed result with a custom message
  ///
  /// [message] - Specific message describing why the validation failed
  static ValidationResult invalid(String message) =>
      ValidationResult._(false, message);

  /// Checks if the validation was successful
  bool get isSuccess => isValid;

  /// Checks if the validation failed
  bool get isFailure => !isValid;
}