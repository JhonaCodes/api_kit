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