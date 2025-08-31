# @RequestBody - Anotación para Cuerpo de Request

## 📋 Descripción

La anotación `@RequestBody` se utiliza para capturar y procesar el cuerpo (body) de las peticiones HTTP. Permite recibir datos estructurados enviados por el cliente, especialmente útil para operaciones POST, PUT y PATCH.

## 🎯 Propósito

- **Recibir datos estructurados**: Capturar JSON, XML u otros formatos de datos
- **Creación de recursos**: Procesar datos para crear nuevos registros
- **Actualización de datos**: Recibir información para modificar recursos existentes
- **Operaciones complejas**: Manejar payloads con múltiples campos y validaciones

## 📝 Sintaxis

```dart
@RequestBody({
  bool required = true,           // Si el body es obligatorio
  String? description,            // Descripción del contenido esperado
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `true` | Si el cuerpo de la petición debe estar presente |
| `description` | `String?` | ❌ No | `null` | Descripción del formato y contenido esperado |

## 🚀 Ejemplos de Uso

### Ejemplo Básico - Creación de Usuario
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Post(path: '/create')
  Future<Response> createUser(
    Request request,
    @RequestBody(required: true, description: 'Datos del nuevo usuario') 
    Map<String, dynamic> userData,
  ) async {
    
    // Validar campos obligatorios
    final requiredFields = ['name', 'email'];
    final missingFields = <String>[];
    
    for (final field in requiredFields) {
      if (!userData.containsKey(field) || userData[field] == null || userData[field].toString().isEmpty) {
        missingFields.add(field);
      }
    }
    
    if (missingFields.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Required fields missing',
        'missing_fields': missingFields,
        'received_data': userData
      }));
    }
    
    // Validar formato de email
    final email = userData['email'] as String;
    if (!email.contains('@') || !email.contains('.')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid email format',
        'email': email,
        'expected_format': 'user@domain.com'
      }));
    }
    
    // Crear usuario
    final newUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': userData['name'],
      'email': userData['email'],
      'phone': userData['phone'], // Opcional
      'created_at': DateTime.now().toIso8601String(),
    };
    
    return Response(201, 
      body: jsonEncode({
        'message': 'User created successfully',
        'user': newUser
      }),
      headers: {'Content-Type': 'application/json'}
    );
  }
}

// Ejemplo de request:
// POST /api/users/create
// Content-Type: application/json
// 
// {
//   "name": "John Doe",
//   "email": "john@example.com",
//   "phone": "+1234567890"
// }
```

