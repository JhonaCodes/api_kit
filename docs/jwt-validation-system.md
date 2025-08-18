# 🔐 JWT Validation System - api_kit

Sistema de validación JWT completo con anotaciones para control granular de autorización en endpoints REST.

## 🎯 Características Principales

- ✅ **Validadores personalizados** - Extiende `JWTValidatorBase` para lógica custom
- ✅ **Anotaciones flexibles** - `@JWTController`, `@JWTEndpoint`, `@JWTPublic`
- ✅ **Lógica AND/OR** - Combina múltiples validadores con `requireAll`
- ✅ **Estructura JWT libre** - El desarrollador controla completamente el payload
- ✅ **Validación jerárquica** - Endpoint sobrescribe Controller
- ✅ **Callbacks avanzados** - Success/failure hooks para logging/analytics
- ✅ **Integración completa** - Se integra automáticamente con `ApiServer`

## 🚀 Quick Start

### 1. Configurar JWT en el Servidor

```dart
import 'package:api_kit/api_kit.dart';

void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  // Configurar JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-super-secret-jwt-key-minimum-32-characters',
    excludePaths: ['/api/public', '/api/auth', '/health'],
  );
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [MyController()],
  );
}
```

### 2. Crear Validadores Personalizados

```dart
import 'package:api_kit/api_kit.dart';

class AdminValidator extends JWTValidatorBase {
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    
    if (role != 'admin') {
      return ValidationResult.invalid('Administrator role required');
    }
    
    if (!isActive) {
      return ValidationResult.invalid('Account is inactive');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Admin access required';
}

class DepartmentValidator extends JWTValidatorBase {
  final List<String> allowedDepartments;
  final bool requireManagerLevel;
  
  DepartmentValidator({
    required this.allowedDepartments,
    this.requireManagerLevel = false,
  });
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final department = jwtPayload['department'] as String?;
    final level = jwtPayload['employee_level'] as String?;
    
    if (department == null || !allowedDepartments.contains(department)) {
      return ValidationResult.invalid(
        'Access restricted to: ${allowedDepartments.join(", ")} departments'
      );
    }
    
    if (requireManagerLevel && level != 'manager' && level != 'director') {
      return ValidationResult.invalid('Management level access required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Department access required';
}
```

### 3. Usar Anotaciones en Controladores

```dart
@Controller('/api/admin')
@JWTController([
  AdminValidator(),
  BusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true) // AMBOS validadores deben pasar (AND logic)
class AdminController extends BaseController {
  
  // Hereda validación del controlador: Admin + Business Hours
  @GET('/users')
  Future<Response> getAllUsers(Request request) async {
    final users = await getUsersFromDatabase();
    return jsonResponse(jsonEncode({
      'success': true,
      'data': users,
      'message': 'Admin access granted',
    }));
  }
  
  // SOBRESCRIBE la validación del controlador
  @POST('/emergency')
  @JWTEndpoint([
    AdminValidator(), // Solo admin, sin horario business
  ])
  Future<Response> emergencyAction(Request request) async {
    // Solo requiere ser admin (ignora horario de business)
    return jsonResponse(jsonEncode({
      'success': true,
      'message': 'Emergency action executed',
    }));
  }
  
  // Endpoint público que sobrescribe CUALQUIER validación
  @GET('/status')
  @JWTPublic()
  Future<Response> getSystemStatus(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'system': 'admin-system',
    }));
  }
}

@Controller('/api/support')
@JWTController([
  AdminValidator(),
  DepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // Lógica OR: admin O departamento support
class SupportController extends BaseController {
  
  // Requiere: admin OR support department
  @GET('/tickets')
  Future<Response> getTickets(Request request) async {
    final tickets = await getTicketsFromDatabase();
    return jsonResponse(jsonEncode({
      'success': true,
      'data': tickets,
    }));
  }
}
```

## 📋 Anotaciones Disponibles

