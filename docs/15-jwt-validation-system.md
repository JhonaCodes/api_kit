# 🔐 JWT Validation System

El **Sistema de Validación JWT** de api_kit proporciona un mecanismo flexible y extensible para implementar autorización basada en anotaciones. Permite a los desarrolladores crear validadores personalizados con control total sobre la estructura del JWT y la lógica de validación.

## 🎯 Conceptos Clave

### 1. **Validadores Extensibles** - Clases personalizadas que extienden `JWTValidatorBase`
### 2. **Anotaciones Declarativas** - `@JWTController`, `@JWTEndpoint`, `@JWTPublic`
### 3. **Validación Jerárquica** - Controller-level y endpoint-level
### 4. **Result Pattern** - Respuestas claras con `ValidationResult`
### 5. **100% Developer Control** - Estructura JWT completamente personalizable

---

## 🏗️ 1. Base del Sistema de Validación

```dart
// lib/src/validators/jwt_validator_base.dart
abstract class JWTValidatorBase {
  /// Método obligatorio que implementa la lógica de validación
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload);
  
  /// Mensaje de error por defecto cuando la validación falla
  String get defaultErrorMessage;
  
  /// Callback opcional ejecutado cuando la validación es exitosa
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    // Implementación opcional por el desarrollador
  }
  
  /// Callback opcional ejecutado cuando la validación falla
  void onValidationFailed(Request request, Map<String, dynamic> jwtPayload, String reason) {
    // Implementación opcional por el desarrollador
  }
}

/// Resultado de validación usando Result Pattern
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult._(this.isValid, this.errorMessage);
  
  /// Crea un resultado exitoso
  static ValidationResult valid() => ValidationResult._(true, null);
  
  /// Crea un resultado fallido con mensaje personalizado
  static ValidationResult invalid(String message) => ValidationResult._(false, message);
  
  /// Verifica si la validación fue exitosa
  bool get isSuccess => isValid;
  
  /// Verifica si la validación falló
  bool get isFailure => !isValid;
}
```

---

## 📝 2. Sistema de Anotaciones

```dart
// lib/src/annotations/jwt_annotations.dart

/// Anotación para validación a nivel de controlador
/// Todos los endpoints del controlador heredan esta validación
class JWTController {
  /// Lista de validadores que se ejecutarán
  final List<JWTValidatorBase> validators;
  
  /// Si es true, TODOS los validadores deben pasar (AND logic)
  /// Si es false, al menos UNO debe pasar (OR logic)
  final bool requireAll;
  
  const JWTController(this.validators, {this.requireAll = true});
}

/// Anotación para validación a nivel de endpoint específico
/// Sobrescribe la validación del controlador si existe
class JWTEndpoint {
  /// Lista de validadores que se ejecutarán
  final List<JWTValidatorBase> validators;
  
  /// Si es true, TODOS los validadores deben pasar (AND logic)
  /// Si es false, al menos UNO debe pasar (OR logic)
  final bool requireAll;
  
  const JWTEndpoint(this.validators, {this.requireAll = true});
}

/// Anotación para marcar un endpoint como público (sin validación JWT)
/// Sobrescribe cualquier validación de controller o endpoint
class JWTPublic {
  const JWTPublic();
}
```

---

## 🛠️ 3. Validadores Personalizados de Ejemplo

