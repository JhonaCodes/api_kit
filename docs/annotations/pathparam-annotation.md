# @PathParam - Anotación para Parámetros de Path

## 📋 Descripción

La anotación `@PathParam` se utiliza para capturar valores dinámicos de la URL del endpoint. Permite extraer segmentos variables de la ruta y convertirlos automáticamente a parámetros de método.

## 🎯 Propósito

- **Capturar IDs**: Obtener identificadores únicos de recursos (`/users/{id}`)
- **Rutas dinámicas**: Manejar segmentos variables en URLs (`/stores/{storeId}/products/{productId}`)
- **Navegación jerárquica**: Rutas anidadas con múltiples parámetros
- **APIs RESTful**: Seguir patrones REST estándar para recursos

## 📝 Sintaxis

```dart
@PathParam(
  String name,                    // Nombre del parámetro en la URL (OBLIGATORIO)
  {String? description}           // Descripción del parámetro
)
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Descripción |
|-----------|------|-------------|-------------|
| `name` | `String` | ✅ Sí | Nombre exacto del parámetro definido en la ruta entre `{}` |
| `description` | `String?` | ❌ No | Descripción del propósito y formato esperado del parámetro |

## 🚀 Ejemplos de Uso

### Ejemplo Básico - Un Parámetro
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/{id}')  // Ruta: /api/users/{id}
  Future<Response> getUserById(
    Request request,
    @PathParam('id') String userId,  // Captura el valor de {id}
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'User retrieved successfully',
      'user_id': userId,  // userId contiene el valor de la URL
      'url_path': '/api/users/$userId'
    }));
  }
}

// Ejemplo de uso:
// GET /api/users/user_123 -> userId = "user_123"
// GET /api/users/456      -> userId = "456"
```

### Ejemplo con Descripción
```dart
@Get(path: '/products/{productId}')
Future<Response> getProduct(
  Request request,
  @PathParam('productId', description: 'ID único del producto en formato prod_*') 
  String productId,
) async {
  
  // Validar formato del ID
  if (!productId.startsWith('prod_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid product ID format',
      'expected_format': 'prod_*',
      'received': productId,
      'example': 'prod_123456'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'product_id': productId,
    'message': 'Product retrieved successfully'
  }));
}

// Ejemplos de uso:
// GET /products/prod_123 -> ✅ Válido
// GET /products/123      -> ❌ Error de formato
```

### Ejemplo con Múltiples Parámetros
```dart
@RestController(basePath: '/api/stores')
class StoreController extends BaseController {
  
  @Get(path: '/{storeId}/categories/{categoryId}/products/{productId}')
  Future<Response> getStoreProduct(
    Request request,
    @PathParam('storeId', description: 'ID único de la tienda') String storeId,
    @PathParam('categoryId', description: 'ID de la categoría de productos') String categoryId,
    @PathParam('productId', description: 'ID específico del producto') String productId,
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'Store product retrieved successfully',
      'hierarchy': {
        'store_id': storeId,
        'category_id': categoryId,
        'product_id': productId,
      },
      'full_path': '/stores/$storeId/categories/$categoryId/products/$productId'
    }));
  }
}

// Ejemplo de uso:
// GET /api/stores/store_456/categories/electronics/products/prod_789
// storeId = "store_456"
// categoryId = "electronics" 
// productId = "prod_789"
```

### Ejemplo con Validación de Tipos
```dart
@Get(path: '/orders/{orderId}/items/{itemNumber}')
Future<Response> getOrderItem(
  Request request,
  @PathParam('orderId', description: 'ID de la orden') String orderId,
  @PathParam('itemNumber', description: 'Número de item (1-99)') String itemNumberStr,
) async {
  
  // Convertir y validar itemNumber
  final itemNumber = int.tryParse(itemNumberStr);
  if (itemNumber == null || itemNumber < 1 || itemNumber > 99) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid item number',
      'received': itemNumberStr,
      'valid_range': '1-99',
      'type': 'integer'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'order_id': orderId,
    'item_number': itemNumber,  // Convertido a int
    'item_number_string': itemNumberStr,  // Valor original
  }));
}

// Ejemplos:
// GET /orders/order_123/items/5  -> ✅ itemNumber = 5
// GET /orders/order_123/items/abc -> ❌ Error de tipo
// GET /orders/order_123/items/100 -> ❌ Fuera de rango
```

