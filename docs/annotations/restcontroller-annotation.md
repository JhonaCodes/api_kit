# @RestController - Anotación para Controladores REST

## 📋 Descripción

La anotación `@RestController` se utiliza para marcar clases como controladores REST que agrupan múltiples endpoints relacionados. Define el path base y características comunes para todos los endpoints del controlador.

## 🎯 Propósito

- **Organizar endpoints**: Agrupar métodos relacionados bajo un path común
- **Definir estructura**: Establecer el basePath para todos los endpoints
- **Documentación automática**: Generar documentación API estructurada
- **Configuración centralizada**: Aplicar configuraciones a nivel de controlador

## 📝 Sintaxis

```dart
@RestController({
  String basePath = '',              // Path base del controlador
  String? description,              // Descripción del controlador
  List<String> tags = const [],     // Tags para documentación
  bool requiresAuth = false,        // Si todos los endpoints requieren auth por defecto
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `basePath` | `String` | ❌ No | `''` | Ruta base común para todos los endpoints del controlador |
| `description` | `String?` | ❌ No | `null` | Descripción del propósito del controlador |
| `tags` | `List<String>` | ❌ No | `[]` | Etiquetas para organización y documentación |
| `requiresAuth` | `bool` | ❌ No | `false` | Si todos los endpoints requieren autenticación por defecto |

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/list')  // URL final: /api/users/list
  Future<Response> getUsers(Request request) async {
    return jsonResponse(jsonEncode({'users': []}));
  }
  
  @Post(path: '/create')  // URL final: /api/users/create
  Future<Response> createUser(Request request) async {
    return jsonResponse(jsonEncode({'message': 'User created'}));
  }
  
  @Get(path: '/{id}')  // URL final: /api/users/{id}
  Future<Response> getUserById(
    Request request,
    @PathParam('id') String userId,
  ) async {
    return jsonResponse(jsonEncode({'user_id': userId}));
  }
}
```

#### Enhanced Approach - No Request Parameter Needed! ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/list')  // URL final: /api/users/list
  Future<Response> getUsersEnhanced() async {
    // Direct implementation without Request parameter
    return jsonResponse(jsonEncode({
      'users': [],
      'enhanced': true,
    }));
  }
  
  @Post(path: '/create')  // URL final: /api/users/create
  Future<Response> createUserEnhanced(
    @RequestBody() Map<String, dynamic> userData,  // Direct body injection
    @RequestHost() String host,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'User created - Enhanced!',
      'user': userData,
      'created_on_host': host,
    }));
  }
  
  @Get(path: '/{id}')  // URL final: /api/users/{id}
  Future<Response> getUserByIdEnhanced(
    @PathParam('id') String userId,
    @RequestMethod() String method,
  ) async {
    return jsonResponse(jsonEncode({
      'user_id': userId,
      'method': method,
      'enhanced': true,
    }));
  }
}
```

### Ejemplo con Descripción y Tags
```dart
@RestController(
  basePath: '/api/products',
  description: 'Gestión completa de productos del catálogo',
  tags: ['products', 'catalog', 'inventory'],
  requiresAuth: false // Los endpoints definen su propia auth
)
class ProductController extends BaseController {
  
  @Get(path: '/search')  // URL: /api/products/search
  @JWTPublic() // Endpoint público
  Future<Response> searchProducts(
    Request request,
    @QueryParam('q', required: true) String query,
    @QueryParam('category', required: false) String? category,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'Product search',
      'query': query,
      'category': category,
      'controller_tags': ['products', 'catalog', 'inventory']
    }));
  }
  
  @Post(path: '/create')  // URL: /api/products/create
  @JWTEndpoint([MyAdminValidator()]) // Solo admins
  Future<Response> createProduct(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'Product created',
      'product': productData
    }));
  }
  
  @Put(path: '/{productId}')  // URL: /api/products/{productId}
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> updateProduct(
    Request request,
    @PathParam('productId') String productId,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'Product updated',
      'product_id': productId,
      'data': productData
    }));
  }
}
```

### Ejemplo con Autenticación por Defecto

#### Traditional Approach - Manual JWT Extraction
```dart
@RestController(
  basePath: '/api/admin',
  description: 'Panel de administración - requiere permisos de admin',
  tags: ['admin', 'management'],
  requiresAuth: true // Todos los endpoints requieren auth por defecto
)
class AdminController extends BaseController {
  
  @Get(path: '/dashboard')  // Hereda requiresAuth = true
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getDashboard(Request request) async {
    return jsonResponse(jsonEncode({'dashboard': 'admin data'}));
  }
  
  @Get(path: '/users')  // Hereda requiresAuth = true  
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getAllUsers(Request request) async {
    return jsonResponse(jsonEncode({'users': []}));
  }
  
