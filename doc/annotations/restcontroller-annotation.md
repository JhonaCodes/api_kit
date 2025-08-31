# @RestController - Annotation for REST Controllers

## 📋 Description

The `@RestController` annotation is used to mark classes as REST controllers that group multiple related endpoints. It defines the base path and common characteristics for all endpoints in the controller.

## 🎯 Purpose

- **Organize endpoints**: Group related methods under a common path
- **Define structure**: Establish the basePath for all endpoints
- **Automatic documentation**: Generate structured API documentation
- **Centralized configuration**: Apply settings at the controller level

## 📝 Syntax

```dart
@RestController({
  String basePath = \'\',              // Base path of the controller
  String? description,
  List<String> tags = const [],     // Tags for documentation
  bool requiresAuth = false,        // If all endpoints require auth by default
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `basePath` | `String` | ❌ No | `\'\' ` | Common base path for all endpoints in the controller |
| `description` | `String?` | ❌ No | `null` | Description of the controller\'s purpose |
| `tags` | `List<String>` | ❌ No | `[]` | Tags for organization and documentation |
| `requiresAuth` | `bool` | ❌ No | `false` | If all endpoints require authentication by default |

## 🚀 Usage Examples

### Basic Example

#### Traditional Approach
```dart
@RestController(basePath: \'/api/users\')
class UserController extends BaseController {
  
  @Get(path: \'/list\')  // Final URL: /api/users/list
  Future<Response> getUsers(Request request) async {
    return ApiKit.ok({\'users\': []}).toHttpResponse();
  }
  
  @Post(path: \'/create\')  // Final URL: /api/users/create
  Future<Response> createUser(Request request) async {
    return ApiKit.ok({\'message\': \'User created\'}).toHttpResponse();
  }
  
  @Get(path: \'/{id}\')  // Final URL: /api/users/{id}
  Future<Response> getUserById(
    Request request,
    @PathParam(\'id\') String userId,
  ) async {
    return ApiKit.ok({\'user_id\': userId}).toHttpResponse();
  }
}
```

#### Enhanced Approach - No Request Parameter Needed! ✨
```dart
@RestController(basePath: \'/api/users\')
class UserController extends BaseController {
  
  @Get(path: \'/list\')  // Final URL: /api/users/list
  Future<Response> getUsersEnhanced() async {
    // Direct implementation without Request parameter
    return ApiKit.ok({
      \'users\': [],
      \'enhanced\': true,
    }).toHttpResponse();
  }
  
  @Post(path: \'/create\')  // Final URL: /api/users/create
  Future<Response> createUserEnhanced(
    @RequestBody() Map<String, dynamic> userData,  // Direct body injection
    @RequestHost() String host,
  ) async {
    return ApiKit.ok({
      \'message\': \'User created - Enhanced!\',
      \'user\': userData,
      \'created_on_host\': host,
    }).toHttpResponse();
  }
  
  @Get(path: \'/{id}\')  // Final URL: /api/users/{id}
  Future<Response> getUserByIdEnhanced(
    @PathParam(\'id\') String userId,
    @RequestMethod() String method,
  ) async {
    return ApiKit.ok({
      \'user_id\': userId,
      \'method\': method,
      \'enhanced\': true,
    }).toHttpResponse();
  }
}
```

### Example with Description and Tags
```dart
@RestController(
  basePath: \'/api/products\',
  description: \'Complete management of catalog products\',
  tags: [\'products\', \'catalog\', \'inventory\'],
  requiresAuth: false // Endpoints define their own auth
)
class ProductController extends BaseController {
  
  @Get(path: \'/search\')  // URL: /api/products/search
  @JWTPublic() // Public endpoint
  Future<Response> searchProducts(
    Request request,
    @QueryParam(\'q\', required: true) String query,
    @QueryParam(\'category\', required: false) String? category,
  ) async {
    return ApiKit.ok({
      \'message\': \'Product search\',
      \'query\': query,
      \'category\': category,
      \'controller_tags\': [\'products\', \'catalog\', \'inventory\']
    }).toHttpResponse();
  }
  
  @Post(path: \'/create\')  // URL: /api/products/create
  @JWTEndpoint([MyAdminValidator()]) // Admins only
  Future<Response> createProduct(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return ApiKit.ok({
      \'message\': \'Product created\',
      \'product\': productData
    }).toHttpResponse();
  }
  
  @Put(path: \'/{productId}\')  // URL: /api/products/{productId}
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> updateProduct(
    Request request,
    @PathParam(\'productId\') String productId,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return ApiKit.ok({
      \'message\': \'Product updated\',
      \'product_id\': productId,
      \'data\': productData
    }).toHttpResponse();
  }
}
```

