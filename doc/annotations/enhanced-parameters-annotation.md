# 🚀 Enhanced Parameters - "All" Mode Support

## 🎯 New Feature: "All" Parameter Capture

api_kit now supports capturing **ALL** parameters of a certain type without specifying individual keys, eliminating the need for the `Request request` parameter in most cases.

## 📋 Enhanced Annotations

### 1. `@RequestHeader.all()` - All Headers

```dart
/// ❌ BEFORE - Only specific headers
@Get(path: '/endpoint')
Future<Response> oldWay(
  Request request,  // ← Necessary for headers
  @RequestHeader('Authorization') String auth,
  @RequestHeader('User-Agent') String userAgent,
) async {
  // Manual extraction for other headers
  final allHeaders = request.headers;
}

/// ✅ NOW - All headers automatically
@Get(path: '/endpoint')
Future<Response> newWay(
  @RequestHeader.all() Map<String, String> allHeaders,  // ← ALL headers
  @RequestHeader('Authorization') String auth,          // ← Specific headers still work
) async {
  // allHeaders contains ALL HTTP headers
  final userAgent = allHeaders['user-agent'];
  final contentType = allHeaders['content-type'];
}
```

### 2. `@QueryParam.all()` - All Query Parameters

```dart
/// ❌ BEFORE - Only specific parameters
@Get(path: '/search')
Future<Response> oldSearch(
  Request request,  // ← Necessary for query params
  @QueryParam('q') String query,
  @QueryParam('page') int page,
) async {
  // Manual extraction for other params
  final allParams = request.url.queryParameters;
}

/// ✅ NOW - All query params automatically  
@Get(path: '/search')
Future<Response> newSearch(
  @QueryParam.all() Map<String, String> allQueryParams,  // ← ALL params
  @QueryParam('q') String query,                         // ← Specific ones still work
) async {
  // allQueryParams contains ALL query parameters
  final filters = allQueryParams.entries
    .where((entry) => entry.key.startsWith('filter_'))
    .toList();
}
```

## 🆕 New Annotations for Request Components

### HTTP Request Information

```dart
@Get(path: '/inspect')
Future<Response> inspectRequest(
  @RequestMethod() String method,        // GET, POST, PUT, DELETE, etc.
  @RequestPath() String path,            // /api/inspect  
  @RequestHost() String host,            // localhost, api.example.com
  @RequestPort() int port,               // 8080, 443
  @RequestScheme() String scheme,        // http, https
  @RequestUrl() Uri fullUrl,             // Full URL as Uri
) async {
  return ApiKit.ok({
    'method': method,      // No request.method
    'path': path,          // No request.url.path
    'host': host,          // No request.url.host
    'port': port,          // No request.url.port
    'scheme': scheme,      // No request.url.scheme
    'url': fullUrl.toString(),
  }).toHttpResponse();
}
```

### Request Context

```dart
/// JWT endpoint WITHOUT manual Request
@Get(path: '/profile')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserProfile(
  @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,  // Specific JWT
  @RequestContext.all() Map<String, dynamic> allContext,           // Entire context
) async {
  // JWT available directly, without request.context['jwt_payload']
  final userId = jwtPayload['user_id'];
  return ApiKit.ok({'user_id': userId}).toHttpResponse();
}
```

## 💡 Complete Use Cases

### Complete Endpoint WITHOUT Manual Request

```dart
@RestController(basePath: '/api/enhanced')
class EnhancedController extends BaseController { 
  
  @Post(path: '/complete-example')
  @JWTEndpoint([MyValidator()])
  Future<Response> completeExample(
    // ✅ Automatic request body parsing
    @RequestBody() Map<String, dynamic> body,
    
    // ✅ ALL headers available
    @RequestHeader.all() Map<String, String> allHeaders,
    
    // ✅ ALL query params available  
    @QueryParam.all() Map<String, String> allQueryParams,
    
    // ✅ Direct JWT payload (no manual extraction)
    @RequestContext('jwt_payload') Map<String, dynamic> jwt,
    
    // ✅ Direct request information
    @RequestMethod() String method,
    @RequestPath() String path,
    @RequestUrl() Uri fullUrl,
    
    // 🎉 NO Request request needed!
  ) async {
    
    // Everything available directly - no manual extractions
    final userId = jwt['user_id'];
    final authHeader = allHeaders['authorization'];
    final debugMode = allQueryParams['debug'] == 'true';
    
    return ApiKit.ok({
      'message': 'Complete request handling without manual Request parameter!',
      'user_id': userId,
      'method': method,
      'path': path,
      'has_auth': authHeader != null,
      'debug_mode': debugMode,
      'request_body': body,
    }).toHttpResponse();
  }
}
```

### Complete Request Inspection

