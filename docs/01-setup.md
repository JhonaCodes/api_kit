# 🏗️ Configuración Inicial

## 📦 Paso 1: Instalación

### Agregar API Kit a tu proyecto

```yaml
# pubspec.yaml
dependencies:
  api_kit:
    path: ../04_Librarys/api_kit  # O tu path local
  # Dependencias requeridas
  shelf: ^1.4.0
  shelf_router: ^1.1.4
  logger_rs: ^1.0.0
  result_controller: ^1.2.0
```

```bash
dart pub get
```

## 🎯 Paso 2: Estructura del Proyecto

Crea la siguiente estructura de archivos:

```
mi_api/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   ├── controllers/              # Controladores de API
│   │   ├── user_controller.dart
│   │   └── product_controller.dart
│   ├── models/                   # Modelos de datos
│   │   └── user.dart
│   ├── services/                 # Lógica de negocio
│   │   └── user_service.dart
│   └── middleware/               # Middleware personalizado
│       └── auth_middleware.dart
├── test/                         # Tests
└── pubspec.yaml
```

## 🚀 Paso 3: Servidor Básico

Crea tu `main.dart`:

```dart
// lib/main.dart
import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'controllers/user_controller.dart';

void main() async {
  print('🚀 Starting API Server...');
  
  // Configuración del servidor
  final config = ServerConfig.development(); // Para desarrollo
  // final config = ServerConfig.production(); // Para producción
  
  final server = ApiServer(config: config);
  
  try {
    final result = await server.start(
      host: 'localhost',
      port: 8080,
      controllerList: [
        UserController(),
        // Agrega más controladores aquí
      ],
    );
    
    result.when(
      ok: (httpServer) {
        print('✅ Server running on http://localhost:8080');
        print('📖 Health check: http://localhost:8080/health');
      },
      err: (error) {
        print('❌ Error starting server: ${error.msm}');
        exit(1);
      },
    );
    
    // Mantener servidor corriendo
    print('Press Ctrl+C to stop...');
    await ProcessSignal.sigint.watch().first;
    
  } catch (e) {
    print('❌ Unexpected error: $e');
    exit(1);
  }
}
```

## 🎮 Paso 4: Tu Primer Controlador

Crea `lib/controllers/user_controller.dart`:

```dart
// lib/controllers/user_controller.dart
import 'dart:convert';
import 'package:api_kit/api_kit.dart';

@Controller('/api/users')
class UserController extends BaseController {
  
  // Datos de ejemplo (en producción usarías una base de datos)
  static final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
    {'id': '2', 'name': 'Jane Smith', 'email': 'jane@example.com'},
  ];

  @GET('/')
  Future<Response> getAllUsers(Request request) async {
    logRequest(request, 'Getting all users');
    
    final response = ApiResponse.success({
      'users': _users,
      'total': _users.length,
    }, 'Users retrieved successfully');
    
    return jsonResponse(response.toJson());
  }

  @GET('/health')
  Future<Response> healthCheck(Request request) async {
    logRequest(request, 'Health check');
    
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'user-api',
    }));
  }
}
```

## ▶️ Paso 5: Ejecutar tu API

```bash
dart run lib/main.dart
```

Deberías ver:

```
🚀 Starting API Server...
INFO: Starting secure API server on localhost:8080
INFO: Registering 1 controllers...
DEBUG: Registering controller: UserController
INFO: Building routes from annotations...
DEBUG: Found route: GET / -> Symbol("getAllUsers")
DEBUG: Found route: GET /health -> Symbol("healthCheck")
✅ Server running on http://localhost:8080
📖 Health check: http://localhost:8080/health
```

## 🧪 Paso 6: Probar tu API

### En tu navegador:
- Health check: http://localhost:8080/api/users/health
- Todos los usuarios: http://localhost:8080/api/users/

### Con curl:
```bash
# Health check
curl http://localhost:8080/api/users/health

# Obtener usuarios
curl http://localhost:8080/api/users/
```

### Respuesta esperada:
```json
{
  "success": true,
  "data": {
    "users": [
      {"id": "1", "name": "John Doe", "email": "john@example.com"},
      {"id": "2", "name": "Jane Smith", "email": "jane@example.com"}
    ],
    "total": 2
  },
  "message": "Users retrieved successfully",
  "status_code": 200
}
```

## 🎯 Configuraciones Disponibles

### ServerConfig.development()
- Rate limiting relajado (1000 requests/min)
- CORS permisivo (`*`)
- Body size: 50MB
- HTTPS: deshabilitado
- Logs detallados

### ServerConfig.production()
- Rate limiting estricto (100 requests/min)
- CORS restrictivo (debe configurarse)
- Body size: 10MB
- HTTPS: habilitado
- Logs optimizados

### Configuración Personalizada
```dart
final config = ServerConfig(
  rateLimit: RateLimitConfig(
    maxRequests: 200,
    window: Duration(minutes: 1),
    maxRequestsPerIP: 2000,
  ),
  cors: CorsConfig(
    allowedOrigins: ['https://mi-frontend.com'],
    allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  ),
  maxBodySize: 20 * 1024 * 1024, // 20MB
  enableHttps: false,
  trustedProxies: ['127.0.0.1'],
);
```

## ✅ ¡Listo!

Ya tienes tu API funcionando con:
- ✅ Servidor HTTP configurado
- ✅ Controlador con anotaciones
- ✅ Endpoints básicos funcionando
- ✅ Logging automático
- ✅ Middleware de seguridad activo

---

**👉 [Siguiente: Tu Primer Controlador Completo →](02-first-controller.md)**