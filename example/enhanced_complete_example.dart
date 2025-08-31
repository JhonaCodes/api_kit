/// 🚀 Complete Enhanced API Kit Example - Before & After Comparison
/// 
/// This example demonstrates the complete transformation of api_kit from
/// traditional Request-based parameters to Enhanced annotations that eliminate
/// the need for manual Request parameters.
///
/// DEMONSTRATES:
/// 1. Traditional methods (with Request parameter)
/// 2. 🆕 Enhanced methods (without Request parameter)
/// 3. Complete CRUD operations in both styles
/// 4. JWT integration in both approaches
/// 5. Real-world usage patterns

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🚀 Complete Enhanced API Kit Example - Before & After Comparison');

  final server = ApiServer.create()
    .configureJWT(
      jwtSecret: 'your-super-secret-jwt-key-256-bits-long!',
      excludePaths: ['/api/public', '/health'],
    )
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8090,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🎯 Server running at http://localhost:8090');
      print('📋 Available endpoints with Traditional vs Enhanced comparison:');
      print('');
      print('🔴 TRADITIONAL methods (with Request parameter):');
      print('   GET    /api/traditional/users        - List users (traditional)');
      print('   POST   /api/traditional/users        - Create user (traditional)');
      print('   GET    /api/traditional/users/{id}   - Get user (traditional)');
      print('   PUT    /api/traditional/users/{id}   - Update user (traditional)');
      print('   DELETE /api/traditional/users/{id}   - Delete user (traditional)');
      print('');
      print('🆕 ENHANCED methods (without Request parameter):');
      print('   GET    /api/enhanced/users           - List users (enhanced)');
      print('   POST   /api/enhanced/users           - Create user (enhanced)');
      print('   GET    /api/enhanced/users/{id}      - Get user (enhanced)');
      print('   PUT    /api/enhanced/users/{id}      - Update user (enhanced)');
      print('   DELETE /api/enhanced/users/{id}      - Delete user (enhanced)');
      print('');
      print('🎯 Testing commands:');
      print('   # Traditional approach');
      print('   curl "http://localhost:8090/api/traditional/users?page=1&limit=5"');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"name":"John Doe","email":"john@example.com"}\' http://localhost:8090/api/traditional/users');
      print('');
      print('   # Enhanced approach (captures everything automatically)');
      print('   curl "http://localhost:8090/api/enhanced/users?page=1&limit=5&sort=name&filter_active=true&debug=true"');
      print('   curl -X POST -H "Content-Type: application/json" -H "User-Agent: TestClient/1.0" -H "X-Request-ID: req123" -d \'{"name":"John Doe","email":"john@example.com"}\' http://localhost:8090/api/enhanced/users');
      print('');
      print('⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
      exit(1);
    },
  );
}

/// ❌ TRADITIONAL Controller - Uses Request parameter everywhere
@RestController(basePath: '/api/traditional')
class TraditionalController extends BaseController {

  /// Traditional GET - Manual Request parameter required
  @Get(path: '/users')
  Future<Response> getUsersTraditional(
    Request request,  // ← Required for everything
    @QueryParam('page', defaultValue: 1) int page,
    @QueryParam('limit', defaultValue: 10) int limit,
    @QueryParam('sort', required: false) String? sort,
  ) async {
    
    // Manual extractions from Request
    final method = request.method;
    final path = request.url.path;
    final allQueryParams = request.url.queryParameters;
    final allHeaders = request.headers;
    
    // Simulate user data
    final users = List.generate(limit, (index) => {
      'id': ((page - 1) * limit) + index + 1,
      'name': 'User ${((page - 1) * limit) + index + 1}',
      'email': 'user${((page - 1) * limit) + index + 1}@example.com',
      'active': true,
    });
    
    return jsonResponse(jsonEncode({
      'message': 'Traditional users retrieved',
      'method': 'TRADITIONAL - requires manual Request parameter',
      'request_info': {
        'method': method,                    // Manual extraction
        'path': path,                        // Manual extraction
        'manual_extractions_needed': 4,
      },
      'pagination': {
        'page': page,
        'limit': limit,
        'total': 100,
        'sort': sort,
      },
      'all_query_params': allQueryParams,    // Manual extraction
      'headers_count': allHeaders.length,    // Manual extraction
      'users': users,
      'framework_issue': 'Required Request parameter even though annotations handle data extraction',
    }));
  }

