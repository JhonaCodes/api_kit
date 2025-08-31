# 📚 api_kit - Complete Annotation-Based Documentation

Welcome to the complete documentation for **api_kit**! This documentation is organized by individual annotations with detailed usage examples and practical use cases.

## 🎯 Why This Documentation?

This documentation is designed so that **each annotation has its own file** with:
- ✅ **Detailed explanation** of what it does and why to use it
- ✅ **Complete syntax** with all parameters
- ✅ **Practical step-by-step examples**
- ✅ **Real-world use cases** with complete code
- ✅ **Best practices** and what to avoid
- ✅ **Combinations** with other annotations

## 🆕 **MAJOR UPDATE**: Enhanced Parameters - Eliminating Manual Request Handling

### 🎯 **New in this version: No more `Request` parameter!

**api_kit** now supports **enhanced parameters** that eliminate the need for the `Request request` parameter in most cases:

```dart
// ❌ BEFORE - Verbose with manual Request
@Get(path: 
'/users'
)
Future<Response> getUsers(
  Request request,  // ← Manual extraction needed
  @QueryParam(
'page'
)
 int page,
) async {
  final method = request.method;        // Manual
  final allHeaders = request.headers;   // Manual
  final jwt = request.context[
'jwt_payload'
];  // Manual
}

// ✅ NOW - Declarative without Request
@Get(path: 
'/users'
)
@JWTEndpoint([MyValidator()])
Future<Response> getUsersEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 ALL params
  @RequestHeader.all() Map<String, String> allHeaders,      // 🆕 ALL headers
  @RequestContext(
'jwt_payload'
) Map<String, dynamic> jwt,  // 🆕 Direct JWT
  @RequestMethod() String method,                           // 🆕 Direct Method
  // 🎉 NO Request request needed!
) async {
  // Everything available directly - no manual extractions
}
```

### 🚀 **New Enhanced Annotations:**
- **`@RequestHeader.all()`** - All headers as `Map<String, String>`
- **`@QueryParam.all()`** - All query params as `Map<String, String>`
- **`@RequestMethod()`** - Direct HTTP method (GET, POST, etc.)
- **`@RequestPath()`** - Direct request path
- **`@RequestHost()`** - Direct host
- **`@RequestUrl()`** - Full URL as `Uri`
- **`@RequestContext()`** - Specific or complete request context

### 🎯 **Immediate Benefits:**
- ✅ **Less boilerplate**: No more mandatory `Request request`
- ✅ **More declarative**: Annotations express exactly what you need
- ✅ **Dynamic filters**: Capture parameters you don't know at development time
- ✅ **Better debugging**: Full access to all parameters and headers
- ✅ **Improved JWT**: No more manual `request.context[
'jwt_payload'
]`
- ✅ **Compatible**: Existing code continues to work without changes

## 🚀 Quick Start

### 1. Installation
```yaml
dependencies:
  api_kit: ^0.0.5
```

### 2. Basic Example
```dart
@RestController(basePath: 
'/api/hello'
)
class HelloController extends BaseController {

  @Get(path: 
'/world'
)
  @JWTPublic()
  Future<Response> sayHello() async {
    return ApiKit.ok({"message": "Hello World!"}).toHttpResponse();
  }
}

void main() async {
  final server = ApiServer(config: ServerConfig.development());
  await server.start(
    host: 
'localhost'
,
    port: 8080,
  );
}
```

### 3. With JWT Authentication
```dart
@RestController(basePath: 
'/api/users'
)
class UserController extends BaseController {

  @Get(path: 
'/profile'
)
  @JWTEndpoint([MyUserValidator()])
  Future<Response> getProfile(
    @RequestContext(
'jwt_payload'
) Map<String, dynamic> jwt,
  ) async {
    return ApiKit.ok({
'user_id'
: jwt[
'user_id'
]}).toHttpResponse();
  }
}
```

---

## 📖 Documentation by Annotation

### 🌐 HTTP Methods - HTTP Method Annotations

