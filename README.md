# api_kit

Production-ready REST API framework with annotation-based routing and comprehensive JWT validation system. Perfect for MVPs, rapid prototyping, and enterprise applications.

## Features

- **✨ Enhanced Parameters (NEW!)**: No more `Request request` - direct parameter injection
- **🚀 Annotation-based routing**: Just add @Get, @Post, etc. and you're done
- **🔐 JWT Authentication System**: Complete JWT validation with custom validators
- **⚡ Fast setup**: Perfect for MVPs and rapid prototyping  
- **🔄 Result pattern**: Clean error handling with result_controller
- **📝 Built-in logging**: Structured logging with logger_rs
- **🛡️ Production security**: Enterprise-grade security features
- **🎯 Flexible validation**: Custom validators with AND/OR logic
- **⚖️ Token blacklisting**: Advanced token management system
- **📋 Complete parameter injection**: @QueryParam.all(), @RequestHeader.all(), @RequestContext()
- **🎪 Zero boilerplate**: Direct access to JWT payload, headers, query params, and body

## 📚 Quick Navigation

### 🚀 Getting Started
- [**Getting Started Guide**](docs/getting-started.md) - Zero to production API in 10 minutes!
- [**Enhanced Parameters**](docs/annotations/enhanced-parameters-annotation.md) - Learn the new parameter injection system

### 🔐 JWT Authentication  
- [**JWT Annotations**](docs/annotations/jwt-annotations.md) - @JWTPublic, @JWTController, @JWTEndpoint
- [**JWT Validation System**](docs/jwt-validation-system.md) - Custom validators and business logic

### 📋 HTTP Methods
- [**@Get**](docs/annotations/get-annotation.md) • [**@Post**](docs/annotations/post-annotation.md) • [**@Put**](docs/annotations/put-annotation.md) • [**@Delete**](docs/annotations/delete-annotation.md) • [**@Patch**](docs/annotations/patch-annotation.md)

### 🎯 Use Cases
- [**Complete CRUD API**](docs/use-cases/complete-crud-api.md) - Full production-ready example
- [**All Documentation**](docs/README.md) - Complete documentation hub

---

## Getting started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  api_kit: ^0.1.0
```

📚 **Need detailed setup help?** → [**Complete Getting Started Guide**](docs/getting-started.md)

## Quick Start

```dart
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  // Create API server with JWT configuration
  final server = ApiServer(config: ServerConfig.production());
  
  // Configure JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key-here',
    excludePaths: ['/api/public', '/health'],
  );

  // Start server with auto-discovery
  await server.start(
    host: 'localhost',
    port: 8080,
  );
  
  print('🚀 Server running on http://localhost:8080');
}
```

## Enhanced Parameters Controller (NEW!)

> 📖 **Want to learn all Enhanced Parameters?** → [**Enhanced Parameters Documentation**](docs/annotations/enhanced-parameters-annotation.md)

```dart
@RestController(basePath: '/api/v1/users')
class UserController extends BaseController {

