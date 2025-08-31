# JWT Annotations - Sistema de Autenticación JWT

## 📋 Descripción

Las anotaciones JWT (`@JWTPublic`, `@JWTController`, `@JWTEndpoint`) forman el sistema de autenticación y autorización de `api_kit`. Permiten definir políticas de seguridad granulares a nivel de controlador y endpoint.

## 🎯 Propósito

- **Seguridad por capas**: Autenticación y autorización a nivel de controller y endpoint
- **Validadores personalizados**: Lógica de negocio específica para cada contexto
- **Flexibilidad**: Combinar múltiples validadores con lógica AND/OR
- **Endpoints públicos**: Marcar endpoints que no requieren autenticación

## 🏗️ Arquitectura del Sistema JWT

```
Request → JWT Middleware → Validators → Endpoint
                ↓
         [@JWTPublic] → Skip validation
         [@JWTController] → Apply to all endpoints  
         [@JWTEndpoint] → Override controller validation
```

## 📝 Anotaciones Disponibles

### 1. @JWTPublic - Endpoint Público

```dart
@JWTPublic()
```

**Propósito**: Marca un endpoint como público, sin validación JWT.
**Prioridad**: Máxima - sobrescribe cualquier validación de controller.

### 2. @JWTController - Validación a Nivel de Controller

```dart
@JWTController(
  List<JWTValidatorBase> validators,    // Lista de validadores
  {bool requireAll = true}              // Lógica AND (true) o OR (false)
)
```

**Propósito**: Aplica validación a todos los endpoints del controller.
**Herencia**: Los endpoints heredan esta validación automáticamente.

### 3. @JWTEndpoint - Validación Específica de Endpoint

```dart
@JWTEndpoint(
  List<JWTValidatorBase> validators,    // Lista de validadores
  {bool requireAll = true}              // Lógica AND (true) o OR (false)
)
```

**Propósito**: Sobrescribe la validación del controller para este endpoint específico.
**Prioridad**: Media - sobrescribe `@JWTController` pero no `@JWTPublic`.

## 🚀 Ejemplos de Uso

### @JWTPublic - Endpoints Públicos

#### Traditional Approach
```dart
@RestController(basePath: '/api/public')
class PublicController extends BaseController {
  
  @Get(path: '/health')
  @JWTPublic()  // No requiere autenticación
  Future<Response> healthCheck(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'api_kit'
    }));
  }
  
  @Get(path: '/info')
  @JWTPublic()  // Información pública
  Future<Response> getPublicInfo(Request request) async {
    return jsonResponse(jsonEncode({
      'app_name': 'My API',
      'version': '1.0.0',
      'documentation': 'https://api.example.com/docs',
      'support': 'support@example.com'
    }));
  }
  
  @Post(path: '/contact')
  @JWTPublic()  // Formulario de contacto público
  Future<Response> submitContact(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> contactData,
  ) async {
    
    // Validar datos del formulario
    final requiredFields = ['name', 'email', 'message'];
    final missingFields = requiredFields
        .where((field) => !contactData.containsKey(field) || 
                         contactData[field].toString().isEmpty)
        .toList();
    
    if (missingFields.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Required fields missing',
        'missing_fields': missingFields
      }));
    }
    
    // Procesar formulario de contacto
    final contactId = 'contact_${DateTime.now().millisecondsSinceEpoch}';
    
    return Response(201, body: jsonEncode({
      'message': 'Contact form submitted successfully',
      'contact_id': contactId,
      'status': 'pending_review'
    }), headers: {'Content-Type': 'application/json'});
  }
}
```