```dart
// lib/src/validators/my_validators.dart

/// Validador para usuarios administradores
class MyAdminValidator extends JWTValidatorBase {
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // El desarrollador tiene control total sobre la estructura del JWT
    final userRole = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    // Lógica personalizada del desarrollador
    if (userRole != 'admin') {
      return ValidationResult.invalid('User must be an administrator');
    }
    
    if (!isActive) {
      return ValidationResult.invalid('Administrator account is inactive');
    }
    
    if (!permissions.contains('admin_access')) {
      return ValidationResult.invalid('Missing admin access permission');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
  
  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final userName = jwtPayload['name'] ?? 'Unknown';
    print('🔐 Admin access granted to: $userName');
  }
  
  @override
  void onValidationFailed(Request request, Map<String, dynamic> jwtPayload, String reason) {
    final userEmail = jwtPayload['email'] ?? 'unknown@example.com';
    print('🚫 Admin access denied for: $userEmail - Reason: $reason');
  }
}

/// Validador para operaciones financieras
class MyFinancialValidator extends JWTValidatorBase {
  final double minimumAmount;
  
  const MyFinancialValidator({this.minimumAmount = 0.0});
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // Estructura JWT completamente controlada por el desarrollador
    final userDepartment = jwtPayload['department'] as String?;
    final clearanceLevel = jwtPayload['clearance_level'] as int? ?? 0;
    final certifications = jwtPayload['certifications'] as List<dynamic>? ?? [];
    
    // Validación de departamento
    if (userDepartment != 'finance' && userDepartment != 'accounting') {
      return ValidationResult.invalid('Access restricted to financial departments');
    }
    
    // Validación de nivel de autorización
    if (clearanceLevel < 3) {
      return ValidationResult.invalid('Insufficient clearance level for financial operations');
    }
    
    // Validación de certificaciones
    if (!certifications.contains('financial_ops_certified')) {
      return ValidationResult.invalid('Financial operations certification required');
    }
    
    // Validación específica basada en el monto de la operación
    if (minimumAmount > 0) {
      final maxAmount = jwtPayload['max_transaction_amount'] as double? ?? 0.0;
      if (maxAmount < minimumAmount) {
        return ValidationResult.invalid('Transaction amount exceeds user authorization limit');
      }
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Financial operations access required';
  
  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final userId = jwtPayload['user_id'];
    final department = jwtPayload['department'];
    print('💰 Financial access granted to user $userId from $department department');
  }
}

/// Validador para departamentos específicos
class MyDepartmentValidator extends JWTValidatorBase {
  final List<String> allowedDepartments;
  final bool requireManagerLevel;
  
  const MyDepartmentValidator({
    required this.allowedDepartments,
    this.requireManagerLevel = false,
  });
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // Control total del desarrollador sobre campos JWT
    final userDepartment = jwtPayload['department'] as String?;
    final jobTitle = jwtPayload['job_title'] as String?;
    final employeeLevel = jwtPayload['employee_level'] as String?;
    
    // Validar departamento
    if (userDepartment == null || !allowedDepartments.contains(userDepartment)) {
      return ValidationResult.invalid(
        'Access restricted to: ${allowedDepartments.join(", ")} departments'
      );
    }
    
    // Validar nivel gerencial si es requerido
    if (requireManagerLevel) {
      if (employeeLevel != 'manager' && employeeLevel != 'director') {
        return ValidationResult.invalid('Management level access required');
      }
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Department access required';
}

/// Validador para horarios de trabajo
class MyBusinessHoursValidator extends JWTValidatorBase {
  final int startHour;
  final int endHour;
  final List<int> allowedWeekdays;
  
  const MyBusinessHoursValidator({
    this.startHour = 9,
    this.endHour = 17,
    this.allowedWeekdays = const [1, 2, 3, 4, 5], // Lunes a Viernes
  });
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    
    // Validar día de la semana
    if (!allowedWeekdays.contains(now.weekday)) {
      return ValidationResult.invalid('Access restricted to business days');
    }
    
    // Validar horario
    if (now.hour < startHour || now.hour >= endHour) {
      return ValidationResult.invalid('Access restricted to business hours ($startHour:00 - $endHour:00)');
    }
    
    // El JWT puede contener overrides específicos del usuario
    final hasAfterHoursAccess = jwtPayload['after_hours_access'] as bool? ?? false;
    if (hasAfterHoursAccess) {
      return ValidationResult.valid();
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Business hours access required';
}
```

---

## 🔍 4. Sistema de Reflexión Mejorado

