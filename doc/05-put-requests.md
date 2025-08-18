# 🔄 PUT Requests

Los **PUT requests** son para **actualizar** recursos existentes de manera **completa**. Son idempotentes (ejecutar múltiples veces produce el mismo resultado).

## 🎯 Conceptos Clave de PUT

- **📝 Reemplazo completo** - PUT reemplaza todo el recurso
- **🔄 Idempotente** - Múltiples llamadas = mismo resultado
- **🎯 Requiere ID** - Siempre actualiza un recurso específico
- **✨ Upsert opcional** - Puede crear si no existe

---

## 📝 1. Actualización Completa de Recurso

```dart
@Controller('/api/users')
class UserController extends BaseController {
  
  static final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'age': 30,
      'role': 'user',
      'active': true,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    }
  ];

  // PUT /api/users/{id}
  @PUT('/<id>')
  Future<Response> updateUser(Request request) async {
    final userId = getRequiredParam(request, 'id');
    logRequest(request, 'Updating user $userId');
    
    try {
      // Leer y parsear body
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Encontrar usuario
      final userIndex = _users.indexWhere((user) => user['id'] == userId);
      if (userIndex == -1) {
        final response = ApiResponse.error('User not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      // Validar datos completos (PUT requiere todos los campos)
      final validation = _validateCompleteUserData(data, userId);
      if (!validation.isValid) {
        final response = ApiResponse.error(validation.errors.join(', '));
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Verificar email único (excluyendo el usuario actual)
      if (_users.any((user) => 
          user['id'] != userId && user['email'] == data['email'])) {
        final response = ApiResponse.error('Email already exists');
        return jsonResponse(response.toJson(), statusCode: 409);
      }
      
      // Preservar campos del sistema
      final originalUser = _users[userIndex];
      
      // Actualizar usuario completamente
      final updatedUser = {
        'id': userId,
        'name': data['name'].toString().trim(),
        'email': data['email'].toString().trim().toLowerCase(),
        'age': data['age'] as int,
        'role': data['role'] ?? 'user',
        'active': data['active'] ?? true,
        // Preservar timestamps del sistema
        'created_at': originalUser['created_at'],
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _users[userIndex] = updatedUser;
      
      print('✅ User updated: ${updatedUser['name']} (${updatedUser['email']})');
      
      final response = ApiResponse.success(updatedUser, 'User updated successfully');
      return jsonResponse(response.toJson());
      
    } catch (e) {
      return _handleUpdateError(e);
    }
  }
  
  // Validación completa para PUT
  ValidationResult _validateCompleteUserData(Map<String, dynamic> data, String userId) {
    final errors = <String>[];
    
    // Todos los campos son requeridos en PUT
    if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
      errors.add('Name is required');
    } else if (data['name'].toString().trim().length < 2) {
      errors.add('Name must be at least 2 characters');
    }
    
    if (!data.containsKey('email') || data['email'].toString().trim().isEmpty) {
      errors.add('Email is required');
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(data['email'])) {
        errors.add('Invalid email format');
      }
    }
    
    if (!data.containsKey('age') || data['age'] is! int) {
      errors.add('Age is required and must be an integer');
    } else if (data['age'] < 0 || data['age'] > 150) {
      errors.add('Age must be between 0 and 150');
    }
    
    // Validar role si se proporciona
    if (data.containsKey('role')) {
      final validRoles = ['user', 'admin', 'moderator'];
      if (!validRoles.contains(data['role'])) {
        errors.add('Role must be one of: ${validRoles.join(', ')}');
      }
    }
    
    // Validar active si se proporciona
    if (data.containsKey('active') && data['active'] is! bool) {
      errors.add('Active must be a boolean');
    }
    
    return ValidationResult(errors.isEmpty, errors);
  }
  
  Response _handleUpdateError(dynamic error) {
    if (error is FormatException) {
      final response = ApiResponse.error('Invalid JSON format');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    print('❌ Error updating user: $error');
    final response = ApiResponse.error('Internal server error');
    return jsonResponse(response.toJson(), statusCode: 500);
  }
}
```

**Test:**
```bash
# Actualización completa exitosa
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "email": "johnsmith@example.com",
    "age": 31,
    "role": "admin",
    "active": true
  }'

# Error - datos incompletos
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith"
  }'
```

---

## 🆕 2. PUT con Upsert (Crear si no existe)

