# @Delete - Annotation for DELETE Endpoints

## 📋 Description

The `@Delete` annotation is used to mark methods as endpoints that respond to HTTP DELETE requests. It is the standard annotation for resource deletion operations.

## 🎯 Purpose

- **Delete resources**: Delete specific records or entities
- **Cleanup operations**: Remove temporary or obsolete data
- **Relationship management**: Remove connections between entities
- **Deactivation APIs**: Soft delete or state changes

## 📝 Syntax

```dart
@Delete({
  required String path,           // Endpoint path (REQUIRED)
  String? description,           // Endpoint description
  int statusCode = 204,          // Default response code (No Content)
  bool requiresAuth = true,      // Requires authentication by default
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `path` | `String` | ✅ Yes | - | Relative path of the endpoint (e.g., `/users/{id}`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Readable description of the endpoint's purpose |
| `statusCode` | `int` | ❌ No | `204` | HTTP status code for a successful response (No Content) |
| `requiresAuth` | `bool` | ❌ No | `true` | Indicates if the endpoint requires authentication |

> **Note**: DELETE requires authentication by default (`requiresAuth = true`) and returns 204 (No Content) as it is a destructive operation.

## 🚀 Usage Examples

### Basic Example

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
    
    // Verify that the user exists (in a real implementation)
    if (userId.isEmpty || !userId.startsWith('user_')) {
      return Response.notFound(jsonEncode({
        'error': 'User not found',
        'user_id': userId
      }));
    }
    
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];
    
    // Simulate deletion
    // In a real implementation: await userRepository.delete(userId);
    
    return Response(204); // No Content - successful deletion
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
    
    // Verify that the user exists (in a real implementation)
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
    
    // Simulate deletion and logging
    // In a real implementation: await userRepository.delete(userId);
    // await auditLogger.logDeletion(deletionLog);
    
    return Response(204); // No Content - successful deletion
  }
}
```

### Example with Confirmation and Log
```dart
@Delete(
  path: '/products/{productId}',
  description: 'Deletes a product from the catalog',
  statusCode: 200 // Return confirmation information
)
@JWTEndpoint([MyAdminValidator()])
Future<Response> deleteProduct(
  Request request,
  @PathParam('productId', description: 'Unique product ID') String productId,
  @QueryParam('force', defaultValue: false, description: 'Force deletion even if it has dependencies') bool force,
) async {
  
  // Validate ID format
  if (!productId.startsWith('prod_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid product ID format',
      'expected_format': 'prod_*',
      'received': productId
    }));
  }
  
  // Get JWT information
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final adminUser = jwtPayload['user_id'];
  
  // Check dependencies (simulate check)
  final hasDependencies = productId == 'prod_123'; // Simulate that this product has dependencies
  
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
  
  // Log the deletion
  final deletionRecord = {
    'product_id': productId,
    'deleted_by': adminUser,
    'deleted_at': DateTime.now().toIso8601String(),
    'forced': force,
    'had_dependencies': hasDependencies,
  };
  
  // Simulate deletion
  // In a real implementation: 
  // if (force && hasDependencies) await cleanupDependencies(productId);
  // await productRepository.delete(productId);
  
  return jsonResponse(jsonEncode({
    'message': 'Product deleted successfully',
    'deletion_info': deletionRecord,
    'warnings': hasDependencies && force ? ['Dependencies were forcefully removed'] : [],
  }));
}
```

