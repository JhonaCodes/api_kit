# 🛡️ Middlewares

Los **middlewares** son funciones que se ejecutan antes o después de los endpoints. Permiten implementar funcionalidades transversales como autenticación, logging, CORS, validación, etc.

## 🎯 Tipos de Middlewares

### 1. **Seguridad** - Authentication, Authorization, CORS
### 2. **Logging** - Request/Response logging, Performance
### 3. **Validación** - Input validation, Rate limiting
### 4. **Transformación** - Data formatting, Compression
### 5. **Error Handling** - Exception handling, Error formatting

---

## 🔐 1. Middleware de Autenticación JWT

```dart
// middleware/auth_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

class AuthMiddleware {
  // Middleware para verificar JWT token
  static Middleware jwtAuth() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          // Verificar si la ruta requiere autenticación
          if (_isPublicRoute(request.requestedUri.path)) {
            return await innerHandler(request);
          }
          
          // Extraer token del header Authorization
          final authHeader = request.headers['authorization'];
          if (authHeader == null || !authHeader.startsWith('Bearer ')) {
            return _unauthorizedResponse('Authorization header missing or invalid');
          }
          
          final token = authHeader.substring(7); // Remover "Bearer "
          
          // Validar token (en producción usarías una librería JWT real)
          final payload = _validateJwtToken(token);
          if (payload == null) {
            return _unauthorizedResponse('Invalid or expired token');
          }
          
          // Agregar información del usuario al request
          final updatedRequest = request.change(context: {
            'user_id': payload['user_id'],
            'user_email': payload['email'],
            'user_role': payload['role'],
            'token_expires': payload['exp'],
          });
          
          print('🔐 Authenticated user: ${payload['email']} (${payload['role']})');
          
          return await innerHandler(updatedRequest);
          
        } catch (e) {
          print('❌ Auth middleware error: $e');
          return _unauthorizedResponse('Authentication failed');
        }
      };
    };
  }
  
  // Middleware para verificar roles específicos
  static Middleware requireRole(List<String> allowedRoles) {
    return (Handler innerHandler) {
      return (Request request) async {
        final userRole = request.context['user_role'] as String?;
        
        if (userRole == null) {
          return _forbiddenResponse('Authentication required');
        }
        
        if (!allowedRoles.contains(userRole)) {
          return _forbiddenResponse('Insufficient permissions. Required: ${allowedRoles.join(' or ')}');
        }
        
        print('✅ Role check passed: $userRole');
        return await innerHandler(request);
      };
    };
  }
  
  // Middleware para verificar ownership (usuario puede acceder solo a sus recursos)
  static Middleware requireOwnership() {
    return (Handler innerHandler) {
      return (Request request) async {
        final userId = request.context['user_id'] as String?;
        final userRole = request.context['user_role'] as String?;
        
        // Admin puede acceder a todo
        if (userRole == 'admin') {
          return await innerHandler(request);
        }
        
        // Extraer ID del recurso de la URL
        final resourceId = _extractResourceId(request.requestedUri.path);
        
        // Verificar ownership (simplificado)
        if (userId != null && resourceId != null && userId == resourceId) {
          return await innerHandler(request);
        }
        
        return _forbiddenResponse('You can only access your own resources');
      };
    };
  }
  
  // Verificar si la ruta es pública (no requiere autenticación)
  static bool _isPublicRoute(String path) {
    final publicRoutes = [
      '/api/health',
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/refresh',
      '/api/docs',
    ];
    
    return publicRoutes.any((route) => path.startsWith(route));
  }
  
  // Validar JWT token (simulado - usar una librería real en producción)
  static Map<String, dynamic>? _validateJwtToken(String token) {
    try {
      // En producción usarías dart_jsonwebtoken o similar
      if (token == 'valid-admin-token') {
        return {
          'user_id': '1',
          'email': 'admin@example.com',
          'role': 'admin',
          'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
        };
      } else if (token == 'valid-user-token') {
        return {
          'user_id': '2',
          'email': 'user@example.com',
          'role': 'user',
          'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
        };
      } else if (token.startsWith('valid-user-')) {
        final userId = token.split('-').last;
        return {
          'user_id': userId,
          'email': 'user$userId@example.com',
          'role': 'user',
          'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
        };
      }
      
      return null; // Token inválido
      
    } catch (e) {
      return null;
    }
  }
  
  static String? _extractResourceId(String path) {
    // Extraer ID de rutas como /api/users/123
    final parts = path.split('/');
    if (parts.length >= 4 && parts[1] == 'api' && parts[2] == 'users') {
      return parts[3];
    }
    return null;
  }
  
  static Response _unauthorizedResponse(String message) {
    return Response.json(
      jsonEncode({
        'success': false,
        'error': message,
        'code': 'UNAUTHORIZED',
      }),
      statusCode: 401,
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  static Response _forbiddenResponse(String message) {
    return Response.json(
      jsonEncode({
        'success': false,
        'error': message,
        'code': 'FORBIDDEN',
      }),
      statusCode: 403,
      headers: {'Content-Type': 'application/json'},
    );
  }
}
```

