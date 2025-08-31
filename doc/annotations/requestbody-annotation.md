# @RequestBody - Annotation for Request Body

## 📋 Description

The `@RequestBody` annotation is used to capture and process the body of HTTP requests. It allows receiving structured data sent by the client, especially useful for POST, PUT, and PATCH operations.

## 🎯 Purpose

- **Receive structured data**: Capture JSON, XML, or other data formats
- **Resource creation**: Process data to create new records
- **Data update**: Receive information to modify existing resources
- **Complex operations**: Handle payloads with multiple fields and validations

## 📝 Syntax

```dart
@RequestBody({
  bool required = true,           // If the body is mandatory
  String? description,            // Description of the expected content
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `true` | If the request body must be present |
| `description` | `String?` | ❌ No | `null` | Description of the expected format and content |

## 🚀 Usage Examples

### Basic Example - User Creation
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Post(path: '/create')
  Future<Response> createUser(
    Request request,
    @RequestBody(required: true, description: 'New user data') 
    Map<String, dynamic> userData,
  ) async {
    
    // Validate required fields
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
    
    // Validate email format
    final email = userData['email'] as String;
    if (!email.contains('@') || !email.contains('.')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid email format',
        'email': email,
        'expected_format': 'user@domain.com'
      }));
    }
    
    // Create user
    final newUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': userData['name'],
      'email': userData['email'],
      'phone': userData['phone'], // Optional
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

// Request example:
// POST /api/users/create
// Content-Type: application/json
// 
// {
//   "name": "John Doe",
//   "email": "john@example.com",
//   "phone": "+1234567890"
// }
```

### Example with Complex Validation
```dart
@Post(path: '/products')
@JWTEndpoint([MyAdminValidator()])
Future<Response> createProduct(
  Request request,
  @RequestBody(
    required: true, 
    description: 'Complete product data including name, price, category, and specifications'
  ) Map<String, dynamic> productData,
) async {
  
  // Structure validations
  final validationErrors = <String>[];
  
  // Validate name
  final name = productData['name'] as String?;
  if (name == null || name.trim().isEmpty) {
    validationErrors.add('Product name is required and cannot be empty');
  } else if (name.length < 3) {
    validationErrors.add('Product name must be at least 3 characters long');
  } else if (name.length > 100) {
    validationErrors.add('Product name cannot exceed 100 characters');
  }
  
  // Validate price
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
  
  // Validate category
  final category = productData['category'] as String?;
  final validCategories = ['electronics', 'clothing', 'books', 'home', 'sports'];
  if (category == null || !validCategories.contains(category)) {
    validationErrors.add('Product category must be one of: ${validCategories.join(', ')}');
  }
  
  // Validate stock (optional)
  final stock = productData['stock'];
  if (stock != null && (stock is! int || stock < 0)) {
    validationErrors.add('Stock must be a non-negative integer');
  }
  
  // Validate specifications (optional)
  final specifications = productData['specifications'];
  if (specifications != null && specifications is! Map<String, dynamic>) {
    validationErrors.add('Specifications must be an object with key-value pairs');
  }
  
  // Validate tags (optional)
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
  
  // Return errors if they exist
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
  
  // Get JWT information
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Create product
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

### Partial Update Example (PATCH)
```dart
@Patch(path: '/users/{userId}')
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUser(
  Request request,
  @PathParam('userId') String userId,
  @RequestBody(
    required: true,
    description: 'User fields to update (only include fields to be modified)'
  ) Map<String, dynamic> updates,
) async {
  
  // Check that there is something to update
  if (updates.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'No fields to update',
      'hint': 'Include at least one field in the request body',
      'updatable_fields': ['name', 'email', 'phone', 'preferences']
    }));
  }
  
  // Validate that the JWT user matches the path user
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Cannot update other users',
      'path_user_id': userId,
      'token_user_id': tokenUserId
    }));
  }
  
  // Valid fields for update
  final validFields = ['name', 'email', 'phone', 'preferences'];
  final updatedFields = <String>[];
  final invalidFields = <String>[];
  final validationErrors = <String>[];
  
  // Validate each sent field
  for (final field in updates.keys) {
    if (!validFields.contains(field)) {
      invalidFields.add(field);
      continue;
    }
    
    final value = updates[field];
    
    // Specific validations per field
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
  
  // Return errors if they exist
  if (invalidFields.isNotEmpty || validationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Update validation failed',
      'invalid_fields': invalidFields,
      'validation_errors': validationErrors,
      'valid_fields': validFields,
    }));
  }
  
  // Build response with updated fields
  final userUpdate = <String, dynamic>{
    'user_id': userId,
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  // Add only the fields that were updated
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

### Example with Multiple Body Types
```dart
@Post(path: '/files/upload')
@JWTEndpoint([MyFileValidator()])
Future<Response> uploadFile(
  Request request,
  @RequestHeader('Content-Type', required: true) String contentType,
  @RequestBody(
    required: true,
    description: 'File metadata or base64 content depending on Content-Type'
  ) Map<String, dynamic> fileData,
) async {
  
  if (contentType.contains('application/json')) {
    // Metadata mode - the file is uploaded separately
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
    
    // Validate size
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
    // Direct upload mode (simulated)
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

### Example with Schema Validation
```dart
@Post(path: '/webhooks/payment')
@JWTPublic() // Webhooks may come without JWT
Future<Response> handlePaymentWebhook(
  Request request,
  @RequestHeader('X-Webhook-Signature', required: true) String signature,
  @RequestBody(
    required: true,
    description: 'Payment webhook payload with event and data'
  ) Map<String, dynamic> webhookPayload,
) async {
  
  // Validate basic webhook structure
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
  
  // Validate event
  final validEvents = ['payment.completed', 'payment.failed', 'payment.refunded'];
  if (!validEvents.contains(event)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid webhook event',
      'event': event,
      'valid_events': validEvents
    }));
  }
  
  // Validate timestamp
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
  
  // Validate that the event is not too old (more than 5 minutes)
  final now = DateTime.now();
  if (now.difference(eventTime).inMinutes > 5) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Webhook event too old',
      'event_timestamp': timestamp,
      'current_timestamp': now.toIso8601String(),
      'max_age_minutes': 5
    }));
  }
  
  // Validate data according to event type
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
  
  // TODO: Verify webhook signature for security
  // final calculatedSignature = calculateWebhookSignature(webhookPayload);
  // if (signature != calculatedSignature) { ... }
  
  // Process the webhook
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
      'signature_verified': true, // Simulated
    }
  }));
}
```

## 🔗 Combination with Other Annotations

### With Path Parameters and Headers
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
    description: 'Updated product data'
  ) Map<String, dynamic> productUpdates,
) async {
  
  // Validate content type
  if (!contentType.contains('application/json')) {
    return Response.badRequest(body: 'Content-Type must be application/json');
  }
  
  // The rest of the logic...
  return jsonResponse(jsonEncode({
    'message': 'Product updated successfully',
    'store_id': storeId,
    'product_id': productId,
    'updates': productUpdates
  }));
}
```