#### Enhanced Approach - Complete Context Without JWT ✨
```dart
@RestController(basePath: '/api/public')
class PublicController extends BaseController {
  
  @Get(path: '/health')
  @JWTPublic()  // No requiere autenticación
  Future<Response> healthCheckEnhanced(
    @RequestHost() String host,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'api_kit',
      'endpoint_info': {
        'host': host,
        'method': method,
        'path': path,
      },
      'enhanced': true,
    }));
  }
  
  @Get(path: '/info')
  @JWTPublic()  // Información pública
  Future<Response> getPublicInfoEnhanced(
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    return jsonResponse(jsonEncode({
      'app_name': 'My API',
      'version': '1.0.0',
      'documentation': 'https://api.example.com/docs',
      'support': 'support@example.com',
      'client_info': {
        'host': host,
        'user_agent': headers['user-agent'] ?? 'unknown',
        'accept_language': headers['accept-language'] ?? 'en',
      },
      'enhanced': true,
    }));
  }
  
  @Post(path: '/contact')
  @JWTPublic()  // Formulario de contacto público
  Future<Response> submitContactEnhanced(
    @RequestBody(required: true) Map<String, dynamic> contactData,
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    
    // Validar datos del formulario
    final requiredFields = ['name', 'email', 'message'];
    final missingFields = requiredFields
        .where((field) => !contactData.containsKey(field) || 
                         contactData[field].toString().isEmpty)
        .toList();
    
    if (missingFields.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Required fields missing',
        'missing_fields': missingFields
      }));
    }
    
    // Enhanced: Capture client context for better support
    final contactId = 'contact_${DateTime.now().millisecondsSinceEpoch}';
    final clientContext = {
      'user_agent': headers['user-agent'],
      'referer': headers['referer'],
      'host': host,
      'ip': headers['x-forwarded-for'] ?? headers['x-real-ip'],
    };
    
    return Response(201, body: jsonEncode({
      'message': 'Contact form submitted successfully',
      'contact_id': contactId,
      'status': 'pending_review',
      'client_context': clientContext,  // Enhanced context tracking
      'enhanced': true,
    }), headers: {'Content-Type': 'application/json'});
  }
}
```

### @JWTController - Validación a Nivel de Controller