### Soft Delete Example
```dart
@Delete(
  path: '/posts/{postId}',
  description: 'Deactivates a post (soft delete)',
  statusCode: 200
)
@JWTEndpoint([MyUserValidator()]) // Only the author can delete
Future<Response> deletePost(
  Request request,
  @PathParam('postId', description: 'Post ID') String postId,
  @QueryParam('permanent', defaultValue: false, description: 'Permanent deletion') bool permanent,
) async {
  
  // Get JWT information
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final currentUser = jwtPayload['user_id'];
  
  // In a real implementation, verify that the user is the author of the post
  final postAuthor = 'user_123'; // Simulate getting author from DB
  
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
    // Soft delete - keep data but mark as deleted
    deletionResult['status'] = 'deleted';
    deletionResult['recoverable_until'] = DateTime.now().add(Duration(days: 30)).toIso8601String();
    deletionResult['recovery_note'] = 'Post can be recovered within 30 days';
  } else {
    // Hard delete - permanently delete
    deletionResult['status'] = 'permanently_deleted';
    deletionResult['recovery_note'] = 'Post cannot be recovered';
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Post deleted successfully',
    'deletion': deletionResult,
  }));
}
```

### Batch Deletion Example
```dart
@Delete(
  path: '/users/{userId}/notifications',
  description: 'Deletes all user notifications'
)
@JWTEndpoint([MyUserValidator()])
Future<Response> deleteAllNotifications(
  Request request,
  @PathParam('userId', description: 'User ID') String userId,
  @QueryParam('older_than_days', required: false, description: 'Only delete notifications older than X days') int? olderThanDays,
  @QueryParam('type', required: false, description: 'Type of notifications to delete') String? notificationType,
) async {
  
  // Validate that the JWT corresponds to the user
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final tokenUserId = jwtPayload['user_id'];
  
  if (tokenUserId != userId) {
    return Response.forbidden(jsonEncode({
      'error': 'Can only delete your own notifications',
      'token_user_id': tokenUserId,
      'requested_user_id': userId
    }));
  }
  
  // Build filters for deletion
  final filters = <String, dynamic>{'user_id': userId};
  
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
  
  // Simulate count and deletion
  final simulatedCount = olderThanDays != null ? 15 : 45; // Simulate quantity
  final deletedCount = notificationType != null ? (simulatedCount * 0.3).round() : simulatedCount;
  
  final deletionResult = {
    'user_id': userId,
    'total_deleted': deletedCount,
    'filters_applied': filters,
    'deleted_at': DateTime.now().toIso8601String(),
  };
  
  // Add details by type if specified
  if (notificationType != null) {
    deletionResult['deleted_by_type'] = {notificationType: deletedCount};
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

### Example with Confirmation Headers
```dart
@Delete(
  path: '/files/{fileId}',
  description: 'Deletes a file from the system'
)
@JWTEndpoint([MyFileValidator()])
Future<Response> deleteFile(
  Request request,
  @PathParam('fileId', description: 'Unique file ID') String fileId,
  @RequestHeader('X-Confirm-Delete', required: true, description: 'Deletion confirmation (must be "yes")') String confirmHeader,
  @QueryParam('remove_thumbnails', defaultValue: true, description: 'Delete associated thumbnails') bool removeThumbnails,
) async {
  
  // Validate confirmation
  if (confirmHeader != 'yes') {
    return Response.badRequest(body: jsonEncode({
      'error': 'Deletion confirmation required',
      'required_header': 'X-Confirm-Delete: yes',
      'received_header': 'X-Confirm-Delete: $confirmHeader',
      'hint': 'This prevents accidental file deletion'
    }));
  }
  
  // Validate file ID format
  if (!fileId.startsWith('file_')) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid file ID format',
      'expected_format': 'file_*',
      'received': fileId
    }));
  }
  
  // Get JWT information
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final currentUser = jwtPayload['user_id'];
  
  // Simulate file information
  final fileInfo = {
    'id': fileId,
    'filename': 'document.pdf',
    'size_bytes': 1048576,
    'owner': currentUser,
    'has_thumbnails': fileId.contains('image'),
  };
  
  // Prepare deletion result
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

## 🔗 Combination with Other Annotations

