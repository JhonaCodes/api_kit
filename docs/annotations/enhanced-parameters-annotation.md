# 🚀 Enhanced Parameters - "All" Mode Support

## 🎯 Nueva Funcionalidad: Captura de Parámetros "All"

api_kit ahora soporta capturar **TODOS** los parámetros de un tipo sin especificar keys individuales, eliminando la necesidad del parámetro `Request request` en la mayoría de casos.

## 📋 Anotaciones Mejoradas

### 1. `@RequestHeader.all()` - Todos los Headers

```dart
/// ❌ ANTES - Solo headers específicos
@Get(path: '/endpoint')
Future<Response> oldWay(
  Request request,  // ← Necesario para headers
  @RequestHeader('Authorization') String auth,
  @RequestHeader('User-Agent') String userAgent,
) async {
  // Manual extraction para otros headers
  final allHeaders = request.headers;
}

/// ✅ AHORA - Todos los headers automáticamente
@Get(path: '/endpoint')
Future<Response> newWay(
  @RequestHeader.all() Map<String, String> allHeaders,  // ← TODOS los headers
  @RequestHeader('Authorization') String auth,          // ← Headers específicos aún funcionan
) async {
  // allHeaders contiene TODOS los headers HTTP
  final userAgent = allHeaders['user-agent'];
  final contentType = allHeaders['content-type'];
}
```

### 2. `@QueryParam.all()` - Todos los Query Parameters

```dart
/// ❌ ANTES - Solo parámetros específicos
@Get(path: '/search')
Future<Response> oldSearch(
  Request request,  // ← Necesario para query params
  @QueryParam('q') String query,
  @QueryParam('page') int page,
) async {
  // Manual extraction para otros params
  final allParams = request.url.queryParameters;
}

/// ✅ AHORA - Todos los query params automáticamente  
@Get(path: '/search')
Future<Response> newSearch(
  @QueryParam.all() Map<String, String> allQueryParams,  // ← TODOS los params
  @QueryParam('q') String query,                         // ← Específicos aún funcionan
) async {
  // allQueryParams contiene TODOS los query parameters
  final filters = allQueryParams.entries
    .where((entry) => entry.key.startsWith('filter_'))
    .toList();
}
```

## 🆕 Nuevas Anotaciones para Request Components

### Información del Request HTTP

```dart
@Get(path: '/inspect')
Future<Response> inspectRequest(
  @RequestMethod() String method,        // GET, POST, PUT, DELETE, etc.
  @RequestPath() String path,            // /api/inspect  
  @RequestHost() String host,            // localhost, api.example.com
  @RequestPort() int port,               // 8080, 443
  @RequestScheme() String scheme,        // http, https
  @RequestUrl() Uri fullUrl,             // URL completa como Uri
) async {
  return jsonResponse(jsonEncode({
    'method': method,      // No request.method
    'path': path,          // No request.url.path
    'host': host,          // No request.url.host
    'port': port,          // No request.url.port
    'scheme': scheme,      // No request.url.scheme
    'url': fullUrl.toString(),
  }));
}
```

### Context del Request

```dart
/// JWT endpoint SIN Request manual
@Get(path: '/profile')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,  // JWT específico
  @RequestContext.all() Map<String, dynamic> allContext,           // Todo el context
) async {
  // JWT disponible directamente, sin request.context['jwt_payload']
  final userId = jwtPayload['user_id'];
  return jsonResponse(jsonEncode({'user_id': userId}));
}
```

## 💡 Casos de Uso Completos

### Endpoint Completo SIN Request Manual

```dart
@RestController(basePath: '/api/enhanced')
class EnhancedController extends BaseController {
  
  @Post(path: '/complete-example')
  @JWTEndpoint([MyValidator()])
  Future<Response> completeExample(
    // ✅ Request body parsing automático
    @RequestBody() Map<String, dynamic> body,
    
    // ✅ TODOS los headers disponibles
    @RequestHeader.all() Map<String, String> allHeaders,
    
    // ✅ TODOS los query params disponibles  
    @QueryParam.all() Map<String, String> allQueryParams,
    
    // ✅ JWT payload directo (sin manual extraction)
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    
    // ✅ Información del request directa
    @RequestMethod() String method,
    @RequestPath() String path,
    @RequestUrl() Uri fullUrl,
    
    // 🎉 NO Request request needed!
  ) async {
    
    // Todo disponible directamente - sin extracciones manuales
    final userId = jwt['user_id'];
    final authHeader = allHeaders['authorization'];
    final debugMode = allQueryParams['debug'] == 'true';
    
    return jsonResponse(jsonEncode({
      'message': 'Complete request handling without manual Request parameter!',
      'user_id': userId,
      'method': method,
      'path': path,
      'has_auth': authHeader != null,
      'debug_mode': debugMode,
      'request_body': body,
    }));
  }
}
```

### Inspección Completa de Request

```dart
@Get(path: '/debug/request')
Future<Response> debugFullRequest(
  @RequestHeader.all() Map<String, String> allHeaders,
  @QueryParam.all() Map<String, String> allQueryParams, 
  @RequestContext.all() Map<String, dynamic> allContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestPort() int port,
  @RequestScheme() String scheme,
  @RequestUrl() Uri fullUrl,
) async {
  return jsonResponse(jsonEncode({
    'complete_request_debug': {
      'http_info': {
        'method': method,
        'path': path,
        'host': host,
        'port': port,
        'scheme': scheme,
        'full_url': fullUrl.toString(),
      },
      'headers': {
        'count': allHeaders.length,
        'all': allHeaders,
        'auth_headers': allHeaders.entries
          .where((e) => e.key.toLowerCase().contains('auth'))
          .map((e) => '${e.key}: ${e.value}')
          .toList(),
      },
      'query_params': {
        'count': allQueryParams.length,
        'all': allQueryParams,
        'filters': allQueryParams.entries
          .where((e) => e.key.startsWith('filter_'))
          .map((e) => '${e.key}: ${e.value}')
          .toList(),
      },
      'context': {
        'keys': allContext.keys.toList(),
        'has_jwt': allContext.containsKey('jwt_payload'),
        'middleware_data': allContext.entries
          .where((e) => e.key != 'jwt_payload')
          .map((e) => '${e.key}: ${e.value.runtimeType}')
          .toList(),
      },
    },
  }));
}
```

