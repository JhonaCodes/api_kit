# @PathParam - Annotation for Path Parameters

## 📋 Description

The `@PathParam` annotation is used to capture dynamic values from the endpoint URL. It allows extracting variable segments from the path and automatically converting them to method parameters.

## 🎯 Purpose

- **Capture IDs**: Get unique identifiers of resources (`/users/{id}`)
- **Dynamic routes**: Handle variable segments in URLs (`/stores/{storeId}/products/{productId}`)
- **Hierarchical navigation**: Nested routes with multiple parameters
- **RESTful APIs**: Follow standard REST patterns for resources

## 📝 Syntax

```dart
@PathParam(
  String name,                    // Name of the parameter in the URL (REQUIRED)
  {String? description}           // Description of the parameter
)
```

## 🔧 Parameters

| Parameter | Type | Required | Description |
|-----------|------|-------------|-------------|
| `name` | `String` | ✅ Yes | Exact name of the parameter defined in the route between `{}` |
| `description` | `String?` | ❌ No | Description of the purpose and expected format of the parameter |

## 🚀 Usage Examples

### Basic Example - One Parameter
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/{id}')  // Route: /api/users/{id}
  Future<Response> getUserById(
    Request request,
    @PathParam('id') String userId,  // Captures the value of {id}
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'User retrieved successfully',
      'user_id': userId,  // userId contains the value from the URL
      'url_path': '/api/users/$userId'
    }));
  }
}

// Usage example:
// GET /api/users/user_123 -> userId = "user_123"
// GET /api/users/456      -> userId = "456"
```

### Example with Description
```dart
@Get(path: '/products/{productId}')
Future<Response> getProduct(
  Request request,
  @PathParam('productId', description: 'Unique product ID in prod_* format') 
  String productId,
) async {
  
  // Validate ID format
  if (!productId.startsWith('prod_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid product ID format',
      'expected_format': 'prod_*',
      'received': productId,
      'example': 'prod_123456'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'product_id': productId,
    'message': 'Product retrieved successfully'
  }));
}

// Usage examples:
// GET /products/prod_123 -> ✅ Valid
// GET /products/123      -> ❌ Format error
```

### Example with Multiple Parameters
```dart
@RestController(basePath: '/api/stores')
class StoreController extends BaseController {
  
  @Get(path: '/{storeId}/categories/{categoryId}/products/{productId}')
  Future<Response> getStoreProduct(
    Request request,
    @PathParam('storeId', description: 'Unique store ID') String storeId,
    @PathParam('categoryId', description: 'Product category ID') String categoryId,
    @PathParam('productId', description: 'Specific product ID') String productId,
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'Store product retrieved successfully',
      'hierarchy': {
        'store_id': storeId,
        'category_id': categoryId,
        'product_id': productId,
      },
      'full_path': '/stores/$storeId/categories/$categoryId/products/$productId'
    }));
  }
}

// Usage example:
// GET /api/stores/store_456/categories/electronics/products/prod_789
// storeId = "store_456"
// categoryId = "electronics" 
// productId = "prod_789"
```

### Example with Type Validation
```dart
@Get(path: '/orders/{orderId}/items/{itemNumber}')
Future<Response> getOrderItem(
  Request request,
  @PathParam('orderId', description: 'Order ID') String orderId,
  @PathParam('itemNumber', description: 'Item number (1-99)') String itemNumberStr,
) async {
  
  // Convert and validate itemNumber
  final itemNumber = int.tryParse(itemNumberStr);
  if (itemNumber == null || itemNumber < 1 || itemNumber > 99) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid item number',
      'received': itemNumberStr,
      'valid_range': '1-99',
      'type': 'integer'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'order_id': orderId,
    'item_number': itemNumber,  // Converted to int
    'item_number_string': itemNumberStr,  // Original value
  }));
}

// Examples:
// GET /orders/order_123/items/5  -> ✅ itemNumber = 5
// GET /orders/order_123/items/abc -> ❌ Type error
// GET /orders/order_123/items/100 -> ❌ Out of range
```

### Example with Parameters and Query Parameters
```dart
@Get(path: '/users/{userId}/posts/{postId}')
Future<Response> getUserPost(
  Request request,
  // Path Parameters
  @PathParam('userId', description: 'Owner user ID') String userId,
  @PathParam('postId', description: 'Specific post ID') String postId,
  
  // Additional Query Parameters
  @QueryParam('include_comments', defaultValue: false) bool includeComments,
  @QueryParam('format', defaultValue: 'json') String format,
) async {
  
  // Validate that the user can access the post
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
  final currentUser = jwtPayload?['user_id'];
  
  final postData = {
    'post_id': postId,
    'user_id': userId,
    'title': 'Sample post title',
    'content': 'Post content here...',
    'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
  };
  
  if (includeComments) {
    postData['comments'] = [
      {'id': 'comment_1', 'content': 'Great post!'},
      {'id': 'comment_2', 'content': 'Thanks for sharing'}
    ];
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Post retrieved successfully',
    'post': postData,
    'request_info': {
      'user_id': userId,
      'post_id': postId,
      'include_comments': includeComments,
      'format': format,
      'current_user': currentUser
    }
  }));
}