```dart
// lib/src/core/enhanced_reflection_helper.dart
class EnhancedReflectionHelper extends ReflectionHelper {
  
  /// Detecta y procesa anotaciones JWT en controladores y endpoints
  static Future<List<Middleware>> createJWTValidationMiddleware(
    Type controllerType,
    String methodName,
  ) async {
    final middlewares = <Middleware>[];
    
    // Verificar anotación @JWTPublic primero (mayor prioridad)
    if (_hasJWTPublicAnnotation(controllerType, methodName)) {
      print('🔓 Public endpoint detected: $controllerType.$methodName - No JWT validation required');
      return middlewares; // Sin middleware de validación
    }
    
    // Obtener validadores del método (endpoint-level)
    final endpointValidators = _getJWTEndpointValidators(controllerType, methodName);
    
    // Si hay validadores a nivel de endpoint, usarlos (sobrescriben controller)
    if (endpointValidators != null) {
      print('🔐 Endpoint-level JWT validation: $controllerType.$methodName');
      middlewares.add(_createValidationMiddleware(endpointValidators.validators, endpointValidators.requireAll));
      return middlewares;
    }
    
    // Obtener validadores del controlador (controller-level)
    final controllerValidators = _getJWTControllerValidators(controllerType);
    
    if (controllerValidators != null) {
      print('🔐 Controller-level JWT validation: $controllerType.$methodName');
      middlewares.add(_createValidationMiddleware(controllerValidators.validators, controllerValidators.requireAll));
      return middlewares;
    }
    
    // Sin validación JWT configurada
    print('🔓 No JWT validation configured for: $controllerType.$methodName');
    return middlewares;
  }
  
  /// Verifica si un método tiene anotación @JWTPublic
  static bool _hasJWTPublicAnnotation(Type controllerType, String methodName) {
    // En implementación real, usar reflexión para detectar @JWTPublic
    // Aquí simulamos la detección
    return false;
  }
  
  /// Obtiene validadores de anotación @JWTEndpoint
  static JWTEndpointConfig? _getJWTEndpointValidators(Type controllerType, String methodName) {
    // En implementación real, usar reflexión para extraer @JWTEndpoint
    // Retorna null si no hay anotación
    return null;
  }
  
  /// Obtiene validadores de anotación @JWTController
  static JWTControllerConfig? _getJWTControllerValidators(Type controllerType) {
    // En implementación real, usar reflexión para extraer @JWTController
    // Retorna null si no hay anotación
    return null;
  }
  
  /// Crea middleware de validación JWT
  static Middleware _createValidationMiddleware(
    List<JWTValidatorBase> validators,
    bool requireAll,
  ) {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          // Obtener JWT del contexto (ya extraído por middleware anterior)
          final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
          
          if (jwtPayload == null) {
            print('🚫 JWT payload not found in request context');
            return Response.json(
              jsonEncode({
                'success': false,
                'error': {
                  'code': 'UNAUTHORIZED',
                  'message': 'JWT token required',
                  'status_code': 401,
                },
                'timestamp': DateTime.now().toIso8601String(),
              }),
              statusCode: 401,
              headers: {'Content-Type': 'application/json'},
            );
          }
          
          // Ejecutar validadores
          final validationResults = <ValidationResult>[];
          final failedReasons = <String>[];
          
          for (final validator in validators) {
            final result = validator.validate(request, jwtPayload);
            validationResults.add(result);
            
            if (result.isSuccess) {
              // Llamar callback de éxito
              validator.onValidationSuccess(request, jwtPayload);
            } else {
              // Llamar callback de falla
              final reason = result.errorMessage ?? validator.defaultErrorMessage;
              failedReasons.add(reason);
              validator.onValidationFailed(request, jwtPayload, reason);
            }
          }
          
          // Evaluar resultados según lógica AND/OR
          bool isAuthorized;
          String errorMessage;
          
          if (requireAll) {
            // Lógica AND: todos los validadores deben pasar
            isAuthorized = validationResults.every((result) => result.isSuccess);
            errorMessage = failedReasons.isNotEmpty 
              ? failedReasons.first 
              : 'Authorization failed';
          } else {
            // Lógica OR: al menos uno debe pasar
            isAuthorized = validationResults.any((result) => result.isSuccess);
            errorMessage = validationResults.every((result) => result.isFailure)
              ? (failedReasons.isNotEmpty ? failedReasons.join('; ') : 'Authorization failed')
              : 'Authorization failed';
          }
          
          if (!isAuthorized) {
            print('🚫 JWT validation failed: $errorMessage');
            return Response.json(
              jsonEncode({
                'success': false,
                'error': {
                  'code': 'FORBIDDEN',
                  'message': errorMessage,
                  'status_code': 403,
                  'details': {
                    'validation_mode': requireAll ? 'require_all' : 'require_any',
                    'validators_count': validators.length,
                    'failed_validations': failedReasons,
                  },
                },
                'timestamp': DateTime.now().toIso8601String(),
              }),
              statusCode: 403,
              headers: {'Content-Type': 'application/json'},
            );
          }
          
          print('✅ JWT validation successful');
          
          // Continuar con el handler
          return await innerHandler(request);
          
        } catch (e, stackTrace) {
          print('💥 JWT validation middleware error: $e');
          print('Stack trace: $stackTrace');
          
          return Response.json(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Authorization system error',
                'status_code': 500,
              },
              'timestamp': DateTime.now().toIso8601String(),
            }),
            statusCode: 500,
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }
}

/// Configuración de validadores a nivel de controlador
class JWTControllerConfig {
  final List<JWTValidatorBase> validators;
  final bool requireAll;
  
  JWTControllerConfig(this.validators, this.requireAll);
}

/// Configuración de validadores a nivel de endpoint
class JWTEndpointConfig {
  final List<JWTValidatorBase> validators;
  final bool requireAll;
  
  JWTEndpointConfig(this.validators, this.requireAll);
}
```

