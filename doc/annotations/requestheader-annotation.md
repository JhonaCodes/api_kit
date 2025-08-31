# @RequestHeader - Annotation for Request Headers

## 📋 Description

The `@RequestHeader` annotation is used to capture and validate HTTP headers from incoming requests. It allows extracting specific values from headers and automatically converting them to method parameters.

## 🎯 Purpose

- **Custom authentication**: Capture tokens, API keys, or authentication headers
- **Request metadata**: Obtain information such as User-Agent, Accept-Language, etc.
- **Origin validation**: Verify security or identification headers
- **Response configuration**: Adapt the response according to client headers

## 📝 Syntax

### Specific Header (Traditional Method)
```dart
@RequestHeader(
  String name,                    // Header name (REQUIRED)
  {bool required = false,         // If the header is mandatory
   String? defaultValue,          // Default value if not provided
   String? description}           // Description of the header's purpose
)
```

### 🆕 All Headers (Enhanced Method)
```dart
@RequestHeader.all({
  bool required = false,          // If at least one header must be present
  String? description             // Description of the headers
})
// Returns: Map<String, String> with ALL HTTP headers
```

## 🔧 Parameters

### For `@RequestHeader('name')`
| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `name` | `String` | ✅ Yes | - | Exact name of the HTTP header (case-insensitive) |
| `required` | `bool` | ❌ No | `false` | If the header must be present in the request |
| `defaultValue` | `String?` | ❌ No | `null` | Value used when the header is not present |
| `description` | `String?` | ❌ No | `null` | Description of the purpose and expected format |

### 🆕 For `@RequestHeader.all()`
| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `false` | If there must be at least one HTTP header |
| `description` | `String?` | ❌ No | `'All HTTP headers as Map<String, String>'` | Description of all headers |

## 🚀 Usage Examples

### Basic Example - Authentication Header (Traditional Method)
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/profile')
  Future<Response> getUserProfile(
    Request request,
    @RequestHeader('Authorization', required: true, description: 'Bearer authentication token') 
    String authHeader,
  ) async {
    
    // Validate Authorization header format
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid authorization header format',
        'expected_format': 'Bearer <token>',
        'received': authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader
      }));
    }
    
    final token = authHeader.substring(7); // Remove "Bearer "
    
    // Validate token (simplified)
    if (token.length < 10) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid token',
        'token_length': token.length,
        'minimum_length_required': 10
      }));
    }
    
    return jsonResponse(jsonEncode({
      'message': 'User profile retrieved',
      'auth_header_processed': true,
      'token_valid': true,
      'user_id': 'user_from_token_${token.hashCode.abs()}',
    }));
  }
}
```

### 🆕 Basic Example - ALL Headers (Enhanced Method)
```dart
@RestController(basePath: '/api/users')  
class UserController extends BaseController {
  
  @Get(path: '/profile')
  Future<Response> getUserProfileEnhanced(
    @RequestHeader.all() Map<String, String> allHeaders,    // 🆕 ALL headers
    @RequestMethod() String method,                          // 🆕 Direct HTTP method
    @RequestPath() String path,                             // 🆕 Direct path
    @RequestHost() String host,                             // 🆕 Direct host
    // 🎉 NO Request request needed!
  ) async {
    
    // Extract specific header from the Map
    final authHeader = allHeaders['authorization'];
    
    if (authHeader == null) {
      return Response.unauthorized(jsonEncode({
        'error': 'Authorization header missing',
        'available_headers': allHeaders.keys.toList(),
        'auth_headers_found': allHeaders.keys
          .where((key) => key.toLowerCase().contains('auth'))
          .toList(),
      }));
    }
    
    // Validate Authorization header format
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid authorization header format',
        'expected_format': 'Bearer <token>',
        'received': authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader
      }));
    }
    
    final token = authHeader.substring(7);
    
    // Analyze other headers automatically
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final acceptLanguage = allHeaders['accept-language'] ?? 'en-US';
    final customHeaders = Map.fromEntries(
      allHeaders.entries.where((entry) => entry.key.startsWith('x-'))
    );
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced user profile retrieved',
      'framework_improvement': 'No manual Request parameter needed!',
      'request_info': {
        'method': method,              // Without request.method
        'path': path,                  // Without request.url.path  
        'host': host,                  // Without request.url.host
      },
      'auth_info': {
        'token_valid': true,
        'user_id': 'user_from_token_${token.hashCode.abs()}',
        'token_length': token.length,
      },
      'headers_analysis': {
        'total_headers': allHeaders.length,
        'all_headers': allHeaders,
        'user_agent': userAgent,
        'accept_language': acceptLanguage,
        'custom_headers': customHeaders,
        'auth_related': allHeaders.entries
          .where((entry) => entry.key.toLowerCase().contains('auth'))
          .map((entry) => '${entry.key}: ${entry.value.substring(0, 20)}...')
          .toList(),
      },
    }));
  }
}
```

**Testing Commands:**
```bash
# Specific header
curl -H "Authorization: Bearer abc123456789" http://localhost:8080/api/users/profile

