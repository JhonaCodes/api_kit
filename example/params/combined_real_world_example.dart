import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:logger_rs/logger_rs.dart';

/// 🌍 Real-World Combined Example - Production-Ready API
///
/// This example demonstrates a production-ready API with:
/// - ✅ Enhanced parameter annotations (NO Request request needed)
/// - ✅ JWT authentication with role-based access
/// - ✅ Complex business logic with validation
/// - ✅ Direct Ok/Err pattern with result_controller
/// - ✅ Real-world error handling and logging
/// - ✅ Complete parameter extraction showcase
///
/// ## 🎯 Real-World Features:
/// - Multi-tenant user management
/// - Product catalog with complex filtering
/// - Order processing with inventory validation
/// - JWT-protected admin operations
/// - Comprehensive error handling
/// - Production-ready logging
///
/// ## Running the Example:
/// ```bash
/// dart run example/params/combined_real_world_example.dart
/// ```
///
/// ## Test Production-Ready Endpoints:
/// ```bash
/// # Public endpoints
/// curl "http://localhost:8080/api/products?category=electronics&page=1&limit=5"
/// curl "http://localhost:8080/api/products/search?q=laptop&sort=price&order=asc"
///
/// # User management (protected)
/// curl "http://localhost:8080/api/users/profile" \
///   -H "Authorization: Bearer your_jwt_token"
///
/// # Admin operations (requires admin JWT)
/// curl "http://localhost:8080/api/admin/analytics?period=monthly" \
///   -H "Authorization: Bearer admin_jwt_token"
///
/// # Order processing
/// curl -X POST "http://localhost:8080/api/orders" \
///   -H "Authorization: Bearer user_jwt_token" \
///   -H "Content-Type: application/json" \
///   -d '{"items":[{"product_id":"prod_123","quantity":2}]}'
/// ```

void main() async {
  final server = ApiServer(config: ServerConfig.development());

  // Configure JWT for production-ready auth
  server.configureJWTAuth(
    jwtSecret: 'real-world-production-secret-key-256-bits-minimum',
    excludePaths: ['/health', '/api/products', '/api/public'],
  );

  final result = await server.start(host: 'localhost', port: 8080);

  result.when(
    ok: (httpServer) {
      Log.i('🌍 Real-World API Server running on http://localhost:8080');
      Log.i('📦 Products API: http://localhost:8080/api/products');
      Log.i('👥 Users API: http://localhost:8080/api/users (protected)');
      Log.i('📋 Orders API: http://localhost:8080/api/orders (protected)');
      Log.i('⚙️  Admin API: http://localhost:8080/api/admin (admin only)');

      ProcessSignal.sigint.watch().listen((sig) async {
        Log.i('🛑 Shutting down real-world server...');
        await httpServer.close(force: false);
        exit(0);
      });
    },
    err: (error) {
      Log.e('❌ Failed to start real-world server: ${error.msm}');
      exit(1);
    },
  );
}

/// 📦 Products Controller - Public Product Catalog
///
/// ✅ Demonstrates complex filtering and search without Request parameter
@RestController(basePath: '/api/products')
class ProductsController extends BaseController {
  final List<Map<String, dynamic>> _products = [
    {
      'id': 'prod_1',
      'name': 'Gaming Laptop Pro',
      'category': 'electronics',
      'price': 1299.99,
      'stock': 15,
      'rating': 4.8,
      'brand': 'TechCorp',
    },
    {
      'id': 'prod_2',
      'name': 'Wireless Headphones',
      'category': 'electronics',
      'price': 199.99,
      'stock': 45,
      'rating': 4.6,
      'brand': 'AudioMax',
    },
    {
      'id': 'prod_3',
      'name': 'Coffee Maker Deluxe',
      'category': 'home',
      'price': 89.99,
      'stock': 23,
      'rating': 4.4,
      'brand': 'BrewMaster',
    },
    {
      'id': 'prod_4',
      'name': 'Running Shoes Elite',
      'category': 'sports',
      'price': 159.99,
      'stock': 67,
      'rating': 4.7,
      'brand': 'SportsPro',
    },
    {
      'id': 'prod_5',
      'name': 'Smart Watch Series X',
      'category': 'electronics',
      'price': 299.99,
      'stock': 8,
      'rating': 4.5,
      'brand': 'TechCorp',
    },
    {
      'id': 'prod_6',
      'name': 'Yoga Mat Premium',
      'category': 'sports',
      'price': 49.99,
      'stock': 112,
      'rating': 4.3,
      'brand': 'FitLife',
    },
  ];