---

## 🌐 5. Middleware de Autenticación JWT

```dart
// lib/src/middleware/enhanced_auth_middleware.dart
class EnhancedAuthMiddleware {
  
  /// Middleware que extrae y valida JWT desde Authorization header
  static Middleware jwtExtractor({
    required String jwtSecret,
    List<String> excludePaths = const [],
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.requestedUri.path;
        
        // Saltar extracción para paths excluidos
        if (excludePaths.any((excludePath) => path.startsWith(excludePath))) {
          return await innerHandler(request);
        }
        
        try {
          // Obtener Authorization header
          final authHeader = request.headers['authorization'];
          
          if (authHeader == null || !authHeader.startsWith('Bearer ')) {
            print('🔐 No Bearer token found in Authorization header');
            
            // Agregar contexto vacío para endpoints que no requieren JWT
            final updatedRequest = request.change(
              context: {...request.context, 'jwt_payload': null}
            );
            
            return await innerHandler(updatedRequest);
          }
          
          // Extraer token
          final token = authHeader.substring(7);
          
          if (token.isEmpty) {
            print('🔐 Empty JWT token provided');
            return _unauthorizedResponse('Invalid JWT token format');
          }
          
          // Validar y decodificar JWT
          final jwtPayload = await _validateAndDecodeJWT(token, jwtSecret);
          
          if (jwtPayload == null) {
            print('🔐 JWT validation failed');
            return _unauthorizedResponse('Invalid or expired JWT token');
          }
          
          print('✅ JWT validated successfully for user: ${jwtPayload['user_id'] ?? 'unknown'}');
          
          // Agregar payload JWT al contexto del request
          final updatedRequest = request.change(
            context: {
              ...request.context,
              'jwt_payload': jwtPayload,
              'user_id': jwtPayload['user_id'],
              'user_email': jwtPayload['email'],
              'user_role': jwtPayload['role'],
            }
          );
          
          return await innerHandler(updatedRequest);
          
        } catch (e, stackTrace) {
          print('💥 JWT extraction error: $e');
          print('Stack trace: $stackTrace');
          
          return Response.json(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Authentication system error',
                'status_code': 500,
              },
              'timestamp': DateTime.now().toIso8601String(),
            }),
            statusCode: 500,
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }
  
  /// Valida y decodifica un JWT usando una librería real
  static Future<Map<String, dynamic>?> _validateAndDecodeJWT(
    String token, 
    String secret,
  ) async {
    try {
      // En implementación real, usar dart_jsonwebtoken o similar
      // Aquí simulamos la validación
      
      // Verificar formato JWT básico (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        print('🔐 Invalid JWT format: expected 3 parts, got ${parts.length}');
        return null;
      }
      
      // Decodificar payload (parte central)
      final payloadPart = parts[1];
      
      // Agregar padding si es necesario para base64
      String normalizedPayload = payloadPart;
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      
      final decodedBytes = base64Url.decode(normalizedPayload);
      final payloadJson = utf8.decode(decodedBytes);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      
      // Verificar expiración
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > exp) {
          print('🔐 JWT token expired');
          return null;
        }
      }
      
      // Verificar issued at
      final iat = payload['iat'] as int?;
      if (iat != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (iat > now) {
          print('🔐 JWT token used before valid');
          return null;
        }
      }
      
      // En implementación real, verificar signature con el secret
      // final isValidSignature = await _verifySignature(parts, secret);
      // if (!isValidSignature) return null;
      
      print('✅ JWT decoded successfully');
      return payload;
      
    } catch (e) {
      print('🔐 JWT decode error: $e');
      return null;
    }
  }
  
  /// Respuesta de error para autenticación fallida
  static Response _unauthorizedResponse(String message) {
    return Response.json(
      jsonEncode({
        'success': false,
        'error': {
          'code': 'UNAUTHORIZED',
          'message': message,
          'status_code': 401,
        },
        'timestamp': DateTime.now().toIso8601String(),
      }),
      statusCode: 401,
      headers: {'Content-Type': 'application/json'},
    );
  }
}
```

