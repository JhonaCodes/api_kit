# 🗑️ DELETE Requests

Los **DELETE requests** son para **eliminar** recursos del servidor. Son idempotentes (eliminar múltiples veces produce el mismo resultado).

## 🎯 Tipos de DELETE

### 1. **Eliminar por ID** - `DELETE /api/resources/{id}`
### 2. **Eliminación Suave** - Marcar como inactivo
### 3. **Eliminación en Lote** - Múltiples recursos
### 4. **Eliminación Condicional** - Con validaciones

---

## 🗑️ 1. Eliminación Simple por ID

```dart
@Controller('/api/users')
class UserController extends BaseController {
  
  static final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'user',
      'active': true,
      'created_at': '2024-01-01T00:00:00Z',
      'deleted_at': null,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'role': 'admin',
      'active': true,
      'created_at': '2024-01-02T00:00:00Z',
      'deleted_at': null,
    }
  ];

  // DELETE /api/users/{id}
  @DELETE('/<id>')
  Future<Response> deleteUser(Request request) async {
    final userId = getRequiredParam(request, 'id');
    logRequest(request, 'Deleting user $userId');
    
    try {
      // Verificar autorización (solo admin puede eliminar usuarios)
      final authHeader = getOptionalHeader(request, 'Authorization');
      if (authHeader == null) {
        final response = ApiResponse.error('Authorization required');
        return jsonResponse(response.toJson(), statusCode: 401);
      }
      
      final currentUserRole = _extractUserRoleFromToken(authHeader);
      if (currentUserRole != 'admin') {
        final response = ApiResponse.error('Admin privileges required');
        return jsonResponse(response.toJson(), statusCode: 403);
      }
      
      // Encontrar usuario
      final userIndex = _users.indexWhere((user) => 
          user['id'] == userId && user['deleted_at'] == null);
      
      if (userIndex == -1) {
        final response = ApiResponse.error('User not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      final user = _users[userIndex];
      
      // Verificar si es el último admin
      if (user['role'] == 'admin') {
        final activeAdmins = _users.where((u) => 
            u['role'] == 'admin' && 
            u['deleted_at'] == null && 
            u['id'] != userId).length;
        
        if (activeAdmins == 0) {
          final response = ApiResponse.error('Cannot delete the last admin user');
          return jsonResponse(response.toJson(), statusCode: 400);
        }
      }
      
      // Eliminación física (remover completamente)
      _users.removeAt(userIndex);
      
      print('🗑️ User deleted: ${user['name']} (${user['email']})');
      
      final response = ApiResponse.success({
        'deleted_user': {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
        },
        'deleted_at': DateTime.now().toIso8601String(),
      }, 'User deleted successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error deleting user: $e');
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }
}
```

**Test:**
```bash
# Eliminar usuario (requiere permisos de admin)
curl -X DELETE http://localhost:8080/api/users/1 \
  -H "Authorization: Bearer admin-token"

# Error - sin autorización
curl -X DELETE http://localhost:8080/api/users/1
```

---

## 🔄 2. Eliminación Suave (Soft Delete)