  /// Traditional POST - Manual Request parameter + parsing
  @Post(path: '/users')
  Future<Response> createUserTraditional(
    Request request,  // ← Required even though @RequestBody exists
    @RequestBody(required: true) Map<String, dynamic> userData,
  ) async {
    
    // Manual extractions (redundant because annotations could handle this)
    final method = request.method;
    final path = request.url.path;
    final allHeaders = request.headers;
    final userAgent = request.headers['user-agent'] ?? 'unknown';
    
    // Validate user data
    final name = userData['name'] as String?;
    final email = userData['email'] as String?;
    
    if (name == null || name.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Name is required',
        'method': 'TRADITIONAL',
      }));
    }
    
    if (email == null || !email.contains('@')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Valid email is required',
        'method': 'TRADITIONAL',
      }));
    }
    
    final userId = DateTime.now().millisecondsSinceEpoch;
    
    return jsonResponse(jsonEncode({
      'message': 'Traditional user created',
      'method': 'TRADITIONAL - manual Request extractions',
      'request_info': {
        'method': method,                    // Manual extraction
        'path': path,                        // Manual extraction
        'user_agent': userAgent,             // Manual extraction
        'headers_count': allHeaders.length,   // Manual extraction
      },
      'created_user': {
        'id': userId,
        'name': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      },
      'framework_redundancy': {
        'request_body_parsed': 'YES (by @RequestBody annotation)',
        'but_still_need_request': 'YES (for other data)',
        'manual_extractions': ['method', 'path', 'headers', 'user-agent'],
      },
    }));
  }

  /// Traditional PUT - Path param + manual extractions
  @Put(path: '/users/{id}')
  Future<Response> updateUserTraditional(
    Request request,  // ← Required for extractions
    @PathParam('id') String userId,
    @RequestBody(required: true) Map<String, dynamic> userData,
  ) async {
    
    // Manual extractions
    final method = request.method;
    final path = request.url.path;
    final allHeaders = request.headers;
    
    return jsonResponse(jsonEncode({
      'message': 'Traditional user updated',
      'method': 'TRADITIONAL',
      'request_info': {
        'method': method,                    // Manual
        'path': path,                        // Manual
        'headers_count': allHeaders.length,   // Manual
      },
      'updated_user': {
        'id': userId,
        'updated_data': userData,
        'updated_at': DateTime.now().toIso8601String(),
      },
    }));
  }

  /// Traditional DELETE
  @Delete(path: '/users/{id}')
  Future<Response> deleteUserTraditional(
    Request request,  // ← Still needed
    @PathParam('id') String userId,
  ) async {
    
    final method = request.method;
    final path = request.url.path;
    
    return jsonResponse(jsonEncode({
      'message': 'Traditional user deleted',
      'method': 'TRADITIONAL',
      'request_info': {
        'method': method,    // Manual
        'path': path,        // Manual
      },
      'deleted_user_id': userId,
      'deleted_at': DateTime.now().toIso8601String(),
    }));
  }
}

/// ✅ ENHANCED Controller - NO Request parameter needed!
@RestController(basePath: '/api/enhanced')
class EnhancedController extends BaseController {

