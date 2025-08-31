/// Ejemplo de uso de @QueryParam - Tradicional vs Enhanced
/// Demuestra cómo capturar parámetros de query string:
/// - Método Tradicional: @QueryParam('key') con Request parameter
/// - 🆕 Método Enhanced: @QueryParam.all() SIN Request parameter
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🔍 QueryParam Example - Traditional vs Enhanced Methods');

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
      print('');
      print('🔴 TRADITIONAL methods (with Request parameter):');
      print('   curl "http://localhost:8091/api/traditional/users?page=1&size=5"');
      print('   curl "http://localhost:8091/api/traditional/search?q=laptop&category=electronics"');
      print('');
      print('🆕 ENHANCED methods (without Request parameter):');
      print('   curl "http://localhost:8091/api/enhanced/users?page=1&size=5&sort=name&filter_active=true"');
      print('   curl "http://localhost:8091/api/enhanced/search?q=laptop&category=electronics&minPrice=100&maxPrice=500&filter_brand=apple&debug=true"');
      print('');
      print('🎯 Framework Comparison:');
      print('   Traditional: Limited to predefined parameters');
      print('   Enhanced: Captures ALL query parameters automatically');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// 🔴 TRADITIONAL Controller - Uses Request parameter (old method)
@RestController(basePath: '/api/traditional')
class TraditionalQueryParamController extends BaseController {

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
      'message': 'Products listed with default parameters (TRADITIONAL)',
      'method': 'TRADITIONAL - requires Request parameter',
      'parameters_used': {
        'limit': limit,
        'sort_by': sortBy,
        'order': order,
      },
      'products': products,
      'framework_note': 'Limited to predefined parameters only',
    }));
  }
}

/// 🆕 ENHANCED Controller - NO Request parameter needed!
@RestController(basePath: '/api/enhanced')
class EnhancedQueryParamController extends BaseController {