## 🎯 Comparación: Antes vs Después

### Endpoint JWT Típico

```dart
/// ❌ ANTES - Verbose y con extracciones manuales
@Post(path: '/api/users')
@JWTEndpoint([MyValidator()])
Future<Response> createUserOld(
  Request request,                                    // ← Requerido
  @RequestBody() Map<String, dynamic> userData,       // ← Parseado pero necesito Request
) async {
  // Extracciones manuales
  final jwt = request.context['jwt_payload'] as Map<String, dynamic>;  // ← Manual
  final method = request.method;                                       // ← Manual
  final allHeaders = request.headers;                                  // ← Manual
  final allQueryParams = request.url.queryParameters;                 // ← Manual
  
  final currentUserId = jwt['user_id'];
  // ... resto de lógica
}

/// ✅ DESPUÉS - Declarativo y directo
@Post(path: '/api/users')
@JWTEndpoint([MyValidator()])
Future<Response> createUserNew(
  @RequestBody() Map<String, dynamic> userData,                        // ← Body parseado
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,             // ← JWT directo
  @RequestHeader.all() Map<String, String> allHeaders,                 // ← Todos los headers
  @QueryParam.all() Map<String, String> allQueryParams,               // ← Todos los params
  @RequestMethod() String method,                                      // ← Método directo
  // NO Request request needed! 🎉
) async {
  // Acceso directo - sin extracciones manuales
  final currentUserId = jwt['user_id'];
  // ... resto de lógica
}
```

## 📚 Sintaxis Completa

### RequestHeader Mejorado

```dart
// Header específico (comportamiento actual)
@RequestHeader('Authorization') String authToken

// NUEVO: Todos los headers
@RequestHeader.all() Map<String, String> allHeaders
```

### QueryParam Mejorado

```dart
// Query param específico (comportamiento actual)  
@QueryParam('page') int page

// NUEVO: Todos los query parameters
@QueryParam.all() Map<String, String> allQueryParams
```

### Nuevas Anotaciones de Request

```dart
@RequestMethod() String method          // HTTP method
@RequestPath() String path              // Request path
@RequestHost() String host              // Request host
@RequestPort() int port                 // Request port  
@RequestScheme() String scheme          // http/https
@RequestUrl() Uri fullUrl               // Complete URL

@RequestContext('key') dynamic value    // Specific context value
@RequestContext.all() Map<String, dynamic> allContext  // All context
```

## ✅ Ventajas del Nuevo Sistema

1. **Menos Boilerplate**: No necesitas `Request request` en la mayoría de casos
2. **Más Declarativo**: Las anotaciones expresan exactamente qué necesitas
3. **Type-Safe**: Parámetros tipados automáticamente
4. **Mejor Testabilidad**: Parámetros inyectados son más fáciles de mockear
5. **Consistencia**: Mismo patrón para todos los componentes del request
6. **Compatibilidad**: El código existente sigue funcionando sin cambios

## 🔄 Migración

### Paso 1: Reemplazar Extracciones Manuales

```dart
// Antes
final allHeaders = request.headers;
final allQueryParams = request.url.queryParameters;
final jwt = request.context['jwt_payload'];

// Después - añadir parámetros de anotación
@RequestHeader.all() Map<String, String> allHeaders,
@QueryParam.all() Map<String, String> allQueryParams,
@RequestContext('jwt_payload') Map<String, dynamic> jwt,
```

### Paso 2: Eliminar Request Parameter

```dart
// Antes
Future<Response> endpoint(Request request, @RequestBody() Map data) async {

// Después  
Future<Response> endpoint(@RequestBody() Map data) async {
```

### Paso 3: Añadir Request Info Si Necesitas

```dart
// Antes
final method = request.method;
final path = request.url.path;

// Después
@RequestMethod() String method,
@RequestPath() String path,
```

## 🎯 Cuándo Usar Cada Anotación

| **Uso** | **Anotación** | **Ejemplo** |
|---------|---------------|-------------|
| **Header específico** | `@RequestHeader('key')` | `@RequestHeader('Authorization') String token` |
| **Todos los headers** | `@RequestHeader.all()` | `@RequestHeader.all() Map<String, String> headers` |
| **Query param específico** | `@QueryParam('key')` | `@QueryParam('page') int page` |
| **Todos los query params** | `@QueryParam.all()` | `@QueryParam.all() Map<String, String> params` |
| **JWT payload** | `@RequestContext('jwt_payload')` | `@RequestContext('jwt_payload') Map jwt` |
| **Todo el context** | `@RequestContext.all()` | `@RequestContext.all() Map context` |
| **Método HTTP** | `@RequestMethod()` | `@RequestMethod() String method` |
| **Path del request** | `@RequestPath()` | `@RequestPath() String path` |
| **Info del host** | `@RequestHost()` | `@RequestHost() String host` |
| **URL completa** | `@RequestUrl()` | `@RequestUrl() Uri url` |

---

**🚀 Con estas mejoras, api_kit elimina la necesidad del parámetro `Request request` en la mayoría de casos, creando un código más limpio y declarativo!**