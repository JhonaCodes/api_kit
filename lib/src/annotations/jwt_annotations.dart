import '../validators/jwt_validator_base.dart';

/// Anotación para validación a nivel de controlador
///
/// Todos los endpoints del controlador heredan esta validación a menos que
/// sean sobrescritos por @JWTEndpoint o @JWTPublic
///
/// Ejemplo:
/// ```dart
/// @Controller('/api/admin')
/// @JWTController([
///   MyAdminValidator(),
///   MyBusinessHoursValidator(),
/// ], requireAll: true)
/// class AdminController extends BaseController {
///   // Todos los endpoints requieren admin + business hours
/// }
/// ```
class JWTController {
  /// Lista de validadores que se ejecutarán
  final List<JWTValidatorBase> validators;

  /// Si es true, TODOS los validadores deben pasar (AND logic)
  /// Si es false, al menos UNO debe pasar (OR logic)
  final bool requireAll;

  const JWTController(this.validators, {this.requireAll = true});
}

/// Anotación para validación a nivel de endpoint específico
///
/// Sobrescribe la validación del controlador si existe.
/// Permite validaciones específicas por endpoint.
///
/// Ejemplo:
/// ```dart
/// @POST('/transactions')
/// @JWTEndpoint([
///   MyFinancialValidator(minimumAmount: 10000),
///   MyDepartmentValidator(allowedDepartments: ['finance']),
/// ], requireAll: true)
/// Future<Response> createTransaction(Request request) async {
///   // Este endpoint requiere validación financiera específica
/// }
/// ```
class JWTEndpoint {
  /// Lista de validadores que se ejecutarán
  final List<JWTValidatorBase> validators;

  /// Si es true, TODOS los validadores deben pasar (AND logic)
  /// Si es false, al menos UNO debe pasar (OR logic)
  final bool requireAll;

  const JWTEndpoint(this.validators, {this.requireAll = true});
}

/// Anotación para marcar un endpoint como público (sin validación JWT)
///
/// Sobrescribe cualquier validación de controller o endpoint.
/// Tiene la mayor prioridad en el sistema de validación.
///
/// Ejemplo:
/// ```dart
/// @GET('/health')
/// @JWTPublic()
/// Future<Response> healthCheck(Request request) async {
///   // Endpoint público - sin validación JWT
/// }
/// ```
class JWTPublic {
  const JWTPublic();
}
