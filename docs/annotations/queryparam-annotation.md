# @QueryParam - Annotation for Query Parameters

## 📋 Description

The `@QueryParam` annotation is used to capture query parameters from the URL. It allows extracting values from the query string after the `?` and automatically converting them to method parameters.

## 🎯 Purpose

- **Data filtering**: Apply filters to lists and searches (`?category=electronics&active=true`)
- **Pagination**: Control page and number of results (`?page=1&limit=10`)
- **Response configuration**: Modify the format or content (`?format=json&include_metadata=true`)
- **Optional parameters**: Values that may or may not be present

## 📝 Syntax

### Specific Parameter (Traditional Method)
```dart
@QueryParam(
  String name,                    // Name of the parameter in the query string (REQUIRED)
  {bool required = false,         // If the parameter is mandatory
   dynamic defaultValue,          // Default value if not provided  
   String? description}           // Description of the parameter
)
```

### 🆕 All Parameters (Enhanced Method)
```dart
@QueryParam.all({
  bool required = false,          // If the parameters are mandatory
  String? description             // Description of the parameters
})
// Returns: Map<String, String> with ALL query parameters
```

## 🔧 Parameters

### For `@QueryParam('name')`
| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `name` | `String` | ✅ Yes | - | Exact name of the parameter in the query string |
| `required` | `bool` | ❌ No | `false` | If the parameter must be present in the request |
| `defaultValue` | `dynamic` | ❌ No | `null` | Value used when the parameter is not present |
| `description` | `String?` | ❌ No | `null` | Description of the purpose and expected format |

### 🆕 For `@QueryParam.all()`
| Parameter | Type | Required | Default Value | Description |
|-----------|------|-------------|-------------------|-------------|
| `required` | `bool` | ❌ No | `false` | If there must be at least one query parameter |
| `description` | `String?` | ❌ No | `'All query parameters as Map<String, String>'` | Description of all parameters |

## 🚀 Usage Examples

### Basic Example - Optional Parameters (Traditional Method)
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
        'query': searchQuery,           // null if not provided
        'category': category,           // null if not provided
        'active_only': activeOnly,      // true by default
      },
      'results': searchQuery != null ? [] : null
    }));
  }
}
```

### 🆕 Basic Example - ALL Parameters (Enhanced Method)
```dart
@RestController(basePath: '/api/products')
class ProductController extends BaseController { 
  
  @Get(path: '/search')  // URL: /api/products/search
  Future<Response> searchProductsEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL params
    @RequestMethod() String method,                         // 🆕 Direct HTTP method
    @RequestPath() String path,                            // 🆕 Direct path
    // 🎉 NO Request request needed!
  ) async { 
    
    // Extract specific parameters from the Map
    final searchQuery = allQueryParams['q'];
    final category = allQueryParams['category'];
    final activeOnly = allQueryParams['active'] == 'true' || allQueryParams['active'] == null;
    
    // Get all dynamic filters
    final filters = allQueryParams.entries
      .where((entry) => entry.key.startsWith('filter_'))
      .map((entry) => '${entry.key}: ${entry.value}')
      .toList();
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced product search executed',
      'framework_improvement': 'No manual Request parameter needed!',
      'request_info': {
        'method': method,              // Without request.method
        'path': path,                  // Without request.url.path
      },
      'search_params': {
        'query': searchQuery,
        'category': category, 
        'active_only': activeOnly,
        'total_params': allQueryParams.length,
        'all_params': allQueryParams,      // All parameters available
        'dynamic_filters': filters,       // Dynamic filters detected
      },
    }));
  }
}
```

**Testing URLs:**
```bash
# No parameters
curl http://localhost:8080/api/products/search

# With some parameters
curl "http://localhost:8080/api/products/search?q=laptop&category=electronics"

