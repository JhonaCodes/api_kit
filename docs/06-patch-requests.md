# 📝 PATCH Requests

Los **PATCH requests** son para **actualizar parcialmente** recursos existentes. Solo modificas los campos que necesitas cambiar, dejando el resto intacto.

## 🎯 PATCH vs PUT

| Aspecto | PATCH | PUT |
|---------|-------|-----|
| **Tipo de actualización** | Parcial | Completa |
| **Campos requeridos** | Solo los que cambias | Todos los campos |
| **Idempotencia** | Depende de la implementación | Siempre idempotente |
| **Uso común** | Cambios pequeños | Reemplazo completo |

---

## 📝 1. Actualización Parcial Básica

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
      'bio': 'Software developer',
      'location': 'New York',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    }
  ];

  // PATCH /api/users/{id}
  @PATCH('/<id>')
  Future<Response> updateUserPartial(Request request) async {
    final userId = getRequiredParam(request, 'id');
    logRequest(request, 'Partially updating user $userId');
    
    try {
      // Leer body
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Verificar que hay al menos un campo para actualizar
      if (data.isEmpty) {
        final response = ApiResponse.error('At least one field is required for update');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Encontrar usuario
      final userIndex = _users.indexWhere((user) => user['id'] == userId);
      if (userIndex == -1) {
        final response = ApiResponse.error('User not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      final user = _users[userIndex];
      
      // Validar solo los campos proporcionados
      final validation = _validatePartialUserData(data, userId);
      if (!validation.isValid) {
        final response = ApiResponse.error(validation.errors.join(', '));
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Lista de campos modificados para logging
      final modifiedFields = <String>[];
      
      // Actualizar solo los campos proporcionados
      if (data.containsKey('name')) {
        user['name'] = data['name'].toString().trim();
        modifiedFields.add('name');
      }
      
      if (data.containsKey('email')) {
        user['email'] = data['email'].toString().trim().toLowerCase();
        modifiedFields.add('email');
      }
      
      if (data.containsKey('age')) {
        user['age'] = data['age'] as int;
        modifiedFields.add('age');
      }
      
      if (data.containsKey('role')) {
        user['role'] = data['role'];
        modifiedFields.add('role');
      }
      
      if (data.containsKey('active')) {
        user['active'] = data['active'] as bool;
        modifiedFields.add('active');
      }
      
      if (data.containsKey('bio')) {
        user['bio'] = data['bio']?.toString().trim() ?? '';
        modifiedFields.add('bio');
      }
      
      if (data.containsKey('location')) {
        user['location'] = data['location']?.toString().trim() ?? '';
        modifiedFields.add('location');
      }
      
      // Actualizar timestamp
      user['updated_at'] = DateTime.now().toIso8601String();
      
      print('✅ User partially updated: ${user['name']}');
      print('   Modified fields: ${modifiedFields.join(', ')}');
      
      final response = ApiResponse.success({
        ...user,
        'modified_fields': modifiedFields,
      }, 'User updated successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      return _handlePatchError(e);
    }
  }
  
  // Validación para campos parciales
  ValidationResult _validatePartialUserData(Map<String, dynamic> data, String userId) {
    final errors = <String>[];
    
    // Validar name si está presente
    if (data.containsKey('name')) {
      if (data['name'].toString().trim().isEmpty) {
        errors.add('Name cannot be empty');
      } else if (data['name'].toString().trim().length < 2) {
        errors.add('Name must be at least 2 characters');
      }
    }
    
    // Validar email si está presente
    if (data.containsKey('email')) {
      if (data['email'].toString().trim().isEmpty) {
        errors.add('Email cannot be empty');
      } else {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(data['email'])) {
          errors.add('Invalid email format');
        }
        
        // Verificar email único (excluyendo el usuario actual)
        if (_users.any((user) => 
            user['id'] != userId && user['email'] == data['email'])) {
          errors.add('Email already exists');
        }
      }
    }
    
    // Validar age si está presente
    if (data.containsKey('age')) {
      if (data['age'] is! int) {
        errors.add('Age must be an integer');
      } else if (data['age'] < 0 || data['age'] > 150) {
        errors.add('Age must be between 0 and 150');
      }
    }
    
    // Validar role si está presente
    if (data.containsKey('role')) {
      final validRoles = ['user', 'admin', 'moderator'];
      if (!validRoles.contains(data['role'])) {
        errors.add('Role must be one of: ${validRoles.join(', ')}');
      }
    }
    
    // Validar active si está presente
    if (data.containsKey('active') && data['active'] is! bool) {
      errors.add('Active must be a boolean');
    }
    
    // Validar bio si está presente
    if (data.containsKey('bio') && data['bio'] != null) {
      if (data['bio'].toString().length > 500) {
        errors.add('Bio must not exceed 500 characters');
      }
    }
    
    // Campos que no se pueden modificar
    final forbiddenFields = ['id', 'created_at', 'password_hash'];
    for (final field in forbiddenFields) {
      if (data.containsKey(field)) {
        errors.add('Field "$field" cannot be modified');
      }
    }
    
    return ValidationResult(errors.isEmpty, errors);
  }
  
  Response _handlePatchError(dynamic error) {
    if (error is FormatException) {
      final response = ApiResponse.error('Invalid JSON format');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    print('❌ Error in PATCH operation: $error');
    final response = ApiResponse.error('Internal server error');
    return jsonResponse(response.toJson(), statusCode: 500);
  }
}
```

**Tests:**
```bash
# Actualizar solo el nombre
curl -X PATCH http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith"
  }'

# Actualizar múltiples campos
curl -X PATCH http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "age": 31,
    "location": "San Francisco",
    "bio": "Senior Software Developer"
  }'

# Error - campo prohibido
curl -X PATCH http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "id": "2"
  }'
```

---

## 🔧 2. PATCH con Operaciones Atómicas

```dart
@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Gaming Laptop',
      'price': 1299.99,
      'stock': 10,
      'tags': ['gaming', 'laptop', 'electronics'],
      'metadata': {
        'warranty_months': 24,
        'brand': 'TechCorp',
        'model': 'GL-2024'
      },
      'updated_at': '2024-01-01T00:00:00Z',
    }
  ];

  // PATCH /api/products/{id}
  @PATCH('/<id>')
  Future<Response> updateProductPartial(Request request) async {
    final productId = getRequiredParam(request, 'id');
    logRequest(request, 'Partially updating product $productId');
    
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (data.isEmpty) {
        final response = ApiResponse.error('At least one field is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final productIndex = _products.indexWhere((p) => p['id'] == productId);
      if (productIndex == -1) {
        final response = ApiResponse.error('Product not found');
        return jsonResponse(response.toJson(), statusCode: 404);
      }
      
      final product = _products[productIndex];
      final modifiedFields = <String>[];
      
      // Validar y aplicar cambios
      final validation = _validatePartialProductData(data, productId);
      if (!validation.isValid) {
        final response = ApiResponse.error(validation.errors.join(', '));
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Actualizar campos básicos
      if (data.containsKey('name')) {
        product['name'] = data['name'].toString().trim();
        modifiedFields.add('name');
      }
      
      if (data.containsKey('price')) {
        product['price'] = (data['price'] as num).toDouble();
        modifiedFields.add('price');
      }
      
      // Operaciones especiales para stock
      if (data.containsKey('stock_operation')) {
        _handleStockOperation(product, data['stock_operation'], modifiedFields);
      } else if (data.containsKey('stock')) {
        product['stock'] = data['stock'] as int;
        modifiedFields.add('stock');
      }
      
      // Operaciones para tags (agregar/remover)
      if (data.containsKey('add_tags')) {
        _addTags(product, data['add_tags'], modifiedFields);
      }
      
      if (data.containsKey('remove_tags')) {
        _removeTags(product, data['remove_tags'], modifiedFields);
      }
      
      // Actualizar metadata parcialmente
      if (data.containsKey('metadata')) {
        _updateMetadata(product, data['metadata'], modifiedFields);
      }
      
      product['updated_at'] = DateTime.now().toIso8601String();
      
      print('✅ Product partially updated: ${product['name']}');
      print('   Modified: ${modifiedFields.join(', ')}');
      
      final response = ApiResponse.success({
        ...product,
        'modified_fields': modifiedFields,
      }, 'Product updated successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      return _handlePatchError(e);
    }
  }
  
  // Operaciones de stock atómicas
  void _handleStockOperation(Map<String, dynamic> product, Map<String, dynamic> operation, List<String> modifiedFields) {
    final type = operation['type'] as String;
    final amount = operation['amount'] as int;
    final currentStock = product['stock'] as int;
    
    switch (type) {
      case 'add':
        product['stock'] = currentStock + amount;
        modifiedFields.add('stock (added $amount)');
        break;
      case 'subtract':
        final newStock = currentStock - amount;
        if (newStock < 0) {
          throw ArgumentError('Stock cannot go below zero');
        }
        product['stock'] = newStock;
        modifiedFields.add('stock (subtracted $amount)');
        break;
      case 'set':
        product['stock'] = amount;
        modifiedFields.add('stock (set to $amount)');
        break;
      default:
        throw ArgumentError('Invalid stock operation type: $type');
    }
  }
  
  // Agregar tags sin duplicados
  void _addTags(Map<String, dynamic> product, List<dynamic> newTags, List<String> modifiedFields) {
    final currentTags = List<String>.from(product['tags']);
    final tagsToAdd = newTags.cast<String>();
    
    for (final tag in tagsToAdd) {
      if (!currentTags.contains(tag)) {
        currentTags.add(tag);
      }
    }
    
    product['tags'] = currentTags;
    modifiedFields.add('tags (added: ${tagsToAdd.join(', ')})');
  }
  
  // Remover tags
  void _removeTags(Map<String, dynamic> product, List<dynamic> tagsToRemove, List<String> modifiedFields) {
    final currentTags = List<String>.from(product['tags']);
    final removeList = tagsToRemove.cast<String>();
    
    currentTags.removeWhere((tag) => removeList.contains(tag));
    
    product['tags'] = currentTags;
    modifiedFields.add('tags (removed: ${removeList.join(', ')})');
  }
  
  // Actualizar metadata parcialmente
  void _updateMetadata(Map<String, dynamic> product, Map<String, dynamic> newMetadata, List<String> modifiedFields) {
    final currentMetadata = Map<String, dynamic>.from(product['metadata']);
    
    for (final entry in newMetadata.entries) {
      currentMetadata[entry.key] = entry.value;
      modifiedFields.add('metadata.${entry.key}');
    }
    
    product['metadata'] = currentMetadata;
  }
  
  ValidationResult _validatePartialProductData(Map<String, dynamic> data, String productId) {
    final errors = <String>[];
    
    // Validar name si está presente
    if (data.containsKey('name') && data['name'].toString().trim().isEmpty) {
      errors.add('Name cannot be empty');
    }
    
    // Validar price si está presente
    if (data.containsKey('price')) {
      if (data['price'] is! num) {
        errors.add('Price must be a number');
      } else if ((data['price'] as num) <= 0) {
        errors.add('Price must be greater than 0');
      }
    }
    
    // Validar stock si está presente
    if (data.containsKey('stock')) {
      if (data['stock'] is! int) {
        errors.add('Stock must be an integer');
      } else if ((data['stock'] as int) < 0) {
        errors.add('Stock cannot be negative');
      }
    }
    
    // Validar operaciones de stock
    if (data.containsKey('stock_operation')) {
      final operation = data['stock_operation'];
      if (operation is! Map<String, dynamic>) {
        errors.add('Stock operation must be an object');
      } else {
        if (!operation.containsKey('type') || !operation.containsKey('amount')) {
          errors.add('Stock operation must have type and amount');
        }
        
        final validTypes = ['add', 'subtract', 'set'];
        if (!validTypes.contains(operation['type'])) {
          errors.add('Stock operation type must be one of: ${validTypes.join(', ')}');
        }
        
        if (operation['amount'] is! int) {
          errors.add('Stock operation amount must be an integer');
        }
      }
    }
    
    // Campos prohibidos
    final forbiddenFields = ['id', 'created_at', 'sku'];
    for (final field in forbiddenFields) {
      if (data.containsKey(field)) {
        errors.add('Field "$field" cannot be modified');
      }
    }
    
    return ValidationResult(errors.isEmpty, errors);
  }
}
```

**Tests:**
```bash
# Actualizar precio y nombre
curl -X PATCH http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Gaming Laptop Pro",
    "price": 1399.99
  }'

# Operación de stock - agregar
curl -X PATCH http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "stock_operation": {
      "type": "add",
      "amount": 5
    }
  }'