## ❓ FAQ: Why Request + @RequestBody?

### Common Doubt
"Why do I need both `Request request` and `@RequestBody()`? Shouldn't it be automatic like in Spring Boot?"

### Answer
**You are right!** - The framework has evolved and you **NO LONGER need** the redundant `Request request` parameter. You can now use **Enhanced Parameters** for direct access:

- **`@RequestBody()`**: Automatically parses the JSON from the body
- **Enhanced Parameters**: Direct access to JWT, headers, context **WITHOUT** the Request parameter

### ❌ Previous Approach (Redundant)
```dart
@Post(path: '/users')
@JWTEndpoint([MyUserValidator()])
Future<Response> createUser(
  Request request, // ❌ NO LONGER NECESSARY
  @RequestBody(required: true) Map<String, dynamic> userData,
) async {
  // Manual JWT extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final userId = jwtPayload['user_id'];
  
  final name = userData['name'];
}
```

### ✅ Current Approach (Enhanced Parameters) ✨
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

### 💫 Benefits of the Enhanced Approach
1. **No Request parameter** - We eliminate redundancy
2. **Direct JWT access** - `@RequestContext('jwt_payload')` injects directly
3. **Complete headers** - `@RequestHeader.all()` gives access to everything
4. **Request information** - `@RequestHost()`, `@RequestMethod()`, etc.
5. **Cleaner code** - Less boilerplate, more declarative

### 🔄 Complete Comparison

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

## 💡 Best Practices

### ✅ Do
- **Use @RequestBody when available**: Avoids manual parsing
- **Prefer Enhanced Parameters**: Eliminates the redundant Request parameter
- **Combine approaches**: @RequestBody + Enhanced Parameters for full context
- **Always validate**: Check structure, types, and values of the data
- **Provide examples**: In descriptions and error messages
- **Document expected structure**: Specify mandatory and optional fields

### ❌ Don't
- **Manual parsing with @RequestBody present**: It is redundant and confusing
- **Redundant Request parameter**: Use Enhanced Parameters when possible
- **Using only Request for everything**: Take advantage of automatic annotations
- **Generic error messages**: Be specific about what is wrong
- **Not sanitizing input**: Validate and clean input data

### 🎯 Enhanced Recommendations by Scenario

#### For Resource Creation with JWT
```dart
// ✅ Enhanced - No Request parameter
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

#### For Update with Complex Validation
```dart
// ✅ Enhanced - Full context for auditing
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

#### For Public APIs with Context
```dart
// ✅ Enhanced - Complete information without JWT
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

#### For Webhooks with Enhanced Validation
```dart
// ✅ Enhanced - Webhook processing with full context
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

## 🔍 Request Body Types

### 1. **Resource creation**
```dart
@RequestBody(required: true, description: 'Complete data to create the resource')
Map<String, dynamic> resourceData,
```

### 2. **Partial update**
```dart
@RequestBody(required: true, description: 'Fields to update (only include modified ones)')
Map<String, dynamic> updates,
```

### 3. **Configuration/Settings**
```dart
@RequestBody(required: true, description: 'Full or partial configuration')
Map<String, dynamic> settings,
```

### 4. **Complex operations**
```dart
@RequestBody(required: true, description: 'Parameters for the complex operation')
Map<String, dynamic> operationParams,
```

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Missing required body | `400` | Bad Request - Request body required |
| Malformed JSON | `400` | Bad Request - Invalid JSON format |
| Missing required fields | `400` | Bad Request - Required fields missing |
| Incorrect data types | `400` | Bad Request - Invalid data types |
| Values out of range | `400` | Bad Request - Values out of valid range |
| Body too large | `413` | Payload Too Large |

## 🌐 Request/Response Example

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

**Next**: [Documentation for @RequestHeader](requestheader-annotation.md) | **Previous**: [Documentation for @QueryParam](queryparam-annotation.md)