// Usage example:
// GET /users/user_123/posts/post_456?include_comments=true&format=detailed
```

### Example with JWT and Path Validation

#### Traditional Approach - Manual JWT Extraction
```dart
@Put(path: '/users/{userId}/settings')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserSettings(
  Request request,
  @PathParam('userId', description: 'ID of the user to update') String userId,
  @RequestBody(required: true) Map<String, dynamic> settings,
) async {
  
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  // Validate that the user can only update their own settings
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update settings for other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'hint': 'You can only update your own settings'
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Settings updated successfully',
    'user_id': userId,
    'updated_settings': settings,
    'updated_by': tokenUserId,
    'path_validation': 'passed'
  }));
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@Put(path: '/users/{userId}/settings')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserSettingsEnhanced(
  @PathParam('userId', description: 'ID of the user to update') String userId,
  @RequestBody(required: true) Map<String, dynamic> settings,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
  @RequestHeader.all() Map<String, String> headers,
  @RequestMethod() String method,
) async {
  
  // Direct JWT access - no manual extraction needed!
  final tokenUserId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];
  
  // Validate that the user can only update their own settings
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update settings for other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'user_role': userRole,
      'hint': 'You can only update your own settings'
    }));
  }
  
  // Enhanced context for auditing
  final updateContext = {
    'updated_by': tokenUserId,
    'user_role': userRole,
    'method': method,
    'user_agent': headers['user-agent'],
    'content_type': headers['content-type'],
  };
  
  return jsonResponse(jsonEncode({
    'message': 'Settings updated successfully - Enhanced!',
    'user_id': userId,
    'updated_settings': settings,
    'update_context': updateContext,
    'path_validation': 'passed',
    'enhanced': true,
  }));
}

// Correct example:
// PUT /users/user_123/settings (with JWT of user_123) -> ✅ Authorized
// PUT /users/user_456/settings (with JWT of user_123) -> ❌ Forbidden
```

### Example with File/Slug Parameters
```dart
@Get(path: '/docs/{category}/{filename}')
Future<Response> getDocumentFile(
  Request request,
  @PathParam('category', description: 'Document category') String category,
  @PathParam('filename', description: 'File name with extension') String filename,
) async {
  
  // Validate category
  final validCategories = ['api', 'tutorials', 'guides', 'reference'];
  if (!validCategories.contains(category)) {
    return Response.notFound(jsonEncode({
      'error': 'Invalid document category',
      'category': category,
      'valid_categories': validCategories
    }));
  }
  
  // Validate file extension
  final allowedExtensions = ['.md', '.pdf', '.txt', '.html'];
  final hasValidExtension = allowedExtensions.any((ext) => filename.endsWith(ext));
  
  if (!hasValidExtension) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid file extension',
      'filename': filename,
      'allowed_extensions': allowedExtensions
    }));
  }
  
  // Build file path
  final filePath = 'docs/$category/$filename';
  
  return jsonResponse(jsonEncode({
    'message': 'Document found',
    'category': category,
    'filename': filename,
    'file_path': filePath,
    'file_url': 'https://api.example.com/docs/$category/$filename'
  }));
}

