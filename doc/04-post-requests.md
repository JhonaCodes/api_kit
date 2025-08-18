# 📤 POST Requests

Los **POST requests** son para **crear** nuevos recursos. No son idempotentes (ejecutar múltiples veces puede crear múltiples recursos).

## 🎯 Tipos de POST Endpoints

### 1. **Crear Recurso** - `POST /api/resources/`
### 2. **Acciones Específicas** - `POST /api/resources/action`
### 3. **Subir Archivos** - `POST /api/resources/upload`
### 4. **Procesamiento de Datos** - `POST /api/resources/process`

---

## ➕ 1. Crear Nuevos Recursos

```dart
@Controller('/api/users')
class UserController extends BaseController {
  
  static final List<Map<String, dynamic>> _users = [];

  // POST /api/users/
  @POST('/')
  Future<Response> createUser(Request request) async {
    logRequest(request, 'Creating new user');
    
    try {
      // Leer el body del request
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Parsear JSON
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Validar campos requeridos
      final validationResult = _validateUserData(data);
      if (validationResult != null) {
        final response = ApiResponse.error(validationResult);
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // Verificar que el email no existe
      if (_users.any((user) => user['email'] == data['email'])) {
        final response = ApiResponse.error('Email already exists');
        return jsonResponse(response.toJson(), statusCode: 409); // Conflict
      }
      
      // Crear usuario
      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': data['name'],
        'email': data['email'],
        'age': data['age'],
        'role': data['role'] ?? 'user',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'active': true,
      };
      
      _users.add(newUser);
      
      print('✅ User created: ${newUser['name']} (${newUser['email']})');
      
      final response = ApiResponse.success(newUser, 'User created successfully');
      return jsonResponse(response.toJson(), statusCode: 201); // Created
      
    } catch (e) {
      if (e is FormatException) {
        final response = ApiResponse.error('Invalid JSON format');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      final response = ApiResponse.error('Internal server error');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }
  
  // Método helper para validación
  String? _validateUserData(Map<String, dynamic> data) {
    if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
      return 'Name is required';
    }
    
    if (!data.containsKey('email') || data['email'].toString().trim().isEmpty) {
      return 'Email is required';
    }
    
    // Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(data['email'])) {
      return 'Invalid email format';
    }
    
    if (!data.containsKey('age') || data['age'] is! int) {
      return 'Age is required and must be a number';
    }
    
    if (data['age'] < 0 || data['age'] > 150) {
      return 'Age must be between 0 and 150';
    }
    
    return null; // Validación exitosa
  }
}
```

**Test:**
```bash
# Crear usuario válido
curl -X POST http://localhost:8080/api/users/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30,
    "role": "admin"
  }'

# Error - datos faltantes
curl -X POST http://localhost:8080/api/users/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane"
  }'
```

---

## 📝 2. Crear con Validación Avanzada