  @Get(path: '/') // GET /api/v1/users/
  Future<Response> getUsers(
    @QueryParam.all() Map<String, String> allParams,
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    // Direct access to all query parameters and headers
    final limit = int.tryParse(allParams['limit'] ?? '10') ?? 10;
    final contentType = headers['content-type'];
    
    // Validate parameters
    if (limit <= 0) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_LIMIT',
        message: 'Limit must be greater than 0',
        details: {'limit': 'Must be a positive number'},
      )).toHttpResponse();
    }
    
    // Business logic - simulate data fetching
    final users = ['user1', 'user2'];
    
    return ApiKit.ok({
      'users': users,
      'total': users.length,
      'limit': limit,
      'content_type': contentType,
      'filters_applied': allParams,
    }).toHttpResponse();
  }

  @Get(path: '/{id}') // GET /api/v1/users/{id}
  Future<Response> getUser(
    @PathParam('id') String userId,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT access
  ) async {
    // No more manual extraction - everything is injected directly!
    final requestingUser = jwtPayload['user_id'];
    
    // Validate user ID
    if (userId.isEmpty) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_USER_ID',
        message: 'User ID cannot be empty',
        details: {'userId': 'User ID is required'},
      )).toHttpResponse();
    }
    
    // Business logic - simulate user fetch
    return ApiKit.ok({
      'id': userId, 
      'name': 'User $userId',
      'requested_by': requestingUser,
      'profile_url': '/api/users/$userId/profile',
    }).toHttpResponse();
  }
}
```

## 🆕 Enhanced Parameters System

> 📋 **See all Enhanced Parameters annotations:** [`@QueryParam.all()`](docs/annotations/queryparam-annotation.md) • [`@RequestHeader.all()`](docs/annotations/requestheader-annotation.md) • [`@RequestBody()`](docs/annotations/requestbody-annotation.md) • [`@PathParam()`](docs/annotations/pathparam-annotation.md)

### Traditional vs Enhanced Approach

#### ❌ Traditional (Old Way)
```dart
@Get(path: '/users')
Future<Response> getUsers(Request request) async {
  // Manual extraction required + try-catch boilerplate
  try {
    final limit = request.url.queryParameters['limit'];
    final offset = request.url.queryParameters['offset'];
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final userAgent = request.headers['user-agent'];
    
    return jsonResponse(jsonEncode({
      'success': true,
      'data': {'users': [], 'total': 100}
    }));
  } catch (e, stack) {
    return jsonResponse(jsonEncode({
      'success': false,
      'error': {'message': e.toString()}
    }), statusCode: 500);
  }
}
```

#### ✅ Enhanced (New Way) - CENTRALIZED PATTERN
```dart
@Get(path: '/users')
Future<Response> getUsers(
  @QueryParam('limit') String? limit,
  @QueryParam('offset') String? offset,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT access
  @RequestHeader('user-agent') String? userAgent,
) async {
  // Everything is injected automatically - zero boilerplate!
  final limitNum = int.tryParse(limit ?? '10') ?? 10;
  final offsetNum = int.tryParse(offset ?? '0') ?? 0;
  
  return ApiKit.ok({
    'users': [], 
    'total': 100, 
    'pagination': {'limit': limitNum, 'offset': offsetNum},
    'user_info': jwtPayload['user_id']
  }).toHttpResponse();
}
```

### Bulk Parameter Access

```dart
@Get(path: '/search')
Future<Response> searchUsers(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
) async {
  // Access ALL parameters at once - Enhanced Parameters power!
  final filters = allQueryParams; // {'name': 'john', 'age': '25', 'city': 'NYC'}
  final headers = allHeaders;     // {'user-agent': '...', 'accept': '...'}
  final user = jwtPayload['user_id']; // Direct JWT payload access
  
  // Validation
  if (filters.isEmpty) {
    return ApiKit.err(ApiErr(
      code: 'NO_SEARCH_CRITERIA',
      message: 'At least one search parameter is required',
      details: {'query': 'Search parameters cannot be empty'},
    )).toHttpResponse();
  }
  
  // Business logic - simulate search
  final results = await filterUsers(filters);
  
  return ApiKit.ok({
    'results': results,
    'user_agent': headers['user-agent'],
    'requested_by': user,
    'filters_applied': filters,
    'search_metadata': {
      'total_filters': filters.length,
      'search_time': DateTime.now().toIso8601String(),
    }
  }).toHttpResponse();
}
```

### POST with Enhanced Parameters

```dart
@Post(path: '/users')
Future<Response> createUser(
  @RequestBody() Map<String, dynamic> userData, // Direct body injection
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // JWT context
  @RequestHeader('content-type') String? contentType,
  @QueryParam.all() Map<String, String> queryParams,
) async {
  final createdBy = jwtPayload['user_id'];
  final version = queryParams['version'] ?? 'v1';
  
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
  
  // Additional validation
  final email = userData['email'] as String;
  if (!email.contains('@')) {
    return ApiKit.err(ApiErr(
      code: 'INVALID_EMAIL',
      message: 'Invalid email format provided',
      details: {'email': 'Must be a valid email address'},
    )).toHttpResponse();
  }
  
  // Business logic - create user
  final newUser = await createUserLogic(userData, createdBy, version);
  
  return ApiKit.ok({
    'user': newUser,
    'created_by': createdBy,
    'api_version': version,
    'creation_metadata': {
      'created_at': DateTime.now().toIso8601String(),
      'content_type': contentType,
    }
  }).toHttpResponse();
}
```

## JWT Authentication System

> 🔐 **Complete JWT Documentation:** [**JWT Annotations Guide**](docs/annotations/jwt-annotations.md) • [**JWT Validation System**](docs/jwt-validation-system.md)

### JWT Annotations

api_kit provides three powerful JWT annotations for complete access control:

#### **@JWTPublic** - Public Endpoints
```dart
@RestController(basePath: '/api/public')
class PublicController extends BaseController {
  @Get(path: '/info')
  @JWTPublic() // ✅ No JWT required - always accessible
  Future<Response> getPublicInfo() async {
    return ApiKit.ok({'message': 'Public data', 'version': '1.0'}).toHttpResponse();
  }
}
```

#### **@JWTController** - Controller-Level Protection
```dart
@RestController(basePath: '/api/admin')
@JWTController([
  const MyAdminValidator(),
  const MyBusinessHoursValidator(),
], requireAll: true) // 🔒 ALL validators must pass (AND logic)
class AdminController extends BaseController {
  
