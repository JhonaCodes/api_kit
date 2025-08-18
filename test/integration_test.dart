import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:api_kit/api_kit.dart';

/// Test controller with all HTTP methods for comprehensive testing.
@Controller('/api/test')
class TestController extends BaseController {
  static final List<Map<String, dynamic>> _data = [
    {'id': '1', 'name': 'Test Item 1', 'value': 100},
    {'id': '2', 'name': 'Test Item 2', 'value': 200},
  ];



  @GET('/')
  Future<Response> getAll(Request request) async {
    logRequest(request, 'Getting all items');
    final response = ApiResponse.success(_data, 'Items retrieved successfully');
    return jsonResponse(response.toJson());
  }

  @GET('/<id>')
  Future<Response> getById(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Getting item $id');
    
    final item = _data.firstWhere((i) => i['id'] == id, orElse: () => {});
    
    final response = item.isEmpty 
        ? ApiResponse.notFound('Item not found')
        : ApiResponse.success(item);
    
    final statusCode = item.isEmpty ? 404 : 200;
    return jsonResponse(response.toJson(), statusCode: statusCode);
  }

  @POST('/')
  Future<Response> create(Request request) async {
    logRequest(request, 'Creating new item');
    
    final body = await request.readAsString();
    if (body.isEmpty) {
      final response = ApiResponse.badRequest('Request body is required');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
    
    try {
      final data = jsonDecode(body);
      final newItem = {
        'id': '${_data.length + 1}',
        'name': data['name'] ?? 'New Item',
        'value': data['value'] ?? 0,
      };
      
      _data.add(newItem);
      
      final response = ApiResponse.success(newItem, 'Item created successfully');
      return jsonResponse(response.toJson(), statusCode: 201);
    } catch (e) {
      final response = ApiResponse.badRequest('Invalid JSON format');
      return jsonResponse(response.toJson(), statusCode: 400);
    }
  }

  @PUT('/<id>')
  Future<Response> update(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Updating item $id');
    
    final itemIndex = _data.indexWhere((i) => i['id'] == id);
    if (itemIndex == -1) {
      final response = ApiResponse.notFound('Item not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    final body = await request.readAsString();
    if (body.isNotEmpty) {
      try {
        final data = jsonDecode(body);
        _data[itemIndex]['name'] = data['name'] ?? _data[itemIndex]['name'];
        _data[itemIndex]['value'] = data['value'] ?? _data[itemIndex]['value'];
      } catch (e) {
        final response = ApiResponse.badRequest('Invalid JSON format');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
    }
    
    final response = ApiResponse.success(_data[itemIndex], 'Item updated successfully');
    return jsonResponse(response.toJson());
  }

  @DELETE('/<id>')
  Future<Response> delete(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Deleting item $id');
    
    final itemIndex = _data.indexWhere((i) => i['id'] == id);
    if (itemIndex == -1) {
      final response = ApiResponse.notFound('Item not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    _data.removeAt(itemIndex);
    
    final response = ApiResponse.success(null, 'Item deleted successfully');
    return jsonResponse(response.toJson());
  }

  @GET('/health')
  Future<Response> health(Request request) async {
    print('🏥 HEALTH ENDPOINT CALLED! 🏥');
    logRequest(request, 'Health check requested');
    final response = {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '0.0.1'
    };
    return jsonResponse(jsonEncode(response));
  }

  @GET('/search')
  Future<Response> search(Request request) async {
    logRequest(request, 'Search with query parameters');
    
    // Get query parameters
    final query = getOptionalQueryParam(request, 'q', 'all');
    final limit = getOptionalQueryParam(request, 'limit', '10');
    final offset = getOptionalQueryParam(request, 'offset', '0');
    final sortBy = getOptionalQueryParam(request, 'sort_by', 'name');
    final order = getOptionalQueryParam(request, 'order', 'asc');
    
    // Filter data based on query
    var filteredData = _data.where((item) {
      if (query == 'all') return true;
      return item['name'].toString().toLowerCase().contains(query?.toLowerCase() ?? '');
    }).toList();
    
    // Apply sorting
    filteredData.sort((a, b) {
      final aValue = a[sortBy] ?? '';
      final bValue = b[sortBy] ?? '';
      final result = aValue.toString().compareTo(bValue.toString());
      return order == 'desc' ? -result : result;
    });
    
    // Apply pagination
    final limitInt = int.tryParse(limit ?? '10') ?? 10;
    final offsetInt = int.tryParse(offset ?? '0') ?? 0;
    final paginatedData = filteredData.skip(offsetInt).take(limitInt).toList();
    
    final response = ApiResponse.success({
      'items': paginatedData,
      'total': filteredData.length,
      'limit': limitInt,
      'offset': offsetInt,
      'query': query,
      'sort_by': sortBy,
      'order': order,
    }, 'Search completed successfully');
    
    return jsonResponse(response.toJson());
  }

  @GET('/filter')
  Future<Response> filter(Request request) async {
    logRequest(request, 'Filter with multiple query parameters');
    
    // Get all query parameters
    final allParams = getAllQueryParams(request);
    
    // Extract specific filters
    final minValue = getOptionalQueryParam(request, 'min_value');
    final maxValue = getOptionalQueryParam(request, 'max_value');
    final name = getOptionalQueryParam(request, 'name');
    final hasValue = getOptionalQueryParam(request, 'has_value');
    
    // Apply filters
    var filteredData = _data.where((item) {
      // Filter by min value
      if (minValue != null) {
        final itemValue = item['value'] as int? ?? 0;
        final min = int.tryParse(minValue) ?? 0;
        if (itemValue < min) return false;
      }
      
      // Filter by max value
      if (maxValue != null) {
        final itemValue = item['value'] as int? ?? 0;
        final max = int.tryParse(maxValue) ?? 999999;
        if (itemValue > max) return false;
      }
      
      // Filter by name (partial match)
      if (name != null) {
        final itemName = item['name'].toString().toLowerCase();
        if (!itemName.contains(name.toLowerCase())) return false;
      }
      
      // Filter by has_value (boolean)
      if (hasValue != null) {
        final shouldHaveValue = hasValue.toLowerCase() == 'true';
        final itemValue = item['value'] as int? ?? 0;
        if (shouldHaveValue && itemValue == 0) return false;
        if (!shouldHaveValue && itemValue != 0) return false;
      }
      
      return true;
    }).toList();
    
    final response = ApiResponse.success({
      'items': filteredData,
      'total': filteredData.length,
      'filters_applied': allParams,
      'available_filters': {
        'min_value': 'number',
        'max_value': 'number', 
        'name': 'string (partial match)',
        'has_value': 'boolean'
      }
    }, 'Filter applied successfully');
    
    return jsonResponse(response.toJson());
  }

  @GET('/headers-test')
  Future<Response> headersTest(Request request) async {
    logRequest(request, 'Testing header extraction');
    
    // Extract headers
    final userAgent = getOptionalHeader(request, 'user-agent', 'unknown');
    final contentType = getOptionalHeader(request, 'content-type', 'not-set');
    final customHeader = getOptionalHeader(request, 'x-custom-header', 'not-provided');
    final authorization = getOptionalHeader(request, 'authorization');
    
    final response = ApiResponse.success({
      'user_agent': userAgent,
      'content_type': contentType,
      'custom_header': customHeader,
      'has_authorization': authorization != null,
      'all_headers': request.headers.keys.toList(),
    }, 'Headers extracted successfully');
    
    return jsonResponse(response.toJson());
  }
}

void main() {
  group('API Kit Integration Tests', () {
    late HttpServer server;
    late String baseUrl;
    
    setUpAll(() async {
      // Start the server
      final apiServer = ApiServer(config: ServerConfig.development());
      
      // Debug: Check if reflection is available
      print('Reflection available: ${ReflectionHelper.isReflectionAvailable}');
      
      final result = await apiServer.start(
        host: 'localhost',
        port: 0, // Use any available port
        controllerList: [TestController()],
      );
      
      result.when(
        ok: (httpServer) {
          server = httpServer;
          baseUrl = 'http://localhost:${server.port}';
          print('Test server started on $baseUrl');
        },
        err: (error) {
          throw Exception('Failed to start test server: ${error.msm}');
        },
      );
    });

    tearDownAll(() async {
      await server.close();
      print('Test server stopped');
    });

    group('Health Check', () {
      test('should return healthy status', () async {
        // Test multiple possible URLs to debug the routing
        print('Testing health endpoint at: $baseUrl/api/test/health');
        final response = await http.get(Uri.parse('$baseUrl/api/test/health'));
        
        if (response.statusCode != 200) {
          print('Health check failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
          
          // Try alternative URL
          print('Trying alternative: $baseUrl/health');
          final altResponse = await http.get(Uri.parse('$baseUrl/health'));
          print('Alternative response: ${altResponse.statusCode}');
        }
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['status'], equals('healthy'));
        expect(data['version'], equals('0.0.1'));
        expect(data['timestamp'], isNotNull);
      });
    });

    group('GET Endpoints', () {
      test('should get all items', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/'));
        
        expect(response.statusCode, equals(200));
        expect(response.headers['content-type'], contains('application/json'));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data'], isList);
        expect(data['data'].length, greaterThan(0));
        expect(data['message'], equals('Items retrieved successfully'));
      });

      test('should get item by id', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/1'));
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['id'], equals('1'));
        expect(data['data']['name'], equals('Test Item 1'));
      });

      test('should return 404 for non-existent item', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/999'));
        
        expect(response.statusCode, equals(404));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('Item not found'));
      });
    });

    group('POST Endpoints', () {
      test('should create new item', () async {
        final newItem = {'name': 'Test Item 3', 'value': 300};
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/test/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newItem),
        );
        
        expect(response.statusCode, equals(201));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['name'], equals('Test Item 3'));
        expect(data['data']['value'], equals(300));
        expect(data['message'], equals('Item created successfully'));
      });

      test('should return 400 for empty body', () async {
        final response = await http.post(Uri.parse('$baseUrl/api/test/'));
        
        expect(response.statusCode, equals(400));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('Request body is required'));
      });
    });

    group('PUT Endpoints', () {
      test('should update existing item', () async {
        final updateData = {'name': 'Updated Item 1', 'value': 150};
        
        final response = await http.put(
          Uri.parse('$baseUrl/api/test/1'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updateData),
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['name'], equals('Updated Item 1'));
        expect(data['data']['value'], equals(150));
        expect(data['message'], equals('Item updated successfully'));
      });

      test('should return 404 for non-existent item update', () async {
        final updateData = {'name': 'Updated Item 999'};
        
        final response = await http.put(
          Uri.parse('$baseUrl/api/test/999'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updateData),
        );
        
        expect(response.statusCode, equals(404));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('Item not found'));
      });
    });

    group('DELETE Endpoints', () {
      test('should delete existing item', () async {
        final response = await http.delete(Uri.parse('$baseUrl/api/test/2'));
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['message'], equals('Item deleted successfully'));
        
        // Verify item is actually deleted
        final getResponse = await http.get(Uri.parse('$baseUrl/api/test/2'));
        expect(getResponse.statusCode, equals(404));
      });

      test('should return 404 for non-existent item deletion', () async {
        final response = await http.delete(Uri.parse('$baseUrl/api/test/999'));
        
        expect(response.statusCode, equals(404));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('Item not found'));
      });
    });

    group('Security Features', () {
      test('should include security headers', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/health'));
        
        expect(response.headers['x-frame-options'], isNotNull);
        expect(response.headers['x-content-type-options'], isNotNull);
        expect(response.headers['x-request-id'], isNotNull);
      });

      test('should handle request size limits', () async {
        final largeBody = 'x' * (60 * 1024 * 1024); // 60MB - exceeds dev limit
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/test/'),
          headers: {'Content-Type': 'application/json'},
          body: largeBody,
        );
        
        expect(response.statusCode, equals(413)); // Request Entity Too Large
      });
    });

    group('Query Parameters', () {
      test('should handle search with query parameters', () async {
        final response = await http.get(
          Uri.parse('$baseUrl/api/test/search?q=test&limit=5&offset=0&sort_by=name&order=asc'),
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['query'], equals('test'));
        expect(data['data']['limit'], equals(5));
        expect(data['data']['offset'], equals(0));
        expect(data['data']['sort_by'], equals('name'));
        expect(data['data']['order'], equals('asc'));
        expect(data['data'], contains('items'));
        expect(data['data'], contains('total'));
      });

      test('should handle search with default parameters', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/search'));
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['query'], equals('all'));
        expect(data['data']['limit'], equals(10));
        expect(data['data']['offset'], equals(0));
        expect(data['data']['sort_by'], equals('name'));
        expect(data['data']['order'], equals('asc'));
      });

      test('should handle multiple filter parameters', () async {
        final response = await http.get(
          Uri.parse('$baseUrl/api/test/filter?min_value=50&max_value=250&name=test&has_value=true'),
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['filters_applied']['min_value'], equals('50'));
        expect(data['data']['filters_applied']['max_value'], equals('250'));
        expect(data['data']['filters_applied']['name'], equals('test'));
        expect(data['data']['filters_applied']['has_value'], equals('true'));
        expect(data['data'], contains('available_filters'));
      });

      test('should handle partial query parameters', () async {
        final response = await http.get(
          Uri.parse('$baseUrl/api/test/filter?min_value=100'),
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['filters_applied']['min_value'], equals('100'));
        expect(data['data']['filters_applied'], hasLength(1));
      });

      test('should handle no query parameters', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/filter'));
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['filters_applied'], isEmpty);
        expect(data['data']['total'], greaterThan(0));
      });
    });

    group('Headers Handling', () {
      test('should extract headers correctly', () async {
        final response = await http.get(
          Uri.parse('$baseUrl/api/test/headers-test'),
          headers: {
            'X-Custom-Header': 'test-value',
            'Authorization': 'Bearer token123',
            'Content-Type': 'application/json',
          },
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['custom_header'], equals('test-value'));
        expect(data['data']['has_authorization'], isTrue);
        expect(data['data']['content_type'], equals('application/json'));
        expect(data['data']['user_agent'], isNotNull);
        expect(data['data']['all_headers'], isList);
      });

      test('should handle missing headers with defaults', () async {
        final response = await http.get(Uri.parse('$baseUrl/api/test/headers-test'));
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['custom_header'], equals('not-provided'));
        expect(data['data']['has_authorization'], isFalse);
        expect(data['data']['user_agent'], isNot(equals('unknown'))); // http package sets user-agent
      });
    });

    group('Complex Parameter Combinations', () {
      test('should handle search with complex query string', () async {
        final uri = Uri.parse('$baseUrl/api/test/search').replace(
          queryParameters: {
            'q': 'Item 1',
            'limit': '1',
            'offset': '0',
            'sort_by': 'value',
            'order': 'desc',
          },
        );
        
        final response = await http.get(uri);
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['items'], hasLength(1));
        expect(data['data']['query'], equals('Item 1'));
        expect(data['data']['sort_by'], equals('value'));
        expect(data['data']['order'], equals('desc'));
      });

      test('should handle URL encoded query parameters', () async {
        final response = await http.get(
          Uri.parse('$baseUrl/api/test/search?q=Test%20Item&sort_by=name&order=asc'),
        );
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isTrue);
        expect(data['data']['query'], equals('Test Item'));
      });
    });

    group('Error Handling', () {
      test('should handle invalid JSON gracefully', () async {
        final response = await http.post(
          Uri.parse('$baseUrl/api/test/'),
          headers: {'Content-Type': 'application/json'},
          body: '{invalid json}',
        );
        
        // Should return 400 Bad Request for invalid JSON
        expect(response.statusCode, equals(400));
        
        final data = jsonDecode(response.body);
        expect(data['success'], isFalse);
        expect(data['error'], equals('Invalid JSON format'));
      });

      test('should return 404 for non-existent routes', () async {
        final response = await http.get(Uri.parse('$baseUrl/non-existent'));
        
        expect(response.statusCode, equals(404));
      });
    });
  });
}