```dart
@Controller('/api/posts')
class PostController extends BaseController {
  
  static final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'title': 'My First Post',
      'content': 'This is my first blog post',
      'author_id': '1',
      'status': 'published',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'deleted_at': null,
    }
  ];

  // DELETE /api/posts/{id} - Soft delete
  @DELETE('/<id>')
  Future<Response> deletePost(Request request) async {
    final postId = getRequiredParam(request, 'id');
    logRequest(request, 'Soft deleting post $postId');
    
    try {
      // Verificar autorización
      final authHeader = getOptionalHeader(request, 'Authorization');
      if (authHeader == null) {
        final response = ApiResponse.error('Authorization required');
        return jsonResponse(response.toJson(), statusCode: 401);
      }
      
      final currentUserId = _extractUserIdFromToken(authHeader);
      final currentUserRole = _extractUserRoleFromToken(authHeader);
      
      // Encontrar post no eliminado
      final postIndex = _posts.indexWhere((post) => 
          post['id'] == postId && post['deleted_at'] == null);
      
      if (postIndex == -1) {
        final response = ApiResponse.error('Post not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      final post = _posts[postIndex];
      
      // Verificar permisos: solo el autor o admin pueden eliminar
      if (post['author_id'] != currentUserId && currentUserRole != 'admin') {
        final response = ApiResponse.error('You can only delete your own posts');
        return jsonResponse(response.toJson(), statusCode: 403);
      }
      
      // Soft delete - marcar como eliminado
      post['deleted_at'] = DateTime.now().toIso8601String();
      post['deleted_by'] = currentUserId;
      post['status'] = 'deleted';
      
      print('🗑️ Post soft deleted: ${post['title']} by user $currentUserId');
      
      final response = ApiResponse.success({
        'deleted_post': {
          'id': post['id'],
          'title': post['title'],
          'deleted_at': post['deleted_at'],
        },
        'restoration_info': 'This post can be restored within 30 days',
      }, 'Post deleted successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error deleting post: $e');
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  // POST /api/posts/{id}/restore - Restaurar post eliminado
  @POST('/<id>/restore')
  Future<Response> restorePost(Request request) async {
    final postId = getRequiredParam(request, 'id');
    logRequest(request, 'Restoring post $postId');
    
    try {
      final authHeader = getOptionalHeader(request, 'Authorization');
      if (authHeader == null) {
        final response = ApiResponse.error('Authorization required');
        return jsonResponse(response.toJson(), statusCode: 401);
      }
      
      final currentUserId = _extractUserIdFromToken(authHeader);
      final currentUserRole = _extractUserRoleFromToken(authHeader);
      
      // Encontrar post eliminado
      final postIndex = _posts.indexWhere((post) => 
          post['id'] == postId && post['deleted_at'] != null);
      
      if (postIndex == -1) {
        final response = ApiResponse.error('Deleted post not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      final post = _posts[postIndex];
      
      // Verificar permisos
      if (post['author_id'] != currentUserId && currentUserRole != 'admin') {
        final response = ApiResponse.error('You can only restore your own posts');
        return jsonResponse(response.toJson(), statusCode: 403);
      }
      
      // Verificar que no hayan pasado más de 30 días
      final deletedAt = DateTime.parse(post['deleted_at']);
      final daysSinceDeleted = DateTime.now().difference(deletedAt).inDays;
      
      if (daysSinceDeleted > 30) {
        final response = ApiResponse.error('Post cannot be restored after 30 days');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Restaurar post
      post['deleted_at'] = null;
      post['deleted_by'] = null;
      post['status'] = 'published';
      post['restored_at'] = DateTime.now().toIso8601String();
      post['restored_by'] = currentUserId;
      
      print('♻️ Post restored: ${post['title']} by user $currentUserId');
      
      final response = ApiResponse.success(post, 'Post restored successfully');
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error restoring post: $e');
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }
}
```

**Tests:**
```bash
# Soft delete de post
curl -X DELETE http://localhost:8080/api/posts/1 \
  -H "Authorization: Bearer user-token"

# Restaurar post
curl -X POST http://localhost:8080/api/posts/1/restore \
  -H "Authorization: Bearer user-token"
```

---

## 📦 3. Eliminación en Lote

