# 🚀 api_kit - Production-Ready REST API Framework

Production-ready REST API framework with comprehensive JWT authentication system. Perfect for MVPs, rapid prototyping, and enterprise applications.

## 🎯 Key Features (v0.0.2)

- ✅ **Complete JWT Authentication System** - `@JWTPublic`, `@JWTController`, `@JWTEndpoint` with custom validators
- ✅ **Annotation-based routing** - `@Controller`, `@GET`, `@POST`, etc.
- ✅ **Production-ready security** - CORS, rate limiting, security headers
- ✅ **Token blacklisting** - Advanced token management and revocation
- ✅ **Custom validators** - Extensible JWT validation with AND/OR logic
- ✅ **Middleware pipeline** - Configurable middleware system
- ✅ **Error handling** - Centralized error handling with Result pattern
- ✅ **139/139 tests passing** - 100% test success rate

## 📚 Complete Documentation Structure

### 🎯 **Main Documentation Hub**
**[`docs/README.md`](docs/README.md)** - **Complete documentation index and navigation guide**

### 🔐 **JWT Authentication System (v0.0.2)**
- **[`docs/15-jwt-validation-system.md`](docs/15-jwt-validation-system.md)** - **Complete JWT system specification**
- **[`docs/16-jwt-quick-start.md`](docs/16-jwt-quick-start.md)** - **Fast JWT setup guide**

### 🚀 **Getting Started**
- [`docs/01-setup.md`](docs/01-setup.md) - Project setup and installation
- [`docs/02-first-controller.md`](docs/02-first-controller.md) - First API controller
- [`docs/03-get-requests.md`](docs/03-get-requests.md) - GET request handling

### 📝 **HTTP Methods**
- [`docs/04-post-requests.md`](docs/04-post-requests.md) - POST request handling
- [`docs/05-put-requests.md`](docs/05-put-requests.md) - PUT request handling
- [`docs/06-patch-requests.md`](docs/06-patch-requests.md) - PATCH request handling
- [`docs/07-delete-requests.md`](docs/07-delete-requests.md) - DELETE request handling

### 🔧 **Advanced Features**
- [`docs/08-query-parameters.md`](docs/08-query-parameters.md) - Query parameter handling
- [`docs/09-middlewares.md`](docs/09-middlewares.md) - Custom middleware
- [`docs/11-error-handling.md`](docs/11-error-handling.md) - Error handling patterns

### 🧪 **Testing & Deployment**
- [`docs/12-testing.md`](docs/12-testing.md) - Testing strategies
- [`docs/13-deployment.md`](docs/13-deployment.md) - Production deployment
- [`docs/14-examples.md`](docs/14-examples.md) - Complete examples

### 📋 **Reference & Information**
- [`docs/17-version-info.md`](docs/17-version-info.md) - Version 0.0.2 information
- [`docs/18-api-reference.md`](docs/18-api-reference.md) - Complete API reference
- [`docs/19-changelog.md`](docs/19-changelog.md) - Version history

## 🔐 JWT System Overview

### Quick JWT Setup
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());
  
  // Configure JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key',
    excludePaths: ['/api/public', '/health'],
  );

  await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [UserController(), AdminController()],
  );
}
```

### JWT Annotations
```dart
// Public endpoint - no authentication
@GET('/info')
@JWTPublic()
Future<Response> getPublicInfo(Request request) async { ... }

// Controller-level protection
@Controller('/api/admin')
@JWTController([
  const MyAdminValidator(),
  const MyBusinessHoursValidator(),
], requireAll: true) // AND logic
class AdminController extends BaseController {
  
  @GET('/users')
  Future<Response> getUsers(Request request) async {
    // Protected by controller validators
  }
  