  @Get(path: '/users')
  Future<Response> getUsers(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Enhanced: Direct JWT injection
    @QueryParam.all() Map<String, String> filters,
  ) async {
    // Protected by controller-level validation - no manual extraction needed!
    final users = await fetchUsers(filters); // Simulate data fetching
    
    return ApiKit.ok({
      'users': users, 
      'admin': jwtPayload['name'],
      'admin_permissions': jwtPayload['permissions'],
      'filters_applied': filters
    }).toHttpResponse();
  }
}
```

#### **@JWTEndpoint** - Endpoint-Level Override
```dart
@RestController(basePath: '/api/finance')
@JWTController([
  const MyDepartmentValidator(allowedDepartments: ['finance']),
])
class FinanceController extends BaseController {
  
  @Get(path: '/reports')
  Future<Response> getReports(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  ) async {
    // Uses controller validation (department = finance)
    return ApiKit.ok({'reports': []}).toHttpResponse();
  }
  
  @Post(path: '/transactions')
  @JWTEndpoint([
    const MyFinancialValidator(minimumAmount: 10000),
    const MyAdminValidator(),
  ], requireAll: false) // 🔀 Either validator can pass (OR logic)
  Future<Response> createTransaction(
    @RequestBody() Map<String, dynamic> transactionData, // Enhanced: Direct body
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Enhanced: Direct JWT
  ) async {
    // Override: Either financial validator OR admin validator
    final amount = transactionData['amount'] as double?;
    final createdBy = jwtPayload['user_id'];
    
    // Validate amount
    if (amount == null || amount <= 0) {
      return ApiKit.err(ApiErr(
        code: 'INVALID_TRANSACTION',
        message: 'Transaction amount must be greater than 0',
        details: {'amount': 'Amount is required and must be positive'},
      )).toHttpResponse();
    }
    
    // Create transaction
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    
    return ApiKit.ok({
      'transaction_id': transactionId,
      'amount': amount,
      'created_by': createdBy,
      'user_role': jwtPayload['role'],
      'transaction_metadata': {
        'created_at': DateTime.now().toIso8601String(),
        'validation_passed': 'financial_or_admin',
      }
    }).toHttpResponse();
  }
}
```

### Custom JWT Validators

> 📖 **Learn to create advanced validators:** [**JWT Validation System Documentation**](docs/jwt-validation-system.md)

Create your own validators by extending `JWTValidatorBase`:

#### Basic Admin Validator
```dart
class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    if (role != 'admin') {
      return ValidationResult.invalid('Administrator role required');
    }
    
    if (!isActive) {
      return ValidationResult.invalid('Account is inactive');
    }
    
    if (!permissions.contains('admin_access')) {
      return ValidationResult.invalid('Missing admin access permission');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}
