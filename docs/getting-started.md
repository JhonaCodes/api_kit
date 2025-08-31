# 🚀 Getting Started with api_kit

Welcome to **api_kit** - the production-ready REST API framework with Enhanced Parameters! This guide will get you up and running in minutes.

## 📋 Prerequisites

- **Dart SDK**: 3.0.0 or higher
- **Basic Dart knowledge**: Understanding of futures, async/await, and classes

## 🎯 What You'll Build

In this guide, you'll create a complete user management API with:
- ✅ User listing and creation endpoints
- ✅ JWT authentication and validation
- ✅ Enhanced Parameters (no more `Request request`!)
- ✅ Production-ready security

## Step 1: Project Setup

### Create New Dart Project
```bash
dart create my_api_project
cd my_api_project
```

### Add api_kit Dependency
Edit your `pubspec.yaml`:

```yaml
name: my_api_project
description: My first api_kit API
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  api_kit: ^0.0.4  # 🆕 Enhanced Parameters support!
  shelf: ^1.4.1
```

### Install Dependencies
```bash
dart pub get
```

## Step 2: Create Your First Controller

Create `lib/controllers/user_controller.dart`:

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:api_kit/api_kit.dart';

@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  // 📋 Get all users - Public endpoint
  @Get(path: '/list')
  @JWTPublic() // No authentication required
  Future<Response> getUsers(
    @QueryParam('limit') String? limit, // Enhanced: Direct parameter injection
    @QueryParam('offset') String? offset,
    @QueryParam.all() Map<String, String> allParams, // Enhanced: Get all params
  ) async {
    final limitNum = int.tryParse(limit ?? '10') ?? 10;
    final offsetNum = int.tryParse(offset ?? '0') ?? 0;
    
    // Validate parameters
    if (limitNum <= 0 || offsetNum < 0) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_PARAMETERS',
        message: 'Limit must be positive and offset cannot be negative',
        details: {
          if (limitNum <= 0) 'limit': 'Must be greater than 0',
          if (offsetNum < 0) 'offset': 'Cannot be negative',
        },
      )).toHttpResponse();
    }
    
    // Simulate database query
    final users = [
      {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
      {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'},
      {'id': 3, 'name': 'Bob Wilson', 'email': 'bob@example.com'},
    ];
    
    final paginatedUsers = users.skip(offsetNum).take(limitNum).toList();
    
    return ApiKit.ok({
      'users': paginatedUsers,
      'total': users.length,
      'limit': limitNum,
      'offset': offsetNum,
      'filters_applied': allParams,
    }).toHttpResponse();
  }
  
  // 👤 Get specific user by ID
  @Get(path: '/{id}')
  @JWTPublic() // Public for demo
  Future<Response> getUser(
    @PathParam('id') String userId, // Enhanced: Direct path parameter injection
    @RequestHeader.all() Map<String, String> headers, // Enhanced: All headers
  ) async {
    final userIdNum = int.tryParse(userId);
    
    if (userIdNum == null) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_USER_ID',
        message: 'User ID must be a valid number',
        details: {'id': 'Must be a valid integer'},
      )).toHttpResponse();
    }
    
    // Simulate user lookup
    final user = {
      'id': userIdNum,
      'name': 'User $userIdNum',
      'email': 'user$userIdNum@example.com',
      'request_info': {
        'user_agent': headers['user-agent'] ?? 'Unknown',
        'accept': headers['accept'] ?? 'Unknown',
      }
    };
    
    return ApiKit.ok(user).toHttpResponse();
  }
  
  // ➕ Create new user - Requires JWT
  @Post(path: '/create')
  @JWTEndpoint([
    const MyAdminValidator(), // Custom validator - we'll create this next
  ])
  Future<Response> createUser(
    @RequestBody() Map<String, dynamic> userData, // Enhanced: Direct body injection
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Enhanced: Direct JWT access
    @RequestHeader('content-type') String? contentType,
  ) async {
    // Validate required fields
    if (userData['name'] == null || userData['email'] == null) {
      return ApiKit.err(ApiErr(
        code: 'VALIDATION_ERROR',
        message: 'Name and email are required fields',
        details: {
          if (userData['name'] == null) 'name': 'Name is required',
          if (userData['email'] == null) 'email': 'Email is required',
        },
      )).toHttpResponse();
    }
    
    // Validate email format (basic validation)
    final email = userData['email'] as String;
    if (!email.contains('@')) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_EMAIL',
        message: 'Invalid email format',
        details: {'email': 'Must be a valid email address'},
      )).toHttpResponse();
    }
    
    // Get admin info from JWT
    final adminUserId = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];
    
    // Simulate user creation
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': userData['name'],
      'email': userData['email'],
      'created_by': adminUserId,
      'created_at': DateTime.now().toIso8601String(),
      'admin_info': {
        'created_by_user': adminUserId,
        'admin_role': adminRole,
      }
    };
    
    return ApiKit.ok(newUser).toHttpResponse();
  }
}
```

## Step 3: Create JWT Validator

Create `lib/validators/admin_validator.dart`:

```dart
import 'package:shelf/shelf.dart';
import 'package:api_kit/api_kit.dart';

