# @Patch - Anotación para Endpoints PATCH

## 📋 Descripción

La anotación `@Patch` se utiliza para marcar métodos como endpoints que responden a peticiones HTTP PATCH. Es la anotación estándar para operaciones de actualización parcial de recursos existentes.

## 🎯 Propósito

- **Actualización parcial**: Modificar solo algunos campos de un recurso existente
- **Operaciones eficientes**: Solo enviar y procesar campos modificados
- **Actualizaciones incrementales**: Cambios graduales sin afectar otros campos
- **APIs de configuración**: Modificar preferencias específicas sin tocar otras

## 📝 Sintaxis

```dart
@Patch({
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

> **Nota**: PATCH requiere autenticación por defecto (`requiresAuth = true`) ya que modifica recursos protegidos.

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach - Manual Body Parsing
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Patch(path: '/{id}')
  Future<Response> updateUserPartial(
    Request request,
    @PathParam('id') String userId,
  ) async {
    // Manual body parsing
    final body = await request.readAsString();
    final updates = jsonDecode(body) as Map<String, dynamic>;
    
    // Solo actualizar campos enviados
    final updatedFields = <String>[];
    final result = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Aplicar solo los campos enviados
    if (updates.containsKey('name')) {
      result['name'] = updates['name'];
      updatedFields.add('name');
    }
    
    if (updates.containsKey('email')) {
      result['email'] = updates['email'];
      updatedFields.add('email');
    }
    
    return jsonResponse(jsonEncode({
      'message': 'User updated successfully',
      'user': result,
      'updated_fields': updatedFields,
    }));
  }
}
```