**Configuración en ApiServer:**
```dart
// En tu ApiServer
void setupMiddlewares() {
  // Agregar middleware de autenticación JWT
  addMiddleware(AuthMiddleware.jwtAuth());
  
  // Para rutas específicas que requieren admin
  addMiddleware(AuthMiddleware.requireRole(['admin']), path: '/api/admin');
  
  // Para rutas que requieren ownership
  addMiddleware(AuthMiddleware.requireOwnership(), path: '/api/users');
}
```

---

## 📊 2. Middleware de Logging y Monitoreo

```dart
// middleware/logging_middleware.dart
class LoggingMiddleware {
  // Middleware de logging completo
  static Middleware requestLogger() {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        final requestId = _generateRequestId();
        final startTime = DateTime.now();
        
        // Log del request
        print('📥 [${_formatTimestamp(startTime)}] [$requestId] ${request.method} ${request.requestedUri}');
        print('   Headers: ${_formatHeaders(request.headers)}');
        
        // Log del body si existe
        String? requestBody;
        if (request.method != 'GET' && request.method != 'DELETE') {
          requestBody = await request.readAsString();
          if (requestBody.isNotEmpty) {
            print('   Body: ${_truncateBody(requestBody)}');
          }
        }
        
        // Agregar request ID al contexto
        final updatedRequest = request.change(
          context: {'request_id': requestId, 'start_time': startTime},
          body: requestBody, // Restaurar body si se leyó
        );
        
        try {
          // Ejecutar handler
          final response = await innerHandler(updatedRequest);
          
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          
          // Log del response
          print('📤 [${_formatTimestamp(DateTime.now())}] [$requestId] ${response.statusCode} - ${duration}ms');
          
          // Log adicional para errores
          if (response.statusCode >= 400) {
            print('   ❌ Error response: Status ${response.statusCode}');
          } else if (duration > 1000) {
            print('   ⚠️ Slow response: ${duration}ms');
          }
          
          // Agregar headers de debugging
          return response.change(headers: {
            ...response.headers,
            'X-Request-ID': requestId,
            'X-Response-Time': '${duration}ms',
          });
          
        } catch (error, stackTrace) {
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          
          print('💥 [${_formatTimestamp(DateTime.now())}] [$requestId] ERROR - ${duration}ms');
          print('   Error: $error');
          print('   Stack: ${_truncateStackTrace(stackTrace.toString())}');
          
          // Retornar error response
          return Response.json(
            jsonEncode({
              'success': false,
              'error': 'Internal server error',
              'request_id': requestId,
            }),
            statusCode: 500,
            headers: {
              'Content-Type': 'application/json',
              'X-Request-ID': requestId,
            },
          );
        }
      };
    };
  }
  
  // Middleware para métricas de performance
  static Middleware performanceMonitor() {
    static final Map<String, List<int>> _routeMetrics = {};
    
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        final route = '${request.method} ${_normalizeRoute(request.requestedUri.path)}';
        
        try {
          final response = await innerHandler(request);
          
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          
          // Registrar métrica
          _routeMetrics.putIfAbsent(route, () => []).add(duration);
          
          // Log cada 10 requests para no saturar
          if (_routeMetrics[route]!.length % 10 == 0) {
            _logRouteStats(route, _routeMetrics[route]!);
          }
          
          return response;
          
        } catch (error) {
          stopwatch.stop();
          print('📊 Performance: $route - ERROR after ${stopwatch.elapsedMilliseconds}ms');
          rethrow;
        }
      };
    };
  }
  
  // Middleware para detectar rutas lentas
  static Middleware slowQueryDetector({int thresholdMs = 1000}) {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        
        final response = await innerHandler(request);
        
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds;
        
        if (duration > thresholdMs) {
          print('🐌 SLOW QUERY DETECTED:');
          print('   Route: ${request.method} ${request.requestedUri.path}');
          print('   Duration: ${duration}ms (threshold: ${thresholdMs}ms)');
          print('   Query params: ${request.requestedUri.queryParameters}');
          print('   User-Agent: ${request.headers['user-agent'] ?? 'unknown'}');
        }
        
        return response;
      };
    };
  }
  
  static String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
  }
  
  static String _formatTimestamp(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
  }
  
  static String _formatHeaders(Map<String, String> headers) {
    final filtered = Map<String, String>.from(headers);
    // Remover headers sensibles
    filtered.remove('authorization');
    filtered.remove('cookie');
    
    return filtered.entries
        .take(3) // Solo mostrar primeros 3 headers
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
  
  static String _truncateBody(String body) {
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }
  
  static String _truncateStackTrace(String stackTrace) {
    final lines = stackTrace.split('\n');
    return lines.take(5).join('\n');
  }
  
  static String _normalizeRoute(String path) {
    // Normalizar rutas para métricas (convertir IDs a parámetros)
    return path.replaceAllMapped(
      RegExp(r'/\d+'),
      (match) => '/{id}',
    ).replaceAllMapped(
      RegExp(r'/[a-f0-9-]{36}'), // UUIDs
      (match) => '/{uuid}',
    );
  }
  
  static void _logRouteStats(String route, List<int> durations) {
    durations.sort();
    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final median = durations[durations.length ~/ 2];
    final p95 = durations[(durations.length * 0.95).floor()];
    
    print('📊 Route stats for $route (${durations.length} requests):');
    print('   Avg: ${avg.toStringAsFixed(1)}ms | Median: ${median}ms | P95: ${p95}ms');
  }
}
```