### `@JWTController([validators], requireAll: bool)`
**Validación a nivel de controlador** - Se aplica a TODOS los endpoints del controlador.

```dart
@JWTController([
  AdminValidator(),
  DepartmentValidator(allowedDepartments: ['finance']),
], requireAll: true) // Ambos validadores deben pasar
class FinanceController extends BaseController { ... }
```

### `@JWTEndpoint([validators], requireAll: bool)`
**Validación a nivel de endpoint** - SOBRESCRIBE la validación del controlador.

```dart
@POST('/high-value-transaction')
@JWTEndpoint([
  FinancialValidator(minimumAmount: 10000),
  ManagerValidator(),
], requireAll: true)
Future<Response> createHighValueTransaction(Request request) async { ... }
```

### `@JWTPublic()`
**Endpoint público** - Sin validación JWT. Tiene la MÁXIMA PRIORIDAD.

```dart
@GET('/health')
@JWTPublic()
Future<Response> healthCheck(Request request) async { ... }
```

## 🔧 Validadores Base

### `JWTValidatorBase`
Clase abstracta que deben extender todos los validadores personalizados:

```dart
abstract class JWTValidatorBase {
  /// Lógica principal de validación
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload);
  
  /// Mensaje de error por defecto
  String get defaultErrorMessage;
  
  /// Callback cuando validación es exitosa (opcional)
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {}
  
  /// Callback cuando validación falla (opcional)
  void onValidationFailed(Request request, Map<String, dynamic> jwtPayload, String reason) {}
}
```

### `ValidationResult`
Resultado de una validación:

```dart
// Validación exitosa
return ValidationResult.valid();

// Validación fallida con mensaje específico
return ValidationResult.invalid('Custom error message');
```

## 🎯 Lógica AND/OR

### Lógica AND (`requireAll: true`)
**TODOS** los validadores deben pasar:

```dart
@JWTController([
  AdminValidator(),
  BusinessHoursValidator(),
  DepartmentValidator(allowedDepartments: ['finance']),
], requireAll: true) // Usuario debe ser: admin + horario business + finance dept
```

### Lógica OR (`requireAll: false`)
**AL MENOS UNO** de los validadores debe pasar:

```dart
@JWTController([
  AdminValidator(),
  DepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // Usuario puede ser: admin OR support/customer_service
```

## 🏗️ Estructura JWT

El desarrollador tiene **control total** sobre la estructura del JWT payload:

```json
{
  "user_id": "123",
  "email": "user@company.com",
  "name": "John Doe",
  "role": "admin",
  "active": true,
  "department": "finance",
  "employee_level": "manager",
  "clearance_level": 5,
  "certifications": ["financial_ops_certified"],
  "max_transaction_amount": 100000.0,
  "permissions": ["read", "write", "admin"],
  "after_hours_access": true,
  "exp": 1735689600,
  "iat": 1735686000
}
```

**Campos obligatorios del sistema:**
- `exp` - Timestamp de expiración
- `iat` - Timestamp de emisión

**Todos los demás campos son libres** y definidos por tu aplicación.

## 📊 Prioridad de Validación

El sistema maneja validación jerárquica:

1. **`@JWTPublic()`** - MÁXIMA PRIORIDAD (sin validación)
2. **`@JWTEndpoint([validators])`** - Sobrescribe validación del controlador  
3. **`@JWTController([validators])`** - Validación por defecto del controlador

```dart
@Controller('/api/finance')
@JWTController([DepartmentValidator(allowedDepartments: ['finance'])])
class FinanceController extends BaseController {
  
  // Usa validación del controlador (finance department)
  @GET('/reports')
  Future<Response> getReports(Request request) async { ... }
  
  // SOBRESCRIBE con validación específica
  @POST('/transactions')
  @JWTEndpoint([FinancialValidator(minimumAmount: 10000)])
  Future<Response> createTransaction(Request request) async { ... }
  
  // SOBRESCRIBE eliminando toda validación
  @GET('/public-balance')
  @JWTPublic()
  Future<Response> getPublicBalance(Request request) async { ... }
}
```

