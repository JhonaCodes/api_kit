# @Delete - Anotación para Endpoints DELETE

## 📋 Descripción

La anotación `@Delete` se utiliza para marcar métodos como endpoints que responden a peticiones HTTP DELETE. Es la anotación estándar para operaciones de eliminación de recursos.

## 🎯 Propósito

- **Eliminar recursos**: Borrar registros o entidades específicas
- **Operaciones de limpieza**: Remover datos temporales o obsoletos
- **Gestión de relaciones**: Eliminar conexiones entre entidades
- **APIs de desactivación**: Soft delete o cambios de estado

## 📝 Sintaxis

```dart
@Delete({
  required String path,           // Ruta del endpoint (OBLIGATORIO)
  String? description,           // Descripción del endpoint
  int statusCode = 204,          // Código de respuesta por defecto (No Content)
  bool requiresAuth = true,      // Requiere autenticación por defecto
})
```

## 🔧 Parámetros

| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Sí | - | Ruta relativa del endpoint (ej: `/users/{id}`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Descripción legible del propósito del endpoint |
| `statusCode` | `int` | ❌ No | `204` | Código de estado HTTP de respuesta exitosa (No Content) |
| `requiresAuth` | `bool` | ❌ No | `true` | Indica si el endpoint requiere autenticación |

> **Nota**: DELETE requiere autenticación por defecto (`requiresAuth = true`) y devuelve 204 (No Content) ya que es una operación destructiva.

## 🚀 Ejemplos de Uso

### Ejemplo Básico

#### Traditional Approach - Manual JWT Extraction
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Delete(path: '/{id}')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> deleteUser(
    Request request,
    @PathParam('id') String userId,
  ) async {
    
    // Verificar que el usuario existe (en implementación real)
    if (userId.isEmpty || !userId.startsWith('user_')) {
      return Response.notFound(jsonEncode({
        'error': 'User not found',
        'user_id': userId
      }));
    }
    
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];
    
    // Simular eliminación
    // En implementación real: await userRepository.delete(userId);
    
    return Response(204); // No Content - eliminación exitosa
  }
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Delete(path: '/{id}')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> deleteUserEnhanced(
    @PathParam('id') String userId,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
    @RequestMethod() String method,
    @RequestHost() String host,
  ) async {
    
    // Verificar que el usuario existe (en implementación real)
    if (userId.isEmpty || !userId.startsWith('user_')) {
      return Response.notFound(jsonEncode({
        'error': 'User not found',
        'user_id': userId
      }));
    }
    
    // Direct JWT access - no manual extraction needed!
    final adminUser = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];
    
    // Enhanced logging with complete context
    final deletionLog = {
      'user_id': userId,
      'deleted_by': adminUser,
      'admin_role': adminRole,
      'method': method,
      'host': host,
      'deleted_at': DateTime.now().toIso8601String(),
    };
    
    // Simular eliminación y logging
    // En implementación real: await userRepository.delete(userId);
    // await auditLogger.logDeletion(deletionLog);
    
    return Response(204); // No Content - eliminación exitosa
  }
}
```

### Ejemplo con Confirmación y Log
```dart
@Delete(
  path: '/products/{productId}',
  description: 'Elimina un producto del catálogo',
  statusCode: 200 // Devolver información de confirmación
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> deleteProduct(
  Request request,
  @PathParam('productId', description: 'ID único del producto') String productId,
  @QueryParam('force', defaultValue: false, description: 'Forzar eliminación aunque tenga dependencias') bool force,
) async {
  
  // Validar formato del ID
  if (!productId.startsWith('prod_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid product ID format',
      'expected_format': 'prod_*',
      'received': productId
    }));
  }
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Verificar dependencias (simular check)
  final hasDependencies = productId == 'prod_123'; // Simular que este producto tiene dependencias
  
  if (hasDependencies && !force) {
    return Response(409, // Conflict
      body: jsonEncode({
        'error': 'Cannot delete product with existing dependencies',
        'product_id': productId,
        'dependencies': ['active_orders', 'shopping_carts'],
        'solution': 'Use force=true to delete anyway or remove dependencies first'
      }),
      headers: {'Content-Type': 'application/json'}
    );
  }
  
  // Registrar la eliminación
  final deletionRecord = {
    'product_id': productId,
    'deleted_by': adminUser,
    'deleted_at': DateTime.now().toIso8601String(),
    'forced': force,
    'had_dependencies': hasDependencies,
  };
  
  // Simular eliminación
  // En implementación real: 
  // if (force && hasDependencies) await cleanupDependencies(productId);
  // await productRepository.delete(productId);
  
  return jsonResponse(jsonEncode({
    'message': 'Product deleted successfully',
    'deletion_info': deletionRecord,
    'warnings': hasDependencies && force ? ['Dependencies were forcefully removed'] : [],
  }));
}
```

### Ejemplo de Soft Delete
```dart
@Delete(
  path: '/posts/{postId}',
  description: 'Desactiva un post (soft delete)',
  statusCode: 200
)
@JWTEndpoint([MyUserValidator()]) // Solo el autor puede eliminar
Future<Response> deletePost(
  Request request,
  @PathParam('postId', description: 'ID del post') String postId,
  @QueryParam('permanent', defaultValue: false, description: 'Eliminación permanente') bool permanent,
) async {
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final currentUser = jwtPayload['user_id'];
  
  // En implementación real, verificar que el usuario es el autor del post
  final postAuthor = 'user_123'; // Simular obtener autor de BD
  
  if (currentUser != postAuthor) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only delete your own posts',
      'post_id': postId,
      'current_user': currentUser,
      'post_author': postAuthor
    }));
  }
  
  final deletionResult = {
    'post_id': postId,
    'deletion_type': permanent ? 'hard_delete' : 'soft_delete',
    'deleted_by': currentUser,
    'deleted_at': DateTime.now().toIso8601String(),
  };
  
  if (!permanent) {
    // Soft delete - mantener datos pero marcar como eliminado
    deletionResult['status'] = 'deleted';
    deletionResult['recoverable_until'] = DateTime.now().add(Duration(days: 30)).toIso8601String();
    deletionResult['recovery_note'] = 'Post can be recovered within 30 days';
  } else {
    // Hard delete - eliminar permanentemente
    deletionResult['status'] = 'permanently_deleted';
    deletionResult['recovery_note'] = 'Post cannot be recovered';
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Post deleted successfully',
    'deletion': deletionResult,
  }));
}
```

### Ejemplo de Eliminación en Lote
```dart
@Delete(
  path: '/users/{userId}/notifications',
  description: 'Elimina todas las notificaciones del usuario'
)
@JWTEndpoint([MyUserValidator()])
Future<Response> deleteAllNotifications(
  Request request,
  @PathParam('userId', description: 'ID del usuario') String userId,
  @QueryParam('older_than_days', required: false, description: 'Solo eliminar notificaciones más antiguas que X días') int? olderThanDays,
  @QueryParam('type', required: false, description: 'Tipo de notificaciones a eliminar') String? notificationType,
) async {
  
  // Validar que el JWT corresponde al usuario
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only delete your own notifications',
      'token_user_id': tokenUserId,
      'requested_user_id': userId
    }));
  }
  
  // Construir filtros para la eliminación
  final filters = <String, dynamic>{
    'user_id': userId,
  };
  
  if (olderThanDays != null) {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
    filters['created_before'] = cutoffDate.toIso8601String();
  }
  
  if (notificationType != null) {
    final validTypes = ['email', 'push', 'sms', 'in_app'];
    if (!validTypes.contains(notificationType)) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid notification type',
        'received_type': notificationType,
        'valid_types': validTypes
      }));
    }
    filters['type'] = notificationType;
  }
  
  // Simular conteo y eliminación
  final simulatedCount = olderThanDays != null ? 15 : 45; // Simular cantidad
  final deletedCount = notificationType != null ? (simulatedCount * 0.3).round() : simulatedCount;
  
  final deletionResult = {
    'user_id': userId,
    'total_deleted': deletedCount,
    'filters_applied': filters,
    'deleted_at': DateTime.now().toIso8601String(),
  };
  
  // Agregar detalles por tipo si se especificó
  if (notificationType != null) {
    deletionResult['deleted_by_type'] = {
      notificationType: deletedCount
    };
  } else {
    deletionResult['deleted_by_type'] = {
      'email': (deletedCount * 0.4).round(),
      'push': (deletedCount * 0.3).round(),
      'in_app': (deletedCount * 0.3).round(),
    };
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Notifications deleted successfully',
    'deletion_summary': deletionResult,
    'affected_count': deletedCount,
  }));
}
```

### Ejemplo con Headers de Confirmación
```dart
@Delete(
  path: '/files/{fileId}',
  description: 'Elimina un archivo del sistema'
)
@JWTEndpoint([MyFileValidator()])
Future<Response> deleteFile(
  Request request,
  @PathParam('fileId', description: 'ID único del archivo') String fileId,
  @RequestHeader('X-Confirm-Delete', required: true, description: 'Confirmación de eliminación (debe ser "yes")') String confirmHeader,
  @QueryParam('remove_thumbnails', defaultValue: true, description: 'Eliminar thumbnails asociados') bool removeThumbnails,
) async {
  
  // Validar confirmación
  if (confirmHeader != 'yes') {
    return Response.badRequest(body: jsonEncode({
      'error': 'Deletion confirmation required',
      'required_header': 'X-Confirm-Delete: yes',
      'received_header': 'X-Confirm-Delete: $confirmHeader',
      'hint': 'This prevents accidental file deletion'
    }));
  }
  
  // Validar formato del file ID
  if (!fileId.startsWith('file_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid file ID format',
      'expected_format': 'file_*',
      'received': fileId
    }));
  }
  
  // Obtener información del JWT
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final currentUser = jwtPayload['user_id'];
  
  // Simular información del archivo
  final fileInfo = {
    'id': fileId,
    'filename': 'document.pdf',
    'size_bytes': 1048576,
    'owner': currentUser,
    'has_thumbnails': fileId.contains('image'),
  };
  
  // Preparar resultado de eliminación
  final deletionActions = <String>[];
  deletionActions.add('file_deleted');
  
  if (removeThumbnails && fileInfo['has_thumbnails'] == true) {
    deletionActions.add('thumbnails_deleted');
  }
  
  final deletionResult = {
    'file_id': fileId,
    'filename': fileInfo['filename'],
    'size_bytes': fileInfo['size_bytes'],
    'deleted_by': currentUser,
    'deleted_at': DateTime.now().toIso8601String(),
    'actions_performed': deletionActions,
    'confirmation_verified': true,
  };
  
  return jsonResponse(jsonEncode({
    'message': 'File deleted successfully',
    'deletion': deletionResult,
  }));
}
```

## 🔗 Combinación con Otras Anotaciones

### Con Múltiples Validadores para Operación Crítica
```dart
@Delete(path: '/financial/accounts/{accountId}', statusCode: 200)
@JWTController([
  MyFinancialValidator(clearanceLevel: 5), // Máximo nivel requerido
  MyBusinessHoursValidator(),
  MyTwoFactorValidator(), // Requiere 2FA
], requireAll: true)
Future<Response> deleteFinancialAccount(
  Request request,
  @PathParam('accountId') String accountId,
  @RequestHeader('X-Two-Factor-Token', required: true) String tfaToken,
) async {
  
  // Validaciones extra para operaciones financieras críticas
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final financialUser = jwtPayload['user_id'];
  
  return jsonResponse(jsonEncode({
    'message': 'Financial account deleted successfully',
    'account_id': accountId,
    'deleted_by': financialUser,
    'security_level': 'maximum',
    'tfa_verified': true,
  }));
}
```

## 💡 Mejores Prácticas

### ✅ Hacer
- **Validar existencia**: Verificar que el recurso existe antes de eliminar
- **Confirmar permisos**: Asegurarse de que el usuario puede eliminar el recurso
- **Registrar la acción**: Log de quién eliminó qué y cuándo
- **Manejar dependencias**: Verificar relaciones antes de eliminar
- **Considerar soft delete**: Para recursos importantes que podrían necesitar recuperación
- **Preferir Enhanced Parameters**: Para acceso completo sin Request parameter
- **Combinar enfoques**: Traditional para validación, Enhanced para contexto completo

### ❌ Evitar
- **Eliminación sin confirmación**: Para recursos críticos, requerir confirmación explícita
- **No validar permisos**: Siempre verificar autorización
- **Eliminar sin log**: Mantener registro de eliminaciones
- **Ignorar dependencias**: Puede crear inconsistencias en los datos
- **Hard delete por defecto**: Considerar soft delete para recuperabilidad
- **Request parameter redundante**: Usar Enhanced Parameters cuando sea posible

### 🎯 Recomendaciones Enhanced por Escenario

#### Para DELETE Simple con Auditoría
```dart
// ✅ Enhanced - Auditoría completa sin Request parameter
@Delete(path: '/posts/{id}')
Future<Response> deletePost(
  @PathParam('id') String id,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  // Complete audit trail without manual extraction
  final auditData = {
    'deleted_by': jwt['user_id'],
    'user_role': jwt['role'],
    'client_ip': headers['x-forwarded-for'],
    'user_agent': headers['user-agent'],
    'host': host,
  };
}
```

#### Para DELETE con Opciones Dinámicas
```dart
// ✅ Enhanced - Opciones de eliminación flexibles
@Delete(path: '/files/{id}')
Future<Response> deleteFile(
  @PathParam('id') String id,
  @QueryParam.all() Map<String, String> deleteOptions,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  final removeThumbnails = deleteOptions['remove_thumbnails']?.toLowerCase() == 'true';
  final permanentDelete = deleteOptions['permanent']?.toLowerCase() == 'true';
  final notifyOwner = deleteOptions['notify_owner']?.toLowerCase() != 'false';
  // Handle unlimited delete options dynamically
}
```

#### Para DELETE Crítico con Confirmación Enhanced
```dart
// ✅ Hybrid - Validación específica + contexto completo
@Delete(path: '/critical/{id}')
@JWTEndpoint([MyAdminValidator()])
Future<Response> deleteCritical(
  @PathParam('id') String id,
  @RequestHeader('X-Confirm-Delete', required: true) String confirmation,  // Type-safe
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,                // Direct
  @RequestHeader.all() Map<String, String> headers,                      // Complete
) async {
  // Secure deletion with complete audit trail
  if (confirmation != 'CONFIRMED') {
    return Response.badRequest(body: 'Confirmation required');
  }
}
```

#### Para Soft DELETE con Recuperación
```dart
// ✅ Enhanced - Soft delete con contexto completo
@Delete(path: '/documents/{id}', statusCode: 200)
Future<Response> softDeleteDocument(
  @PathParam('id') String id,
  @QueryParam.all() Map<String, String> deleteOptions,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestMethod() String method,
) async {
  final recoveryDays = int.tryParse(deleteOptions['recovery_days'] ?? '30') ?? 30;
  final permanent = deleteOptions['permanent']?.toLowerCase() == 'true';
  
  return jsonResponse(jsonEncode({
    'message': 'Document deleted successfully',
    'deletion_type': permanent ? 'hard' : 'soft',
    'recoverable_until': permanent ? null : 
      DateTime.now().add(Duration(days: recoveryDays)).toIso8601String(),
  }));
}
```

## 🔍 Tipos de Eliminación

### 1. **Hard Delete (Eliminación Física)**
```dart
@Delete(path: '/temp-files/{fileId}')
Future<Response> deleteTemporaryFile(Request request, @PathParam('fileId') String fileId) async {
  // Elimina completamente el archivo - no se puede recuperar
  return Response(204); // No Content
}
```

### 2. **Soft Delete (Eliminación Lógica)**
```dart
@Delete(path: '/posts/{postId}', statusCode: 200)
Future<Response> deletePost(Request request, @PathParam('postId') String postId) async {
  // Marca como eliminado pero mantiene los datos
  return jsonResponse(jsonEncode({
    'message': 'Post deleted successfully',
    'recoverable_until': DateTime.now().add(Duration(days: 30)).toIso8601String()
  }));
}
```

### 3. **Eliminación con Confirmación**
```dart
@Delete(path: '/critical-data/{id}')
Future<Response> deleteCriticalData(
  Request request, 
  @PathParam('id') String id,
  @RequestHeader('X-Confirm-Delete', required: true) String confirmation
) async {
  if (confirmation != 'CONFIRMED') {
    return Response.badRequest(body: 'Confirmation required');
  }
  // Proceder con eliminación
  return Response(204);
}
```

## 📊 Códigos de Respuesta Recomendados

| Situación | Código | Descripción |
|-----------|---------|-------------|
| Eliminación exitosa sin contenido | `204` | No Content - Recurso eliminado |
| Eliminación exitosa con info | `200` | OK - Con detalles de eliminación |
| Recurso no encontrado | `404` | Not Found - ID no existe |
| Confirmación requerida | `400` | Bad Request - Falta confirmación |
| Sin autorización | `401` | Unauthorized - Token JWT inválido |
| Prohibido | `403` | Forbidden - Sin permisos de eliminación |
| Tiene dependencias | `409` | Conflict - No se puede eliminar |
| Error del servidor | `500` | Internal Server Error |

## 🌐 URL Resultantes

Si tu controller tiene `basePath: '/api/v1'` y usas `@Delete(path: '/users/{id}')`, la URL final será:
```
DELETE http://localhost:8080/api/v1/users/{id}
```

## 📋 Ejemplo de Request/Response

### Request - Eliminación Simple
```http
DELETE http://localhost:8080/api/users/user_123
Authorization: Bearer admin_token_456
```

### Response - Sin contenido (204)
```http
HTTP/1.1 204 No Content
```

### Request - Eliminación con Confirmación
```http
DELETE http://localhost:8080/api/files/file_789?remove_thumbnails=true
Authorization: Bearer file_token_456
X-Confirm-Delete: yes
```

### Response - Con información (200)
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "File deleted successfully",
  "deletion": {
    "file_id": "file_789",
    "filename": "document.pdf",
    "size_bytes": 1048576,
    "deleted_by": "user_456",
    "deleted_at": "2024-12-21T10:30:56.789Z",
    "actions_performed": ["file_deleted", "thumbnails_deleted"],
    "confirmation_verified": true
  }
}
```

---

**Siguiente**: [Documentación de @RestController](restcontroller-annotation.md) | **Anterior**: [Documentación de @Patch](patch-annotation.md)