### With Multiple Validators for Critical Operation
```dart
@Delete(path: '/financial/accounts/{accountId}', statusCode: 200)
@JWTController([
  MyFinancialValidator(clearanceLevel: 5), // Maximum level required
  MyBusinessHoursValidator(),
  MyTwoFactorValidator(), // Requires 2FA
], requireAll: true)
Future<Response> deleteFinancialAccount(
  Request request,
  @PathParam('accountId') String accountId,
  @RequestHeader('X-Two-Factor-Token', required: true) String tfaToken,
) async {
  
  // Extra validations for critical financial operations
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

## 💡 Best Practices

### ✅ Do
- **Validate existence**: Verify that the resource exists before deleting
- **Confirm permissions**: Ensure the user can delete the resource
- **Log the action**: Log who deleted what and when
- **Handle dependencies**: Check relationships before deleting
- **Consider soft delete**: For important resources that might need recovery
- **Prefer Enhanced Parameters**: For full access without the Request parameter
- **Combine approaches**: Traditional for validation, Enhanced for context

### ❌ Don't
- **Deletion without confirmation**: For critical resources, require explicit confirmation
- **Not validating permissions**: Always check authorization
- **Deleting without a log**: Keep a record of deletions
- **Ignoring dependencies**: Can create data inconsistencies
- **Hard delete by default**: Consider soft delete for recoverability
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Enhanced Recommendations by Scenario

#### For Simple DELETE with Auditing
```dart
// ✅ Enhanced - Complete auditing without Request parameter
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

#### For DELETE with Dynamic Options
```dart
// ✅ Enhanced - Flexible deletion options
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

#### For Critical DELETE with Enhanced Confirmation
```dart
// ✅ Hybrid - Specific validation + full context
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

#### For Soft DELETE with Recovery
```dart
// ✅ Enhanced - Soft delete with full context
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

## 🔍 Deletion Types

### 1. **Hard Delete (Physical Deletion)**
```dart
@Delete(path: '/temp-files/{fileId}')
Future<Response> deleteTemporaryFile(Request request, @PathParam('fileId') String fileId) async {
  // Completely deletes the file - cannot be recovered
  return Response(204); // No Content
}
```

### 2. **Soft Delete (Logical Deletion)**
```dart
@Delete(path: '/posts/{postId}', statusCode: 200)
Future<Response> deletePost(Request request, @PathParam('postId') String postId) async {
  // Marks as deleted but keeps the data
  return jsonResponse(jsonEncode({
    'message': 'Post deleted successfully',
    'recoverable_until': DateTime.now().add(Duration(days: 30)).toIso8601String()
  }));
}
```

### 3. **Deletion with Confirmation**
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
  // Proceed with deletion
  return Response(204);
}
```

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Elimination exitosa sin contenido | `204` | No Content - Resource deleted |
| Elimination exitosa con info | `200` | OK - With deletion details |
| Resource not found | `404` | Not Found - ID does not exist |
| Confirmation required | `400` | Bad Request - Missing confirmation |
| Unauthorized | `401` | Unauthorized - Invalid JWT token |
| Forbidden | `403` | Forbidden - No deletion permissions |
| Has dependencies | `409` | Conflict - Cannot be deleted |
| Server error | `500` | Internal Server Error |

## 🌐 URL Resultantes

If your controller has `basePath: '/api/v1'` and you use `@Delete(path: '/users/{id}')`, the final URL will be:
```
DELETE http://localhost:8080/api/v1/users/{id}
```

## 📋 Request/Response Example

### Request - Simple Deletion
```http
DELETE http://localhost:8080/api/users/user_123
Authorization: Bearer admin_token_456
```

### Response - No content (204)
```http
HTTP/1.1 204 No Content
```

### Request - Deletion with Confirmation
```http
DELETE http://localhost:8080/api/files/file_789?remove_thumbnails=true
Authorization: Bearer file_token_456
X-Confirm-Delete: yes
```

### Response - With information (200)
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

**Next**: [Documentation for @RestController](restcontroller-annotation.md) | **Previous**: [Documentation for @Patch](patch-annotation.md)