// Usage examples:
// GET /docs/api/authentication.md     -> ✅ Valid
// GET /docs/tutorials/getting-started.pdf -> ✅ Valid  
// GET /docs/invalid/file.exe          -> ❌ Invalid category and extension
```

## 🔗 Combination with Other Annotations

### With RequestBody and Headers
```dart
@Put(path: '/stores/{storeId}/products/{productId}')
Future<Response> updateStoreProduct(
  Request request,
  // Path Parameters
  @PathParam('storeId', description: 'Store ID') String storeId,
  @PathParam('productId', description: 'Product ID') String productId,
  
  // Headers
  @RequestHeader('X-Store-Verification', required: true) String storeVerification,
  
  // Body
  @RequestBody(required: true) Map<String, dynamic> productData,
) async {
  
  // Validate that the header matches the path parameter
  if (storeVerification != storeId) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Store verification mismatch',
      'path_store_id': storeId,
      'header_store_id': storeVerification
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'store_id': storeId,
    'product_id': productId,
    'verification': 'passed'
  }));
}
```

## 💡 Best Practices

### ✅ Do
- **Use descriptive names**: `userId` instead of just `id`
- **Include descriptions**: Specify expected format and examples
- **Validate format**: Verify that IDs follow the expected format
- **Handle errors**: Clear responses for invalid or not found IDs
- **Be consistent**: Use the same format for similar types of IDs
- **Combine with Enhanced Parameters**: For full context access without Request
- **Prefer hybrid approach**: Specific @PathParam + Enhanced Parameters for context

### ❌ Don't
- **Generic names**: `id` when there are multiple parameters
- **Not validating format**: Assuming all values are valid
- **Sensitive IDs in URL**: Avoid putting sensitive information in path parameters
- **Very long routes**: Do not abuse nested parameters
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Enhanced Recommendations for PathParam

#### For Resources with JWT Validation
```dart
// ✅ Enhanced - Specific PathParam + direct JWT
@Get(path: '/users/{userId}/profile')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(
  @PathParam('userId') String userId,                    // Type-safe path param
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct JWT
  @RequestHost() String host,
) async {
  final currentUser = jwt['user_id'];
  
  return jsonResponse(jsonEncode({
    'profile': 'user profile data',
    'user_id': userId,
    'requested_by': currentUser,
    'host': host,
  }));
}
```

#### For Multi-level Resource Hierarchies
```dart
// ✅ Enhanced - Multiple PathParams + full context
@Get(path: '/stores/{storeId}/categories/{categoryId}/products/{productId}')
Future<Response> getStoreProductEnhanced(
  @PathParam('storeId') String storeId,
  @PathParam('categoryId') String categoryId,
  @PathParam('productId') String productId,
  @QueryParam.all() Map<String, String> options,  // Dynamic options
  @RequestMethod() String method,
  @RequestPath() String fullPath,
) async {
  return jsonResponse(jsonEncode({
    'hierarchy': {
      'store_id': storeId,
      'category_id': categoryId,
      'product_id': productId,
    },
    'options': options,
    'request_info': {
      'method': method,
      'full_path': fullPath,
    },
  }));
}
```

#### For File/Document Access
```dart
// ✅ Enhanced - File params + security headers
@Get(path: '/files/{folder}/{filename}')
@JWTEndpoint([MyFileValidator()])
Future<Response> getFileEnhanced(
  @PathParam('folder') String folder,
  @PathParam('filename') String filename,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  final userId = jwt['user_id'];
  final userAgent = headers['user-agent'] ?? 'unknown';
  
  // Enhanced security logging
  final accessLog = {
    'user_id': userId,
    'folder': folder,
    'filename': filename,
    'user_agent': userAgent,
    'host': host,
    'access_time': DateTime.now().toIso8601String(),
  };
  
  return jsonResponse(jsonEncode({
    'message': 'File accessed successfully',
    'file_path': '$folder/$filename',
    'access_log': accessLog,
  }));
}
```

#### For User-specific Resources
```dart
// ✅ Enhanced - User ownership validation
@Put(path: '/users/{userId}/documents/{docId}')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserDocument(
  @PathParam('userId') String userId,
  @PathParam('docId') String docId,
  @RequestBody(required: true) Map<String, dynamic> docData,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final tokenUserId = jwt['user_id'];
  
  // Enhanced ownership validation
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot modify documents of other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId,
      'document_id': docId,
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Document updated successfully',
    'user_id': userId,
    'document_id': docId,
    'updated_fields': docData.keys.toList(),
    'client_info': {
      'user_agent': headers['user-agent'],
      'content_type': headers['content-type'],
    },
  }));
}
```

## 🔍 Common Use Cases

### 1. **Resource by ID**
```dart
@Get(path: '/users/{userId}')
Future<Response> getUser(Request request, @PathParam('userId') String userId) async { ... }
```

### 2. **Nested resource**
```dart
@Get(path: '/users/{userId}/orders/{orderId}')
Future<Response> getUserOrder(
  Request request,
  @PathParam('userId') String userId,
  @PathParam('orderId') String orderId,
) async { ... }
```

### 3. **Categories/Slugs**
```dart
@Get(path: '/blog/{category}/{slug}')
Future<Response> getBlogPost(
  Request request,
  @PathParam('category') String category,
  @PathParam('slug') String slug,
) async { ... }
```

### 4. **Files/Routes**
```dart
@Get(path: '/files/{folder}/{filename}')
Future<Response> getFile(
  Request request,
  @PathParam('folder') String folder,
  @PathParam('filename') String filename,
) async { ... }
```

## 📊 Recommended Validations

### Format Validation
```dart
// Validate IDs with a specific format
if (!userId.startsWith('user_') || userId.length < 10) {
  return Response.badRequest(body: 'Invalid user ID format');
}

// Validate numeric IDs
final numericId = int.tryParse(productId);
if (numericId == null || numericId <= 0) {
  return Response.badRequest(body: 'Product ID must be a positive integer');
}

// Validate slugs/filenames
if (filename.contains('..') || filename.contains('/')) {
  return Response.badRequest(body: 'Invalid filename');
}
```

### Existence Validation
```dart
// In a real implementation, check in the database
final user = await userRepository.findById(userId);
if (user == null) {
  return Response.notFound(jsonEncode({
    'error': 'User not found',
    'user_id': userId
  }));
}
```

## 🌐 URL Mapping

### Mapping Examples
```dart
// Definition
@Get(path: '/stores/{storeId}/products/{productId}')

// Valid URLs:
// /stores/store_123/products/prod_456
// -> storeId = "store_123", productId = "prod_456"

// /stores/my-store/products/special-item
// -> storeId = "my-store", productId = "special-item"
```

### Special Characters
- **Allowed in path params**: letters, numbers, `-`, `_`
- **Automatically URL-decoded**: spaces and special characters
- **Case-sensitive**: `Store_123` ≠ `store_123`

---

**Next**: [Documentation for @QueryParam](queryparam-annotation.md) | **Previous**: [Documentation for @RestController](restcontroller-annotation.md)
