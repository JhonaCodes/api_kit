# @QueryParam - Anotación para Parámetros de Query

## 📋 Descripción

La anotación `@QueryParam` se utiliza para capturar parámetros de consulta (query parameters) de la URL. Permite extraer valores de la cadena de consulta después del `?` y convertirlos automáticamente a parámetros de método.

## 🎯 Propósito

- **Filtrado de datos**: Aplicar filtros a listados y búsquedas (`?category=electronics&active=true`)
- **Paginación**: Controlar página y cantidad de resultados (`?page=1&limit=10`)
- **Configuración de respuesta**: Modificar el formato o contenido (`?format=json&include_metadata=true`)
- **Parámetros opcionales**: Valores que pueden estar presentes o no

## 📝 Sintaxis

### Parámetro Específico (Método Tradicional)
```dart
@QueryParam(
  String name,                    // Nombre del parámetro en la query string (OBLIGATORIO)
  {bool required = false,         // Si el parámetro es obligatorio
   dynamic defaultValue,          // Valor por defecto si no se proporciona  
   String? description}           // Descripción del parámetro
)
```

### 🆕 Todos los Parámetros (Método Enhanced)
```dart
@QueryParam.all({
  bool required = false,          // Si los parámetros son obligatorios
  String? description             // Descripción de los parámetros
})
// Retorna: Map<String, String> con TODOS los query parameters
```

## 🔧 Parámetros

### Para `@QueryParam('name')`
| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `name` | `String` | ✅ Sí | - | Nombre exacto del parámetro en la query string |
| `required` | `bool` | ❌ No | `false` | Si el parámetro debe estar presente en la request |
| `defaultValue` | `dynamic` | ❌ No | `null` | Valor usado cuando el parámetro no está presente |
| `description` | `String?` | ❌ No | `null` | Descripción del propósito y formato esperado |

### 🆕 Para `@QueryParam.all()`
| Parámetro | Tipo | Obligatorio | Valor por Defecto | Descripción |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `false` | Si debe haber al menos un query parameter |
| `description` | `String?` | ❌ No | `'All query parameters as Map<String, String>'` | Descripción de todos los parámetros |

## 🚀 Ejemplos de Uso

### Ejemplo Básico - Parámetros Opcionales (Método Tradicional)
```dart
@RestController(basePath: '/api/products')
class ProductController extends BaseController {
  
  @Get(path: '/search')  // URL: /api/products/search
  Future<Response> searchProducts(
    Request request,
    @QueryParam('q', required: false) String? searchQuery,
    @QueryParam('category', required: false) String? category,
    @QueryParam('active', defaultValue: true) bool activeOnly,
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'Product search executed',
      'search_params': {
        'query': searchQuery,           // null si no se proporciona
        'category': category,           // null si no se proporciona
        'active_only': activeOnly,      // true por defecto
      },
      'results': searchQuery != null ? [] : null
    }));
  }
}
```

### 🆕 Ejemplo Básico - TODOS los Parámetros (Método Enhanced)
```dart
@RestController(basePath: '/api/products')
class ProductController extends BaseController {
  
  @Get(path: '/search')  // URL: /api/products/search
  Future<Response> searchProductsEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 TODOS los params
    @RequestMethod() String method,                         // 🆕 Método HTTP directo
    @RequestPath() String path,                            // 🆕 Path directo
    // 🎉 NO Request request needed!
  ) async {
    
    // Extraer parámetros específicos del Map
    final searchQuery = allQueryParams['q'];
    final category = allQueryParams['category'];
    final activeOnly = allQueryParams['active'] == 'true' || allQueryParams['active'] == null;
    
    // Obtener todos los filtros dinámicos
    final filters = allQueryParams.entries
      .where((entry) => entry.key.startsWith('filter_'))
      .map((entry) => '${entry.key}: ${entry.value}')
      .toList();
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced product search executed',
      'framework_improvement': 'No manual Request parameter needed!',
      'request_info': {
        'method': method,              // Sin request.method
        'path': path,                  // Sin request.url.path
      },
      'search_params': {
        'query': searchQuery,
        'category': category, 
        'active_only': activeOnly,
        'total_params': allQueryParams.length,
        'all_params': allQueryParams,      // Todos los parámetros disponibles
        'dynamic_filters': filters,       // Filtros dinámicos detectados
      },
    }));
  }
}
```

**Testing URLs:**
```bash
# Sin parámetros
curl http://localhost:8080/api/products/search

# Con algunos parámetros
curl "http://localhost:8080/api/products/search?q=laptop&category=electronics"

# Con todos los parámetros + filtros dinámicos (🆕 Enhanced captura TODO)
curl "http://localhost:8080/api/products/search?q=gaming&category=electronics&active=false&filter_price_min=100&filter_brand=apple&debug=true"
```

