# Use Case: Complete CRUD API with Authentication

## 📋 Description

This use case demonstrates how to implement a complete CRUD (Create, Read, Update, Delete) API for product management using all the annotations of `api_kit` with a robust JWT authentication system.

## 🎯 Use Case Objectives

- **Complete CRUD**: Implement all basic operations
- **Multi-level authentication**: Different permissions for different operations  
- **Data validation**: Complete input validation with clear messages
- **Error handling**: Consistent responses for all error cases
- **Search and filters**: Advanced query endpoints

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────┐
│                 Product API                     │
├─────────────────────────────────────────────────┤
│ GET    /api/products          → List/Search     │
│ GET    /api/products/{id}     → Get Single      │
│ POST   /api/products          → Create          │
│ PUT    /api/products/{id}     → Update Complete │
│ PATCH  /api/products/{id}     → Update Partial  │
│ DELETE /api/products/{id}     → Delete          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│              Authentication Levels              │
├─────────────────────────────────────────────────┤
│ 🌍 Public    → Search products (limited)        │
│ 👤 User      → View full details                │
│ ⚡ Manager   → Create/Edit products             │
│ 🔑 Admin     → Delete products                  │
└─────────────────────────────────────────────────┘
```

## 🚀 Complete Implementation

### Custom JWT Validators

```dart
// Basic user validator
class UserValidator extends JWTValidatorBase {
  const UserValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userId = jwtPayload['user_id'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    
    if (userId == null || userId.isEmpty) {
      return ValidationResult.invalid('Valid user ID required');
    }
    
    if (!isActive) {
      return ValidationResult.invalid('User account is inactive');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Valid user authentication required';
}

// Manager validator
class ManagerValidator extends JWTValidatorBase {
  const ManagerValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    final isManager = role == 'manager' || role == 'admin';
    final hasPermission = permissions.contains('product_management');
    
    if (!isManager || !hasPermission) {
      return ValidationResult.invalid('Manager level access required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Manager access required for product management';
}

// Admin validator
class AdminValidator extends JWTValidatorBase {
  const AdminValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    if (role != 'admin' || !permissions.contains('admin_access')) {
      return ValidationResult.invalid('Administrator access required');
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Administrator access required';
}

// Business hours validator
class BusinessHoursValidator extends JWTValidatorBase {
  const BusinessHoursValidator();
  
  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekday = now.weekday >= 1 && now.weekday <= 5;
    final isBusinessHours = hour >= 9 && hour <= 18;
    
    if (!isWeekday || !isBusinessHours) {
      return ValidationResult.invalid(
        'Product operations only allowed during business hours (Mon-Fri, 9 AM - 6 PM)'
      );
    }
    
    return ValidationResult.valid();
  }
  
  @override
  String get defaultErrorMessage => 'Operation only allowed during business hours';
}
```

### Complete CRUD Controller

```dart
@RestController(
  basePath: '/api/products',
  description: 'Complete product management system with CRUD and multi-level authentication',
  tags: ['products', 'crud', 'inventory']
)
class ProductController extends BaseController {
  
  // ========================================
  // READ OPERATIONS (GET)
  // ========================================
  
  /// List and search products - Public endpoint with limited filters
  @Get(
    path: '/search',
    description: 'Public product search with basic filters'
  )
  @JWTPublic()
  Future<Response> searchProductsPublic(
    Request request,
    @QueryParam('q', required: false, description: 'Search term') String? query,
    @QueryParam('category', required: false, description: 'Filter by category') String? category,
    @QueryParam('page', defaultValue: 1, description: 'Page number') int page,
    @QueryParam('limit', defaultValue: 20, description: 'Products per page') int limit,
  ) async {
    
    // Basic validations
    if (page < 1 || limit < 1 || limit > 50) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid pagination parameters',
        'valid_page': 'page >= 1',
        'valid_limit': '1 <= limit <= 50 (public limit)'
      }).toHttpResponse());
    }
    
    // Simulate public search (limited data)
    final products = _generateMockProducts(query, category, page, limit, isPublic: true);
    
    return ApiKit.ok({
      'message': 'Public product search completed',
      'products': products,
      'pagination': {
        'page': page,
        'limit': limit,
        'total_found': products.length,
        'public_search': true,
      },
      'filters': {
        'query': query,
        'category': category,
      },
      'note': 'Login for detailed product information and advanced filters'
    }).toHttpResponse();
  }
  
