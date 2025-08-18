# 🔍 Query Parameters Avanzados

Los **query parameters** son fundamentales para crear APIs flexibles y potentes. Permiten filtrado, paginación, búsqueda y configuración de respuestas.

## 🎯 Tipos de Query Parameters

### 1. **Filtros** - `?category=electronics&price_min=100`
### 2. **Paginación** - `?page=2&limit=20`
### 3. **Ordenamiento** - `?sort_by=price&order=desc`
### 4. **Búsqueda** - `?search=gaming&fields=name,description`
### 5. **Inclusión** - `?include=reviews,author`

---

## 🔍 1. Sistema de Filtros Avanzado

```dart
@Controller('/api/products')
class ProductController extends BaseController {
  
  static final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Gaming Laptop',
      'category': 'electronics',
      'price': 1299.99,
      'rating': 4.5,
      'in_stock': true,
      'brand': 'TechCorp',
      'tags': ['gaming', 'laptop', 'high-performance'],
      'created_at': '2024-01-01T00:00:00Z',
    },
    {
      'id': '2',
      'name': 'Wireless Mouse',
      'category': 'electronics',
      'price': 79.99,
      'rating': 4.2,
      'in_stock': false,
      'brand': 'TechCorp',
      'tags': ['mouse', 'wireless', 'gaming'],
      'created_at': '2024-01-15T00:00:00Z',
    },
    {
      'id': '3',
      'name': 'Programming Book',
      'category': 'books',
      'price': 49.99,
      'rating': 4.8,
      'in_stock': true,
      'brand': 'TechPublisher',
      'tags': ['programming', 'education'],
      'created_at': '2024-02-01T00:00:00Z',
    },
  ];

  // GET /api/products?category=electronics&price_min=50&price_max=200&in_stock=true
  @GET('/')
  Future<Response> getProducts(Request request) async {
    logRequest(request, 'Getting products with filters');
    
    try {
      // Extraer y validar parámetros de filtro
      final filters = _extractFilters(request);
      final pagination = _extractPagination(request);
      final sorting = _extractSorting(request);
      final inclusion = _extractInclusion(request);
      
      print('🔍 Applied filters:');
      print('  - Filters: ${filters.entries.where((e) => e.value != null).map((e) => '${e.key}=${e.value}').join(', ')}');
      print('  - Pagination: page=${pagination['page']}, limit=${pagination['limit']}');
      print('  - Sorting: ${sorting['sort_by']} ${sorting['order']}');
      print('  - Include: ${inclusion.join(', ')}');
      
      // Aplicar filtros
      var filteredProducts = _products.where((product) {
        return _matchesFilters(product, filters);
      }).toList();
      
      // Aplicar ordenamiento
      _applySorting(filteredProducts, sorting);
      
      // Aplicar paginación
      final totalResults = filteredProducts.length;
      final paginatedProducts = _applyPagination(filteredProducts, pagination);
      
      // Enriquecer datos según inclusiones
      final enrichedProducts = await _enrichProducts(paginatedProducts, inclusion);
      
      final response = ApiResponse.success({
        'products': enrichedProducts,
        'pagination': _buildPaginationInfo(pagination, totalResults),
        'filters_applied': _cleanFilters(filters),
        'sorting': sorting,
        'total_results': totalResults,
        'results_count': paginatedProducts.length,
      }, 'Products retrieved successfully');
      
      return jsonResponse(response.toJson());
      
    } catch (e) {
      print('❌ Error filtering products: $e');
      final response = ApiResponse.error('Error processing filters');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
  }
  
  // Extraer filtros de query parameters
  Map<String, dynamic> _extractFilters(Request request) {
    return {
      'category': getOptionalQueryParam(request, 'category'),
      'brand': getOptionalQueryParam(request, 'brand'),
      'price_min': _parseDouble(getOptionalQueryParam(request, 'price_min')),
      'price_max': _parseDouble(getOptionalQueryParam(request, 'price_max')),
      'rating_min': _parseDouble(getOptionalQueryParam(request, 'rating_min')),
      'rating_max': _parseDouble(getOptionalQueryParam(request, 'rating_max')),
      'in_stock': _parseBool(getOptionalQueryParam(request, 'in_stock')),
      'tags': _parseArray(getOptionalQueryParam(request, 'tags')),
      'search': getOptionalQueryParam(request, 'search'),
      'created_after': getOptionalQueryParam(request, 'created_after'),
      'created_before': getOptionalQueryParam(request, 'created_before'),
    };
  }
  
  // Extraer parámetros de paginación
  Map<String, int> _extractPagination(Request request) {
    final page = int.tryParse(getOptionalQueryParam(request, 'page', '1')) ?? 1;
    final limit = int.tryParse(getOptionalQueryParam(request, 'limit', '10')) ?? 10;
    
    // Validar límites
    final validatedPage = page < 1 ? 1 : page;
    final validatedLimit = limit < 1 ? 10 : (limit > 100 ? 100 : limit);
    
    return {
      'page': validatedPage,
      'limit': validatedLimit,
      'offset': (validatedPage - 1) * validatedLimit,
    };
  }
  
  // Extraer parámetros de ordenamiento
  Map<String, String> _extractSorting(Request request) {
    final sortBy = getOptionalQueryParam(request, 'sort_by', 'created_at');
    final order = getOptionalQueryParam(request, 'order', 'desc');
    
    // Validar campos de ordenamiento permitidos
    final allowedSortFields = ['name', 'price', 'rating', 'created_at', 'category'];
    final validSortBy = allowedSortFields.contains(sortBy) ? sortBy : 'created_at';
    final validOrder = ['asc', 'desc'].contains(order) ? order : 'desc';
    
    return {
      'sort_by': validSortBy,
      'order': validOrder,
    };
  }
  
  // Extraer parámetros de inclusión
  List<String> _extractInclusion(Request request) {
    final includeParam = getOptionalQueryParam(request, 'include');
    if (includeParam == null) return [];
    
    final allowedInclusions = ['reviews', 'specs', 'related', 'brand_info'];
    return includeParam
        .split(',')
        .map((s) => s.trim())
        .where((s) => allowedInclusions.contains(s))
        .toList();
  }
  
  // Verificar si un producto coincide con los filtros
  bool _matchesFilters(Map<String, dynamic> product, Map<String, dynamic> filters) {
    // Filtro por categoría
    if (filters['category'] != null && product['category'] != filters['category']) {
      return false;
    }
    
    // Filtro por marca
    if (filters['brand'] != null && product['brand'] != filters['brand']) {
      return false;
    }
    
    // Filtro por rango de precio
    final price = product['price'] as double;
    if (filters['price_min'] != null && price < filters['price_min']) {
      return false;
    }
    if (filters['price_max'] != null && price > filters['price_max']) {
      return false;
    }
    
    // Filtro por rating
    final rating = product['rating'] as double;
    if (filters['rating_min'] != null && rating < filters['rating_min']) {
      return false;
    }
    if (filters['rating_max'] != null && rating > filters['rating_max']) {
      return false;
    }
    
    // Filtro por disponibilidad
    if (filters['in_stock'] != null && product['in_stock'] != filters['in_stock']) {
      return false;
    }
    
    // Filtro por tags
    if (filters['tags'] != null && filters['tags'].isNotEmpty) {
      final productTags = List<String>.from(product['tags']);
      final filterTags = List<String>.from(filters['tags']);
      
      // Debe tener al menos uno de los tags especificados
      if (!filterTags.any((tag) => productTags.contains(tag))) {
        return false;
      }
    }
    
    // Búsqueda de texto
    if (filters['search'] != null) {
      final searchTerm = filters['search'].toString().toLowerCase();
      final name = product['name'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();
      
      if (!name.contains(searchTerm) && 
          !category.contains(searchTerm) && 
          !brand.contains(searchTerm)) {
        return false;
      }
    }
    
    // Filtro por fecha de creación
    if (filters['created_after'] != null || filters['created_before'] != null) {
      final createdAt = DateTime.parse(product['created_at']);
      
      if (filters['created_after'] != null) {
        final afterDate = DateTime.tryParse(filters['created_after']);
        if (afterDate != null && createdAt.isBefore(afterDate)) {
          return false;
        }
      }
      
      if (filters['created_before'] != null) {
        final beforeDate = DateTime.tryParse(filters['created_before']);
        if (beforeDate != null && createdAt.isAfter(beforeDate)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  // Aplicar ordenamiento
  void _applySorting(List<Map<String, dynamic>> products, Map<String, String> sorting) {
    final sortBy = sorting['sort_by']!;
    final order = sorting['order']!;
    
    products.sort((a, b) {
      dynamic aValue = a[sortBy];
      dynamic bValue = b[sortBy];
      
      if (aValue is String && bValue is String) {
        final result = aValue.toLowerCase().compareTo(bValue.toLowerCase());
        return order == 'desc' ? -result : result;
      } else if (aValue is num && bValue is num) {
        final result = aValue.compareTo(bValue);
        return order == 'desc' ? -result : result;
      } else if (aValue is DateTime && bValue is DateTime) {
        final result = aValue.compareTo(bValue);
        return order == 'desc' ? -result : result;
      } else {
        // Para otros tipos (incluyendo DateTime como String)
        if (sortBy == 'created_at') {
          final dateA = DateTime.parse(aValue.toString());
          final dateB = DateTime.parse(bValue.toString());
          final result = dateA.compareTo(dateB);
          return order == 'desc' ? -result : result;
        }
        
        final result = aValue.toString().compareTo(bValue.toString());
        return order == 'desc' ? -result : result;
      }
    });
  }
  
  // Aplicar paginación
  List<Map<String, dynamic>> _applyPagination(
    List<Map<String, dynamic>> products, 
    Map<String, int> pagination
  ) {
    final offset = pagination['offset']!;
    final limit = pagination['limit']!;
    
    return products.skip(offset).take(limit).toList();
  }
  
  // Enriquecer productos con datos adicionales
  Future<List<Map<String, dynamic>>> _enrichProducts(
    List<Map<String, dynamic>> products, 
    List<String> inclusions
  ) async {
    if (inclusions.isEmpty) return products;
    
    return products.map((product) {
      final enriched = Map<String, dynamic>.from(product);
      
      for (final inclusion in inclusions) {
        switch (inclusion) {
          case 'reviews':
            enriched['reviews_summary'] = {
              'total_reviews': 25,
              'average_rating': product['rating'],
              'recent_reviews': 5,
            };
            break;
          case 'specs':
            enriched['specifications'] = {
              'weight': '2.5kg',
              'dimensions': '35x25x2cm',
              'warranty': '2 years',
            };
            break;
          case 'related':
            enriched['related_products'] = [
              {'id': '999', 'name': 'Related Product 1'},
              {'id': '998', 'name': 'Related Product 2'},
            ];
            break;
          case 'brand_info':
            enriched['brand_details'] = {
              'founded': 2010,
              'country': 'USA',
              'website': 'https://techcorp.com',
            };
            break;
        }
      }
      
      return enriched;
    }).toList();
  }
  
  // Construir información de paginación
  Map<String, dynamic> _buildPaginationInfo(Map<String, int> pagination, int totalResults) {
    final page = pagination['page']!;
    final limit = pagination['limit']!;
    final totalPages = (totalResults / limit).ceil();
    
    return {
      'current_page': page,
      'per_page': limit,
      'total_results': totalResults,
      'total_pages': totalPages,
      'has_next': page < totalPages,
      'has_previous': page > 1,
      'next_page': page < totalPages ? page + 1 : null,
      'previous_page': page > 1 ? page - 1 : null,
    };
  }
  
  // Limpiar filtros para response (remover nulls)
  Map<String, dynamic> _cleanFilters(Map<String, dynamic> filters) {
    final cleaned = <String, dynamic>{};
    for (final entry in filters.entries) {
      if (entry.value != null) {
        cleaned[entry.key] = entry.value;
      }
    }
    return cleaned;
  }
  
  // Helpers para parsing
  double? _parseDouble(String? value) {
    return value != null ? double.tryParse(value) : null;
  }
  
  bool? _parseBool(String? value) {
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }
  
  List<String> _parseArray(String? value) {
    if (value == null) return [];
    return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
```

