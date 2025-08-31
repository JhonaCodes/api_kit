# @Post - Annotation for POST Endpoints

## 📋 Description

The `@Post` annotation is used to mark methods as endpoints that respond to HTTP POST requests. It is the standard annotation for resource creation and data submission operations to the server.

## 🎯 Purpose

- **Create resources**: Insert new records or entities
- **Form submission**: Process data from web forms
- **Write operations**: Any action that modifies the server's state
- **Authentication APIs**: Login, registration, token renewal

## 📝 Syntax

```dart
@Post({
  required String path,           // Endpoint path (REQUIRED)
  String? description,           // Endpoint description
  int statusCode = 201,          // Default response code (Created)
  bool requiresAuth = false,     // If it requires authentication
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Yes | - | Relative path of the endpoint (e.g., `/users`, `/products`) |
| `description` | `String?` | ❌ No | `null` | Readable description of the endpoint's purpose |
| `statusCode` | `int` | ❌ No | `201` | HTTP status code for a successful response (Created) |
| `requiresAuth` | `bool` | ❌ No | `false` | Indicates if the endpoint requires authentication |

## 🚀 Usage Examples

### Basic Example

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

### Example with Typed RequestBody

#### Traditional Approach
```dart
@Post(
  path: '/users',
  description: 'Creates a new user in the system'
)
Future<Response> createUser(
  Request request,
  @RequestBody(required: true, description: 'New user data') 
  Map<String, dynamic> userData,
) async {
  // Validations
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
  description: 'Creates a new user in the system'
)
Future<Response> createUserEnhanced(
  @RequestBody(required: true, description: 'New user data') 
  Map<String, dynamic> userData,
  @RequestMethod() String method,
  @RequestHost() String host,
) async {
  // Validations
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

### Example with Headers and Auth

#### Traditional Approach - Manual JWT Extraction
```dart
@Post(
  path: '/products',
  description: 'Creates a new product (requires admin)',
  requiresAuth: true
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProduct(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestHeader('X-Store-ID', required: true) String storeId,
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  
  // Validate content type
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
  description: 'Creates a new product (requires admin)',
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
  
  // Validate content type
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

### Example with Query Parameters

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

## 🔗 Combination with Other Annotations

### With Multiple JWT Validators

#### Traditional Approach
```dart
@Post(path: '/transactions', requiresAuth: true)
@JWTController([
  MyFinancialValidator(minimumAmount: 1000),
  MyBusinessHoursValidator(),
], requireAll: true) // Both validators must pass
Future<Response> createTransaction(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> transactionData,
) async {
  // Only executes if the user has financial permissions AND it is during business hours
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
], requireAll: true) // Both validators must pass
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

### With Complex Validation

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

## 💡 Best Practices

### ✅ Do
- **Validate input data**: Always check required fields
- **Use appropriate status codes**: 201 for creation, 200 for operations
- **Include generated IDs**: Return the ID of the created resource
- **Handle validation errors**: Clear responses for invalid data
- **Use @RequestBody**: For structured data in JSON
- **Prefer Enhanced Parameters**: For greater flexibility and less boilerplate
- **Combine approaches**: Traditional for automatic validation, Enhanced for full access

### ❌ Don't
- **Create without validation**: Do not assume data is valid
- **Inconsistent responses**: Maintain a standard format
- **Ignore Content-Type**: Validate that it is application/json when necessary
- **Not returning the created resource**: The client needs to know what was created
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Recommendations by Scenario

#### For Stable Creation APIs
```dart
// ✅ Traditional - Automatic validation of known fields
@Post(path: '/users')
Future<Response> createUser(
  @RequestBody(required: true) Map<String, dynamic> userData,
) async { ... }
```

#### For Dynamic APIs or with Many Options
```dart
// ✅ Enhanced - Flexibility for unlimited options
@Post(path: '/posts')
Future<Response> createPost(
  @RequestBody(required: true) Map<String, dynamic> postData,
  @QueryParam.all() Map<String, String> allOptions,
) async {
  // Handle unlimited creation options dynamically
}
```