# Multiple headers (🆕 Enhanced captures EVERYTHING)
curl -H "Authorization: Bearer abc123456789" \
     -H "User-Agent: MyApp/1.0" \
     -H "Accept-Language: es-ES,en;q=0.9" \
     -H "X-API-Key: key123" \
     -H "X-Client-Version: 2.1.0" \
     http://localhost:8080/api/users/profile
```

### Example of Multiple Required Headers (Traditional)
```dart
@Get(path: '/secure-data')
Future<Response> getSecureData(
  Request request,
  @RequestHeader('X-API-Key', required: true) String apiKey,
  @RequestHeader('X-Client-Version', required: true) String clientVersion,
  @RequestHeader('User-Agent', required: false, defaultValue: 'Unknown') String userAgent,
) async {
  
  // Validate API Key
  final validApiKeys = ['key123', 'key456', 'key789'];
  if (!validApiKeys.contains(apiKey)) {
    return Response.forbidden(jsonEncode({
      'error': 'Invalid API key',
      'api_key_received': apiKey.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey
    }));
  }
  
  // Validate client version
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
  if (!versionRegex.hasMatch(clientVersion)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid client version format',
      'expected_format': 'X.Y.Z (semantic version)',
      'received': clientVersion
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Secure data retrieved',
    'client_info': {
      'api_key_valid': true,
      'client_version': clientVersion,
      'user_agent': userAgent,
    },
    'data': ['secure_item_1', 'secure_item_2']
  }));
}
```

### 🆕 Example of Multiple Headers (Enhanced)
```dart
@Get(path: '/secure-data')
Future<Response> getSecureDataEnhanced(
  @RequestHeader.all() Map<String, String> allHeaders,     // 🆕 All headers
  @RequestMethod() String method,                          // 🆕 HTTP method
  @RequestUrl() Uri fullUrl,                              // 🆕 Full URL
  // NO Request request needed! 🎉
) async {
  
  // Extract required headers from the Map
  final apiKey = allHeaders['x-api-key'];
  final clientVersion = allHeaders['x-client-version'];
  final userAgent = allHeaders['user-agent'] ?? 'Unknown';
  
  // Validation of required headers
  final missingHeaders = <String>[];
  if (apiKey == null) missingHeaders.add('X-API-Key');
  if (clientVersion == null) missingHeaders.add('X-Client-Version');
  
  if (missingHeaders.isNotEmpty) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Required headers missing',
      'missing_headers': missingHeaders,
      'provided_headers': allHeaders.keys.toList(),
      'headers_analysis': {
        'total_provided': allHeaders.length,
        'required': ['X-API-Key', 'X-Client-Version'],
        'optional': ['User-Agent'],
      },
    }));
  }
  
  // Validate API Key  
  final validApiKeys = ['key123', 'key456', 'key789'];
  if (!validApiKeys.contains(apiKey)) {
    return Response.forbidden(jsonEncode({
      'error': 'Invalid API key',
      'api_key_received': apiKey!.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey
    }));
  }
  
  // Validate client version
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
  if (!versionRegex.hasMatch(clientVersion!)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid client version format',
      'expected_format': 'X.Y.Z (semantic version)',
      'received': clientVersion
    }));
  }
  
  // Analyze additional headers automatically
  final securityHeaders = Map.fromEntries(
    allHeaders.entries.where((entry) => 
      ['authorization', 'x-api-key', 'x-csrf-token', 'x-request-id']
        .contains(entry.key.toLowerCase()))
  );
  
  final customHeaders = Map.fromEntries(
    allHeaders.entries.where((entry) => entry.key.startsWith('x-'))
  );
  
  return jsonResponse(jsonEncode({
    'message': 'Enhanced secure data retrieved',
    'framework_improvement': 'All headers captured automatically!',
    'request_info': {
      'method': method,                 // Without request.method
      'full_url': fullUrl.toString(),   // Without request.url
    },
    'client_info': {
      'api_key_valid': true,
      'client_version': clientVersion,
      'user_agent': userAgent,
    },
    'headers_analysis': {
      'total_headers': allHeaders.length,
      'all_headers': allHeaders,
      'security_headers': securityHeaders,
      'custom_headers': customHeaders,
      'browser_info': {
        'user_agent': userAgent,
        'accept_language': allHeaders['accept-language'] ?? 'not provided',
        'accept_encoding': allHeaders['accept-encoding'] ?? 'not provided',
      },
    },
    'data': ['secure_item_1', 'secure_item_2'],
  }));
}
```

### Content Negotiation with Enhanced Headers
```dart
@Get(path: '/content')
Future<Response> getContentWithNegotiation(
  @RequestHeader.all() Map<String, String> allHeaders,     // 🆕 All headers
  @QueryParam.all() Map<String, String> allQueryParams,    // 🆕 All query params  
  @RequestPath() String path,                              // 🆕 Direct path
) async {
  
  // Content negotiation based on headers
  final accept = allHeaders['accept'] ?? 'application/json';
  final acceptLanguage = allHeaders['accept-language'] ?? 'en-US';
  final acceptEncoding = allHeaders['accept-encoding'] ?? '';
  
  // Determine response format
  final responseFormat = accept.contains('application/xml') ? 'xml' :
                        accept.contains('text/plain') ? 'text' : 'json';
  
  // Parse preferred language
  final languages = acceptLanguage.split(',').map((lang) {
    final parts = lang.trim().split(';');
    final code = parts[0].trim();
    final quality = parts.length > 1 ? 
      double.tryParse(parts[1].replaceAll('q=', '').trim()) ?? 1.0 : 1.0;
    return {'code': code, 'quality': quality};
  }).toList();
  
  languages.sort((a, b) => (b['quality'] as double).compareTo(a['quality'] as double));
  final preferredLanguage = languages.isNotEmpty ? languages.first['code'] as String : 'en-US';
  
  // Localized content
  final localizedContent = {
    'en-US': 'Welcome to our enhanced API',
    'es': 'Bienvenido a nuestra API mejorada',
    'fr': 'Bienvenue dans notre API améliorée',
    'de': 'Willkommen bei unserer verbesserten API',
  };
  
  final message = localizedContent[preferredLanguage.split('-').first] ?? 
                  localizedContent['en-US']!;
  
  // Response according to format
  final responseData = {
    'message': message,
    'content_negotiation': {
      'requested_format': responseFormat,
      'language': preferredLanguage,
      'compression': acceptEncoding.contains('gzip') ? 'gzip' : 'none',
    },
    'request_analysis': {
      'path': path,              // Without request.url.path
      'total_headers': allHeaders.length,
      'total_params': allQueryParams.length,
    },
    'headers_used': {
      'accept': accept,
      'accept_language': acceptLanguage,
      'accept_encoding': acceptEncoding,
    },
    'data': ['item1', 'item2', 'item3'],
  };
  
  // Return in the requested format
  if (responseFormat == 'xml') {
    return Response.ok(
      '<?xml version="1.0"?><response><message>$message</message></response>',
      headers: {'Content-Type': 'application/xml'}
    );
  } else if (responseFormat == 'text') {
    return Response.ok(
      message,
      headers: {'Content-Type': 'text/plain'}
    );
  }
  
  return jsonResponse(jsonEncode(responseData));
}
```

## 🎯 Common Use Cases

### 1. **Custom Authentication**
```dart
// Traditional
@RequestHeader('Authorization') String authToken,
@RequestHeader('X-API-Key') String apiKey,

