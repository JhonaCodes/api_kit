# @RequestHeader - Anotación para Headers de Request

## 📋 Descripción

La anotación `@RequestHeader` se utiliza para capturar y validar headers HTTP de las peticiones entrantes. Permite extraer valores específicos de los headers y convertirlos automáticamente a parámetros de método.

## 🎯 Propósito

- **Autenticación personalizada**: Capturar tokens, API keys, o headers de autenticación
- **Metadatos de request**: Obtener información como User-Agent, Accept-Language, etc.
- **Validación de origen**: Verificar headers de seguridad o identificación
- **Configuración de respuesta**: Adaptar respuesta según headers del cliente

## 📝 Sintaxis

### Header Específico (Método Tradicional)
```dart
@RequestHeader(
  String name,                    // Nombre del header (OBLIGATORIO)
  {bool required = false,         // Si el header es obligatorio
   String? defaultValue,          // Valor por defecto si no se proporciona
   String? description}           // Descripción del propósito del header
)
```

### 🆕 Todos los Headers (Método Enhanced)
```dart
@RequestHeader.all({
  bool required = false,          // Si debe haber al menos un header
  String? description             // Descripción de los headers
})
// Retorna: Map<String, String> con TODOS los headers HTTP
```

## 🔧 Parámetros

### Para `@RequestHeader('name')`
| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `name` | `String` | ✅ Sí | - | Nombre exacto del header HTTP (case-insensitive) |
| `required` | `bool` | ❌ No | `false` | Si el header debe estar presente en la request |
| `defaultValue` | `String?` | ❌ No | `null` | Valor usado cuando el header no está presente |
| `description` | `String?` | ❌ No | `null` | Descripción del propósito y formato esperado |

### 🆕 Para `@RequestHeader.all()`
| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `false` | Si debe haber al menos un header HTTP |
| `description` | `String?` | ❌ No | `'All HTTP headers as Map<String, String>'` | Descripción de todos los headers |

## 🚀 Ejemplos de Uso

### Ejemplo Básico - Header de Autenticación (Método Tradicional)
```dart
@RestController(basePath: '/api/users')
class UserController extends BaseController {
  
  @Get(path: '/profile')
  Future<Response> getUserProfile(
    Request request,
    @RequestHeader('Authorization', required: true, description: 'Bearer token de autenticación') 
    String authHeader,
  ) async {
    
    // Validar formato del header Authorization
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid authorization header format',
        'expected_format': 'Bearer <token>',
        'received': authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader
      }));
    }
    
    final token = authHeader.substring(7); // Remover "Bearer "
    
    // Validar token (simplificado)
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

### 🆕 Ejemplo Básico - TODOS los Headers (Método Enhanced)
```dart
@RestController(basePath: '/api/users')  
class UserController extends BaseController {
  
