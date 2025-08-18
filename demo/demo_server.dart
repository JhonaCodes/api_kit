import 'dart:io';
import 'dart:convert';
import 'package:api_kit/api_kit.dart';

/// Demo controller to showcase all the API Kit features
@Controller('/api/demo')
class DemoController extends BaseController {
  static final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Laptop Pro',
      'price': 1299.99,
      'category': 'electronics',
      'stock': 15,
    },
    {
      'id': '2',
      'name': 'Coffee Mug',
      'price': 12.50,
      'category': 'home',
      'stock': 50,
    },
    {
      'id': '3',
      'name': 'Wireless Mouse',
      'price': 45.00,
      'category': 'electronics',
      'stock': 30,
    },
    {
      'id': '4',
      'name': 'Notebook',
      'price': 8.99,
      'category': 'office',
      'stock': 100,
    },
    {
      'id': '5',
      'name': 'Smartphone',
      'price': 699.99,
      'category': 'electronics',
      'stock': 25,
    },
  ];

  @GET('/')
  Future<Response> getAllProducts(Request request) async {
    logRequest(request, 'Getting all products');

    final response = ApiResponse.success({
      'products': _products,
      'total': _products.length,
      'message': 'All products retrieved successfully',
    }, 'Products retrieved');

    return jsonResponse(response.toJson());
  }

  @GET('/search')
  Future<Response> searchProducts(Request request) async {
    logRequest(request, 'Searching products with filters');

    // Extract query parameters
    final query = getOptionalQueryParam(request, 'q', '');
    final category = getOptionalQueryParam(request, 'category');
    final minPrice = getOptionalQueryParam(request, 'min_price');
    final maxPrice = getOptionalQueryParam(request, 'max_price');
    final limit = getOptionalQueryParam(request, 'limit', '10');
    final offset = getOptionalQueryParam(request, 'offset', '0');
    final sortBy = getOptionalQueryParam(request, 'sort_by', 'name');
    final order = getOptionalQueryParam(request, 'order', 'asc');

    print('🔍 Search Parameters:');
    print('  - Query: "$query"');
    print('  - Category: ${category ?? "any"}');
    print('  - Price range: ${minPrice ?? "0"} - ${maxPrice ?? "∞"}');
    print('  - Sort: $sortBy ($order)');
    print('  - Pagination: offset=$offset, limit=$limit');

    // Filter products
    var filteredProducts = _products.where((product) {
      // Text search
      if (query != null && query.isNotEmpty) {
        final productName = product['name'].toString().toLowerCase();
        if (!productName.contains(query.toLowerCase())) return false;
      }

      // Category filter
      if (category != null) {
        if (product['category'] != category) return false;
      }

      // Price range filter
      final price = product['price'] as double;
      if (minPrice != null) {
        final min = double.tryParse(minPrice) ?? 0;
        if (price < min) return false;
      }
      if (maxPrice != null) {
        final max = double.tryParse(maxPrice) ?? double.infinity;
        if (price > max) return false;
      }

      return true;
    }).toList();

    // Sort products
    filteredProducts.sort((a, b) {
      dynamic aValue = a[sortBy];
      dynamic bValue = b[sortBy];

      // Handle different data types
      if (aValue is String && bValue is String) {
        final result = aValue.toLowerCase().compareTo(bValue.toLowerCase());
        return order == 'desc' ? -result : result;
      } else if (aValue is num && bValue is num) {
        final result = aValue.compareTo(bValue);
        return order == 'desc' ? -result : result;
      } else {
        final result = aValue.toString().compareTo(bValue.toString());
        return order == 'desc' ? -result : result;
      }
    });

    // Apply pagination
    final limitInt = int.tryParse(limit ?? '10') ?? 10;
    final offsetInt = int.tryParse(offset ?? '0') ?? 0;
    final paginatedProducts = filteredProducts
        .skip(offsetInt)
        .take(limitInt)
        .toList();

    final response = ApiResponse.success({
      'products': paginatedProducts,
      'pagination': {
        'total': filteredProducts.length,
        'limit': limitInt,
        'offset': offsetInt,
        'has_more': (offsetInt + limitInt) < filteredProducts.length,
      },
      'filters': {
        'query': query,
        'category': category,
        'min_price': minPrice,
        'max_price': maxPrice,
        'sort_by': sortBy,
        'order': order,
      },
    }, 'Search completed successfully');

    return jsonResponse(response.toJson());
  }

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

    final response = ApiResponse.success(
      product,
      'Product retrieved successfully',
    );
    return jsonResponse(response.toJson());
  }

  @POST('/')
  Future<Response> createProduct(Request request) async {
    logRequest(request, 'Creating new product');

    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.error('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('name') ||
          !data.containsKey('price') ||
          !data.containsKey('category')) {
        final response = ApiResponse.error(
          'Missing required fields: name, price, category',
        );
        return jsonResponse(response.toJson(), statusCode: 400);
      }

      // Create new product
      final newProduct = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': data['name'],
        'price': (data['price'] as num).toDouble(),
        'category': data['category'],
        'stock': data['stock'] ?? 0,
      };

      _products.add(newProduct);

      print(
        '✅ Created product: ${newProduct['name']} (\$${newProduct['price']})',
      );

      final response = ApiResponse.success(
        newProduct,
        'Product created successfully',
      );
      return jsonResponse(response.toJson(), statusCode: 201);
    } catch (e) {
      final response = ApiResponse.error('Invalid JSON format');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
  }

  @GET('/stats')
  Future<Response> getStats(Request request) async {
    logRequest(request, 'Getting statistics');

    // Extract headers for demo
    final userAgent = getOptionalHeader(request, 'user-agent', 'unknown');
    final acceptLanguage = getOptionalHeader(request, 'accept-language', 'en');
    final customToken = getOptionalHeader(request, 'x-api-token');

    print('📊 Request Headers:');
    print('  - User-Agent: $userAgent');
    print('  - Accept-Language: $acceptLanguage');
    print('  - Custom Token: ${customToken ?? "not provided"}');

    // Calculate statistics
    final totalProducts = _products.length;
    final totalValue = _products.fold(
      0.0,
      (sum, p) => sum + (p['price'] as double) * (p['stock'] as int),
    );
    final categories = _products.map((p) => p['category']).toSet().toList();
    final avgPrice =
        _products.fold(0.0, (sum, p) => sum + (p['price'] as double)) /
        totalProducts;

    final stats = {
      'total_products': totalProducts,
      'total_inventory_value': totalValue,
      'categories': categories,
      'average_price': avgPrice,
      'request_info': {
        'user_agent': userAgent,
        'accept_language': acceptLanguage,
        'has_api_token': customToken != null,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    final response = ApiResponse.success(
      stats,
      'Statistics generated successfully',
    );
    return jsonResponse(response.toJson());
  }

  @GET('/health')
  Future<Response> healthCheck(Request request) async {
    logRequest(request, 'Health check requested');

    final health = {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'uptime': 'Demo mode',
      'products_count': _products.length,
    };

    return jsonResponse(jsonEncode(health));
  }
}

void main() async {
  print('🚀 Starting API Kit Demo Server...\n');

  final apiServer = ApiServer(config: ServerConfig.development());

  try {
    final result = await apiServer.start(
      host: 'localhost',
      port: 8080,
      controllerList: [DemoController()],
    );

    late HttpServer server;
    result.when(
      ok: (httpServer) {
        server = httpServer;
        print('✅ Demo server is running!');
        print('📍 Base URL: http://localhost:8080');
        print('\n🎯 Available endpoints:');
        print('   GET  /api/demo/              - Get all products');
        print('   GET  /api/demo/search        - Search products with filters');
        print('   GET  /api/demo/<id>          - Get specific product');
        print('   POST /api/demo/              - Create new product');
        print('   GET  /api/demo/stats         - Get statistics');
        print('   GET  /api/demo/health        - Health check');
        print('\n🔥 Server ready for requests!\n');
      },
      err: (error) {
        print('❌ Error starting server: ${error.msm}');
        return;
      },
    );

    // Keep server running
    print('Press Ctrl+C to stop the server...');
    await ProcessSignal.sigint.watch().first;
    await server.close();
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n👋 Demo server stopped!');
}