```dart
@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Product 1', 'category': 'electronics', 'active': true},
    {'id': '2', 'name': 'Product 2', 'category': 'clothing', 'active': true},
    {'id': '3', 'name': 'Product 3', 'category': 'electronics', 'active': true},
  ];

  // DELETE /api/products/batch
  @DELETE('/batch')
  Future<Response> deleteProductsBatch(Request request) async {
    logRequest(request, 'Batch deleting products');
    
    try {
      // Verificar autorización de admin
      final authHeader = getOptionalHeader(request, 'Authorization');
      if (authHeader == null) {
        final response = ApiResponse.error('Authorization required');
        return jsonResponse(response.toJson(), statusCode: 401);
      }
      
      final currentUserRole = _extractUserRoleFromToken(authHeader);
      if (currentUserRole != 'admin') {
        final response = ApiResponse.error('Admin privileges required');
        return jsonResponse(response.toJson(), statusCode: 403);
      }
      
      // Leer IDs a eliminar
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body with product IDs is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (!data.containsKey('product_ids') || data['product_ids'] is! List) {
        final response = ApiResponse.error('product_ids array is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final productIds = List<String>.from(data['product_ids']);
      
      if (productIds.isEmpty) {
        final response = ApiResponse.error('At least one product ID is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      if (productIds.length > 100) {
        final response = ApiResponse.error('Cannot delete more than 100 products at once');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Verificar confirmación para lotes grandes
      final confirmDeletion = data['confirm_deletion'] ?? false;
      if (productIds.length > 10 && !confirmDeletion) {
        final response = ApiResponse.error(
          'Deleting ${productIds.length} products requires confirmation. '
          'Add "confirm_deletion": true to proceed.'
        );
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Procesar eliminaciones
      final deletedProducts = <Map<String, dynamic>>[];
      final notFoundIds = <String>[];
      final errors = <String>[];
      
      for (final productId in productIds) {
        final productIndex = _products.indexWhere((p) => p['id'] == productId);
        
        if (productIndex == -1) {
          notFoundIds.add(productId);
          continue;
        }
        
        final product = _products[productIndex];
        
        // Verificar si se puede eliminar (ej: no tiene órdenes pendientes)
        if (product['has_pending_orders'] == true) {
          errors.add('Product ${product['name']} (${productId}) has pending orders');
          continue;
        }
        
        // Eliminar producto
        _products.removeAt(productIndex);
        deletedProducts.add({
          'id': product['id'],
          'name': product['name'],
          'category': product['category'],
        });
      }
      
      print('🗑️ Batch deletion completed:');
      print('   Deleted: ${deletedProducts.length} products');
      print('   Not found: ${notFoundIds.length} IDs');
      print('   Errors: ${errors.length} products');
      
      final response = ApiResponse.success({
        'deleted_products': deletedProducts,
        'deleted_count': deletedProducts.length,
        'not_found_ids': notFoundIds,
        'errors': errors,
        'total_requested': productIds.length,
        'deleted_at': DateTime.now().toIso8601String(),
      }, 'Batch deletion completed');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error in batch deletion: $e');
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  // DELETE /api/products/category/{category}
  @DELETE('/category/<category>')
  Future<Response> deleteProductsByCategory(Request request) async {
    final category = getRequiredParam(request, 'category');
    logRequest(request, 'Deleting all products in category: $category');
    
    try {
      // Verificar autorización de admin
      final authHeader = getOptionalHeader(request, 'Authorization');
      if (authHeader == null) {
        final response = ApiResponse.error('Authorization required');
        return jsonResponse(response.toJson(), statusCode: 401);
      }
      
      final currentUserRole = _extractUserRoleFromToken(authHeader);
      if (currentUserRole != 'admin') {
        final response = ApiResponse.error('Admin privileges required');
        return jsonResponse(response.toJson(), statusCode: 403);
      }
      
      // Verificar confirmación requerida
      final confirmHeader = getOptionalHeader(request, 'X-Confirm-Deletion');
      if (confirmHeader != 'yes') {
        final productsInCategory = _products.where((p) => p['category'] == category).length;
        
        final response = ApiResponse.error(
          'This will delete $productsInCategory products. '
          'Add header "X-Confirm-Deletion: yes" to confirm.'
        );
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Encontrar productos de la categoría
      final productsToDelete = _products.where((p) => p['category'] == category).toList();
      
      if (productsToDelete.isEmpty) {
        final response = ApiResponse.error('No products found in category: $category');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      // Eliminar productos
      _products.removeWhere((p) => p['category'] == category);
      
      print('🗑️ Category deletion completed: $category');
      print('   Deleted ${productsToDelete.length} products');
      
      final response = ApiResponse.success({
        'deleted_category': category,
        'deleted_products': productsToDelete.map((p) => {
          'id': p['id'],
          'name': p['name'],
        }).toList(),
        'deleted_count': productsToDelete.length,
        'deleted_at': DateTime.now().toIso8601String(),
      }, 'Category deleted successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error deleting category: $e');
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }
}
```

