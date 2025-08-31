# @Post - Anotación para Endpoints POST

## 📋 Descripción

La anotación `@Post` se utiliza para marcar métodos como endpoints que responden a peticiones HTTP POST. Es la anotación estándar para operaciones de creación de recursos y envío de datos al servidor.

## 🎯 Propósito

- **Crear recursos**: Insertar nuevos registros o entidades
- **Envío de formularios**: Procesar datos de formularios web
- **Operaciones de escritura**: Cualquier acción que modifique el estado del servidor
- **APIs de autenticación**: Login, registro, renovación de tokens

## 📝 Sintaxis

```dart
@Post({
  required String path,           // Ruta del endpoint (OBLIGATORIO)
  String? description,           // Descripción del endpoint
  int statusCode = 201,          // Código de respuesta por defecto (Created)
  bool requiresAuth = false,     // Si requiere autenticación
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Sí | - | Ruta relativa del endpoint (ej: `/users`, `/products`) |
| `description` | `String?` | ❌ No | `null` | Descripción legible del propósito del endpoint |
| `statusCode` | `int` | ❌ No | `201` | Código de estado HTTP de respuesta exitosa (Created) |
| `requiresAuth` | `bool` | ❌ No | `false` | Indica si el endpoint requiere autenticación |

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach - Manual Body Parsing
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Post(path: '/create')
  Future<Response> createUser(Request request) async {
    // Manual body parsing
    final body = await request.readAsString();
    final userData = jsonDecode(body);
    
    return jsonResponse(jsonEncode({
      'message': 'User created successfully',
      'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': userData['name']
    }));
  }
}
```

