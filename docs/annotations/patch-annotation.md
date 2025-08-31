# @Patch - Annotation for PATCH Endpoints

## 📋 Description

The `@Patch` annotation is used to mark methods as endpoints that respond to HTTP PATCH requests. It is the standard annotation for partial update operations of existing resources.

## 🎯 Purpose

- **Partial update**: Modify only some fields of an existing resource
- **Efficient operations**: Only send and process modified fields
- **Incremental updates**: Gradual changes without affecting other fields
- **Configuration APIs**: Modify specific preferences without touching others

## 📝 Syntax

```dart
@Patch({
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
| `description` | `String?` | ❌ No | `null` | Readable description of the endpoint\'s purpose |
| `statusCode` | `int` | ❌ No | `200` | HTTP status code for a successful response |
| `requiresAuth` | `bool` | ❌ No | `true` | Indicates if the endpoint requires authentication |

> **Note**: PATCH requires authentication by default (`requiresAuth = true`) as it modifies protected resources.

## 🚀 Usage Examples

### Basic Example

#### Traditional Approach - Manual Body Parsing
```dart
@RestController(basePath: \'/api/users\')
class UserController extends BaseController {
  
  @Patch(path: \'/{id}\')
  Future<Response> updateUserPartial(
    Request request,
    @PathParam(\'id\') String userId,
  ) async {
    // Manual body parsing
    final body = await request.readAsString();
    final updates = jsonDecode(body) as Map<String, dynamic>;
    
    // Only update sent fields
    final updatedFields = <String>[];
    final result = <String, dynamic>{
      \'id\': userId,
      \'updated_at\': DateTime.now().toIso8601String(),
    };
    
    // Apply only the sent fields
    if (updates.containsKey(\'name\')) {
      result[\'name\'] = updates[\'name\'];
      updatedFields.add(\'name\');
    }
    
    if (updates.containsKey(\'email\')) {
      result[\'email\'] = updates[\'email\'];
      updatedFields.add(\'email\');
    }
    
    return jsonResponse(jsonEncode({
      \'message\': \'User updated successfully\',
      \'user\': result,
      \'updated_fields\': updatedFields,
    }));
  }
}
```

#### Enhanced Approach - Direct Body Injection ✨
```dart
@RestController(basePath: \'/api/users\')
class UserController extends BaseController {
  
  @Patch(path: \'/{id}\')
  Future<Response> updateUserPartialEnhanced(
    @PathParam(\'id\') String userId,
    @RequestBody() Map<String, dynamic> updates,  // Direct body injection
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    // No manual parsing needed!
    final updatedFields = <String>[];
    final result = <String, dynamic>{
      \'id\': userId,
      \'updated_at\': DateTime.now().toIso8601String(),
      \'method_used\': method,      // Direct access
      \'endpoint_path\': path,      // Direct access
    };
    
    // Apply only the sent fields
    if (updates.containsKey(\'name\')) {
      result[\'name\'] = updates[\'name\'];
      updatedFields.add(\'name\');
    }
    
    if (updates.containsKey(\'email\')) {
      result[\'email\'] = updates[\'email\'];
      updatedFields.add(\'email\');
    }
    
    // Enhanced: Handle any additional fields dynamically
    final allowedFields = [\'name\', \'email\', \'phone\', \'address\'];
    for (final field in updates.keys) {
      if (![\'name\', \'email\'].contains(field) && allowedFields.contains(field)) {
        result[field] = updates[field];
        updatedFields.add(field);
      }
    }
    
    return jsonResponse(jsonEncode({
      \'message\': \'User updated successfully - Enhanced!\',
      \'user\': result,
      \'updated_fields\': updatedFields,
      \'total_updates\': updatedFields.length,
      \'enhanced\': true,
    }));
  }
}
```

### Example with Selective Validation
```dart
@Patch(
  path: \'/products/{productId}\',
  description: \'Updates specific fields of a product\'
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> updateProductPartial(
  Request request,
  @PathParam(\'productId\', description: \'Unique product ID\') String productId,
  @RequestBody(required: true, description: \'Fields to update for the product\') 
  Map<String, dynamic> updates,
) async {
  
  if (updates.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'No fields to update\',
      \'hint\': \'Include at least one field in the request body\'
    }));
  }
  
  // Valid fields for update
  final validFields = [\'name\', \'price\', \'description\', \'category\', \'stock\', \'tags\'];
  final updatedFields = <String>[];
  final invalidFields = <String>[];
  
  // Validate that only valid fields are sent
  for (final field in updates.keys) {
    if (validFields.contains(field)) {
      updatedFields.add(field);
    } else {
      invalidFields.add(field);
    }
  }
  
  if (invalidFields.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'Invalid fields in update request\',
      \'invalid_fields\': invalidFields,
      \'valid_fields\': validFields
    }));
  }
  
  // Specific validations per field
  if (updates.containsKey(\'price\')) {
    final price = updates[\'price\'];
    if (price is! num || price <= 0) {
      return Response.badRequest(body: jsonEncode({
        \'error\': \'Price must be a positive number\',
        \'received_price\': price
      }));
    }
  }
  
  if (updates.containsKey(\'stock\')) {
    final stock = updates[\'stock\'];
    if (stock is! int || stock < 0) {
      return Response.badRequest(body: jsonEncode({
        \'error\': \'Stock must be a non-negative integer\',
        \'received_stock\': stock
      }));
    }
  }
  
  // Get JWT information
  final jwtPayload = request.context[\'jwt_payload\'] as Map<String, dynamic>;
  final adminUser = jwtPayload[\'user_id\'];
  
  // Build response with only the updated fields
  final patchedProduct = <String, dynamic>{
    \'id\': productId,
    \'updated_at\': DateTime.now().toIso8601String(),
    \'updated_by\': adminUser,
  };
  
  // Add only the fields that were updated
  for (final field in updatedFields) {
    patchedProduct[field] = updates[field];
  }
  
  return jsonResponse(jsonEncode({
    \'message\': \'Product updated successfully\',
    \'product\': patchedProduct,
    \'updated_fields\': updatedFields,
    \'patch_summary\': {
      \'fields_updated\': updatedFields.length,
      \'total_valid_fields\': validFields.length,
      \'update_percentage\': ((updatedFields.length / validFields.length) * 100).toStringAsFixed(1),
    },
  }));
}
```

### Status Update Example
```dart
@Patch(
  path: \'/orders/{orderId}/status\',
  description: \'Updates the status of an order\'
)
@JWTEndpoint([MyWarehouseValidator()])
Future<Response> updateOrderStatus(
  Request request,
  @PathParam(\'orderId\', description: \'Order ID\') String orderId,
  @QueryParam(\'notify_customer\', defaultValue: true) bool notifyCustomer,
  @RequestBody(required: true) Map<String, dynamic> statusUpdate,
) async {
  
  // Validate that it includes the status field
  if (!statusUpdate.containsKey(\'status\')) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'Status field is required\',
      \'required_fields\': [\'status\'],
      \'optional_fields\': [\'notes\', \'estimated_delivery\']
    }));
  }
  
  final newStatus = statusUpdate[\'status\'] as String?;
  final validStatuses = [\'pending\', \'processing\', \'shipped\', \'delivered\', \'cancelled\'];
  
  if (newStatus == null || !validStatuses.contains(newStatus)) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'Invalid status value\',
      \'received_status\': newStatus,
      \'valid_statuses\': validStatuses
    }));
  }
  
  // Get JWT information
  final jwtPayload = request.context[\'jwt_payload\'] as Map<String, dynamic>;
  final warehouseUser = jwtPayload[\'user_id\'];
  
  // Build status update
  final statusUpdateResult = {
    \'order_id\': orderId,
    \'status\': newStatus,
    \'updated_at\': DateTime.now().toIso8601String(),
    \'updated_by\': warehouseUser,
  };
  
  // Optional fields
  if (statusUpdate.containsKey(\'notes\')) {
    statusUpdateResult[\'notes\'] = statusUpdate[\'notes\'];
  }
  
  if (statusUpdate.containsKey(\'estimated_delivery\') && newStatus == \'shipped\') {
    statusUpdateResult[\'estimated_delivery\'] = statusUpdate[\'estimated_delivery\'];
  }
  
  // Simulate customer notification
  final actions = <String>[];
  if (notifyCustomer) {
    actions.add(\'customer_notified\');
  }
  
  // Add automatic actions based on status
  if (newStatus == \'shipped\') {
    actions.add(\'tracking_number_generated\');
  } else if (newStatus == \'delivered\') {
    actions.add(\'feedback_request_sent\');
  }
  
  return jsonResponse(jsonEncode({
    \'message\': \'Order status updated successfully\',
    \'order\': statusUpdateResult,
    \'previous_status\': \'processing\', // In a real implementation, get from DB
    \'new_status\': newStatus,
    \'actions_performed\': actions,
    \'metadata\': {
      \'status_change_valid\': true,
      \'notification_sent\': notifyCustomer,
      \'update_type\': \'status_patch\',
    },
  }));
}
```

### Partial Configuration Example
```dart
@Patch(
  path: \'/users/{userId}/preferences\',
  description: \'Updates specific user preferences\'
)
@JWTEndpoint([MyUserValidator()]) // Only the user themselves
Future<Response> updateUserPreferences(
  Request request,
  @PathParam(\'userId\') String userId,
  @RequestBody(required: true, description: \'Preferences to update\') 
  Map<String, dynamic> preferences,
) async {
  
  // Validate that the JWT corresponds to the user
  final jwtPayload = request.context[\'jwt_payload\'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload[\'user_id\'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      \'error\': \'Can only update your own preferences\',
      \'token_user_id\': tokenUserId,
      \'requested_user_id\': userId
    }));
  }
  
  // Valid preferences that can be updated
  final validPreferences = {
    \'theme\': [\'light\', \'dark\', \'auto\'],
    \'language\': [\'en\', \'es\', \'fr\', \'de\'],
    \'notifications\': null, // Object, validated separately
    \'timezone\': null, // String, validated separately
    \'currency\': [\'USD\', \'EUR\', \'GBP\', \'JPY\'],
  };
  
  final updatedPreferences = <String, dynamic>{};
  final validationErrors = <String>[];
  
  for (final pref in preferences.keys) {
    if (!validPreferences.containsKey(pref)) {
      validationErrors.add(\'Unknown preference: $pref\');
      continue;
    }
    
    final value = preferences[pref];
    final allowedValues = validPreferences[pref];
    
    // Validate specific values
    if (allowedValues != null && !allowedValues.contains(value)) {
      validationErrors.add(\'Invalid value for $pref: $value. Allowed: $allowedValues\');
      continue;
    }
    
    // Special validations
    if (pref == \'notifications\' && value is Map<String, dynamic>) {
      // Validate notification structure
      final validNotificationKeys = [\'email\', \'push\', \'sms\'];
      final invalidKeys = value.keys.where((k) => !validNotificationKeys.contains(k));
      
      if (invalidKeys.isNotEmpty) {
        validationErrors.add(\'Invalid notification keys: $invalidKeys\');
        continue;
      }
    }
    
    if (pref == \'timezone\' && value is String) {
      // Basic timezone validation
      if (!value.contains(\'/\')) {
        validationErrors.add(\'Timezone must be in format: Continent/City\');
        continue;
      }
    }
    
    updatedPreferences[pref] = value;
  }
  
  if (validationErrors.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'Preference validation failed\',
      \'validation_errors\': validationErrors,
      \'valid_preferences\': validPreferences.keys.toList(),
    }));
  }
  
  // Build response with updated preferences
  final preferencesUpdate = {
    \'user_id\': userId,
    \'updated_preferences\': updatedPreferences,
    \'updated_at\': DateTime.now().toIso8601String(),
  };
  
  return jsonResponse(jsonEncode({
    \'message\': \'User preferences updated successfully\',
    \'preferences\': preferencesUpdate,
    \'updated_count\': updatedPreferences.length,
    \'update_summary\': {
      \'preferences_updated\': updatedPreferences.keys.toList(),
      \'total_available_preferences\': validPreferences.length,
    },
  }));
}
```

## 🔗 Combination with Other Annotations

### With Query Parameters for Options
```dart
@Patch(path: \'/articles/{articleId}\')
Future<Response> updateArticle(
  Request request,
  @PathParam(\'articleId\') String articleId,
  @QueryParam(\'publish\', defaultValue: false) bool shouldPublish,
  @QueryParam(\'send_notifications\', defaultValue: false) bool sendNotifications,
  @RequestBody(required: true) Map<String, dynamic> updates,
) async {
  
  // Validate article fields
  final validFields = [\'title\', \'content\', \'tags\', \'category\', \'excerpt\'];
  final updatedFields = updates.keys.where((k) => validFields.contains(k)).toList();
  
  if (updatedFields.isEmpty) {
    return Response.badRequest(body: jsonEncode({
      \'error\': \'No valid fields to update\',
      \'valid_fields\': validFields
    }));
  }
  
  // Build result
  final articleUpdate = <String, dynamic>{
    \'id\': articleId,
    \'updated_at\': DateTime.now().toIso8601String(),
  };
  
  // Add only updated fields
  for (final field in updatedFields) {
    articleUpdate[field] = updates[field];
  }
  
  // Apply actions based on query parameters
  final actions = <String>[];
  if (shouldPublish) {
    articleUpdate[\'status\'] = \'published\';
    articleUpdate[\'published_at\'] = DateTime.now().toIso8601String();
    actions.add(\'published\');
  }
  
  if (sendNotifications && shouldPublish) {
    actions.add(\'subscribers_notified\');
  }
  
  return jsonResponse(jsonEncode({
    \'message\': \'Article updated successfully\',
    \'article\': articleUpdate,
    \'updated_fields\': updatedFields,
    \'actions_performed\': actions,
  }));
}
```

## 💡 Best Practices

### ✅ Do
- **Validate sent fields**: Verify that they are valid for update
- **Update only sent fields**: Do not touch unspecified fields
- **Return updated fields**: Show what exactly changed
- **Allow empty updates**: Return an error if there are no fields
- **Validate data types**: Each field must have the correct type
- **Prefer Enhanced Parameters**: For full access without the Request parameter
- **Combine approaches**: Traditional for specific validation, Enhanced for flexibility

### ❌ Don\'t
- **Require all fields**: That is PUT\'s responsibility
- **Update unsent fields**: Only modify what is specified
- **Ignore per-field validations**: Each field must be validated individually
- **Return the full resource**: Only return updated fields and metadata
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Enhanced Recommendations by Scenario

#### For PATCH with Specific Validation
```dart
// ✅ Traditional - Automatic validation per field
@Patch(path: \'/users/{id}\')
Future<Response> updateUser(
  @PathParam(\'id\') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
) async {
  // Automatic validation for each field
}
```

#### For PATCH with Full Context
```dart
// ✅ Enhanced - Full access without Request parameter
@Patch(path: \'/products/{id}\')
Future<Response> updateProductEnhanced(
  @PathParam(\'id\') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
  @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,
  @RequestHeader.all() Map<String, String> headers,
) async {
  final updatedBy = jwt[\'user_id\'];  // Direct access
  final userAgent = headers[\'user-agent\'];  // All headers
}
```

#### For PATCH with Dynamic Options
```dart
// ✅ Enhanced - Flexible update options
@Patch(path: \'/articles/{id}\')
Future<Response> updateArticleWithOptions(
  @PathParam(\'id\') String id,
  @RequestBody(required: true) Map<String, dynamic> updates,
  @QueryParam.all() Map<String, String> patchOptions,
  @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,
) async {
  final notify = patchOptions[\'notify_subscribers\']?.toLowerCase() == \'true\';
  final autoPublish = patchOptions[\'auto_publish\']?.toLowerCase() == \'true\';
  // Handle unlimited patch options dynamically
}
```

#### For Status PATCH
```dart
// ✅ Hybrid - Specific validation + enhanced context
@Patch(path: \'/orders/{id}/status\')
Future<Response> updateOrderStatus(
  @PathParam(\'id\') String id,
  @RequestBody(required: true) Map<String, dynamic> statusUpdate,
  @QueryParam(\'notify_customer\', defaultValue: true) bool notify,  // Type-safe
  @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,         // Direct
  @RequestMethod() String method,
) async {
  // Secure status update with complete audit trail
}
```

## 🔍 Differences with PUT

| Aspect | PUT | PATCH |
|---------|-----|--------|
| **Purpose** | Full update | Partial update |
| **Sent fields** | All mandatory | Only those to be changed |
| **Missing fields** | Are set to null/default | Are kept unchanged |
| **Validation** | All fields | Only sent fields |
| **Idempotency** | Always | Depends on implementation |
| **Typical use** | Replace resource | Modify specific fields |

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Successful update | `200` | OK - Fields updated |
| No fields to update | `400` | Bad Request - Empty body |
| Invalid fields | `400` | Bad Request - Unknown fields |
| Resource not found | `404` | Not Found - ID does not exist |
| Unauthorized | `401` | Unauthorized - Invalid JWT token |
| Forbidden | `403` | Forbidden - No modification permissions |
| Conflict | `409` | Conflict - Version conflict |
| Server error | `500` | Internal Server Error |

## 🌐 Resulting URLs

If your controller has `basePath: \'/api/v1\'` and you use `@Patch(path: \'/users/{id}\')`, the final URL will be:
```
PATCH http://localhost:8080/api/v1/users/{id}
```

## 📋 Request/Response Example

### Request - Update only the price
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

### Request - Update status only
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

**Next**: [Documentation for @Delete](delete-annotation.md) | **Previous**: [Documentation for @Put](put-annotation.md)