  @Get(path: '/profile')
  Future<Response> getUserProfileEnhanced(
    @RequestHeader.all() Map<String, String> allHeaders,    // 🆕 TODOS los headers
    @RequestMethod() String method,                          // 🆕 Método HTTP directo
    @RequestPath() String path,                             // 🆕 Path directo
    @RequestHost() String host,                             // 🆕 Host directo
    // 🎉 NO Request request needed!
  ) async {
    
    // Extraer header específico del Map
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
    
    // Validar formato del header Authorization
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid authorization header format',
        'expected_format': 'Bearer <token>',
        'received': authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader
      }));
    }
    
    final token = authHeader.substring(7);
    
    // Analizar otros headers automáticamente
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final acceptLanguage = allHeaders['accept-language'] ?? 'en-US';
    final customHeaders = Map.fromEntries(
      allHeaders.entries.where((entry) => entry.key.startsWith('x-'))
    );
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced user profile retrieved',
      'framework_improvement': 'No manual Request parameter needed!',
      'request_info': {
        'method': method,              // Sin request.method
        'path': path,                  // Sin request.url.path  
        'host': host,                  // Sin request.url.host
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
# Header específico
curl -H "Authorization: Bearer abc123456789" http://localhost:8080/api/users/profile

# Múltiples headers (🆕 Enhanced captura TODO)
curl -H "Authorization: Bearer abc123456789" \
     -H "User-Agent: MyApp/1.0" \
     -H "Accept-Language: es-ES,en;q=0.9" \
     -H "X-API-Key: key123" \
     -H "X-Client-Version: 2.1.0" \
     http://localhost:8080/api/users/profile
```

### Ejemplo de Múltiples Headers Requeridos (Tradicional)
```dart
@Get(path: '/secure-data')
Future<Response> getSecureData(
  Request request,
  @RequestHeader('X-API-Key', required: true) String apiKey,
  @RequestHeader('X-Client-Version', required: true) String clientVersion,
  @RequestHeader('User-Agent', required: false, defaultValue: 'Unknown') String userAgent,
) async {
  
  // Validar API Key
  final validApiKeys = ['key123', 'key456', 'key789'];
  if (!validApiKeys.contains(apiKey)) {
    return Response.forbidden(jsonEncode({
      'error': 'Invalid API key',
      'api_key_received': apiKey.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey
    }));
  }
  
  // Validar versión del cliente
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

### 🆕 Ejemplo de Múltiples Headers (Enhanced)
```dart
@Get(path: '/secure-data')
Future<Response> getSecureDataEnhanced(
  @RequestHeader.all() Map<String, String> allHeaders,     // 🆕 Todos los headers
  @RequestMethod() String method,                          // 🆕 Método HTTP
  @RequestUrl() Uri fullUrl,                              // 🆕 URL completa
  // NO Request request needed! 🎉
) async {
  
  // Extraer headers requeridos del Map
  final apiKey = allHeaders['x-api-key'];
  final clientVersion = allHeaders['x-client-version'];
  final userAgent = allHeaders['user-agent'] ?? 'Unknown';
  
  // Validación de headers requeridos
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
  
  // Validar API Key  
  final validApiKeys = ['key123', 'key456', 'key789'];
  if (!validApiKeys.contains(apiKey)) {
    return Response.forbidden(jsonEncode({
      'error': 'Invalid API key',
      'api_key_received': apiKey!.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey
    }));
  }
  
  // Validar versión del cliente
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
  if (!versionRegex.hasMatch(clientVersion!)) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid client version format',
      'expected_format': 'X.Y.Z (semantic version)',
      'received': clientVersion
    }));
  }
  
  // Analizar headers adicionales automáticamente
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
      'method': method,                 // Sin request.method
      'full_url': fullUrl.toString(),   // Sin request.url
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

### Content Negotiation con Enhanced Headers
```dart
@Get(path: '/content')
Future<Response> getContentWithNegotiation(
  @RequestHeader.all() Map<String, String> allHeaders,     // 🆕 Todos los headers
  @QueryParam.all() Map<String, String> allQueryParams,    // 🆕 Todos los query params  
  @RequestPath() String path,                              // 🆕 Path directo
) async {
  
  // Content negotiation basado en headers
  final accept = allHeaders['accept'] ?? 'application/json';
  final acceptLanguage = allHeaders['accept-language'] ?? 'en-US';
  final acceptEncoding = allHeaders['accept-encoding'] ?? '';
  
  // Determinar formato de respuesta
  final responseFormat = accept.contains('application/xml') ? 'xml' :
                        accept.contains('text/plain') ? 'text' : 'json';
  
  // Parsear idioma preferido
  final languages = acceptLanguage.split(',').map((lang) {
    final parts = lang.trim().split(';');
    final code = parts[0].trim();
    final quality = parts.length > 1 ? 
      double.tryParse(parts[1].replaceAll('q=', '').trim()) ?? 1.0 : 1.0;
    return {'code': code, 'quality': quality};
  }).toList();
  
  languages.sort((a, b) => (b['quality'] as double).compareTo(a['quality'] as double));
  final preferredLanguage = languages.isNotEmpty ? languages.first['code'] as String : 'en-US';
  
  // Contenido localizado
  final localizedContent = {
    'en-US': 'Welcome to our enhanced API',
    'es': 'Bienvenido a nuestra API mejorada',
    'fr': 'Bienvenue dans notre API améliorée',
    'de': 'Willkommen bei unserer verbesserten API',
  };
  
  final message = localizedContent[preferredLanguage.split('-').first] ?? 
                  localizedContent['en-US']!;
  
  // Respuesta según formato
  final responseData = {
    'message': message,
    'content_negotiation': {
      'requested_format': responseFormat,
      'language': preferredLanguage,
      'compression': acceptEncoding.contains('gzip') ? 'gzip' : 'none',
    },
    'request_analysis': {
      'path': path,              // Sin request.url.path
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
  
  // Retornar en el formato solicitado
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

## 🎯 Casos de Uso Comunes

### 1. **Autenticación Personalizada**
```dart
// Tradicional
@RequestHeader('Authorization') String authToken,
@RequestHeader('X-API-Key') String apiKey,

// 🆕 Enhanced - captura todos los headers de auth
@RequestHeader.all() Map<String, String> allHeaders,
// Permite: Authorization, X-API-Key, X-Auth-Token, Custom-Auth, etc.
```

### 2. **Información del Cliente**
```dart
// Tradicional
@RequestHeader('User-Agent') String userAgent,
@RequestHeader('Accept-Language') String language,

// 🆕 Enhanced - información completa del cliente
@RequestHeader.all() Map<String, String> allHeaders,
// Permite: User-Agent, Accept-Language, Accept-Encoding, X-Forwarded-For, etc.
```

### 3. **Content Negotiation**
```dart
// Tradicional
@RequestHeader('Accept') String accept,
@RequestHeader('Accept-Language') String acceptLang,
@RequestHeader('Accept-Encoding') String acceptEnc,

// 🆕 Enhanced - negociación completa de contenido
@RequestHeader.all() Map<String, String> allHeaders,
// Permite: Accept, Accept-*, If-*, Cache-Control, etc.
```

### 4. **Headers de Seguridad**
```dart
// 🆕 Enhanced - análisis completo de seguridad
@RequestHeader.all() Map<String, String> allHeaders,
// Permite: X-CSRF-Token, X-Forwarded-*, Origin, Referer, etc.
```

## ⚡ Ventajas del Método Enhanced

### ✅ Beneficios
1. **Flexibilidad Total**: Captura cualquier header sin definirlo previamente
2. **Menos Boilerplate**: No necesitas `Request request`
3. **Análisis Dinámico**: Permite headers que no conoces en desarrollo
4. **Mejor Debugging**: Puedes ver todos los headers en logs
5. **Content Negotiation**: Acceso completo para negociación de contenido
6. **Análisis de Seguridad**: Acceso a todos los headers de seguridad

### ⚠️ Consideraciones
1. **Case Sensitivity**: Los nombres de headers son case-insensitive (HTTP spec)
2. **Validación Manual**: Debes validar presencia y valores manualmente
3. **Documentación**: Los headers no están explícitos en la función
4. **Type Safety**: Todos los valores vienen como String

## 🔄 Migración de Tradicional a Enhanced

### Paso 1: Reemplazar headers individuales
```dart
// Antes
@RequestHeader('Authorization') String auth,
@RequestHeader('User-Agent') String userAgent,
@RequestHeader('Accept') String accept,

// Después
@RequestHeader.all() Map<String, String> allHeaders,
```

### Paso 2: Extraer headers del Map
```dart
// Extraer headers específicos (case-insensitive)
final auth = allHeaders['authorization'];
final userAgent = allHeaders['user-agent'] ?? 'unknown';
final accept = allHeaders['accept'] ?? 'application/json';
```

### Paso 3: Eliminar Request parameter
```dart
// Antes  
Future<Response> endpoint(Request request, @RequestHeader('x') String x) async {

// Después
Future<Response> endpoint(@RequestHeader.all() Map<String, String> headers) async {
```

## 🎯 Cuándo Usar Cada Método

| **Escenario** | **Método Tradicional** | **Método Enhanced** |
|---------------|------------------------|-------------------|
| **Headers conocidos** | ✅ Explícito y claro | ⚠️ Menos explícito |
| **Content negotiation** | ❌ Limitado | ✅ Perfecto |
| **Análisis de seguridad** | ❌ Headers limitados | ✅ Análisis completo |
| **APIs públicas** | ✅ Documentación clara | ⚠️ Requiere docs extra |
| **Debugging** | ❌ Headers limitados | ✅ Ve todos los headers |
| **Prototipado** | ❌ Más código | ✅ Más flexible |

## 🔗 Combinaciones con Otras Anotaciones

### Con Query Parameters Enhanced
```dart
@Get(path: '/search')
Future<Response> searchWithFullContext(
  @RequestHeader.all() Map<String, String> allHeaders,
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestMethod() String method,
) async {
  // Acceso completo a headers, params y método
}
```

### Con JWT Context
```dart
@Get(path: '/user-data')
@JWTEndpoint([MyUserValidator()])
Future<Response> getUserDataWithHeaders(
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  // Headers completos + JWT payload directo
}
```

### Con Request Body
```dart
@Post(path: '/upload')
Future<Response> uploadWithMetadata(
  @RequestBody() Map<String, dynamic> fileData,
  @RequestHeader.all() Map<String, String> allHeaders,
) async {
  // Body data + headers completos (Content-Type, Content-Length, etc.)
}
```

### Ejemplo Completo Multi-Anotación
```dart
@Post(path: '/comprehensive')
@JWTEndpoint([MyUserValidator()])
Future<Response> comprehensiveEndpoint(
  @RequestBody() Map<String, dynamic> data,                // Request body
  @RequestHeader.all() Map<String, String> allHeaders,     // Todos los headers
  @QueryParam.all() Map<String, String> allQueryParams,    // Todos los params
  @RequestContext('jwt_payload') Map<String, dynamic> jwt, // JWT payload
  @RequestMethod() String method,                          // HTTP method
  @RequestUrl() Uri fullUrl,                              // URL completa
  // 🎉 Acceso completo a TODA la información del request sin manual Request!
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

**🚀 Con @RequestHeader.all(), tienes acceso completo a todos los headers HTTP sin necesidad de definirlos previamente, eliminando el parámetro Request manual y habilitando análisis dinámico de headers!**