```dart
@Get(path: '/debug/request')
Future<Response> debugFullRequest(
  @RequestHeader.all() Map<String, String> allHeaders,
  @QueryParam.all() Map<String, String> allQueryParams, 
  @RequestContext.all() Map<String, dynamic> allContext,
  @RequestMethod() String method,
  @RequestPath() String path,
  @RequestHost() String host,
  @RequestPort() int port,
  @RequestScheme() String scheme,
  @RequestUrl() Uri fullUrl,
) async {
  return ApiKit.ok({
    'complete_request_debug': {
      'http_info': {
        'method': method,
        'path': path,
        'host': host,
        'port': port,
        'scheme': scheme,
        'full_url': fullUrl.toString(),
      },
      'headers': {
        'count': allHeaders.length,
        'all': allHeaders,
        'auth_headers': allHeaders.entries
          .where((e) => e.key.toLowerCase().contains('auth'))
          .map((e) => '${e.key}: ${e.value}')
          .toList(),
      },
      'query_params': {
        'count': allQueryParams.length,
        'all': allQueryParams,
        'filters': allQueryParams.entries
          .where((e) => e.key.startsWith('filter_'))
          .map((e) => '${e.key}: ${e.value}')
          .toList(),
      },
      'context': {
        'keys': allContext.keys.toList(),
        'has_jwt': allContext.containsKey('jwt_payload'),
        'middleware_data': allContext.entries
          .where((e) => e.key != 'jwt_payload')
          .map((e) => '${e.key}: ${e.value.runtimeType}')
          .toList(),
      },
    },
  }).toHttpResponse();
}
```

## 🎯 Comparison: Before vs After

### Typical JWT Endpoint

```dart
/// ❌ BEFORE - Verbose and with manual extractions
@Post(path: '/api/users')
@JWTEndpoint([MyValidator()])
Future<Response> createUserOld(
  Request request,                                    // ← Required
  @RequestBody() Map<String, dynamic> userData,       // ← Parsed but I need Request
) async {
  // Manual extractions
  final jwt = request.context['jwt_payload'] as Map<String, dynamic>;  // ← Manual
  final method = request.method;                                       // ← Manual
  final allHeaders = request.headers;                                  // ← Manual
  final allQueryParams = request.url.queryParameters;                 // ← Manual
  
  final currentUserId = jwt['user_id'];
  // ... rest of the logic
}

/// ✅ AFTER - Declarative and direct
@Post(path: '/api/users')
@JWTEndpoint([MyValidator()])
Future<Response> createUserNew(
  @RequestBody() Map<String, dynamic> userData,                        // ← Parsed body
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,             // ← Direct JWT
  @RequestHeader.all() Map<String, String> allHeaders,                 // ← All headers
  @QueryParam.all() Map<String, String> allQueryParams,               // ← All params
  @RequestMethod() String method,                                      // ← Direct method
  // NO Request request needed! 🎉
) async {
  // Direct access - no manual extractions
  final currentUserId = jwt['user_id'];
  // ... rest of the logic
}
```

## 📚 Complete Syntax

### Enhanced RequestHeader

```dart
// Specific header (current behavior)
@RequestHeader('Authorization') String authToken

// NEW: All headers
@RequestHeader.all() Map<String, String> allHeaders
```

### Enhanced QueryParam

```dart
// Specific query param (current behavior)  
@QueryParam('page') int page

// NEW: All query parameters
@QueryParam.all() Map<String, String> allQueryParams
```

### New Request Annotations

```dart
@RequestMethod() String method          // HTTP method
@RequestPath() String path              // Request path
@RequestHost() String host              // Request host
@RequestPort() int port                 // Request port  
@RequestScheme() String scheme          // http/https
@RequestUrl() Uri fullUrl               // Complete URL

@RequestContext('key') dynamic value    // Specific context value
@RequestContext.all() Map<String, dynamic> allContext  // All context
```

## ✅ Advantages of the New System

1. **Less Boilerplate**: You don't need `Request request` in most cases
2. **More Declarative**: Annotations express exactly what you need
3. **Type-Safe**: Parameters are automatically typed
4. **Better Testability**: Injected parameters are easier to mock
5. **Consistency**: Same pattern for all request components
6. **Compatibility**: Existing code continues to work without changes

## 🔄 Migration

### Step 1: Replace Manual Extractions

```dart
// Before
final allHeaders = request.headers;
final allQueryParams = request.url.queryParameters;
final jwt = request.context['jwt_payload'];

// After - add annotation parameters
@RequestHeader.all() Map<String, String> allHeaders,
@QueryParam.all() Map<String, String> allQueryParams,
@RequestContext('jwt_payload') Map<String, dynamic> jwt,
```

### Step 2: Remove Request Parameter

```dart
// Before
Future<Response> endpoint(Request request, @RequestBody() Map data) async {

// After  
Future<Response> endpoint(@RequestBody() Map data) async {
```

### Step 3: Add Request Info If You Need It

```dart
// Before
final method = request.method;
final path = request.url.path;

// After
@RequestMethod() String method,
@RequestPath() String path,
```

## 🎯 When to Use Each Annotation

| **Usage** | **Annotation** | **Example** |
|---------------|---------------|-------------|
| **Specific header** | `@RequestHeader('key')` | `@RequestHeader('Authorization') String token` |
| **All headers** | `@RequestHeader.all()` | `@RequestHeader.all() Map<String, String> headers` |
| **Specific query param** | `@QueryParam('key')` | `@QueryParam('page') int page` |
| **All query params** | `@QueryParam.all()` | `@QueryParam.all() Map<String, String> params` |
| **JWT payload** | `@RequestContext('jwt_payload')` | `@RequestContext('jwt_payload') Map jwt` |
| **Entire context** | `@RequestContext.all()` | `@RequestContext.all() Map context` |
| **HTTP method** | `@RequestMethod()` | `@RequestMethod() String method` |
| **Request path** | `@RequestPath()` | `@RequestPath() String path` |
| **Host info** | `@RequestHost()` | `@RequestHost() String host` |
| **Full URL** | `@RequestUrl()` | `@RequestUrl() Uri url` |

---

**🚀 With these improvements, api_kit eliminates the need for the `Request request` parameter in most cases, creating cleaner and more declarative code!**
