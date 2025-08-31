# 📚 api_kit - Documentación Completa por Anotaciones

¡Bienvenido a la documentación completa de **api_kit**! Esta documentación está organizada por anotaciones individuales con ejemplos de uso detallados y casos de uso prácticos.

## 🎯 ¿Por Qué Esta Documentación?

Esta documentación está diseñada para que **cada anotación tenga su propio archivo** con:
- ✅ **Explicación detallada** de qué hace y por qué usarla
- ✅ **Sintaxis completa** con todos los parámetros
- ✅ **Ejemplos prácticos** paso a paso
- ✅ **Casos de uso reales** con código completo
- ✅ **Mejores prácticas** y qué evitar
- ✅ **Combinaciones** con otras anotaciones

## 🆕 **MAJOR UPDATE**: Enhanced Parameters - Eliminación del Request Manual

### 🎯 **Nuevo en esta versión: Sin Request parameter!**

**api_kit** ahora soporta **enhanced parameters** que eliminan la necesidad del parámetro `Request request` en la mayoría de casos:

```dart
// ❌ ANTES - Verbose con Request manual
@Get(path: '/users')
Future<Response> getUsers(
  Request request,  // ← Manual extraction needed
  @QueryParam('page') int page,
) async {
  final method = request.method;        // Manual
  final allHeaders = request.headers;   // Manual
  final jwt = request.context['jwt_payload'];  // Manual
}

// ✅ AHORA - Declarativo sin Request
@Get(path: '/users')
@JWTEndpoint([MyValidator()])
Future<Response> getUsersEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 ALL params
  @RequestHeader.all() Map<String, String> allHeaders,      // 🆕 ALL headers  
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,  // 🆕 JWT directo
  @RequestMethod() String method,                           // 🆕 Method directo
  // 🎉 NO Request request needed!
) async {
  // Todo disponible directamente - sin extracciones manuales
}
```

### 🚀 **Nuevas Anotaciones Enhanced:**
- **`@RequestHeader.all()`** - Todos los headers como `Map<String, String>`
- **`@QueryParam.all()`** - Todos los query params como `Map<String, String>`
- **`@RequestMethod()`** - Método HTTP directo (GET, POST, etc.)
- **`@RequestPath()`** - Path de la request directo
- **`@RequestHost()`** - Host directo
- **`@RequestUrl()`** - URL completa como `Uri`
- **`@RequestContext()`** - Context específico o completo del request

### 🎯 **Beneficios Inmediatos:**
- ✅ **Menos boilerplate**: No más `Request request` obligatorio
- ✅ **Más declarativo**: Las anotaciones expresan exactamente qué necesitas  
- ✅ **Filtros dinámicos**: Captura parámetros que no conoces en desarrollo
- ✅ **Mejor debugging**: Acceso completo a todos los parámetros y headers
- ✅ **JWT mejorado**: No más `request.context['jwt_payload']` manual
- ✅ **Compatible**: El código existente sigue funcionando sin cambios

## 🚀 Inicio Rápido

### 1. Instalación
```yaml
dependencies:
  api_kit: ^0.0.5
```

### 2. Ejemplo Básico
```dart
@RestController(basePath: '/api/hello')
class HelloController extends BaseController {
  
  @Get(path: '/world')
  @JWTPublic()
  Future<Response> sayHello(Request request) async {
    return jsonResponse('{"message": "Hello World!"}');
  }
}

void main() async {
  final server = ApiServer(config: ServerConfig.development());
  await server.start(
    host: 'localhost', 
    port: 8080,
    controllerList: [HelloController()],
  );
}
```