```

#### Advanced Financial Validator
```dart
class MyFinancialValidator extends JWTValidatorBase {
  final double minimumAmount;
  
  const MyFinancialValidator({this.minimumAmount = 0.0});
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final department = jwtPayload['department'] as String?;
    final clearanceLevel = jwtPayload['clearance_level'] as int? ?? 0;
    final certifications = jwtPayload['certifications'] as List<dynamic>? ?? [];
    final maxTransactionAmount = jwtPayload['max_transaction_amount'] as double? ?? 0.0;
    
    // Validate department
    if (department != 'finance' && department != 'accounting') {
      return ValidationResult.invalid('Access restricted to financial departments');
    }
    
    // Validate clearance level
    if (clearanceLevel < 3) {
      return ValidationResult.invalid('Insufficient clearance level for financial operations');
    }
    
    // Validate certifications
    if (!certifications.contains('financial_ops_certified')) {
      return ValidationResult.invalid('Financial operations certification required');
    }
    
    // Validate transaction amount limits
    if (minimumAmount > 0 && maxTransactionAmount < minimumAmount) {
      return ValidationResult.invalid('Transaction amount exceeds user authorization limit');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Financial operations access required';
}
```

### JWT Configuration Options

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());
  
  // Configure JWT with all options
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key-for-production',
    excludePaths: ['/api/public', '/health', '/docs'],
  );
  
  // Token blacklist management
  server.blacklistToken('jwt-token-to-invalidate');
  server.clearTokenBlacklist();
  print('Blacklisted tokens: ${server.blacklistedTokensCount}');
  
  // Dynamic configuration changes
  server.disableJWTAuth(); // Temporarily disable
  server.configureJWTAuth(jwtSecret: 'new-secret'); // Re-enable with new config
}
```

### JWT Payload Access with Enhanced Parameters

Access JWT data directly with Enhanced Parameters:

```dart
@Get(path: '/profile')
Future<Response> getProfile(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Enhanced: Direct injection
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
) async {
  // Direct access - no manual extraction needed!
  final userId = jwtPayload['user_id'];
  final userEmail = jwtPayload['email'];
  final userRole = jwtPayload['role'];
  
  // Validate required JWT fields
  if (userId == null || userEmail == null) {
    return ApiKit.err(ApiErr(
      code: 'INVALID_JWT_PAYLOAD',
      message: 'Missing required user information in token',
      details: {
        if (userId == null) 'user_id': 'User ID is required in JWT',
        if (userEmail == null) 'email': 'Email is required in JWT',
      },
    )).toHttpResponse();
  }
  
  return ApiKit.ok({
    'user_id': userId,
    'email': userEmail,
    'name': jwtPayload['name'],
    'role': userRole,
    'custom_data': jwtPayload['custom_field'],
    'request_info': {
      'user_agent': headers['user-agent'],
      'include_permissions': params['include_permissions'] == 'true',
    }
    // All JWT claims and request data available directly
  }).toHttpResponse();
}
```

## Validation Logic

### AND Logic (requireAll: true)
```dart
@JWTController([
  const MyAdminValidator(),
  const MyBusinessHoursValidator(),
], requireAll: true) // ✅ BOTH validators must pass
```

### OR Logic (requireAll: false)
```dart
@JWTController([
  const MyAdminValidator(),
  const MyDepartmentValidator(allowedDepartments: ['support']),
], requireAll: false) // ✅ EITHER validator can pass
```

## Built-in Validators

api_kit includes production-ready validators:

### MyAdminValidator
- Validates `role: 'admin'`
- Checks `active: true`
- Requires `permissions: ['admin_access']`

### MyFinancialValidator
- Department validation (finance/accounting)
- Clearance level requirements
- Certification validation
- Transaction amount limits

### MyDepartmentValidator
- Configurable allowed departments
- Optional management level requirements
- Employee level validation

### MyBusinessHoursValidator
- Working hours validation (configurable)
- Business days only
- After-hours access override

## Error Responses

Consistent error handling with detailed information:

### 401 Unauthorized (No/Invalid JWT)
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "JWT token required",
    "details": {}
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### 403 Forbidden (JWT Valid, Authorization Failed)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Administrator access required",
    "details": {
      "validation_mode": "require_all",
      "validators_count": 2,
      "failed_validations": ["Administrator role required"]
    }
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Available Annotations

### HTTP Methods
- [`@Get(path: '/path')`](docs/annotations/get-annotation.md) - GET request handling
- [`@Post(path: '/path')`](docs/annotations/post-annotation.md) - POST request handling  
- [`@Put(path: '/path')`](docs/annotations/put-annotation.md) - PUT request handling
- [`@Delete(path: '/path')`](docs/annotations/delete-annotation.md) - DELETE request handling
- [`@Patch(path: '/path')`](docs/annotations/patch-annotation.md) - PATCH request handling

### JWT Authentication
- [`@JWTPublic()`](docs/annotations/jwt-annotations.md#jwtpublic---public-endpoint) - Public endpoint (no JWT required)
- [`@JWTController([validators], requireAll: bool)`](docs/annotations/jwt-annotations.md#jwtcontroller---controller-level-validation) - Controller-level protection
- [`@JWTEndpoint([validators], requireAll: bool)`](docs/annotations/jwt-annotations.md#jwtendpoint---endpoint-specific-validation) - Endpoint-level protection

### Controllers
- [`@RestController(basePath: '/base/path')`](docs/annotations/restcontroller-annotation.md) - Define base path for controller

### 🆕 Enhanced Parameter Annotations
- [`@PathParam('name')`](docs/annotations/pathparam-annotation.md) - Extract specific path parameter
- [`@QueryParam('name')`](docs/annotations/queryparam-annotation.md) - Extract specific query parameter
- [`@QueryParam.all()`](docs/annotations/queryparam-annotation.md) - Get all query parameters as Map<String, String>
- [`@RequestHeader('name')`](docs/annotations/requestheader-annotation.md) - Extract specific header
- [`@RequestHeader.all()`](docs/annotations/requestheader-annotation.md) - Get all headers as Map<String, String>
- [`@RequestBody()`](docs/annotations/requestbody-annotation.md) - Direct body injection as Map<String, dynamic>
- [`@RequestContext('jwt_payload')`](docs/annotations/enhanced-parameters-annotation.md#request-context) - Direct JWT payload access
- [`@RequestContext.all()`](docs/annotations/enhanced-parameters-annotation.md#request-context) - Get all context as Map<String, dynamic>
- [`@RequestMethod()`](docs/annotations/enhanced-parameters-annotation.md#request-components) - Get HTTP method (GET, POST, etc.)
- [`@RequestPath()`](docs/annotations/enhanced-parameters-annotation.md#request-components) - Get full request path
- [`@RequestHost()`](docs/annotations/enhanced-parameters-annotation.md#request-components) - Get request host
- [`@RequestUrl()`](docs/annotations/enhanced-parameters-annotation.md#request-components) - Get complete request URL

## Path Parameters with Enhanced Parameters

> 📖 **Learn all about path parameters:** [**PathParam Annotation Documentation**](docs/annotations/pathparam-annotation.md)

Access path parameters directly with Enhanced Parameters:

```dart
@Get(path: '/users/{userId}/posts/{postId}')
Future<Response> getUserPost(
  @PathParam('userId') String userId, // Enhanced: Direct injection
  @PathParam('postId') String postId, // Enhanced: Direct injection
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Enhanced: JWT context
) async {
  // No manual extraction needed!
  final requestingUser = jwtPayload['user_id'];
  
  // Validate path parameters
  if (userId.isEmpty || postId.isEmpty) {
    return ApiKit.err(ApiErr(
      code: 'INVALID_PARAMETERS',
      message: 'User ID and Post ID cannot be empty',
      details: {
        if (userId.isEmpty) 'userId': 'User ID is required',
        if (postId.isEmpty) 'postId': 'Post ID is required',
      },
    )).toHttpResponse();
  }
  
  // Simulate data fetching
  final postData = await fetchUserPost(userId, postId);
  
  return ApiKit.ok({
    'user_id': userId,
    'post_id': postId,
    'post_data': postData,
    'requested_by': requestingUser,
  }).toHttpResponse();
}
```

## Security Features

### Automatic Security Headers
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security`
- `Content-Security-Policy`

### JWT Token Blacklisting
```dart
// Blacklist a specific token
server.blacklistToken('eyJhbGciOiJIUzI1NiIs...');

// Check blacklist size
print('Blacklisted tokens: ${server.blacklistedTokensCount}');

// Clear all blacklisted tokens
server.clearTokenBlacklist();
```

### Rate Limiting
```dart
final config = ServerConfig(
  rateLimit: RateLimitConfig(
    maxRequests: 100,
    window: Duration(minutes: 1),
    maxRequestsPerIP: 1000,
  ),
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

### Custom Configuration
```dart
final config = ServerConfig(
  cors: CorsConfig.permissive(),
  rateLimit: RateLimitConfig(maxRequests: 1000),
  security: SecurityConfig.strict(),
);
```

## Logging

Uses `logger_rs` for structured logging:

```dart
Log.i('Server started successfully');
Log.w('Rate limit warning');
Log.e('Error occurred', error: error, stackTrace: stackTrace);

// JWT-specific logging
Log.i('🔐 JWT authentication configured');
Log.w('🚫 Token added to blacklist');
Log.e('❌ JWT validation failed');
```

## Production Deployment

### Docker Example
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /app/bin/server /app/bin/server
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
```

### Environment Variables
```bash
export JWT_SECRET="your-production-secret-key-256-bits-minimum"
export SERVER_PORT="8080"
export SERVER_HOST="0.0.0.0"
export LOG_LEVEL="INFO"
```

## Testing

The JWT system includes comprehensive tests:

```bash
# Run all tests
dart test

# Run JWT-specific tests
dart test test/jwt_validation_system_test.dart
dart test test/jwt_production_ready_test.dart

# Run with coverage
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
```

## Performance

- **139/139 tests passing** with 100% success rate
- **Concurrent request handling** tested and validated
- **Token blacklisting** with efficient lookup
- **Production-grade error handling**
- **Enhanced Parameters** zero-overhead direct injection

## 📚 Complete Documentation

### 🎯 Annotation Reference
- **[GET Annotation](docs/annotations/get-annotation.md)** - GET request handling with Enhanced Parameters
- **[POST Annotation](docs/annotations/post-annotation.md)** - POST request handling and body injection
- **[PUT Annotation](docs/annotations/put-annotation.md)** - PUT request handling for complete updates
- **[PATCH Annotation](docs/annotations/patch-annotation.md)** - PATCH request handling for partial updates
- **[DELETE Annotation](docs/annotations/delete-annotation.md)** - DELETE request handling with audit
- **[RestController Annotation](docs/annotations/restcontroller-annotation.md)** - Controller organization and structure

### 🔐 JWT Authentication Reference
- **[JWT Annotations](docs/annotations/jwt-annotations.md)** - @JWTPublic, @JWTController, @JWTEndpoint
- **[JWT Validation System](docs/jwt-validation-system.md)** - Custom validators and business logic

### 🆕 Enhanced Parameters Reference
- **[QueryParam Annotation](docs/annotations/queryparam-annotation.md)** - Query parameter extraction and .all() access
- **[RequestHeader Annotation](docs/annotations/requestheader-annotation.md)** - Header extraction and .all() access
- **[PathParam Annotation](docs/annotations/pathparam-annotation.md)** - Path parameter extraction
- **[RequestBody Annotation](docs/annotations/requestbody-annotation.md)** - Direct body injection
- **[Enhanced Parameters](docs/annotations/enhanced-parameters-annotation.md)** - Complete enhanced parameters guide

### 📋 Use Cases & Examples  
- **[Complete CRUD API](docs/use-cases/complete-crud-api.md)** - Full CRUD with Enhanced Parameters
- **[Complete CRUD Enhanced](docs/use-cases/complete-crud-api-enhanced.md)** - Enhanced version with new patterns
- **[Framework Limitations](docs/use-cases/framework-limitations.md)** - Current limitations and future improvements

### 🚀 Getting Started
- **[Getting Started Guide](docs/getting-started.md)** - Complete tutorial: Zero to production API in 10 minutes!

## Migration Guide

### Before (Old Pattern)
```dart
@Controller('/api/admin')
class AdminController extends BaseController {
  @GET('/users')
  Future<Response> getUsers(Request request) async {
    // Manual extraction + try-catch
    try {
      final jwtPayload = request.context['jwt_payload'];
      return jsonResponse({'users': []});
    } catch (e) {
      return jsonResponse({'error': e.toString()});
    }
  }
}
```

### After (New Pattern)
```dart
@RestController(basePath: '/api/admin')
@JWTController([const MyAdminValidator()])
class AdminController extends BaseController {
  @Get(path: '/users')
  Future<Response> getUsers(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  ) async {
    // Direct injection + standardized responses
    return ApiKit.ok({'users': []}).toHttpResponse();
  }
}
```

## Roadmap

- [x] JWT authentication system with custom validators
- [x] Token blacklisting and management
- [x] Comprehensive test coverage (139 tests)
- [x] Production-ready security headers
- [x] Enhanced Parameters system
- [x] Result pattern standardization
- [ ] Database integration helpers
- [ ] WebSocket support with JWT
- [ ] Metrics and monitoring
- [ ] OpenAPI/Swagger documentation generation
- [ ] Redis-based token blacklist for scaling

## Contributing

This library is production-ready with comprehensive test coverage. Contributions, suggestions, and feedback are welcome!

### Development Setup
```bash
git clone https://github.com/JhonaCodes/api_kit
cd api_kit
dart pub get
dart test
```

## License

MIT License - see LICENSE file for details.

---

## 📚 Explore Complete Documentation

**Ready to dive deeper?** Our comprehensive documentation covers every aspect:

### 🎯 **Start Here**
- **[Documentation Hub](docs/README.md)** - Complete navigation and overview
- **[Getting Started](docs/getting-started.md)** - Step-by-step tutorial

### 🔥 **Master the Framework**
- **[All HTTP Annotations](docs/annotations/)** - Complete annotation reference
- **[Enhanced Parameters](docs/annotations/enhanced-parameters-annotation.md)** - Zero-boilerplate parameter injection
- **[JWT System](docs/annotations/jwt-annotations.md)** - Production-ready authentication

### 🎆 **Production Examples** 
- **[Complete CRUD API](docs/use-cases/complete-crud-api.md)** - Real-world implementation
- **[Framework Limitations](docs/use-cases/framework-limitations.md)** - Understand current boundaries

**🚀 Start building production-ready APIs today!**

---

**Built with ❤️ for developers who need production-ready APIs fast.**