#### Traditional Approach - Manual JWT Extraction
```dart
@RestController(basePath: '/api/admin')
@JWTController([
  MyAdminValidator(),              // Debe ser administrador
  MyActiveSessionValidator(),      // Sesión debe estar activa
], requireAll: true)               // Ambos validadores deben pasar
class AdminController extends BaseController {
  
  @Get(path: '/users')  // Hereda validación del controller
  Future<Response> getAllUsers(Request request) async {
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];
    
    return jsonResponse(jsonEncode({
      'message': 'All users retrieved',
      'requested_by': adminUser,
      'validation': 'admin + active_session',
      'users': [] // En implementación real, obtener de BD
    }));
  }
  
  @Post(path: '/users')  // Hereda validación del controller
  Future<Response> createUser(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> userData,
  ) async {
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];
    
    return Response(201, body: jsonEncode({
      'message': 'User created successfully',
      'created_by': adminUser,
      'user': userData,
      'validation_passed': ['admin', 'active_session']
    }), headers: {'Content-Type': 'application/json'});
  }
  
  @Get(path: '/health')
  @JWTPublic()  // Sobrescribe la validación del controller
  Future<Response> adminHealthCheck(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'service': 'admin-panel',
      'authentication': 'bypassed'
    }));
  }
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@RestController(basePath: '/api/admin')
@JWTController([
  MyAdminValidator(),              // Debe ser administrador
  MyActiveSessionValidator(),      // Sesión debe estar activa
], requireAll: true)               // Ambos validadores deben pasar
class AdminController extends BaseController {
  
  @Get(path: '/users')  // Hereda validación del controller
  Future<Response> getAllUsersEnhanced(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
    @QueryParam.all() Map<String, String> filters,  // Dynamic filtering
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    final adminUser = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    // Enhanced: Dynamic filtering capabilities
    final page = int.tryParse(filters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(filters['limit'] ?? '10') ?? 10;
    final search = filters['search'];
    
    return jsonResponse(jsonEncode({
      'message': 'All users retrieved - Enhanced!',
      'requested_by': adminUser,
      'admin_context': {
        'role': adminRole,
        'permissions': permissions,
        'permissions_count': permissions.length,
      },
      'filters': {
        'page': page,
        'limit': limit,
        'search': search,
        'total_filters': filters.length,
      },
      'client_info': {
        'user_agent': headers['user-agent'],
      },
      'validation': 'admin + active_session',
      'users': [], // En implementación real, obtener de BD con filtros
      'enhanced': true,
    }));
  }
  
  @Post(path: '/users')  // Hereda validación del controller
  Future<Response> createUserEnhanced(
    @RequestBody(required: true) Map<String, dynamic> userData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
    @RequestHost() String host,
    @RequestMethod() String method,
  ) async {
    final adminUser = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];
    
    return Response(201, body: jsonEncode({
      'message': 'User created successfully - Enhanced!',
      'created_by': adminUser,
      'admin_role': adminRole,
      'user': userData,
      'creation_context': {
        'host': host,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'validation_passed': ['admin', 'active_session'],
      'enhanced': true,
    }), headers: {'Content-Type': 'application/json'});
  }
  
  @Get(path: '/health')
  @JWTPublic()  // Sobrescribe la validación del controller
  Future<Response> adminHealthCheckEnhanced(
    @RequestHost() String host,
    @RequestPath() String path,
    @RequestMethod() String method,
  ) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'service': 'admin-panel',
      'authentication': 'bypassed',
      'endpoint_info': {
        'host': host,
        'path': path,
        'method': method,
      },
      'enhanced': true,
    }));
  }
}

// Validadores personalizados
class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    if (role != 'admin' || !permissions.contains('admin_access')) {
      return ValidationResult.invalid('Administrator access required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}

class MyActiveSessionValidator extends JWTValidatorBase {
  const MyActiveSessionValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final sessionActive = jwtPayload['session_active'] as bool? ?? false;
    final lastActivity = jwtPayload['last_activity'] as String?;
    
    if (!sessionActive) {
      return ValidationResult.invalid('Session is not active');
    }
    
    if (lastActivity != null) {
      final lastActiveTime = DateTime.tryParse(lastActivity);
      if (lastActiveTime != null) {
        final hoursSinceActivity = DateTime.now().difference(lastActiveTime).inHours;
        if (hoursSinceActivity > 24) {
          return ValidationResult.invalid('Session expired due to inactivity');
        }
      }
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Active session required';
}
```

### @JWTEndpoint - Validación Específica por Endpoint