  /// 🆕 Enhanced GET - NO Request parameter needed!
  @Get(path: '/users')
  Future<Response> getUsersEnhanced(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 All params automatically
    @RequestHeader.all() Map<String, String> allHeaders,   // 🆕 All headers automatically
    @RequestMethod() String method,                         // 🆕 HTTP method directly
    @RequestPath() String path,                            // 🆕 Path directly
    @RequestHost() String host,                            // 🆕 Host directly
    @RequestUrl() Uri fullUrl,                             // 🆕 Full URL directly
    // 🎉 NO Request request parameter needed!
  ) async {
    
    // Extract specific params from Map (with defaults)
    final page = int.tryParse(allQueryParams['page'] ?? '1') ?? 1;
    final limit = int.tryParse(allQueryParams['limit'] ?? '10') ?? 10;
    final sort = allQueryParams['sort'];
    
    // Extract all dynamic filters
    final filters = Map.fromEntries(
      allQueryParams.entries.where((entry) => 
        !['page', 'limit', 'sort'].contains(entry.key))
    );
    
    // Simulate user data
    final users = List.generate(limit, (index) => {
      'id': ((page - 1) * limit) + index + 1,
      'name': 'Enhanced User ${((page - 1) * limit) + index + 1}',
      'email': 'user${((page - 1) * limit) + index + 1}@enhanced.com',
      'active': true,
      'filters_applied': filters.isNotEmpty,
    });
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced users retrieved',
      'method': 'ENHANCED - NO manual Request parameter needed!',
      'framework_improvement': 'Direct parameter injection with annotations',
      'request_info': {
        'method': method,                    // Direct injection
        'path': path,                        // Direct injection
        'host': host,                        // Direct injection
        'full_url': fullUrl.toString(),      // Direct injection
        'user_agent': allHeaders['user-agent'] ?? 'unknown',
        'manual_extractions_needed': 0,      // Zero!
      },
      'pagination': {
        'page': page,
        'limit': limit,
        'total': 100,
        'sort': sort,
      },
      'dynamic_capabilities': {
        'all_query_params': allQueryParams,   // Everything captured
        'total_params': allQueryParams.length,
        'dynamic_filters': filters,           // Dynamic filters detected
        'filter_count': filters.length,
        'all_headers': allHeaders,            // Everything captured
        'headers_count': allHeaders.length,
      },
      'users': users,
      'framework_benefits': [
        'No manual Request parameter needed',
        'All query parameters captured automatically',
        'All headers captured automatically',
        'Direct access to request components',
        'Dynamic filter support',
        'Better debugging capabilities',
      ],
    }));
  }

  /// 🆕 Enhanced POST - Complete request data without Request!
  @Post(path: '/users')
  Future<Response> createUserEnhanced(
    @RequestBody() Map<String, dynamic> userData,          // Request body
    @RequestHeader.all() Map<String, String> allHeaders,   // All headers
    @QueryParam.all() Map<String, String> allQueryParams,  // All query params
    @RequestMethod() String method,                         // HTTP method
    @RequestPath() String path,                            // Request path
    @RequestUrl() Uri fullUrl,                             // Full URL
    // 🎉 Complete request access without Request parameter!
  ) async {
    
    // Validate user data
    final name = userData['name'] as String?;
    final email = userData['email'] as String?;
    
    if (name == null || name.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Name is required',
        'method': 'ENHANCED',
        'available_data': userData.keys.toList(),
      }));
    }
    
    if (email == null || !email.contains('@')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Valid email is required',
        'method': 'ENHANCED',
        'received_email': email,
      }));
    }
    
    final userId = DateTime.now().millisecondsSinceEpoch;
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final requestId = allHeaders['x-request-id'] ?? 'generated_${userId}';
    
    // Analyze additional context automatically captured
    final customHeaders = Map.fromEntries(
      allHeaders.entries.where((entry) => entry.key.startsWith('x-'))
    );
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced user created',
      'method': 'ENHANCED - complete request access without manual Request!',
      'framework_achievement': 'All request data available through annotations',
      'request_analysis': {
        'method': method,                    // Direct access
        'path': path,                        // Direct access
        'full_url': fullUrl.toString(),      // Direct access
        'user_agent': userAgent,             // From headers map
        'request_id': requestId,             // From headers map
        'custom_headers': customHeaders,     // Filtered automatically
        'total_headers': allHeaders.length,   // Count available
        'query_params': allQueryParams,      // All available
      },
      'created_user': {
        'id': userId,
        'name': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': userAgent,
        'request_id': requestId,
      },
      'framework_comparison': {
        'traditional_approach': {
          'request_parameter_needed': true,
          'manual_extractions': ['method', 'path', 'headers', 'user-agent'],
          'boilerplate_code': 'High',
        },
        'enhanced_approach': {
          'request_parameter_needed': false,
          'manual_extractions': [],
          'boilerplate_code': 'None',
          'additional_capabilities': ['dynamic_headers', 'automatic_filtering'],
        },
      },
    }));
  }

  /// 🆕 Enhanced PUT - Path param + comprehensive data access
  @Put(path: '/users/{id}')
  Future<Response> updateUserEnhanced(
    @PathParam('id') String userId,                         // Path parameter
    @RequestBody() Map<String, dynamic> userData,           // Request body
    @RequestHeader.all() Map<String, String> allHeaders,    // All headers
    @QueryParam.all() Map<String, String> allQueryParams,   // All query params
    @RequestMethod() String method,                          // HTTP method
    @RequestUrl() Uri fullUrl,                              // Full URL
    // 🎉 Everything available without Request parameter!
  ) async {
    
    // Comprehensive request analysis
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final contentType = allHeaders['content-type'] ?? 'unknown';
    final debugMode = allQueryParams['debug'] == 'true';
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced user updated',
      'method': 'ENHANCED - comprehensive request data access',
      'comprehensive_analysis': {
        'path_param': {'user_id': userId},
        'request_body': userData,
        'request_method': method,                // Direct
        'full_url': fullUrl.toString(),          // Direct
        'content_type': contentType,             // From headers
        'user_agent': userAgent,                 // From headers
        'debug_mode': debugMode,                 // From query params
        'total_headers': allHeaders.length,      // Count
        'total_query_params': allQueryParams.length, // Count
      },
      'updated_user': {
        'id': userId,
        'updated_data': userData,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': userAgent,
        'debug_info_included': debugMode,
      },
      'framework_power': {
        'single_request_object': false,
        'direct_parameter_injection': true,
        'comprehensive_data_access': true,
        'zero_boilerplate': true,
      },
    }));
  }

  /// 🆕 Enhanced DELETE - Clean and comprehensive
  @Delete(path: '/users/{id}')
  Future<Response> deleteUserEnhanced(
    @PathParam('id') String userId,                         // Path parameter
    @RequestHeader.all() Map<String, String> allHeaders,    // All headers
    @RequestMethod() String method,                          // HTTP method
    @RequestPath() String path,                             // Request path
    // 🎉 Clean, no Request parameter!
  ) async {
    
    final userAgent = allHeaders['user-agent'] ?? 'unknown';
    final authorization = allHeaders['authorization'];
    
    return jsonResponse(jsonEncode({
      'message': 'Enhanced user deleted',
      'method': 'ENHANCED - clean parameter injection',
      'clean_access': {
        'method': method,        // Direct
        'path': path,            // Direct
        'user_agent': userAgent, // From headers map
        'has_authorization': authorization != null,
      },
      'deleted_user': {
        'id': userId,
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': userAgent,
      },
      'code_quality': {
        'lines_of_boilerplate': 0,
        'manual_extractions': 0,
        'readability': 'High',
        'maintainability': 'Excellent',
      },
    }));
  }
}

