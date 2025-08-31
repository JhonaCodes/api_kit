import '../validators/jwt_validator_base.dart';

/// Annotation for controller-level validation
///
/// All endpoints of the controller inherit this validation unless
/// they are overridden by @JWTEndpoint or @JWTPublic
///
/// Example:
/// ```dart
/// @Controller('/api/admin')
/// @JWTController([
///   MyAdminValidator(),
///   MyBusinessHoursValidator(),
/// ], requireAll: true)
/// class AdminController extends BaseController {
///   // All endpoints require admin + business hours
/// }
/// ```
class JWTController {
  /// List of validators to be executed
  final List<JWTValidatorBase> validators;

  /// If true, ALL validators must pass (AND logic)
  /// If false, at least ONE must pass (OR logic)
  final bool requireAll;

  const JWTController(this.validators, {this.requireAll = true});
}

/// Annotation for specific endpoint-level validation
///
/// Overrides the controller\'s validation if it exists.
/// Allows for specific validations per endpoint.
///
/// Example:
/// ```dart
/// @POST('/transactions')
/// @JWTEndpoint([
///   MyFinancialValidator(minimumAmount: 10000),
///   MyDepartmentValidator(allowedDepartments: [\'finance\']),
/// ], requireAll: true)
/// Future<Response> createTransaction(Request request) async {
///   // This endpoint requires specific financial validation
/// }
/// ```
class JWTEndpoint {
  /// List of validators to be executed
  final List<JWTValidatorBase> validators;

  /// If true, ALL validators must pass (AND logic)
  /// If false, at least ONE must pass (OR logic)
  final bool requireAll;

  const JWTEndpoint(this.validators, {this.requireAll = true});
}

/// Annotation to mark an endpoint as public (without JWT validation)
///
/// Overrides any controller or endpoint validation.
/// Has the highest priority in the validation system.
///
/// Example:
/// ```dart
/// @GET('/health')
/// @JWTPublic()
/// Future<Response> healthCheck(Request request) async {
///   // Public endpoint - no JWT validation
/// }
/// ```
class JWTPublic {
  const JWTPublic();
}
