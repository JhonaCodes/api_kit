# JWT Annotations - JWT Authentication System

## 📋 Description

The JWT annotations (`@JWTPublic`, `@JWTController`, `@JWTEndpoint`) form the authentication and authorization system of `api_kit`. They allow defining granular security policies at the controller and endpoint level.

## 🎯 Purpose

- **Layered Security**: Authentication and authorization at the controller and endpoint level.
- **Custom Validators**: Specific business logic for each context.
- **Flexibility**: Combine multiple validators with AND/OR logic.
- **Public Endpoints**: Mark endpoints that do not require authentication.

## 🏗️ JWT System Architecture

```
Request → JWT Middleware → Validators → Endpoint
                ↓
         [@JWTPublic] → Skip validation
         [@JWTController] → Apply to all endpoints
         [@JWTEndpoint] → Override controller validation
```

## 📝 Available Annotations

### 1. @JWTPublic - Public Endpoint

```dart
@JWTPublic()
```

**Purpose**: Marks an endpoint as public, without JWT validation.
**Priority**: Highest - overrides any controller validation.

### 2. @JWTController - Controller-Level Validation

```dart
@JWTController(
  List<JWTValidatorBase> validators,    // List of validators
  {bool requireAll = true}              // AND (true) or OR (false) logic
)
```

**Purpose**: Applies validation to all endpoints of the controller.
**Inheritance**: Endpoints inherit this validation automatically.

### 3. @JWTEndpoint - Endpoint-Specific Validation

```dart
@JWTEndpoint(
  List<JWTValidatorBase> validators,    // List of validators
  {bool requireAll = true}              // AND (true) or OR (false) logic
)
```

**Purpose**: Overrides the controller\'s validation for this specific endpoint.
**Priority**: Medium - overrides `@JWTController` but not `@JWTPublic`.

## 🚀 Usage Examples

### @JWTPublic - Public Endpoints

#### Traditional Approach
```dart
@RestController(basePath: '/api/public')
class PublicController extends BaseController {

  @Get(path: '/health')
  @JWTPublic()  // No authentication required
  Future<Response> healthCheck(Request request) async {
    return ApiKit.ok({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'api_kit'
    }).toHttpResponse();
  }

  @Get(path: '/info')
  @JWTPublic()  // Public information
  Future<Response> getPublicInfo(Request request) async {
    return ApiKit.ok({
      'app_name': 'My API',
      'version': '1.0.0',
      'documentation': 'https://api.example.com/docs',
      'support': 'support@example.com'
    }).toHttpResponse();
  }

  @Post(path: '/contact')
  @JWTPublic()  // Public contact form
  Future<Response> submitContact(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> contactData,
  ) async {

    // Validate form data
    final requiredFields = ['name', 'email', 'message'];
    final missingFields = requiredFields
        .where((field) => !contactData.containsKey(field) ||
                         contactData[field].toString().isEmpty)
        .toList();

    if (missingFields.isNotEmpty) {
      return ApiKit.err(ApiErr(
        code: 'MISSING_FIELDS',
        message: 'Required fields missing',
        details: {'missing_fields': missingFields},
      )).toHttpResponse();
    }

    // Process contact form
    final contactId = 'contact_${DateTime.now().millisecondsSinceEpoch}';

    return ApiKit.ok({
      'message': 'Contact form submitted successfully',
      'contact_id': contactId,
      'status': 'pending_review'
    }).toHttpResponse();
  }
}
```