### Ejemplo con Validación Compleja
```dart
@Post(path: '/products')
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProduct(
  Request request,
  @RequestBody(
    required: true, 
    description: 'Datos completos del producto incluyendo nombre, precio, categoría y especificaciones'
  ) Map<String, dynamic> productData,
) async {
  
  // Validaciones de estructura
  final validationErrors = <String>[];
  
  // Validar nombre
  final name = productData['name'] as String?;
  if (name == null || name.trim().isEmpty) {
    validationErrors.add('Product name is required and cannot be empty');
  } else if (name.length < 3) {
    validationErrors.add('Product name must be at least 3 characters long');
  } else if (name.length > 100) {
    validationErrors.add('Product name cannot exceed 100 characters');
  }
  
  // Validar precio
  final price = productData['price'];
  if (price == null) {
    validationErrors.add('Product price is required');
  } else if (price is! num) {
    validationErrors.add('Product price must be a number');
  } else if (price <= 0) {
    validationErrors.add('Product price must be greater than 0');
  } else if (price > 999999.99) {
    validationErrors.add('Product price cannot exceed 999,999.99');
  }
  
  // Validar categoría
  final category = productData['category'] as String?;
  final validCategories = ['electronics', 'clothing', 'books', 'home', 'sports'];
  if (category == null || !validCategories.contains(category)) {
    validationErrors.add('Product category must be one of: ${validCategories.join(', ')}');
  }
  
  // Validar stock (opcional)
  final stock = productData['stock'];
  if (stock != null && (stock is! int || stock < 0)) {
    validationErrors.add('Stock must be a non-negative integer');
  }
  
  // Validar especificaciones (opcional)
  final specifications = productData['specifications'];
  if (specifications != null && specifications is! Map<String, dynamic>) {
    validationErrors.add('Specifications must be an object with key-value pairs');
  }
  
  // Validar tags (opcional)
  final tags = productData['tags'];
  if (tags != null) {
    if (tags is! List) {
      validationErrors.add('Tags must be an array of strings');
    } else {
      final invalidTags = tags.where((tag) => tag is! String).toList();
      if (invalidTags.isNotEmpty) {
        validationErrors.add('All tags must be strings');
      }
      if (tags.length > 10) {
        validationErrors.add('Maximum 10 tags allowed');
      }
    }
  }
  
  // Retornar errores si existen
  if (validationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Product validation failed',
      'validation_errors': validationErrors,
      'received_data': productData,
      'valid_example': {
        'name': 'iPhone 15 Pro',
        'price': 999.99,
        'category': 'electronics',
        'stock': 50,
        'specifications': {
          'color': 'Space Black',
          'storage': '256GB',
          'screen_size': '6.1 inches'
        },
        'tags': ['smartphone', 'apple', 'premium']
      }
    }));
  }
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Crear producto
  final newProduct = {
    'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
    'name': name!.trim(),
    'price': price,
    'category': category,
    'stock': stock ?? 0,
    'specifications': specifications ?? {},
    'tags': tags ?? [],
    'created_by': adminUser,
    'created_at': DateTime.now().toIso8601String(),
    'status': 'active',
  };
  
  return Response(201,
    body: jsonEncode({
      'message': 'Product created successfully',
      'product': newProduct,
      'validation_summary': {
        'fields_validated': ['name', 'price', 'category', 'stock', 'specifications', 'tags'],
        'validation_passed': true,
      }
    }),
    headers: {'Content-Type': 'application/json'}
  );
}
```

### Ejemplo de Actualización Parcial (PATCH)
```dart
@Patch(path: '/users/{userId}')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUser(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(
    required: true,
    description: 'Campos del usuario a actualizar (solo incluir campos que se quieren modificar)'
  ) Map<String, dynamic> updates,
) async {
  
  // Verificar que hay algo que actualizar
  if (updates.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'No fields to update',
      'hint': 'Include at least one field in the request body',
      'updatable_fields': ['name', 'email', 'phone', 'preferences']
    }));
  }
  
  // Validar que el usuario del JWT coincide con el del path
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId
    }));
  }
  
  // Campos válidos para actualización
  final validFields = ['name', 'email', 'phone', 'preferences'];
  final updatedFields = <String>[];
  final invalidFields = <String>[];
  final validationErrors = <String>[];
  
  // Validar cada campo enviado
  for (final field in updates.keys) {
    if (!validFields.contains(field)) {
      invalidFields.add(field);
      continue;
    }
    
    final value = updates[field];
    
    // Validaciones específicas por campo
    switch (field) {
      case 'name':
        if (value is! String || value.trim().isEmpty) {
          validationErrors.add('Name must be a non-empty string');
        } else if (value.length < 2 || value.length > 100) {
          validationErrors.add('Name must be between 2 and 100 characters');
        } else {
          updatedFields.add(field);
        }
        break;
        
      case 'email':
        if (value is! String || !value.contains('@') || !value.contains('.')) {
          validationErrors.add('Email must be a valid email address');
        } else {
          updatedFields.add(field);
        }
        break;
        
      case 'phone':
        if (value != null && (value is! String || value.length < 10)) {
          validationErrors.add('Phone must be a valid phone number (min 10 digits)');
        } else {
          updatedFields.add(field);
        }
        break;
        
      case 'preferences':
        if (value is! Map<String, dynamic>) {
          validationErrors.add('Preferences must be an object');
        } else {
          updatedFields.add(field);
        }
        break;
    }
  }
  
  // Retornar errores si existen
  if (invalidFields.isNotEmpty || validationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Update validation failed',
      'invalid_fields': invalidFields,
      'validation_errors': validationErrors,
      'valid_fields': validFields,
    }));
  }
  
  // Construir respuesta con campos actualizados
  final userUpdate = <String, dynamic>{
    'user_id': userId,
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  // Agregar solo los campos que se actualizaron
  for (final field in updatedFields) {
    userUpdate[field] = updates[field];
  }
  
  return jsonResponse(jsonEncode({
    'message': 'User updated successfully',
    'user': userUpdate,
    'updated_fields': updatedFields,
    'update_summary': {
      'fields_updated': updatedFields.length,
      'validation_passed': true,
    }
  }));
}
```