  /// Complete product list - Requires user authentication
  @Get(
    path: '',
    description: 'Complete product list with advanced filters (login required)'
  )
  @JWTEndpoint([UserValidator()])
  Future<Response> listProducts(
    Request request,
    // Basic filters
    @QueryParam('q', required: false) String? query,
    @QueryParam('category', required: false) String? category,
    @QueryParam('active', defaultValue: true) bool activeOnly,
    
    // Price filters
    @QueryParam('min_price', required: false) double? minPrice,
    @QueryParam('max_price', required: false) double? maxPrice,
    
    // Pagination
    @QueryParam('page', defaultValue: 1) int page,
    @QueryParam('limit', defaultValue: 50) int limit,
    
    // Sorting
    @QueryParam('sort', defaultValue: 'name') String sortBy,
    @QueryParam('order', defaultValue: 'asc') String sortOrder,
    
    // Response options
    @QueryParam('include_stock', defaultValue: false) bool includeStock,
    @QueryParam('include_supplier', defaultValue: false) bool includeSupplier,
  ) async {
    
    // Get authenticated user information
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final userId = jwtPayload['user_id'];
    
    // Parameter validations
    final validationErrors = <String>[];
    
    if (page < 1) validationErrors.add('Page must be >= 1');
    if (limit < 1 || limit > 200) validationErrors.add('Limit must be between 1 and 200');
    
    if (minPrice != null && minPrice < 0) validationErrors.add('Min price cannot be negative');
    if (maxPrice != null && maxPrice < 0) validationErrors.add('Max price cannot be negative');
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      validationErrors.add('Min price cannot be greater than max price');
    }
    
    final validSortFields = ['name', 'price', 'category', 'created_at', 'updated_at'];
    if (!validSortFields.contains(sortBy)) {
      validationErrors.add('Invalid sort field. Valid options: ${validSortFields.join(', ')}');
    }
    
    final validOrders = ['asc', 'desc'];
    if (!validOrders.contains(sortOrder)) {
      validationErrors.add('Invalid sort order. Valid options: ${validOrders.join(', ')}');
    }
    