**Tests:**
```bash
# Eliminar productos en lote
curl -X DELETE http://localhost:8080/api/products/batch \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer admin-token" \
  -d '{
    "product_ids": ["1", "2", "3"],
    "confirm_deletion": true
  }'

# Eliminar por categoría
curl -X DELETE http://localhost:8080/api/products/category/electronics \
  -H "Authorization: Bearer admin-token" \
  -H "X-Confirm-Deletion: yes"
```

---

## 🔐 4. Eliminación con Validaciones Complejas

```dart
// DELETE /api/accounts/{id} - Eliminar cuenta con validaciones estrictas
@DELETE('/<id>')
Future<Response> deleteAccount(Request request) async {
  final accountId = getRequiredParam(request, 'id');
  logRequest(request, 'Attempting to delete account $accountId');
  
  try {
    final authHeader = getOptionalHeader(request, 'Authorization');
    if (authHeader == null) {
      final response = ApiResponse.error('Authorization required');
      return jsonResponse(response.toJson(), statusCode: 401);
    }
    
    final currentUserId = _extractUserIdFromToken(authHeader);
    final currentUserRole = _extractUserRoleFromToken(authHeader);
    
    // Solo el propietario o super admin puede eliminar cuenta
    if (accountId != currentUserId && currentUserRole != 'super_admin') {
      final response = ApiResponse.error('Insufficient permissions');
      return jsonResponse(response.toJson(), statusCode: 403);
    }
    
    // Leer validaciones del body
    final body = await request.readAsString();
    final data = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : {};
    
    // Verificar validaciones requeridas
    final validationResult = await _validateAccountDeletion(accountId, data);
    if (!validationResult['can_delete']) {
      final response = ApiResponse.error(validationResult['reason']);
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    // Ejecutar eliminación con pasos de limpieza
    final deletionResult = await _executeAccountDeletion(accountId, data);
    
    print('🗑️ Account deleted: $accountId');
    print('   Cleanup actions: ${deletionResult['cleanup_actions'].length}');
    
    final response = ApiResponse.success(deletionResult, 'Account deleted successfully');
    return jsonResponse(response.toJson());
    
  } catch (e) {
    print('❌ Error deleting account: $e');
    final response = ApiResponse.error('Internal server error');
    return jsonResponse(response.toJson(), statusCode: 500);
  }
}

// Validaciones complejas para eliminación de cuenta
Future<Map<String, dynamic>> _validateAccountDeletion(String accountId, Map<String, dynamic> data) async {
  final validations = <String>[];
  
  // 1. Verificar confirmación del usuario
  if (data['confirm_deletion'] != true) {
    return {
      'can_delete': false,
      'reason': 'Account deletion requires explicit confirmation'
    };
  }
  
  // 2. Verificar contraseña actual
  if (!data.containsKey('current_password')) {
    return {
      'can_delete': false,
      'reason': 'Current password is required for account deletion'
    };
  }
  
  // En producción verificarías la contraseña real
  // if (!await _verifyPassword(accountId, data['current_password'])) {
  //   return {'can_delete': false, 'reason': 'Invalid password'};
  // }
  
  // 3. Verificar que no hay transacciones pendientes
  final hasPendingTransactions = false; // Simular verificación
  if (hasPendingTransactions) {
    return {
      'can_delete': false,
      'reason': 'Account has pending transactions. Please complete or cancel them first.'
    };
  }
  
  // 4. Verificar período de enfriamiento
  final lastLoginStr = '2024-01-01T00:00:00Z'; // Simular último login
  final lastLogin = DateTime.parse(lastLoginStr);
  final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
  
  if (daysSinceLogin < 1) {
    return {
      'can_delete': false,
      'reason': 'Account must be inactive for at least 24 hours before deletion'
    };
  }
  
  // 5. Verificar datos de contacto para recuperación
  final hasValidEmail = true; // Simular verificación
  if (!hasValidEmail) {
    return {
      'can_delete': false,
      'reason': 'Valid email required for account deletion confirmation'
    };
  }
  
  return {
    'can_delete': true,
    'validations_passed': validations,
  };
}

// Ejecutar eliminación con limpieza
Future<Map<String, dynamic>> _executeAccountDeletion(String accountId, Map<String, dynamic> data) async {
  final cleanupActions = <String>[];
  
  // 1. Anonymizar datos personales (GDPR compliance)
  // await _anonymizePersonalData(accountId);
  cleanupActions.add('Personal data anonymized');
  
  // 2. Eliminar archivos del usuario
  // await _deleteUserFiles(accountId);
  cleanupActions.add('User files deleted');
  
  // 3. Cancelar suscripciones
  // await _cancelSubscriptions(accountId);
  cleanupActions.add('Subscriptions cancelled');
  
  // 4. Notificar servicios externos
  // await _notifyExternalServices(accountId);
  cleanupActions.add('External services notified');
  
  // 5. Crear registro de auditoría
  final auditRecord = {
    'action': 'account_deletion',
    'account_id': accountId,
    'deleted_at': DateTime.now().toIso8601String(),
    'deletion_reason': data['deletion_reason'] ?? 'User requested',
    'ip_address': '127.0.0.1', // En producción obtener IP real
  };
  cleanupActions.add('Audit record created');
  
  // 6. Eliminar cuenta (soft delete por regulaciones)
  // await _softDeleteAccount(accountId);
  cleanupActions.add('Account marked as deleted');
  
  return {
    'account_id': accountId,
    'deleted_at': DateTime.now().toIso8601String(),
    'cleanup_actions': cleanupActions,
    'audit_record_id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
    'recovery_period_days': 30,
  };
}
```