/// 🎯 Comparison Demo Controller - Side by side examples
@RestController(basePath: '/api/comparison')
class ComparisonController extends BaseController {

  /// Direct comparison: Traditional vs Enhanced in same response
  @Get(path: '/demo')
  Future<Response> comparisonDemo(
    // Traditional parameters
    Request request,  // ← Still needed for traditional approach
    @QueryParam('example_param', defaultValue: 'test') String exampleParam,
    
    // Enhanced parameters (coexist with traditional)
    @QueryParam.all() Map<String, String> allQueryParams,   // 🆕 Enhanced
    @RequestHeader.all() Map<String, String> allHeaders,    // 🆕 Enhanced
    @RequestMethod() String method,                          // 🆕 Enhanced
  ) async {
    
    // Traditional approach extractions
    final traditionalMethod = request.method;  // Manual
    final traditionalPath = request.url.path;  // Manual
    final traditionalHeaders = request.headers; // Manual
    
    return jsonResponse(jsonEncode({
      'comparison_demo': 'Traditional vs Enhanced side by side',
      
      'traditional_approach': {
        'description': 'Requires Request parameter + manual extractions',
        'method_extraction': traditionalMethod,     // Manual from request
        'path_extraction': traditionalPath,         // Manual from request
        'headers_extraction': traditionalHeaders.length, // Manual from request
        'specific_param': exampleParam,             // Annotation-based (good)
        'boilerplate': 'High - need Request + manual extractions',
      },
      
      'enhanced_approach': {
        'description': 'Direct parameter injection via annotations',
        'method_injection': method,                 // Direct injection
        'all_query_params': allQueryParams,         // Everything automatically
        'all_headers_count': allHeaders.length,     // Everything automatically
        'specific_param': allQueryParams['example_param'] ?? 'test',
        'boilerplate': 'Zero - everything injected directly',
      },
      
      'side_by_side_benefits': {
        'traditional_code_lines': '~10 lines for extractions',
        'enhanced_code_lines': '0 lines for extractions',
        'traditional_error_prone': 'Manual extraction can fail',
        'enhanced_error_prone': 'Framework handles safely',
        'traditional_debugging': 'Limited to defined parameters',
        'enhanced_debugging': 'Complete request visibility',
        'traditional_scalability': 'Add Request extraction for each new need',
        'enhanced_scalability': 'Everything available automatically',
      },
      
      'recommendation': {
        'for_new_projects': 'Use Enhanced approach exclusively',
        'for_existing_projects': 'Migrate endpoint by endpoint',
        'migration_effort': 'Low - mainly remove Request parameter',
        'breaking_changes': 'None - both approaches coexist',
      },
    }));
  }
}