### Example with Default Authentication

#### Traditional Approach - Manual JWT Extraction
```dart
@RestController(
  basePath: \'/api/admin\',
  description: \'Admin panel - requires admin permissions\',
  tags: [\'admin\', \'management\'],
  requiresAuth: true // All endpoints require auth by default
)
class AdminController extends BaseController {
  
  @Get(path: \'/dashboard\')  // Inherits requiresAuth = true
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getDashboard(Request request) async {
    return ApiKit.ok({\'dashboard\': \'admin data\'}).toHttpResponse();
  }
  
  @Get(path: \'/users\')  // Inherits requiresAuth = true  
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getAllUsers(Request request) async {
    return ApiKit.ok({\'users\': []}).toHttpResponse();
  }
  
  @Get(path: \'/health\')  // Overrides requiresAuth
  @JWTPublic() // This endpoint is public despite the controller\'s requiresAuth
  Future<Response> adminHealthCheck(Request request) async {
    return ApiKit.ok({
      \'status\': \'healthy\',
      \'service\': \'admin-panel\'
    }).toHttpResponse();
  }
}
```

#### Enhanced Approach - Direct JWT & Context Injection ✨
```dart
@RestController(
  basePath: \'/api/admin\',
  description: \'Admin panel - requires admin permissions\',
  tags: [\'admin\', \'management\'],
  requiresAuth: true // All endpoints require auth by default
)
class AdminController extends BaseController {
  
  @Get(path: \'/dashboard\')  // Inherits requiresAuth = true
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getDashboardEnhanced(
    @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt, // Direct JWT
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    final adminId = jwt[\'user_id\'];
    final adminRole = jwt[\'role\'];
    
    return ApiKit.ok({
      \'dashboard\': \'admin data\',
      \'admin_context\': {
        \'admin_id\': adminId,
        \'role\': adminRole,
        \'host\': host,
        \'user_agent\': headers[\'user-agent\'],
      },
      \'enhanced\': true,
    }).toHttpResponse();
  }
  
  @Get(path: \'/users\')  // Inherits requiresAuth = true  
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> getAllUsersEnhanced(
    @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,
    @QueryParam.all() Map<String, String> filters, // Dynamic filtering
  ) async {
    final adminId = jwt[\'user_id\'];
    final page = int.tryParse(filters[\'page\'] ?? \'1\') ?? 1;
    final limit = int.tryParse(filters[\'limit\'] ?? \'10\') ?? 10;
    
    return ApiKit.ok({
      \'users\': [],
      \'admin_id\': adminId,
      \'pagination\': {\'page\': page, \'limit\': limit},
      \'applied_filters\': filters,
      \'enhanced\': true,
    }).toHttpResponse();
  }
  
  @Get(path: \'/health\')  // Overrides requiresAuth
  @JWTPublic() // This endpoint is public despite the controller\'s requiresAuth
  Future<Response> adminHealthCheckEnhanced(
    @RequestHost() String host,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    return ApiKit.ok({
      \'status\': \'healthy\',
      \'service\': \'admin-panel\',
      \'endpoint_info\': {
        \'host\': host,
        \'method\': method,
        \'path\': path,
      },
      \'enhanced\': true,
    }).toHttpResponse();
  }
}
```