// 🆕 Enhanced - captures all auth headers
@RequestHeader.all() Map<String, String> allHeaders,
// Allows: Authorization, X-API-Key, X-Auth-Token, Custom-Auth, etc.
```

### 2. **Client Information**
```dart
// Traditional
@RequestHeader('User-Agent') String userAgent,
@RequestHeader('Accept-Language') String language,

// 🆕 Enhanced - complete client information
@RequestHeader.all() Map<String, String> allHeaders,
// Allows: User-Agent, Accept-Language, Accept-Encoding, X-Forwarded-For, etc.
```

### 3. **Content Negotiation**
```dart
// Traditional
@RequestHeader('Accept') String accept,
@RequestHeader('Accept-Language') String acceptLang,
@RequestHeader('Accept-Encoding') String acceptEnc,

// 🆕 Enhanced - full content negotiation
@RequestHeader.all() Map<String, String> allHeaders,
// Allows: Accept, Accept-*, If-*, Cache-Control, etc.
```

### 4. **Security Headers**
```dart
// 🆕 Enhanced - full security analysis
@RequestHeader.all() Map<String, String> allHeaders,
// Allows: X-CSRF-Token, X-Forwarded-*, Origin, Referer, etc.
```

## ⚡ Advantages of the Enhanced Method

### ✅ Benefits
1. **Total Flexibility**: Capture any header without defining it beforehand
2. **Less Boilerplate**: You don't need `Request request`
3. **Dynamic Analysis**: Allows for headers you don't know at development time
4. **Improved Debugging**: You can see all headers in logs
5. **Content Negotiation**: Full access for content negotiation
6. **Security Analysis**: Access to all security headers

### ⚠️ Considerations
1. **Case Sensitivity**: Header names are case-insensitive (HTTP spec)
2. **Manual Validation**: You must validate presence and values manually
3. **Documentation**: Headers are not explicit in the function
4. **Type Safety**: All values come as String

## 🔄 Migration from Traditional to Enhanced

### Step 1: Replace individual headers
```dart
// Before
@RequestHeader('Authorization') String auth,
@RequestHeader('User-Agent') String userAgent,
@RequestHeader('Accept') String accept,