#### Enhanced Approach - Complete Context Without JWT ✨
```dart
@RestController(basePath: '/api/public')
class PublicController extends BaseController {

  @Get(path: '/health')
  @JWTPublic()  // No authentication required
  Future<Response> healthCheckEnhanced(
    @RequestHost() String host,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    return ApiKit.ok({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'api_kit',
      'endpoint_info': {
        'host': host,
        'method': method,
        'path': path,
      },
      'enhanced': true,
    }).toHttpResponse();
  }

  @Get(path: '/info')
  @JWTPublic()  // Public information
  Future<Response> getPublicInfoEnhanced(
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    return ApiKit.ok({
      'app_name': 'My API',
      'version': '1.0.0',
      'documentation': 'https://api.example.com/docs',
      'support': 'support@example.com',
      'client_info': {
        'host': host,
        'user_agent': headers['user-agent'] ?? 'unknown',
        'accept_language': headers['accept-language'] ?? 'en',
      },
      'enhanced': true,
    }).toHttpResponse();
  }

  @Post(path: '/contact')
  @JWTPublic()  // Public contact form
  Future<Response> submitContactEnhanced(
    @RequestBody(required: true) Map<String, dynamic> contactData,
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {

    // Validate form data
    final requiredFields = ['name', 'email', 'message'];
    final missingFields = requiredFields
        .where((field) => !contactData.containsKey(field) ||
                         contactData[field].toString().isEmpty)
        .toList();

    if (missingFields.isNotEmpty) {
      return ApiKit.err(ApiErr(
        code: 'MISSING_FIELDS',
        message: 'Required fields missing',
        details: {'missing_fields': missingFields},
      )).toHttpResponse();
    }

    // Enhanced: Capture client context for better support
    final contactId = 'contact_${DateTime.now().millisecondsSinceEpoch}';
    final clientContext = {
      'user_agent': headers['user-agent'],
      'referer': headers['referer'],
      'host': host,
      'ip': headers['x-forwarded-for'] ?? headers['x-real-ip'],
    };

    return ApiKit.ok({
      'message': 'Contact form submitted successfully',
      'contact_id': contactId,
      'status': 'pending_review',
      'client_context': clientContext,  // Enhanced context tracking
      'enhanced': true,
    }).toHttpResponse();
  }
}
```

### @JWTController - Controller-Level Validation

#### Traditional Approach - Manual JWT Extraction
```dart
@RestController(basePath: '/api/admin')
@JWTController([
  MyAdminValidator(),              // Must be an administrator
  MyActiveSessionValidator(),      // Session must be active
], requireAll: true)               // Both validators must pass
class AdminController extends BaseController {

  @Get(path: '/users')  // Inherits validation from the controller
  Future<Response> getAllUsers(Request request) async {
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];

    return ApiKit.ok({
      'message': 'All users retrieved',
      'requested_by': adminUser,
      'validation': 'admin + active_session',
      'users': [] // In a real implementation, get from DB
    }).toHttpResponse();
  }

  @Post(path: '/users')  // Inherits validation from the controller
  Future<Response> createUser(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> userData,
  ) async {
    // Manual JWT extraction
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminUser = jwtPayload['user_id'];

    return ApiKit.ok({
      'message': 'User created successfully',
      'created_by': adminUser,
      'user': userData,
      'validation_passed': ['admin', 'active_session']
    }).toHttpResponse();
  }

  @Get(path: '/health')
  @JWTPublic()  // Overrides the controller\'s validation
  Future<Response> adminHealthCheck(Request request) async {
    return ApiKit.ok({
      'status': 'healthy',
      'service': 'admin-panel',
      'authentication': 'bypassed'
    }).toHttpResponse();
  }
}
```