    if (validationErrors.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid query parameters',
        'validation_errors': validationErrors
      }).toHttpResponse());
    }
    
    // Simulate full search
    final products = _generateMockProducts(query, category, page, limit, 
      activeOnly: activeOnly,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
      includeStock: includeStock,
      includeSupplier: includeSupplier,
    );
    
    return ApiKit.ok({
      'message': 'Products retrieved successfully',
      'products': products,
      'pagination': {
        'page': page,
        'limit': limit,
        'total_found': products.length,
        'has_next': products.length >= limit,
      },
      'filters_applied': {
        'query': query,
        'category': category,
        'active_only': activeOnly,
        'price_range': {'min': minPrice, 'max': maxPrice},
        'sorting': {'field': sortBy, 'order': sortOrder},
      },
      'user_context': {
        'user_id': userId,
        'detailed_view': true,
        'stock_included': includeStock,
        'supplier_included': includeSupplier,
      }
    }).toHttpResponse();
  }
  
  /// Get a specific product by ID
  @Get(
    path: '/{productId}',
    description: 'Gets the full details of a specific product'
  )
  @JWTEndpoint([UserValidator()])
  Future<Response> getProduct(
    Request request,
    @PathParam('productId', description: 'Unique product ID') String productId,
    @QueryParam('include_reviews', defaultValue: false) bool includeReviews,
    @QueryParam('include_related', defaultValue: false) bool includeRelated,
  ) async {
    
    // Validate ID format
    if (!productId.startsWith('prod_') || productId.length < 10) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid product ID format',
        'expected_format': 'prod_<identifier>',
        'received': productId
      }).toHttpResponse());
    }
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final userId = jwtPayload['user_id'];
    
    // Simulate getting the product
    final product = _getMockProduct(productId);
    if (product == null) {
      return Response.notFound(jsonEncode({
        'error': 'Product not found',
        'product_id': productId,
        'suggestion': 'Check the product ID or use the search endpoint'
      }).toHttpResponse());
    }
    
    // Add additional information based on parameters
    if (includeReviews) {
      product['reviews'] = _getMockReviews(productId);
    }
    
    if (includeRelated) {
      product['related_products'] = _getMockRelatedProducts(productId);
    }
    
    return ApiKit.ok({
      'message': 'Product retrieved successfully',
      'product': product,
      'user_context': {
        'user_id': userId,
        'reviews_included': includeReviews,
        'related_included': includeRelated,
      }
    }).toHttpResponse();
  }
  
  // ========================================
  // CREATE OPERATION (POST)
  // ========================================
  
  /// Create a new product - Requires Manager permissions
  @Post(
    path: '',
    description: 'Create a new product (requires manager permissions)',
    statusCode: 201
  )
  @JWTEndpoint([ManagerValidator(), BusinessHoursValidator()], requireAll: true)
  Future<Response> createProduct(
    Request request, // ⚠️ Only necessary to get JWT context (current limitation)
    @RequestHeader('Content-Type', required: true) String contentType,
    @RequestBody(
      required: true,
      description: 'Complete data for the new product'
    ) Map<String, dynamic> productData, // ✅ Already parsed automatically by @RequestBody
  ) async {
    
    // Validate Content-Type
    if (!contentType.contains('application/json')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid Content-Type',
        'expected': 'application/json',
        'received': contentType
      }).toHttpResponse());
    }
    
    // ⚠️ Current limitation: JWT must be manually extracted from the Request
    // TODO: In future versions, it should be injected automatically
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final managerId = jwtPayload['user_id'];
    
    // Complete product validations
    final validationResult = _validateProductData(productData, isCreate: true);
    if (!validationResult['valid']) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Product validation failed',
        'validation_errors': validationResult['errors'],
        'received_data': productData
      }).toHttpResponse());
    }
    
    // Create product
    final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final newProduct = {
      'id': productId,
      'name': productData['name'],
      'description': productData['description'],
      'price': productData['price'],
      'category': productData['category'],
      'stock': productData['stock'] ?? 0,
      'sku': productData['sku'],
      'specifications': productData['specifications'] ?? {},
      'tags': productData['tags'] ?? [],
      'active': productData['active'] ?? true,
      'created_by': managerId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    return Response(201, body: jsonEncode({
      'message': 'Product created successfully',
      'product': newProduct,
      'creation_context': {
        'created_by': managerId,
        'created_during_business_hours': true,
        'manager_permissions_verified': true,
      }
    }), headers: {'Content-Type': 'application/json'});
  }
  
  // ========================================
  // UPDATE OPERATIONS (PUT & PATCH)
  // ========================================
  
  /// Complete product update
  @Put(
    path: '/{productId}',
    description: 'Complete update of a product (requires all fields)'
  )
  @JWTEndpoint([ManagerValidator()], requireAll: true)
  Future<Response> updateProductComplete(
    Request request,
    @PathParam('productId') String productId,
    @QueryParam('notify_suppliers', defaultValue: false) bool notifySuppliers,
    @RequestBody(required: true) Map<String, dynamic> productData,
  ) async {
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final managerId = jwtPayload['user_id'];
    
    // Verify that the product exists
    if (!_productExists(productId)) {
      return Response.notFound(jsonEncode({
        'error': 'Product not found',
        'product_id': productId
      }).toHttpResponse());
    }
    
    // Validate complete data for PUT
    final validationResult = _validateProductData(productData, isCreate: false, isCompleteUpdate: true);
    if (!validationResult['valid']) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Complete product data validation failed',
        'validation_errors': validationResult['errors'],
        'hint': 'PUT requires all fields. Use PATCH for partial updates.'
      }).toHttpResponse());
    }
    
    // Update complete product
    final updatedProduct = {
      'id': productId,
      ...productData,
      'updated_by': managerId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    final actions = <String>[];
    if (notifySuppliers) {
      actions.add('suppliers_notified');
    }
    
    return ApiKit.ok({
      'message': 'Product updated completely',
      'product': updatedProduct,
      'update_type': 'complete_replacement',
      'actions_performed': actions,
      'updated_by': managerId,
    }).toHttpResponse();
  }
  
  /// Partial product update
  @Patch(
    path: '/{productId}',
    description: 'Partial update of a product (only sent fields)'
  )
  @JWTEndpoint([ManagerValidator()], requireAll: true)
  Future<Response> updateProductPartial(
    Request request,
    @PathParam('productId') String productId,
    @QueryParam('validate_stock', defaultValue: true) bool validateStock,
    @RequestBody(required: true) Map<String, dynamic> updates,
  ) async {
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final managerId = jwtPayload['user_id'];
    
    // Verify that there are fields to update
    if (updates.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'No fields to update',
        'hint': 'Include at least one field in the request body'
      }).toHttpResponse());
    }
    
    // Verify that the product exists
    if (!_productExists(productId)) {
      return Response.notFound(jsonEncode({
        'error': 'Product not found',
        'product_id': productId
      }).toHttpResponse());
    }
    
    // Validate sent fields
    final validationResult = _validateProductData(updates, isPartialUpdate: true, validateStock: validateStock);
    if (!validationResult['valid']) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Partial update validation failed',
        'validation_errors': validationResult['errors']
      }).toHttpResponse());
    }
    
    // Apply partial update
    final updatedFields = updates.keys.toList();
    final patchedProduct = <String, dynamic>{
      'id': productId,
      'updated_by': managerId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Only include updated fields
    for (final field in updatedFields) {
      patchedProduct[field] = updates[field];
    }
    
    return ApiKit.ok({
      'message': 'Product updated partially',
      'product': patchedProduct,
      'updated_fields': updatedFields,
      'update_type': 'partial_update',
      'patch_summary': {
        'fields_updated': updatedFields.length,
        'stock_validation': validateStock,
      }
    }).toHttpResponse();
  }
  
  // ========================================
  // DELETE OPERATION (DELETE)
  // ========================================
  
  /// Delete product - Requires Admin permissions
  @Delete(
    path: '/{productId}',
    description: 'Delete a product from the system (requires admin)',
    statusCode: 200 // Return information instead of 204
  )
  @JWTEndpoint([AdminValidator(), BusinessHoursValidator()], requireAll: true)
  Future<Response> deleteProduct(
    Request request,
    @PathParam('productId') String productId,
    @QueryParam('force', defaultValue: false, description: 'Force deletion even if it has dependencies') bool force,
    @RequestHeader('X-Confirm-Delete', required: true, description: 'Deletion confirmation') String confirmHeader,
  ) async {
    
    // Validate confirmation
    if (confirmHeader != 'CONFIRM_DELETE') {
      return Response.badRequest(body: jsonEncode({
        'error': 'Deletion confirmation required',
        'required_header': 'X-Confirm-Delete: CONFIRM_DELETE',
        'received': confirmHeader
      }).toHttpResponse());
    }
    
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>;
    final adminId = jwtPayload['user_id'];
    
    // Verify that the product exists
    if (!_productExists(productId)) {
      return Response.notFound(jsonEncode({
        'error': 'Product not found',
        'product_id': productId
      }).toHttpResponse());
    }
    
    // Check dependencies
    final dependencies = _checkProductDependencies(productId);
    if (dependencies.isNotEmpty && !force) {
      return Response(409, body: jsonEncode({ // Conflict
        'error': 'Cannot delete product with existing dependencies',
        'product_id': productId,
        'dependencies': dependencies,
        'solution': 'Use force=true to delete anyway or remove dependencies first'
      }), headers: {'Content-Type': 'application/json'});
    }
    
    // Perform deletion
    final deletionRecord = {
      'product_id': productId,
      'deleted_by': adminId,
      'deleted_at': DateTime.now().toIso8601String(),
      'forced_deletion': force,
      'had_dependencies': dependencies.isNotEmpty,
      'dependencies_removed': dependencies,
      'confirmation_verified': true,
    };
    
    return ApiKit.ok({
      'message': 'Product deleted successfully',
      'deletion_record': deletionRecord,
      'security_validation': {
        'admin_permissions': true,
        'business_hours': true,
        'confirmation_header': true,
      }
    }).toHttpResponse();
  }
  
  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================
  
  List<Map<String, dynamic>> _generateMockProducts(
    String? query, 
    String? category, 
    int page, 
    int limit, {
    bool isPublic = false,
    bool activeOnly = true,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'name',
    String sortOrder = 'asc',
    bool includeStock = false,
    bool includeSupplier = false,
  }) {
    
    return List.generate(limit, (index) {
      final productIndex = (page - 1) * limit + index + 1;
      final basePrice = 50.0 + (index * 25.0);
      
      final product = <String, dynamic>{
        'id': 'prod_$productIndex',
        'name': 'Product $productIndex ${category ?? 'Generic'}',
        'price': basePrice,
        'category': category ?? 'electronics',
      };
      
      // Add detailed fields for authenticated users
      if (!isPublic) {
        product.addAll({
          'description': 'Detailed description for Product $productIndex',
          'sku': 'SKU-$productIndex',
          'active': activeOnly,
          'created_at': DateTime.now().subtract(Duration(days: productIndex)).toIso8601String(),
        });
        
        if (includeStock) {
          product['stock'] = index * 10;
          product['stock_status'] = index > 0 ? 'in_stock' : 'out_of_stock';
        }
        
        if (includeSupplier) {
          product['supplier'] = {
            'id': 'supplier_${index % 3 + 1}',
            'name': 'Supplier ${index % 3 + 1}',
            'contact': 'supplier${index % 3 + 1}@example.com'
          };
        }
      }
      
      return product;
    });
  }
  
  Map<String, dynamic>? _getMockProduct(String productId) {
    // Simulate product search
    if (!productId.startsWith('prod_')) return null;
    
    return {
      'id': productId,
      'name': 'Sample Product',
      'description': 'Detailed product description...',
      'price': 299.99,
      'category': 'electronics',
      'sku': 'SKU-123',
      'specifications': {
        'color': 'black',
        'weight': '2.5kg',
        'dimensions': '30x20x10 cm'
      },
      'tags': ['popular', 'bestseller'],
      'active': true,
      'stock': 50,
      'created_at': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      'updated_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
    };
  }
  
  List<Map<String, dynamic>> _getMockReviews(String productId) {
    return [
      {
        'id': 'review_1',
        'user': 'customer_123',
        'rating': 5,
        'comment': 'Excellent product!',
        'created_at': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'review_2',
        'user': 'customer_456',
        'rating': 4,
        'comment': 'Good quality, fast delivery.',
        'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      }
    ];
  }
  
  List<Map<String, dynamic>> _getMockRelatedProducts(String productId) {
    return [
      {'id': 'prod_related_1', 'name': 'Related Product 1', 'price': 199.99},
      {'id': 'prod_related_2', 'name': 'Related Product 2', 'price': 149.99},
    ];
  }
  
  Map<String, dynamic> _validateProductData(
    Map<String, dynamic> data, {
    bool isCreate = false,
    bool isCompleteUpdate = false,
    bool isPartialUpdate = false,
    bool validateStock = true,
  }) {
    
    final errors = <String>[];
    
    // Required fields for creation or full update
    final requiredFields = ['name', 'price', 'category'];
    if (isCreate || isCompleteUpdate) {
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          errors.add('Field $field is required');
        }
      }
    }
    
    // Validate specific fields if present
    if (data.containsKey('name')) {
      final name = data['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        errors.add('Product name cannot be empty');
      } else if (name.length < 3 || name.length > 100) {
        errors.add('Product name must be between 3 and 100 characters');
      }
    }
    
    if (data.containsKey('price')) {
      final price = data['price'];
      if (price is! num || price <= 0) {
        errors.add('Price must be a positive number');
      } else if (price > 999999.99) {
        errors.add('Price cannot exceed 999,999.99');
      }
    }
    
    if (data.containsKey('category')) {
      final category = data['category'] as String?;
      final validCategories = ['electronics', 'clothing', 'books', 'home', 'sports', 'toys'];
      if (category == null || !validCategories.contains(category)) {
        errors.add('Invalid category. Valid options: ${validCategories.join(', ')}');
      }
    }
    
    if (data.containsKey('stock') && validateStock) {
      final stock = data['stock'];
      if (stock is! int || stock < 0) {
        errors.add('Stock must be a non-negative integer');
      }
    }
    
    if (data.containsKey('sku')) {
      final sku = data['sku'] as String?;
      if (sku != null && (sku.length < 3 || sku.length > 20)) {
        errors.add('SKU must be between 3 and 20 characters');
      }
    }
    
    return {
      'valid': errors.isEmpty,
      'errors': errors,
    };
  }
  
  bool _productExists(String productId) {
    // Simulation - in a real implementation, query the database
    return productId.startsWith('prod_') && productId.length >= 10;
  }
  
  List<String> _checkProductDependencies(String productId) {
    // Simulation - in a real implementation, query dependencies
    if (productId == 'prod_123') {
      return ['active_orders', 'shopping_carts', 'wishlists'];
    }
    return [];
  }
}
```

## 🔧 Server Configuration

```dart
void main() async {
  final server = ApiServer(config: ServerConfig.production());
  
  // Configure JWT
  server.configureJWTAuth(
    jwtSecret: 'your-256-bit-secret-key-for-products-api',
    excludePaths: ['/api/products/search', '/health'], // Public paths
  );
  
  await server.start(
    host: '0.0.0.0',
    port: 8080,
    // Controllers auto-discovered
  );
  
  print('🚀 Product CRUD API running on http://localhost:8080');
  print('📚 API Documentation:');
  print('   GET  /api/products/search      → Public search');
  print('   GET  /api/products             → List all (auth required)');
  print('   GET  /api/products/{id}        → Get single (auth required)');
  print('   POST /api/products             → Create (manager required)');
  print('   PUT  /api/products/{id}        → Update complete (manager required)');
  print('   PATCH /api/products/{id}       → Update partial (manager required)');
  print('   DELETE /api/products/{id}      → Delete (admin required)');
}
```

## 📊 API Testing

### 1. Public Search (No Authentication)
```bash
# Basic search
curl "http://localhost:8080/api/products/search?q=phone&category=electronics"