// After
@RequestHeader.all() Map<String, String> allHeaders,
```

### Step 2: Extract headers from the Map
```dart
// Extract specific headers (case-insensitive)
final auth = allHeaders['authorization'];
final userAgent = allHeaders['user-agent'] ?? 'unknown';
final accept = allHeaders['accept'] ?? 'application/json';
```

### Step 3: Remove Request parameter
```dart
// Before  
Future<Response> endpoint(Request request, @RequestHeader('x') String x) async {

// After
Future<Response> endpoint(@RequestHeader.all() Map<String, String> headers) async {
```

## 🎯 When to Use Each Method

| **Scenario** | **Traditional Method** | **Enhanced Method** | 
|---------------|------------------------|-------------------|
| **Known headers** | ✅ Explicit and clear | ⚠️ Less explicit |
| **Content negotiation** | ❌ Limited | ✅ Perfect |
| **Security analysis** | ❌ Limited headers | ✅ Full analysis |
| **Public APIs** | ✅ Clear documentation | ⚠️ Requires extra docs |
| **Debugging** | ❌ Limited headers | ✅ See all headers |
| **Prototyping** | ❌ More code | ✅ More flexible |

## 🔗 Combinations with Other Annotations

### With Enhanced Query Parameters
```dart
@Get(path: '/search')
Future<Response> searchWithFullContext(
  @RequestHeader.all() Map<String, String> allHeaders,
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestMethod() String method,
) async {
  // Full access to headers, params, and method
}
```

### With JWT Context
```dart
@Get(path: '/user-data')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserDataWithHeaders(
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  // Complete headers + direct JWT payload
}
```

### With Request Body
```dart
@Post(path: '/upload')
Future<Response> uploadWithMetadata(
  @RequestBody() Map<String, dynamic> fileData,
  @RequestHeader.all() Map<String, String> allHeaders,
) async {
  // Body data + complete headers (Content-Type, Content-Length, etc.)
}
```

### Complete Multi-Annotation Example
```dart
@Post(path: '/comprehensive')
@JWTEndpoint([MyUserValidator()])
Future<Response> comprehensiveEndpoint(
  @RequestBody() Map<String, dynamic> data,                // Request body
  @RequestHeader.all() Map<String, String> allHeaders,     // All headers
  @QueryParam.all() Map<String, String> allQueryParams,    // All params
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // JWT payload
  @RequestMethod() String method,                          // HTTP method
  @RequestUrl() Uri fullUrl,                              // Full URL
  // 🎉 Full access to ALL request information without manual Request!
) async {
  
  return jsonResponse(jsonEncode({
    'message': 'Comprehensive request processing',
    'complete_access': {
      'body_data': data,
      'all_headers': allHeaders,
      'all_query_params': allQueryParams,
      'jwt_user': jwt['user_id'],
      'method': method,
      'full_url': fullUrl.toString(),
    },
    'framework_achievement': 'Complete request access without manual Request parameter!',
  }));
}
```

---

**🚀 With @RequestHeader.all(), you have full access to all HTTP headers without needing to define them beforehand, eliminating the manual Request parameter and enabling dynamic header analysis!**