### Ejemplo con Parámetros Obligatorios (Tradicional)
```dart
@Get(path: '/reports')
Future<Response> generateReport(
  Request request,
  @QueryParam('start_date', required: true, description: 'Fecha inicio en formato YYYY-MM-DD') String startDate,
  @QueryParam('end_date', required: true, description: 'Fecha fin en formato YYYY-MM-DD') String endDate,
  @QueryParam('format', defaultValue: 'json', description: 'Formato del reporte') String format,
) async {
  
  // Validar formato de fechas
  DateTime? start, end;
  
  try {
    start = DateTime.parse('${startDate}T00:00:00Z');
    end = DateTime.parse('${endDate}T23:59:59Z');
  } catch (e) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid date format',
      'start_date': startDate,
      'end_date': endDate,
      'expected_format': 'YYYY-MM-DD',
      'examples': ['2024-01-15', '2024-12-31']
    }));
  }
  
  return jsonResponse(jsonEncode({
    'message': 'Report generated successfully',
    'parameters': {
      'start_date': startDate,
      'end_date': endDate,
      'format': format,
      'period_days': end.difference(start).inDays,
    }
  }));
}
```

### 🆕 Ejemplo con Parámetros Obligatorios (Enhanced)
```dart
@Get(path: '/reports')
Future<Response> generateReportEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 Todos los parámetros
  @RequestMethod() String method,                            // 🆕 Método HTTP
  @RequestUrl() Uri fullUrl,                                // 🆕 URL completa
  // NO Request request needed! 🎉
) async {
  
  // Extraer parámetros requeridos
  final startDate = allQueryParams['start_date'];
  final endDate = allQueryParams['end_date'];
  final format = allQueryParams['format'] ?? 'json';
  
  // Validación de parámetros requeridos
  if (startDate == null || endDate == null) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Required parameters missing',
      'required_params': ['start_date', 'end_date'],
      'provided_params': allQueryParams.keys.toList(),
      'missing_params': ['start_date', 'end_date']
        .where((param) => !allQueryParams.containsKey(param))
        .toList(),
    }));
  }
  
  // Validar formato de fechas
  DateTime? start, end;
  
  try {
    start = DateTime.parse('${startDate}T00:00:00Z');
    end = DateTime.parse('${endDate}T23:59:59Z');
  } catch (e) {
    return Response.badRequest(body: jsonEncode({
      'error': 'Invalid date format',
      'start_date': startDate,
      'end_date': endDate,
      'expected_format': 'YYYY-MM-DD',
      'examples': ['2024-01-15', '2024-12-31']
    }));
  }
  
  // Extraer parámetros adicionales dinámicos
  final additionalParams = Map.fromEntries(
    allQueryParams.entries.where((entry) => 
      !['start_date', 'end_date', 'format'].contains(entry.key))
  );
  
  return jsonResponse(jsonEncode({
    'message': 'Enhanced report generated successfully',
    'framework_improvement': 'All parameters captured automatically!',
    'request_info': {
      'method': method,                 // Sin request.method
      'full_url': fullUrl.toString(),   // Sin request.url
    },
    'parameters': {
      'start_date': startDate,
      'end_date': endDate,
      'format': format,
      'period_days': end.difference(start).inDays,
      'total_params': allQueryParams.length,
      'all_params': allQueryParams,
      'additional_params': additionalParams,  // Parámetros adicionales capturados
    }
  }));
}
```

### Paginación Completa con Enhanced Parameters
```dart
@Get(path: '/list')
Future<Response> getProductListEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 Todos los parámetros
  @RequestHeader.all() Map<String, String> allHeaders,      // 🆕 Todos los headers
  @RequestHost() String host,                               // 🆕 Host directo
  @RequestPath() String path,                              // 🆕 Path directo
) async {
  
  // Extraer parámetros de paginación
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;
  final sortBy = allQueryParams['sort_by'] ?? 'name';
  final sortOrder = allQueryParams['sort_order'] ?? 'asc';
  
  // Extraer todos los filtros dinámicos
  final filters = Map.fromEntries(
    allQueryParams.entries.where((entry) => 
      !['page', 'limit', 'sort_by', 'sort_order'].contains(entry.key))
  );
  
  // Simular datos paginados
  final totalItems = 1000;
  final totalPages = (totalItems / limit).ceil();
  final products = List.generate(limit, (index) => {
    'id': ((page - 1) * limit) + index + 1,
    'name': 'Product ${((page - 1) * limit) + index + 1}',
    'sort_by': sortBy,
    'filters_applied': filters.isNotEmpty,
  });
  
  return jsonResponse(jsonEncode({
    'message': 'Enhanced product list with complete parameter capture',
    'framework_benefits': [
      'No manual Request parameter needed',
      'All query parameters captured automatically',
      'All headers available',
      'Direct access to request components',
    ],
    'request_info': {
      'host': host,              // Sin request.url.host
      'path': path,              // Sin request.url.path
      'user_agent': allHeaders['user-agent'] ?? 'unknown',
    },
    'pagination': {
      'current_page': page,
      'items_per_page': limit,
      'total_items': totalItems,
      'total_pages': totalPages,
      'has_next': page < totalPages,
      'has_prev': page > 1,
    },
    'sorting': {
      'sort_by': sortBy,
      'sort_order': sortOrder,
    },
    'filtering': {
      'total_filters': filters.length,
      'active_filters': filters,
      'all_query_params': allQueryParams,
    },
    'products': products,
  }));
}
```