# With pagination
curl "http://localhost:8080/api/products/search?page=2&limit=10"
```

### 2. Full List (Authentication Required)
```bash
# List with advanced filters
curl -H "Authorization: Bearer <user_token>" \
     "http://localhost:8080/api/products?min_price=100&max_price=500&include_stock=true"
```

### 3. Create Product (Manager Required)
```bash
curl -X POST \
     -H "Authorization: Bearer <manager_token>" \
     -H "Content-Type: application/json" \
     -d 
{
  "name": "New Smartphone",
  "description": "Latest model with advanced features",
  "price": 699.99,
  "category": "electronics",
  "stock": 50,
  "sku": "PHONE-2024-01"
}
 \
     "http://localhost:8080/api/products"
```

### 4. Partial Update (Manager)
```bash
curl -X PATCH \
     -H "Authorization: Bearer <manager_token>" \
     -H "Content-Type: application/json" \
     -d 
{
  "price": 649.99,
  "stock": 75
}
 \
     "http://localhost:8080/api/products/prod_123"
```

### 5. Deletion (Admin Required)
```bash
curl -X DELETE \
     -H "Authorization: Bearer <admin_token>" \
     -H "X-Confirm-Delete: CONFIRM_DELETE" \
     "http://localhost:8080/api/products/prod_123?force=true"
```

## 💡 Best Practices Implemented

### ✅ Security
- **Multi-level authentication**: Different permissions for different operations
- **Time-based validation**: Critical operations only during business hours
- **Deletion confirmation**: Specific headers for destructive operations
- **Input validation**: Exhaustive validation of all fields

### ✅ Usability
- **Public endpoints**: Basic search without authentication
- **Flexible filters**: Multiple filtering and sorting options
- **Pagination**: To handle large datasets
- **Contextual information**: Responses that include user and context information

### ✅ Maintainability
- **Reusable validators**: Modular validation logic
- **Separation of concerns**: Private methods for specific logic
- **Inline documentation**: Clear description of each endpoint
- **Consistent error handling**: Standard format for error responses

## 🎯 Use Cases Covered

1. **Unauthenticated client**: Can search for products with basic information
2. **Authenticated user**: Can view full details and use advanced filters
3. **Manager**: Can create and modify products
4. **Admin**: Can delete products with confirmation
5. **Time restrictions**: Critical operations only during business hours

This use case demonstrates a complete and professional implementation using all the features of `api_kit` to create a robust, secure, and scalable API.

--- 

**Next**: [Complete E-commerce API](ecommerce-api.md) | **Previous**: [Annotation Documentation](../annotations/README.md)