#### Enhanced Approach - Direct Body Injection ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Post(path: '/create')
  Future<Response> createUserEnhanced(
    @RequestBody() Map<String, dynamic> userData, // Direct body injection
  ) async {
    // No manual parsing needed!
    return jsonResponse(jsonEncode({
      'message': 'User created successfully - Enhanced!',
      'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': userData['name'],
      'enhanced': true,
    }));
  }
}
```

### Ejemplo con RequestBody Tipado

#### Traditional Approach
```dart
@Post(
  path: '/users',
  description: 'Crea un nuevo usuario en el sistema'
)
Future<Response> createUser(
  Request request,
  @RequestBody(required: true, description: 'Datos del nuevo usuario') 
  Map<String, dynamic> userData,
) async {
  // Validaciones
  if (userData['name'] == null || userData['email'] == null) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Name and email are required'
    }));
  }
  
  final newUser = {
    'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
    'name': userData['name'],
    'email': userData['email'],
    'created_at': DateTime.now().toIso8601String(),
  };
  
  return Response(
    201, // Created
    body: jsonEncode({
      'message': 'User created successfully',
      'user': newUser
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
```

#### Enhanced Approach - No Request Parameter Needed ✨
```dart
@Post(
  path: '/users',
  description: 'Crea un nuevo usuario en el sistema'
)
Future<Response> createUserEnhanced(
  @RequestBody(required: true, description: 'Datos del nuevo usuario') 
  Map<String, dynamic> userData,
  @RequestMethod() String method,
  @RequestHost() String host,
) async {
  // Validaciones
  if (userData['name'] == null || userData['email'] == null) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Name and email are required'
    }));
  }
  
  final newUser = {
    'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
    'name': userData['name'],
    'email': userData['email'],
    'created_at': DateTime.now().toIso8601String(),
    'created_via_method': method,    // Direct access
    'server_host': host,             // Direct access
  };
  
  return Response(
    201, // Created
    body: jsonEncode({
      'message': 'User created successfully - Enhanced!',
      'user': newUser
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
```

### Ejemplo con Headers y Auth

#### Traditional Approach - Manual JWT Extraction
```dart
@Post(
  path: '/products',
  description: 'Crea un nuevo producto (requiere admin)',
  requiresAuth: true
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProduct(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader('X-Store-ID', required: true) String storeId,
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  
  // Validar content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Content-Type must be application/json'
    }));
  }
  
  // Manual JWT extraction from context
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  final newProduct = {
    'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
    'store_id': storeId,
    'name': productData['name'],
    'price': productData['price'],
    'created_by': adminUser,
    'created_at': DateTime.now().toIso8601String(),
  };
  
  return Response(
    201,
    body: jsonEncode({
      'message': 'Product created successfully',
      'product': newProduct
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
```

#### Enhanced Approach - Direct JWT & Headers Injection ✨
```dart
@Post(
  path: '/products',
  description: 'Crea un nuevo producto (requiere admin)',
  requiresAuth: true
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProductEnhanced(
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader('X-Store-ID', required: true) String storeId,
  @RequestHeader.all() Map<String, String> allHeaders,     // All headers access
  @RequestBody(required: true) Map<String, dynamic> productData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
  @RequestMethod() String method,
  @RequestPath() String path,
) async {
  
  // Validar content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Content-Type must be application/json'
    }));
  }
  
  // Direct JWT access - no manual extraction needed!
  final adminUser = jwtPayload['user_id'];
  final adminRole = jwtPayload['role'];
  
  final newProduct = {
    'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
    'store_id': storeId,
    'name': productData['name'],
    'price': productData['price'],
    'created_by': adminUser,
    'created_by_role': adminRole,
    'created_at': DateTime.now().toIso8601String(),
    'method': method,                    // Direct access
    'endpoint_path': path,               // Direct access
    'total_headers': allHeaders.length,  // Bonus: headers count
  };
  
  return Response(
    201,
    body: jsonEncode({
      'message': 'Product created successfully - Enhanced!',
      'product': newProduct
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
```

### Ejemplo con Query Parameters

#### Traditional Approach - Limited Parameters
```dart
@Post(path: '/posts')
Future<Response> createPost(
  Request request,
  @QueryParam('auto_publish', defaultValue: false) bool autoPublish,
  @QueryParam('notify_followers', defaultValue: true) bool notifyFollowers,
  @RequestBody(required: true) Map<String, dynamic> postData,
) async {
  
  final newPost = {
    'id': 'post_${DateTime.now().millisecondsSinceEpoch}',
    'content': postData['content'],
    'status': autoPublish ? 'published' : 'draft',
    'created_at': DateTime.now().toIso8601String(),
  };
  
  final actions = <String>[];
  if (autoPublish) actions.add('published');
  if (notifyFollowers && autoPublish) actions.add('followers_notified');
  
  return jsonResponse(jsonEncode({
    'message': 'Post created successfully',
    'post': newPost,
    'actions_performed': actions
  }));
}
```

#### Enhanced Approach - Unlimited Dynamic Parameters ✨
```dart
@Post(path: '/posts')
Future<Response> createPostEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestBody(required: true) Map<String, dynamic> postData,
) async {
  
  // Parse what you need, handle unlimited options dynamically
  final autoPublish = allQueryParams['auto_publish']?.toLowerCase() == 'true';
  final notifyFollowers = allQueryParams['notify_followers']?.toLowerCase() != 'false';
  final scheduleDate = allQueryParams['schedule_date'];
  final tags = allQueryParams['tags']?.split(',') ?? [];
  final priority = allQueryParams['priority'] ?? 'normal';
  final category = allQueryParams['category'];
  
  final newPost = {
    'id': 'post_${DateTime.now().millisecondsSinceEpoch}',
    'content': postData['content'],
    'status': autoPublish ? 'published' : 'draft',
    'scheduled_date': scheduleDate,
    'tags': tags,
    'priority': priority,
    'category': category,
    'created_at': DateTime.now().toIso8601String(),
  };
  
  final actions = <String>[];
  if (autoPublish) actions.add('published');
  if (notifyFollowers && autoPublish) actions.add('followers_notified');
  if (scheduleDate != null) actions.add('scheduled');
  
  return jsonResponse(jsonEncode({
    'message': 'Post created successfully - Enhanced with dynamic options!',
    'post': newPost,
    'actions_performed': actions,
    'all_query_options': allQueryParams,      // See all provided parameters
    'options_count': allQueryParams.length,   // Dynamic flexibility
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con Múltiples Validadores JWT

#### Traditional Approach
```dart
@Post(path: '/transactions', requiresAuth: true)
@JWTController([
  MyFinancialValidator(minimumAmount: 1000),
  MyBusinessHoursValidator(),
], requireAll: true) // Ambos validadores deben pasar
Future<Response> createTransaction(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> transactionData,
) async {
  // Solo se ejecuta si el usuario tiene permisos financieros Y está en horas de negocio
  return jsonResponse(jsonEncode({
    'message': 'Transaction created successfully'
  }));
}
```

#### Enhanced Approach - Complete Context Access ✨
```dart
@Post(path: '/transactions', requiresAuth: true)
@JWTController([
  MyFinancialValidator(minimumAmount: 1000),
  MyBusinessHoursValidator(),
], requireAll: true) // Ambos validadores deben pasar
Future<Response> createTransactionEnhanced(
  @RequestBody(required: true) Map<String, dynamic> transactionData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
  @RequestPath() String path,
) async {
  // Complete access without Request parameter
  final userId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];
  final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
  
  return jsonResponse(jsonEncode({
    'message': 'Transaction created successfully - Enhanced!',
    'transaction_id': 'tx_${DateTime.now().millisecondsSinceEpoch}',
    'amount': transactionData['amount'],
    'processed_by': userId,
    'user_role': userRole,
    'permissions': permissions,
    'method': method,
    'endpoint': path,
    'user_agent': headers['user-agent'],
  }));
}
```

### Con Validación Compleja

#### Traditional Approach
```dart
@Post(path: '/upload/{folderId}')
Future<Response> uploadFile(
  Request request,
  @PathParam('folderId', description: 'Folder destination ID') String folderId,
  @QueryParam('create_thumbnails', defaultValue: false) bool createThumbnails,
  @RequestHeader('Content-Length', required: true) String contentLength,
  @RequestBody(required: true, description: 'File metadata') Map<String, dynamic> fileData,
) async {
  
  final fileSize = int.tryParse(contentLength) ?? 0;
  const maxFileSize = 50 * 1024 * 1024; // 50MB
  
  if (fileSize > maxFileSize) {
    return Response.badRequest(body: jsonEncode({
      'error': 'File size exceeds maximum allowed (50MB)',
      'received_size': fileSize,
      'max_size': maxFileSize
    }));
  }
  
  final uploadResult = {
    'file_id': 'file_${DateTime.now().millisecondsSinceEpoch}',
    'folder_id': folderId,
    'filename': fileData['filename'],
    'size_bytes': fileSize,
    'thumbnails_created': createThumbnails,
    'uploaded_at': DateTime.now().toIso8601String(),
  };
  
  return Response(201, 
    body: jsonEncode({
      'message': 'File uploaded successfully',
      'file': uploadResult
    }),
    headers: {'Content-Type': 'application/json'}
  );
}
```

#### Enhanced Approach - Dynamic Upload Options ✨
```dart
@Post(path: '/upload/{folderId}')
Future<Response> uploadFileEnhanced(
  @PathParam('folderId', description: 'Folder destination ID') String folderId,
  @QueryParam.all() Map<String, String> allUploadOptions,
  @RequestHeader('Content-Length', required: true) String contentLength,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestBody(required: true, description: 'File metadata') Map<String, dynamic> fileData,
  @RequestMethod() String method,
  @RequestHost() String host,
) async {
  
  final fileSize = int.tryParse(contentLength) ?? 0;
  const maxFileSize = 50 * 1024 * 1024; // 50MB
  
  if (fileSize > maxFileSize) {
    return Response.badRequest(body: jsonEncode({
      'error': 'File size exceeds maximum allowed (50MB)',
      'received_size': fileSize,
      'max_size': maxFileSize
    }));
  }
  
  // Enhanced: Dynamic upload options from query params
  final createThumbnails = allUploadOptions['create_thumbnails']?.toLowerCase() == 'true';
  final generatePreview = allUploadOptions['generate_preview']?.toLowerCase() == 'true';
  final compress = allUploadOptions['compress']?.toLowerCase() == 'true';
  final quality = int.tryParse(allUploadOptions['quality'] ?? '85') ?? 85;
  final tags = allUploadOptions['tags']?.split(',') ?? [];
  final category = allUploadOptions['category'];
  
  final uploadResult = {
    'file_id': 'file_${DateTime.now().millisecondsSinceEpoch}',
    'folder_id': folderId,
    'filename': fileData['filename'],
    'size_bytes': fileSize,
    'thumbnails_created': createThumbnails,
    'preview_generated': generatePreview,
    'compressed': compress,
    'quality': quality,
    'tags': tags,
    'category': category,
    'uploaded_at': DateTime.now().toIso8601String(),
    'method': method,
    'host': host,
    'client_info': {
      'user_agent': allHeaders['user-agent'],
      'content_type': allHeaders['content-type'],
    },
    'all_upload_options': allUploadOptions,  // Complete flexibility
  };
  
  return Response(201, 
    body: jsonEncode({
      'message': 'File uploaded successfully with dynamic options!',
      'file': uploadResult,
      'options_processed': allUploadOptions.length,
    }),
    headers: {'Content-Type': 'application/json'}
  );
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Validar datos de entrada**: Siempre verificar required fields
- **Usar códigos de estado apropiados**: 201 para creación, 200 para operaciones
- **Incluir IDs generados**: Devolver el ID del recurso creado
- **Manejar errores de validación**: Respuestas claras para datos inválidos
- **Usar @RequestBody**: Para datos estructurados en JSON
- **Preferir Enhanced Parameters**: Para mayor flexibilidad y menos boilerplate
- **Combinar enfoques**: Traditional para validación automática, Enhanced para acceso completo

### ❌ Evitar
- **Crear sin validación**: No asumir que los datos son válidos
- **Respuestas inconsistentes**: Mantener formato estándar
- **Ignorar Content-Type**: Validar que sea application/json cuando sea necesario
- **No devolver el recurso creado**: El cliente necesita saber qué se creó
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones por Escenario

#### Para APIs de Creación Estable
```dart
// ✅ Traditional - Validación automática de campos conocidos
@Post(path: '/users')
Future<Response> createUser(
  @RequestBody(required: true) Map<String, dynamic> userData,
) async { ... }
```

#### Para APIs Dinámicas o Con Muchas Opciones
```dart
// ✅ Enhanced - Flexibilidad para opciones ilimitadas
@Post(path: '/posts')
Future<Response> createPost(
  @RequestBody(required: true) Map<String, dynamic> postData,
  @QueryParam.all() Map<String, String> allOptions,
) async {
  // Handle unlimited creation options dynamically
}
```

#### Para APIs con JWT Complejo
```dart
// ✅ Enhanced - Acceso directo a contexto JWT
@Post(path: '/admin/actions')
@JWTEndpoint([MyAdminValidator()])
Future<Response> adminAction(
  @RequestBody(required: true) Map<String, dynamic> actionData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  final adminId = jwt['user_id'];  // Direct access
}
```

#### Para Upload de Archivos
```dart
// ✅ Hybrid - Validación específica + opciones dinámicas
@Post(path: '/upload/{folderId}')
Future<Response> uploadFile(
  @PathParam('folderId') String folderId,              // Type-safe path
  @RequestHeader('Content-Length', required: true) String contentLength, // Required header
  @QueryParam.all() Map<String, String> uploadOptions, // Flexible options
  @RequestBody(required: true) Map<String, dynamic> fileData,
) async { ... }
```

## 🔍 Casos de Uso Comunes

### 1. **Creación de usuario**

#### Traditional
```dart
@Post(path: '/register', description: 'Registra un nuevo usuario')
@JWTPublic() // Endpoint público
Future<Response> registerUser(Request request, @RequestBody(required: true) Map<String, dynamic> userData) async { ... }
```

#### Enhanced ✨
```dart
@Post(path: '/register', description: 'Registra un nuevo usuario')
@JWTPublic() // Endpoint público
Future<Response> registerUserEnhanced(
  @RequestBody(required: true) Map<String, dynamic> userData,
  @RequestHost() String host,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // No Request parameter needed, complete access
}
```

### 2. **Login/Autenticación**

#### Traditional
```dart
@Post(path: '/login', description: 'Autentica usuario y devuelve token')
@JWTPublic()
Future<Response> loginUser(Request request, @RequestBody(required: true) Map<String, dynamic> credentials) async { ... }
```

#### Enhanced ✨
```dart
@Post(path: '/login', description: 'Autentica usuario y devuelve token')
@JWTPublic()
Future<Response> loginUserEnhanced(
  @RequestBody(required: true) Map<String, dynamic> credentials,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  final userAgent = headers['user-agent'] ?? 'unknown';
  final clientIp = headers['x-forwarded-for'] ?? headers['x-real-ip'];
  
  // Enhanced login with client tracking
  return jsonResponse(jsonEncode({
    'token': 'jwt_token_here',
    'user_id': 'user123',
    'login_info': {
      'host': host,
      'user_agent': userAgent,
      'client_ip': clientIp,
      'login_time': DateTime.now().toIso8601String(),
    }
  }));
}
```

### 3. **Creación con relaciones**

#### Traditional
```dart
@Post(path: '/users/{userId}/orders', description: 'Crea orden para usuario específico')
Future<Response> createOrder(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(required: true) Map<String, dynamic> orderData,
) async { ... }
```

#### Enhanced - Con Opciones Dinámicas ✨
```dart
@Post(path: '/users/{userId}/orders', description: 'Crea orden con opciones dinámicas')
Future<Response> createOrderEnhanced(
  @PathParam('userId') String userId,
  @RequestBody(required: true) Map<String, dynamic> orderData,
  @QueryParam.all() Map<String, String> orderOptions,
  @RequestMethod() String method,
) async {
  final priority = orderOptions['priority'] ?? 'normal';
  final deliveryType = orderOptions['delivery'] ?? 'standard';
  final giftWrap = orderOptions['gift_wrap']?.toLowerCase() == 'true';
  final notes = orderOptions['notes'];
  
  return jsonResponse(jsonEncode({
    'order_id': 'order_${DateTime.now().millisecondsSinceEpoch}',
    'user_id': userId,
    'items': orderData['items'],
    'options': {
      'priority': priority,
      'delivery_type': deliveryType,
      'gift_wrap': giftWrap,
      'notes': notes,
    },
    'all_options': orderOptions,  // See all provided options
  }));
}
```

### 4. **Upload de archivos**

#### Traditional - Limited
```dart
@Post(path: '/files/upload', description: 'Sube archivo al servidor')
Future<Response> uploadFile(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestBody(required: true) Map<String, dynamic> fileData,
) async { ... }
```

#### Enhanced - Complete Upload Control ✨
```dart
@Post(path: '/files/upload', description: 'Sube archivo con opciones completas')
Future<Response> uploadFileEnhanced(
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader.all() Map<String, String> allHeaders,
  @QueryParam.all() Map<String, String> uploadSettings,
  @RequestBody(required: true) Map<String, dynamic> fileData,
) async {
  final optimize = uploadSettings['optimize']?.toLowerCase() == 'true';
  final quality = int.tryParse(uploadSettings['quality'] ?? '90') ?? 90;
  final thumbnails = uploadSettings['thumbnails']?.split(',') ?? ['small'];
  final folder = uploadSettings['folder'] ?? 'uploads';
  
  return jsonResponse(jsonEncode({
    'file_id': 'file_${DateTime.now().millisecondsSinceEpoch}',
    'filename': fileData['filename'],
    'size': fileData['size'],
    'processing': {
      'optimized': optimize,
      'quality': quality,
      'thumbnails_generated': thumbnails,
      'folder': folder,
    },
    'client_info': {
      'content_type': contentType,
      'user_agent': allHeaders['user-agent'],
    },
    'all_settings': uploadSettings,  // Complete upload customization
  }));
}
```

### 5. **Procesamiento de formularios**

#### Traditional
```dart
@Post(path: '/contact', description: 'Procesa formulario de contacto')
@JWTPublic()
Future<Response> submitContact(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> contactData,
) async { ... }
```

#### Enhanced - Smart Form Processing ✨
```dart
@Post(path: '/contact', description: 'Procesa formulario inteligente')
@JWTPublic()
Future<Response> submitContactEnhanced(
  @RequestBody(required: true) Map<String, dynamic> contactData,
  @QueryParam.all() Map<String, String> formSettings,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  final autoReply = formSettings['auto_reply']?.toLowerCase() != 'false';
  final priority = formSettings['priority'] ?? 'normal';
  final department = formSettings['department'] ?? 'general';
  final language = formSettings['lang'] ?? 'en';
  
  return jsonResponse(jsonEncode({
    'message': 'Contact form submitted successfully!',
    'ticket_id': 'ticket_${DateTime.now().millisecondsSinceEpoch}',
    'contact_info': contactData,
    'processing': {
      'auto_reply_sent': autoReply,
      'priority': priority,
      'assigned_department': department,
      'language': language,
    },
    'client_info': {
      'user_agent': headers['user-agent'],
      'referer': headers['referer'],
      'host': host,
    },
    'form_settings': formSettings,  // All form customization
  }));
}
```

### 6. **🆕 Caso Enhanced: API Creation con JWT**
```dart
@Post(path: '/admin/api-keys', description: 'Crea nueva API key')
@JWTEndpoint([MyAdminValidator()])
Future<Response> createApiKeyEnhanced(
  @RequestBody(required: true) Map<String, dynamic> keyData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @QueryParam.all() Map<String, String> permissions,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final adminId = jwt['user_id'];
  final adminRole = jwt['role'];
  
  // Dynamic permissions from query params
  final canRead = permissions['read']?.toLowerCase() != 'false';
  final canWrite = permissions['write']?.toLowerCase() == 'true';
  final canDelete = permissions['delete']?.toLowerCase() == 'true';
  final scopes = permissions['scopes']?.split(',') ?? ['basic'];
  final expiryDays = int.tryParse(permissions['expires_in'] ?? '30') ?? 30;
  
  return jsonResponse(jsonEncode({
    'api_key': 'ak_${DateTime.now().millisecondsSinceEpoch}',
    'name': keyData['name'],
    'created_by': adminId,
    'admin_role': adminRole,
    'permissions': {
      'read': canRead,
      'write': canWrite,
      'delete': canDelete,
      'scopes': scopes,
    },
    'expires_at': DateTime.now().add(Duration(days: expiryDays)).toIso8601String(),
    'all_permissions': permissions,  // Complete permission control
  }));
}
```

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Recurso creado | `201` | Created - Recurso creado exitosamente |
| Operación exitosa | `200` | OK - Operación completada |
| Datos inválidos | `400` | Bad Request - Datos mal formateados |
| No autorizado | `401` | Unauthorized - Token JWT inválido |
| Prohibido | `403` | Forbidden - Sin permisos suficientes |
| Conflicto | `409` | Conflict - Recurso ya existe |
| Payload muy grande | `413` | Payload Too Large - Archivo muy grande |
| Error del servidor | `500` | Internal Server Error |

## 🌐 URL Resultantes

Si tu controller tiene `basePath: '/api/v1'` y usas `@Post(path: '/users')`, la URL final será:
```
POST http://localhost:8080/api/v1/users
```

## 📋 Ejemplo de Request/Response

### Request
```http
POST http://localhost:8080/api/users
Content-Type: application/json
Authorization: Bearer admin_token_123

{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user"
}
```

### Response
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "message": "User created successfully",
  "user": {
    "id": "user_1703123456789",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2024-12-21T10:30:56.789Z"
  }
}
```

---

**Siguiente**: [Documentación de @Put](put-annotation.md) | **Anterior**: [Documentación de @Get](get-annotation.md)