class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // Check if user has admin role
    final role = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    // Validate admin role
    if (role != 'admin') {
      return ValidationResult.invalid('Administrator role required');
    }
    
    // Validate active status
    if (!isActive) {
      return ValidationResult.invalid('Account is inactive');
    }
    
    // Validate admin permissions
    if (!permissions.contains('admin_access')) {
      return ValidationResult.invalid('Missing admin access permission');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}
```

## Step 4: Create Your Server

Create `bin/server.dart`:

```dart
import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:my_api_project/controllers/user_controller.dart';
import 'package:my_api_project/validators/admin_validator.dart';

void main() async {
  print('🚀 Starting api_kit server with Enhanced Parameters...');
  
  // Create server with production configuration
  final server = ApiServer(config: ServerConfig.development()); // Use development for easy testing
  
  // Configure JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-super-secret-256-bit-jwt-key-change-in-production!',
    excludePaths: ['/api/users/list', '/api/users/'], // Public endpoints
  );
  
  // Start server with auto-discovery
  await server.start(
    host: 'localhost',
    port: 8080,
  );
  
  print('✅ Server running successfully!');
  print('🌐 API available at: http://localhost:8080');
  print('📋 Available endpoints:');
  print('  • GET  http://localhost:8080/api/users/list');
  print('  • GET  http://localhost:8080/api/users/{id}');
  print('  • POST http://localhost:8080/api/users/create (JWT Required)');
  print('');
  print('🔐 To test JWT endpoints, create a token with:');
  print('  {');
  print('    "user_id": "admin123",');
  print('    "role": "admin",');
  print('    "active": true,');
  print('    "permissions": ["admin_access"]');
  print('  }');
}
```

## Step 5: Update Project Imports

Create `lib/my_api_project.dart`:

```dart
// Export your controllers and validators
export 'controllers/user_controller.dart';
export 'validators/admin_validator.dart';
```

Make sure to import this in your `bin/server.dart`:

```dart
import 'package:my_api_project/my_api_project.dart';
```

## Step 6: Run Your API!

```bash
dart run bin/server.dart
```

You should see:
```
🚀 Starting api_kit server with Enhanced Parameters...
✅ Server running successfully!
🌐 API available at: http://localhost:8080
📋 Available endpoints:
  • GET  http://localhost:8080/api/users/list
  • GET  http://localhost:8080/api/users/{id}
  • POST http://localhost:8080/api/users/create (JWT Required)
```

## Step 7: Test Your API

### Test Public Endpoints

```bash
# Get all users
curl http://localhost:8080/api/users/list

# Get all users with pagination
curl "http://localhost:8080/api/users/list?limit=2&offset=1&filter=active"