#### Enhanced Approach - Direct JWT Injection ✨
```dart
@RestController(basePath: '/api/admin')
@JWTController([
  MyAdminValidator(),              // Must be an administrator
  MyActiveSessionValidator(),      // Session must be active
], requireAll: true)               // Both validators must pass
class AdminController extends BaseController {

  @Get(path: '/users')  // Inherits validation from the controller
  Future<Response> getAllUsersEnhanced(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
    @QueryParam.all() Map<String, String> filters,  // Dynamic filtering
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    final adminUser = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    // Enhanced: Dynamic filtering capabilities
    final page = int.tryParse(filters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(filters['limit'] ?? '10') ?? 10;
    final search = filters['search'];

    return ApiKit.ok({
      'message': 'All users retrieved - Enhanced!',
      'requested_by': adminUser,
      'admin_context': {
        'role': adminRole,
        'permissions': permissions,
        'permissions_count': permissions.length,
      },
      'filters': {
        'page': page,
        'limit': limit,
        'search': search,
        'total_filters': filters.length,
      },
      'client_info': {
        'user_agent': headers['user-agent'],
      },
      'validation': 'admin + active_session',
      'users': [], // In a real implementation, get from DB with filters
      'enhanced': true,
    }).toHttpResponse();
  }

  @Post(path: '/users')  // Inherits validation from the controller
  Future<Response> createUserEnhanced(
    @RequestBody(required: true) Map<String, dynamic> userData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // Direct JWT
    @RequestHost() String host,
    @RequestMethod() String method,
  ) async {
    final adminUser = jwtPayload['user_id'];
    final adminRole = jwtPayload['role'];

    return ApiKit.ok({
      'message': 'User created successfully - Enhanced!',
      'created_by': adminUser,
      'admin_role': adminRole,
      'user': userData,
      'creation_context': {
        'host': host,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'validation_passed': ['admin', 'active_session'],
      'enhanced': true,
    }).toHttpResponse();
  }

  @Get(path: '/health')
  @JWTPublic()  // Overrides the controller\'s validation
  Future<Response> adminHealthCheckEnhanced(
    @RequestHost() String host,
    @RequestPath() String path,
    @RequestMethod() String method,
  ) async {
    return ApiKit.ok({
      'status': 'healthy',
      'service': 'admin-panel',
      'authentication': 'bypassed',
      'endpoint_info': {
        'host': host,
        'path': path,
        'method': method,
      },
      'enhanced': true,
    }).toHttpResponse();
  }
}

// Custom validators
class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    if (role != 'admin' || !permissions.contains('admin_access')) {
      return ValidationResult.invalid('Administrator access required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Administrator access required';
}

class MyActiveSessionValidator extends JWTValidatorBase {
  const MyActiveSessionValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final sessionActive = jwtPayload['session_active'] as bool? ?? false;
    final lastActivity = jwtPayload['last_activity'] as String?;

    if (!sessionActive) {
      return ValidationResult.invalid('Session is not active');
    }

    if (lastActivity != null) {
      final lastActiveTime = DateTime.tryParse(lastActivity);
      if (lastActiveTime != null) {
        final hoursSinceActivity = DateTime.now().difference(lastActiveTime).inHours;
        if (hoursSinceActivity > 24) {
          return ValidationResult.invalid('Session expired due to inactivity');
        }
      }
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Active session required';
}
```

### @JWTEndpoint - Endpoint-Specific Validation