# Operaciones con tags
curl -X PATCH http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "add_tags": ["new", "featured"],
    "remove_tags": ["laptop"]
  }'

# Actualizar metadata
curl -X PATCH http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "warranty_months": 36,
      "color": "black"
    }
  }'
```

---

## 🔐 3. PATCH con Control de Permisos

```dart
// PATCH /api/users/{id}/settings - Solo el usuario puede cambiar sus settings
@PATCH('/<id>/settings')
Future<Response> updateUserSettings(Request request) async {
  final userId = getRequiredParam(request, 'id');
  logRequest(request, 'Updating settings for user $userId');
  
  try {
    // Verificar autorización
    final authHeader = getOptionalHeader(request, 'Authorization');
    if (authHeader == null) {
      final response = ApiResponse.error('Authorization required');
      return jsonResponse(response.toJson(), statusCode: 401);
    }
    
    final currentUserId = _extractUserIdFromToken(authHeader);
    
    // Solo el mismo usuario puede cambiar sus settings
    if (currentUserId != userId) {
      final response = ApiResponse.error('You can only modify your own settings');
      return jsonResponse(response.toJson(), statusCode: 403);
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    if (data.isEmpty) {
      final response = ApiResponse.error('At least one setting is required');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    // Encontrar usuario
    final userIndex = _users.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      final response = ApiResponse.error('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    final user = _users[userIndex];
    
    // Inicializar settings si no existe
    if (!user.containsKey('settings')) {
      user['settings'] = <String, dynamic>{};
    }
    
    final settings = user['settings'] as Map<String, dynamic>;
    final modifiedSettings = <String>[];
    
    // Settings permitidos para usuarios
    final allowedSettings = {
      'theme': ['light', 'dark', 'auto'],
      'notifications': [true, false],
      'language': ['en', 'es', 'fr', 'de'],
      'timezone': null, // Cualquier string válido
      'email_updates': [true, false],
      'profile_visibility': ['public', 'private', 'friends'],
    };
    
    // Validar y actualizar settings
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (!allowedSettings.containsKey(key)) {
        final response = ApiResponse.error('Setting "$key" is not allowed');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Validar valores permitidos
      final allowedValues = allowedSettings[key];
      if (allowedValues != null && !allowedValues.contains(value)) {
        final response = ApiResponse.error(
          'Invalid value for "$key". Allowed: ${allowedValues.join(', ')}'
        );
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Validaciones especiales
      if (key == 'timezone' && value is String) {
        // Validación básica de timezone
        if (value.isEmpty || value.length > 50) {
          final response = ApiResponse.error('Invalid timezone format');
          return jsonResponse(response.toJson(), statusCode: 400);
        }
      }
      
      settings[key] = value;
      modifiedSettings.add(key);
    }
    
    user['updated_at'] = DateTime.now().toIso8601String();
    
    print('✅ Settings updated for user: ${user['name']}');
    print('   Modified settings: ${modifiedSettings.join(', ')}');
    
    final response = ApiResponse.success({
      'user_id': userId,
      'settings': settings,
      'modified_settings': modifiedSettings,
    }, 'Settings updated successfully');
    
    return jsonResponse(response.toJson());
    
  } catch (e) {
    return _handleSettingsUpdateError(e);
  }
}

Response _handleSettingsUpdateError(dynamic error) {
  if (error is FormatException) {
    final response = ApiResponse.error('Invalid JSON format');
    return jsonResponse(response.toJson(), statusCode: 400);
  }
  
  print('❌ Error updating settings: $error');
  final response = ApiResponse.error('Internal server error');
  return jsonResponse(response.toJson(), statusCode: 500);
}
```

**Test:**
```bash
# Actualizar configuraciones del usuario
curl -X PATCH http://localhost:8080/api/users/1/settings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer user-token" \
  -d '{
    "theme": "dark",
    "notifications": false,
    "language": "es",
    "profile_visibility": "private"
  }'
```

---

## 🏆 Mejores Prácticas para PATCH

### ✅ **DO's**
- ✅ Validar solo los campos proporcionados
- ✅ Permitir actualizaciones parciales
- ✅ Verificar permisos antes de actualizar
- ✅ Loggear qué campos se modificaron
- ✅ Mantener operaciones atómicas
- ✅ Rechazar campos prohibidos

### ❌ **DON'Ts**
- ❌ Requerir todos los campos (eso es PUT)
- ❌ Permitir modificar campos del sistema
- ❌ Hacer operaciones no-atómicas
- ❌ Ignorar validación de tipos
- ❌ Actualizar sin verificar permisos

### 📊 Casos de Uso Ideales para PATCH
- **👤 Perfiles de usuario** - Cambiar avatar, bio, etc.
- **⚙️ Configuraciones** - Theme, notificaciones, idioma
- **📊 Contadores** - Incrementar/decrementar stock, likes
- **🏷️ Tags y categorías** - Agregar/remover etiquetas
- **🔧 Metadata** - Actualizar propiedades específicas

### 🔄 Operaciones Atómicas Comunes
```json
{
  "stock_operation": {"type": "add", "amount": 5},
  "add_tags": ["new", "featured"],
  "remove_tags": ["old"],
  "increment_views": 1,
  "metadata": {"color": "red"}
}
```

---

**👉 [Siguiente: DELETE Requests →](07-delete-requests.md)**