```dart
@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [];
  static final List<String> _validCategories = [
    'electronics', 'clothing', 'books', 'home', 'sports'
  ];

  // POST /api/products/
  @POST('/')
  Future<Response> createProduct(Request request) async {
    logRequest(request, 'Creating new product');
    
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return _errorResponse('Request body is required', 400);
      }
      
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Validación completa
      final validation = _validateProductData(data);
      if (!validation.isValid) {
        return _errorResponse(validation.errors.join(', '), 400);
      }
      
      // Verificar SKU único
      if (_products.any((p) => p['sku'] == data['sku'])) {
        return _errorResponse('SKU already exists', 409);
      }
      
      // Crear producto
      final newProduct = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
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
      
      _products.add(newProduct);
      
      print('✅ Product created: ${newProduct['name']} (SKU: ${newProduct['sku']})');
      
      final response = ApiResponse.success(newProduct, 'Product created successfully');
      return jsonResponse(response.toJson(), statusCode: 201);
      
    } catch (e) {
      return _handleCreateError(e);
    }
  }
  
  // Validación estructurada
  ValidationResult _validateProductData(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Nombre
    if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
      errors.add('Name is required');
    } else if (data['name'].toString().length < 3) {
      errors.add('Name must be at least 3 characters');
    }
    
    // Precio
    if (!data.containsKey('price')) {
      errors.add('Price is required');
    } else if (data['price'] is! num) {
      errors.add('Price must be a number');
    } else if ((data['price'] as num) <= 0) {
      errors.add('Price must be greater than 0');
    }
    
    // Categoría
    if (!data.containsKey('category')) {
      errors.add('Category is required');
    } else if (!_validCategories.contains(data['category'])) {
      errors.add('Category must be one of: ${_validCategories.join(', ')}');
    }
    
    // SKU
    if (!data.containsKey('sku') || data['sku'].toString().trim().isEmpty) {
      errors.add('SKU is required');
    } else {
      final sku = data['sku'].toString();
      if (sku.length < 3 || sku.length > 20) {
        errors.add('SKU must be between 3 and 20 characters');
      }
      if (!RegExp(r'^[A-Z0-9-_]+$').hasMatch(sku.toUpperCase())) {
        errors.add('SKU can only contain letters, numbers, hyphens, and underscores');
      }
    }
    
    // Stock (opcional)
    if (data.containsKey('stock') && data['stock'] is! int) {
      errors.add('Stock must be an integer');
    }
    
    // Tags (opcional)
    if (data.containsKey('tags') && data['tags'] is! List) {
      errors.add('Tags must be an array');
    }
    
    return ValidationResult(errors.isEmpty, errors);
  }
  
  Response _errorResponse(String message, int statusCode) {
    final response = ApiResponse.error(message);
    return jsonResponse(response.toJson(), statusCode: statusCode);
  }
  
  Response _handleCreateError(dynamic error) {
    if (error is FormatException) {
      return _errorResponse('Invalid JSON format', 400);
    }
    
    print('❌ Error creating product: $error');
    return _errorResponse('Internal server error', 500);
  }
}

// Clase helper para validación
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult(this.isValid, this.errors);
}
```

**Test:**
```bash
# Producto válido
curl -X POST http://localhost:8080/api/products/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Gaming Laptop",
    "description": "High-performance laptop for gaming",
    "price": 1299.99,
    "category": "electronics",
    "sku": "LAPTOP-001",
    "stock": 10,
    "tags": ["gaming", "laptop", "electronics"]
  }'

# Error - categoría inválida
curl -X POST http://localhost:8080/api/products/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "category": "invalid-category",
    "sku": "TEST-001"
  }'
```

---

## 🎬 3. Acciones Específicas (Non-CRUD)

```dart
// POST /api/users/{id}/activate
@POST('/<id>/activate')
Future<Response> activateUser(Request request) async {
  final userId = getRequiredParam(request, 'id');
  logRequest(request, 'Activating user $userId');
  
  final userIndex = _users.indexWhere((user) => user['id'] == userId);
  if (userIndex == -1) {
    final response = ApiResponse.error('User not found');
    return jsonResponse(response.toJson(), statusCode: 404);
  }
  
  if (_users[userIndex]['active'] == true) {
    final response = ApiResponse.error('User is already active');
    return jsonResponse(response.toJson(), statusCode: 400);
  }
  
  _users[userIndex]['active'] = true;
  _users[userIndex]['activated_at'] = DateTime.now().toIso8601String();
  _users[userIndex]['updated_at'] = DateTime.now().toIso8601String();
  
  print('✅ User activated: ${_users[userIndex]['name']}');
  
  final response = ApiResponse.success(
    _users[userIndex], 
    'User activated successfully'
  );
  return jsonResponse(response.toJson());
}

// POST /api/users/{id}/change-password
@POST('/<id>/change-password')
Future<Response> changePassword(Request request) async {
  final userId = getRequiredParam(request, 'id');
  logRequest(request, 'Changing password for user $userId');
  
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    // Validar campos requeridos
    if (!data.containsKey('current_password') || !data.containsKey('new_password')) {
      final response = ApiResponse.error('Current password and new password are required');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    // Validar fortaleza de contraseña
    final newPassword = data['new_password'].toString();
    if (newPassword.length < 8) {
      final response = ApiResponse.error('New password must be at least 8 characters long');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    final userIndex = _users.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      final response = ApiResponse.error('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    // En producción aquí verificarías la contraseña actual
    // if (!verifyPassword(data['current_password'], _users[userIndex]['password_hash'])) {
    //   return _errorResponse('Current password is incorrect', 401);
    // }
    
    // Actualizar contraseña (en producción usarías hash)
    _users[userIndex]['password_hash'] = 'hashed_${newPassword}';
    _users[userIndex]['password_changed_at'] = DateTime.now().toIso8601String();
    _users[userIndex]['updated_at'] = DateTime.now().toIso8601String();
    
    print('✅ Password changed for user: ${_users[userIndex]['name']}');
    
    final response = ApiResponse.success(
      {'message': 'Password changed successfully'}, 
      'Password updated successfully'
    );
    return jsonResponse(response.toJson());
    
  } catch (e) {
    final response = ApiResponse.error('Invalid request format');
    return jsonResponse(response.toJson(), statusCode: 400);
  }
}
```

