# @Get - Anotación para Endpoints GET

## 📋 Descripción

La anotación `@Get` se utiliza para marcar métodos como endpoints que responden a peticiones HTTP GET. Es la anotación más utilizada para operaciones de consulta y recuperación de datos.

## 🎯 Propósito

- **Consultar recursos**: Obtener información sin modificar el estado del servidor
- **Listados y filtros**: Recuperar colecciones de datos con parámetros de búsqueda  
- **Endpoints públicos**: Información que no requiere autenticación por defecto
- **APIs de solo lectura**: Operaciones que no alteran datos

## 📝 Sintaxis

```dart
@Get({
  required String path,           // Ruta del endpoint (OBLIGATORIO)
  String? description,           // Descripción del endpoint
  int statusCode = 200,          // Código de respuesta por defecto
  bool requiresAuth = false,     // Si requiere autenticación
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Sí | - | Ruta relativa del endpoint (ej: `/users`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Descripción legible del propósito del endpoint |
| `statusCode` | `int` | ❌ No | `200` | Código de estado HTTP de respuesta exitosa |
| `requiresAuth` | `bool` | ❌ No | `false` | Indica si el endpoint requiere autenticación |

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/list')
  Future<Response> getUsers(Request request) async {
    return jsonResponse(jsonEncode({
      'users': ['John', 'Jane', 'Bob'],
      'total': 3
    }));
  }
}
```

