# @Get - Annotation for GET Endpoints

## 📋 Description

The `@Get` annotation is used to mark methods as endpoints that respond to HTTP GET requests. It is the most commonly used annotation for query and data retrieval operations.

## 🎯 Purpose

- **Query resources**: Obtain information without modifying the server's state.
- **Listings and filters**: Retrieve collections of data with search parameters.
- **Public endpoints**: Information that does not require authentication by default.
- **Read-only APIs**: Operations that do not alter data.

## 📝 Syntax

```dart
@Get({
  required String path,           // Endpoint path (REQUIRED)
  String? description,           // Endpoint description
  int statusCode = 200,          // Default response code
  bool requiresAuth = false,     // If it requires authentication
})
```

## 🔧 Parameters

| Parameter | Type | Required | Default Value | Description |
|-----------|------|----------|---------------|-------------|
| `path` | `String` | ✅ Yes | - | Relative path of the endpoint (e.g., `/users`, `/products/{id}`) |
| `description` | `String?` | ❌ No | `null` | Readable description of the endpoint's purpose |
| `statusCode` | `int` | ❌ No | `200` | HTTP status code for a successful response |
| `requiresAuth` | `bool` | ❌ No | `false` | Indicates if the endpoint requires authentication |

## 🚀 Usage Examples

### Basic Example

#### Traditional Approach
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {

  @Get(path: '/list')
  Future<Response> getUsers() async {
    final users = ['John', 'Jane', 'Bob'];
    return ApiKit.ok({
      'users': users,
          'total': users.length
        }
      }).toHttpResponse();
  }
}
```

#### Enhanced Approach - No Request Parameter Needed! ✨
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {

  @Get(path: '/list')
  Future<Response> getUsersEnhanced() async {
    // Direct implementation without manual Request extraction
    final users = ['John', 'Jane', 'Bob'];
    return ApiKit.ok({
      'success': true,
      'data': {
        'users': users,
        'total': users.length,
        'message': 'Enhanced implementation - no Request parameter needed!'
      }
    }).toHttpResponse();
  }
}
```

### Example with Request Info

#### Traditional Approach - Manual Extractions
```dart
@Get(
  path: '/products',
  description: 'Gets the complete list of available products'
)
Future<Response> getProducts(Request request) async {
  // Manual extractions
  final method = request.method;
  final userAgent = request.headers['user-agent'];

  return ApiKit.ok({
    'products': [],
    'method': method,
    'user_agent': userAgent
  }).toHttpResponse();
}
```

#### Enhanced Approach - Direct Injection
```dart
@Get(
  path: '/products',
  description: 'Gets the complete list of available products'
)
Future<Response> getProductsEnhanced(
  @RequestMethod() String method,
  @RequestHeader.all() Map<String, String> headers,
) async {
  // Direct parameter injection - no manual extraction needed
  return ApiKit.ok({
    'products': [],
    'method': method,                          // Direct injection
    'user_agent': headers['user-agent'],       // From headers map
    'all_headers_count': headers.length,       // Bonus: access to all headers
  }).toHttpResponse();
}
```

### Example with Custom Parameters

#### Traditional Approach
```dart
@Get(
  path: '/status',
  description: 'System health check endpoint',
  statusCode: 200,
  requiresAuth: false
)
Future<Response> healthCheck(Request request) async {
  final host = request.url.host;
  final path = request.url.path;

  return ApiKit.ok({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,
    'path': path
  }).toHttpResponse();
}
```

#### Enhanced Approach
```dart
@Get(
  path: '/status',
  description: 'System health check endpoint',
  statusCode: 200,
  requiresAuth: false
)
Future<Response> healthCheckEnhanced(
  @RequestHost() String host,
  @RequestPath() String path,
  @RequestUrl() Uri fullUrl,
) async {
  return ApiKit.ok({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,           // Direct injection
    'path': path,           // Direct injection
    'full_url': fullUrl.toString(),  // Complete URL access
  }).toHttpResponse();
}
```

### Example with Path Parameters

