/// Ejemplo de uso de @QueryParam
/// Demuestra cómo capturar parámetros de query string como ?page=1&size=10&filter=active
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🔍 QueryParam Example - Capturing query string parameters');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8091,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test QueryParam endpoints:');
      print('   # Basic pagination:');
      print('   curl "http://localhost:8091/api/users?page=1&size=5"');
      print('   # With filters:');
      print('   curl "http://localhost:8091/api/users?page=2&size=10&status=active&role=admin"');
      print('   # Search with optional params:');
      print('   curl "http://localhost:8091/api/search?q=laptop&category=electronics&minPrice=100"');
      print('   # Using defaults (no query params):');
      print('   curl http://localhost:8091/api/products');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demostrando el uso de QueryParam
@RestController(basePath: '/api')
class QueryParamController extends BaseController {

  /// Ejemplo básico: paginación con query parameters
  @Get(path: '/users')
  Future<Response> getUsers(
    Request request,
    @QueryParam('page', defaultValue: 1, description: 'Page number') int page,
    @QueryParam('size', defaultValue: 10, description: 'Items per page') int size,
    @QueryParam('status', required: false, description: 'Filter by status') String? status,
    @QueryParam('role', required: false, description: 'Filter by role') String? role,
  ) async {
    
    // Simulación de datos filtrados
    final users = <Map<String, dynamic>>[];
    for (int i = 1; i <= size; i++) {
      final userId = ((page - 1) * size) + i;
      users.add({
        'id': userId,
        'name': 'User #$userId',
        'email': 'user$userId@example.com',
        'status': status ?? 'active',
        'role': role ?? 'user',
      });
    }

    return jsonResponse(jsonEncode({
      'message': 'Users retrieved with query parameters',
      'query_params': {
        'page': page,
        'size': size,
        'status': status,
        'role': role,
      },
      'pagination': {
        'current_page': page,
        'items_per_page': size,
        'total_items': 100, // Simulado
        'total_pages': (100 / size).ceil(),
      },
      'filters_applied': {
        'status': status != null,
        'role': role != null,
      },
      'users': users,
    }));
  }

  /// Ejemplo de búsqueda con múltiples filtros opcionales
  @Get(path: '/search')
  Future<Response> searchProducts(
    Request request,
    @QueryParam('q', required: true, description: 'Search query') String query,
    @QueryParam('category', required: false, description: 'Product category') String? category,
    @QueryParam('minPrice', required: false, defaultValue: 0, description: 'Minimum price') double minPrice,
    @QueryParam('maxPrice', required: false, description: 'Maximum price') double? maxPrice,
    @QueryParam('inStock', required: false, defaultValue: true, description: 'Only in stock items') bool inStock,
  ) async {
    
    // Simulación de resultados de búsqueda
    final products = [
      {
        'id': 1,
        'name': query.contains('laptop') ? 'Gaming Laptop' : 'Product containing "$query"',
        'category': category ?? 'electronics',
        'price': minPrice + 100,
        'in_stock': inStock,
        'matches_query': true,
      },
      {
        'id': 2,
        'name': '$query Pro',
        'category': category ?? 'accessories',
        'price': maxPrice != null ? (maxPrice - 50) : (minPrice + 200),
        'in_stock': inStock,
        'matches_query': true,
      }
    ];

    return jsonResponse(jsonEncode({
      'message': 'Search completed',
      'search_params': {
        'query': query,
        'category': category,
        'price_range': {
          'min': minPrice,
          'max': maxPrice,
        },
        'in_stock_only': inStock,
      },
      'results': {
        'total_found': products.length,
        'products': products,
      },
    }));
  }

  /// Ejemplo usando solo valores por defecto
  @Get(path: '/products')
  Future<Response> getProducts(
    Request request,
    @QueryParam('limit', defaultValue: 20, description: 'Maximum items to return') int limit,
    @QueryParam('sortBy', defaultValue: 'name', description: 'Sort field') String sortBy,
    @QueryParam('order', defaultValue: 'asc', description: 'Sort order (asc/desc)') String order,
  ) async {
    
    final products = List.generate(limit, (index) => {
      'id': index + 1,
      'name': 'Product ${index + 1}',
      'price': (index + 1) * 10.0,
      'category': ['electronics', 'books', 'clothing', 'home'][index % 4],
    });

    // Simulación de ordenamiento
    if (sortBy == 'price') {
      products.sort((a, b) => order == 'desc' 
        ? (b['price'] as double).compareTo(a['price'] as double) 
        : (a['price'] as double).compareTo(b['price'] as double));
    }

    return jsonResponse(jsonEncode({
      'message': 'Products listed with default parameters',
      'parameters_used': {
        'limit': limit,
        'sort_by': sortBy,
        'order': order,
      },
      'products': products,
    }));
  }
}