### API Versioning Example
```dart
// API version 1
@RestController(
  basePath: \'/api/v1/orders\',
  description: \'Order system - version 1.0\',
  tags: [\'orders\', \'v1\', \'legacy\']
)
class OrderControllerV1 extends BaseController {
  
  @Get(path: \'/list\')  // URL: /api/v1/orders/list
  Future<Response> getOrders(Request request) async {
    return ApiKit.ok({
      \'version\': \'1.0\',
      \'orders\': []
    }).toHttpResponse();
  }
}

// API version 2 with improvements
@RestController(
  basePath: \'/api/v2/orders\',
  description: \'Order system - version 2.0 with new features\',
  tags: [\'orders\', \'v2\', \'current\']
)
class OrderControllerV2 extends BaseController {
  
  @Get(path: \'/list\')  // URL: /api/v2/orders/list
  Future<Response> getOrders(
    Request request,
    @QueryParam(\'status\', required: false) String? status,
    @QueryParam(\'page\', defaultValue: 1) int page,
  ) async {
    return ApiKit.ok({
      \'version\': \'2.0\',
      \'orders\': [],
      \'pagination\': {\'page\': page},
      \'filters\': {\'status\': status}
    }).toHttpResponse();
  }
  
  @Get(path: \'/{orderId}/detailed\')  // URL: /api/v2/orders/{orderId}/detailed
  Future<Response> getDetailedOrder(
    Request request,
    @PathParam(\'orderId\') String orderId,
  ) async {
    return ApiKit.ok({
      \'version\': \'2.0\',
      \'order_id\': orderId,
      \'detailed_info\': true
    }).toHttpResponse();
  }
}
```

### Nested/Hierarchical Controller Example
```dart
@RestController(
  basePath: \'/api/stores\',
  description: \'Management of stores and their resources\',
  tags: [\'stores\', \'multi-tenant\']
)
class StoreController extends BaseController {
  
  @Get(path: \'/list\')  // URL: /api/stores/list
  Future<Response> getStores(Request request) async {
    return ApiKit.ok({\'stores\': []}).toHttpResponse();
  }
  
  @Get(path: \'/{storeId}/info\')  // URL: /api/stores/{storeId}/info
  Future<Response> getStoreInfo(
    Request request,
    @PathParam(\'storeId\') String storeId,
  ) async {
    return ApiKit.ok({
      \'store_id\': storeId,
      \'info\': \'store details\'
    }).toHttpResponse();
  }
}

// Controller for products of a specific store
@RestController(
  basePath: \'/api/stores/{storeId}/products\',
  description: \'Products specific to each store\',
  tags: [\'stores\', \'products\', \'nested\']
)
class StoreProductController extends BaseController {
  
  @Get(path: \'/list\')  // URL: /api/stores/{storeId}/products/list
  Future<Response> getStoreProducts(
    Request request,
    @PathParam(\'storeId\') String storeId,
  ) async {
    return ApiKit.ok({
      \'store_id\': storeId,
      \'products\': []
    }).toHttpResponse();
  }
  
  @Post(path: \'/create\')  // URL: /api/stores/{storeId}/products/create
  Future<Response> createStoreProduct(
    Request request,
    @PathParam(\'storeId\') String storeId,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    return ApiKit.ok({
      \'message\': \'Product created for store\',
      \'store_id\': storeId,
      \'product\': productData
    }).toHttpResponse();
  }
}
```

### Example with Controller-Level Middleware
```dart
@RestController(
  basePath: \'/api/financial\',
  description: \'Financial services with high security\',
  tags: [\'financial\', \'secure\', \'compliance\']
)
@JWTController([
  MyFinancialValidator(clearanceLevel: 2),
  MyBusinessHoursValidator(),
  MyAuditValidator(), // Log all actions
], requireAll: true)
class FinancialController extends BaseController {
  
  @Get(path: \'/balance\')  // Inherits all validators from the controller
  Future<Response> getBalance(Request request) async {
    // Only executes if it passes financial validation + business hours + audit
    final jwtPayload = request.context[\'jwt_payload\'] as Map<String, dynamic>;
    return ApiKit.ok({
      \'balance\': 1000.0,
      \'user_id\': jwtPayload[\'user_id\'],
      \'timestamp\': DateTime.now().toIso8601String()
    }).toHttpResponse();
  }
  
  @Post(path: \'/transfer\')  // Inherits validators + specific validation
  @JWTEndpoint([
    MyTransferValidator(minimumAmount: 10.0),
  ]) // Is combined with those of the controller
  Future<Response> makeTransfer(
    Request request,
    @RequestBody(required: true) Map<String, dynamic> transferData,
  ) async {
    // Requires: financial + business hours + audit + transfer validation
    return ApiKit.ok({
      \'message\': \'Transfer completed\',
      \'transfer\': transferData
    }).toHttpResponse();
  }
}
```