```dart
@RestController(basePath: '/api/financial')
@JWTController([
  MyUserValidator(),               // Validación básica de usuario
], requireAll: true)
class FinancialController extends BaseController {
  
  @Get(path: '/balance')  // Solo validación de usuario (hereda del controller)
  Future<Response> getBalance(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    return jsonResponse(jsonEncode({
      'balance': 1000.0,
      'user_id': jwtPayload['user_id'],
      'validation_level': 'basic_user'
    }));
  }
  
  @Post(path: '/transfer')
  @JWTEndpoint([
    MyUserValidator(),             // Usuario válido
    MyFinancialValidator(minimumClearance: 2),  // Clearance financiero nivel 2
    MyBusinessHoursValidator(),    // Solo en horario de oficina
  ], requireAll: true)             // TODOS deben pasar
  Future<Response> makeTransfer(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> transferData,
  ) async {
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final userId = jwtPayload['user_id'];
    
    return Response(201, body: jsonEncode({
      'message': 'Transfer completed successfully',
      'transfer_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'from_user': userId,
      'amount': transferData['amount'],
      'validation_passed': ['user', 'financial_clearance_2', 'business_hours']
    }), headers: {'Content-Type': 'application/json'});
  }
  
  @Delete(path: '/transactions/{transactionId}')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 5),  // Solo clearance máximo
    MyAuditValidator(),        // Auditoría requerida
  ], requireAll: true)
  Future<Response> deleteTransaction(
    Request request,
    @PathParam('transactionId') String transactionId,
  ) async {
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    
    return jsonResponse(jsonEncode({
      'message': 'Transaction deleted successfully',
      'transaction_id': transactionId,
      'deleted_by': jwtPayload['user_id'],
      'validation_level': 'maximum_clearance_with_audit'
    }));
  }
  
  @Get(path: '/reports/summary')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 1),  // Clearance mínimo
    MyDepartmentValidator(allowedDepartments: ['finance', 'accounting']),
  ], requireAll: false)          // Cualquiera de los dos (OR logic)
  Future<Response> getFinancialSummary(Request request) async {
    
    return jsonResponse(jsonEncode({
      'summary': 'Financial summary data...',
      'validation_logic': 'OR - financial_clearance_1 OR department_finance_accounting'
    }));
  }
}

// Validadores financieros personalizados
class MyFinancialValidator extends JWTValidatorBase {
  final int minimumClearance;
  
  const MyFinancialValidator({this.minimumClearance = 1});
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final clearanceLevel = jwtPayload['financial_clearance'] as int? ?? 0;
    
    if (clearanceLevel < minimumClearance) {
      return ValidationResult.invalid(
        'Financial clearance level $minimumClearance required, current: $clearanceLevel'
      );
    }
    
    // Validar que el clearance no haya expirado
    final clearanceExpiry = jwtPayload['clearance_expiry'] as String?;
    if (clearanceExpiry != null) {
      final expiryDate = DateTime.tryParse(clearanceExpiry);
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        return ValidationResult.invalid('Financial clearance has expired');
      }
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Financial clearance level $minimumClearance required';
}

class MyBusinessHoursValidator extends JWTValidatorBase {
  const MyBusinessHoursValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekday = now.weekday >= 1 && now.weekday <= 5; // Lunes a Viernes
    final isBusinessHour = hour >= 9 && hour <= 17; // 9 AM a 5 PM
    
    if (!isWeekday || !isBusinessHour) {
      return ValidationResult.invalid(
        'Financial operations only allowed during business hours (Mon-Fri, 9 AM - 5 PM)'
      );
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Operation only allowed during business hours';
}

class MyDepartmentValidator extends JWTValidatorBase {
  final List<String> allowedDepartments;
  
  const MyDepartmentValidator({required this.allowedDepartments});
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userDepartment = jwtPayload['department'] as String?;
    
    if (userDepartment == null || !allowedDepartments.contains(userDepartment)) {
      return ValidationResult.invalid(
        'Access restricted to departments: ${allowedDepartments.join(', ')}'
      );
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Department access required';
}

class MyAuditValidator extends JWTValidatorBase {
  const MyAuditValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // En implementación real, registrar en sistema de auditoría
    final userId = jwtPayload['user_id'];
    final action = _extractActionFromRequest(request);
    
    // Simular registro de auditoría
    _logAuditEvent(userId, action, request);
    
    return ValidationResult.valid();
  }
  
  String _extractActionFromRequest(Request request) {
    final method = request.method;
    final path = request.requestedUri.path;
    return '$method $path';
  }
  
  void _logAuditEvent(String userId, String action, Request request) {
    // En implementación real, guardar en base de datos de auditoría
    print('AUDIT: User $userId performed action: $action at ${DateTime.now()}');
  }
  
  @override
  String get defaultErrorMessage => 'Audit logging failed';
}
```

### Ejemplo Complejo: Múltiples Niveles de Validación

