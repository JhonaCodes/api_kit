# 🛡️ DartSecureAPI - Librería de Seguridad Completa para Dart/Shelf

## Tabla de Contenidos
1. [Arquitectura Base](#arquitectura-base)
2. [OWASP Top 10 - Implementación](#owasp-top-10---implementación)
3. [Rate Limiting Avanzado](#rate-limiting-avanzado)
4. [Circuit Breaker Pattern](#circuit-breaker-pattern-anti-crash)
5. [Auto-Recovery y Health Checks](#auto-recovery-y-health-checks)
6. [Supervisor Pattern](#supervisor-pattern-never-die)
7. [Optimización de Anotaciones](#optimización-de-anotaciones)
8. [Configuración Completa](#configuración-completa)
9. [Deployment Production-Ready](#deployment-production-ready)
10. [Uso Final](#uso-final)

## Arquitectura Base

### Core del Servidor Seguro

```dart
// lib/src/core/secure_server.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:isolate';

class ApiServer {
  final ServerConfig config;
  final Router router;
  late final Pipeline pipeline;
  
  ApiServer({
    required this.config,
    required this.router,
  }) {
    pipeline = _buildSecurePipeline();
  }
  
  Pipeline _buildSecurePipeline() {
    return Pipeline()
      // 1. Request ID para tracing
      .addMiddleware(requestIdMiddleware())
      
      // 2. Security Headers (OWASP)
      .addMiddleware(securityHeadersMiddleware())
      
      // 3. Rate Limiting (DDoS protection)
      .addMiddleware(rateLimitMiddleware(config.rateLimit))
      
      // 4. Request Size Limit
      .addMiddleware(requestSizeLimitMiddleware(config.maxBodySize))
      
      // 5. CORS configurado
      .addMiddleware(corsMiddleware(config.cors))
      
      // 6. Request Sanitization (XSS/SQLi)
      .addMiddleware(sanitizationMiddleware())
      
      // 7. Authentication
      .addMiddleware(authMiddleware(config.auth))
      
      // 8. Request Logging
      .addMiddleware(loggingMiddleware())
      
      // 9. Error Handling (no leak info)
      .addMiddleware(errorHandlingMiddleware())
      
      // 10. Response Time Headers
      .addMiddleware(responseTimeMiddleware());
  }
  
  // Multi-isolate para alta concurrencia
  Future<void> startWithIsolates({
    required String host,
    required int port,
    int isolates = 4,
  }) async {
    for (int i = 0; i < isolates; i++) {
      await Isolate.spawn(_startServer, {
        'host': host,
        'port': port + i,
        'handler': pipeline.addHandler(router),
      });
    }
    
    // Nginx/HAProxy balancea entre estos puertos
    print('Server running on ports ${port} - ${port + isolates - 1}');
  }
}
```

## OWASP Top 10 - Implementación

### OWASP #1: Broken Access Control

```dart
// lib/src/security/owasp_protection.dart

Middleware authMiddleware(ServerConfig config) {
  return (Handler handler) {
    return (Request request) async {
      // Skip public routes
      if (config.publicPaths.any((p) => request.url.path.startsWith(p))) {
        return handler(request);
      }
      
      final token = extractToken(request);
      if (token == null) {
        return Response.unauthorized('Missing token');
      }
      
      try {
        // Verify JWT with proper algorithms (no 'none' attack)
        final payload = JWT.verify(
          token, 
          SecretKey(config.secret),
          checkHeaderType: false,
          audience: config.audience,
          issuer: config.issuer,
        );
        
        // Add user context
        request = request.change(
          context: {'user': payload, 'permissions': extractPermissions(payload)}
        );
        
        // Check permissions
        if (!hasRequiredPermissions(request, config)) {
          return Response.forbidden('Insufficient permissions');
        }
        
        return handler(request);
      } catch (e) {
        return Response.unauthorized('Invalid token');
      }
    };
  };
}
```

### OWASP #2: Cryptographic Failures

```dart
class CryptoService {
  // Usar algoritmos seguros
  static const algorithm = AesGcm.with256bits();
  
  static Future<String> encrypt(String plaintext, String key) async {
    final secretKey = await algorithm.newSecretKeyFromBytes(
      base64.decode(key)
    );
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );
    return base64.encode(secretBox.concatenation());
  }
  
  static String hashPassword(String password) {
    // Usar Argon2 o bcrypt, NUNCA MD5/SHA1
    final salt = generateSalt();
    return hashPasswordWithSalt(password, salt);
  }
}
```

### OWASP #3: Injection Prevention

```dart
Middleware sanitizationMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'POST' || request.method == 'PUT') {
        final body = await request.readAsString();
        
        // Validar JSON estructura
        try {
          final json = jsonDecode(body);
          
          // Sanitizar cada campo
          final sanitized = sanitizeJson(json);
          
          // SQL Injection prevention
          validateNoSqlKeywords(sanitized);
          
          // NoSQL Injection prevention
          validateNoMongoOperators(sanitized);
          
          // Command injection prevention
          validateNoShellCharacters(sanitized);
          
          request = request.change(body: jsonEncode(sanitized));
        } catch (e) {
          return Response.badRequest(body: 'Invalid JSON');
        }
      }
      
      // XSS Prevention en query params
      final sanitizedUrl = sanitizeQueryParams(request.url);
      if (sanitizedUrl != request.url) {
        request = request.change(url: sanitizedUrl);
      }
      
      return handler(request);
    };
  };
}

// Sanitización específica
Map<String, dynamic> sanitizeJson(Map<String, dynamic> json) {
  return json.map((key, value) {
    if (value is String) {
      // Escapar HTML
      value = HtmlEscape().convert(value);
      // Remover caracteres peligrosos
      value = value.replaceAll(RegExp(r'[<>\"\'&]'), '');
      // Limitar longitud
      if (value.length > 10000) {
        value = value.substring(0, 10000);
      }
    } else if (value is Map) {
      value = sanitizeJson(value as Map<String, dynamic>);
    } else if (value is List) {
      value = value.map((item) {
        if (item is Map) return sanitizeJson(item as Map<String, dynamic>);
        return item;
      }).toList();
    }
    return MapEntry(key, value);
  });
}
```

## Rate Limiting Avanzado

```dart
// lib/src/security/rate_limiter.dart
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final Map<String, int> _blacklist = {};
  
  Middleware create({
    int maxRequests = 100,
    Duration window = const Duration(minutes: 1),
    int blacklistThreshold = 5, // Bloquear tras 5 violaciones
  }) {
    return (Handler handler) {
      return (Request request) async {
        final ip = getClientIp(request);
        
        // Check blacklist
        if (_blacklist.containsKey(ip)) {
          if (_blacklist[ip]! > DateTime.now().millisecondsSinceEpoch) {
            return Response(429, body: 'IP temporarily banned');
          } else {
            _blacklist.remove(ip);
          }
        }
        
        final now = DateTime.now();
        _requests[ip] ??= [];
        
        // Limpiar requests viejos
        _requests[ip]!.removeWhere(
          (time) => now.difference(time) > window
        );
        
        // Verificar límite
        if (_requests[ip]!.length >= maxRequests) {
          // Incrementar violaciones
          final violations = (_requests['${ip}_violations'] ??= []);
          violations.add(now);
          
          if (violations.length >= blacklistThreshold) {
            // Banear por 1 hora
            _blacklist[ip] = now.add(Duration(hours: 1)).millisecondsSinceEpoch;
            return Response(429, body: 'IP banned for 1 hour');
          }
          
          return Response(429, 
            headers: {
              'Retry-After': '${window.inSeconds}',
              'X-RateLimit-Limit': '$maxRequests',
              'X-RateLimit-Remaining': '0',
              'X-RateLimit-Reset': '${now.add(window).millisecondsSinceEpoch}',
            },
            body: 'Rate limit exceeded'
          );
        }
        
        _requests[ip]!.add(now);
        
        // Agregar headers informativos
        final response = await handler(request);
        return response.change(headers: {
          ...response.headers,
          'X-RateLimit-Limit': '$maxRequests',
          'X-RateLimit-Remaining': '${maxRequests - _requests[ip]!.length}',
        });
      };
    };
  }
}

// IP extraction con proxy support
String getClientIp(Request request) {
  // Check headers in order (for reverse proxies)
  return request.headers['x-real-ip'] ??
         request.headers['x-forwarded-for']?.split(',').first.trim() ??
         request.context['shelf.io.connection_info']?.remoteAddress.address ??
         'unknown';
}
```

## Circuit Breaker Pattern (Anti-Crash)

```dart
// lib/src/resilience/circuit_breaker.dart
enum CircuitState { open, closed, halfOpen }

class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;
  
  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 10),
    this.resetTimeout = const Duration(seconds: 60),
  });
  
  Future<T> execute<T>(Future<T> Function() action) async {
    if (_state == CircuitState.open) {
      if (DateTime.now().difference(_lastFailureTime!) > resetTimeout) {
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitBreakerOpenException();
      }
    }
    
    try {
      final result = await action().timeout(timeout);
      
      if (_state == CircuitState.halfOpen) {
        _state = CircuitState.closed;
        _failureCount = 0;
      }
      
      return result;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      
      if (_failureCount >= failureThreshold) {
        _state = CircuitState.open;
        print('Circuit breaker OPEN after $_failureCount failures');
      }
      
      rethrow;
    }
  }
}

// Uso en endpoints
class UserService {
  final circuitBreaker = CircuitBreaker();
  final db = Database();
  
  Future<Response> getUser(Request request, String id) async {
    try {
      final user = await circuitBreaker.execute(
        () => db.getUser(id)
      );
      return Response.ok(jsonEncode(user));
    } on CircuitBreakerOpenException {
      // Respuesta de fallback
      return Response.serviceUnavailable(
        body: 'Service temporarily unavailable'
      );
    } catch (e) {
      return Response.internalServerError();
    }
  }
}
```

## Auto-Recovery y Health Checks

```dart
// lib/src/resilience/health_monitor.dart
class HealthMonitor {
  final List<HealthCheck> checks;
  Timer? _timer;
  bool _healthy = true;
  
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _timer = Timer.periodic(interval, (_) async {
      await runHealthChecks();
    });
  }
  
  Future<void> runHealthChecks() async {
    final results = await Future.wait(
      checks.map((check) => check.execute())
    );
    
    _healthy = results.every((r) => r.healthy);
    
    if (!_healthy) {
      await attemptRecovery();
    }
  }
  
  Future<void> attemptRecovery() async {
    print('Attempting auto-recovery...');
    
    // Reconectar DB
    if (!await DatabaseCheck().execute().then((r) => r.healthy)) {
      await Database.reconnect();
    }
    
    // Limpiar caché corrupto
    if (Cache.instance.isCorrupted) {
      Cache.instance.clear();
    }
    
    // Reiniciar servicios fallidos
    ServiceManager.restartFailed();
  }
}

// Health endpoint
Router healthRouter() {
  final router = Router();
  
  router.get('/health', (Request request) async {
    final checks = {
      'database': await DatabaseCheck().execute(),
      'redis': await RedisCheck().execute(),
      'disk': await DiskSpaceCheck().execute(),
      'memory': await MemoryCheck().execute(),
    };
    
    final healthy = checks.values.every((c) => c.healthy);
    
    return Response(
      healthy ? 200 : 503,
      body: jsonEncode({
        'status': healthy ? 'healthy' : 'unhealthy',
        'checks': checks,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  });
  
  router.get('/health/live', (Request request) async {
    // Simple liveness check
    return Response.ok('alive');
  });
  
  router.get('/health/ready', (Request request) async {
    // Readiness check
    final dbReady = await Database.isReady();
    final cacheReady = await Cache.isReady();
    
    if (dbReady && cacheReady) {
      return Response.ok('ready');
    }
    return Response.serviceUnavailable();
  });
  
  return router;
}
```

## Supervisor Pattern (Never Die)

```dart
// lib/src/resilience/supervisor.dart
class ServerSupervisor {
  static const maxRestarts = 5;
  static const restartWindow = Duration(minutes: 5);
  
  final List<DateTime> _restarts = [];
  
  Future<void> supervise(Future<void> Function() serverStart) async {
    while (true) {
      try {
        print('Starting server...');
        await serverStart();
      } catch (e, stack) {
        print('Server crashed: $e');
        await logCrash(e, stack);
        
        if (!shouldRestart()) {
          print('Too many restarts, stopping supervisor');
          await notifyAdmins('Server failing repeatedly');
          exit(1);
        }
        
        print('Restarting in 5 seconds...');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }
  
  bool shouldRestart() {
    final now = DateTime.now();
    _restarts.add(now);
    
    // Limpiar restarts viejos
    _restarts.removeWhere(
      (time) => now.difference(time) > restartWindow
    );
    
    return _restarts.length <= maxRestarts;
  }
  
  Future<void> logCrash(Object error, StackTrace stack) async {
    final crashLog = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stack': stack.toString(),
      'restarts_in_window': _restarts.length,
    };
    
    // Log to file
    await File('crashes.log').writeAsString(
      jsonEncode(crashLog) + '\n',
      mode: FileMode.append,
    );
    
    // Send to monitoring service
    try {
      await http.post(
        Uri.parse('https://monitoring.example.com/crash'),
        body: jsonEncode(crashLog),
      );
    } catch (_) {
      // Don't crash the crash handler
    }
  }
}

// main.dart con supervisor
void main() async {
  final supervisor = ServerSupervisor();
  
  await supervisor.supervise(() async {
    final server = ApiServer(
      config: ServerConfig.production(),
      router: setupRoutes(),
    );
    
    // Graceful shutdown
    ProcessSignal.sigterm.watch().listen((_) async {
      print('Received SIGTERM, shutting down gracefully...');
      await server.close();
      exit(0);
    });
    
    ProcessSignal.sigint.watch().listen((_) async {
      print('Received SIGINT, shutting down gracefully...');
      await server.close();
      exit(0);
    });
    
    await server.startWithIsolates(
      host: '0.0.0.0',
      port: int.parse(env['PORT'] ?? '8080'),
      isolates: Platform.numberOfProcessors,
    );
  });
}
```

## Optimización de Anotaciones

```dart
// lib/src/annotations/optimized_annotations.dart

// Definir anotaciones
class Controller {
  final String path;
  const Controller(this.path);
}

class GET {
  final String path;
  const GET([this.path = '']);
}

class POST {
  final String path;
  const POST([this.path = '']);
}

class PUT {
  final String path;
  const PUT([this.path = '']);
}

class DELETE {
  final String path;
  const DELETE([this.path = '']);
}

// Cache para evitar reflection repetida
class AnnotationCache {
  static final _cache = <Type, ClassMetadata>{};
  
  static ClassMetadata getMetadata(Type type) {
    return _cache.putIfAbsent(type, () => _scanClass(type));
  }
  
  static ClassMetadata _scanClass(Type type) {
    // Hacer reflection UNA SOLA VEZ al inicio
    final mirror = reflectClass(type);
    final endpoints = <EndpointMetadata>[];
    
    // Obtener path base del controller
    String basePath = '';
    for (final annotation in mirror.metadata) {
      if (annotation.reflectee is Controller) {
        basePath = annotation.reflectee.path;
        break;
      }
    }
    
    for (final declaration in mirror.declarations.entries) {
      final method = declaration.value;
      if (method is MethodMirror) {
        final annotations = method.metadata;
        
        for (final annotation in annotations) {
          String? httpMethod;
          String path = '';
          
          if (annotation.reflectee is GET) {
            httpMethod = 'GET';
            path = annotation.reflectee.path;
          } else if (annotation.reflectee is POST) {
            httpMethod = 'POST';
            path = annotation.reflectee.path;
          } else if (annotation.reflectee is PUT) {
            httpMethod = 'PUT';
            path = annotation.reflectee.path;
          } else if (annotation.reflectee is DELETE) {
            httpMethod = 'DELETE';
            path = annotation.reflectee.path;
          }
          
          if (httpMethod != null) {
            endpoints.add(EndpointMetadata(
              method: method.simpleName,
              httpMethod: httpMethod,
              path: basePath + path,
              handler: _createOptimizedHandler(method),
            ));
          }
        }
      }
    }
    
    return ClassMetadata(endpoints: endpoints);
  }
  
  // Crear handler optimizado que no usa reflection
  static Function _createOptimizedHandler(MethodMirror method) {
    // Pre-compilar toda la info necesaria
    final paramTypes = method.parameters.map((p) => p.type).toList();
    final methodSymbol = method.simpleName;
    
    return (Object instance, Request request) async {
      // Usar invoke UNA vez, no reflection adicional
      final result = reflect(instance).invoke(
        methodSymbol,
        [request], // Parámetros ya preparados
      );
      
      return result.reflectee;
    };
  }
}

// Metadata classes
class ClassMetadata {
  final List<EndpointMetadata> endpoints;
  ClassMetadata({required this.endpoints});
}

class EndpointMetadata {
  final Symbol method;
  final String httpMethod;
  final String path;
  final Function handler;
  
  EndpointMetadata({
    required this.method,
    required this.httpMethod,
    required this.path,
    required this.handler,
  });
}

// Base class para controllers
abstract class BaseController {
  late final ClassMetadata _metadata;
  
  BaseController() {
    _metadata = AnnotationCache.getMetadata(runtimeType);
  }
  
  Router get router {
    final router = Router();
    
    // Usar metadata cacheada, sin reflection adicional
    for (final endpoint in _metadata.endpoints) {
      router.add(
        endpoint.httpMethod,
        endpoint.path,
        (req) => endpoint.handler(this, req),
      );
    }
    
    return router;
  }
}

// Uso optimizado
@Controller('/users')
class UserController extends BaseController {
  @GET('/:id')
  Future<Response> getUser(Request req) async {
    final id = req.params['id'];
    // Tu lógica aquí
    return Response.ok('User $id');
  }
  
  @POST('/')
  Future<Response> createUser(Request req) async {
    final body = await req.readAsString();
    // Tu lógica aquí
    return Response.ok('Created');
  }
  
  @PUT('/:id')
  Future<Response> updateUser(Request req) async {
    final id = req.params['id'];
    // Tu lógica aquí
    return Response.ok('Updated $id');
  }
  
  @DELETE('/:id')
  Future<Response> deleteUser(Request req) async {
    final id = req.params['id'];
    // Tu lógica aquí
    return Response.ok('Deleted $id');
  }
}
```

## Configuración Completa

```dart
// lib/src/config/security_config.dart
class SecurityConfig {
  final RateLimitConfig rateLimit;
  final CorsConfig cors;
  final AuthConfig auth;
  final int maxBodySize;
  final bool enableHttps;
  final List<String> trustedProxies;
  
  SecurityConfig.production() : this(
    rateLimit: RateLimitConfig(
      maxRequests: 100,
      window: Duration(minutes: 1),
      maxRequestsPerIP: 1000,
      maxRequestsPerUser: 5000,
    ),
    cors: CorsConfig(
      allowedOrigins: [env['FRONTEND_URL']!],
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    ),
    auth: AuthConfig(
      secret: env['JWT_SECRET']!,
      issuer: 'your-api',
      audience: 'your-app',
      publicPaths: ['/health', '/metrics', '/auth/login'],
    ),
    maxBodySize: 10 * 1024 * 1024, // 10MB
    enableHttps: true,
    trustedProxies: ['127.0.0.1', '10.0.0.0/8'],
  );
  
  SecurityConfig.development() : this(
    rateLimit: RateLimitConfig(
      maxRequests: 1000,
      window: Duration(minutes: 1),
      maxRequestsPerIP: 10000,
      maxRequestsPerUser: 50000,
    ),
    cors: CorsConfig(
      allowedOrigins: ['*'],
      allowedMethods: ['*'],
      allowedHeaders: ['*'],
      credentials: false,
    ),
    auth: AuthConfig(
      secret: 'dev-secret-change-in-production',
      issuer: 'your-api-dev',
      audience: 'your-app-dev',
      publicPaths: ['/'],
    ),
    maxBodySize: 50 * 1024 * 1024, // 50MB for dev
    enableHttps: false,
    trustedProxies: ['*'],
  );
}

class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  final int maxRequestsPerIP;
  final int maxRequestsPerUser;
  
  RateLimitConfig({
    required this.maxRequests,
    required this.window,
    required this.maxRequestsPerIP,
    required this.maxRequestsPerUser,
  });
}

class CorsConfig {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool credentials;
  
  CorsConfig({
    required this.allowedOrigins,
    required this.allowedMethods,
    required this.allowedHeaders,
    required this.credentials,
  });
}

class AuthConfig {
  final String secret;
  final String issuer;
  final String audience;
  final List<String> publicPaths;
  
  AuthConfig({
    required this.secret,
    required this.issuer,
    required this.audience,
    required this.publicPaths,
  });
}
```

## Deployment Production-Ready

### Docker Configuration

```dockerfile
# Dockerfile
FROM dart:stable AS build

WORKDIR /app

# Copy dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source
COPY . .

# Compile to native executable
RUN dart compile exe bin/server.dart -o bin/server

# Production image
FROM debian:bullseye-slim

# Install required libraries
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r dart && useradd -r -g dart dart

# Copy executable
COPY --from=build --chown=dart:dart /app/bin/server /app/bin/server

# Switch to non-root user
USER dart

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["/app/bin/server"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - api1
      - api2
      - api3
      - api4
    restart: unless-stopped

  api1:
    build: .
    environment:
      - PORT=8081
      - INSTANCE_ID=1
      - DB_HOST=postgres
      - REDIS_HOST=redis
    restart: unless-stopped
    depends_on:
      - postgres
      - redis

  api2:
    build: .
    environment:
      - PORT=8082
      - INSTANCE_ID=2
      - DB_HOST=postgres
      - REDIS_HOST=redis
    restart: unless-stopped
    depends_on:
      - postgres
      - redis

  api3:
    build: .
    environment:
      - PORT=8083
      - INSTANCE_ID=3
      - DB_HOST=postgres
      - REDIS_HOST=redis
    restart: unless-stopped
    depends_on:
      - postgres
      - redis

  api4:
    build: .
    environment:
      - PORT=8084
      - INSTANCE_ID=4
      - DB_HOST=postgres
      - REDIS_HOST=redis
    restart: unless-stopped
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=api_db
      - POSTGRES_USER=api_user
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### Nginx Configuration

```nginx
# nginx.conf
upstream dart_api {
    least_conn;
    server api1:8081 max_fails=3 fail_timeout=30s;
    server api2:8082 max_fails=3 fail_timeout=30s;
    server api3:8083 max_fails=3 fail_timeout=30s;
    server api4:8084 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name api.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    
    # Rate limiting at nginx level
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;
    
    # Request size limit
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://dart_api;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Circuit breaker at nginx level
        proxy_next_upstream error timeout http_503;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
    
    # Health check endpoint (no rate limit)
    location /health {
        proxy_pass http://dart_api;
        limit_req off;
    }
}
```

## Uso Final

### Estructura del Proyecto

```
dart_secure_api/
├── bin/
│   └── server.dart
├── lib/
│   ├── src/
│   │   ├── core/
│   │   │   ├── secure_server.dart
│   │   │   └── base_controller.dart
│   │   ├── security/
│   │   │   ├── owasp_protection.dart
│   │   │   ├── rate_limiter.dart
│   │   │   └── crypto_service.dart
│   │   ├── resilience/
│   │   │   ├── circuit_breaker.dart
│   │   │   ├── health_monitor.dart
│   │   │   └── supervisor.dart
│   │   ├── middleware/
│   │   │   ├── auth_middleware.dart
│   │   │   ├── cors_middleware.dart
│   │   │   └── logging_middleware.dart
│   │   ├── annotations/
│   │   │   └── optimized_annotations.dart
│   │   └── config/
│   │       └── security_config.dart
│   └── dart_secure_api.dart
├── test/
├── docker-compose.yml
├── Dockerfile
├── nginx.conf
└── pubspec.yaml
```

### pubspec.yaml

```yaml
name: dart_secure_api
description: A secure API framework for Dart
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_cors_headers: ^0.1.5
  shelf_static: ^1.1.0
  dart_jsonwebtoken: ^2.12.0
  crypto: ^3.0.3
  bcrypt: ^1.1.3
  postgres: ^2.6.0
  redis: ^3.1.0
  http: ^1.1.0
  logging: ^1.2.0
  dotenv: ^4.2.0
  uuid: ^4.2.0

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
  mockito: ^5.4.0
```

### Main Server File

```dart
// bin/server.dart
import 'package:dart_secure_api/dart_secure_api.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() async {
  // Load environment variables
  final env = DotEnv()..load();
  
  // Create secure API instance
  final api = SecureAPI(
    config: Platform.environment['ENV'] == 'production'
        ? SecurityConfig.production()
        : SecurityConfig.development(),
  );
  
  // Register controllers with annotations
  api.register(UserController());
  api.register(ProductController());
  api.register(OrderController());
  api.register(AuthController());
  
  // Add custom middleware if needed
  api.addMiddleware(customBusinessLogicMiddleware());
  
  // Start with supervisor for auto-recovery
  await api.startSupervised(
    host: '0.0.0.0',
    port: int.parse(Platform.environment['PORT'] ?? '8080'),
    isolates: int.parse(Platform.environment['ISOLATES'] ?? '4'),
  );
}

// Example controller with annotations
@Controller('/api/v1/users')
class UserController extends BaseController {
  final UserService userService = UserService();
  
  @GET('/:id')
  Future<Response> getUser(Request req) async {
    final id = req.params['id'];
    
    try {
      final user = await userService.findById(id!);
      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      if (e is NotFoundException) {
        return Response.notFound('User not found');
      }
      return Response.internalServerError();
    }
  }
  
  @POST('/')
  Future<Response> createUser(Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body);
    
    // Validation
    final validation = UserValidator.validate(data);
    if (!validation.isValid) {
      return Response.badRequest(
        body: jsonEncode({'errors': validation.errors}),
      );
    }
    
    try {
      final user = await userService.create(data);
      return Response(
        201,
        body: jsonEncode(user.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError();
    }
  }
  
  @PUT('/:id')
  Future<Response> updateUser(Request req) async {
    final id = req.params['id'];
    final body = await req.readAsString();
    final data = jsonDecode(body);
    
    try {
      final user = await userService.update(id!, data);
      return Response.ok(
        jsonEncode(user.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      if (e is NotFoundException) {
        return Response.notFound('User not found');
      }
      return Response.internalServerError();
    }
  }
  
  @DELETE('/:id')
  Future<Response> deleteUser(Request req) async {
    final id = req.params['id'];
    
    try {
      await userService.delete(id!);
      return Response.noContent();
    } catch (e) {
      if (e is NotFoundException) {
        return Response.notFound('User not found');
      }
      return Response.internalServerError();
    }
  }
}
```

## Comandos de Desarrollo

```bash
# Desarrollo local
dart run bin/server.dart

# Tests
dart test

# Build para producción
dart compile exe bin/server.dart -o bin/server

# Docker build
docker build -t dart-secure-api .

# Docker compose up
docker-compose up -d

# Ver logs
docker-compose logs -f

# Escalar servicios
docker-compose up -d --scale api=8

# Health check
curl http://localhost/health

# Monitoreo de métricas
curl http://localhost/metrics
```

## Mejores Prácticas de Seguridad

1. **Nunca confíes en el input del usuario**
   - Siempre valida y sanitiza
   - Usa whitelisting, no blacklisting

2. **Principio de menor privilegio**
   - Cada servicio con permisos mínimos
   - Tokens con expiración corta

3. **Defense in depth**
   - Múltiples capas de seguridad
   - No depender de una sola medida

4. **Fail securely**
   - Errores no deben exponer información
   - Logs detallados pero respuestas genéricas

5. **Monitoreo constante**
   - Logs centralizados
   - Alertas de anomalías
   - Métricas en tiempo real

## Recursos Adicionales

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Dart Security Best Practices](https://dart.dev/guides/security)
- [Shelf Documentation](https://pub.dev/packages/shelf)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Nginx Security Headers](https://securityheaders.com/)

## Licencia

MIT License - Úsalo como quieras 🚀