### Ejemplo con Múltiples Tipos de Body
```dart
@Post(path: '/files/upload')
@JWTEndpoint([MyFileValidator()])
Future<Response> uploadFile(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestBody(
    required: true,
    description: 'Metadatos del archivo o contenido base64 dependiendo del Content-Type'
  ) Map<String, dynamic> fileData,
) async {
  
  if (contentType.contains('application/json')) {
    // Modo metadatos - el archivo se sube por separado
    final requiredMetadata = ['filename', 'size', 'content_type'];
    final missingMetadata = requiredMetadata
        .where((field) => !fileData.containsKey(field))
        .toList();
    
    if (missingMetadata.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Missing file metadata',
        'missing_fields': missingMetadata,
        'required_fields': requiredMetadata
      }));
    }
    
    final filename = fileData['filename'] as String;
    final size = fileData['size'] as int;
    final fileContentType = fileData['content_type'] as String;
    
    // Validar tamaño
    const maxSize = 50 * 1024 * 1024; // 50MB
    if (size > maxSize) {
      return Response.badRequest(body: jsonEncode({
        'error': 'File size exceeds maximum allowed',
        'file_size': size,
        'max_size': maxSize,
        'max_size_mb': maxSize / (1024 * 1024)
      }));
    }
    
    final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';
    
    return jsonResponse(jsonEncode({
      'message': 'File metadata received successfully',
      'file_id': fileId,
      'filename': filename,
      'size_bytes': size,
      'content_type': fileContentType,
      'upload_url': '/api/files/upload/$fileId/content',
      'expires_at': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    }));
    
  } else if (contentType.contains('multipart/form-data')) {
    // Modo upload directo (simulado)
    return jsonResponse(jsonEncode({
      'message': 'Multipart upload not implemented in this example',
      'hint': 'Use application/json with metadata first'
    }));
    
  } else {
    return Response.badRequest(body: jsonEncode({
      'error': 'Unsupported content type',
      'content_type': contentType,
      'supported_types': ['application/json', 'multipart/form-data']
    }));
  }
}
```