## 🎯 Casos de Uso Comunes

### 1. **Búsqueda Básica**
```dart
// Tradicional
@QueryParam('q', required: false) String? query,

// 🆕 Enhanced - captura búsquedas dinámicas
@QueryParam.all() Map<String, String> allParams,
// Permite: ?q=text&search_title=title&search_description=desc
```

### 2. **Paginación**
```dart
// Tradicional
@QueryParam('page', defaultValue: 1) int page,
@QueryParam('limit', defaultValue: 10) int limit,

// 🆕 Enhanced - paginación + filtros dinámicos
@QueryParam.all() Map<String, String> allParams,
// Permite: ?page=1&limit=10&offset=20&filter_category=tech&filter_price_max=100
```

### 3. **Configuración de Respuesta**
```dart
// Tradicional
@QueryParam('format', defaultValue: 'json') String format,
@QueryParam('include_metadata', defaultValue: false) bool includeMeta,

// 🆕 Enhanced - configuraciones dinámicas
@QueryParam.all() Map<String, String> allParams,
// Permite: ?format=xml&include_metadata=true&include_stats=true&debug=true
```

### 4. **Filtros Complejos**
```dart
// 🆕 Enhanced - filtros completamente dinámicos
@QueryParam.all() Map<String, String> allParams,
// Permite: ?filter_price_min=10&filter_price_max=100&filter_brand=apple&filter_condition=new
```

## ⚡ Ventajas del Método Enhanced

### ✅ Beneficios
1. **Flexibilidad Total**: Captura cualquier parámetro sin definirlo previamente
2. **Menos Boilerplate**: No necesitas `Request request` 
3. **Filtros Dinámicos**: Permite filtros que no conoces en tiempo de desarrollo
4. **Mejor Escalabilidad**: Fácil añadir nuevos parámetros sin cambiar código
5. **Debugging Mejorado**: Puedes ver todos los parámetros en logs

### ⚠️ Consideraciones
1. **Validación Manual**: Debes validar tipos y valores manualmente
2. **Documentación**: Los parámetros no están explícitos en la función
3. **Type Safety**: Pierdes tipado automático (todo viene como String)

## 🔄 Migración de Tradicional a Enhanced

### Paso 1: Reemplazar parámetros individuales
```dart
// Antes
@QueryParam('page') int page,
@QueryParam('limit') int limit,
@QueryParam('category') String? category,

// Después  
@QueryParam.all() Map<String, String> allQueryParams,
```

### Paso 2: Extraer parámetros del Map
```dart
// Extraer y convertir tipos
final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10; 
final category = allQueryParams['category'];
```

### Paso 3: Eliminar Request parameter
```dart
// Antes
Future<Response> endpoint(Request request, @QueryParam('x') int x) async {

// Después
Future<Response> endpoint(@QueryParam.all() Map<String, String> params) async {
```

## 🎯 Cuándo Usar Cada Método

| **Escenario** | **Método Tradicional** | **Método Enhanced** |
|---------------|------------------------|-------------------|
| **API estable** | ✅ Mejor tipado | ❌ Menos explícito |
| **Filtros dinámicos** | ❌ Limitado | ✅ Perfecto |
| **Prototipado rápido** | ❌ Más código | ✅ Más flexible |
| **APIs públicas** | ✅ Documentación clara | ⚠️ Requiere docs extra |
| **Debugging** | ❌ Parámetros limitados | ✅ Ve todos los params |
| **Type safety** | ✅ Tipado automático | ❌ Tipado manual |

## 🔗 Combinaciones con Otras Anotaciones

### Con Headers Enhanced
```dart
@Get(path: '/search')
Future<Response> searchWithHeaders(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestMethod() String method,
) async {
  // Tienes acceso completo a query params, headers y método
}
```

### Con JWT
```dart
@Get(path: '/user-search')
@JWTEndpoint([MyUserValidator()])
Future<Response> userSearch(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  // Búsqueda personalizada basada en usuario + parámetros dinámicos
}
```

### Con Request Body
```dart
@Post(path: '/advanced-search')
Future<Response> advancedSearch(
  @RequestBody() Map<String, dynamic> searchCriteria,
  @QueryParam.all() Map<String, String> allQueryParams,
) async {
  // Búsqueda compleja con criterios en body y parámetros en query
}
```

---

**🚀 Con @QueryParam.all(), tienes acceso completo a todos los parámetros de query sin necesidad de definirlos previamente, eliminando el parámetro Request manual y creando APIs más flexibles!**