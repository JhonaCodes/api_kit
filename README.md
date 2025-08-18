# api_kit

Simple, fast REST API framework with annotation-based routing. Perfect for MVPs and rapid prototyping.

## Features

- **🚀 Annotation-based routing**: Just add @GET, @POST, etc. and you're done
- **⚡ Fast setup**: Perfect for MVPs and rapid prototyping  
- **📦 Controller lists**: Register controllers like simple_rest
- **🔄 Result pattern**: Clean error handling with result_controller
- **📝 Built-in logging**: Structured logging with logger_rs
- **🛡️ Basic security**: Essential protection without complexity

## Getting started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  api_kit: ^0.0.1
```

## Basic Usage

```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:api_kit/api_kit.dart';

void main() async {
  // Create API server
  final server = ApiServer(config: ServerConfig.development());

  // Start with controller list - that's it!
  final result = await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [UserController()],
  );
  
  result.when(
    ok: (httpServer) => print('🚀 Server running on http://localhost:8080'),
    err: (error) => print('❌ Failed to start: ${error.msm}'),
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

## Annotation-Based Routing + Middleware

Perfect for MVPs! Automatic route generation with flexible middleware support:

### Available Annotations

**HTTP Methods:**
- `@GET('/path')`, `@POST('/path')`, `@PUT('/path')`, `@DELETE('/path')`, `@PATCH('/path')`

**Middleware & Security:**
- `@RequireAuth()` - Require JWT authentication
- `@RequireAuth(role: 'admin')` - Require specific role
- `@RateLimit(maxRequests: 10, window: Duration(minutes: 1))` - Endpoint-specific rate limiting
- `@UseMiddleware([myCustomMiddleware])` - Apply custom middleware
- `@SkipMiddleware(['cors', 'logging'])` - Skip specific middleware

### Example with Middleware

```dart
@Controller('/api/v1/products')
class ProductController extends BaseController {
  @GET('/')
  Future<Response> getPublicProducts(Request request) async {
    // Public endpoint - no auth needed
  }

  @GET('/admin')
  @RequireAuth(role: 'admin')
  Future<Response> getAdminProducts(Request request) async {
    // Only admins can access this
  }

  @POST('/')
  @RequireAuth()
  @RateLimit(maxRequests: 5, window: Duration(minutes: 1))
  Future<Response> createProduct(Request request) async {
    // Authenticated users, rate limited
  }

  @GET('/heavy-operation')
  @UseMiddleware([BuiltInMiddleware.apiKey(validKey: 'secret123')])
  Future<Response> heavyOperation(Request request) async {
    // Custom API key auth for this endpoint
  }
}
```

### Custom Middleware Setup

```dart
void main() async {
  // Register your custom middleware
  MiddlewareRegistry.register('jwt', BuiltInMiddleware.jwt(
    secret: 'your-secret-key',
    requiredRoles: ['user'],
  ));

  // Your controllers use @RequireAuth automatically!
  final server = ApiServer(config: ServerConfig.development());
  await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [ProductController()],
  );
}
```

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
final config = ServerConfig(
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
  ok: (httpServer) => handleSuccess(httpServer),
  err: (error) => handleError(error),
);
```

## Configuration

### Production Configuration
```dart
final server = ApiServer(
  config: ServerConfig.production(),
);
```

### Development Configuration
```dart
final server = ApiServer(
  config: ServerConfig.development(), // More permissive for development
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