### Ejemplo con Parámetros y Query Parameters
```dart
@Get(path: '/users/{userId}/posts/{postId}')
Future<Response> getUserPost(
  Request request,
  // Path Parameters
  @PathParam('userId', description: 'ID del usuario propietario') String userId,
  @PathParam('postId', description: 'ID del post específico') String postId,
  
  // Query Parameters adicionales
  @QueryParam('include_comments', defaultValue: false) bool includeComments,
  @QueryParam('format', defaultValue: 'json') String format,
) async {
  
  // Validar que el usuario puede acceder al post
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
  final currentUser = jwtPayload?['user_id'];
  
  final postData = {
    'post_id': postId,
    'user_id': userId,
    'title': 'Sample post title',
    'content': 'Post content here...',
    'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
  };
  
  if (includeComments) {
    postData['comments'] = [
      {'id': 'comment_1', 'content': 'Great post!'},
      {'id': 'comment_2', 'content': 'Thanks for sharing'}
    ];
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Post retrieved successfully',
    'post': postData,
    'request_info': {
      'user_id': userId,
      'post_id': postId,
      'include_comments': includeComments,
      'format': format,
      'current_user': currentUser
    }
  }));
}

// Ejemplo de uso:
// GET /users/user_123/posts/post_456?include_comments=true&format=detailed
```

### Ejemplo con Validación JWT y Path

#### Traditional Approach - Manual JWT Extraction
```dart
@Put(path: '/users/{userId}/settings')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserSettings(
  Request request,
  @PathParam('userId', description: 'ID del usuario a actualizar') String userId,
  @RequestBody(required: true) Map<String, dynamic> settings,
) async {
  
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  // Validar que el usuario solo puede actualizar sus propios settings
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update settings for other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'hint': 'You can only update your own settings'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Settings updated successfully',
    'user_id': userId,
    'updated_settings': settings,
    'updated_by': tokenUserId,
    'path_validation': 'passed'
  }));
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@Put(path: '/users/{userId}/settings')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserSettingsEnhanced(
  @PathParam('userId', description: 'ID del usuario a actualizar') String userId,
  @RequestBody(required: true) Map<String, dynamic> settings,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
) async {
  
  // Direct JWT access - no manual extraction needed!
  final tokenUserId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];
  
  // Validar que el usuario solo puede actualizar sus propios settings
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update settings for other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'user_role': userRole,
      'hint': 'You can only update your own settings'
    }));
  }
  
  // Enhanced context for auditing
  final updateContext = {
    'updated_by': tokenUserId,
    'user_role': userRole,
    'method': method,
    'user_agent': headers['user-agent'],
    'content_type': headers['content-type'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Settings updated successfully - Enhanced!',
    'user_id': userId,
    'updated_settings': settings,
    'update_context': updateContext,
    'path_validation': 'passed',
    'enhanced': true,
  }));
}

// Ejemplo correcto:
// PUT /users/user_123/settings (con JWT de user_123) -> ✅ Autorizado
// PUT /users/user_456/settings (con JWT de user_123) -> ❌ Prohibido
```