**Tests avanzados:**
```bash
# Filtros múltiples
curl "http://localhost:8080/api/products?category=electronics&price_min=50&price_max=200&in_stock=true"

# Búsqueda con ordenamiento
curl "http://localhost:8080/api/products?search=gaming&sort_by=price&order=asc"

# Paginación con filtros
curl "http://localhost:8080/api/products?category=electronics&page=2&limit=5"

# Con inclusiones
curl "http://localhost:8080/api/products?include=reviews,specs&brand=TechCorp"

# Filtro por tags
curl "http://localhost:8080/api/products?tags=gaming,laptop&rating_min=4.0"

# Filtro por fechas
curl "http://localhost:8080/api/products?created_after=2024-01-01&created_before=2024-02-01"
```

---

## 📅 2. Filtros de Fechas Avanzados

```dart
// GET /api/orders?date_from=2024-01-01&date_to=2024-12-31&period=last_30_days
@GET('/orders')
Future<Response> getOrders(Request request) async {
  logRequest(request, 'Getting orders with date filters');
  
  try {
    final dateFilters = _extractDateFilters(request);
    final statusFilters = _extractStatusFilters(request);
    
    print('📅 Date filters applied:');
    print('  - Period: ${dateFilters['period'] ?? 'custom'}');
    print('  - From: ${dateFilters['date_from'] ?? 'any'}');
    print('  - To: ${dateFilters['date_to'] ?? 'any'}');
    print('  - Status: ${statusFilters.join(', ')}');
    
    // Simular datos de órdenes
    final orders = _generateSampleOrders();
    
    // Aplicar filtros de fecha
    var filteredOrders = orders.where((order) {
      return _matchesDateFilters(order, dateFilters) && 
             _matchesStatusFilters(order, statusFilters);
    }).toList();
    
    // Agrupar por período si se solicita
    final groupBy = getOptionalQueryParam(request, 'group_by');
    final result = groupBy != null 
        ? _groupOrdersByPeriod(filteredOrders, groupBy)
        : {'orders': filteredOrders};
    
    final response = ApiResponse.success({
      ...result,
      'total_orders': filteredOrders.length,
      'date_range': dateFilters,
      'filters_applied': statusFilters,
    }, 'Orders retrieved successfully');
    
    return jsonResponse(response.toJson());
    
  } catch (e) {
    print('❌ Error filtering orders: $e');
    final response = ApiResponse.error('Error processing date filters');
    return jsonResponse(response.toJson(), statusCode: 400);
  }
}

Map<String, dynamic> _extractDateFilters(Request request) {
  final period = getOptionalQueryParam(request, 'period');
  final dateFrom = getOptionalQueryParam(request, 'date_from');
  final dateTo = getOptionalQueryParam(request, 'date_to');
  
  // Si se especifica un período predefinido, calcular fechas
  if (period != null) {
    final now = DateTime.now();
    DateTime fromDate;
    DateTime toDate = now;
    
    switch (period) {
      case 'today':
        fromDate = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        final yesterday = now.subtract(Duration(days: 1));
        fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        toDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'last_7_days':
        fromDate = now.subtract(Duration(days: 7));
        break;
      case 'last_30_days':
        fromDate = now.subtract(Duration(days: 30));
        break;
      case 'this_month':
        fromDate = DateTime(now.year, now.month, 1);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        fromDate = lastMonth;
        toDate = DateTime(now.year, now.month, 0, 23, 59, 59); // Último día del mes anterior
        break;
      case 'this_year':
        fromDate = DateTime(now.year, 1, 1);
        break;
      default:
        fromDate = now.subtract(Duration(days: 30)); // Default a 30 días
    }
    
    return {
      'period': period,
      'date_from': fromDate.toIso8601String(),
      'date_to': toDate.toIso8601String(),
    };
  }
  
  // Usar fechas personalizadas
  return {
    'date_from': dateFrom,
    'date_to': dateTo,
  };
}

List<String> _extractStatusFilters(Request request) {
  final statusParam = getOptionalQueryParam(request, 'status');
  if (statusParam == null) return [];
  
  final allowedStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  return statusParam
      .split(',')
      .map((s) => s.trim())
      .where((s) => allowedStatuses.contains(s))
      .toList();
}

bool _matchesDateFilters(Map<String, dynamic> order, Map<String, dynamic> dateFilters) {
  final orderDate = DateTime.parse(order['created_at']);
  
  if (dateFilters['date_from'] != null) {
    final fromDate = DateTime.parse(dateFilters['date_from']);
    if (orderDate.isBefore(fromDate)) return false;
  }
  
  if (dateFilters['date_to'] != null) {
    final toDate = DateTime.parse(dateFilters['date_to']);
    if (orderDate.isAfter(toDate)) return false;
  }
  
  return true;
}

bool _matchesStatusFilters(Map<String, dynamic> order, List<String> statusFilters) {
  if (statusFilters.isEmpty) return true;
  return statusFilters.contains(order['status']);
}

Map<String, dynamic> _groupOrdersByPeriod(List<Map<String, dynamic>> orders, String groupBy) {
  final groups = <String, List<Map<String, dynamic>>>{};
  
  for (final order in orders) {
    final orderDate = DateTime.parse(order['created_at']);
    String groupKey;
    
    switch (groupBy) {
      case 'day':
        groupKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
        break;
      case 'week':
        final weekStart = orderDate.subtract(Duration(days: orderDate.weekday - 1));
        groupKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
        break;
      case 'month':
        groupKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}';
        break;
      case 'quarter':
        final quarter = ((orderDate.month - 1) ~/ 3) + 1;
        groupKey = '${orderDate.year}-Q$quarter';
        break;
      case 'year':
        groupKey = orderDate.year.toString();
        break;
      default:
        groupKey = 'all';
    }
    
    if (!groups.containsKey(groupKey)) {
      groups[groupKey] = [];
    }
    groups[groupKey]!.add(order);
  }
  
  return {
    'groups': groups.map((key, orders) => MapEntry(key, {
      'period': key,
      'orders': orders,
      'count': orders.length,
      'total_amount': orders.fold(0.0, (sum, o) => sum + (o['total'] as double)),
    })),
    'group_by': groupBy,
  };
}

int _getWeekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

List<Map<String, dynamic>> _generateSampleOrders() {
  final statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  final orders = <Map<String, dynamic>>[];
  
  for (int i = 1; i <= 50; i++) {
    final daysAgo = Random().nextInt(90);
    final createdAt = DateTime.now().subtract(Duration(days: daysAgo));
    
    orders.add({
      'id': 'ORD-${1000 + i}',
      'customer_id': 'CUST-${100 + (i % 10)}',
      'status': statuses[Random().nextInt(statuses.length)],
      'total': (Random().nextDouble() * 1000) + 50,
      'items_count': Random().nextInt(5) + 1,
      'created_at': createdAt.toIso8601String(),
    });
  }
  
  return orders;
}
```