  @Get(path: '/health')  // Sobrescribe requiresAuth
  @JWTPublic() // Este endpoint es público a pesar del requiresAuth del controller
  Future<Response> adminHealthCheck(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'service': 'admin-panel'
    }));
  }
}
```

#### Enhanced Approach - Direct JWT & Context Injection ✨
```dart
@RestController(
  basePath: '/api/admin',
  description: 'Panel de administración - requiere permisos de admin',
  tags: ['admin', 'management'],
  requiresAuth: true // Todos los endpoints requieren auth por defecto
)
class AdminController extends BaseController {
  
  @Get(path: '/dashboard')  // Hereda requiresAuth = true
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getDashboardEnhanced(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct JWT
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    final adminId = jwt['user_id'];
    final adminRole = jwt['role'];
    
    return jsonResponse(jsonEncode({
      'dashboard': 'admin data',
      'admin_context': {
        'admin_id': adminId,
        'role': adminRole,
        'host': host,
        'user_agent': headers['user-agent'],
      },
      'enhanced': true,
    }));
  }
  
  @Get(path: '/users')  // Hereda requiresAuth = true  
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getAllUsersEnhanced(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    @QueryParam.all() Map<String, String> filters, // Dynamic filtering
  ) async {
    final adminId = jwt['user_id'];
    final page = int.tryParse(filters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(filters['limit'] ?? '10') ?? 10;
    
    return jsonResponse(jsonEncode({
      'users': [],
      'admin_id': adminId,
      'pagination': {'page': page, 'limit': limit},
      'applied_filters': filters,
      'enhanced': true,
    }));
  }
  
  @Get(path: '/health')  // Sobrescribe requiresAuth
  @JWTPublic() // Este endpoint es público a pesar del requiresAuth del controller
  Future<Response> adminHealthCheckEnhanced(
    @RequestHost() String host,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'service': 'admin-panel',
      'endpoint_info': {
        'host': host,
        'method': method,
        'path': path,
      },
      'enhanced': true,
    }));
  }
}
```

### Ejemplo de API Versioning
```dart
// Versión 1 de la API
@RestController(
  basePath: '/api/v1/orders',
  description: 'Sistema de órdenes - versión 1.0',
  tags: ['orders', 'v1', 'legacy']
)
class OrderControllerV1 extends BaseController {
  
  @Get(path: '/list')  // URL: /api/v1/orders/list
  Future<Response> getOrders(Request request) async {
    return jsonResponse(jsonEncode({
      'version': '1.0',
      'orders': []
    }));
  }
}

// Versión 2 de la API con mejoras
@RestController(
  basePath: '/api/v2/orders',
  description: 'Sistema de órdenes - versión 2.0 con nuevas funcionalidades',
  tags: ['orders', 'v2', 'current']
)
class OrderControllerV2 extends BaseController {
  
  @Get(path: '/list')  // URL: /api/v2/orders/list
  Future<Response> getOrders(
    Request request,
    @QueryParam('status', required: false) String? status,
    @QueryParam('page', defaultValue: 1) int page,
  ) async {
    return jsonResponse(jsonEncode({
      'version': '2.0',
      'orders': [],
      'pagination': {'page': page},
      'filters': {'status': status}
    }));
  }
  
  @Get(path: '/{orderId}/detailed')  // URL: /api/v2/orders/{orderId}/detailed
  Future<Response> getDetailedOrder(
    Request request,
    @PathParam('orderId') String orderId,
  ) async {
    return jsonResponse(jsonEncode({
      'version': '2.0',
      'order_id': orderId,
      'detailed_info': true
    }));
  }
}
```

### Ejemplo de Controlador Anidado/Jerárquico
```dart
@RestController(
  basePath: '/api/stores',
  description: 'Gestión de tiendas y sus recursos',
  tags: ['stores', 'multi-tenant']
)
class StoreController extends BaseController {
  
  @Get(path: '/list')  // URL: /api/stores/list
  Future<Response> getStores(Request request) async {
    return jsonResponse(jsonEncode({'stores': []}));
  }
  
  @Get(path: '/{storeId}/info')  // URL: /api/stores/{storeId}/info
  Future<Response> getStoreInfo(
    Request request,
    @PathParam('storeId') String storeId,
  ) async {
    return jsonResponse(jsonEncode({
      'store_id': storeId,
      'info': 'store details'
    }));
  }
}

// Controlador para productos de tienda específica
@RestController(
  basePath: '/api/stores/{storeId}/products',
  description: 'Productos específicos de cada tienda',
  tags: ['stores', 'products', 'nested']
)
class StoreProductController extends BaseController {
  
