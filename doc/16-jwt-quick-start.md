# 🚀 JWT Quick Start Guide

## 📋 Resumen
El sistema JWT de api_kit proporciona validación flexible y extensible basada en anotaciones con control total del desarrollador sobre la estructura JWT.

## 🔧 Setup Básico

```dart
import 'package:api_kit/api_kit.dart';

void main() async {
  final server = ApiServer(config: ServerConfig());
  
  // 1. Configurar JWT
  server.configureJWTAuth(
    jwtSecret: 'your-secret-key',
    excludePaths: ['/api/public', '/api/auth'],
  );
  
  // 2. Registrar controladores
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [MyController()],
  );
}
```

## 🏗️ Crear Validadores Personalizados

```dart
class MyAdminValidator extends JWTValidatorBase {
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    if (jwtPayload['role'] != 'admin') {
      return ValidationResult.invalid('Admin role required');
    }
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Admin access required';
}
```

## 📝 Usar Anotaciones

### Controller Level (todos los endpoints heredan)
```dart
@Controller('/api/admin')
@JWTController([MyAdminValidator()])
class AdminController extends BaseController {
  @GET('/users')
  Future<Response> getUsers(Request request) async {
    // Requiere validador admin
  }
}
```

### Endpoint Level (sobrescribe controller)
```dart
@POST('/transactions')
@JWTEndpoint([MyFinanceValidator()], requireAll: true)
Future<Response> createTransaction(Request request) async {
  // Solo requiere validador financiero
}
```

### Endpoint Público
```dart
@GET('/health')
@JWTPublic('Health check')
Future<Response> health(Request request) async {
  // Sin validación JWT
}
```

## 🔍 Lógica AND/OR

```dart
// AND Logic: TODOS los validadores deben pasar
@JWTController([ValidatorA(), ValidatorB()], requireAll: true)

// OR Logic: AL MENOS UNO debe pasar  
@JWTController([ValidatorA(), ValidatorB()], requireAll: false)
```

## 📊 Estructura JWT Flexible

```json
{
  "user_id": "123",
  "role": "admin", 
  "department": "finance",
  "permissions": ["read", "write"],
  "custom_field": "any_value",
  "exp": 1704063600
}
```

## 🎯 Validadores Incluidos

- `MyAdminValidator` - Rol admin + activo + permisos
- `MyFinancialValidator` - Operaciones financieras con límites
- `MyDepartmentValidator` - Departamentos específicos + nivel
- `MyBusinessHoursValidator` - Horarios de trabajo
- `MyResourceValidator` - Permisos sobre recursos específicos

## ✅ Features

- ✅ **100% Developer Control** - Estructura JWT completamente personalizable
- ✅ **Result Pattern** - `ValidationResult.valid()` / `ValidationResult.invalid()`
- ✅ **Validación Jerárquica** - Controller-level y endpoint-level
- ✅ **Callbacks Opcionales** - `onValidationSuccess()` / `onValidationFailed()`
- ✅ **JWT Extraction** - Automático desde Authorization header
- ✅ **Token Blacklisting** - Para logout y revocación
- ✅ **Logging & Auditing** - Integrado con sistema de logs

## 🔥 Ejemplo Completo

Ver `lib/src/examples/jwt_example_usage.dart` para un ejemplo completo funcionando con:
- Múltiples controladores
- Diferentes validaciones
- Endpoints públicos y protegidos
- Testing examples con curl

## 📖 Documentación Completa

Ver `doc/15-jwt-validation-system.md` para documentación detallada del sistema.

---

**¡El sistema está listo para usar!** 🚀