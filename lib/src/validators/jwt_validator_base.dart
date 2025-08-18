import 'package:shelf/shelf.dart';

/// Base abstracta para todos los validadores JWT personalizados.
/// 
/// Los desarrolladores extienden esta clase para crear validadores específicos
/// con control total sobre la estructura del JWT y la lógica de validación.
abstract class JWTValidatorBase {
  /// Constructor const para permitir validadores const en anotaciones
  const JWTValidatorBase();
  /// Método obligatorio que implementa la lógica de validación
  /// 
  /// [request] - El request HTTP actual
  /// [jwtPayload] - El payload decodificado del JWT
  /// 
  /// Retorna [ValidationResult] indicando éxito o falla con mensaje
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload);
  
  /// Mensaje de error por defecto cuando la validación falla
  /// 
  /// Este mensaje se usa si [ValidationResult.invalid()] es llamado sin mensaje específico
  String get defaultErrorMessage;
  
  /// Callback opcional ejecutado cuando la validación es exitosa
  /// 
  /// Útil para logging, auditoría, o lógica de negocio adicional
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    // Implementación opcional por el desarrollador
  }
  
  /// Callback opcional ejecutado cuando la validación falla
  /// 
  /// [reason] - El mensaje específico de por qué falló la validación
  /// 
  /// Útil para logging de fallos, auditoría de seguridad, o alertas
  void onValidationFailed(Request request, Map<String, dynamic> jwtPayload, String reason) {
    // Implementación opcional por el desarrollador
  }
}

/// Resultado de validación usando Result Pattern
/// 
/// Proporciona respuestas claras sobre el éxito o falla de la validación
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult._(this.isValid, this.errorMessage);
  
  /// Crea un resultado exitoso
  /// 
  /// Indica que la validación pasó exitosamente
  static ValidationResult valid() => ValidationResult._(true, null);
  
  /// Crea un resultado fallido con mensaje personalizado
  /// 
  /// [message] - Mensaje específico describiendo por qué falló la validación
  static ValidationResult invalid(String message) => ValidationResult._(false, message);
  
  /// Verifica si la validación fue exitosa
  bool get isSuccess => isValid;
  
  /// Verifica si la validación falló
  bool get isFailure => !isValid;
}