```dart
@RestController(basePath: '/api/enterprise')
@JWTController([
  MyEmployeeValidator(),           // Debe ser empleado válido
  MyCompanyValidator(),           // Debe pertenecer a la empresa
], requireAll: true)
class EnterpriseController extends BaseController {
  
  @Get(path: '/dashboard')  // Solo validación de empleado + empresa
  Future<Response> getDashboard(Request request) async {
    return jsonResponse(jsonEncode({
      'dashboard': 'employee dashboard data',
      'validation': 'employee + company'
    }));
  }
  
  @Get(path: '/hr/employees')
  @JWTEndpoint([
    MyEmployeeValidator(),
    MyHRValidator(),               // Debe ser de RRHH
    MyPrivacyValidator(level: 'high'),  // Alto nivel de privacidad
  ], requireAll: true)
  Future<Response> getHREmployees(Request request) async {
    return jsonResponse(jsonEncode({
      'employees': 'HR employee data',
      'validation': 'employee + hr + high_privacy'
    }));
  }
  
  @Post(path: '/finance/budget')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 3),
    MyManagerValidator(minimumLevel: 2),  // Manager nivel 2+
    MyBudgetValidator(maxAmount: 100000), // Límite de presupuesto
  ], requireAll: true)
  Future<Response> createBudget(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> budgetData,
  ) async {
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    
    return Response(201, body: jsonEncode({
      'message': 'Budget created successfully',
      'budget': budgetData,
      'created_by': jwtPayload['user_id'],
      'validation': 'financial_3 + manager_2 + budget_limit'
    }), headers: {'Content-Type': 'application/json'});
  }
  
  @Get(path: '/public/company-info')
  @JWTPublic()  // Información pública de la empresa
  Future<Response> getCompanyInfo(Request request) async {
    return jsonResponse(jsonEncode({
      'company_name': 'Enterprise Corp',
      'founded': '2010',
      'industry': 'Technology',
      'authentication': 'not_required'
    }));
  }
}
```

## 🔄 Flujo de Validación JWT

### Orden de Precedencia
1. **@JWTPublic** - Máxima prioridad, salta toda validación
2. **@JWTEndpoint** - Sobrescribe validación del controller
3. **@JWTController** - Validación por defecto para todos los endpoints
4. **Sin anotación** - Usa configuración del servidor

### Proceso de Validación
```
1. Request llega al endpoint
2. ¿Tiene @JWTPublic? → Sí: Permitir acceso
3. ¿Tiene @JWTEndpoint? → Sí: Usar esos validadores
4. ¿Controller tiene @JWTController? → Sí: Usar esos validadores
5. Ejecutar validadores según requireAll (AND/OR)
6. ¿Todos pasan? → Sí: Permitir acceso / No: Denegar
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Usar @JWTPublic solo cuando sea necesario**: Para endpoints verdaderamente públicos
- **Aplicar validación granular**: Diferentes validadores para diferentes niveles de acceso
- **Crear validadores específicos**: Para lógica de negocio específica de tu aplicación
- **Documentar validadores**: Explicar qué valida cada validador y por qué
- **Usar requireAll apropiadamente**: AND para validaciones estrictas, OR para flexibilidad
- **Preferir Enhanced Parameters**: Para acceso directo al JWT payload sin Request parameter
- **Combinar enfoques**: Traditional para validación robusta, Enhanced para contexto completo

### ❌ Evitar
- **Validadores demasiado genéricos**: Crear validadores específicos para cada caso de uso
- **No manejar errores específicos**: Proporcionar mensajes claros sobre por qué falló la validación
- **Validadores lentos**: Las validaciones deben ser rápidas para no afectar performance
- **No testear validadores**: Crear tests para cada validador personalizado
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced para JWT

#### Para Endpoints Públicos con Contexto
```dart
// ✅ Enhanced - Información completa sin JWT
@Get(path: '/public/status')
@JWTPublic()
Future<Response> getPublicStatus(
  @RequestHost() String host,
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
) async {
  // Complete context access without authentication
  return jsonResponse(jsonEncode({
    'status': 'operational',
    'host': host,
    'client_info': headers,
    'request_params': params,
  }));
}
```

#### Para JWT Controller con Filtros Dinámicos
```dart
// ✅ Enhanced - JWT directo + filtros ilimitados
@RestController(basePath: '/api/secure')
@JWTController([MyUserValidator()])
class SecureController extends BaseController {
  
