# @Put - Anotación para Endpoints PUT

## 📋 Descripción

La anotación `@Put` se utiliza para marcar métodos como endpoints que responden a peticiones HTTP PUT. Es la anotación estándar para operaciones de actualización completa de recursos existentes.

## 🎯 Propósito

- **Actualización completa**: Reemplazar completamente un recurso existente
- **Operaciones idempotentes**: La misma operación produce el mismo resultado
- **Modificación con ID**: Actualizar recursos identificados por un ID específico
- **APIs de configuración**: Actualizar configuraciones o preferencias

## 📝 Sintaxis

```dart
@Put({
  required String path,           // Ruta del endpoint (OBLIGATORIO)
  String? description,           // Descripción del endpoint
  int statusCode = 200,          // Código de respuesta por defecto (OK)
  bool requiresAuth = true,      // Requiere autenticación por defecto
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Sí | - | Ruta relativa del endpoint (ej: `/users/{id}`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Descripción legible del propósito del endpoint |
| `statusCode` | `int` | ❌ No | `200` | Código de estado HTTP de respuesta exitosa |
| `requiresAuth` | `bool` | ❌ No | `true` | Indica si el endpoint requiere autenticación |

> **Nota**: PUT requiere autenticación por defecto (`requiresAuth = true`) ya que generalmente modifica recursos protegidos.

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach - Manual Body Parsing
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Put(path: '/{id}')
  Future<Response> updateUser(
    Request request,
    @PathParam('id') String userId,
  ) async {
    // Manual body parsing
    final body = await request.readAsString();
    final userData = jsonDecode(body);
    
    // Simular actualización
    final updatedUser = {
      'id': userId,
      'name': userData['name'],
      'email': userData['email'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    return jsonResponse(jsonEncode({
      'message': 'User updated successfully',
      'user': updatedUser
    }));
  }
}
```