**Tests para fechas:**
```bash
# Períodos predefinidos
curl "http://localhost:8080/api/orders?period=last_30_days"
curl "http://localhost:8080/api/orders?period=this_month"
curl "http://localhost:8080/api/orders?period=yesterday"

# Fechas personalizadas
curl "http://localhost:8080/api/orders?date_from=2024-01-01&date_to=2024-01-31"

# Con agrupación
curl "http://localhost:8080/api/orders?period=last_30_days&group_by=day"
curl "http://localhost:8080/api/orders?period=this_year&group_by=month"

# Múltiples filtros
curl "http://localhost:8080/api/orders?period=last_7_days&status=delivered,shipped&group_by=day"
```

---

## 🏆 Mejores Prácticas para Query Parameters

### ✅ **DO's**
- ✅ Validar y sanitizar todos los parámetros
- ✅ Proporcionar valores por defecto sensatos
- ✅ Implementar límites máximos (ej: limit ≤ 100)
- ✅ Documentar todos los parámetros disponibles
- ✅ Usar nombres descriptivos y consistentes
- ✅ Retornar información sobre filtros aplicados

### ❌ **DON'Ts**
- ❌ Confiar en parámetros sin validación
- ❌ Permitir consultas sin límites
- ❌ Usar nombres inconsistentes de parámetros
- ❌ Ignorar parámetros inválidos silenciosamente
- ❌ Exponer lógica interna en parámetros