**Test:**
```bash
# Activar usuario
curl -X POST http://localhost:8080/api/users/1/activate

# Cambiar contraseña
curl -X POST http://localhost:8080/api/users/1/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "old_password",
    "new_password": "new_secure_password_123"
  }'
```

---

## 📊 4. Procesamiento de Datos

```dart
// POST /api/analytics/process
@POST('/process')
Future<Response> processAnalytics(Request request) async {
  logRequest(request, 'Processing analytics data');
  
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    if (!data.containsKey('events') || data['events'] is! List) {
      final response = ApiResponse.error('Events array is required');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    final events = data['events'] as List;
    
    // Procesar eventos
    final processedEvents = <Map<String, dynamic>>[];
    final errors = <String>[];
    
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      if (event is! Map<String, dynamic>) {
        errors.add('Event at index $i is not a valid object');
        continue;
      }
      
      if (!event.containsKey('type') || !event.containsKey('timestamp')) {
        errors.add('Event at index $i is missing required fields (type, timestamp)');
        continue;
      }
      
      // Procesar evento
      final processedEvent = {
        'id': 'evt_${DateTime.now().millisecondsSinceEpoch}_$i',
        'type': event['type'],
        'timestamp': event['timestamp'],
        'data': event['data'] ?? {},
        'processed_at': DateTime.now().toIso8601String(),
        'user_agent': getOptionalHeader(request, 'User-Agent', 'unknown'),
      };
      
      processedEvents.add(processedEvent);
    }
    
    print('📊 Processed ${processedEvents.length} events, ${errors.length} errors');
    
    final response = ApiResponse.success({
      'processed_events': processedEvents.length,
      'total_events': events.length,
      'errors': errors,
      'processing_time_ms': DateTime.now().millisecondsSinceEpoch,
    }, 'Analytics data processed successfully');
    
    return jsonResponse(response.toJson(), statusCode: 201);
    
  } catch (e) {
    final response = ApiResponse.error('Error processing analytics data');
    return jsonResponse(response.toJson(), statusCode: 500);
  }
}
```

**Test:**
```bash
curl -X POST http://localhost:8080/api/analytics/process \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {
        "type": "page_view",
        "timestamp": "2024-01-01T12:00:00Z",
        "data": {"page": "/home", "user_id": "123"}
      },
      {
        "type": "button_click",
        "timestamp": "2024-01-01T12:01:00Z",
        "data": {"button": "signup", "user_id": "123"}
      }
    ]
  }'
```

---

## 🏆 Mejores Prácticas para POST

### ✅ **DO's**
- ✅ Validar todo el input cuidadosamente
- ✅ Retornar 201 Created para recursos nuevos
- ✅ Incluir el recurso creado en la response
- ✅ Verificar duplicados antes de crear
- ✅ Usar transacciones para operaciones complejas
- ✅ Loggear creaciones importantes

### ❌ **DON'Ts**
- ❌ Crear recursos sin validación
- ❌ Retornar 200 OK para creaciones (usar 201)
- ❌ Ignorar validación de tipos de datos
- ❌ Permitir datos duplicados sin control
- ❌ Exponer errores internos en responses

### 📊 Status Codes Comunes
- **201 Created** - Recurso creado exitosamente
- **400 Bad Request** - Datos inválidos o faltantes
- **409 Conflict** - Recurso ya existe (ej: email duplicado)
- **422 Unprocessable Entity** - Datos bien formados pero inválidos
- **500 Internal Server Error** - Error del servidor

---

**👉 [Siguiente: PUT Requests →](05-put-requests.md)**