| Annotation | Purpose | Complete Documentation |
|-----------|-----------|----------------------|
| **`@Get`** | GET endpoints for queries | [`docs/annotations/get-annotation.md`](annotations/get-annotation.md) |
| **`@Post`** | POST endpoints for creation | [`docs/annotations/post-annotation.md`](annotations/post-annotation.md) |
| **`@Put`** | PUT endpoints for full updates | [`docs/annotations/put-annotation.md`](annotations/put-annotation.md) |
| **`@Patch`** | PATCH endpoints for partial updates | [`docs/annotations/patch-annotation.md`](annotations/patch-annotation.md) |
| **`@Delete`** | DELETE endpoints for deletion | [`docs/annotations/delete-annotation.md`](annotations/delete-annotation.md) |

### 🏗️ Controllers - Structure Annotations

| Annotation | Purpose | Complete Documentation |
|-----------|-----------|----------------------|
| **`@RestController`** | Defines REST controllers with a basePath | [`docs/annotations/restcontroller-annotation.md`](annotations/restcontroller-annotation.md) |

### 📥 Parameters - Parameter Annotations

| Annotation | Purpose | Complete Documentation |
|-----------|-----------|----------------------|
| **`@PathParam`** | Captures URL parameters (`/users/{id}`) | [`docs/annotations/pathparam-annotation.md`](annotations/pathparam-annotation.md) |
| **`@QueryParam`** | Captures query parameters (`?page=1&limit=10`) | [`docs/annotations/queryparam-annotation.md`](annotations/queryparam-annotation.md) |
| **`@RequestBody`** | Captures and parses the request body | [`docs/annotations/requestbody-annotation.md`](annotations/requestbody-annotation.md) |
| **`@RequestHeader`** | Captures specific HTTP headers | [`docs/annotations/requestheader-annotation.md`](annotations/requestheader-annotation.md) |
| **🆕 `@RequestHeader.all()`** | **Captures ALL headers as a Map** | [`docs/annotations/enhanced-parameters-annotation.md#requestheaderall`](annotations/enhanced-parameters-annotation.md#requestheaderall) |
| **🆕 `@QueryParam.all()`** | **Captures ALL query params as a Map** | [`docs/annotations/enhanced-parameters-annotation.md#queryparamall`](annotations/enhanced-parameters-annotation.md#queryparamall) |

### 🆕 Request Components - New Request Annotations

| Annotation | Purpose | Complete Documentation |
|-----------|-----------|----------------------|
| **🆕 `@RequestMethod()`** | **Direct HTTP method (GET, POST, etc.)** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestPath()`** | **Direct request path** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestHost()`** | **Direct request host** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestUrl()`** | **Direct full URL as Uri** | [`docs/annotations/enhanced-parameters-annotation.md#request-components`](annotations/enhanced-parameters-annotation.md#request-components) |
| **🆕 `@RequestContext()`** | **Specific or complete request context** | [`docs/annotations/enhanced-parameters-annotation.md#request-context`](annotations/enhanced-parameters-annotation.md#request-context) |

### 🔐 JWT Security - Authentication Annotations

| Annotation | Purpose | Complete Documentation |
|-----------|-----------|----------------------|
| **`@JWTPublic`** | Marks endpoints as public (no auth) | [`docs/annotations/jwt-annotations.md#jwtpublic---public-endpoint`](annotations/jwt-annotations.md#jwtpublic---public-endpoint) |
| **`@JWTController`** | Applies JWT validation to the entire controller | [`docs/annotations/jwt-annotations.md#jwtcontroller---controller-level-validation`](annotations/jwt-annotations.md#jwtcontroller---controller-level-validation) |
| **`@JWTEndpoint`** | Endpoint-specific JWT validation | [`docs/annotations/jwt-annotations.md#jwtendpoint---endpoint-specific-validation`](annotations/jwt-annotations.md#jwtendpoint---endpoint-specific-validation) |

---

## 🎯 Complete Use Cases

### 📋 Documented Use Cases

| Use Case | Description | Documentation |
|-------------|-------------|---------------|
| **Complete CRUD API** | A complete product system with multi-level authentication | [`docs/use-cases/complete-crud-api.md`](use-cases/complete-crud-api.md) |
| **Framework Limitations** | Analysis of current limitations and suggested evolution | [`docs/use-cases/framework-limitations.md`](use-cases/framework-limitations.md) |

---

## 🔧 Examples by Complexity

### 🟢 Basic - First Endpoint
```dart
@RestController(basePath: 
'/api'
)
class SimpleController extends BaseController {

  @Get(path: 
'/hello'
)
  @JWTPublic()
  Future<Response> hello(Request request) async {
    return jsonResponse(
'{"message": "Hello api_kit!"}'
);
  }
}
```
**→ See more at**: [`@Get`](annotations/get-annotation.md#basic-example)

### 🟡 Intermediate - With Parameters (Traditional Method)
```dart
@Get(path: 
'/users/{userId}/posts'
)
Future<Response> getUserPosts(
  Request request,
  @PathParam(
'userId'
) String userId,
  @QueryParam(
'page'
, defaultValue: 1) int page,
  @QueryParam(
'limit'
, defaultValue: 10) int limit,
) async {
  return jsonResponse(jsonEncode({
    
'user_id'
: userId,
    
'posts'
: [],
    
'page'
: page,
    
'limit'
: limit
  }));
}
```

### 🟡 Intermediate - With Enhanced Parameters (🆕 New)
```dart
@Get(path: 
'/users/{userId}/posts'
)
Future<Response> getUserPostsEnhanced(
  @PathParam(
'userId'
) String userId,
  @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL query params
  @RequestMethod() String method,                        // 🆕 Direct HTTP method
  @RequestPath() String path,                           // 🆕 Direct path
) async {
  final page = int.tryParse(allQueryParams[
'page'
] ?? 
'1'
) ?? 1;
  final limit = int.tryParse(allQueryParams[
'limit'
] ?? 
'10'
) ?? 10;

  return jsonResponse(jsonEncode({
    
'user_id'
: userId,
    
'posts'
: [],
    
'page'
: page,
    
'limit'
: limit,
    
'method'
: method,           // Without request.method
    
'path'
: path,               // Without request.url.path
    
'all_filters'
: allQueryParams.entries
      .where((e) => e.key.startsWith(
'filter_'
))
      .map((e) => 
'${e.key}: ${e.value}'
)
      .toList(),
  }));
}
```
**→ See more at**: [`Enhanced Parameters`](annotations/enhanced-parameters-annotation.md)

### 🔴 Advanced - With JWT and Validation (Traditional Method)
```dart
@Post(path: 
'/financial/transfer'
)
@JWTEndpoint([
  MyFinancialValidator(clearanceLevel: 3),
  MyBusinessHoursValidator(),
], requireAll: true)
Future<Response> createTransfer(
  Request request,
  @RequestBody(required: true) Map<String, dynamic> transferData,
  @RequestHeader(
'X-Two-Factor-Token'
, required: true) String tfaToken,
) async {
  final jwt = request.context[
'jwt_payload'
] as Map<String, dynamic>;
  // Transfer logic...
  return jsonResponse(jsonEncode({
'transfer_id'
: 
'txn_123'
}));
}
```

### 🔴 Advanced - Enhanced JWT WITHOUT Manual Request (🆕 New)
```dart
@Post(path: 
'/financial/transfer'
)
@JWTEndpoint([
  MyFinancialValidator(clearanceLevel: 3),
  MyBusinessHoursValidator(),
], requireAll: true)
Future<Response> createTransferEnhanced(
  @RequestBody() Map<String, dynamic> transferData,                     // Request body
  @RequestContext(
'jwt_payload'
) Map<String, dynamic> jwt,              // 🆕 Direct JWT
  @RequestHeader.all() Map<String, String> allHeaders,                  // 🆕 All headers
  @RequestHeader(
'X-Two-Factor-Token'
) String tfaToken,                 // Specific header
  @RequestMethod() String method,                                       // 🆕 HTTP method
  @RequestUrl() Uri fullUrl,                                           // 🆕 Full URL
  // 🎉 NO Request request needed!
) async {
  final userId = jwt[
'user_id'
];        // Without request.context[
'jwt_payload'
]
  final userAgent = allHeaders[
'user-agent'
] ?? 
'unknown'
;

  return jsonResponse(jsonEncode({
    
'transfer_id'
: 
'txn_${DateTime.now().millisecondsSinceEpoch}'
,
    
'user_id'
: userId,
    
'method'
: method,               // Without request.method
    
'url'
: fullUrl.toString(),      // Without request.url
    
'user_agent'
: userAgent,
    
'two_factor_provided'
: tfaToken.isNotEmpty,
    
'framework_improvement'
: 
'No manual Request parameter needed!'
,
  }));
}
```
**→ See more at**: [`Enhanced Parameters`](annotations/enhanced-parameters-annotation.md), [JWT Annotations](annotations/jwt-annotations.md) and [CRUD Use Case](use-cases/complete-crud-api.md)

---

## 🛠️ Server Configuration

### Basic Configuration
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.development());

  await server.start(
    host: 
'localhost'
,
    port: 8080,
  );
}
```

### Configuration with JWT
```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());

  // Configure JWT
  server.configureJWTAuth(
    jwtSecret: 
'your-256-bit-secret-key'
,
    excludePaths: [
'/api/public'
, 
'/health'
],
  );

  await server.start(
    host: 
'0.0.0.0'
,
    port: 8080,
  );
}
```

---

## 🎨 Common Design Patterns

### 1. **Simple Public Endpoint**
```dart
@Get(path: 
'/info'
)
@JWTPublic()
Future<Response> getInfo() async {
  return ApiKit.ok({
'info'
: 
'public endpoint'
}).toHttpResponse();
}
```

### 2. **CRUD with Authentication**
```dart
@RestController(basePath: 
'/api/products'
)
@JWTController([UserValidator()])
class ProductController extends BaseController {

  @Get(path: 
''
) // List - inherits auth from controller
  @Post(path: 
''
) // Create - inherits auth from controller  
  @Put(path: 
'/{id}'
) // Update - inherits auth from controller
  @Delete(path: 
'/{id}'
) 
  @JWTEndpoint([AdminValidator()]) // Delete requires specific admin auth
}
```

### 3. **Multi-level Validation**
```dart
@JWTEndpoint([
  BasicUserValidator(),        // Must be a valid user
  FinancialValidator(),       // Must have financial permissions
  BusinessHoursValidator(),   // Only during business hours
], requireAll: true)          // ALL must pass
```

### 4. **Content Negotiation**
```dart
@Get(path: 
'/report/{id}'
)
Future<Response> getReport(
  @PathParam(
'id'
) String reportId,
  @RequestHeader(
'Accept'
, defaultValue: 
'application/json'
) String format,
) async {
  if (format.contains(
'application/pdf'
)) {
    return Response.ok(pdfData, headers: {
'Content-Type'
: 
'application/pdf'
});
  }
  return ApiKit.ok(reportData).toHttpResponse();
}
```

---

## ❓ FAQ and Known Limitations

### ❓ Why do I need `Request request` if I already have `@RequestBody`?

**Answer**: You don't need it anymore! With the new enhanced parameters:

```dart
// ✅ Current state (already implemented)
@Post(path: 
'/users'
)
Future<Response> createUser(
  @RequestBody() Map<String, dynamic> data,
  @RequestContext(
'jwt_payload'
) Map<String, dynamic> jwt, // ← Available now!
) async {
  return ApiKit.ok({
'user_created'
: data[
'name'
], 
'by'
: jwt[
'user_id'
]}).toHttpResponse();
}

// ❌ No longer necessary (obsolete)
@Post(path: 
'/users'
)
Future<Response> createUserOld(
  Request request,  // ← No longer necessary
  @RequestBody() Map<String, dynamic> data,
) async {
  final jwt = request.context[
'jwt_payload'
]; // ← Manual extraction is obsolete
}
```

### ❓ Why do I need to extract JWT if I already used `@JWTEndpoint`?

**Answer**: This is already solved! With `@RequestContext(
'jwt_payload'
)`:

```dart
// ✅ Current state (already works)
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUser(
  @RequestBody() Map<String, dynamic> data,
  @RequestContext(
'jwt_payload'
) Map<String, dynamic> jwt, // ← Automatic!
) async {
  return ApiKit.ok({
'updated'
: data[
'id'
], 
'by'
: jwt[
'user_id'
]}).toHttpResponse();
}

// ❌ No longer necessary (obsolete)
@JWTEndpoint([MyUserValidator()])
Future<Response> updateUserOld(Request request) async {
  final jwt = request.context[
'jwt_payload'
]; // ← Manual and obsolete
}
```

**→ See full analysis**: [Framework Limitations](use-cases/framework-limitations.md)

### ❓ Can JWT validators access the request body?

**Answer**: Currently, no. Validators only have access to `Request` and `jwtPayload`. In the future, they might have access to the entire context.

### ❓ How do I handle validation errors consistently?

**Answer**: Use the standard error response pattern:

```dart
return ApiKit.err(ApiErr(
  code: 
'VALIDATION_ERROR'
,
  message: 
'Error description'
,
  details: {
    
'validation_errors'
: [
'List'
, 
'of'
, 
'errors'
],
    
'received_data'
: receivedData,
    
'expected_format'
: 
'Expected format'
  },
)).toHttpResponse();
```

---

## 🚀 Next Steps

### For Beginners
1. **Read**: [`@Get` annotation](annotations/get-annotation.md) - The most basic endpoint
2. **Read**: [`@RestController`](annotations/restcontroller-annotation.md) - Organize endpoints
3. **Practice**: Create a simple public endpoint
4. **Read**: [JWT Annotations](annotations/jwt-annotations.md) - Add security

### For Intermediate Users
1. **Read**: [`@RequestBody`](annotations/requestbody-annotation.md) - Handle POST/PUT data
2. **Read**: [`@QueryParam`](annotations/queryparam-annotation.md) - Filters and pagination
3. **Practice**: [Complete CRUD Use Case](use-cases/complete-crud-api.md)

### For Advanced Users
1. **Create custom JWT validators**
2. **Implement complex authentication systems**
3. **Optimize performance and structure**
4. **Contribute to the framework** based on [identified limitations](use-cases/framework-limitations.md)

---

## 🤝 Contributing to the Documentation

Found something unclear? Have an interesting use case? Identified limitations like those mentioned in [`framework-limitations.md`](use-cases/framework-limitations.md)?

### Documentation Structure
```
docs/
├── README.md                          # This file - main navigation
├── annotations/                       # One annotation = One file
│   ├── get-annotation.md
│   ├── post-annotation.md
│   ├── restcontroller-annotation.md
│   ├── pathparam-annotation.md
│   ├── queryparam-annotation.md
│   ├── requestbody-annotation.md
│   ├── requestheader-annotation.md
│   └── jwt-annotations.md
└── use-cases/                        # Complete use cases
    ├── complete-crud-api.md
    └── framework-limitations.md
```

Each file follows the same pattern:
- **Description** and purpose
- **Complete syntax**
- **Step-by-step examples**
- **Combinations** with other annotations
- **Best practices**
- **Real-world use cases**

---

## 📞 Support

- **Framework Documentation**: This documentation
- **Live Examples**: `/example` directory in the repository
- **Issues and bugs**: GitHub issues for the api_kit repository
- **Known Limitations**: [`framework-limitations.md`](use-cases/framework-limitations.md)

---

**🚀 Happy coding with api_kit!**

> This documentation is designed to grow with you: from your first endpoint to complex enterprise APIs with multiple authentication levels.
