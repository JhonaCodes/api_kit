# 🎯 Tu Primer Controlador

## 📖 Conceptos Básicos

Un **controlador** en API Kit es una clase que agrupa endpoints relacionados. Cada controlador:

- ✅ Extiende `BaseController`
- ✅ Usa la anotación `@Controller('/path')`
- ✅ Define métodos con anotaciones HTTP (`@GET`, `@POST`, etc.)
- ✅ Maneja requests y devuelve responses

## 🏗️ Anatomía de un Controlador

```dart
// lib/controllers/product_controller.dart
import 'dart:convert';
import 'package:api_kit/api_kit.dart';

@Controller('/api/products')        // ← Ruta base del controlador
class ProductController extends BaseController {
  
  // Datos de ejemplo
  static final List<Map<String, dynamic>> _products = [];

  @GET('/')                         // ← Endpoint: GET /api/products/
  Future<Response> getAllProducts(Request request) async {
    logRequest(request, 'Getting all products');
    
    final response = ApiResponse.success(_products, 'Products retrieved');
    return jsonResponse(response.toJson());
  }

  @GET('/<id>')                     // ← Endpoint: GET /api/products/{id}
  Future<Response> getProduct(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Getting product $id');
    
    // Buscar producto...
    final product = _products.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {},
    );
    
    if (product.isEmpty) {
      final response = ApiResponse.error('Product not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    final response = ApiResponse.success(product, 'Product found');
    return jsonResponse(response.toJson());
  }
}
```

## 🔧 BaseController - Métodos Útiles

Tu controlador hereda estos métodos útiles:

### 📥 Parámetros de Ruta
```dart
// Para rutas como: /api/products/{id}
@GET('/<id>')
Future<Response> getProduct(Request request) async {
  final id = getRequiredParam(request, 'id');        // Requerido
  final version = getOptionalParam(request, 'v');    // Opcional
}
```

### 🔍 Query Parameters
```dart
// Para URLs como: /api/products?category=electronics&limit=10
@GET('/')
Future<Response> getProducts(Request request) async {
  final category = getOptionalQueryParam(request, 'category', 'all');
  final limit = getOptionalQueryParam(request, 'limit', '10');
  final allParams = getAllQueryParams(request);
}
```

### 📨 Headers
```dart
@GET('/secure')
Future<Response> secureEndpoint(Request request) async {
  final auth = getRequiredHeader(request, 'Authorization');
  final userAgent = getOptionalHeader(request, 'User-Agent', 'unknown');
}
```

### 📤 Responses
```dart
// Response JSON exitoso
return jsonResponse(data);                          // 200 OK
return jsonResponse(data, statusCode: 201);         // 201 Created

// Response de error
return errorResponse('Not found', statusCode: 404); // 404 Not Found
return errorResponse('Bad request', statusCode: 400); // 400 Bad Request
```

### 📝 Logging
```dart
logRequest(request, 'Custom log message');
```

## 🎨 Patrón de Response Estándar

API Kit usa un patrón de response consistente:

### Response Exitoso
```json
{
  "success": true,
  "data": {
    // Tus datos aquí
  },
  "message": "Operation completed successfully",
  "status_code": 200
}
```

### Response de Error
```json
{
  "success": false,
  "error": "Error message",
  "status_code": 404
}
```

## 📋 Controlador Completo de Ejemplo

```dart
// lib/controllers/product_controller.dart
import 'dart:convert';
import 'package:api_kit/api_kit.dart';

@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Laptop Pro',
      'price': 1299.99,
      'category': 'electronics',
      'stock': 15,
      'created_at': '2024-01-01T00:00:00Z'
    },
    {
      'id': '2', 
      'name': 'Coffee Mug',
      'price': 12.50,
      'category': 'home',
      'stock': 50,
      'created_at': '2024-01-02T00:00:00Z'
    },
  ];

  // GET /api/products/
  @GET('/')
  Future<Response> getAllProducts(Request request) async {
    logRequest(request, 'Getting all products');
    
    final response = ApiResponse.success({
      'products': _products,
      'total': _products.length,
      'timestamp': DateTime.now().toIso8601String(),
    }, 'Products retrieved successfully');
    
    return jsonResponse(response.toJson());
  }

  // GET /api/products/{id}
  @GET('/<id>')
  Future<Response> getProduct(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Getting product $id');
    
    final product = _products.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {},
    );
    
    if (product.isEmpty) {
      final response = ApiResponse.error('Product not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    final response = ApiResponse.success(product, 'Product retrieved successfully');
    return jsonResponse(response.toJson());
  }

  // GET /api/products/category/{category}
  @GET('/category/<category>')
  Future<Response> getProductsByCategory(Request request) async {
    final category = getRequiredParam(request, 'category');
    logRequest(request, 'Getting products in category: $category');
    
    final filteredProducts = _products
        .where((p) => p['category'] == category)
        .toList();
    
    final response = ApiResponse.success({
      'products': filteredProducts,
      'category': category,
      'total': filteredProducts.length,
    }, 'Products filtered by category');
    
    return jsonResponse(response.toJson());
  }

  // GET /api/products/search
  @GET('/search')
  Future<Response> searchProducts(Request request) async {
    final query = getOptionalQueryParam(request, 'q', '');
    final limit = getOptionalQueryParam(request, 'limit', '10');
    
    logRequest(request, 'Searching products: "$query"');
    
    var results = _products;
    
    // Filtrar por query si existe
    if (query.isNotEmpty) {
      results = results
          .where((p) => p['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    
    // Aplicar límite
    final limitInt = int.tryParse(limit) ?? 10;
    if (results.length > limitInt) {
      results = results.take(limitInt).toList();
    }
    
    final response = ApiResponse.success({
      'products': results,
      'query': query,
      'total_found': results.length,
      'limit_applied': limitInt,
    }, 'Search completed');
    
    return jsonResponse(response.toJson());
  }

  // GET /api/products/health
  @GET('/health')
  Future<Response> healthCheck(Request request) async {
    logRequest(request, 'Product service health check');
    
    return jsonResponse(jsonEncode({
      'service': 'product-api',
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'products_count': _products.length,
      'version': '1.0.0',
    }));
  }
}
```

## 🧪 Registrar tu Controlador

No olvides agregar tu controlador al servidor:

```dart
// lib/main.dart
final result = await server.start(
  host: 'localhost',
  port: 8080,
  controllerList: [
    UserController(),      // ← Tu controlador anterior
    ProductController(),   // ← Tu nuevo controlador
  ],
);
```

## 🌐 Probar tu Controlador

```bash
# Todos los productos
curl http://localhost:8080/api/products/

# Producto específico
curl http://localhost:8080/api/products/1

# Por categoría
curl http://localhost:8080/api/products/category/electronics

# Búsqueda
curl "http://localhost:8080/api/products/search?q=laptop&limit=5"

# Health check
curl http://localhost:8080/api/products/health
```

## ✅ Lo que has logrado

- ✅ **Controlador completo** con múltiples endpoints
- ✅ **Parámetros de ruta** dinámicos (`<id>`, `<category>`)
- ✅ **Query parameters** para búsquedas
- ✅ **Manejo de errores** (404 para productos no encontrados)
- ✅ **Logging automático** de todas las operaciones
- ✅ **Responses estructurados** y consistentes

---

**👉 [Siguiente: GET Requests Avanzados →](03-get-requests.md)**