### 📊 Convenciones de Naming
```
# Filtros
?category=electronics
?status=active
?type=premium

# Rangos
?price_min=100&price_max=500
?date_from=2024-01-01&date_to=2024-12-31
?rating_min=4.0

# Paginación
?page=2&limit=20
?offset=40&limit=20

# Ordenamiento
?sort_by=price&order=desc
?sort=name:asc,price:desc

# Búsqueda
?search=gaming
?q=laptop

# Inclusión
?include=reviews,specs
?expand=author,categories

# Arrays
?tags=gaming,laptop
?categories=electronics,books
```

### 🔍 Validaciones Comunes
```dart
// Validar enteros positivos
int validatePositiveInt(String? value, int defaultValue, int maxValue) {
  final parsed = int.tryParse(value ?? '') ?? defaultValue;
  return parsed < 1 ? defaultValue : (parsed > maxValue ? maxValue : parsed);
}

// Validar enum values
String validateEnum(String? value, List<String> allowed, String defaultValue) {
  return allowed.contains(value) ? value! : defaultValue;
}

// Validar fechas
DateTime? validateDate(String? value) {
  try {
    return value != null ? DateTime.parse(value) : null;
  } catch (e) {
    return null;
  }
}

// Validar arrays
List<String> validateArray(String? value, List<String> allowed) {
  if (value == null) return [];
  return value.split(',')
      .map((s) => s.trim())
      .where((s) => allowed.contains(s))
      .toList();
}
```

---

**👉 [Siguiente: Middlewares →](09-middlewares.md)**