# Get specific user
curl http://localhost:8080/api/users/123
```

### Test JWT Protected Endpoint

First, create a JWT token at https://jwt.io/ with the secret `your-super-secret-256-bit-jwt-key-change-in-production!` and payload:

```json
{
  "user_id": "admin123",
  "role": "admin",
  "active": true,
  "permissions": ["admin_access"]
}
```

Then test the protected endpoint:

```bash
# Create user (JWT required)
curl -X POST http://localhost:8080/api/users/create \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"name": "New User", "email": "newuser@example.com"}'
```

## 🎉 Congratulations!

You've successfully created your first api_kit API with Enhanced Parameters! Notice how clean your code is:

### ✅ What You Achieved:
- **Zero boilerplate**: No more `Request request` parameter extractions
- **Direct injection**: Path params, query params, headers, and JWT payload injected directly
- **Type safety**: Strong typing for all parameters
- **JWT security**: Production-ready authentication with custom validators
- **Clean code**: Declarative parameter handling

### 🔄 Traditional vs Enhanced Comparison

#### ❌ Old way (before Enhanced Parameters):
```dart
@Get(path: '/users/{id}')
Future<Response> getUser(Request request) async {
  final id = request.params['id']; // Manual extraction
  final limit = request.url.queryParameters['limit']; // Manual extraction
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>; // Manual extraction
  final userAgent = request.headers['user-agent']; // Manual extraction
  // ... more boilerplate
  
  return jsonResponse(jsonEncode({'success': true, 'data': {}})); // Manual JSON encoding
}
```

#### ✅ Enhanced way (with Enhanced Parameters):
```dart
@Get(path: '/users/{id}')
Future<Response> getUser(
  @PathParam('id') String id, // Direct injection
  @QueryParam('limit') String? limit, // Direct injection
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct injection
  @RequestHeader('user-agent') String? userAgent, // Direct injection
) async {
  // Everything is already extracted - pure business logic!
  return ApiKit.ok({'success': true, 'data': {}}).toHttpResponse(); // Clean response
}
```

## 📚 Next Steps

### 🔍 Learn More:
- **[Complete Documentation](../README.md)** - Full api_kit reference
- **[JWT System Deep Dive](annotations/jwt-annotations.md)** - Advanced JWT validation
- **[Enhanced Parameters Guide](annotations/queryparam-annotation.md)** - Master parameter injection
- **[Production Deployment](use-cases/complete-crud-api-enhanced.md)** - Scale your API

### 🚀 Extend Your API:
1. **Add more HTTP methods**: Implement PUT, PATCH, DELETE endpoints
2. **Create custom validators**: Add business-specific JWT validation
3. **Add middleware**: Implement logging, rate limiting, CORS
4. **Database integration**: Connect to PostgreSQL, MySQL, or MongoDB
5. **Add tests**: Write unit and integration tests for your endpoints

### 💡 Pro Tips:

#### Use .all() for Dynamic Parameters
```dart
@Get(path: '/search')
Future<Response> search(
  @QueryParam.all() Map<String, String> filters, // Get ALL query params
  @RequestHeader.all() Map<String, String> headers, // Get ALL headers
) async {
  // Perfect for dynamic filtering and content negotiation
  final results = await performSearch(filters);
  return ApiKit.ok({'success': true, 'data': results}).toHttpResponse();
}
```

#### Combine Specific and Bulk Parameters
```dart
@Post(path: '/data')
Future<Response> processData(
  @RequestBody() Map<String, dynamic> body, // Main data
  @QueryParam('version') String? version, // Specific param
  @QueryParam.all() Map<String, String> allParams, // All params for extras
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // JWT data
) async {
  // Best of both worlds!
  final processedData = await processBusinessLogic(body, version, allParams, jwtPayload);
  return ApiKit.ok({'success': true, 'data': processedData}).toHttpResponse();
}
```

## 🎯 Ready for Production?

Your api_kit application is production-ready! Check out:
- **[Security Configuration](../README.md#security-features)** - HTTPS, CORS, rate limiting
- **[Docker Deployment](../README.md#production-deployment)** - Container deployment
- **[Monitoring & Logging](../README.md#logging)** - Structured logging with logger_rs

---

**Happy coding with api_kit and Enhanced Parameters! 🚀**

*Need help? Check the [complete documentation](../README.md) or create an issue on GitHub.*