  @Get(path: '/list')  // URL: /api/stores/{storeId}/products/list
  Future<Response> getStoreProducts(
    Request request,
    @PathParam('storeId') String storeId,
  ) async {
    return jsonResponse(jsonEncode({
      'store_id': storeId,
      'products': []
    }));
  }
  
  @Post(path: '/create')  // URL: /api/stores/{storeId}/products/create
  Future<Response> createStoreProduct(
    Request request,
    @PathParam('storeId') String storeId,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'Product created for store',
      'store_id': storeId,
      'product': productData
    }));
  }
}
```

### Ejemplo con Middleware a Nivel de Controlador
```dart
@RestController(
  basePath: '/api/financial',
  description: 'Servicios financieros con alta seguridad',
  tags: ['financial', 'secure', 'compliance']
)
@JWTController([
  MyFinancialValidator(clearanceLevel: 2),
  MyBusinessHoursValidator(),
  MyAuditValidator(), // Log todas las acciones
], requireAll: true)
class FinancialController extends BaseController {
  
  @Get(path: '/balance')  // Hereda todos los validadores del controlador
  Future<Response> getBalance(Request request) async {
    // Solo ejecuta si pasa validación financiera + horas de negocio + auditoría
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    return jsonResponse(jsonEncode({
      'balance': 1000.0,
      'user_id': jwtPayload['user_id'],
      'timestamp': DateTime.now().toIso8601String()
    }));
  }
  
  @Post(path: '/transfer')  // Hereda validadores + validación específica
  @JWTEndpoint([
    MyTransferValidator(minimumAmount: 10.0),
  ]) // Se combina con los del controlador
  Future<Response> makeTransfer(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> transferData,
  ) async {
    // Requiere: financial + business hours + audit + transfer validation
    return jsonResponse(jsonEncode({
      'message': 'Transfer completed',
      'transfer': transferData
    }));
  }
}
```

## 🔗 Combinación con Otras Anotaciones

### Con JWT a Nivel de Controlador
```dart
@RestController(basePath: '/api/secure')
@JWTController([
  MyUserValidator(),
  MyActiveSessionValidator(),
], requireAll: true) // Aplica a todos los endpoints
class SecureController extends BaseController {
  
  @Get(path: '/profile')  // Hereda validación del controlador
  Future<Response> getProfile(Request request) async { ... }
  
  @Get(path: '/public-info')  
  @JWTPublic() // Sobrescribe la validación del controlador
  Future<Response> getPublicInfo(Request request) async { ... }
  