  /// 📋 Get products with advanced filtering
  ///
  /// ✅ Complex query parameter processing without Request parameter
  @Get(path: '/')
  Future<Response> getProducts(
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
    @RequestHost() String host,
  ) async {
    // ✅ Extract and validate pagination parameters
    final pageStr = allQueryParams['page'] ?? '1';
    final limitStr = allQueryParams['limit'] ?? '10';
    final page = int.tryParse(pageStr) ?? 1;
    final limit = int.tryParse(limitStr) ?? 10;

    if (page < 1 || limit < 1 || limit > 100) {
      final result = ApiKit.badRequest<Map<String, dynamic>>(
        'Invalid pagination parameters',
        validations: <String, String>{
          if (page < 1) 'page': 'Page must be >= 1',
          if (limit < 1 || limit > 100) 'limit': 'Limit must be 1-100',
        },
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // ✅ Apply complex filtering
    var filteredProducts = List<Map<String, dynamic>>.from(_products);

    // Category filter
    final categoryFilter = allQueryParams['category'];
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((p) => p['category'] == categoryFilter)
          .toList();
    }

    // Brand filter
    final brandFilter = allQueryParams['brand'];
    if (brandFilter != null && brandFilter.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((p) => p['brand'] == brandFilter)
          .toList();
    }

    // Price range filter
    final minPriceStr = allQueryParams['min_price'];
    final maxPriceStr = allQueryParams['max_price'];
    if (minPriceStr != null || maxPriceStr != null) {
      final minPrice = double.tryParse(minPriceStr ?? '0') ?? 0;
      final maxPrice = double.tryParse(maxPriceStr ?? '999999') ?? 999999;

      filteredProducts = filteredProducts.where((p) {
        final price = p['price'] as double;
        return price >= minPrice && price <= maxPrice;
      }).toList();
    }

    // Stock availability filter
    final inStockOnly = allQueryParams['in_stock'] == 'true';
    if (inStockOnly) {
      filteredProducts = filteredProducts
          .where((p) => (p['stock'] as int) > 0)
          .toList();
    }

    // ✅ Apply sorting
    final sortBy = allQueryParams['sort'] ?? 'name';
    final sortOrder = allQueryParams['order'] ?? 'asc';

    filteredProducts.sort((a, b) {
      dynamic valueA = a[sortBy];
      dynamic valueB = b[sortBy];

      if (valueA == null || valueB == null) return 0;

      int comparison;
      if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return sortOrder == 'desc' ? -comparison : comparison;
    });

    // ✅ Apply pagination
    final totalProducts = filteredProducts.length;
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, totalProducts);

    if (startIndex >= totalProducts) {
      filteredProducts = [];
    } else {
      filteredProducts = filteredProducts.sublist(startIndex, endIndex);
    }

    final result = ApiKit.ok({
      'products': filteredProducts,
      'pagination': {
        'current_page': page,
        'per_page': limit,
        'total_items': totalProducts,
        'total_pages': (totalProducts / limit).ceil(),
        'has_next': endIndex < totalProducts,
        'has_prev': page > 1,
      },
      'filters_applied': {
        'category': categoryFilter,
        'brand': brandFilter,
        'min_price': minPriceStr != null ? double.tryParse(minPriceStr) : null,
        'max_price': maxPriceStr != null ? double.tryParse(maxPriceStr) : null,
        'in_stock_only': inStockOnly,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      },
      'request_info': {
        'method': method,
        'host': host,
        'query_params_count': allQueryParams.length,
        'headers_count': allHeaders.length,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 🔍 Product search with advanced text matching
  @Get(path: '/search')
  Future<Response> searchProducts(
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestPath() String path,
    @RequestMethod() String method,
  ) async {
    final searchQuery = allQueryParams['q'];

    if (searchQuery == null || searchQuery.trim().isEmpty) {
      final result = ApiKit.badRequest<Map<String, dynamic>>(
        'Search query is required',
        validations: {'q': 'Query parameter cannot be empty'},
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // ✅ Advanced text search
    final query = searchQuery.toLowerCase().trim();
    final searchResults = _products.where((product) {
      final name = product['name'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();

      return name.contains(query) ||
          category.contains(query) ||
          brand.contains(query);
    }).toList();

    // Calculate relevance scores
    for (var product in searchResults) {
      int score = 0;
      final name = product['name'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();

      if (name.contains(query)) score += 3;
      if (category.contains(query)) score += 2;
      if (brand.contains(query)) score += 1;

      product['relevance_score'] = score;
    }

    // Sort by relevance and rating
    searchResults.sort((a, b) {
      final scoreComparison = (b['relevance_score'] as int).compareTo(
        a['relevance_score'] as int,
      );
      if (scoreComparison != 0) return scoreComparison;
      return (b['rating'] as double).compareTo(a['rating'] as double);
    });

    final result = ApiKit.ok({
      'search_results': searchResults,
      'search_info': {
        'query': searchQuery,
        'results_count': searchResults.length,
        'total_products_searched': _products.length,
      },
      'request_info': {
        'method': method,
        'path': path,
        'search_performed_at': DateTime.now().toIso8601String(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 📦 Get single product details
  @Get(path: '/{productId}')
  Future<Response> getProductById(
    @PathParam('productId') String productId,
    @RequestHeader.all() Map<String, String> allHeaders,
  ) async {
    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => <String, dynamic>{},
    );

    if (product.isEmpty) {
      final result = ApiKit.notFound<Map<String, dynamic>>(
        'Product with ID $productId not found',
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // Add additional details for single product view
    final productDetails = Map<String, dynamic>.from(product);
    productDetails['details'] = {
      'description': 'Detailed description for ${product['name']}',
      'specifications': {
        'warranty': '2 years',
        'shipping_weight': '2.5 lbs',
        'dimensions': '12x8x4 inches',
      },
      'availability': {
        'in_stock': (product['stock'] as int) > 0,
        'stock_level': product['stock'],
        'estimated_delivery': '3-5 business days',
      },
    };

    final result = ApiKit.ok({
      'product': productDetails,
      'request_info': {
        'product_id_requested': productId,
        'user_agent': allHeaders['user-agent'] ?? 'unknown',
        'viewed_at': DateTime.now().toIso8601String(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }
}

/// 👥 Users Controller - JWT-Protected User Management
///
/// ✅ Demonstrates JWT integration with enhanced parameters
@RestController(basePath: '/api/users')
@JWTController([UserActiveValidator()]) // All endpoints require active user
class UsersController extends BaseController {
  final Map<String, Map<String, dynamic>> _users = {
    'user_123': {
      'id': 'user_123',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'customer',
      'active': true,
    },
    'user_456': {
      'id': 'user_456',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'role': 'premium',
      'active': true,
    },
    'user_789': {
      'id': 'user_789',
      'name': 'Admin User',
      'email': 'admin@example.com',
      'role': 'admin',
      'active': true,
    },
  };

  /// 👤 Get user profile with JWT context
  @Get(path: '/profile')
  Future<Response> getUserProfile(
    @RequestContext('jwt_payload')
    Map<String, dynamic> jwtPayload, // ✅ Direct JWT access
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    final userId = jwtPayload['user_id'] as String;
    final userRole = jwtPayload['role'] as String?;

    final user = _users[userId];
    if (user == null) {
      final result = ApiKit.notFound<Map<String, dynamic>>(
        'User profile not found',
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // Add profile-specific information
    final profile = Map<String, dynamic>.from(user);
    profile['profile_info'] = {
      'last_login': DateTime.now()
          .subtract(Duration(hours: 2))
          .toIso8601String(),
      'account_type': userRole ?? 'standard',
      'preferences': {
        'notifications': true,
        'marketing_emails': false,
        'theme': 'auto',
      },
    };

    final result = ApiKit.ok({
      'profile': profile,
      'jwt_context': {
        'authenticated_as': userId,
        'role': userRole,
        'token_valid': true,
      },
      'request_info': {
        'method': method,
        'path': path,
        'user_agent': allHeaders['user-agent'],
        'accessed_at': DateTime.now().toIso8601String(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// ✏️ Update user profile
  @Put(path: '/profile')
  Future<Response> updateProfile(
    @RequestBody() Map<String, dynamic> updateData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @RequestHeader.all() Map<String, String> allHeaders,
  ) async {
    try {
      final userId = jwtPayload['user_id'] as String;

      final user = _users[userId];
      if (user == null) {
        final result = ApiKit.notFound<Map<String, dynamic>>(
          'User profile not found',
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Validate update data
      if (updateData.isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'No update data provided',
          validations: {'body': 'Request body cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Apply allowed updates
      final updatedUser = Map<String, dynamic>.from(user);

      if (updateData['name'] != null) {
        final name = updateData['name'].toString().trim();
        if (name.isEmpty) {
          final result = ApiKit.badRequest<Map<String, dynamic>>(
            'Name cannot be empty',
            validations: {'name': 'Name must have content'},
          );
          return ApiResponseBuilder.fromResult(result);
        }
        updatedUser['name'] = name;
      }

      if (updateData['email'] != null) {
        final email = updateData['email'].toString().trim();
        if (!email.contains('@') || email.length < 5) {
          final result = ApiKit.badRequest<Map<String, dynamic>>(
            'Invalid email format',
            validations: {'email': 'Email must be valid format'},
          );
          return ApiResponseBuilder.fromResult(result);
        }
        updatedUser['email'] = email;
      }

      updatedUser['updated_at'] = DateTime.now().toIso8601String();
      _users[userId] = updatedUser;

      final result = ApiKit.ok({
        'user': updatedUser,
        'message': 'Profile updated successfully',
        'changes_applied': updateData.keys.toList(),
        'update_context': {
          'updated_by': userId,
          'content_type': allHeaders['content-type'],
          'updated_at': updatedUser['updated_at'],
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to update profile: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }
}

/// 📋 Orders Controller - Complex Business Logic
///
/// ✅ Demonstrates real-world order processing with validation
@RestController(basePath: '/api/orders')
@JWTController([UserActiveValidator()])
class OrdersController extends BaseController {
  final List<Map<String, dynamic>> _orders = [];
  final Map<String, int> _inventory = {
    'prod_1': 15,
    'prod_2': 45,
    'prod_3': 23,
    'prod_4': 67,
    'prod_5': 8,
    'prod_6': 112,
  };

  /// 📋 Create new order with complex validation
  @Post(path: '/')
  Future<Response> createOrder(
    @RequestBody() Map<String, dynamic> orderData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestHeader.all() Map<String, String> allHeaders,
  ) async {
    try {
      final userId = jwtPayload['user_id'] as String;
      final userRole = jwtPayload['role'] as String?;

      // ✅ Validate order structure
      final items = orderData['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Order must contain at least one item',
          validations: {'items': 'Items array is required and cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // ✅ Validate each item and check inventory
      final validatedItems = <Map<String, dynamic>>[];
      double totalAmount = 0.0;
      final inventoryChanges = <String, int>{};

      for (var i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>?;
        if (item == null) {
          final result = ApiKit.badRequest<Map<String, dynamic>>(
            'Invalid item at index $i',
            validations: {'items[$i]': 'Item must be an object'},
          );
          return ApiResponseBuilder.fromResult(result);
        }

        final productId = item['product_id'] as String?;
        final quantity = item['quantity'] as int?;

        if (productId == null || quantity == null || quantity <= 0) {
          final result = ApiKit.badRequest<Map<String, dynamic>>(
            'Invalid item data at index $i',
            validations: <String, String>{
              if (productId == null)
                'items[$i].product_id': 'Product ID is required',
              if (quantity == null || quantity <= 0)
                'items[$i].quantity': 'Quantity must be positive',
            },
          );
          return ApiResponseBuilder.fromResult(result);
        }

        // Check inventory availability
        final availableStock = _inventory[productId] ?? 0;
        if (availableStock < quantity) {
          final result = ApiKit.conflict<Map<String, dynamic>>(
            'Insufficient stock for product $productId. Available: $availableStock, Requested: $quantity',
          );
          return ApiResponseBuilder.fromResult(result);
        }

        // Find product price (mock product lookup)
        final productPrice = _getProductPrice(productId);
        if (productPrice == null) {
          final result = ApiKit.notFound<Map<String, dynamic>>(
            'Product $productId not found',
          );
          return ApiResponseBuilder.fromResult(result);
        }

        final itemTotal = productPrice * quantity;
        totalAmount += itemTotal;

        validatedItems.add({
          'product_id': productId,
          'quantity': quantity,
          'unit_price': productPrice,
          'total_price': itemTotal,
        });

        inventoryChanges[productId] =
            (inventoryChanges[productId] ?? 0) + quantity;
      }

      // Apply quantity-based discount for premium users
      if (userRole == 'premium' && totalAmount > 100.0) {
        totalAmount *= 0.9; // 10% discount
      }

      // Create order
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      final order = {
        'id': orderId,
        'user_id': userId,
        'items': validatedItems,
        'total_amount': totalAmount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'user_role': userRole,
        'discount_applied':
            userRole == 'premium' && totalAmount > 90.0, // After discount
      };

      // Update inventory
      inventoryChanges.forEach((productId, quantity) {
        _inventory[productId] = (_inventory[productId] ?? 0) - quantity;
      });

      _orders.add(order);

      final result = ApiKit.ok({
        'order': order,
        'message': 'Order created successfully',
        'inventory_updates': inventoryChanges.map(
          (productId, quantity) =>
              MapEntry(productId, 'Reserved $quantity units'),
        ),
        'processing_info': {
          'order_id': orderId,
          'items_count': validatedItems.length,
          'total_amount': totalAmount,
          'user_role': userRole,
          'premium_discount': userRole == 'premium',
        },
        'request_context': {
          'user_agent': allHeaders['user-agent'],
          'content_type': allHeaders['content-type'],
          'query_params': allQueryParams,
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to create order: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }

  /// 📋 Get user's orders
  @Get(path: '/')
  Future<Response> getUserOrders(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @QueryParam.all() Map<String, String> allQueryParams,
  ) async {
    final userId = jwtPayload['user_id'] as String;

    // Filter orders by user
    var userOrders = _orders
        .where((order) => order['user_id'] == userId)
        .toList();

    // Apply status filter if provided
    final statusFilter = allQueryParams['status'];
    if (statusFilter != null && statusFilter.isNotEmpty) {
      userOrders = userOrders
          .where((order) => order['status'] == statusFilter)
          .toList();
    }

    // Sort by creation date (newest first)
    userOrders.sort(
      (a, b) => DateTime.parse(
        b['created_at'],
      ).compareTo(DateTime.parse(a['created_at'])),
    );

    final result = ApiKit.ok({
      'orders': userOrders,
      'summary': {
        'total_orders': userOrders.length,
        'status_filter': statusFilter,
        'user_id': userId,
      },
      'order_stats': {
        'pending': userOrders.where((o) => o['status'] == 'pending').length,
        'completed': userOrders.where((o) => o['status'] == 'completed').length,
        'cancelled': userOrders.where((o) => o['status'] == 'cancelled').length,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// Helper method to get product price (mock implementation)
  double? _getProductPrice(String productId) {
    final prices = {
      'prod_1': 1299.99,
      'prod_2': 199.99,
      'prod_3': 89.99,
      'prod_4': 159.99,
      'prod_5': 299.99,
      'prod_6': 49.99,
    };
    return prices[productId];
  }
}

/// ⚙️ Admin Controller - Advanced Analytics and Management
///
/// ✅ Demonstrates admin-only operations with complex data processing
@RestController(basePath: '/api/admin')
@JWTController([AdminRoleValidator(), AdminActiveValidator()], requireAll: true)
class AdminController extends BaseController {
  /// 📊 Get business analytics
  @Get(path: '/analytics')
  Future<Response> getAnalytics(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
  ) async {
    final adminId = jwtPayload['user_id'] as String;
    final period = allQueryParams['period'] ?? 'daily';
    final category = allQueryParams['category'];

    // Generate mock analytics data based on parameters
    final analytics = {
      'period': period,
      'category_filter': category,
      'metrics': {
        'total_revenue': 15420.50,
        'total_orders': 87,
        'average_order_value': 177.13,
        'conversion_rate': 3.2,
      },
      'top_products': [
        {'id': 'prod_1', 'name': 'Gaming Laptop Pro', 'sales': 12},
        {'id': 'prod_4', 'name': 'Running Shoes Elite', 'sales': 8},
        {'id': 'prod_2', 'name': 'Wireless Headphones', 'sales': 6},
      ],
      'sales_by_category': {
        'electronics': 8950.75,
        'sports': 4320.25,
        'home': 2149.50,
      },
      'generated_at': DateTime.now().toIso8601String(),
      'generated_by': adminId,
    };

    final result = ApiKit.ok({
      'analytics': analytics,
      'request_info': {
        'method': method,
        'admin_id': adminId,
        'query_params': allQueryParams,
        'user_agent': allHeaders['user-agent'],
      },
      'admin_context': {
        'has_full_access': true,
        'data_access_level': 'all_tenants',
        'report_generated_at': DateTime.now().toIso8601String(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// ⚙️ System health check for admins
  @Get(path: '/system/health')
  Future<Response> getSystemHealth(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @RequestPath() String path,
  ) async {
    final adminId = jwtPayload['user_id'] as String;

    final systemHealth = {
      'status': 'healthy',
      'uptime':
          '${DateTime.now().difference(DateTime.now().subtract(Duration(hours: 24))).inHours} hours',
      'services': {
        'database': 'operational',
        'cache': 'operational',
        'message_queue': 'operational',
        'external_apis': 'operational',
      },
      'metrics': {
        'cpu_usage': '45%',
        'memory_usage': '68%',
        'disk_usage': '23%',
        'active_connections': 142,
      },
      'last_deployment': DateTime.now()
          .subtract(Duration(days: 3))
          .toIso8601String(),
      'checked_by': adminId,
      'check_time': DateTime.now().toIso8601String(),
    };

    final result = ApiKit.ok({
      'system_health': systemHealth,
      'admin_info': {
        'admin_id': adminId,
        'access_level': 'system_admin',
        'path_accessed': path,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }
}

// ===== JWT VALIDATORS =====

/// User active validator
class UserActiveValidator extends JWTValidatorBase {
  const UserActiveValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final isActive = jwtPayload['active'] as bool? ?? false;
    if (!isActive) {
      return ValidationResult.invalid('User account is not active');
    }
    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'User account must be active';
}

/// Admin role validator
class AdminRoleValidator extends JWTValidatorBase {
  const AdminRoleValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    if (role != 'admin') {
      return ValidationResult.invalid('Administrator role required');
    }
    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Administrator role required';
}

/// Admin active validator
class AdminActiveValidator extends JWTValidatorBase {
  const AdminActiveValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final isActive = jwtPayload['active'] as bool? ?? false;
    final role = jwtPayload['role'] as String?;

    if (!isActive || role != 'admin') {
      return ValidationResult.invalid('Active administrator account required');
    }
    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Active administrator account required';
}