```dart
@RestController(basePath: '/api/financial')
@JWTController([
  MyUserValidator(),               // Basic user validation
], requireAll: true)
class FinancialController extends BaseController {

  @Get(path: '/balance')  // Only user validation (inherited from controller)
  Future<Response> getBalance(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    return ApiKit.ok({
      'balance': 1000.0,
      'user_id': jwtPayload['user_id'],
      'validation_level': 'basic_user'
    }).toHttpResponse();
  }

  @Post(path: '/transfer')
  @JWTEndpoint([
    MyUserValidator(),             // Valid user
    MyFinancialValidator(minimumClearance: 2),  // Financial clearance level 2
    MyBusinessHoursValidator(),    // Only during business hours
  ], requireAll: true)             // ALL must pass
  Future<Response> makeTransfer(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> transferData,
  ) async {

    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final userId = jwtPayload['user_id'];

    return ApiKit.ok({
      'message': 'Transfer completed successfully',
      'transfer_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'from_user': userId,
      'amount': transferData['amount'],
      'validation_passed': ['user', 'financial_clearance_2', 'business_hours']
    }).toHttpResponse();
  }

  @Delete(path: '/transactions/{transactionId}')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 5),  // Maximum clearance only
    MyAuditValidator(),        // Audit required
  ], requireAll: true)
  Future<Response> deleteTransaction(
    Request request,
    @PathParam('transactionId') String transactionId,
  ) async {

    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;

    return ApiKit.ok({
      'message': 'Transaction deleted successfully',
      'transaction_id': transactionId,
      'deleted_by': jwtPayload['user_id'],
      'validation_level': 'maximum_clearance_with_audit'
    }).toHttpResponse();
  }

  @Get(path: '/reports/summary')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 1),  // Minimum clearance
    MyDepartmentValidator(allowedDepartments: ['finance', 'accounting']),
  ], requireAll: false)          // Either of the two (OR logic)
  Future<Response> getFinancialSummary(Request request) async {

    return ApiKit.ok({
      'summary': 'Financial summary data...', 
      'validation_logic': 'OR - financial_clearance_1 OR department_finance_accounting'
    }).toHttpResponse();
  }
}

// Custom financial validators
class MyFinancialValidator extends JWTValidatorBase {
  final int minimumClearance;

  const MyFinancialValidator({this.minimumClearance = 1});

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final clearanceLevel = jwtPayload['financial_clearance'] as int? ?? 0;

    if (clearanceLevel < minimumClearance) {
      return ValidationResult.invalid(
        'Financial clearance level $minimumClearance required, current: $clearanceLevel'
      );
    }

    // Validate that the clearance has not expired
    final clearanceExpiry = jwtPayload['clearance_expiry'] as String?;
    if (clearanceExpiry != null) {
      final expiryDate = DateTime.tryParse(clearanceExpiry);
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        return ValidationResult.invalid('Financial clearance has expired');
      }
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Financial clearance level $minimumClearance required';
}

class MyBusinessHoursValidator extends JWTValidatorBase {
  const MyBusinessHoursValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekday = now.weekday >= 1 && now.weekday <= 5; // Monday to Friday
    final isBusinessHour = hour >= 9 && hour <= 17; // 9 AM to 5 PM

    if (!isWeekday || !isBusinessHour) {
      return ValidationResult.invalid(
        'Financial operations only allowed during business hours (Mon-Fri, 9 AM - 5 PM)'
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Operation only allowed during business hours';
}

class MyDepartmentValidator extends JWTValidatorBase {
  final List<String> allowedDepartments;

  const MyDepartmentValidator({required this.allowedDepartments});

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userDepartment = jwtPayload['department'] as String?;

    if (userDepartment == null || !allowedDepartments.contains(userDepartment)) {
      return ValidationResult.invalid(
        'Access restricted to departments: ${allowedDepartments.join(', ')}'
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Department access required';
}

class MyAuditValidator extends JWTValidatorBase {
  const MyAuditValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // In a real implementation, log to an audit system
    final userId = jwtPayload['user_id'];
    final action = _extractActionFromRequest(request);

    // Simulate audit logging
    _logAuditEvent(userId, action, request);

    return ValidationResult.valid();
  }

  String _extractActionFromRequest(Request request) {
    final method = request.method;
    final path = request.requestedUri.path;
    return '$method $path';
  }

  void _logAuditEvent(String userId, String action, Request request) {
    // In a real implementation, save to an audit database
    print('AUDIT: User $userId performed action: $action at ${DateTime.now()}');
  }

  @override
  String get defaultErrorMessage => 'Audit logging failed';
}
```

### Complex Example: Multiple Levels of Validation