### Ejemplo con Parámetros de Archivo/Slug
```dart
@Get(path: '/docs/{category}/{filename}')
Future<Response> getDocumentFile(
  Request request,
  @PathParam('category', description: 'Categoría del documento') String category,
  @PathParam('filename', description: 'Nombre del archivo con extensión') String filename,
) async {
  
  // Validar categoría
  final validCategories = ['api', 'tutorials', 'guides', 'reference'];
  if (!validCategories.contains(category)) {
    return Response.notFound(jsonEncode({
      'error': 'Invalid document category',
      'category': category,
      'valid_categories': validCategories
    }));
  }
  
  // Validar extensión de archivo
  final allowedExtensions = ['.md', '.pdf', '.txt', '.html'];
  final hasValidExtension = allowedExtensions.any((ext) => filename.endsWith(ext));
  
  if (!hasValidExtension) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid file extension',
      'filename': filename,
      'allowed_extensions': allowedExtensions
    }));
  }
  
  // Construir path del archivo
  final filePath = 'docs/$category/$filename';
  
  return jsonResponse(jsonEncode({
    'message': 'Document found',
    'category': category,
    'filename': filename,
    'file_path': filePath,
    'file_url': 'https://api.example.com/docs/$category/$filename'
  }));
}

// Ejemplos de uso:
// GET /docs/api/authentication.md     -> ✅ Válido
// GET /docs/tutorials/getting-started.pdf -> ✅ Válido  
// GET /docs/invalid/file.exe          -> ❌ Categoría y extensión inválidas
```

## 🔗 Combinación con Otras Anotaciones

### Con RequestBody y Headers
```dart
@Put(path: '/stores/{storeId}/products/{productId}')
Future<Response> updateStoreProduct(
  Request request,
  // Path Parameters
  @PathParam('storeId', description: 'ID de la tienda') String storeId,
  @PathParam('productId', description: 'ID del producto') String productId,
  
  // Headers
  @RequestHeader('X-Store-Verification', required: true) String storeVerification,
  
  // Body
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  
  // Validar que el header coincide con el path parameter
  if (storeVerification != storeId) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Store verification mismatch',
      'path_store_id': storeId,
      'header_store_id': storeVerification
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'store_id': storeId,
    'product_id': productId,
    'verification': 'passed'
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Usar nombres descriptivos**: `userId` en lugar de solo `id`
- **Incluir descripciones**: Especificar formato esperado y ejemplos
- **Validar formato**: Verificar que los IDs siguen el formato esperado
- **Manejar errores**: Respuestas claras para IDs inválidos o no encontrados
- **Ser consistente**: Usar el mismo formato para tipos similares de IDs
- **Combinar con Enhanced Parameters**: Para acceso completo al contexto sin Request
- **Preferir enfoque híbrido**: @PathParam específico + Enhanced Parameters para contexto

### ❌ Evitar
- **Nombres genéricos**: `id` cuando hay múltiples parámetros
- **No validar formato**: Asumir que todos los valores son válidos
- **IDs sensibles en URL**: Evitar poner información sensible en path parameters
- **Rutas muy largas**: No abusar de parámetros anidados
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced para PathParam

#### Para Recursos con JWT Validation
```dart
// ✅ Enhanced - PathParam específico + JWT directo
@Get(path: '/users/{userId}/profile')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(
  @PathParam('userId') String userId,                    // Type-safe path param
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct JWT
  @RequestHost() String host,
) async {
  final currentUser = jwt['user_id'];
  
  return jsonResponse(jsonEncode({
    'profile': 'user profile data',
    'user_id': userId,
    'requested_by': currentUser,
    'host': host,
  }));
}
```

#### Para Multi-level Resource Hierarchies
```dart
// ✅ Enhanced - Múltiples PathParams + contexto completo
@Get(path: '/stores/{storeId}/categories/{categoryId}/products/{productId}')
Future<Response> getStoreProductEnhanced(
  @PathParam('storeId') String storeId,
  @PathParam('categoryId') String categoryId,
  @PathParam('productId') String productId,
  @QueryParam.all() Map<String, String> options,  // Dynamic options
  @RequestMethod() String method,
  @RequestPath() String fullPath,
) async {
  return jsonResponse(jsonEncode({
    'hierarchy': {
      'store_id': storeId,
      'category_id': categoryId,
      'product_id': productId,
    },
    'options': options,
    'request_info': {
      'method': method,
      'full_path': fullPath,
    },
  }));
}
```

#### Para File/Document Access
```dart
// ✅ Enhanced - File params + security headers
@Get(path: '/files/{folder}/{filename}')
@JWTEndpoint([MyFileValidator()])
Future<Response> getFileEnhanced(
  @PathParam('folder') String folder,
  @PathParam('filename') String filename,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  final userId = jwt['user_id'];
  final userAgent = headers['user-agent'] ?? 'unknown';
  
  // Enhanced security logging
  final accessLog = {
    'user_id': userId,
    'folder': folder,
    'filename': filename,
    'user_agent': userAgent,
    'host': host,
    'access_time': DateTime.now().toIso8601String(),
  };
  
  return jsonResponse(jsonEncode({
    'message': 'File accessed successfully',
    'file_path': '$folder/$filename',
    'access_log': accessLog,
  }));
}
```

#### Para User-specific Resources
```dart
// ✅ Enhanced - User ownership validation
@Put(path: '/users/{userId}/documents/{docId}')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserDocument(
  @PathParam('userId') String userId,
  @PathParam('docId') String docId,
  @RequestBody(required: true) Map<String, dynamic> docData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final tokenUserId = jwt['user_id'];
  
  // Enhanced ownership validation
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot modify documents of other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'document_id': docId,
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Document updated successfully',
    'user_id': userId,
    'document_id': docId,
    'updated_fields': docData.keys.toList(),
    'client_info': {
      'user_agent': headers['user-agent'],
      'content_type': headers['content-type'],
    },
  }));
}
```

## 🔍 Casos de Uso Comunes

### 1. **Recurso por ID**
```dart
@Get(path: '/users/{userId}')
Future<Response> getUser(Request request, @PathParam('userId') String userId) async { ... }
```

### 2. **Recurso anidado**
```dart
@Get(path: '/users/{userId}/orders/{orderId}')
Future<Response> getUserOrder(
  Request request,
  @PathParam('userId') String userId,
  @PathParam('orderId') String orderId,
) async { ... }
```

### 3. **Categorías/Slugs**
```dart
@Get(path: '/blog/{category}/{slug}')
Future<Response> getBlogPost(
  Request request,
  @PathParam('category') String category,
  @PathParam('slug') String slug,
) async { ... }
```

### 4. **Archivos/Rutas**
```dart
@Get(path: '/files/{folder}/{filename}')
Future<Response> getFile(
  Request request,
  @PathParam('folder') String folder,
  @PathParam('filename') String filename,
) async { ... }
```

## 📊 Validaciones Recomendadas

### Validación de Formato
```dart
// Validar IDs con formato específico
if (!userId.startsWith('user_') || userId.length < 10) {
  return Response.badRequest(body: 'Invalid user ID format');
}