#### Enhanced Approach - Direct Body Injection ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Put(path: '/{id}')
  Future<Response> updateUserEnhanced(
    @PathParam('id') String userId,
    @RequestBody() Map<String, dynamic> userData,  // Direct body injection
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    // No manual parsing needed!
    final updatedUser = {
      'id': userId,
      'name': userData['name'],
      'email': userData['email'],
      'updated_at': DateTime.now().toIso8601String(),
      'method_used': method,        // Direct access
      'endpoint_path': path,        // Direct access
      'enhanced': true,
    };
    
    return jsonResponse(jsonEncode({
      'message': 'User updated successfully - Enhanced!',
      'user': updatedUser
    }));
  }
}
```

### Ejemplo con RequestBody Tipado

#### Traditional Approach - Manual JWT Extraction
```dart
@Put(
  path: '/products/{productId}',
  description: 'Actualiza completamente un producto existente'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProduct(
  Request request,
  @PathParam('productId', description: 'ID único del producto') String productId,
  @RequestBody(required: true, description: 'Datos completos del producto') 
  Map<String, dynamic> productData,
) async {
  
  // Validaciones obligatorias para PUT (debe incluir todos los campos)
  final requiredFields = ['name', 'price', 'description', 'category', 'stock'];
  final missingFields = <String>[];
  
  for (final field in requiredFields) {
    if (!productData.containsKey(field) || productData[field] == null) {
      missingFields.add(field);
    }
  }
  
  if (missingFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'PUT requires all fields - missing fields',
      'missing_fields': missingFields,
      'required_fields': requiredFields,
      'hint': 'Use PATCH for partial updates'
    }));
  }
  
  // Validar tipos de datos
  if (productData['price'] is! num || productData['price'] <= 0) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Price must be a positive number',
      'received': productData['price']
    }));
  }
  
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Simular actualización completa
  final updatedProduct = {
    'id': productId,
    'name': productData['name'],
    'price': productData['price'],
    'description': productData['description'],
    'category': productData['category'],
    'stock': productData['stock'],
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': adminUser,
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'product': updatedProduct,
    'updated_fields': requiredFields.length,
  }));
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@Put(
  path: '/products/{productId}',
  description: 'Actualiza completamente un producto existente'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProductEnhanced(
  @PathParam('productId', description: 'ID único del producto') String productId,
  @RequestBody(required: true, description: 'Datos completos del producto') 
  Map<String, dynamic> productData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
  @RequestHost() String host,
) async {
  
  // Validaciones obligatorias para PUT (debe incluir todos los campos)
  final requiredFields = ['name', 'price', 'description', 'category', 'stock'];
  final missingFields = <String>[];
  
  for (final field in requiredFields) {
    if (!productData.containsKey(field) || productData[field] == null) {
      missingFields.add(field);
    }
  }
  
  if (missingFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'PUT requires all fields - missing fields',
      'missing_fields': missingFields,
      'required_fields': requiredFields,
      'hint': 'Use PATCH for partial updates'
    }));
  }
  
  // Validar tipos de datos
  if (productData['price'] is! num || productData['price'] <= 0) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Price must be a positive number',
      'received': productData['price']
    }));
  }
  
  // Direct JWT access - no manual extraction needed!
  final adminUser = jwtPayload['user_id'];
  final adminRole = jwtPayload['role'];
  final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
  
  // Enhanced product update with complete context
  final updatedProduct = {
    'id': productId,
    'name': productData['name'],
    'price': productData['price'],
    'description': productData['description'],
    'category': productData['category'],
    'stock': productData['stock'],
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': adminUser,
    'updated_by_role': adminRole,
    'admin_permissions': permissions,
    'method_used': method,
    'server_host': host,
    'user_agent': headers['user-agent'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully - Enhanced!',
    'product': updatedProduct,
    'updated_fields': requiredFields.length,
    'admin_context': {
      'user_id': adminUser,
      'role': adminRole,
      'permissions_count': permissions.length,
    }
  }));
}
```

### Ejemplo con Headers y Query Parameters
```dart
@Put(
  path: '/stores/{storeId}/products/{productId}',
  description: 'Actualiza producto con opciones avanzadas'
)
Future<Response> updateStoreProduct(
  Request request,
  // Path Parameters
  @PathParam('storeId', description: 'ID de la tienda') String storeId,
  @PathParam('productId', description: 'ID del producto') String productId,
  
  // Query Parameters
  @QueryParam('notify_users', defaultValue: false) bool notifyUsers,
  @QueryParam('publish_immediately', defaultValue: true) bool publishImmediately,
  @QueryParam('create_backup', defaultValue: true) bool createBackup,
  
  // Headers
  @RequestHeader('X-Store-ID', required: true) String storeIdHeader,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader('Authorization', required: true) String authHeader,
  
  // Body
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  
  // Validar que el store ID del path coincide con el header
  if (storeId != storeIdHeader) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Store ID mismatch',
      'path_store_id': storeId,
      'header_store_id': storeIdHeader,
    }));
  }
  
  // Validar content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Content-Type must be application/json',
      'received': contentType
    }));
  }
  
  // Validar autorización
  if (!authHeader.startsWith('Bearer ')) {
    return Response.unauthorized(jsonEncode({
      'error': 'Invalid authorization format',
      'expected': 'Bearer <token>'
    }));
  }
  
  // Simular backup si está habilitado
  final actions = <String>[];
  if (createBackup) actions.add('backup_created');
  
  // Actualización del producto
  final updatedProduct = {
    'id': productId,
    'store_id': storeId,
    'name': productData['name'],
    'price': productData['price'],
    'description': productData['description'],
    'category': productData['category'],
    'updated_at': DateTime.now().toIso8601String(),
    'status': publishImmediately ? 'published' : 'draft',
  };
  
  // Acciones adicionales
  if (publishImmediately) actions.add('published');
  if (notifyUsers && publishImmediately) actions.add('users_notified');
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'product': updatedProduct,
    'update_options': {
      'notify_users': notifyUsers,
      'publish_immediately': publishImmediately,
      'create_backup': createBackup,
    },
    'actions_performed': actions,
    'metadata': {
      'store_verified': storeId == storeIdHeader,
      'content_type_verified': contentType.contains('application/json'),
      'update_duration_ms': 150,
    },
  }));
}
```

### Ejemplo de Configuración de Usuario
```dart
@Put(
  path: '/users/{userId}/settings',
  description: 'Actualiza completamente la configuración del usuario'
)
@JWTEndpoint([MyUserValidator()]) // Solo el mismo usuario puede actualizar
Future<Response> updateUserSettings(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(required: true, description: 'Configuración completa del usuario') 
  Map<String, dynamic> settings,
) async {
  
  // Validar que el JWT corresponde al usuario
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only update your own settings',
      'token_user_id': tokenUserId,
      'requested_user_id': userId
    }));
  }
  
  // Configuraciones requeridas para PUT completo
  final requiredSettings = [
    'theme', 'language', 'notifications', 'privacy', 'preferences'
  ];
  
  final missingSettings = requiredSettings
      .where((setting) => !settings.containsKey(setting))
      .toList();
  
  if (missingSettings.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Complete settings required for PUT operation',
      'missing_settings': missingSettings,
      'required_settings': requiredSettings,
      'hint': 'Use PATCH /users/{userId}/settings for partial updates'
    }));
  }
  
  // Validar estructura de notificaciones
  final notifications = settings['notifications'] as Map<String, dynamic>?;
  if (notifications == null || 
      !notifications.containsKey('email') || 
      !notifications.containsKey('push')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Notifications must include email and push settings',
      'received': notifications
    }));
  }
  
  // Actualizar configuraciones
  final updatedSettings = {
    'user_id': userId,
    'theme': settings['theme'],
    'language': settings['language'],
    'notifications': notifications,
    'privacy': settings['privacy'],
    'preferences': settings['preferences'],
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  return jsonResponse(jsonEncode({
    'message': 'User settings updated successfully',
    'settings': updatedSettings,
    'settings_count': requiredSettings.length,
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con Múltiples Validadores
```dart
@Put(path: '/financial/accounts/{accountId}', requiresAuth: true)
@JWTController([
  MyFinancialValidator(clearanceLevel: 3),
  MyBusinessHoursValidator(),
  MyDepartmentValidator(allowedDepartments: ['finance', 'admin']),
], requireAll: true)
Future<Response> updateFinancialAccount(
  Request request,
  @PathParam('accountId') String accountId,
  @RequestBody(required: true) Map<String, dynamic> accountData,
) async {
  // Solo usuarios con clearance financiero nivel 3, en horas de negocio,
  // y del departamento finance o admin pueden actualizar cuentas
  return jsonResponse(jsonEncode({
    'message': 'Financial account updated successfully'
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Requerir todos los campos**: PUT debe actualizar el recurso completo
- **Validar IDs en el path**: Verificar que el recurso existe
- **Usar idempotencia**: La misma petición produce el mismo resultado
- **Incluir timestamps**: Campos de `updated_at` y `updated_by`
- **Responder con el recurso actualizado**: Devolver el estado final
- **Preferir Enhanced Parameters**: Para acceso completo sin Request parameter
- **Combinar enfoques**: Traditional para validación, Enhanced para contexto completo

### ❌ Evitar
- **Actualizaciones parciales**: Usar PATCH para eso
- **Crear recursos**: Usar POST para creación
- **Ignorar validaciones**: Siempre validar datos completos
- **No verificar permisos**: Asegurarse de que el usuario puede modificar el recurso
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced por Escenario

#### Para PUT con Validación Estricta
```dart
// ✅ Traditional - Validación automática de tipos
@Put(path: '/products/{id}')
Future<Response> updateProduct(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> data,
) async {
  // Automatic type validation and required field checking
}
```

#### Para PUT con Context Completo
```dart
// ✅ Enhanced - Acceso completo sin Request parameter
@Put(path: '/products/{id}')
Future<Response> updateProductEnhanced(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> data,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final updatedBy = jwt['user_id'];  // Direct access
  final userAgent = headers['user-agent'];  // All headers
}
```

#### Para PUT con Opciones Dinámicas
```dart
// ✅ Enhanced - Opciones de actualización flexibles
@Put(path: '/products/{id}')
Future<Response> updateProductWithOptions(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> data,
  @QueryParam.all() Map<String, String> updateOptions,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  final notify = updateOptions['notify_users']?.toLowerCase() == 'true';
  final backup = updateOptions['create_backup']?.toLowerCase() != 'false';
  // Handle unlimited update options dynamically
}
```

#### Para PUT con Múltiples Validadores
```dart
// ✅ Hybrid - Validación robusta + contexto enhanced
@Put(path: '/sensitive/{id}')
@JWTEndpoint([MyAdminValidator(), MyDepartmentValidator()])
Future<Response> updateSensitiveData(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> data,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader('X-Request-ID', required: true) String requestId,
) async {
  // Secure update with complete audit trail
}
```

## 🔍 Diferencias con PATCH

| Aspecto | PUT | PATCH |
|---------|-----|--------|
| **Propósito** | Actualización completa | Actualización parcial |
| **Campos requeridos** | Todos los campos | Solo campos a modificar |
| **Idempotencia** | Sí | Puede variar |
| **Campos faltantes** | Se establecen como null/default | Se mantienen sin cambios |
| **Uso típico** | Reemplazar recurso | Modificar algunos campos |

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Actualización exitosa | `200` | OK - Recurso actualizado |
| Recurso no encontrado | `404` | Not Found - ID no existe |
| Datos incompletos | `400` | Bad Request - Faltan campos requeridos |
| Datos inválidos | `400` | Bad Request - Tipos o valores incorrectos |
| Sin autorización | `401` | Unauthorized - Token JWT inválido |
| Prohibido | `403` | Forbidden - Sin permisos de modificación |
| Conflicto | `409` | Conflict - Conflicto de versiones |
| Error del servidor | `500` | Internal Server Error |

## 🌐 URL Resultantes

Si tu controller tiene `basePath: '/api/v1'` y usas `@Put(path: '/users/{id}')`, la URL final será:
```
PUT http://localhost:8080/api/v1/users/{id}
```

## 📋 Ejemplo de Request/Response

### Request
```http
PUT http://localhost:8080/api/products/prod_123
Content-Type: application/json
Authorization: Bearer admin_token_456
X-Store-ID: store_789

{
  "name": "Updated Product Name",
  "price": 299.99,
  "description": "Updated complete description",
  "category": "electronics",
  "stock": 50,
  "tags": ["electronics", "popular"],
  "specifications": {
    "color": "black",
    "weight": "2.5kg"
  }
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "Product updated successfully",
  "product": {
    "id": "prod_123",
    "name": "Updated Product Name",
    "price": 299.99,
    "description": "Updated complete description",
    "category": "electronics",
    "stock": 50,
    "tags": ["electronics", "popular"],
    "specifications": {
      "color": "black",
      "weight": "2.5kg"
    },
    "updated_at": "2024-12-21T10:30:56.789Z",
    "updated_by": "admin_456"
  },
  "updated_fields": 7
}
```

---

**Siguiente**: [Documentación de @Patch](patch-annotation.md) | **Anterior**: [Documentación de @Post](post-annotation.md)