# With all parameters + dynamic filters (🆕 Enhanced captures EVERYTHING)
curl "http://localhost:8080/api/products/search?q=gaming&category=electronics&active=false&filter_price_min=100&filter_brand=apple&debug=true"
```

### Example with Required Parameters (Traditional)
```dart
@Get(path: '/reports')
Future<Response> generateReport(
  Request request,
  @QueryParam('start_date', required: true, description: 'Start date in YYYY-MM-DD format') String startDate,
  @QueryParam('end_date', required: true, description: 'End date in YYYY-MM-DD format') String endDate,
  @QueryParam('format', defaultValue: 'json', description: 'Report format') String format,
) async { 
  
  // Validate date format
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

### 🆕 Example with Required Parameters (Enhanced)
```dart
@Get(path: '/reports')
Future<Response> generateReportEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 All parameters
  @RequestMethod() String method,                            // 🆕 HTTP method
  @RequestUrl() Uri fullUrl,                                // 🆕 Full URL
  // NO Request request needed! 🎉
) async { 
  
  // Extract required parameters
  final startDate = allQueryParams['start_date'];
  final endDate = allQueryParams['end_date'];
  final format = allQueryParams['format'] ?? 'json';
  
  // Validation of required parameters
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
  
  // Validate date format
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
  
  // Extract additional dynamic parameters
  final additionalParams = Map.fromEntries(
    allQueryParams.entries.where((entry) => 
      !['start_date', 'end_date', 'format'].contains(entry.key))
  );
  
  return jsonResponse(jsonEncode({
    'message': 'Enhanced report generated successfully',
    'framework_improvement': 'All parameters captured automatically!',
    'request_info': {
      'method': method,                 // Without request.method
      'full_url': fullUrl.toString(),   // Without request.url
    },
    'parameters': {
      'start_date': startDate,
      'end_date': endDate,
      'format': format,
      'period_days': end.difference(start).inDays,
      'total_params': allQueryParams.length,
      'all_params': allQueryParams,
      'additional_params': additionalParams,  // Additional parameters captured
    }
  }));
}
```

### Complete Pagination with Enhanced Parameters
```dart
@Get(path: '/list')
Future<Response> getProductListEnhanced(
  @QueryParam.all() Map<String, String> allQueryParams,     // 🆕 All parameters
  @RequestHeader.all() Map<String, String> allHeaders,      // 🆕 All headers
  @RequestHost() String host,                               // 🆕 Direct host
  @RequestPath() String path,                              // 🆕 Direct path
) async { 
  
  // Extract pagination parameters
  final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
  final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;
  final sortBy = allQueryParams['sort_by'] ?? 'name';
  final sortOrder = allQueryParams['sort_order'] ?? 'asc';
  
  // Extract all dynamic filters
  final filters = Map.fromEntries(
    allQueryParams.entries.where((entry) => 
      !['page', 'limit', 'sort_by', 'sort_order'].contains(entry.key))
  );
  
  // Simulate paginated data
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
      'host': host,              // Without request.url.host
      'path': path,              // Without request.url.path
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

## 🎯 Common Use Cases

### 1. **Basic Search**
```dart
// Traditional
@QueryParam('q', required: false) String? query,

// 🆕 Enhanced - captures dynamic searches
@QueryParam.all() Map<String, String> allParams,
// Allows: ?q=text&search_title=title&search_description=desc
```

### 2. **Pagination**
```dart
// Traditional
@QueryParam('page', defaultValue: 1) int page,
@QueryParam('limit', defaultValue: 10) int limit,

// 🆕 Enhanced - pagination + dynamic filters
@QueryParam.all() Map<String, String> allParams,
// Allows: ?page=1&limit=10&offset=20&filter_category=tech&filter_price_max=100
```

### 3. **Response Configuration**
```dart
// Traditional
@QueryParam('format', defaultValue: 'json') String format,
@QueryParam('include_metadata', defaultValue: false) bool includeMeta,

// 🆕 Enhanced - dynamic configurations
@QueryParam.all() Map<String, String> allParams,
// Allows: ?format=xml&include_metadata=true&include_stats=true&debug=true
```

### 4. **Complex Filters**
```dart
// 🆕 Enhanced - completely dynamic filters
@QueryParam.all() Map<String, String> allParams,
// Allows: ?filter_price_min=10&filter_price_max=100&filter_brand=apple&filter_condition=new
```

## ⚡ Advantages of the Enhanced Method

### ✅ Benefits
1. **Total Flexibility**: Capture any parameter without defining it beforehand
2. **Less Boilerplate**: You don't need `Request request` 
3. **Dynamic Filters**: Allows filters you don't know at development time
4. **Better Scalability**: Easy to add new parameters without changing code
5. **Improved Debugging**: You can see all parameters in logs

### ⚠️ Considerations
1. **Manual Validation**: You must validate types and values manually
2. **Documentation**: Parameters are not explicit in the function
3. **Type Safety**: You lose automatic typing (everything comes as a String)

## 🔄 Migration from Traditional to Enhanced

### Step 1: Replace individual parameters
```dart
// Before
@QueryParam('page') int page,
@QueryParam('limit') int limit,
@QueryParam('category') String? category,

// After  
@QueryParam.all() Map<String, String> allQueryParams,
```

### Step 2: Extract parameters from the Map
```dart
// Extract and convert types
final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10; 
final category = allQueryParams['category'];
```

### Step 3: Remove Request parameter
```dart
// Before
Future<Response> endpoint(Request request, @QueryParam('x') int x) async {

// After
Future<Response> endpoint(@QueryParam.all() Map<String, String> params) async {
```

## 🎯 When to Use Each Method

| **Scenario** | **Traditional Method** | **Enhanced Method** |
|---------------|------------------------|-------------------|
| **Stable API** | ✅ Better typing | ❌ Less explicit |
| **Dynamic filters** | ❌ Limited | ✅ Perfect |
| **Rapid prototyping** | ❌ More code | ✅ More flexible |
| **Public APIs** | ✅ Clear documentation | ⚠️ Requires extra docs |
| **Debugging** | ❌ Limited parameters | ✅ See all params |
| **Type safety** | ✅ Automatic typing | ❌ Manual typing |

## 🔗 Combinations with Other Annotations

### With Enhanced Headers
```dart
@Get(path: '/search')
Future<Response> searchWithHeaders(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestHeader.all() Map<String, String> allHeaders,
  @RequestMethod() String method,
) async {
  // You have full access to query params, headers, and method
}
```

### With JWT
```dart
@Get(path: '/user-search')
@JWTEndpoint([MyUserValidator()])
Future<Response> userSearch(
  @QueryParam.all() Map<String, String> allQueryParams,
  @RequestContext('jwt_payload') Map<String, dynamic> jwt,
) async {
  // Custom search based on user + dynamic parameters
}
```

### With Request Body
```dart
@Post(path: '/advanced-search')
Future<Response> advancedSearch(
  @RequestBody() Map<String, dynamic> searchCriteria,
  @QueryParam.all() Map<String, String> allQueryParams,
) async {
  // Complex search with criteria in body and parameters in query
}
```

---

**🚀 With @QueryParam.all(), you have full access to all query parameters without needing to define them beforehand, eliminating the manual Request parameter and creating more flexible APIs!**