  @Post(path: '/sensitive')
  @JWTEndpoint([MyAdminValidator()]) // Se combina con validadores del controlador
  Future<Response> sensitiveOperation(Request request) async { ... }
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Usar basePath descriptivos**: `/api/users`, `/api/products`, `/api/orders`
- **Agrupar endpoints relacionados**: Todos los endpoints de un recurso en el mismo controlador
- **Incluir versioning**: `/api/v1/users`, `/api/v2/users` para diferentes versiones
- **Documentar el propósito**: Usar `description` para explicar qué hace el controlador
- **Usar tags organizacionalmente**: Para agrupar controladores en documentación
- **Preferir Enhanced Parameters**: En todos los endpoints para eliminar Request redundante
- **Combinar enfoques**: Traditional para validación, Enhanced para flexibilidad

### ❌ Evitar
- **BasePaths muy genéricos**: `/api`, `/data` sin especificidad
- **Mezclar recursos diferentes**: No poner endpoints de users y products en el mismo controlador
- **BasePaths muy largos**: Evitar rutas anidadas excesivamente profundas
- **Duplicar functionality**: Un recurso debe tener un controlador principal
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced por Tipo de Controller

#### Para Controllers Públicos
```dart
// ✅ Enhanced - Endpoints públicos con contexto opcional
@RestController(basePath: '/api/public')
class PublicController extends BaseController {
  
  @Get(path: '/info')
  @JWTPublic()
  Future<Response> getPublicInfo(
    @RequestHost() String host,
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    // Complete access without authentication
    return jsonResponse(jsonEncode({
      'public_data': 'available',
      'host': host,
      'user_agent': headers['user-agent'] ?? 'unknown',
    }));
  }
}
```

#### Para Controllers Autenticados
```dart
// ✅ Enhanced - JWT directo sin Request parameter
@RestController(basePath: '/api/secure', requiresAuth: true)
@JWTController([MyUserValidator()])
class SecureController extends BaseController {
  
  @Get(path: '/profile')
  Future<Response> getProfile(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    @RequestMethod() String method,
  ) async {
    final userId = jwt['user_id'];
    final userRole = jwt['role'];
    
    return jsonResponse(jsonEncode({
      'profile': 'user profile data',
      'user_id': userId,
      'role': userRole,
      'method': method,
    }));
  }
}
```

#### Para Controllers con Filtros Dinámicos
```dart
// ✅ Enhanced - Filtros ilimitados con QueryParam.all()
@RestController(basePath: '/api/data')
class DataController extends BaseController {
  
  @Get(path: '/search')
  Future<Response> searchData(
    @QueryParam.all() Map<String, String> allFilters,
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  ) async {
    // Handle unlimited search criteria dynamically
    return jsonResponse(jsonEncode({
      'results': [],
      'applied_filters': allFilters,
      'total_filters': allFilters.length,
      'user_id': jwt['user_id'],
    }));
  }
}
```

#### Para Controllers de API Versioning
```dart
// ✅ Enhanced - Versioning con contexto completo
@RestController(basePath: '/api/v2/advanced')
class AdvancedV2Controller extends BaseController {
  
  @Get(path: '/features')
  Future<Response> getAdvancedFeatures(
    @QueryParam.all() Map<String, String> options,
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    return jsonResponse(jsonEncode({
      'version': '2.0',
      'features': ['enhanced_params', 'dynamic_filtering', 'direct_jwt'],
      'client_options': options,
      'client_info': {
        'host': host,
        'user_agent': headers['user-agent'],
      },
    }));
  }
}
```

#### Para Controllers Multi-tenant
```dart
// ✅ Hybrid - Path params específicos + Enhanced flexibility
@RestController(basePath: '/api/tenants/{tenantId}')
class TenantController extends BaseController {
  
  @Get(path: '/resources')
  Future<Response> getTenantResources(
    @PathParam('tenantId') String tenantId,              // Type-safe tenant
    @QueryParam.all() Map<String, String> resourceFilters, // Dynamic filters
    @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct JWT
  ) async {
    final userId = jwt['user_id'];
    
    return jsonResponse(jsonEncode({
      'tenant_id': tenantId,
      'resources': [],
      'filters': resourceFilters,
      'requested_by': userId,
    }));
  }
}
```

## 🔍 Jerarquía de URLs

### Controlador Simple
```dart
@RestController(basePath: '/api/users')
// URLs resultantes:
// GET  /api/users/list
// POST /api/users/create  
// GET  /api/users/{id}
```

### Controlador Anidado
```dart
@RestController(basePath: '/api/stores/{storeId}/products')
// URLs resultantes:
// GET  /api/stores/{storeId}/products/list
// POST /api/stores/{storeId}/products/create
// PUT  /api/stores/{storeId}/products/{productId}
```

### Controlador con Versioning
```dart
@RestController(basePath: '/api/v2/analytics')
// URLs resultantes:
// GET  /api/v2/analytics/reports
// POST /api/v2/analytics/custom-report
// GET  /api/v2/analytics/dashboard
```

## 🌐 Registro en el Servidor

Los controladores se registran al iniciar el servidor:

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [
      UserController(),           // @RestController(basePath: '/api/users')
      ProductController(),        // @RestController(basePath: '/api/products')
      AdminController(),          // @RestController(basePath: '/api/admin')
      OrderControllerV1(),        // @RestController(basePath: '/api/v1/orders')
      OrderControllerV2(),        // @RestController(basePath: '/api/v2/orders')
    ],
  );
}
```

## 📊 Ejemplo de Estructura Completa

### Controlador Principal
```dart
@RestController(
  basePath: '/api/ecommerce/stores',
  description: 'Sistema completo de gestión de tiendas e-commerce',
  tags: ['ecommerce', 'stores', 'management']
)
class EcommerceStoreController extends BaseController {
  
  @Get(path: '/list')
  @JWTPublic()
  Future<Response> listStores(Request request) async { ... }
  
  @Post(path: '/create')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> createStore(Request request) async { ... }
  
  @Get(path: '/{storeId}')
  Future<Response> getStoreDetails(Request request, @PathParam('storeId') String storeId) async { ... }
  
  @Put(path: '/{storeId}')
  @JWTEndpoint([MyStoreOwnerValidator()])
  Future<Response> updateStore(Request request, @PathParam('storeId') String storeId) async { ... }
  
  @Delete(path: '/{storeId}')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> deleteStore(Request request, @PathParam('storeId') String storeId) async { ... }
}
```

### URLs Resultantes
```
GET    /api/ecommerce/stores/list
POST   /api/ecommerce/stores/create
GET    /api/ecommerce/stores/{storeId}
PUT    /api/ecommerce/stores/{storeId}
DELETE /api/ecommerce/stores/{storeId}
```

---

**Siguiente**: [Documentación de @Service](service-annotation.md) | **Anterior**: [Documentación de @Delete](delete-annotation.md)