#### Enhanced Approach - Direct Body Injection ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Patch(path: '/{id}')
  Future<Response> updateUserPartialEnhanced(
    @PathParam('id') String userId,
    @RequestBody() Map<String, dynamic> updates,  // Direct body injection
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    // No manual parsing needed!
    final updatedFields = <String>[];
    final result = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      'method_used': method,      // Direct access
      'endpoint_path': path,      // Direct access
    };
    
    // Aplicar solo los campos enviados
    if (updates.containsKey('name')) {
      result['name'] = updates['name'];
      updatedFields.add('name');
    }
    
    if (updates.containsKey('email')) {
      result['email'] = updates['email'];
      updatedFields.add('email');
    }
    
    // Enhanced: Handle any additional fields dynamically
    final allowedFields = ['name', 'email', 'phone', 'address'];
    for (final field in updates.keys) {
      if (!['name', 'email'].contains(field) && allowedFields.contains(field)) {
        result[field] = updates[field];
        updatedFields.add(field);
      }
    }
    
    return jsonResponse(jsonEncode({
      'message': 'User updated successfully - Enhanced!',
      'user': result,
      'updated_fields': updatedFields,
      'total_updates': updatedFields.length,
      'enhanced': true,
    }));
  }
}
```

### Ejemplo con Validación Selectiva
```dart
@Patch(
  path: '/products/{productId}',
  description: 'Actualiza campos específicos de un producto'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProductPartial(
  Request request,
  @PathParam('productId', description: 'ID único del producto') String productId,
  @RequestBody(required: true, description: 'Campos a actualizar del producto') 
  Map<String, dynamic> updates,
) async {
  
  if (updates.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'No fields to update',
      'hint': 'Include at least one field in the request body'
    }));
  }
  
  // Campos válidos para actualización
  final validFields = ['name', 'price', 'description', 'category', 'stock', 'tags'];
  final updatedFields = <String>[];
  final invalidFields = <String>[];
  
  // Validar que solo se envíen campos válidos
  for (final field in updates.keys) {
    if (validFields.contains(field)) {
      updatedFields.add(field);
    } else {
      invalidFields.add(field);
    }
  }
  
  if (invalidFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid fields in update request',
      'invalid_fields': invalidFields,
      'valid_fields': validFields
    }));
  }
  
  // Validaciones específicas por campo
  if (updates.containsKey('price')) {
    final price = updates['price'];
    if (price is! num || price <= 0) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Price must be a positive number',
        'received_price': price
      }));
    }
  }
  
  if (updates.containsKey('stock')) {
    final stock = updates['stock'];
    if (stock is! int || stock < 0) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Stock must be a non-negative integer',
        'received_stock': stock
      }));
    }
  }
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Construir respuesta con solo los campos actualizados
  final patchedProduct = <String, dynamic>{
    'id': productId,
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': adminUser,
  };
  
  // Agregar solo los campos que fueron actualizados
  for (final field in updatedFields) {
    patchedProduct[field] = updates[field];
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'product': patchedProduct,
    'updated_fields': updatedFields,
    'patch_summary': {
      'fields_updated': updatedFields.length,
      'total_valid_fields': validFields.length,
      'update_percentage': ((updatedFields.length / validFields.length) * 100).toStringAsFixed(1),
    },
  }));
}
```

### Ejemplo de Estado/Status Update
```dart
@Patch(
  path: '/orders/{orderId}/status',
  description: 'Actualiza el estado de una orden'
)
@JWTEndpoint([MyWarehouseValidator()])
Future<Response> updateOrderStatus(
  Request request,
  @PathParam('orderId', description: 'ID de la orden') String orderId,
  @QueryParam('notify_customer', defaultValue: true) bool notifyCustomer,
  @RequestBody(required: true) Map<String, dynamic> statusUpdate,
) async {
  
  // Validar que incluya el campo status
  if (!statusUpdate.containsKey('status')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Status field is required',
      'required_fields': ['status'],
      'optional_fields': ['notes', 'estimated_delivery']
    }));
  }
  
  final newStatus = statusUpdate['status'] as String?;
  final validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  
  if (newStatus == null || !validStatuses.contains(newStatus)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid status value',
      'received_status': newStatus,
      'valid_statuses': validStatuses
    }));
  }
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final warehouseUser = jwtPayload['user_id'];
  
  // Construir actualización de estado
  final statusUpdateResult = {
    'order_id': orderId,
    'status': newStatus,
    'updated_at': DateTime.now().toIso8601String(),
    'updated_by': warehouseUser,
  };
  
  // Campos opcionales
  if (statusUpdate.containsKey('notes')) {
    statusUpdateResult['notes'] = statusUpdate['notes'];
  }
  
  if (statusUpdate.containsKey('estimated_delivery') && newStatus == 'shipped') {
    statusUpdateResult['estimated_delivery'] = statusUpdate['estimated_delivery'];
  }
  
  // Simular notificación al cliente
  final actions = <String>[];
  if (notifyCustomer) {
    actions.add('customer_notified');
  }
  
  // Agregar acciones automáticas basadas en el estado
  if (newStatus == 'shipped') {
    actions.add('tracking_number_generated');
  } else if (newStatus == 'delivered') {
    actions.add('feedback_request_sent');
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Order status updated successfully',
    'order': statusUpdateResult,
    'previous_status': 'processing', // En una implementación real, obtener de BD
    'new_status': newStatus,
    'actions_performed': actions,
    'metadata': {
      'status_change_valid': true,
      'notification_sent': notifyCustomer,
      'update_type': 'status_patch',
    },
  }));
}
```

### Ejemplo de Configuración Parcial
```dart
@Patch(
  path: '/users/{userId}/preferences',
  description: 'Actualiza preferencias específicas del usuario'
)
@JWTEndpoint([MyUserValidator()]) // Solo el mismo usuario
Future<Response> updateUserPreferences(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(required: true, description: 'Preferencias a actualizar') 
  Map<String, dynamic> preferences,
) async {
  
  // Validar que el JWT corresponde al usuario
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only update your own preferences',
      'token_user_id': tokenUserId,
      'requested_user_id': userId
    }));
  }
  
  // Preferencias válidas que se pueden actualizar
  final validPreferences = {
    'theme': ['light', 'dark', 'auto'],
    'language': ['en', 'es', 'fr', 'de'],
    'notifications': null, // Object, validated separately
    'timezone': null, // String, validated separately
    'currency': ['USD', 'EUR', 'GBP', 'JPY'],
  };
  
  final updatedPreferences = <String, dynamic>{};
  final validationErrors = <String>[];
  
  for (final pref in preferences.keys) {
    if (!validPreferences.containsKey(pref)) {
      validationErrors.add('Unknown preference: $pref');
      continue;
    }
    
    final value = preferences[pref];
    final allowedValues = validPreferences[pref];
    
    // Validar valores específicos
    if (allowedValues != null && !allowedValues.contains(value)) {
      validationErrors.add('Invalid value for $pref: $value. Allowed: $allowedValues');
      continue;
    }
    
    // Validaciones especiales
    if (pref == 'notifications' && value is Map<String, dynamic>) {
      // Validar estructura de notificaciones
      final validNotificationKeys = ['email', 'push', 'sms'];
      final invalidKeys = value.keys.where((k) => !validNotificationKeys.contains(k));
      
      if (invalidKeys.isNotEmpty) {
        validationErrors.add('Invalid notification keys: $invalidKeys');
        continue;
      }
    }
    
    if (pref == 'timezone' && value is String) {
      // Validación básica de timezone
      if (!value.contains('/')) {
        validationErrors.add('Timezone must be in format: Continent/City');
        continue;
      }
    }
    
    updatedPreferences[pref] = value;
  }
  
  if (validationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Preference validation failed',
      'validation_errors': validationErrors,
      'valid_preferences': validPreferences.keys.toList(),
    }));
  }
  
  // Construir respuesta con preferencias actualizadas
  final preferencesUpdate = {
    'user_id': userId,
    'updated_preferences': updatedPreferences,
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  return jsonResponse(jsonEncode({
    'message': 'User preferences updated successfully',
    'preferences': preferencesUpdate,
    'updated_count': updatedPreferences.length,
    'update_summary': {
      'preferences_updated': updatedPreferences.keys.toList(),
      'total_available_preferences': validPreferences.length,
    },
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con Query Parameters para Opciones
```dart
@Patch(path: '/articles/{articleId}')
Future<Response> updateArticle(
  Request request,
  @PathParam('articleId') String articleId,
  @QueryParam('publish', defaultValue: false) bool shouldPublish,
  @QueryParam('send_notifications', defaultValue: false) bool sendNotifications,
  @RequestBody(required: true) Map<String, dynamic> updates,
) async {
  
  // Validar campos de artículo
  final validFields = ['title', 'content', 'tags', 'category', 'excerpt'];
  final updatedFields = updates.keys.where((k) => validFields.contains(k)).toList();
  
  if (updatedFields.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'No valid fields to update',
      'valid_fields': validFields
    }));
  }
  
  // Construir resultado
  final articleUpdate = <String, dynamic>{
    'id': articleId,
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  // Solo agregar campos actualizados
  for (final field in updatedFields) {
    articleUpdate[field] = updates[field];
  }
  
  // Aplicar acciones basadas en query parameters
  final actions = <String>[];
  if (shouldPublish) {
    articleUpdate['status'] = 'published';
    articleUpdate['published_at'] = DateTime.now().toIso8601String();
    actions.add('published');
  }
  
  if (sendNotifications && shouldPublish) {
    actions.add('subscribers_notified');
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Article updated successfully',
    'article': articleUpdate,
    'updated_fields': updatedFields,
    'actions_performed': actions,
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Validar campos enviados**: Verificar que sean válidos para actualización
- **Actualizar solo campos enviados**: No tocar campos no especificados
- **Devolver campos actualizados**: Mostrar qué cambió exactamente
- **Permitir actualizaciones vacías**: Devolver error si no hay campos
- **Validar tipos de datos**: Cada campo debe tener el tipo correcto
- **Preferir Enhanced Parameters**: Para acceso completo sin Request parameter
- **Combinar enfoques**: Traditional para validación específica, Enhanced para flexibilidad

### ❌ Evitar
- **Requerir todos los campos**: Eso es responsabilidad de PUT
- **Actualizar campos no enviados**: Solo modificar lo que se especifica
- **Ignorar validaciones por campo**: Cada campo debe validarse individualmente
- **Devolver el recurso completo**: Solo devolver campos actualizados y metadatos
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced por Escenario

#### Para PATCH con Validación Específica
```dart
// ✅ Traditional - Validación automática por campo
@Patch(path: '/users/{id}')
Future<Response> updateUser(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
) async {
  // Automatic validation for each field
}
```

#### Para PATCH con Contexto Completo
```dart
// ✅ Enhanced - Acceso completo sin Request parameter
@Patch(path: '/products/{id}')
Future<Response> updateProductEnhanced(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final updatedBy = jwt['user_id'];  // Direct access
  final userAgent = headers['user-agent'];  // All headers
}
```

#### Para PATCH con Opciones Dinámicas
```dart
// ✅ Enhanced - Opciones de actualización flexibles
@Patch(path: '/articles/{id}')
Future<Response> updateArticleWithOptions(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
  @QueryParam.all() Map<String, String> patchOptions,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  final notify = patchOptions['notify_subscribers']?.toLowerCase() == 'true';
  final autoPublish = patchOptions['auto_publish']?.toLowerCase() == 'true';
  // Handle unlimited patch options dynamically
}
```

#### Para PATCH de Status/Estado
```dart
// ✅ Hybrid - Validación específica + contexto enhanced
@Patch(path: '/orders/{id}/status')
Future<Response> updateOrderStatus(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> statusUpdate,
  @QueryParam('notify_customer', defaultValue: true) bool notify,  // Type-safe
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,         // Direct
  @RequestMethod() String method,
) async {
  // Secure status update with complete audit trail
}
```

## 🔍 Diferencias con PUT

| Aspecto | PUT | PATCH |
|---------|-----|--------|
| **Propósito** | Actualización completa | Actualización parcial |
| **Campos enviados** | Todos obligatorios | Solo los que se van a cambiar |
| **Campos faltantes** | Se establecen como null/default | Se mantienen sin cambios |
| **Validación** | Todos los campos | Solo campos enviados |
| **Idempotencia** | Siempre | Depende de la implementación |
| **Uso típico** | Reemplazar recurso | Modificar campos específicos |

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Actualización exitosa | `200` | OK - Campos actualizados |
| Sin campos para actualizar | `400` | Bad Request - Body vacío |
| Campos inválidos | `400` | Bad Request - Campos desconocidos |
| Recurso no encontrado | `404` | Not Found - ID no existe |
| Sin autorización | `401` | Unauthorized - Token JWT inválido |
| Prohibido | `403` | Forbidden - Sin permisos de modificación |
| Conflicto | `409` | Conflict - Conflicto de versiones |
| Error del servidor | `500` | Internal Server Error |

## 🌐 URL Resultantes

Si tu controller tiene `basePath: '/api/v1'` y usas `@Patch(path: '/users/{id}')`, la URL final será:
```
PATCH http://localhost:8080/api/v1/users/{id}
```

## 📋 Ejemplo de Request/Response

### Request - Actualizar solo el precio
```http
PATCH http://localhost:8080/api/products/prod_123
Content-Type: application/json
Authorization: Bearer admin_token_456

{
  "price": 199.99,
  "tags": ["sale", "popular"]
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
    "price": 199.99,
    "tags": ["sale", "popular"],
    "updated_at": "2024-12-21T10:30:56.789Z",
    "updated_by": "admin_456"
  },
  "updated_fields": ["price", "tags"],
  "patch_summary": {
    "fields_updated": 2,
    "total_valid_fields": 8,
    "update_percentage": "25.0"
  }
}
```

### Request - Solo actualizar estado
```http
PATCH http://localhost:8080/api/orders/order_456/status?notify_customer=true
Content-Type: application/json
Authorization: Bearer warehouse_token_789

{
  "status": "shipped",
  "notes": "Package dispatched via express delivery",
  "estimated_delivery": "2024-12-23"
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "Order status updated successfully",
  "order": {
    "order_id": "order_456",
    "status": "shipped",
    "notes": "Package dispatched via express delivery",
    "estimated_delivery": "2024-12-23",
    "updated_at": "2024-12-21T10:30:56.789Z",
    "updated_by": "warehouse_789"
  },
  "previous_status": "processing",
  "new_status": "shipped",
  "actions_performed": ["customer_notified", "tracking_number_generated"]
}
```

---

**Siguiente**: [Documentación de @Delete](delete-annotation.md) | **Anterior**: [Documentación de @Put](put-annotation.md)