#### Traditional Approach
```dart
@Get(path: '/users/{userId}')
Future<Response> getUserById(
  Request request,
  @PathParam('userId') String userId,
) async {
  final method = request.method;

  return ApiKit.ok({
    'user_id': userId,
    'name': 'John Doe',
    'email': 'john@example.com',
    'method': method
  }).toHttpResponse();
}
```

#### Enhanced Approach - Hybrid Parameters
```dart
@Get(path: '/users/{userId}')
Future<Response> getUserByIdEnhanced(
  @PathParam('userId') String userId,        // Keep specific path params
  @RequestMethod() String method,            // Direct method injection
) async {
  return ApiKit.ok({
    'user_id': userId,
    'name': 'John Doe',
    'email': 'john@example.com',
    'method': method,                        // No manual extraction
  }).toHttpResponse();
}
```

### Example with Query Parameters

#### Traditional Approach - Limited to Predefined Params
```dart
@Get(path: '/products')
Future<Response> getProductsWithFilters(
  Request request,
  @QueryParam('category', required: false) String? category,
  @QueryParam('page', defaultValue: 1) int page,
  @QueryParam('limit', defaultValue: 10) int limit,
) async {
  // Can't access additional query parameters not predefined
  return ApiKit.ok({
    'products': [],
    'filters': {
      'category': category,
      'page': page,
      'limit': limit
    }
  }).toHttpResponse();
}
```

#### Enhanced Approach - Unlimited Dynamic Filtering
```dart
@Get(path: '/products')
Future<Response> getProductsWithFiltersEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
) async {
  // Parse what you need, ignore the rest
  final category = allQueryParams['category'];
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;

  return ApiKit.ok({
    'products': [],
    'filters': {
      'category': category,
      'page': page,
      'limit': limit,
      'all_params': allQueryParams,          // Bonus: see all parameters
      'total_filters': allQueryParams.length, // Dynamic filtering support
    }
  }).toHttpResponse();
}
```

## 🔗 Combination with Other Annotations

### With JWT Authentication

#### Traditional Approach - Manual Context Extraction
```dart
@Get(path: '/profile', requiresAuth: true)
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(Request request) async {
  // Manual JWT extraction from context
  final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
  final userId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];

  return ApiKit.ok({
    'user_id': userId,
    'role': userRole,
    'profile': 'user profile data'
  }).toHttpResponse();
}
```

#### Enhanced Approach - Direct JWT Injection
```dart
@Get(path: '/profile', requiresAuth: true)
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfileEnhanced(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @RequestMethod() String method,
) async {
  // Direct JWT payload injection - no manual extraction needed!
  final userId = jwtPayload['user_id'];
  final userRole = jwtPayload['role'];

  return ApiKit.ok({
    'user_id': userId,
    'role': userRole,
    'profile': 'user profile data',
    'method': method,           // Bonus: direct method access
  }).toHttpResponse();
}
```

### With Public Endpoint

#### Traditional Approach
```dart
@Get(path: '/public-info')
@JWTPublic() // Overrides requiresAuth
Future<Response> getPublicInfo(Request request) async {
  final userAgent = request.headers['user-agent'];

  return ApiKit.ok({
    'message': 'This information is public',
    'user_agent': userAgent
  }).toHttpResponse();
}
```

#### Enhanced Approach
```dart
@Get(path: '/public-info')
@JWTPublic() // Overrides requiresAuth
Future<Response> getPublicInfoEnhanced(
  @RequestHeader.all() Map<String, String> headers,
  @RequestHost() String host,
) async {
  return ApiKit.ok({
    'message': 'This information is public',
    'user_agent': headers['user-agent'] ?? 'unknown',
    'host': host,
    'headers_count': headers.length,
  }).toHttpResponse();
}
```

### Complete Enhanced Example - GET with Everything
```dart
@Get(path: '/dashboard')
@JWTEndpoint([MyAdminValidator()])
Future<Response> getDashboardEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestUrl() Uri fullUrl,
) async {
  // Comprehensive access without manual Request parameter!
  final userId = jwtPayload['user_id'];
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;

  return ApiKit.ok({
    'dashboard_data': 'admin dashboard content',
    'user_id': userId,
    'page': page,
    'method': method,
    'path': path,
    'host': host,
    'query_params_count': allQueryParams.length,
    'headers_count': allHeaders.length,
    'context_keys': fullContext.keys.toList(),
    'full_url': fullUrl.toString(),
  }).toHttpResponse();
}
```

