# @Put - Annotation for PUT Endpoints

## 📋 Description

The `@Put` annotation is used to mark methods as endpoints that respond to HTTP PUT requests. It is the standard annotation for full update operations of existing resources.

## 🎯 Purpose

- **Full update**: Completely replace an existing resource
- **Idempotent operations**: The same operation produces the same result
- **Modification with ID**: Update resources identified by a specific ID
- **Configuration APIs**: Update configurations or preferences

## 📝 Syntax

```dart
@Put({
  required String path,           // Endpoint path (REQUIRED)
  String? description,           // Endpoint description
  int statusCode = 200,          // Default response code (OK)
  bool requiresAuth = true,      // Requires authentication by default
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Yes | - | Relative path of the endpoint (e.g., `/users/{id}`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Readable description of the endpoint's purpose |
| `statusCode` | `int` | ❌ No | `200` | HTTP status code for a successful response |
| `requiresAuth` | `bool` | ❌ No | `true` | Indicates if the endpoint requires authentication |

> **Note**: PUT requires authentication by default (`requiresAuth = true`) as it generally modifies protected resources.

## 🚀 Usage Examples

### Basic Example

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
    
    // Simulate update
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

### Example with Typed RequestBody

#### Traditional Approach - Manual JWT Extraction
```dart
@Put(
  path: '/products/{productId}',
  description: 'Completely updates an existing product'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProduct(
  Request request,
  @PathParam('productId', description: 'Unique product ID') String productId,
  @RequestBody(required: true, description: 'Complete product data') 
  Map<String, dynamic> productData,
) async {
  
  // Mandatory validations for PUT (must include all fields)
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
  
  // Validate data types
  if (productData['price'] is! num || productData['price'] <= 0) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Price must be a positive number',
      'received': productData['price']
    }));
  }
  
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Simulate full update
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
  description: 'Completely updates an existing product'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProductEnhanced(
  @PathParam('productId', description: 'Unique product ID') String productId,
  @RequestBody(required: true, description: 'Complete product data') 
  Map<String, dynamic> productData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
  @RequestHost() String host,
) async {
  
  // Mandatory validations for PUT (must include all fields)
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
  
  // Validate data types
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

### Example with Headers and Query Parameters
```dart
@Put(
  path: '/stores/{storeId}/products/{productId}',
  description: 'Updates a product with advanced options'
)
Future<Response> updateStoreProduct(
  Request request,
  // Path Parameters
  @PathParam('storeId', description: 'Store ID') String storeId,
  @PathParam('productId', description: 'Product ID') String productId,
  
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
  
  // Validate that the store ID from the path matches the header
  if (storeId != storeIdHeader) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Store ID mismatch',
      'path_store_id': storeId,
      'header_store_id': storeIdHeader,
    }));
  }
  
  // Validate content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Content-Type must be application/json',
      'received': contentType
    }));
  }
  
  // Validate authorization
  if (!authHeader.startsWith('Bearer ')) {
    return Response.unauthorized(jsonEncode({
      'error': 'Invalid authorization format',
      'expected': 'Bearer <token>'
    }));
  }
  
  // Simulate backup if enabled
  final actions = <String>[];
  if (createBackup) actions.add('backup_created');
  
  // Product update
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
  
  // Additional actions
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

### User Configuration Example
```dart
@Put(
  path: '/users/{userId}/settings',
  description: 'Completely updates the user\'s configuration'
)
@JWTEndpoint([MyUserValidator()]) // Only the user themselves can update
Future<Response> updateUserSettings(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(required: true, description: 'Complete user configuration') 
  Map<String, dynamic> settings,
) async {
  
  // Validate that the JWT corresponds to the user
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only update your own settings',
      'token_user_id': tokenUserId,
      'requested_user_id': userId
    }));
  }
  
  // Required settings for a full PUT
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
  
  // Validate notification structure
  final notifications = settings['notifications'] as Map<String, dynamic>?;
  if (notifications == null || 
      !notifications.containsKey('email') || 
      !notifications.containsKey('push')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Notifications must include email and push settings',
      'received': notifications
    }));
  }
  
  // Update settings
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

## 🔗 Combination with Other Annotations

### With Multiple Validators
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
  // Only users with financial clearance level 3, during business hours,
  // and from the finance or admin department can update accounts
  return jsonResponse(jsonEncode({
    'message': 'Financial account updated successfully'
  }));
}
```

## 💡 Best Practices

### ✅ Do
- **Require all fields**: PUT should update the entire resource
- **Validate IDs in the path**: Verify that the resource exists
- **Use idempotency**: The same request produces the same result
- **Include timestamps**: `updated_at` and `updated_by` fields
- **Respond with the updated resource**: Return the final state
- **Prefer Enhanced Parameters**: For full access without the Request parameter
- **Combine approaches**: Traditional for validation, Enhanced for context

### ❌ Don\'t
- **Partial updates**: Use PATCH for that
- **Create resources**: Use POST for creation
- **Ignore validations**: Always validate complete data
- **Not checking permissions**: Ensure the user can modify the resource
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Enhanced Recommendations by Scenario

#### For PUT with Strict Validation
```dart
// ✅ Traditional - Automatic type validation
@Put(path: '/products/{id}')
Future<Response> updateProduct(
  @PathParam('id') String id,
  @RequestBody(required: true) Map<String, dynamic> data,
) async {
  // Automatic type validation and required field checking
}
```

#### For PUT with Full Context
```dart
// ✅ Enhanced - Full access without Request parameter
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

#### For PUT with Dynamic Options
```dart
// ✅ Enhanced - Flexible update options
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

#### For PUT with Multiple Validators
```dart
// ✅ Hybrid - Robust validation + enhanced context
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

## 🔍 Differences with PATCH

| Aspect | PUT | PATCH |
|---------|-----|--------|--------|
| **Purpose** | Full update | Partial update |
| **Required fields** | All fields | Only fields to modify |
| **Idempotency** | Yes | May vary |
| **Missing fields** | Are set to null/default | Are kept unchanged |
| **Typical use** | Replace resource | Modify some fields |

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Successful update | `200` | OK - Resource updated |
| Resource not found | `404` | Not Found - ID does not exist |
| Incomplete data | `400` | Bad Request - Missing required fields |
| Invalid data | `400` | Bad Request - Incorrect types or values |
| Unauthorized | `401` | Unauthorized - Invalid JWT token |
| Forbidden | `403` | Forbidden - No modification permissions |
| Conflict | `409` | Conflict - Version conflict |
| Server error | `500` | Internal Server Error |

## 🌐 Resulting URLs

If your controller has `basePath: '/api/v1'` and you use `@Put(path: '/users/{id}')`, the final URL will be:
```
PUT http://localhost:8080/api/v1/users/{id}
```

## 📋 Request/Response Example

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

**Next**: [Documentation for @Patch](patch-annotation.md) | **Previous**: [Documentation for @Post](post-annotation.md)