## 🧪 Testing

### Generar JWT de Prueba

```dart
// Usar la clase de ejemplo para testing
class ExampleJWTs {
  static String adminToken() {
    final payload = {
      'user_id': 'admin123',
      'email': 'admin@company.com',
      'name': 'Admin User',
      'role': 'admin',
      'active': true,
      'permissions': ['admin_access', 'read', 'write'],
      'after_hours_access': true,
      'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    
    return _createMockJWT(payload);
  }
}
```

### Comandos de Prueba

```bash
# Endpoint público (sin JWT)
curl -X GET http://localhost:8080/api/finance/public-balance

# Endpoint protegido sin JWT (401 Unauthorized)
curl -X GET http://localhost:8080/api/admin/users

# Endpoint protegido con JWT válido
curl -X GET http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer ${ADMIN_JWT_TOKEN}"

# Endpoint con permisos insuficientes (403 Forbidden)
curl -X POST http://localhost:8080/api/finance/transactions \
  -H "Authorization: Bearer ${USER_JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"amount": 15000}'
```

## 🔒 Configuración de Seguridad

### Configuración del Servidor

```dart
server.configureJWTAuth(
  jwtSecret: Platform.environment['JWT_SECRET'] ?? 'fallback-secret',
  excludePaths: [
    '/api/auth',     // Endpoints de autenticación
    '/api/public',   // API pública
    '/health',       // Health checks
    '/metrics',      // Métricas de sistema
  ],
);
```

### Blacklist de Tokens

```dart
// Revocar token (logout)
server.blacklistToken(jwtToken);

// Limpiar tokens blacklisteados
server.clearTokenBlacklist();

// Ver cantidad de tokens revocados
print('Blacklisted tokens: ${server.blacklistedTokensCount}');
```

## 📚 Validadores de Ejemplo

La librería incluye validadores de ejemplo listos para usar:

- **`MyAdminValidator`** - Valida rol admin y estado activo
- **`MyFinancialValidator`** - Operaciones financieras con límites configurables  
- **`MyDepartmentValidator`** - Control por departamento y nivel gerencial
- **`MyBusinessHoursValidator`** - Restricción por horarios de trabajo

## 🎯 Casos de Uso Comunes

### Sistema Empresarial
```dart
@JWTController([
  AdminValidator(),
  BusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true)
```

### API Financiera
```dart
@JWTEndpoint([
  FinancialValidator(minimumAmount: 10000),
  DepartmentValidator(allowedDepartments: ['finance'], requireManagerLevel: true),
], requireAll: true)
```

### Soporte Multi-Role
```dart
@JWTController([
  AdminValidator(),
  DepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // OR logic
```

## 📖 Ejemplo Completo

Ver [`lib/src/examples/jwt_complete_example.dart`](../lib/src/examples/jwt_complete_example.dart) para implementación completa con:

- ✅ Servidor configurado con JWT
- ✅ Múltiples controladores con diferentes validaciones
- ✅ Ejemplos de tokens JWT
- ✅ Comandos de testing
- ✅ Validadores personalizados

---

## 🚀 Resumen

1. **Extiende `JWTValidatorBase`** para validadores personalizados
2. **Usa `@JWTController`** para validación a nivel de controlador  
3. **Usa `@JWTEndpoint`** para sobrescribir validación específica
4. **Usa `@JWTPublic`** para endpoints sin autenticación
5. **Controla lógica AND/OR** con el parámetro `requireAll`
6. **Estructura JWT libre** - define los campos que necesites
7. **Configura el servidor** con `configureJWTAuth()`

El sistema JWT de api_kit está diseñado para ser **flexible, extensible y production-ready**. 🔐