### Ejemplo con Validación de Schema
```dart
@Post(path: '/webhooks/payment')
@JWTPublic() // Los webhooks pueden venir sin JWT
Future<Response> handlePaymentWebhook(
  Request request,
  @RequestHeader('X-Webhook-Signature', required: true) String signature,
  @RequestBody(
    required: true,
    description: 'Payload del webhook de pago con evento y datos'
  ) Map<String, dynamic> webhookPayload,
) async {
  
  // Validar estructura básica del webhook
  final requiredFields = ['event', 'data', 'timestamp'];
  final missingFields = requiredFields
      .where((field) => !webhookPayload.containsKey(field))
      .toList();
  
  if (missingFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid webhook payload structure',
      'missing_fields': missingFields,
      'expected_structure': {
        'event': 'payment.completed | payment.failed | payment.refunded',
        'data': 'object with payment details',
        'timestamp': 'ISO 8601 timestamp'
      }
    }));
  }
  
  final event = webhookPayload['event'] as String;
  final data = webhookPayload['data'] as Map<String, dynamic>;
  final timestamp = webhookPayload['timestamp'] as String;
  
  // Validar evento
  final validEvents = ['payment.completed', 'payment.failed', 'payment.refunded'];
  if (!validEvents.contains(event)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid webhook event',
      'event': event,
      'valid_events': validEvents
    }));
  }
  
  // Validar timestamp
  DateTime eventTime;
  try {
    eventTime = DateTime.parse(timestamp);
  } catch (e) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid timestamp format',
      'timestamp': timestamp,
      'expected_format': 'ISO 8601 (2024-12-21T10:30:56.789Z)'
    }));
  }
  
  // Validar que el evento no sea muy antiguo (más de 5 minutos)
  final now = DateTime.now();
  if (now.difference(eventTime).inMinutes > 5) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Webhook event too old',
      'event_timestamp': timestamp,
      'current_timestamp': now.toIso8601String(),
      'max_age_minutes': 5
    }));
  }
  
  // Validar datos según el tipo de evento
  final requiredDataFields = <String>[];
  switch (event) {
    case 'payment.completed':
      requiredDataFields.addAll(['payment_id', 'amount', 'currency', 'customer_id']);
      break;
    case 'payment.failed':
      requiredDataFields.addAll(['payment_id', 'error_code', 'error_message']);
      break;
    case 'payment.refunded':
      requiredDataFields.addAll(['payment_id', 'refund_id', 'amount']);
      break;
  }
  
  final missingDataFields = requiredDataFields
      .where((field) => !data.containsKey(field))
      .toList();
  
  if (missingDataFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Missing required data fields for event type',
      'event': event,
      'missing_data_fields': missingDataFields,
      'required_fields': requiredDataFields
    }));
  }
  
  // TODO: Verificar signature del webhook para seguridad
  // final calculatedSignature = calculateWebhookSignature(webhookPayload);
  // if (signature != calculatedSignature) { ... }
  
  // Procesar el webhook
  final webhookId = 'webhook_${DateTime.now().millisecondsSinceEpoch}';
  
  return jsonResponse(jsonEncode({
    'message': 'Webhook processed successfully',
    'webhook_id': webhookId,
    'event': event,
    'processed_at': DateTime.now().toIso8601String(),
    'validation_summary': {
      'structure_valid': true,
      'timestamp_valid': true,
      'data_fields_valid': true,
      'signature_verified': true, // Simulado
    }
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con Path Parameters y Headers
```dart
@Put(path: '/stores/{storeId}/products/{productId}')
Future<Response> updateStoreProduct(
  Request request,
  // Path Parameters
  @PathParam('storeId') String storeId,
  @PathParam('productId') String productId,
  
  // Headers
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader('X-Store-Token', required: true) String storeToken,
  
  // Request Body
  @RequestBody(
    required: true,
    description: 'Datos actualizados del producto'
  ) Map<String, dynamic> productUpdates,
) async {
  
  // Validar content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: 'Content-Type must be application/json');
  }
  
  // El resto de la lógica...
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'store_id': storeId,
    'product_id': productId,
    'updates': productUpdates
  }));
}
```

## ❓ FAQ: ¿Por qué Request + @RequestBody?

### Duda Común
"¿Por qué necesito tanto `Request request` como `@RequestBody()`? ¿No debería ser automático como en Spring Boot?"

### Respuesta
**¡Tienes razón!** - El framework ha evolucionado y ya **NO necesitas** el `Request request` redundante. Ahora puedes usar **Enhanced Parameters** para acceso directo:

- **`@RequestBody()`**: Parsea automáticamente el JSON del body
- **Enhanced Parameters**: Acceso directo a JWT, headers, contexto **SIN** Request parameter

### ❌ Enfoque Anterior (Redundante)
```dart
@Post(path: '/users')
@JWTEndpoint([MyUserValidator()])
Future<Response> createUser(
  Request request, // ❌ YA NO ES NECESARIO
  @RequestBody(required: true) Map<String, dynamic> userData,
) async {
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final userId = jwtPayload['user_id'];
  
  final name = userData['name'];
}
```

### ✅ Enfoque Actual (Enhanced Parameters) ✨
```dart
@Post(path: '/users')
@JWTEndpoint([MyUserValidator()])
Future<Response> createUserEnhanced(
  @RequestBody(required: true) Map<String, dynamic> userData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT!
  @RequestHeader.all() Map<String, String> headers,              // All headers!
  @RequestHost() String host,                                    // Direct host!
) async {
  // Direct access - no manual extraction needed!
  final userId = jwtPayload['user_id'];
  final userAgent = headers['user-agent'];
  final name = userData['name'];
  
  return jsonResponse(jsonEncode({
    'message': 'User created successfully - Enhanced!',
    'user': {'name': name, 'created_by': userId},
    'context': {'host': host, 'user_agent': userAgent},
    'enhanced': true,
  }));
}
```

### 💫 Beneficios del Enhanced Approach
1. **Sin Request parameter** - Eliminamos la redundancia
2. **Acceso directo al JWT** - `@RequestContext('jwt_payload')` inyecta directamente
3. **Headers completos** - `@RequestHeader.all()` da acceso a todo
4. **Información de request** - `@RequestHost()`, `@RequestMethod()`, etc.
5. **Código más limpio** - Menos boilerplate, más declarativo

### 🔄 Comparación Completa

#### Traditional (Verbose)
```dart
@Post(path: '/products')
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProduct(
  Request request,                                    // ❌ Manual parameter
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  // Manual extractions
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  final userAgent = request.headers['user-agent'];
  final method = request.method;
  
  // Business logic...
}
```

#### Enhanced (Declarative) ✨
```dart
@Post(path: '/products')
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProductEnhanced(
  @RequestBody(required: true) Map<String, dynamic> productData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,  // Direct
  @RequestHeader.all() Map<String, String> headers,               // Complete
  @RequestMethod() String method,                                 // Direct
  @RequestHost() String host,                                     // Direct
) async {
  // Direct access - no manual extraction!
  final adminUser = jwtPayload['user_id'];
  final userAgent = headers['user-agent'] ?? 'unknown';
  
  // Business logic with enhanced context...
  return jsonResponse(jsonEncode({
    'message': 'Product created - Enhanced!',
    'product': productData,
    'created_by': adminUser,
    'method': method,
    'host': host,
    'enhanced': true,
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Usar @RequestBody cuando esté disponible**: Evita parsing manual
- **Preferir Enhanced Parameters**: Elimina el Request parameter redundante
- **Combinar enfoques**: @RequestBody + Enhanced Parameters para contexto completo
- **Validar siempre**: Verificar estructura, tipos y valores de los datos
- **Proporcionar ejemplos**: En descripciones y mensajes de error
- **Documentar estructura esperada**: Especificar campos obligatorios y opcionales

### ❌ Evitar
- **Parsing manual con @RequestBody presente**: Es redundante y confuso
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible
- **Usar solo Request para todo**: Aprovecha las anotaciones automáticas
- **Mensajes de error genéricos**: Ser específico sobre qué está mal
- **No sanitizar entrada**: Validar y limpiar datos de entrada

### 🎯 Recomendaciones Enhanced por Escenario

#### Para Creación de Recursos con JWT
```dart
// ✅ Enhanced - Sin Request parameter
@Post(path: '/posts')
@JWTEndpoint([MyUserValidator()])
Future<Response> createPost(
  @RequestBody(required: true) Map<String, dynamic> postData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHost() String host,
) async {
  final authorId = jwt['user_id'];
  
  return jsonResponse(jsonEncode({
    'message': 'Post created successfully',
    'post': postData,
    'author_id': authorId,
    'created_on_host': host,
  }));
}
```

#### Para Actualización con Validación Compleja
```dart
// ✅ Enhanced - Contexto completo para auditoría
@Put(path: '/products/{id}')
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProduct(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> productData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
) async {
  // Complete audit trail without Request parameter
  final auditData = {
    'product_id': id,
    'updated_by': jwt['user_id'],
    'admin_role': jwt['role'],
    'method': method,
    'user_agent': headers['user-agent'],
    'content_type': headers['content-type'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated',
    'product_id': id,
    'audit_trail': auditData,
  }));
}
```

#### Para APIs Públicas con Contexto
```dart
// ✅ Enhanced - Información completa sin JWT
@Post(path: '/contact')
@JWTPublic()
Future<Response> submitContact(
  @RequestBody(required: true) Map<String, dynamic> contactData,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
  @RequestPath() String path,
) async {
  // Enhanced context tracking for public endpoints
  final submissionContext = {
    'submitted_from': host,
    'endpoint': path,
    'user_agent': headers['user-agent'],
    'referer': headers['referer'],
    'client_ip': headers['x-forwarded-for'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Contact form submitted',
    'contact_id': 'contact_${DateTime.now().millisecondsSinceEpoch}',
    'submission_context': submissionContext,
  }));
}
```

#### Para Webhooks con Validación Enhanced
```dart
// ✅ Enhanced - Webhook processing con contexto completo
@Post(path: '/webhooks/payment')
@JWTPublic()
Future<Response> processWebhook(
  @RequestBody(required: true) Map<String, dynamic> webhookData,
  @RequestHeader('X-Webhook-Signature', required: true) String signature,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestHost() String host,
  @RequestMethod() String method,
) async {
  // Enhanced webhook processing with complete context
  final webhookContext = {
    'signature': signature,
    'host': host,
    'method': method,
    'content_type': allHeaders['content-type'],
    'user_agent': allHeaders['user-agent'],
    'received_headers': allHeaders.keys.toList(),
  };
  
  return jsonResponse(jsonEncode({
    'webhook_id': 'wh_${DateTime.now().millisecondsSinceEpoch}',
    'status': 'processed',
    'context': webhookContext,
  }));
}
```

## 🔍 Tipos de Request Body

### 1. **Creación de recursos**
```dart
@RequestBody(required: true, description: 'Datos completos para crear el recurso')
Map<String, dynamic> resourceData,
```

### 2. **Actualización parcial**
```dart
@RequestBody(required: true, description: 'Campos a actualizar (solo incluir los modificados)')
Map<String, dynamic> updates,
```

### 3. **Configuración/Settings**
```dart
@RequestBody(required: true, description: 'Configuración completa o parcial')
Map<String, dynamic> settings,
```

### 4. **Operaciones complejas**
```dart
@RequestBody(required: true, description: 'Parámetros de la operación compleja')
Map<String, dynamic> operationParams,
```

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Body requerido faltante | `400` | Bad Request - Request body required |
| JSON malformado | `400` | Bad Request - Invalid JSON format |
| Campos obligatorios faltantes | `400` | Bad Request - Required fields missing |
| Tipos de datos incorrectos | `400` | Bad Request - Invalid data types |
| Valores fuera de rango | `400` | Bad Request - Values out of valid range |
| Body demasiado grande | `413` | Payload Too Large |

## 🌐 Ejemplo de Request/Response

### Request
```http
POST /api/products
Content-Type: application/json
Authorization: Bearer admin_token_123

{
  "name": "iPhone 15 Pro",
  "price": 999.99,
  "category": "electronics",
  "stock": 50,
  "specifications": {
    "color": "Space Black",
    "storage": "256GB"
  },
  "tags": ["smartphone", "apple", "premium"]
}
```

### Response
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "message": "Product created successfully",
  "product": {
    "id": "prod_1703123456789",
    "name": "iPhone 15 Pro",
    "price": 999.99,
    "category": "electronics",
    "stock": 50,
    "specifications": {
      "color": "Space Black",
      "storage": "256GB"
    },
    "tags": ["smartphone", "apple", "premium"],
    "created_by": "admin_123",
    "created_at": "2024-12-21T10:30:56.789Z",
    "status": "active"
  }
}
```

---

**Siguiente**: [Documentación de @RequestHeader](requestheader-annotation.md) | **Anterior**: [Documentación de @QueryParam](queryparam-annotation.md)