```dart
@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [];

  // PUT /api/products/{id} - Con capacidad de crear
  @PUT('/<id>')
  Future<Response> upsertProduct(Request request) async {
    final productId = getRequiredParam(request, 'id');
    logRequest(request, 'Upserting product $productId');
    
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Validar datos completos
      final validation = _validateCompleteProductData(data);
      if (!validation.isValid) {
        final response = ApiResponse.error(validation.errors.join(', '));
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Buscar producto existente
      final productIndex = _products.indexWhere((p) => p['id'] == productId);
      final isUpdate = productIndex != -1;
      
      // Verificar SKU único (excluyendo el producto actual si es update)
      if (_products.any((p) => 
          (!isUpdate || p['id'] != productId) && p['sku'] == data['sku'])) {
        final response = ApiResponse.error('SKU already exists');
        return jsonResponse(response.toJson(), statusCode: 409);
      }
      
      Map<String, dynamic> product;
      
      if (isUpdate) {
        // Actualizar producto existente
        final originalProduct = _products[productIndex];
        
        product = {
          'id': productId,
          'name': data['name'].toString().trim(),
          'description': data['description']?.toString().trim() ?? '',
          'price': (data['price'] as num).toDouble(),
          'category': data['category'],
          'sku': data['sku'].toString().toUpperCase(),
          'stock': data['stock'] ?? 0,
          'active': data['active'] ?? true,
          'tags': data['tags'] ?? [],
          'created_at': originalProduct['created_at'], // Preservar
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        _products[productIndex] = product;
        
        print('✅ Product updated: ${product['name']} (SKU: ${product['sku']})');
        
      } else {
        // Crear nuevo producto
        product = {
          'id': productId,
          'name': data['name'].toString().trim(),
          'description': data['description']?.toString().trim() ?? '',
          'price': (data['price'] as num).toDouble(),
          'category': data['category'],
          'sku': data['sku'].toString().toUpperCase(),
          'stock': data['stock'] ?? 0,
          'active': data['active'] ?? true,
          'tags': data['tags'] ?? [],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        _products.add(product);
        
        print('✅ Product created: ${product['name']} (SKU: ${product['sku']})');
      }
      
      final statusCode = isUpdate ? 200 : 201;
      final message = isUpdate ? 'Product updated successfully' : 'Product created successfully';
      
      final response = ApiResponse.success(product, message);
      return jsonResponse(response.toJson(), statusCode: statusCode);
      
    } catch (e) {
      return _handleUpsertError(e);
    }
  }
  
  ValidationResult _validateCompleteProductData(Map<String, dynamic> data) {
    final errors = <String>[];
    final validCategories = ['electronics', 'clothing', 'books', 'home', 'sports'];
    
    // Campos requeridos
    if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
      errors.add('Name is required');
    } else if (data['name'].toString().length < 3) {
      errors.add('Name must be at least 3 characters');
    }
    
    if (!data.containsKey('price') || data['price'] is! num) {
      errors.add('Price is required and must be a number');
    } else if ((data['price'] as num) <= 0) {
      errors.add('Price must be greater than 0');
    }
    
    if (!data.containsKey('category')) {
      errors.add('Category is required');
    } else if (!validCategories.contains(data['category'])) {
      errors.add('Category must be one of: ${validCategories.join(', ')}');
    }
    
    if (!data.containsKey('sku') || data['sku'].toString().trim().isEmpty) {
      errors.add('SKU is required');
    } else {
      final sku = data['sku'].toString();
      if (sku.length < 3 || sku.length > 20) {
        errors.add('SKU must be between 3 and 20 characters');
      }
    }
    
    // Campos opcionales con validación
    if (data.containsKey('stock') && data['stock'] is! int) {
      errors.add('Stock must be an integer');
    }
    
    if (data.containsKey('active') && data['active'] is! bool) {
      errors.add('Active must be a boolean');
    }
    
    if (data.containsKey('tags') && data['tags'] is! List) {
      errors.add('Tags must be an array');
    }
    
    return ValidationResult(errors.isEmpty, errors);
  }
  
  Response _handleUpsertError(dynamic error) {
    if (error is FormatException) {
      final response = ApiResponse.error('Invalid JSON format');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    print('❌ Error in upsert operation: $error');
    final response = ApiResponse.error('Internal server error');
    return jsonResponse(response.toJson(), statusCode: 500);
  }
}
```

**Test:**
```bash
# Crear producto nuevo (ID no existe)
curl -X PUT http://localhost:8080/api/products/new-123 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Gaming Mouse",
    "description": "High precision gaming mouse",
    "price": 79.99,
    "category": "electronics",
    "sku": "MOUSE-001",
    "stock": 25,
    "tags": ["gaming", "mouse", "electronics"]
  }'

# Actualizar producto existente
curl -X PUT http://localhost:8080/api/products/new-123 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Gaming Mouse",
    "description": "Updated high precision gaming mouse",
    "price": 89.99,
    "category": "electronics",
    "sku": "MOUSE-001",
    "stock": 30,
    "tags": ["gaming", "mouse", "electronics", "updated"]
  }'
```

---

## 🔐 3. PUT con Validación de Permisos