## 🔗 Combination with Other Annotations

### With JWT at the Controller Level
```dart
@RestController(basePath: \'/api/secure\')
@JWTController([
  MyUserValidator(),
  MyActiveSessionValidator(),
], requireAll: true) // Applies to all endpoints
class SecureController extends BaseController {
  
  @Get(path: \'/profile\')  // Inherits validation from the controller
  Future<Response> getProfile(Request request) async { ... }
  
  @Get(path: \'/public-info\')  
  @JWTPublic() // Overrides the controller\'s validation
  Future<Response> getPublicInfo(Request request) async { ... }
  
  @Post(path: \'/sensitive\')
  @JWTEndpoint([MyAdminValidator()]) // Is combined with the controller\'s validators
  Future<Response> sensitiveOperation(Request request) async { ... }
}
```

## 💡 Best Practices

### ✅ Do
- **Use descriptive basePaths**: `/api/users`, `/api/products`, `/api/orders`
- **Group related endpoints**: All endpoints of a resource in the same controller
- **Include versioning**: `/api/v1/users`, `/api/v2/users` for different versions
- **Document the purpose**: Use `description` to explain what the controller does
- **Use tags for organization**: To group controllers in documentation
- **Prefer Enhanced Parameters**: In all endpoints to eliminate redundant Request
- **Combine approaches**: Traditional for validation, Enhanced for flexibility

### ❌ Don\'t
- **Very generic basePaths**: `/api`, `/data` without specificity
- **Mixing different resources**: Do not put user and product endpoints in the same controller
- **Very long basePaths**: Avoid excessively deep nested routes
- **Duplicate functionality**: A resource should have a main controller
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Enhanced Recommendations by Controller Type

#### For Public Controllers
```dart
// ✅ Enhanced - Public endpoints with optional context
@RestController(basePath: \'/api/public\')
class PublicController extends BaseController {
  
  @Get(path: \'/info\')
  @JWTPublic()
  Future<Response> getPublicInfo(
    @RequestHost() String host,
    @RequestHeader.all() Map<String, String> headers,
  ) async {
    // Complete access without authentication
    return ApiKit.ok({
      \'public_data\': \'available\',
      \'host\': host,
      \'user_agent\': headers[\'user-agent\'] ?? \'unknown\',
    }).toHttpResponse();
  }
}
```

#### For Authenticated Controllers
```dart
// ✅ Enhanced - Direct JWT without Request parameter
@RestController(basePath: \'/api/secure\', requiresAuth: true)
@JWTController([MyUserValidator()])
class SecureController extends BaseController {
  
  @Get(path: \'/profile\')
  Future<Response> getProfile(
    @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,
    @RequestMethod() String method,
  ) async {
    final userId = jwt[\'user_id\'];
    final userRole = jwt[\'role\'];
    
    return ApiKit.ok({
      \'profile\': \'user profile data\',
      \'user_id\': userId,
      \'role\': userRole,
      \'method\': method,
    }).toHttpResponse();
  }
}
```

#### For Controllers with Dynamic Filters
```dart
// ✅ Enhanced - Unlimited filters with QueryParam.all()
@RestController(basePath: \'/api/data\')
class DataController extends BaseController {
  
  @Get(path: \'/search\')
  Future<Response> searchData(
    @QueryParam.all() Map<String, String> allFilters,
    @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt,
  ) async {
    // Handle unlimited search criteria dynamically
    return ApiKit.ok({
      \'results\': [],
      \'applied_filters\': allFilters,
      \'total_filters\': allFilters.length,
      \'user_id\': jwt[\'user_id\'],
    }).toHttpResponse();
  }
}
```