```dart
@RestController(basePath: '/api/enterprise')
@JWTController([
  MyEmployeeValidator(),           // Must be a valid employee
  MyCompanyValidator(),           // Must belong to the company
], requireAll: true)
class EnterpriseController extends BaseController {

  @Get(path: '/dashboard')  // Only employee + company validation
  Future<Response> getDashboard(Request request) async {
    return ApiKit.ok({
      'dashboard': 'employee dashboard data',
      'validation': 'employee + company'
    }).toHttpResponse();
  }

  @Get(path: '/hr/employees')
  @JWTEndpoint([
    MyEmployeeValidator(),
    MyHRValidator(),               // Must be from HR
    MyPrivacyValidator(level: 'high'),  // High privacy level
  ], requireAll: true)
  Future<Response> getHREmployees(Request request) async {
    return ApiKit.ok({
      'employees': 'HR employee data',
      'validation': 'employee + hr + high_privacy'
    }).toHttpResponse();
  }

  @Post(path: '/finance/budget')
  @JWTEndpoint([
    MyFinancialValidator(minimumClearance: 3),
    MyManagerValidator(minimumLevel: 2),  // Manager level 2+
    MyBudgetValidator(maxAmount: 100000), // Budget limit
  ], requireAll: true)
  Future<Response> createBudget(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> budgetData,
  ) async {

    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;

    return ApiKit.ok({
      'message': 'Budget created successfully',
      'budget': budgetData,
      'created_by': jwtPayload['user_id'],
      'validation': 'financial_3 + manager_2 + budget_limit'
    }).toHttpResponse();
  }

  @Get(path: '/public/company-info')
  @JWTPublic()  // Public company information
  Future<Response> getCompanyInfo(Request request) async {
    return ApiKit.ok({
      'company_name': 'Enterprise Corp',
      'founded': '2010',
      'industry': 'Technology',
      'authentication': 'not_required'
    }).toHttpResponse();
  }
}
```

## 🔄 JWT Validation Flow

### Order of Precedence
1. **@JWTPublic** - Highest priority, skips all validation.
2. **@JWTEndpoint** - Overrides controller validation.
3. **@JWTController** - Default validation for all endpoints.
4. **No annotation** - Uses server configuration.

### Validation Process
```
1. Request arrives at the endpoint
2. Does it have @JWTPublic? → Yes: Allow access
3. Does it have @JWTEndpoint? → Yes: Use those validators
4. Does the controller have @JWTController? → Yes: Use those validators
5. Execute validators according to requireAll (AND/OR)
6. Do all pass? → Yes: Allow access / No: Deny
```

## 💡 Best Practices

### ✅ Do
- **Use @JWTPublic only when necessary**: For truly public endpoints.
- **Apply granular validation**: Different validators for different access levels.
- **Create specific validators**: For business logic specific to your application.
- **Document validators**: Explain what each validator checks and why.
- **Use requireAll appropriately**: AND for strict validations, OR for flexibility.
- **Prefer Enhanced Parameters**: for direct access to the JWT payload without the Request parameter.
- **Combine approaches**: Traditional for robust validation, Enhanced for full context.

### ❌ Don\'t
- **Overly generic validators**: Create specific validators for each use case.
- **Not handling specific errors**: Provide clear messages about why validation failed.
- **Slow validators**: Validations should be fast to not affect performance.
- **Not testing validators**: Create tests for each custom validator.
- **Redundant Request parameter**: Use Enhanced Parameters whenever possible.

### 🎯 Enhanced Recommendations for JWT

#### For Public Endpoints with Context
```dart
// ✅ Enhanced - Complete information without JWT
@Get(path: '/public/status')
@JWTPublic()
Future<Response> getPublicStatus(
  @RequestHost() String host,
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
) async {
  // Complete context access without authentication
  return ApiKit.ok({
    'status': 'operational',
    'host': host,
    'client_info': headers,
    'request_params': params,
  }).toHttpResponse();
}
```

#### For JWT Controller with Dynamic Filters
```dart
// ✅ Enhanced - Direct JWT + unlimited filters
@RestController(basePath: '/api/secure')
@JWTController([MyUserValidator()])
class SecureController extends BaseController {

  @Get(path: '/data')
  Future<Response> getSecureData(
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    @QueryParam.all() Map<String, String> filters,
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    final userId = jwt['user_id'];
    final userRole = jwt['role'];

    return ApiKit.ok({
      'secure_data': [],
      'user_context': {'id': userId, 'role': userRole},
      'applied_filters': filters,
      'client_info': headers,
    }).toHttpResponse();
  }
}
```

