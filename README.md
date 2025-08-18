# dart_secure_api

A comprehensive security framework for Dart/Shelf APIs with OWASP protection, rate limiting, and built-in security best practices.

## Features

- **🛡️ OWASP Security**: Built-in protection against common web vulnerabilities
- **⚡ Rate Limiting**: Configurable rate limiting with automatic IP banning
- **📝 Structured Logging**: Integration with logger_rs for comprehensive logging
- **🔄 Result Pattern**: Uses result_controller for robust error handling
- **🏗️ Controller Annotations**: Simple annotation-based routing (planned)
- **⚙️ Configurable Security**: Production and development security configurations

## Getting started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_secure_api: ^0.0.1
```

## Basic Usage

```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_secure_api/rest_api.dart';

void main() async {
  // Create your controllers
  final userController = UserController();
  
  // Setup main router
  final router = Router();
  router.mount('/api/v1/users', userController.router);
  
  // Create secure server
  final server = SecureServer(
    config: SecurityConfig.production(),
    router: router,
  );

  // Start the server
  final result = await server.start(host: 'localhost', port: 8080);
  
  result.when(
    success: (httpServer) => print('Server running on http://localhost:8080'),
    error: (error, stackTrace) => print('Failed to start: $error'),
  );
}

@Controller('/api/v1/users') // Base path for this controller
class UserController extends BaseController {
  // No need to override `router` - it's automatically built from annotations!

  @GET('/') // GET /api/v1/users/
  Future<Response> getUsers(Request request) async {
    logRequest(request, 'Getting users');
    
    final response = ApiResponse.success(['user1', 'user2']);
    return jsonResponse(response.toJson());
  }

  @GET('/<id>') // GET /api/v1/users/<id>
  Future<Response> getUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    final response = ApiResponse.success({'id': id, 'name': 'User $id'});
    return jsonResponse(response.toJson());
  }

  @POST('/') // POST /api/v1/users/
  Future<Response> createUser(Request request) async {
    final response = ApiResponse.success({'id': '1', 'name': 'New User'});
    return jsonResponse(response.toJson(), statusCode: 201);
  }

  @PUT('/<id>') // PUT /api/v1/users/<id>
  Future<Response> updateUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    final response = ApiResponse.success({'id': id, 'name': 'Updated User'});
    return jsonResponse(response.toJson());
  }

  @DELETE('/<id>') // DELETE /api/v1/users/<id>
  Future<Response> deleteUser(Request request) async {
    final response = ApiResponse.success(null, 'User deleted');
    return jsonResponse(response.toJson());
  }
}
```

## Automatic Annotation-Based Routing

One of the key features of `dart_secure_api` is automatic route generation using annotations, similar to Spring Boot, ASP.NET Core, or `simple_rest`:

### Available Annotations

- `@Controller('/base/path')` - Defines the base path for all routes in the controller
- `@GET('/path')` - Creates a GET endpoint
- `@POST('/path')` - Creates a POST endpoint  
- `@PUT('/path')` - Creates a PUT endpoint
- `@DELETE('/path')` - Creates a DELETE endpoint
- `@PATCH('/path')` - Creates a PATCH endpoint

### How It Works

```dart
@Controller('/api/v1/products')
class ProductController extends BaseController {
  @GET('/')                    // -> GET /api/v1/products/
  @GET('/<id>')               // -> GET /api/v1/products/<id>
  @POST('/')                  // -> POST /api/v1/products/
  @PUT('/<id>')               // -> PUT /api/v1/products/<id>
  @DELETE('/<id>')            // -> DELETE /api/v1/products/<id>
  @PATCH('/<id>/status')      // -> PATCH /api/v1/products/<id>/status

  Future<Response> methodName(Request request) async {
    // Your implementation
  }
}
```

The framework automatically:
1. Scans your controller for annotations using reflection
2. Builds the router with all annotated methods
3. Handles path parameters (like `<id>`)
4. Combines base path + method path for full routes

### Path Parameters

Access path parameters using the `getRequiredParam()` method:

```dart
@GET('/users/<userId>/posts/<postId>')
Future<Response> getUserPost(Request request) async {
  final userId = getRequiredParam(request, 'userId');
  final postId = getRequiredParam(request, 'postId');
  // Implementation
}
```

### Reflection Support

The framework automatically detects if reflection is available:

- **With Reflection** (Dart VM): Annotations work automatically via `dart:mirrors`
- **Without Reflection** (Flutter Web): Falls back to manual route registration

Example with fallback:

```dart
@Controller('/api/v1/products')
class ProductController extends BaseController {
  @override
  Router get router {
    // Check if reflection is available
    if (ReflectionHelper.isReflectionAvailable) {
      return super.router; // Automatic annotation-based routing
    }
    
    // Manual fallback when reflection is not available
    final router = Router();
    router.get('/', getProducts);
    router.post('/', createProduct);
    return router;
  }

  @GET('/')
  Future<Response> getProducts(Request request) async {
    // Implementation works in both cases
  }
}
```

## Security Features

### Automatic Security Headers
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security
- Content-Security-Policy

### Rate Limiting
```dart
final config = SecurityConfig(
  rateLimit: RateLimitConfig(
    maxRequests: 100,
    window: Duration(minutes: 1),
    maxRequestsPerIP: 1000,
  ),
  // ... other config
);
```

### Error Handling
All responses use the Result pattern with `result_controller`:

```dart
final result = await server.start(host: 'localhost', port: 8080);
result.when(
  success: (httpServer) => handleSuccess(httpServer),
  error: (error, stackTrace) => handleError(error, stackTrace),
);
```

## Configuration

### Production Configuration
```dart
final server = SecureServer(
  config: SecurityConfig.production(),
  router: router,
);
```

### Development Configuration
```dart
final server = SecureServer(
  config: SecurityConfig.development(), // More permissive for development
  router: router,
);
```

## Logging

Uses `logger_rs` for structured logging:

```dart
Log.i('Server started successfully');
Log.w('Rate limit warning');
Log.e('Error occurred', error: error, stackTrace: stackTrace);
```

## Roadmap

- [ ] Authentication middleware
- [ ] JWT token validation
- [ ] Database integration helpers
- [ ] WebSocket support
- [ ] Metrics and monitoring
- [ ] Docker deployment templates

## Contributing

This is an early-stage library (v0.0.1). Contributions, suggestions, and feedback are welcome!

## License

MIT License - see LICENSE file for details.
