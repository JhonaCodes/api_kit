# 🚀 api_kit - Simple REST API Framework

Simple, fast REST API framework with annotation-based routing for Dart. Perfect for MVPs and rapid prototyping.

## 🎯 Características Principales

- ✅ **Annotation-based routing** - `@Controller`, `@GET`, `@POST`, etc.
- ✅ **JWT Validation System** - Sistema completo de validación JWT con validadores personalizados
- ✅ **Built-in security** - CORS, rate limiting, security headers
- ✅ **Middleware system** - Pipeline de middleware configurable  
- ✅ **Error handling** - Manejo centralizado de errores con result pattern
- ✅ **Auto-registration** - Registro automático de controladores
- ✅ **Development-ready** - Configuraciones para desarrollo y producción

## 🔐 JWT Validation System

**Documentación completa**: [`docs/jwt-validation-system.md`](docs/jwt-validation-system.md)

Sistema avanzado de validación JWT con:

### Anotaciones Disponibles
- `@JWTController([validators], requireAll: bool)` - Validación a nivel de controlador
- `@JWTEndpoint([validators], requireAll: bool)` - Validación específica por endpoint
- `@JWTPublic()` - Endpoints públicos sin validación

### Validadores Personalizados
```dart
class AdminValidator extends JWTValidatorBase {
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    return role == 'admin' 
        ? ValidationResult.valid()
        : ValidationResult.invalid('Admin role required');
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}
```

### Ejemplo de Uso
```dart
@Controller('/api/admin')
@JWTController([
  AdminValidator(),
  BusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true) // Lógica AND: ambos validadores deben pasar
class AdminController extends BaseController {
  
  @GET('/users')
  Future<Response> getAllUsers(Request request) async {
    // Automáticamente validado por AdminValidator + BusinessHoursValidator
    return jsonResponse(jsonEncode({'users': [...]}));
  }
  
  @GET('/emergency')
  @JWTEndpoint([AdminValidator()]) // Sobrescribe: solo admin, sin horario
  Future<Response> emergencyAccess(Request request) async { ... }
  
  @GET('/status')
  @JWTPublic() // Público: sin validación JWT
  Future<Response> getStatus(Request request) async { ... }
}
```

### Configuración del Servidor
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  // Configurar JWT
  server.configureJWTAuth(
    jwtSecret: 'your-super-secret-jwt-key',
    excludePaths: ['/api/public', '/api/auth'],
  );
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [AdminController()],
  );
}
```

## 🏗️ Arquitectura Básica

### Controlador Simple
```dart
@Controller('/api/users')
class UserController extends BaseController {
  
  @GET('/list')
  Future<Response> getUsers(Request request) async {
    return jsonResponse(jsonEncode({'users': ['John', 'Jane']}));
  }
  
  @POST('/create')
  Future<Response> createUser(Request request) async {
    final body = await request.readAsString();
    final userData = jsonDecode(body);
    return jsonResponse(jsonEncode({'created': userData['name']}));
  }
}
```

### Servidor Básico
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [UserController()],
  );
}
```

## 📚 Documentación Completa

### JWT System
- [`docs/jwt-validation-system.md`](docs/jwt-validation-system.md) - **Sistema JWT completo**
- [`lib/src/examples/jwt_complete_example.dart`](lib/src/examples/jwt_complete_example.dart) - Ejemplo completo funcionando

### Documentación General
- [`docs/15-jwt-validation-system.md`](docs/15-jwt-validation-system.md) - Especificación original del sistema JWT
- [`docs/README.md`](docs/README.md) - Índice completo de documentación

## 🛠️ Componentes Principales

### Validadores JWT
- `JWTValidatorBase` - Clase base para validadores personalizados
- `MyAdminValidator` - Validador de rol administrador
- `MyFinancialValidator` - Validador para operaciones financieras
- `MyDepartmentValidator` - Validador por departamento
- `MyBusinessHoursValidator` - Validador por horarios de trabajo

### Middleware System
- JWT extraction y validación
- Token blacklisting para logout
- Rate limiting y security headers
- Error handling centralizado
- Request logging y tracing

### Anotaciones
- `@Controller('/path')` - Definir controlador
- `@GET('/endpoint')`, `@POST('/endpoint')` - Métodos HTTP
- `@JWTController([validators])` - Validación JWT a nivel controlador
- `@JWTEndpoint([validators])` - Validación JWT específica
- `@JWTPublic()` - Endpoints públicos

## 🧪 Testing

### Generar JWT de Prueba
```dart
final adminToken = ExampleJWTs.adminToken();
final financeToken = ExampleJWTs.financeManagerToken();
final supportToken = ExampleJWTs.supportUserToken();
```

### Comandos cURL
```bash
# Endpoint público
curl -X GET http://localhost:8080/api/admin/status

# Endpoint protegido con JWT
curl -X GET http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer ${ADMIN_JWT_TOKEN}"
```

## 🚀 Getting Started

1. **Instalar dependencias**:
```yaml
dependencies:
  api_kit:
    path: ../api_kit
  shelf: ^1.4.0
  result_controller: ^1.2.0
```

2. **Crear controlador**:
```dart
@Controller('/api/hello')
class HelloController extends BaseController {
  @GET('/world')
  Future<Response> sayHello(Request request) async {
    return jsonResponse('{"message": "Hello World!"}');
  }
}
```

3. **Inicializar servidor**:
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  await server.start(
    host: '0.0.0.0', 
    port: 8080,
    controllerList: [HelloController()],
  );
}
```

## 🔧 Configuración

### Desarrollo
```dart
ServerConfig.development() // CORS abierto, logging verbose
```

### Producción  
```dart
ServerConfig.production() // CORS restrictivo, security headers
```

### Custom
```dart
ServerConfig(
  rateLimit: RateLimitConfig(requestsPerMinute: 1000),
  maxBodySize: 10 * 1024 * 1024, // 10MB
  cors: CORSConfig(allowOrigin: 'https://myapp.com'),
)
```

---

## 🎯 Flujo de Desarrollo Típico

1. **Crear validadores JWT personalizados** según tus necesidades
2. **Anotar controladores** con `@JWTController` para validación base
3. **Anotar endpoints específicos** con `@JWTEndpoint` para casos especiales
4. **Marcar endpoints públicos** con `@JWTPublic`
5. **Configurar servidor** con `configureJWTAuth()`
6. **Testing** con tokens JWT generados

El sistema está diseñado para ser **simple para MVPs** pero **escalable para producción**. 🚀