#### For API Versioning Controllers
```dart
// ✅ Enhanced - Versioning with full context
@RestController(basePath: \'/api/v2/advanced\')
class AdvancedV2Controller extends BaseController {
  
  @Get(path: \'/features\')
  Future<Response> getAdvancedFeatures(
    @QueryParam.all() Map<String, String> options,
    @RequestHeader.all() Map<String, String> headers,
    @RequestHost() String host,
  ) async {
    return ApiKit.ok({
      \'version\': \'2.0\',
      \'features\': [\'enhanced_params\', \'dynamic_filtering\', \'direct_jwt\'],
      \'client_options\': options,
      \'client_info\': {
        \'host\': host,
        \'user_agent\': headers[\'user-agent\'],
      },
    }).toHttpResponse();
  }
}
```

#### For Multi-tenant Controllers
```dart
// ✅ Hybrid - Specific path params + Enhanced flexibility
@RestController(basePath: \'/api/tenants/{tenantId}\')
class TenantController extends BaseController {
  
  @Get(path: \'/resources\')
  Future<Response> getTenantResources(
    @PathParam(\'tenantId\') String tenantId,              // Type-safe tenant
    @QueryParam.all() Map<String, String> resourceFilters, // Dynamic filters
    @RequestContext(\'jwt_payload\') Map<String, dynamic> jwt, // Direct JWT
  ) async {
    final userId = jwt[\'user_id\'];
    
    return ApiKit.ok({
      \'tenant_id\': tenantId,
      \'resources\': [],
      \'filters\': resourceFilters,
      \'requested_by\': userId,
    }).toHttpResponse();
  }
}
```

## 🔍 URL Hierarchy

### Simple Controller
```dart
@RestController(basePath: \'/api/users\')
// Resulting URLs:
// GET  /api/users/list
// POST /api/users/create  
// GET  /api/users/{id}
```

### Nested Controller
```dart
@RestController(basePath: \'/api/stores/{storeId}/products\')
// Resulting URLs:
// GET  /api/stores/{storeId}/products/list
// POST /api/stores/{storeId}/products/create
// PUT  /api/stores/{storeId}/products/{productId}
```

### Controller with Versioning
```dart
@RestController(basePath: \'/api/v2/analytics\')
// Resulting URLs:
// GET  /api/v2/analytics/reports
// POST /api/v2/analytics/custom-report
// GET  /api/v2/analytics/dashboard
```

## 🌐 Server Registration

Controllers are registered when the server starts:

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: \'localhost\',
    port: 8080,
    // Auto-discovery - [
      UserController(),           // @RestController(basePath: \'/api/users\')
      ProductController(),        // @RestController(basePath: \'/api/products\')
      AdminController(),          // @RestController(basePath: \'/api/admin\')
      OrderControllerV1(),        // @RestController(basePath: \'/api/v1/orders\')
      OrderControllerV2(),        // @RestController(basePath: \'/api/v2/orders\')
    ],
  );
}
```

## 📊 Complete Structure Example

### Main Controller
```dart
@RestController(
  basePath: \'/api/ecommerce/stores\',
  description: \'Complete e-commerce store management system\',
  tags: [\'ecommerce\', \'stores\', \'management\']
)
class EcommerceStoreController extends BaseController {
  
  @Get(path: \'/list\')
  @JWTPublic()
  Future<Response> listStores(Request request) async { ... }
  
  @Post(path: \'/create\')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> createStore(Request request) async { ... }
  
  @Get(path: \'/{storeId}\')
  Future<Response> getStoreDetails(Request request, @PathParam(\'storeId\') String storeId) async { ... }
  
  @Put(path: \'/{storeId}\')
  @JWTEndpoint([MyStoreOwnerValidator()])
  Future<Response> updateStore(Request request, @PathParam(\'storeId\') String storeId) async { ... }
  
  @Delete(path: \'/{storeId}\')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> deleteStore(Request request, @PathParam(\'storeId\') String storeId) async { ... }
}
```

### Resulting URLs
```
GET    /api/ecommerce/stores/list
POST   /api/ecommerce/stores/create
GET    /api/ecommerce/stores/{storeId}
PUT    /api/ecommerce/stores/{storeId}
DELETE /api/ecommerce/stores/{storeId}
```

---

**Next**: [Documentation for @Service](service-annotation.md) | **Previous**: [Documentation for @Delete](delete-annotation.md)