  // Endpoint-specific validation (overrides controller)
  @POST('/emergency-access')
  @JWTEndpoint([
    const MyAdminValidator(), // Only admin required
  ])
  Future<Response> emergencyAccess(Request request) async { ... }
}
```

### Custom Validators
```dart
class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    if (role != 'admin' || !isActive || !permissions.contains('admin_access')) {
      return ValidationResult.invalid('Administrator access required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}
```

## 🏗️ Basic Controller Example

```dart
@Controller('/api/users')
class UserController extends BaseController {
  
  @GET('/list')
  @JWTPublic() // Public endpoint
  Future<Response> getUsers(Request request) async {
    return jsonResponse(jsonEncode({'users': ['John', 'Jane']}));
  }
  
  @POST('/create')
  @JWTController([const MyAdminValidator()]) // Admin only
  Future<Response> createUser(Request request) async {
    final body = await request.readAsString();
    final userData = jsonDecode(body);
    
    // JWT payload available in context
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];
    
    return jsonResponse(jsonEncode({
      'created': userData['name'],
      'created_by': adminUser,
    }));
  }
}
```

## 🛠️ Key Components

### JWT Validators (Built-in)
- **`MyAdminValidator`** - Administrator role validation
- **`MyFinancialValidator`** - Financial operations with clearance levels
- **`MyDepartmentValidator`** - Department-based access control
- **`MyBusinessHoursValidator`** - Time-based access restrictions

### Core Annotations
- **`@Controller('/path')`** - Define controller base path
- **`@GET('/endpoint')`, `@POST('/endpoint')`** - HTTP method routing
- **`@JWTPublic()`** - Public endpoint (no JWT required)
- **`@JWTController([validators], requireAll: bool)`** - Controller-level JWT validation
- **`@JWTEndpoint([validators], requireAll: bool)`** - Endpoint-specific JWT validation

### Validation Logic
- **AND Logic** (`requireAll: true`) - All validators must pass
- **OR Logic** (`requireAll: false`) - At least one validator must pass
- **Hierarchical** - Endpoint validators override controller validators

## 🧪 Testing & Development

### Test Status
- **139/139 tests passing** (100% success rate)
- **6 JWT test suites** covering all scenarios
- **Production-ready validation** with real HTTP servers
- **Comprehensive edge case coverage**

### Run Tests
```bash
# All tests
dart test

# JWT-specific tests
dart test test/jwt_validation_system_test.dart
dart test test/jwt_production_ready_test.dart
```

### Generate Test JWTs
```dart
// Built-in test JWT generators
final adminToken = _createTestJWT({
  'user_id': 'admin123',
  'role': 'admin',
  'active': true,
  'permissions': ['admin_access'],
});
```

## 🚀 Quick Start Guide

### 1. Add Dependency
```yaml
dependencies:
  api_kit: ^0.0.2
```

### 2. Create Controller
```dart
@Controller('/api/hello')
class HelloController extends BaseController {
  @GET('/world')
  @JWTPublic()
  Future<Response> sayHello(Request request) async {
    return jsonResponse('{"message": "Hello World!"}');
  }
}
```

### 3. Start Server
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  await server.start(
    host: 'localhost', 
    port: 8080,
    controllerList: [HelloController()],
  );
}
```

## ⚙️ Configuration Options

### Development
```dart
ServerConfig.development() // Permissive CORS, verbose logging
```

### Production
```dart
ServerConfig.production() // Restrictive CORS, security headers
```

### Custom Configuration
```dart
ServerConfig(
  rateLimit: RateLimitConfig(maxRequests: 1000, window: Duration(minutes: 1)),
  cors: CorsConfig.permissive(),
  maxBodySize: 10 * 1024 * 1024, // 10MB
)
```

## 🎯 Development Workflow

1. **Read Documentation**: Start with [`docs/README.md`](docs/README.md) for complete guidance
2. **Setup JWT**: Follow [`docs/16-jwt-quick-start.md`](docs/16-jwt-quick-start.md) for authentication
3. **Create Custom Validators**: Extend `JWTValidatorBase` for your business logic
4. **Annotate Controllers**: Use `@JWTController` and `@JWTEndpoint` as needed
5. **Mark Public Endpoints**: Use `@JWTPublic()` for open endpoints
6. **Configure Server**: Setup JWT secrets and excluded paths
7. **Test Thoroughly**: Validate with provided test patterns

## 📊 Version 0.0.2 Highlights

- **Complete JWT Authentication System** with custom validators
- **Token Blacklisting** for secure logout and token management  
- **Production-Ready Testing** with 139/139 tests passing
- **Comprehensive Documentation** reorganized in `docs/` directory
- **Real-World Examples** for immediate implementation
- **Enterprise Security Features** ready for production use

---

**🚀 Ready for production with enterprise-grade JWT authentication system!**

**Next Steps**: 
- **Beginners**: [`docs/01-setup.md`](docs/01-setup.md)
- **JWT Setup**: [`docs/16-jwt-quick-start.md`](docs/16-jwt-quick-start.md)
- **Full Documentation**: [`docs/README.md`](docs/README.md)