### 3. Con JWT Authentication
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/profile')
  @JWTEndpoint([MyUserValidator()])
  Future<Response> getProfile(Request request) async {
    final jwt = request.context['jwt_payload'] as Map<String, dynamic>;
    return jsonResponse(jsonEncode({'user_id': jwt['user_id']}));
  }
}
```

---

## 📖 Documentación por Anotaciones

### 🌐 HTTP Methods - Anotaciones de Métodos HTTP

| Anotación | Propósito | Documentación Completa |
|-----------|-----------|----------------------|
| **`@Get`** | Endpoints GET para consultas | [`docs/annotations/get-annotation.md`](annotations/get-annotation.md) |
| **`@Post`** | Endpoints POST para creación | [`docs/annotations/post-annotation.md`](annotations/post-annotation.md) |
| **`@Put`** | Endpoints PUT para actualización completa | [`docs/annotations/put-annotation.md`](annotations/put-annotation.md) |
| **`@Patch`** | Endpoints PATCH para actualización parcial | [`docs/annotations/patch-annotation.md`](annotations/patch-annotation.md) |
| **`@Delete`** | Endpoints DELETE para eliminación | [`docs/annotations/delete-annotation.md`](annotations/delete-annotation.md) |

### 🏗️ Controllers - Anotaciones de Estructura

| Anotación | Propósito | Documentación Completa |
|-----------|-----------|----------------------|
| **`@RestController`** | Define controladores REST con basePath | [`docs/annotations/restcontroller-annotation.md`](annotations/restcontroller-annotation.md) |

### 📥 Parameters - Anotaciones de Parámetros

| Anotación | Propósito | Documentación Completa |
|-----------|-----------|----------------------|
| **`@PathParam`** | Captura parámetros de la URL (`/users/{id}`) | [`docs/annotations/pathparam-annotation.md`](annotations/pathparam-annotation.md) |
| **`@QueryParam`** | Captura query parameters (`?page=1&limit=10`) | [`docs/annotations/queryparam-annotation.md`](annotations/queryparam-annotation.md) |
| **`@RequestBody`** | Captura y parsea el cuerpo de la request | [`docs/annotations/requestbody-annotation.md`](annotations/requestbody-annotation.md) |
| **`@RequestHeader`** | Captura headers HTTP específicos | [`docs/annotations/requestheader-annotation.md`](annotations/requestheader-annotation.md) |
| **🆕 `@RequestHeader.all()`** | **Captura TODOS los headers como Map** | [`docs/annotations/enhanced-parameters-annotation.md#requestheaderall`](annotations/enhanced-parameters-annotation.md#requestheaderall) |
| **🆕 `@QueryParam.all()`** | **Captura TODOS los query params como Map** | [`docs/annotations/enhanced-parameters-annotation.md#queryparamall`](annotations/enhanced-parameters-annotation.md#queryparamall) |

### 🆕 Request Components - Nuevas Anotaciones de Request

| Anotación | Propósito | Documentación Completa |
|-----------|-----------|----------------------|
| **🆕 `@RequestMethod()`** | **Método HTTP (GET, POST, etc.) directamente** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestPath()`** | **Path de la request directamente** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestHost()`** | **Host del request directamente** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestUrl()`** | **URL completa como Uri directamente** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestContext()`** | **Context específico o completo del request** | [`docs/annotations/enhanced-parameters-annotation.md#request-context`](annotations/enhanced-parameters-annotation.md#request-context) |

### 🔐 JWT Security - Anotaciones de Autenticación

| Anotación | Propósito | Documentación Completa |
|-----------|-----------|----------------------|
| **`@JWTPublic`** | Marca endpoints como públicos (sin auth) | [`docs/annotations/jwt-annotations.md#jwtpublic`](annotations/jwt-annotations.md#jwtpublic---endpoint-público) |
| **`@JWTController`** | Aplica validación JWT a todo el controller | [`docs/annotations/jwt-annotations.md#jwtcontroller`](annotations/jwt-annotations.md#jwtcontroller---validación-a-nivel-de-controller) |
| **`@JWTEndpoint`** | Validación JWT específica por endpoint | [`docs/annotations/jwt-annotations.md#jwtendpoint`](annotations/jwt-annotations.md#jwtendpoint---validación-específica-de-endpoint) |

---

## 🎯 Casos de Uso Completos

### 📋 Casos de Uso Documentados

| Caso de Uso | Descripción | Documentación |
|-------------|-------------|---------------|
| **API CRUD Completa** | Sistema completo de productos con autenticación multinivel | [`docs/use-cases/complete-crud-api.md`](use-cases/complete-crud-api.md) |
| **Limitaciones del Framework** | Análisis de limitaciones actuales y evolución sugerida | [`docs/use-cases/framework-limitations.md`](use-cases/framework-limitations.md) |

---

## 🔧 Ejemplos por Complejidad

### 🟢 Básico - Primer Endpoint
```dart
@RestController(basePath: '/api')
class SimpleController extends BaseController {
  
  @Get(path: '/hello')
  @JWTPublic()
  Future<Response> hello(Request request) async {
    return jsonResponse('{"message": "Hello api_kit!"}');
  }
}
```
**→ Ver más en**: [`@Get`](annotations/get-annotation.md#ejemplo-básico)

### 🟡 Intermedio - Con Parámetros (Método Tradicional)
```dart
@Get(path: '/users/{userId}/posts')
Future<Response> getUserPosts(
  Request request,
  @PathParam('userId') String userId,
  @QueryParam('page', defaultValue: 1) int page,
  @QueryParam('limit', defaultValue: 10) int limit,
) async {
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'posts': [],
    'page': page,
    'limit': limit
  }));
}
```

### 🟡 Intermedio - Con Parámetros Mejorados (🆕 Nuevo)
```dart
@Get(path: '/users/{userId}/posts')
Future<Response> getUserPostsEnhanced(
  @PathParam('userId') String userId,
  @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 TODOS los query params
  @RequestMethod() String method,                        // 🆕 Método HTTP directo
  @RequestPath() String path,                           // 🆕 Path directo
) async {
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;
  
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'posts': [],
    'page': page,
    'limit': limit,
    'method': method,           // Sin request.method
    'path': path,               // Sin request.url.path
    'all_filters': allQueryParams.entries
      .where((e) => e.key.startsWith('filter_'))
      .map((e) => '${e.key}: ${e.value}')
      .toList(),
  }));
}
```
**→ Ver más en**: [`Enhanced Parameters`](annotations/enhanced-parameters-annotation.md)

### 🔴 Avanzado - Con JWT y Validación (Método Tradicional)
```dart
@Post(path: '/financial/transfer')
@JWTEndpoint([
  MyFinancialValidator(clearanceLevel: 3),
  MyBusinessHoursValidator(),
], requireAll: true)
Future<Response> createTransfer(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> transferData,
  @RequestHeader('X-Two-Factor-Token', required: true) String tfaToken,
) async {
  final jwt = request.context['jwt_payload'] as Map<String, dynamic>;
  // Lógica de transferencia...
  return jsonResponse(jsonEncode({'transfer_id': 'txn_123'}));
}
```

### 🔴 Avanzado - JWT Mejorado SIN Request Manual (🆕 Nuevo)
```dart
@Post(path: '/financial/transfer')
@JWTEndpoint([
  MyFinancialValidator(clearanceLevel: 3),
  MyBusinessHoursValidator(),
], requireAll: true)
Future<Response> createTransferEnhanced(
  @RequestBody() Map<String, dynamic> transferData,                     // Request body
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,              // 🆕 JWT directo
  @RequestHeader.all() Map<String, String> allHeaders,                  // 🆕 Todos los headers
  @RequestHeader('X-Two-Factor-Token') String tfaToken,                 // Header específico
  @RequestMethod() String method,                                       // 🆕 Método HTTP
  @RequestUrl() Uri fullUrl,                                           // 🆕 URL completa
  // 🎉 NO Request request needed!
) async {
  final userId = jwt['user_id'];        // Sin request.context['jwt_payload']
  final userAgent = allHeaders['user-agent'] ?? 'unknown';
  
  return jsonResponse(jsonEncode({
    'transfer_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
    'user_id': userId,
    'method': method,               // Sin request.method
    'url': fullUrl.toString(),      // Sin request.url
    'user_agent': userAgent,
    'two_factor_provided': tfaToken.isNotEmpty,
    'framework_improvement': 'No manual Request parameter needed!',
  }));
}
```
**→ Ver más en**: [`Enhanced Parameters`](annotations/enhanced-parameters-annotation.md), [JWT Annotations](annotations/jwt-annotations.md) y [Caso de Uso CRUD](use-cases/complete-crud-api.md)

---

## 🛠️ Configuración del Servidor

### Configuración Básica
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [YourController()],
  );
}
```

### Configuración con JWT
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());
  
  // Configurar JWT
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key',
    excludePaths: ['/api/public', '/health'],
  );
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [
      PublicController(),
      UserController(),
      AdminController(),
    ],
  );
}
```

---

## 🎨 Patrones de Diseño Comunes

### 1. **Endpoint Público Simple**
```dart
@Get(path: '/info')
@JWTPublic()
Future<Response> getInfo(Request request) async { ... }
```

### 2. **CRUD con Autenticación**
```dart
@RestController(basePath: '/api/products')
@JWTController([UserValidator()])
class ProductController extends BaseController {
  
  @Get(path: '') // Lista - hereda auth del controller
  @Post(path: '') // Crear - hereda auth del controller  
  @Put(path: '/{id}') // Actualizar - hereda auth del controller
  @Delete(path: '/{id}') 
  @JWTEndpoint([AdminValidator()]) // Delete requiere admin específico
}
```

### 3. **Validación Multinivel**
```dart
@JWTEndpoint([
  BasicUserValidator(),        // Debe ser usuario válido
  FinancialValidator(),       // Debe tener permisos financieros
  BusinessHoursValidator(),   // Solo en horario de oficina
], requireAll: true)          // TODOS deben pasar
```

### 4. **Content Negotiation**
```dart
@Get(path: '/report/{id}')
Future<Response> getReport(
  Request request,
  @PathParam('id') String reportId,
  @RequestHeader('Accept', defaultValue: 'application/json') String format,
) async {
  if (format.contains('application/pdf')) {
    return Response.ok(pdfData, headers: {'Content-Type': 'application/pdf'});
  }
  return jsonResponse(jsonEncode(reportData));
}
```

---

## ❓ FAQ y Limitaciones Conocidas

### ❓ ¿Por qué necesito `Request request` si ya tengo `@RequestBody`?

**Respuesta**: Es una limitación actual del framework. `@RequestBody` parsea el JSON automáticamente, pero aún necesitas `Request` para acceder al contexto JWT.

```dart
// Estado actual (necesario)
@Post(path: '/users')
Future<Response> createUser(
  Request request,  // ← Para JWT context
  @RequestBody() Map<String, dynamic> data, // ← Ya parseado
) async {
  final jwt = request.context['jwt_payload']; // Extracción manual
}

// Estado ideal (futuro)
@Post(path: '/users')
Future<Response> createUser(
  @RequestBody() Map<String, dynamic> data,
  @JWTPayload() Map<String, dynamic> jwt, // ← Inyectado automáticamente
) async {
  // Sin Request manual
}
```

### ❓ ¿Por qué necesito extraer JWT si ya usé `@JWTEndpoint`?

**Respuesta**: Otra limitación actual. Si `@JWTEndpoint([MyValidator()])` ya validó el JWT, debería estar disponible automáticamente.

```dart
// Estado actual (redundante)
@JWTEndpoint([MyUserValidator()]) // ← Ya validó el JWT aquí
Future<Response> updateUser(Request request) async {
  final jwt = request.context['jwt_payload']; // ← ¿Por qué extraer manualmente?
}

// Estado lógico (como debería ser)
@JWTEndpoint([MyUserValidator()]) // JWT validado automáticamente
Future<Response> updateUser(@RequestBody() Map<String, dynamic> data) async {
  // JWT disponible implícitamente porque la anotación lo garantiza
  final jwt = currentJWT; // O algún mecanismo automático
}
```

**→ Ver análisis completo**: [Limitaciones del Framework](use-cases/framework-limitations.md)

### ❓ ¿Los validadores JWT pueden acceder al request body?

**Respuesta**: Actualmente no. Los validadores solo tienen acceso a `Request` y `jwtPayload`. En el futuro podrían tener acceso a todo el contexto.

### ❓ ¿Cómo manejo errores de validación consistentemente?

**Respuesta**: Usa el patrón estándar de respuestas de error:

```dart
return Response.badRequest(body: jsonEncode({
  'error': 'Descripción del error',
  'validation_errors': ['Lista', 'de', 'errores'],
  'received_data': dataRecibida,
  'expected_format': 'Formato esperado'
}));
```

---

## 🚀 Siguientes Pasos

### Para Principiantes
1. **Leer**: [`@Get` annotation](annotations/get-annotation.md) - Endpoint más básico
2. **Leer**: [`@RestController`](annotations/restcontroller-annotation.md) - Organizar endpoints
3. **Practicar**: Crear un endpoint público simple
4. **Leer**: [JWT Annotations](annotations/jwt-annotations.md) - Añadir seguridad

### Para Usuarios Intermedios
1. **Leer**: [`@RequestBody`](annotations/requestbody-annotation.md) - Manejar datos POST/PUT
2. **Leer**: [`@QueryParam`](annotations/queryparam-annotation.md) - Filtros y paginación
3. **Practicar**: [Caso de Uso CRUD Completo](use-cases/complete-crud-api.md)

### Para Usuarios Avanzados
1. **Crear validadores JWT personalizados**
2. **Implementar sistemas de autenticación complejos**
3. **Optimizar performance y estructura**
4. **Contribuir al framework** basado en [limitaciones identificadas](use-cases/framework-limitations.md)

---

## 🤝 Contribuir a la Documentación

¿Encontraste algo poco claro? ¿Tienes un caso de uso interesante? ¿Identificaste limitaciones como las mencionadas en [`framework-limitations.md`](use-cases/framework-limitations.md)?

### Estructura de la Documentación
```
docs/
├── README.md                          # Este archivo - navegación principal
├── annotations/                       # Una anotación = Un archivo
│   ├── get-annotation.md
│   ├── post-annotation.md
│   ├── restcontroller-annotation.md
│   ├── pathparam-annotation.md
│   ├── queryparam-annotation.md
│   ├── requestbody-annotation.md
│   ├── requestheader-annotation.md
│   └── jwt-annotations.md
└── use-cases/                        # Casos de uso completos
    ├── complete-crud-api.md
    └── framework-limitations.md
```

Cada archivo sigue el mismo patrón:
- **Descripción** y propósito
- **Sintaxis** completa  
- **Ejemplos** paso a paso
- **Combinaciones** con otras anotaciones
- **Mejores prácticas**
- **Casos de uso reales**

---

## 📞 Soporte

- **Documentación del framework**: Esta documentación
- **Ejemplos en vivo**: Directorio `/example` del repositorio
- **Issues y bugs**: GitHub issues del repositorio api_kit
- **Limitaciones conocidas**: [`framework-limitations.md`](use-cases/framework-limitations.md)

---

**🚀 ¡Feliz codificación con api_kit!**

> Esta documentación está diseñada para crecer contigo: desde tu primer endpoint hasta APIs empresariales complejas con múltiples niveles de autenticación.