---

## 🌐 3. Middleware de CORS

```dart
// middleware/cors_middleware.dart
class CorsMiddleware {
  // Middleware CORS completo
  static Middleware cors({
    List<String> allowedOrigins = const ['*'],
    List<String> allowedMethods = const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    List<String> allowedHeaders = const ['*'],
    List<String> exposedHeaders = const [],
    bool allowCredentials = false,
    Duration maxAge = const Duration(hours: 24),
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final origin = request.headers['origin'];
        
        // Verificar si el origen está permitido
        final isAllowedOrigin = allowedOrigins.contains('*') || 
            (origin != null && allowedOrigins.contains(origin));
        
        // Headers CORS básicos
        final corsHeaders = <String, String>{};
        
        if (isAllowedOrigin) {
          corsHeaders['Access-Control-Allow-Origin'] = origin ?? '*';
        }
        
        corsHeaders['Access-Control-Allow-Methods'] = allowedMethods.join(', ');
        
        if (allowedHeaders.contains('*')) {
          final requestHeaders = request.headers['access-control-request-headers'];
          corsHeaders['Access-Control-Allow-Headers'] = requestHeaders ?? 
              'Origin, X-Requested-With, Content-Type, Accept, Authorization';
        } else {
          corsHeaders['Access-Control-Allow-Headers'] = allowedHeaders.join(', ');
        }
        
        if (exposedHeaders.isNotEmpty) {
          corsHeaders['Access-Control-Expose-Headers'] = exposedHeaders.join(', ');
        }
        
        if (allowCredentials) {
          corsHeaders['Access-Control-Allow-Credentials'] = 'true';
        }
        
        corsHeaders['Access-Control-Max-Age'] = maxAge.inSeconds.toString();
        
        // Manejar preflight requests (OPTIONS)
        if (request.method == 'OPTIONS') {
          print('🌐 CORS preflight request from: ${origin ?? 'unknown'}');
          
          return Response.ok(
            '',
            headers: {
              ...corsHeaders,
              'Content-Length': '0',
            },
          );
        }
        
        // Procesar request normal
        final response = await innerHandler(request);
        
        // Agregar headers CORS a la response
        return response.change(headers: {
          ...response.headers,
          ...corsHeaders,
        });
      };
    };
  }
  
  // CORS configurado para desarrollo
  static Middleware development() {
    return cors(
      allowedOrigins: ['http://localhost:3000', 'http://localhost:8080', 'http://127.0.0.1:3000'],
      allowCredentials: true,
      exposedHeaders: ['X-Request-ID', 'X-Response-Time'],
    );
  }
  
  // CORS configurado para producción
  static Middleware production(List<String> domains) {
    return cors(
      allowedOrigins: domains,
      allowCredentials: true,
      allowedHeaders: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept', 'Authorization'],
      exposedHeaders: ['X-Request-ID'],
      maxAge: Duration(hours: 1),
    );
  }
}
```