#### For APIs with Complex JWT
```dart
// ✅ Enhanced - Direct access to JWT context
@Post(path: '/admin/actions')
@JWTEndpoint([MyAdminValidator()])
Future<Response> adminAction(
  @RequestBody(required: true) Map<String, dynamic> actionData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  final adminId = jwt['user_id'];  // Direct access
}
```

#### For File Uploads
```dart
// ✅ Hybrid - Specific validation + dynamic options
@Post(path: '/upload/{folderId}')
Future<Response> uploadFile(
  @PathParam('folderId') String folderId,              // Type-safe path
  @RequestHeader('Content-Length', required: true) String contentLength, // Required header
  @QueryParam.all() Map<String, String> uploadOptions, // Flexible options
  @RequestBody(required: true) Map<String, dynamic> fileData,
) async { ... }
```

## 🔍 Common Use Cases

### 1. **User creation**

#### Traditional
```dart
@Post(path: '/register', description: 'Registers a new user')
@JWTPublic() // Public endpoint
Future<Response> registerUser(Request request, @RequestBody(required: true) Map<String, dynamic> userData) async { ... }
```

#### Enhanced ✨
```dart
@Post(path: '/register', description: 'Registers a new user')
@JWTPublic() // Public endpoint
Future<Response> registerUserEnhanced(
  @RequestBody(required: true) Map<String, dynamic> userData,
  @RequestHost() String host,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // No Request parameter needed, complete access
}
```

### 2. **Login/Authentication**

#### Traditional
```dart
@Post(path: '/login', description: 'Authenticates user and returns token')
@JWTPublic()
Future<Response> loginUser(Request request, @RequestBody(required: true) Map<String, dynamic> credentials) async { ... }
```

#### Enhanced ✨
```dart
@Post(path: '/login', description: 'Authenticates user and returns token')
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

### 3. **Creation with relationships**

#### Traditional
```dart
@Post(path: '/users/{userId}/orders', description: 'Creates an order for a specific user')
Future<Response> createOrder(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(required: true) Map<String, dynamic> orderData,
) async { ... }
```

#### Enhanced - With Dynamic Options ✨
```dart
@Post(path: '/users/{userId}/orders', description: 'Creates an order with dynamic options')
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

### 4. **File upload**

#### Traditional - Limited
```dart
@Post(path: '/files/upload', description: 'Uploads a file to the server')
Future<Response> uploadFile(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestBody(required: true) Map<String, dynamic> fileData,
) async { ... }
```

#### Enhanced - Complete Upload Control ✨
```dart
@Post(path: '/files/upload', description: 'Uploads a file with complete options')
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

### 5. **Form processing**

#### Traditional
```dart
@Post(path: '/contact', description: 'Processes a contact form')
@JWTPublic()
Future<Response> submitContact(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> contactData,
) async { ... }
```

#### Enhanced - Smart Form Processing ✨
```dart
@Post(path: '/contact', description: 'Processes a smart form')
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

### 6. **🆕 Enhanced Case: API Creation with JWT**
```dart
@Post(path: '/admin/api-keys', description: 'Creates a new API key')
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

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Resource created | `201` | Created - Resource created successfully |
| Successful operation | `200` | OK - Operation completed |
| Invalid data | `400` | Bad Request - Malformed data |
| Unauthorized | `401` | Unauthorized - Invalid JWT token |
| Forbidden | `403` | Forbidden - Insufficient permissions |
| Conflict | `409` | Conflict - Resource already exists |
| Payload too large | `413` | Payload Too Large - File too large |
| Server error | `500` | Internal Server Error |

## 🌐 Resulting URLs

If your controller has `basePath: '/api/v1'` and you use `@Post(path: '/users')`, the final URL will be:
```
POST http://localhost:8080/api/v1/users
```

## 📋 Request/Response Example

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

**Next**: [Documentation for @Put](put-annotation.md) | **Previous**: [Documentation for @Get](get-annotation.md)