  @Get(path: '/data')
  Future<Response> getSecureData(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    @QueryParam.all() Map<String, String> filters,
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    final userId = jwt['user_id'];
    final userRole = jwt['role'];
    
    return jsonResponse(jsonEncode({
      'secure_data': [],
      'user_context': {'id': userId, 'role': userRole},
      'applied_filters': filters,
      'client_info': headers,
    }));
  }
}
```

#### Para JWT Endpoint con Validación Compleja
```dart
// ✅ Enhanced - Múltiples validadores + contexto completo
@Post(path: '/sensitive')
@JWTEndpoint([
  MyAdminValidator(),
  MyFinancialValidator(clearance: 3),
  MyAuditValidator(),
])
Future<Response> sensitiveOperation(
  @RequestBody(required: true) Map<String, dynamic> data,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // Complete audit trail with Enhanced Parameters
  final auditData = {
    'user_id': jwt['user_id'],
    'operation': 'sensitive_operation',
    'data_keys': data.keys.toList(),
    'context_keys': fullContext.keys.toList(),
    'client_ip': headers['x-forwarded-for'],
    'user_agent': headers['user-agent'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Sensitive operation completed',
    'audit_id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
  }));
}
```

#### Para Debugging JWT Context
```dart
// ✅ Enhanced - Debugging completo del contexto JWT
@Get(path: '/debug/jwt')
@JWTEndpoint([MyAdminValidator()])
Future<Response> debugJWTContext(
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
) async {
  return jsonResponse(jsonEncode({
    'jwt_payload': jwt,
    'full_context_keys': fullContext.keys.toList(),
    'headers_count': headers.length,
    'query_params_count': params.length,
    'debug_info': {
      'jwt_user_id': jwt['user_id'],
      'jwt_keys': jwt.keys.toList(),
      'context_size': fullContext.length,
    }
  }));
}
```

## 🔍 Ejemplos de Validadores Personalizados

### Validador de Rol Simple
```dart
class RoleValidator extends JWTValidatorBase {
  final String requiredRole;
  
  const RoleValidator(this.requiredRole);
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userRole = jwtPayload['role'] as String?;
    
    if (userRole != requiredRole) {
      return ValidationResult.invalid('Role $requiredRole required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Role $requiredRole required';
}
```

### Validador de Permisos Múltiples
```dart
class PermissionsValidator extends JWTValidatorBase {
  final List<String> requiredPermissions;
  final bool requireAll;
  
  const PermissionsValidator(this.requiredPermissions, {this.requireAll = true});
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userPermissions = (jwtPayload['permissions'] as List<dynamic>?)
        ?.cast<String>() ?? [];
    
    if (requireAll) {
      final missingPermissions = requiredPermissions
          .where((perm) => !userPermissions.contains(perm))
          .toList();
      
      if (missingPermissions.isNotEmpty) {
        return ValidationResult.invalid(
          'Missing permissions: ${missingPermissions.join(', ')}'
        );
      }
    } else {
      final hasAnyPermission = requiredPermissions
          .any((perm) => userPermissions.contains(perm));
      
      if (!hasAnyPermission) {
        return ValidationResult.invalid(
          'At least one of these permissions required: ${requiredPermissions.join(', ')}'
        );
      }
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Insufficient permissions';
}
```

## 🌐 Configuración del Servidor JWT

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());
  
  // Configurar JWT
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key-here',
    excludePaths: ['/api/public', '/health'], // Paths siempre públicos
  );
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [
      PublicController(),
      AdminController(),
      FinancialController(),
      EnterpriseController(),
    ],
  );
}
```

## 📊 Códigos de Respuesta JWT

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Token faltante | `401` | Unauthorized - No JWT token provided |
| Token inválido | `401` | Unauthorized - Invalid JWT token |
| Token expirado | `401` | Unauthorized - JWT token expired |
| Validador falla | `403` | Forbidden - Insufficient permissions |
| Múltiples validadores fallan | `403` | Forbidden - Multiple validation failures |

---

**Siguiente**: [Casos de Uso - Documentación](../use-cases/README.md) | **Anterior**: [Documentación de @RequestHeader](requestheader-annotation.md)