---

## 🚀 6. Ejemplos de Uso

### Controlador con Validación a Nivel de Controller

```dart
@Controller('/api/admin')
@JWTController([
  MyAdminValidator(),
  MyBusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true)
class AdminController extends BaseController {
  
  // Todos los endpoints heredan la validación del controlador
  
  @GET('/users')
  Future<Response> getAllUsers(Request request) async {
    // Este endpoint requiere:
    // 1. MyAdminValidator (rol admin + activo + permisos)
    // 2. MyBusinessHoursValidator (horario laboral)
    // Ambos deben pasar (requireAll: true)
    
    return jsonResponse({'users': []});
  }
  
  @DELETE('/users/<id>')
  Future<Response> deleteUser(Request request) async {
    // Misma validación que el controlador
    final userId = getRequiredParam(request, 'id');
    return jsonResponse({'deleted_user_id': userId});
  }
}
```

### Controlador con Validación Mixta

```dart
@Controller('/api/finance')
@JWTController([
  MyDepartmentValidator(
    allowedDepartments: ['finance', 'accounting'],
    requireManagerLevel: false,
  ),
])
class FinanceController extends BaseController {
  
  @GET('/reports')
  Future<Response> getReports(Request request) async {
    // Usa validación del controlador: acceso para dept. finance/accounting
    return jsonResponse({'reports': []});
  }
  
  @POST('/transactions')
  @JWTEndpoint([
    MyFinancialValidator(minimumAmount: 10000),
    MyDepartmentValidator(
      allowedDepartments: ['finance'],
      requireManagerLevel: true,
    ),
  ], requireAll: true)
  Future<Response> createTransaction(Request request) async {
    // Sobrescribe validación del controlador con:
    // 1. MyFinancialValidator (certificación + nivel + límite)
    // 2. MyDepartmentValidator (solo finance + nivel manager)
    // Ambos deben pasar
    
    return jsonResponse({'transaction_created': true});
  }
  
  @GET('/balance')
  @JWTPublic()
  Future<Response> getPublicBalance(Request request) async {
    // Endpoint público - sin validación JWT
    return jsonResponse({'public_balance': 'Available'});
  }
}
```

### Controlador con Lógica OR

```dart
@Controller('/api/support')
@JWTController([
  MyAdminValidator(),
  MyDepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // Lógica OR
class SupportController extends BaseController {
  
  @GET('/tickets')
  Future<Response> getTickets(Request request) async {
    // El usuario puede acceder si:
    // - Es admin (MyAdminValidator pasa) OR
    // - Pertenece a support/customer_service (MyDepartmentValidator pasa)
    
    return jsonResponse({'tickets': []});
  }
}
```

---

## 🔧 7. Configuración en ApiServer

```dart
// lib/src/core/api_server.dart (extensión)
class ApiServer {
  
  /// Configurar JWT authentication middleware
  void configureJWTAuth({
    required String jwtSecret,
    List<String> excludePaths = const ['/api/auth', '/api/public'],
  }) {
    // Middleware global para extraer JWT
    use(EnhancedAuthMiddleware.jwtExtractor(
      jwtSecret: jwtSecret,
      excludePaths: excludePaths,
    ));
    
    print('🔐 JWT authentication middleware configured');
    print('   Secret: ${jwtSecret.substring(0, 8)}...');
    print('   Excluded paths: ${excludePaths.join(', ')}');
  }
  
  /// Registrar controlador con validación JWT automática
  @override
  Future<void> registerController(Type controllerType) async {
    // Registrar rutas normalmente
    await super.registerController(controllerType);
    
    // Obtener métodos del controlador
    final methods = _getControllerMethods(controllerType);
    
    for (final methodName in methods) {
      // Crear middleware JWT específico para cada método
      final jwtMiddlewares = await EnhancedReflectionHelper
        .createJWTValidationMiddleware(controllerType, methodName);
      
      if (jwtMiddlewares.isNotEmpty) {
        // Aplicar middlewares JWT a la ruta específica
        final routePath = _getRoutePathForMethod(controllerType, methodName);
        for (final middleware in jwtMiddlewares) {
          useForPath(routePath, middleware);
        }
      }
    }
  }
}
```