```dart
// PUT /api/users/{id}/profile - Solo el usuario o admin puede actualizar
@PUT('/<id>/profile')
Future<Response> updateUserProfile(Request request) async {
  final userId = getRequiredParam(request, 'id');
  logRequest(request, 'Updating profile for user $userId');
  
  try {
    // Verificar autorización (en producción extraerías del JWT)
    final authHeader = getOptionalHeader(request, 'Authorization');
    if (authHeader == null) {
      final response = ApiResponse.error('Authorization required');
      return jsonResponse(response.toJson(), statusCode: 401);
    }
    
    // Simular extracción de usuario del token
    final currentUserId = _extractUserIdFromToken(authHeader);
    final currentUserRole = _extractUserRoleFromToken(authHeader);
    
    // Verificar permisos: solo el mismo usuario o un admin
    if (currentUserId != userId && currentUserRole != 'admin') {
      final response = ApiResponse.error('Insufficient permissions');
      return jsonResponse(response.toJson(), statusCode: 403);
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    // Encontrar usuario
    final userIndex = _users.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      final response = ApiResponse.error('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    // Validar campos de perfil
    final validation = _validateProfileData(data);
    if (!validation.isValid) {
      final response = ApiResponse.error(validation.errors.join(', '));
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    // Actualizar solo campos de perfil (no datos sensibles)
    final user = _users[userIndex];
    user['name'] = data['name'].toString().trim();
    user['bio'] = data['bio']?.toString().trim() ?? '';
    user['avatar_url'] = data['avatar_url']?.toString().trim() ?? '';
    user['location'] = data['location']?.toString().trim() ?? '';
    user['website'] = data['website']?.toString().trim() ?? '';
    user['updated_at'] = DateTime.now().toIso8601String();
    
    // No incluir datos sensibles en la response
    final safeUser = Map<String, dynamic>.from(user);
    safeUser.remove('password_hash');
    
    print('✅ Profile updated for user: ${user['name']}');
    
    final response = ApiResponse.success(safeUser, 'Profile updated successfully');
    return jsonResponse(response.toJson());
    
  } catch (e) {
    return _handleProfileUpdateError(e);
  }
}

// Simulación de extracción de JWT (en producción usarías una librería real)
String _extractUserIdFromToken(String authHeader) {
  // En producción: jwt.verify(token)
  return '1'; // Usuario simulado
}

String _extractUserRoleFromToken(String authHeader) {
  // En producción: extraer del payload del JWT
  return 'user'; // Rol simulado
}

ValidationResult _validateProfileData(Map<String, dynamic> data) {
  final errors = <String>[];
  
  // Validar nombre
  if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
    errors.add('Name is required');
  } else if (data['name'].toString().length > 100) {
    errors.add('Name must not exceed 100 characters');
  }
  
  // Validar bio (opcional)
  if (data.containsKey('bio') && data['bio'].toString().length > 500) {
    errors.add('Bio must not exceed 500 characters');
  }
  
  // Validar URL del avatar (opcional)
  if (data.containsKey('avatar_url') && data['avatar_url'].toString().isNotEmpty) {
    final urlRegex = RegExp(r'^https?://');
    if (!urlRegex.hasMatch(data['avatar_url'])) {
      errors.add('Avatar URL must be a valid HTTP/HTTPS URL');
    }
  }
  
  // Validar website (opcional)
  if (data.containsKey('website') && data['website'].toString().isNotEmpty) {
    final urlRegex = RegExp(r'^https?://');
    if (!urlRegex.hasMatch(data['website'])) {
      errors.add('Website must be a valid HTTP/HTTPS URL');
    }
  }
  
  return ValidationResult(errors.isEmpty, errors);
}
```

**Test:**
```bash
# Actualizar perfil con autorización
curl -X PUT http://localhost:8080/api/users/1/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer fake-jwt-token" \
  -d '{
    "name": "John Updated",
    "bio": "Software developer and tech enthusiast",
    "avatar_url": "https://example.com/avatar.jpg",
    "location": "San Francisco, CA",
    "website": "https://johndoe.dev"
  }'

# Error - sin autorización
curl -X PUT http://localhost:8080/api/users/1/profile \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated"
  }'
```

---

## 🏆 Mejores Prácticas para PUT

### ✅ **DO's**
- ✅ Requerir **todos** los campos en PUT
- ✅ Validar permisos antes de actualizar
- ✅ Preservar timestamps del sistema
- ✅ Verificar que el recurso existe
- ✅ Implementar idempotencia
- ✅ Usar 200 para updates, 201 para creaciones

### ❌ **DON'Ts**
- ❌ Permitir actualizaciones parciales (usar PATCH)
- ❌ Cambiar campos del sistema (id, created_at)
- ❌ Actualizar sin validación de permisos
- ❌ Permitir modificar datos de otros usuarios
- ❌ Retornar datos sensibles

### 📊 Status Codes para PUT
- **200 OK** - Recurso actualizado exitosamente
- **201 Created** - Recurso creado (upsert)
- **400 Bad Request** - Datos inválidos o incompletos
- **401 Unauthorized** - Falta autenticación
- **403 Forbidden** - Sin permisos suficientes
- **404 Not Found** - Recurso no existe
- **409 Conflict** - Conflicto de datos (ej: email duplicado)

---

**👉 [Siguiente: PATCH Requests →](06-patch-requests.md)**