## 💡 Best Practices

### ✅ Do
- **Use descriptive routes**: `/products`, `/users/{id}`, `/categories/{categoryId}/products`
- **Include descriptions**: Especially for complex endpoints
- **Handle errors**: Return appropriate status codes
- **Validate parameters**: Check types and value ranges
- **Consistent responses**: Use standard JSON format
- **Prefer Enhanced Parameters**: For greater flexibility and less boilerplate
- **Combine approaches**: Traditional for specific parameters, Enhanced for full access

### ❌ Don't
- **Ambiguous routes**: `/data`, `/info`, `/get`
- **Modify state**: GETs should not change data
- **Required parameters in query**: Use PathParam for required values
- **Unstructured responses**: Return plain strings or inconsistent data
- **Redundant Request parameter**: Use Enhanced Parameters when possible

### 🎯 Recommendations by Scenario

#### For Stable APIs with Known Parameters
```dart
// ✅ Traditional - Type-safe and automatic validation
@Get(path: '/products')
Future<Response> getProducts(
  @QueryParam('page', defaultValue: 1) int page,
  @QueryParam('limit', defaultValue: 10) int limit,
) async { ... }
```

#### For Dynamic APIs or Flexible Filters
```dart
// ✅ Enhanced - Maximum flexibility
@Get(path: '/products/search')
Future<Response> searchProducts(
  @QueryParam.all() Map<String, String> filters,
) async {
  // Handle unlimited filter combinations
}
```

#### For Development and Debugging
```dart
// ✅ Enhanced - Full visibility
@Get(path: '/debug/request')
Future<Response> debugRequest(
  @RequestHeader.all() Map<String, String> headers,
  @QueryParam.all() Map<String, String> params,
  @RequestContext.all() Map<String, dynamic> context,
) async {
  // Complete request visibility
}
```

#### For Production APIs
```dart
// ✅ Hybrid - Best of both worlds
@Get(path: '/users')
Future<Response> getUsers(
  @QueryParam('page', defaultValue: 1) int page,        // Type-safe
  @QueryParam.all() Map<String, String> allFilters,    // Flexible
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // Direct
) async { ... }
```

## 🔍 Common Use Cases

### 1. **Resource Listing**

#### Traditional
```dart
@Get(path: '/products', description: 'Lists all products')
Future<Response> listProducts(Request request) async { ... }
```

#### Enhanced ✨
```dart
@Get(path: '/products', description: 'Lists all products')
Future<Response> listProductsEnhanced() async {
  // Direct implementation - no Request parameter needed
}
```

### 2. **Resource by ID**

#### Traditional
```dart
@Get(path: '/products/{id}', description: 'Gets a specific product')
Future<Response> getProduct(Request request, @PathParam('id') String id) async { ... }
```

#### Enhanced - Hybrid ✨
```dart
@Get(path: '/products/{id}', description: 'Gets a specific product')
Future<Response> getProductEnhanced(@PathParam('id') String id) async {
  // Keep specific path params, remove Request parameter
}
```

### 3. **Search with filters**

#### Traditional - Limited
```dart
@Get(path: '/products/search', description: 'Searches for products with filters')
Future<Response> searchProducts(
  Request request,
  @QueryParam('q') String query,
  @QueryParam('category', required: false) String? category
) async { ... }
```

#### Enhanced - Unlimited Filters ✨
```dart
@Get(path: '/products/search', description: 'Searches for products with dynamic filters')
Future<Response> searchProductsEnhanced(
  @QueryParam.all() Map<String, String> allFilters,
) async {
  // Handle unlimited search criteria dynamically
  final query = allFilters['q'];
  final category = allFilters['category'];
  final minPrice = allFilters['min_price'];
  final maxPrice = allFilters['max_price'];
  final brand = allFilters['brand'];
  final color = allFilters['color'];
  // ... any other filters the client sends
}
```