---

## 🧪 8. Ejemplos de Testing

```bash
# Test de endpoint público
curl -X GET http://localhost:8080/api/finance/balance
# Respuesta: {"public_balance": "Available"}

# Test sin JWT (debería fallar)
curl -X GET http://localhost:8080/api/admin/users
# Respuesta: 401 Unauthorized

# Test con JWT válido pero sin permisos admin
curl -X GET http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
# Respuesta: 403 Forbidden - "User must be an administrator"

# Test con JWT válido y permisos admin
curl -X GET http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
# Respuesta: 200 OK - {"users": [...]}

# Test de endpoint con lógica OR
curl -X GET http://localhost:8080/api/support/tickets \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
# Pasa si el usuario es admin O pertenece a support/customer_service
```

---

## 📊 9. Estructura JWT Flexible

El sistema permite cualquier estructura JWT. Ejemplos:

```json
// JWT para usuario básico
{
  "user_id": "123",
  "email": "user@example.com",
  "role": "user",
  "active": true,
  "department": "sales",
  "permissions": ["read", "write"],
  "exp": 1704063600
}

// JWT para administrador financiero
{
  "user_id": "456",
  "email": "finance.manager@example.com",
  "role": "admin",
  "active": true,
  "department": "finance",
  "job_title": "Finance Manager",
  "employee_level": "manager",
  "clearance_level": 5,
  "certifications": ["financial_ops_certified", "compliance_certified"],
  "max_transaction_amount": 100000.0,
  "after_hours_access": true,
  "permissions": ["read", "write", "delete", "admin", "financial_ops"],
  "exp": 1704063600
}

// JWT personalizado para caso específico
{
  "user_id": "789",
  "email": "custom.user@example.com",
  "custom_field_1": "value1",
  "custom_field_2": {"nested": "value"},
  "business_logic_data": [1, 2, 3],
  "exp": 1704063600
}
```

---

## 🏆 Mejores Prácticas

### ✅ **DO's**
- ✅ Crear validadores específicos para cada caso de uso
- ✅ Usar Result Pattern para respuestas claras
- ✅ Implementar callbacks para logging y auditoría
- ✅ Combinar validadores con lógica AND/OR según necesidad
- ✅ Usar `@JWTPublic` para endpoints que no requieren auth
- ✅ Validar estructura JWT en validadores personalizados

### ❌ **DON'Ts**
- ❌ Asumir estructura fija del JWT
- ❌ Hardcodear valores en los validadores
- ❌ Ignorar los callbacks de validación
- ❌ Usar validación excesivamente compleja en un solo validador
- ❌ Exponer información sensible en mensajes de error
- ❌ Olvidar manejar casos edge en la validación

### 🔒 Seguridad
```dart
// Validar siempre la expiración del JWT
final exp = jwtPayload['exp'] as int?;
if (exp != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
  return ValidationResult.invalid('Token expired');
}

// No exponer información sensible en errores
return ValidationResult.invalid('Access denied'); // ✅ Genérico
// NO: ValidationResult.invalid('User john@example.com lacks admin role'); // ❌ Expone info
```

### 📝 Logging y Auditoría
```dart
@override
void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
  final userId = jwtPayload['user_id'];
  final endpoint = request.requestedUri.path;
  print('✅ [AUDIT] User $userId accessed $endpoint successfully');
}

@override
void onValidationFailed(Request request, Map<String, dynamic> jwtPayload, String reason) {
  final userId = jwtPayload['user_id'] ?? 'unknown';
  final endpoint = request.requestedUri.path;
  final ip = request.headers['x-forwarded-for'] ?? request.connectionInfo?.remoteAddress.address;
  print('🚫 [AUDIT] User $userId failed to access $endpoint from $ip - Reason: $reason');
}
```

---

**Resumen:** El sistema de validación JWT de api_kit proporciona máxima flexibilidad permitiendo a los desarrolladores crear validadores personalizados con control total sobre la estructura del JWT y la lógica de negocio. El JWT se extrae del request, se valida internamente con claves/secretos, y se procesan las anotaciones tanto a nivel de controlador como de endpoint para proporcionar autorización granular y extensible.

---

**👉 [Volver a: JWT Authentication →](10-jwt-authentication.md)**