**Test:**
```bash
# Eliminar cuenta con todas las validaciones
curl -X DELETE http://localhost:8080/api/accounts/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer user-token" \
  -d '{
    "confirm_deletion": true,
    "current_password": "user_password",
    "deletion_reason": "No longer needed"
  }'
```

---

## 🏆 Mejores Prácticas para DELETE

### ✅ **DO's**
- ✅ Verificar permisos antes de eliminar
- ✅ Implementar soft delete para datos importantes
- ✅ Validar dependencias antes de eliminar
- ✅ Loggear todas las eliminaciones
- ✅ Proporcionar confirmación para lotes grandes
- ✅ Implementar períodos de recuperación

### ❌ **DON'Ts**
- ❌ Eliminar sin verificar permisos
- ❌ Hard delete de datos críticos sin respaldo
- ❌ Permitir eliminación en cascada sin control
- ❌ Ignorar dependencias y referencias
- ❌ Eliminar sin auditoría

### 📊 Status Codes para DELETE
- **200 OK** - Eliminación exitosa (con body)
- **204 No Content** - Eliminación exitosa (sin body)
- **401 Unauthorized** - Falta autenticación
- **403 Forbidden** - Sin permisos suficientes
- **404 Not Found** - Recurso no existe
- **400 Bad Request** - Validaciones fallaron
- **409 Conflict** - No se puede eliminar (dependencias)

### 🔄 Tipos de Eliminación
1. **Hard Delete** - Eliminación física permanente
2. **Soft Delete** - Marcado como eliminado (reversible)
3. **Archive** - Mover a almacenamiento de archivo
4. **Anonymize** - Eliminar datos personales pero mantener estadísticas

---

**👉 [Siguiente: Query Parameters Avanzados →](08-query-parameters.md)**