---

## 🚦 4. Middleware de Rate Limiting

```dart
// middleware/rate_limit_middleware.dart
class RateLimitMiddleware {
  static final Map<String, List<DateTime>> _requestLog = {};
  static final Map<String, DateTime> _blockedUntil = {};
  
  // Rate limiting básico
  static Middleware rateLimit({
    int requestsPerMinute = 60,
    Duration windowDuration = const Duration(minutes: 1),
    Duration blockDuration = const Duration(minutes: 5),
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final clientId = _getClientId(request);
        final now = DateTime.now();
        
        // Verificar si el cliente está bloqueado
        if (_blockedUntil.containsKey(clientId)) {
          final blockedUntil = _blockedUntil[clientId]!;
          if (now.isBefore(blockedUntil)) {
            final remainingSeconds = blockedUntil.difference(now).inSeconds;
            return _rateLimitResponse(
              'Too many requests. Blocked for $remainingSeconds more seconds.',
              blockedUntil.millisecondsSinceEpoch ~/ 1000,
            );
          } else {
            _blockedUntil.remove(clientId);
          }
        }
        
        // Limpiar requests antiguos
        _requestLog.putIfAbsent(clientId, () => []);
        final requests = _requestLog[clientId]!;
        final windowStart = now.subtract(windowDuration);
        requests.removeWhere((time) => time.isBefore(windowStart));
        
        // Verificar límite
        if (requests.length >= requestsPerMinute) {
          print('🚦 Rate limit exceeded for client: $clientId');
          
          // Bloquear cliente
          _blockedUntil[clientId] = now.add(blockDuration);
          
          return _rateLimitResponse(
            'Rate limit exceeded. Blocked for ${blockDuration.inMinutes} minutes.',
            _blockedUntil[clientId]!.millisecondsSinceEpoch ~/ 1000,
          );
        }
        
        // Registrar request
        requests.add(now);
        
        // Procesar request
        final response = await innerHandler(request);
        
        // Agregar headers de rate limiting
        final remaining = requestsPerMinute - requests.length;
        final resetTime = windowStart.add(windowDuration);
        
        return response.change(headers: {
          ...response.headers,
          'X-RateLimit-Limit': requestsPerMinute.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': (resetTime.millisecondsSinceEpoch ~/ 1000).toString(),
        });
      };
    };
  }
  
  // Rate limiting por endpoint
  static Middleware endpointRateLimit(Map<String, int> endpointLimits) {
    final endpointLog = <String, Map<String, List<DateTime>>>{};
    
    return (Handler innerHandler) {
      return (Request request) async {
        final clientId = _getClientId(request);
        final endpoint = '${request.method} ${_normalizeRoute(request.requestedUri.path)}';
        final limit = endpointLimits[endpoint] ?? 100; // Default limit
        
        final now = DateTime.now();
        endpointLog.putIfAbsent(endpoint, () => {});
        endpointLog[endpoint]!.putIfAbsent(clientId, () => []);
        
        final requests = endpointLog[endpoint]![clientId]!;
        final windowStart = now.subtract(Duration(minutes: 1));
        requests.removeWhere((time) => time.isBefore(windowStart));
        
        if (requests.length >= limit) {
          print('🚦 Endpoint rate limit exceeded: $endpoint for client: $clientId');
          return _rateLimitResponse(
            'Rate limit exceeded for this endpoint',
            windowStart.add(Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000,
          );
        }
        
        requests.add(now);
        
        final response = await innerHandler(request);
        return response.change(headers: {
          ...response.headers,
          'X-RateLimit-Endpoint': endpoint,
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': (limit - requests.length).toString(),
        });
      };
    };
  }
  
  static String _getClientId(Request request) {
    // En producción podrías usar JWT user_id o IP + User-Agent
    final ip = request.headers['x-forwarded-for'] ?? 
               request.headers['x-real-ip'] ?? 
               request.context['shelf.io.connection_info']?.remoteAddress.address ?? 
               'unknown';
    
    final userAgent = request.headers['user-agent'] ?? 'unknown';
    return '$ip:${userAgent.hashCode}';
  }
  
  static String _normalizeRoute(String path) {
    return path.replaceAllMapped(RegExp(r'/\d+'), (match) => '/{id}');
  }
  
  static Response _rateLimitResponse(String message, int resetTime) {
    return Response.json(
      jsonEncode({
        'success': false,
        'error': message,
        'code': 'RATE_LIMIT_EXCEEDED',
        'reset_time': resetTime,
      }),
      statusCode: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': '60',
      },
    );
  }
}
```