  /// 🆕 Enhanced pagination - ALL query parameters captured automatically
  @Get(path: '/users')
  Future<Response> getUsersEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL params
    @RequestMethod() String method,                         // 🆕 HTTP method
    @RequestPath() String path,                            // 🆕 Path
    @RequestHost() String host,                            // 🆕 Host
    // 🎉 NO Request request needed!
  ) async {
    
    // Extract specific parameters with defaults
    final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
    final size = int.tryParse(allQueryParams['size'] ?? '10') ?? 10;
    final status = allQueryParams['status'];
    final role = allQueryParams['role'];
    final sort = allQueryParams['sort'];
    
    // Extract ALL dynamic filters automatically
    final filters = Map.fromEntries(
      allQueryParams.entries.where((entry) => 
        !['page', 'size', 'status', 'role', 'sort'].contains(entry.key))
    );
    
    // Simulación de datos filtrados
    final users = <Map<String, dynamic>>[];
    for (int i = 1; i <= size; i++) {
      final userId = ((page - 1) * size) + i;
      users.add({
        'id': userId,
        'name': 'Enhanced User #$userId',
        'email': 'user$userId@enhanced.com',
        'status': status ?? 'active',
        'role': role ?? 'user',
        'filters_applied': filters.isNotEmpty,
      });
    }

    return jsonResponse(jsonEncode({
      'message': 'Enhanced users retrieved with complete query parameter capture',
      'method': 'ENHANCED - NO Request parameter needed!',
      'framework_improvement': 'All query parameters captured automatically',
      'request_info': {
        'method': method,            // Direct injection
        'path': path,                // Direct injection  
        'host': host,                // Direct injection
      },
      'query_params': {
        'total_params': allQueryParams.length,
        'all_params': allQueryParams,          // Everything available
        'specific_params': {
          'page': page,
          'size': size, 
          'status': status,
          'role': role,
          'sort': sort,
        },
        'dynamic_filters': filters,            // Dynamic filters detected
        'filter_count': filters.length,
      },
      'pagination': {
        'current_page': page,
        'items_per_page': size,
        'total_items': 100,
        'total_pages': (100 / size).ceil(),
      },
      'users': users,
      'enhanced_capabilities': [
        'Captures unlimited query parameters',
        'Dynamic filter detection',
        'No predefined parameter limits',
        'Better debugging with complete parameter visibility',
        'Zero boilerplate code',
      ],
    }));
  }

  /// 🆕 Enhanced search - Comprehensive parameter capture
  @Get(path: '/search')
  Future<Response> searchProductsEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL params
    @RequestHeader.all() Map<String, String> allHeaders,   // 🆕 ALL headers too!
    @RequestUrl() Uri fullUrl,                             // 🆕 Complete URL
    // 🎉 Complete request data without Request parameter!
  ) async {
    
    // Required parameter validation
    final query = allQueryParams['q'];
    if (query == null || query.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Query parameter "q" is required',
        'method': 'ENHANCED',
        'available_params': allQueryParams.keys.toList(),
        'example': '?q=search_term&category=electronics',
      }));
    }
    
    // Extract all search parameters
    final category = allQueryParams['category'];
    final minPrice = double.tryParse(allQueryParams['minPrice'] ?? '0') ?? 0;
    final maxPrice = double.tryParse(allQueryParams['maxPrice'] ?? '999999') ?? 999999;
    final inStock = allQueryParams['inStock'] != 'false';
    final debug = allQueryParams['debug'] == 'true';
    
    // Extract ALL filter parameters dynamically
    final searchFilters = Map.fromEntries(
      allQueryParams.entries.where((entry) => 
        entry.key.startsWith('filter_') || entry.key.startsWith('search_'))
    );
    
    // Extract additional context from headers
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final acceptLanguage = allHeaders['accept-language'] ?? 'en-US';
    
    // Simulación de resultados de búsqueda
    final products = [
      {
        'id': 1,
        'name': query.contains('laptop') ? 'Gaming Laptop Enhanced' : 'Product containing "$query"',
        'category': category ?? 'electronics',
        'price': minPrice + 100,
        'in_stock': inStock,
        'matches_query': true,
        'user_agent': userAgent,
        'language': acceptLanguage.split(',').first,
      },
      {
        'id': 2,
        'name': '$query Pro Enhanced',
        'category': category ?? 'accessories',
        'price': maxPrice > 500 ? (maxPrice - 50) : (minPrice + 200),
        'in_stock': inStock,
        'matches_query': true,
        'debug_mode': debug,
      }
    ];

    return jsonResponse(jsonEncode({
      'message': 'Enhanced search with comprehensive parameter and header capture',
      'method': 'ENHANCED - Complete request analysis without Request parameter',
      'framework_power': {
        'unlimited_query_params': true,
        'all_headers_available': true,
        'dynamic_filtering': true,
        'automatic_context': true,
      },
      'request_analysis': {
        'full_url': fullUrl.toString(),        // Complete URL
        'total_params': allQueryParams.length,
        'total_headers': allHeaders.length,
        'user_agent': userAgent,               // From headers
        'accept_language': acceptLanguage,     // From headers
      },
      'search_params': {
        'query': query,
        'category': category,
        'price_range': {'min': minPrice, 'max': maxPrice},
        'in_stock_only': inStock,
        'debug_mode': debug,
        'all_params': allQueryParams,          // Everything visible
        'search_filters': searchFilters,       // Dynamic filters
        'filter_count': searchFilters.length,
      },
      'results': {
        'total_found': products.length,
        'products': products,
        'search_time_ms': debug ? 125 : null,  // Debug info when requested
        'filters_applied': searchFilters.isNotEmpty,
      },
      'comparison_with_traditional': {
        'traditional_limitations': 'Fixed parameters only',
        'enhanced_capabilities': 'Unlimited dynamic parameters + headers',
        'code_complexity': 'Traditional: High, Enhanced: Low',
        'debugging': 'Traditional: Limited, Enhanced: Complete visibility',
      },
    }));
  }

  /// 🆕 Enhanced products with sorting - Complete parameter handling
  @Get(path: '/products')
  Future<Response> getProductsEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL params
    @RequestMethod() String method,                         // 🆕 HTTP method
    @RequestPath() String path,                            // 🆕 Path
    // 🎉 Clean, no Request needed!
  ) async {
    
    // Extract parameters with intelligent defaults
    final limit = int.tryParse(allQueryParams['limit'] ?? '20') ?? 20;
    final sortBy = allQueryParams['sortBy'] ?? allQueryParams['sort_by'] ?? 'name';
    final order = allQueryParams['order'] ?? 'asc';
    
    // Extract all additional parameters automatically
    final additionalParams = Map.fromEntries(
      allQueryParams.entries.where((entry) => 
        !['limit', 'sortBy', 'sort_by', 'order'].contains(entry.key))
    );
    
    final products = List.generate(limit, (index) => {
      'id': index + 1,
      'name': 'Enhanced Product ${index + 1}',
      'price': (index + 1) * 10.0,
      'category': ['electronics', 'books', 'clothing', 'home'][index % 4],
      'enhanced': true,
    });

    // Enhanced sorting with more options
    switch (sortBy.toLowerCase()) {
      case 'price':
        products.sort((a, b) => order == 'desc' 
          ? (b['price'] as double).compareTo(a['price'] as double) 
          : (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'name':
        products.sort((a, b) => order == 'desc' 
          ? (b['name'] as String).compareTo(a['name'] as String)
          : (a['name'] as String).compareTo(b['name'] as String));
        break;
      case 'category':
        products.sort((a, b) => order == 'desc' 
          ? (b['category'] as String).compareTo(a['category'] as String)
          : (a['category'] as String).compareTo(b['category'] as String));
        break;
    }

    return jsonResponse(jsonEncode({
      'message': 'Enhanced products with comprehensive parameter handling',
      'method': 'ENHANCED - Flexible parameter processing',
      'request_info': {
        'method': method,        // Direct access
        'path': path,            // Direct access
      },
      'parameters_analysis': {
        'total_params': allQueryParams.length,
        'all_params': allQueryParams,
        'used_params': {
          'limit': limit,
          'sort_by': sortBy,
          'order': order,
        },
        'additional_params': additionalParams,
        'additional_count': additionalParams.length,
      },
      'products': products,
      'enhanced_features': [
        'Flexible parameter naming (sortBy or sort_by)',
        'Automatic additional parameter detection',
        'Enhanced sorting options',
        'Complete parameter visibility',
        'No parameter count limits',
      ],
    }));
  }
}