#### For JWT Endpoint with Complex Validation
```dart
// ✅ Enhanced - Multiple validators + full context
@Post(path: '/sensitive')
@JWTEndpoint([
  MyAdminValidator(),
  MyFinancialValidator(clearance: 3),
  MyAuditValidator(),
])
Future<Response> sensitiveOperation(
  @RequestBody(required: true) Map<String, dynamic> data,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // Complete audit trail with Enhanced Parameters
  final auditData = {
    'user_id': jwt['user_id'],
    'operation': 'sensitive_operation',
    'data_keys': data.keys.toList(),
    'context_keys': fullContext.keys.toList(),
    'client_ip': headers['x-forwarded-for'],
    'user_agent': headers['user-agent'],
  };

  return ApiKit.ok({
    'message': 'Sensitive operation completed',
    'audit_id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
  }).toHttpResponse();
}
```

#### For Debugging JWT Context
```dart
// ✅ Enhanced - Complete debugging of JWT context
@Get(path: '/debug/jwt')
@JWTEndpoint([MyAdminValidator()])
Future<Response> debugJWTContext(
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
) async {
  return ApiKit.ok({
    'jwt_payload': jwt,
    'full_context_keys': fullContext.keys.toList(),
    'headers_count': headers.length,
    'query_params_count': params.length,
    'debug_info': {
      'jwt_user_id': jwt['user_id'],
      'jwt_keys': jwt.keys.toList(),
      'context_size': fullContext.length,
    }
  }).toHttpResponse();
}
```

## 🔍 Custom Validator Examples

### Simple Role Validator
```dart
class RoleValidator extends JWTValidatorBase {
  final String requiredRole;

  const RoleValidator(this.requiredRole);

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userRole = jwtPayload['role'] as String?;

    if (userRole != requiredRole) {
      return ValidationResult.invalid('Role $requiredRole required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Role $requiredRole required';
}
```

### Multiple Permissions Validator
```dart
class PermissionsValidator extends JWTValidatorBase {
  final List<String> requiredPermissions;
  final bool requireAll;

  const PermissionsValidator(this.requiredPermissions, {this.requireAll = true});

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userPermissions = (jwtPayload['permissions'] as List<dynamic>?)
        ?.cast<String>() ?? [];

    if (requireAll) {
      final missingPermissions = requiredPermissions
          .where((perm) => !userPermissions.contains(perm))
          .toList();

      if (missingPermissions.isNotEmpty) {
        return ValidationResult.invalid(
          'Missing permissions: ${missingPermissions.join(', ')}'
        );
      }
    } else {
      final hasAnyPermission = requiredPermissions
          .any((perm) => userPermissions.contains(perm));

      if (!hasAnyPermission) {
        return ValidationResult.invalid(
          'At least one of these permissions required: ${requiredPermissions.join(', ')}'
        );
      }
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Insufficient permissions';
}
```

## 🌐 JWT Server Configuration

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());

  // Configure JWT
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key-here',
    excludePaths: ['/api/public', '/health'], // Always public paths
  );

  await server.start(
    host: '0.0.0.0',
    port: 8080,
  );
}
```

## 📊 JWT Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Missing token | `401` | Unauthorized - No JWT token provided |
| Invalid token | `401` | Unauthorized - Invalid JWT token |
| Expired token | `401` | Unauthorized - JWT token expired |
| Validator fails | `403` | Forbidden - Insufficient permissions |
| Multiple validators fail | `403` | Forbidden - Multiple validation failures |

---

**Next**: [Use Cases - Documentation](../use-cases/README.md) | **Previous**: [@RequestHeader Documentation](requestheader-annotation.md)
