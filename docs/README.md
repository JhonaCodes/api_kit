# 🚀 API Kit - Spring Boot Style Framework for Dart

**API Kit** es un framework moderno para crear APIs REST en Dart usando anotaciones, inspirado en Spring Boot. Proporciona configuración automática, middleware de seguridad, validación y mucho más.

## 📋 Tabla de Contenidos

1. [🏗️ **Configuración Inicial**](01-setup.md) - Instalación y configuración básica
2. [🎯 **Tu Primer Controlador**](02-first-controller.md) - Crear tu primera API
3. [📥 **GET Requests**](03-get-requests.md) - Endpoints de lectura
4. [📤 **POST Requests**](04-post-requests.md) - Crear recursos
5. [🔄 **PUT Requests**](05-put-requests.md) - Actualizar recursos completos
6. [📝 **PATCH Requests**](06-patch-requests.md) - Actualizar recursos parcialmente
7. [🗑️ **DELETE Requests**](07-delete-requests.md) - Eliminar recursos
8. [🔍 **Query Parameters**](08-query-parameters.md) - Filtros, búsquedas y paginación
9. [📨 **Headers & Authentication**](09-headers-auth.md) - Manejo de headers y JWT
10. [🛡️ **Middleware & Security**](10-middleware-security.md) - Seguridad y middleware personalizado
11. [⚠️ **Error Handling**](11-error-handling.md) - Manejo profesional de errores
12. [📊 **Logging & Monitoring**](12-logging-monitoring.md) - Logs y métricas
13. [🧪 **Testing**](13-testing.md) - Testing de APIs
14. [🚀 **Deployment**](14-deployment.md) - Despliegue a producción

## 🎯 ¿Qué puedes hacer con API Kit?

- ✅ **Anotaciones declarativas** como Spring Boot (`@Controller`, `@GET`, `@POST`, etc.)
- ✅ **Reflection automática** para registro de rutas
- ✅ **Query parameters avanzados** con filtros y paginación
- ✅ **Headers extraction** para autenticación y metadata
- ✅ **Middleware de seguridad** OWASP, rate limiting, CORS
- ✅ **JWT authentication** built-in
- ✅ **Error handling** estructurado
- ✅ **Logging profesional** con request IDs y métricas
- ✅ **Validación automática** de requests
- ✅ **Testing framework** integrado

## 🚀 Quick Start

```dart
import 'package:api_kit/api_kit.dart';

@Controller('/api/users')
class UserController extends BaseController {
  @GET('/')
  Future<Response> getUsers(Request request) async {
    // Tu lógica aquí
    return jsonResponse('{"users": []}');
  }
}

void main() async {
  final server = ApiServer(config: ServerConfig.development());
  
  await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [UserController()],
  );
}
```

## 📚 Comenzar

**¡Empieza con la [Configuración Inicial](01-setup.md) para tener tu primera API funcionando en 5 minutos!**

---

### 🎯 Características Principales

#### **Spring Boot Style Annotations**
```dart
@Controller('/api/products')
class ProductController extends BaseController {
  @GET('/search')
  @POST('/')
  @PUT('/<id>')
  @DELETE('/<id>')
}
```

#### **Query Parameters Avanzados**
```dart
@GET('/search')
Future<Response> search(Request request) async {
  final query = getOptionalQueryParam(request, 'q', 'all');
  final limit = getOptionalQueryParam(request, 'limit', '10');
  final category = getOptionalQueryParam(request, 'category');
  // Lógica de búsqueda...
}
```

#### **Headers & JWT**
```dart
@GET('/profile')
@RequireAuth()
Future<Response> getProfile(Request request) async {
  final token = getRequiredHeader(request, 'Authorization');
  final user = getUserFromToken(token);
  // Lógica del perfil...
}
```

#### **Middleware Personalizado**
```dart
@Controller('/api/admin')
@UseMiddleware([AdminMiddleware])
class AdminController extends BaseController {
  // Solo administradores pueden acceder
}
```

---

**👉 [Empezar con la Configuración →](01-setup.md)**