**Configuración de middlewares en ApiServer:**
```dart
// En ApiServer
void configureMiddlewares() {
  // 1. CORS (primero)
  addMiddleware(CorsMiddleware.development());
  
  // 2. Logging
  addMiddleware(LoggingMiddleware.requestLogger());
  addMiddleware(LoggingMiddleware.performanceMonitor());
  addMiddleware(LoggingMiddleware.slowQueryDetector(thresholdMs: 500));
  
  // 3. Rate limiting
  addMiddleware(RateLimitMiddleware.rateLimit(requestsPerMinute: 100));
  addMiddleware(RateLimitMiddleware.endpointRateLimit({
    'POST /api/auth/login': 5,      // 5 intentos de login por minuto
    'POST /api/users': 10,          // 10 creaciones de usuario por minuto
    'GET /api/products': 60,        // 60 consultas de productos por minuto
  }));
  
  // 4. Autenticación (después de logging y rate limiting)
  addMiddleware(AuthMiddleware.jwtAuth());
  
  // 5. Middlewares específicos por ruta
  addMiddleware(AuthMiddleware.requireRole(['admin']), path: '/api/admin');
  addMiddleware(AuthMiddleware.requireOwnership(), path: '/api/users');
}
```

---

## 🏆 Mejores Prácticas para Middlewares

### ✅ **DO's**
- ✅ Ordenar middlewares correctamente (CORS → Logging → Auth)
- ✅ Manejar errores en middlewares
- ✅ Agregar headers informativos (request-id, response-time)
- ✅ Validar input en middlewares de seguridad
- ✅ Usar middleware para funcionalidades transversales
- ✅ Implementar rate limiting y monitoreo

### ❌ **DON'Ts**
- ❌ Poner lógica de negocio en middlewares
- ❌ Ignorar errores en middlewares
- ❌ Hacer middlewares lentos o bloqueantes
- ❌ Exponer información sensible en logs
- ❌ Usar estado global sin sincronización

### 🔄 Orden Recomendado de Middlewares
```
1. CORS Middleware
2. Security Headers
3. Request Logging
4. Rate Limiting
5. Authentication/Authorization
6. Input Validation
7. Business Logic (Controllers)
8. Error Handling
9. Response Logging
```

---

**👉 [Siguiente: JWT Authentication →](10-jwt-authentication.md)**