// Validar IDs numéricos
final numericId = int.tryParse(productId);
if (numericId == null || numericId <= 0) {
  return Response.badRequest(body: 'Product ID must be a positive integer');
}

// Validar slugs/nombres de archivo
if (filename.contains('..') || filename.contains('/')) {
  return Response.badRequest(body: 'Invalid filename');
}
```

### Validación de Existencia
```dart
// En implementación real, verificar en base de datos
final user = await userRepository.findById(userId);
if (user == null) {
  return Response.notFound(jsonEncode({
    'error': 'User not found',
    'user_id': userId
  }));
}
```

## 🌐 URL Mapping

### Ejemplos de Mapeo
```dart
// Definición
@Get(path: '/stores/{storeId}/products/{productId}')

// URLs válidas:
// /stores/store_123/products/prod_456
// -> storeId = "store_123", productId = "prod_456"

// /stores/my-store/products/special-item
// -> storeId = "my-store", productId = "special-item"
```

### Caracteres Especiales
- **Permitidos en path params**: letras, números, `-`, `_`
- **Automáticamente URL-decoded**: espacios y caracteres especiales
- **Case-sensitive**: `Store_123` ≠ `store_123`

---

**Siguiente**: [Documentación de @QueryParam](queryparam-annotation.md) | **Anterior**: [Documentación de @RestController](restcontroller-annotation.md)