### 4. **Status endpoints**

#### Traditional
```dart
@Get(path: '/health', description: 'Service health check')
Future<Response> healthCheck(Request request) async { ... }
```

#### Enhanced - Comprehensive Health Check ✨
```dart
@Get(path: '/health', description: 'Service health check')
Future<Response> healthCheckEnhanced(
  @RequestHost() String host,
  @RequestPath() String path,
  @RequestHeader.all() Map<String, String> headers,
) async {
  return ApiKit.ok({
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'host': host,
    'path': path,
    'user_agent': headers['user-agent'],
    'total_headers': headers.length,
  }).toHttpResponse();
}
```

### 5. **Nested resources**

#### Traditional
```dart
@Get(path: '/users/{userId}/orders', description: 'Orders for a specific user')
Future<Response> getUserOrders(
  Request request,
  @PathParam('userId') String userId
) async { ... }
```

#### Enhanced - With Filtering ✨
```dart
@Get(path: '/users/{userId}/orders', description: 'User orders with filters')
Future<Response> getUserOrdersEnhanced(
  @PathParam('userId') String userId,
  @QueryParam.all() Map<String, String> filters,
  @RequestMethod() String method,
) async {
  final status = filters['status'];          // Optional filter
  final dateFrom = filters['date_from'];     // Optional filter
  final dateTo = filters['date_to'];         // Optional filter

  return ApiKit.ok({
    'user_id': userId,
    'orders': [],  // Filtered results
    'applied_filters': filters,
    'method': method,
  }).toHttpResponse();
}
```

### 6. **🆕 Enhanced Use Case: Debug Endpoint**
```dart
@Get(path: '/debug/request', description: 'Complete request analysis')
Future<Response> debugRequestEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext.all() Map<String, dynamic> fullContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestUrl() Uri fullUrl,
) async {
  return ApiKit.ok({
    'request_analysis': {
      'method': method,
      'path': path,
      'host': host,
      'full_url': fullUrl.toString(),
      'query_params': allQueryParams,
      'headers': allHeaders,
      'context_keys': fullContext.keys.toList(),
      'stats': {
        'total_query_params': allQueryParams.length,
        'total_headers': allHeaders.length,
        'context_entries': fullContext.length,
      }
    }
  }).toHttpResponse();
}
```

### 7. **🆕 Enhanced Use Case: JWT Dashboard**
```dart
@Get(path: '/admin/dashboard', description: 'Admin dashboard with full context')
@JWTEndpoint([MyAdminValidator()])
Future<Response> adminDashboardEnhanced(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  @QueryParam.all() Map<String, String> filters,
  @RequestHost() String host,
) async {
  final adminId = jwtPayload['user_id'];
  final role = jwtPayload['role'];

  return ApiKit.ok({
    'dashboard_data': 'admin content',
    'admin_info': {
      'id': adminId,
      'role': role,
    },
    'host': host,
    'active_filters': filters,
    'timestamp': DateTime.now().toIso8601String(),
  }).toHttpResponse();
}
```

## 🌐 Resulting URLs

If your controller has `basePath: '/api/v1'` and you use `@Get(path: '/products')`, the final URL will be:
```
GET http://localhost:8080/api/v1/products
```

## 📊 Recommended Response Codes

| Situation | Code | Description |
|-----------|---------|-------------|
| Success | `200` | Resource found and returned |
| Resource not found | `404` | ID does not exist |
| Invalid parameters | `400` | Malformed query params |
| Unauthorized | `401` | Invalid JWT token |
| Forbidden | `403` | Valid token but no permissions |
| Server error | `500` | Internal error |

## 🔧 Server Configuration

Endpoints marked with `@Get` are automatically registered when you start the server:

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());

  await server.start(
    host: 'localhost',
    port: 8080,
    // Controllers auto-discovered
  );
}
```

---

**Next**: [@Post Documentation](post-annotation.md) | **Previous**: [Annotation Index](../README.md)