#### Enhanced Approach - No Request Parameter Needed! ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/list')
  Future<Response> getUsersEnhanced() async {
    // Direct implementation without manual Request extraction
    return jsonResponse(jsonEncode({
      'users': ['John', 'Jane', 'Bob'],
      'total': 3,
      'message': 'Simplified implementation - no Request parameter needed!'
    }));
  }
}
```

### Ejemplo con Request Info

#### Traditional Approach - Manual Extractions
```dart
@Get(
  path: '/products', 
  description: 'Obtiene la lista completa de productos disponibles'
)
Future<Response> getProducts(Request request) async {
  // Manual extractions
  final method = request.method;
  final userAgent = request.headers['user-agent'];
  
  return jsonResponse(jsonEncode({
    'products': [],
    'method': method,
    'user_agent': userAgent
  }));
}
```

#### Enhanced Approach - Direct Injection
```dart
@Get(
  path: '/products', 
  description: 'Obtiene la lista completa de productos disponibles'
)
Future<Response> getProductsEnhanced(
  @RequestMethod() String method,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // Direct parameter injection - no manual extraction needed
  return jsonResponse(jsonEncode({
    'products': [],
    'method': method,                          // Direct injection
    'user_agent': headers['user-agent'],       // From headers map
    'all_headers_count': headers.length,       // Bonus: access to all headers
  }));
}
```

### Ejemplo con Parámetros Personalizados

#### Traditional Approach
```dart
@Get(
  path: '/status',
  description: 'Endpoint de health check del sistema',
  statusCode: 200,
  requiresAuth: false
)
Future<Response> healthCheck(Request request) async {
  final host = request.url.host;
  final path = request.url.path;
  
  return jsonResponse(jsonEncode({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,
    'path': path
  }));
}
```

#### Enhanced Approach
```dart
@Get(
  path: '/status',
  description: 'Endpoint de health check del sistema',
  statusCode: 200,
  requiresAuth: false
)
Future<Response> healthCheckEnhanced(
  @RequestHost() String host,
  @RequestPath() String path,
  @RequestUrl() Uri fullUrl,
) async {
  return jsonResponse(jsonEncode({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,           // Direct injection
    'path': path,           // Direct injection
    'full_url': fullUrl.toString(),  // Complete URL access
  }));
}
```

### Ejemplo con Parámetros de Path

#### Traditional Approach
```dart
@Get(path: '/users/{userId}')
Future<Response> getUserById(
  Request request,
  @PathParam('userId') String userId,
) async {
  final method = request.method;
  
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'name': 'John Doe',
    'email': 'john@example.com',
    'method': method
  }));
}
```

#### Enhanced Approach - Hybrid Parameters
```dart
@Get(path: '/users/{userId}')
Future<Response> getUserByIdEnhanced(
  @PathParam('userId') String userId,        // Keep specific path params
  @RequestMethod() String method,            // Direct method injection
) async {
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'name': 'John Doe',
    'email': 'john@example.com',
    'method': method,                        // No manual extraction
  }));
}
```

### Ejemplo con Query Parameters

#### Traditional Approach - Limited to Predefined Params
```dart
@Get(path: '/products')
Future<Response> getProductsWithFilters(
  Request request,
  @QueryParam('category', required: false) String? category,
  @QueryParam('page', defaultValue: 1) int page,
  @QueryParam('limit', defaultValue: 10) int limit,
) async {
  // Can't access additional query parameters not predefined
  return jsonResponse(jsonEncode({
    'products': [],
    'filters': {
      'category': category,
      'page': page, 
      'limit': limit
    }
  }));
}
```

#### Enhanced Approach - Unlimited Dynamic Filtering
```dart
@Get(path: '/products')
Future<Response> getProductsWithFiltersEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
) async {
  // Parse what you need, ignore the rest
  final category = allQueryParams['category'];
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;
  
  return jsonResponse(jsonEncode({
    'products': [],
    'filters': {
      'category': category,
      'page': page,
      'limit': limit,
      'all_params': allQueryParams,          // Bonus: see all parameters
      'total_filters': allQueryParams.length, // Dynamic filtering support
    }
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con JWT Authentication

#### Traditional Approach - Manual Context Extraction
```dart
@Get(path: '/profile', requiresAuth: true)
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(Request request) async {
  // Manual JWT extraction from context
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final userId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];
  
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'role': userRole,
    'profile': 'user profile data'
  }));
}
```

#### Enhanced Approach - Direct JWT Injection
```dart
@Get(path: '/profile', requiresAuth: true)
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfileEnhanced(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @RequestMethod() String method,
) async {
  // Direct JWT payload injection - no manual extraction needed!
  final userId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];
  
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'role': userRole,
    'profile': 'user profile data',
    'method': method,           // Bonus: direct method access
  }));
}
```

### Con Endpoint Público

#### Traditional Approach
```dart
@Get(path: '/public-info')
@JWTPublic() // Sobrescribe requiresAuth
Future<Response> getPublicInfo(Request request) async {
  final userAgent = request.headers['user-agent'];
  
  return jsonResponse(jsonEncode({
    'message': 'Esta información es pública',
    'user_agent': userAgent
  }));
}
```

#### Enhanced Approach
```dart
@Get(path: '/public-info')
@JWTPublic() // Sobrescribe requiresAuth
Future<Response> getPublicInfoEnhanced(
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  return jsonResponse(jsonEncode({
    'message': 'Esta información es pública',
    'user_agent': headers['user-agent'] ?? 'unknown',
    'host': host,
    'headers_count': headers.length,
  }));
}
```

### Ejemplo Completo Enhanced - GET con Todo
```dart
@Get(path: '/dashboard')
@JWTEndpoint([MyAdminValidator()])
Future<Response> getDashboardEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestUrl() Uri fullUrl,
) async {
  // Comprehensive access without manual Request parameter!
  final userId = jwtPayload['user_id'];
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  
  return jsonResponse(jsonEncode({
    'dashboard_data': 'admin dashboard content',
    'user_id': userId,
    'page': page,
    'method': method,
    'path': path,
    'host': host,
    'query_params_count': allQueryParams.length,
    'headers_count': allHeaders.length,
    'context_keys': fullContext.keys.toList(),
    'full_url': fullUrl.toString(),
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Usar rutas descriptivas**: `/products`, `/users/{id}`, `/categories/{categoryId}/products`
- **Incluir descripciones**: Especialmente para endpoints complejos
- **Manejar errores**: Devolver códigos de estado apropiados
- **Validar parámetros**: Verificar tipos y rangos de valores
- **Respuestas consistentes**: Usar formato JSON estándar
- **Preferir Enhanced Parameters**: Para mayor flexibilidad y menos boilerplate
- **Combinar enfoques**: Traditional para parámetros específicos, Enhanced para acceso completo

### ❌ Evitar
- **Rutas ambiguas**: `/data`, `/info`, `/get`
- **Modificar estado**: Los GET no deben cambiar datos
- **Parámetros obligatorios en query**: Usar PathParam para valores requeridos
- **Respuestas sin estructura**: Devolver strings planos o datos inconsistentes
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones por Escenario

#### Para APIs Estables con Parámetros Conocidos
```dart
// ✅ Traditional - Type-safe y validación automática
@Get(path: '/products')
Future<Response> getProducts(
  @QueryParam('page', defaultValue: 1) int page,
  @QueryParam('limit', defaultValue: 10) int limit,
) async { ... }
```

#### Para APIs Dinámicas o Filtros Flexibles
```dart
// ✅ Enhanced - Máxima flexibilidad
@Get(path: '/products/search')
Future<Response> searchProducts(
  @QueryParam.all() Map<String, String> filters,
) async {
  // Handle unlimited filter combinations
}
```

#### Para Desarrollo y Debug
```dart
// ✅ Enhanced - Visibilidad completa
@Get(path: '/debug/request')
Future<Response> debugRequest(
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
  @RequestContext.all() Map<String, dynamic> context,
) async {
  // Complete request visibility
}
```

#### Para APIs de Producción
```dart
// ✅ Hybrid - Mejor de ambos mundos
@Get(path: '/users')
Future<Response> getUsers(
  @QueryParam('page', defaultValue: 1) int page,        // Type-safe
  @QueryParam.all() Map<String, String> allFilters,    // Flexible
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct
) async { ... }
```

## 🔍 Casos de Uso Comunes

### 1. **Listado de recursos**

#### Traditional
```dart
@Get(path: '/products', description: 'Lista todos los productos')
Future<Response> listProducts(Request request) async { ... }
```

#### Enhanced ✨
```dart
@Get(path: '/products', description: 'Lista todos los productos')
Future<Response> listProductsEnhanced() async {
  // Direct implementation - no Request parameter needed
}
```

### 2. **Recurso por ID**

#### Traditional
```dart
@Get(path: '/products/{id}', description: 'Obtiene producto específico')  
Future<Response> getProduct(Request request, @PathParam('id') String id) async { ... }
```

#### Enhanced - Hybrid ✨
```dart
@Get(path: '/products/{id}', description: 'Obtiene producto específico')  
Future<Response> getProductEnhanced(@PathParam('id') String id) async {
  // Keep specific path params, remove Request parameter
}
```

### 3. **Búsqueda con filtros**

#### Traditional - Limited
```dart
@Get(path: '/products/search', description: 'Busca productos con filtros')
Future<Response> searchProducts(
  Request request,
  @QueryParam('q') String query,
  @QueryParam('category', required: false) String? category
) async { ... }
```

#### Enhanced - Unlimited Filters ✨
```dart
@Get(path: '/products/search', description: 'Busca productos con filtros dinámicos')
Future<Response> searchProductsEnhanced(
  @QueryParam.all() Map<String, String> allFilters,
) async {
  // Handle unlimited search criteria dynamically
  final query = allFilters['q'];
  final category = allFilters['category'];
  final minPrice = allFilters['min_price'];
  final maxPrice = allFilters['max_price'];
  final brand = allFilters['brand'];
  final color = allFilters['color'];
  // ... any other filters the client sends
}
```

### 4. **Endpoints de estado**

#### Traditional
```dart
@Get(path: '/health', description: 'Health check del servicio')
Future<Response> healthCheck(Request request) async { ... }
```

#### Enhanced - Comprehensive Health Check ✨
```dart
@Get(path: '/health', description: 'Health check del servicio')
Future<Response> healthCheckEnhanced(
  @RequestHost() String host,
  @RequestPath() String path,
  @RequestHeader.all() Map<String, String> headers,
) async {
  return jsonResponse(jsonEncode({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,
    'path': path,
    'user_agent': headers['user-agent'],
    'total_headers': headers.length,
  }));
}
```

### 5. **Recursos anidados**

#### Traditional
```dart
@Get(path: '/users/{userId}/orders', description: 'Órdenes de un usuario específico')
Future<Response> getUserOrders(
  Request request,
  @PathParam('userId') String userId
) async { ... }
```

#### Enhanced - With Filtering ✨
```dart
@Get(path: '/users/{userId}/orders', description: 'Órdenes de usuario con filtros')
Future<Response> getUserOrdersEnhanced(
  @PathParam('userId') String userId,
  @QueryParam.all() Map<String, String> filters,
  @RequestMethod() String method,
) async {
  final status = filters['status'];          // Optional filter
  final dateFrom = filters['date_from'];     // Optional filter
  final dateTo = filters['date_to'];         // Optional filter
  
  return jsonResponse(jsonEncode({
    'user_id': userId,
    'orders': [],  // Filtered results
    'applied_filters': filters,
    'method': method,
  }));
}
```

### 6. **🆕 Caso de Uso Enhanced: Debug Endpoint**
```dart
@Get(path: '/debug/request', description: 'Complete request analysis')
Future<Response> debugRequestEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestUrl() Uri fullUrl,
) async {
  return jsonResponse(jsonEncode({
    'request_analysis': {
      'method': method,
      'path': path,
      'host': host,
      'full_url': fullUrl.toString(),
      'query_params': allQueryParams,
      'headers': allHeaders,
      'context_keys': fullContext.keys.toList(),
      'stats': {
        'total_query_params': allQueryParams.length,
        'total_headers': allHeaders.length,
        'context_entries': fullContext.length,
      }
    }
  }));
}
```

### 7. **🆕 Caso de Uso Enhanced: JWT Dashboard**
```dart
@Get(path: '/admin/dashboard', description: 'Admin dashboard con contexto completo')
@JWTEndpoint([MyAdminValidator()])
Future<Response> adminDashboardEnhanced(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @QueryParam.all() Map<String, String> filters,
  @RequestHost() String host,
) async {
  final adminId = jwtPayload['user_id'];
  final role = jwtPayload['role'];
  
  return jsonResponse(jsonEncode({
    'dashboard_data': 'admin content',
    'admin_info': {
      'id': adminId,
      'role': role,
    },
    'host': host,
    'active_filters': filters,
    'timestamp': DateTime.now().toIso8601String(),
  }));
}
```

## 🌐 URL Resultantes

Si tu controller tiene `basePath: '/api/v1'` y usas `@Get(path: '/products')`, la URL final será:
```
GET http://localhost:8080/api/v1/products
```

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Éxito | `200` | Recurso encontrado y devuelto |
| Recurso no encontrado | `404` | ID no existe |
| Parámetros inválidos | `400` | Query params mal formateados |
| Sin autorización | `401` | Token JWT inválido |
| Prohibido | `403` | Token válido pero sin permisos |
| Error del servidor | `500` | Error interno |

## 🔧 Configuración del Servidor

Los endpoints marcados con `@Get` se registran automáticamente cuando inicias el servidor:

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [UserController(), ProductController()],
  );
}
```

---

**Siguiente**: [Documentación de @Post](post-annotation.md) | **Anterior**: [Índice de Anotaciones](../README.md)