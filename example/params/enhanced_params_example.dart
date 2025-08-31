/// 🚀 Enhanced Parameters Example - New "All" Mode Support
/// 
/// This example demonstrates the NEW enhanced parameter annotations that support
/// capturing ALL parameters of a type without specifying individual keys:
/// 
/// 1. @RequestHeader.all() - Captures ALL HTTP headers as Map<String, String>
/// 2. @QueryParam.all() - Captures ALL query parameters as Map<String, String>
/// 3. @RequestContext.all() - Captures ALL request context as Map<String, dynamic>
/// 4. New request component annotations (@RequestMethod, @RequestPath, etc.)
/// 5. Complete elimination of manual Request parameter in most cases
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🚀 Enhanced Parameters Example - "All" Mode Support');

  final server = ApiServer.create()
    .configureJWT(
      jwtSecret: 'your-super-secret-jwt-key-256-bits-long!',
      excludePaths: ['/api/public'],
    )
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8095,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test Enhanced Parameters endpoints:');
      print('   # All headers capture:');
      print('   curl -H "Authorization: Bearer token123" -H "X-API-Key: key456" -H "User-Agent: TestApp/1.0" http://localhost:8095/api/inspect/headers');
      
      print('   # All query parameters capture:');
      print('   curl "http://localhost:8095/api/inspect/query?page=1&limit=10&filter=active&sort=name&category=tech"');
      
      print('   # Complete request inspection (no manual Request needed):');
      print('   curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer token123" -d \'{"name":"test"}\' "http://localhost:8095/api/inspect/complete?debug=true"');
      
      print('   # JWT endpoint with automatic context extraction:');
      print('   curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8095/api/user/profile');
      
      print('\n🎯 Key Features Demonstrated:');
      print('   ✅ @RequestHeader.all() - All headers as Map');
      print('   ✅ @QueryParam.all() - All query params as Map');
      print('   ✅ @RequestContext.all() - All context as Map');
      print('   ✅ @RequestMethod() - HTTP method directly');
      print('   ✅ @RequestPath() - Request path directly');
      print('   ✅ @RequestHost() - Host directly');
      print('   ✅ @RequestPort() - Port directly');
      print('   ✅ @RequestScheme() - Scheme directly');
      print('   ✅ @RequestUrl() - Complete URL directly');
      print('   ✅ No manual Request parameter needed in most cases');
      
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demonstrating enhanced parameter annotations
@RestController(basePath: '/api/inspect')
class EnhancedParamsController extends BaseController {

  /// Example 1: Capture ALL headers automatically
  @Get(path: '/headers')
  Future<Response> inspectAllHeaders(
    @RequestHeader.all() Map<String, String> allHeaders,  // 🆕 ALL headers
    @RequestMethod() String method,                        // 🆕 HTTP method
    @RequestPath() String path,                           // 🆕 Request path
  ) async {
    
    // Analyze headers without manual extraction
    final authHeaders = allHeaders.entries
      .where((entry) => entry.key.toLowerCase().contains('auth'))
      .map((entry) => '${entry.key}: ${entry.value}')
      .toList();
    
    final apiHeaders = allHeaders.entries
      .where((entry) => entry.key.toLowerCase().startsWith('x-'))
      .map((entry) => '${entry.key}: ${entry.value}')
      .toList();
    
    return jsonResponse(jsonEncode({
      'message': 'All headers captured automatically',
      'request_info': {
        'method': method,           // Direct access, no request.method
        'path': path,               // Direct access, no request.url.path
      },
      'headers_analysis': {
        'total_headers': allHeaders.length,
        'all_headers': allHeaders,
        'auth_related': authHeaders,
        'api_headers': apiHeaders,
        'has_user_agent': allHeaders.containsKey('user-agent'),
        'has_authorization': allHeaders.containsKey('authorization'),
        'content_type': allHeaders['content-type'] ?? 'not provided',
      },
      'header_categories': {
        'standard': allHeaders.keys.where((k) => !k.startsWith('x-')).toList(),
        'custom': allHeaders.keys.where((k) => k.startsWith('x-')).toList(),
      },
    }));
  }

  /// Example 2: Capture ALL query parameters automatically
  @Get(path: '/query')
  Future<Response> inspectAllQueryParams(
    @QueryParam.all() Map<String, String> allQueryParams,  // 🆕 ALL query params
    @RequestHost() String host,                            // 🆕 Request host
    @RequestPort() int port,                               // 🆕 Request port
    @RequestUrl() Uri fullUrl,                             // 🆕 Complete URL
  ) async {
    
    // Analyze query parameters without manual extraction
    final paginationParams = ['page', 'limit', 'offset', 'size']
      .where((param) => allQueryParams.containsKey(param))
      .map((param) => '$param: ${allQueryParams[param]}')
      .toList();
    
    final filterParams = allQueryParams.entries
      .where((entry) => ['filter', 'search', 'category', 'status'].contains(entry.key))
      .map((entry) => '${entry.key}: ${entry.value}')
      .toList();
    
    return jsonResponse(jsonEncode({
      'message': 'All query parameters captured automatically',
      'request_info': {
        'host': host,                    // Direct access, no request.url.host
        'port': port,                    // Direct access, no request.url.port
        'full_url': fullUrl.toString(),  // Direct access, no request.url
      },
      'query_analysis': {
        'total_params': allQueryParams.length,
        'all_params': allQueryParams,
        'pagination_params': paginationParams,
        'filter_params': filterParams,
        'has_pagination': paginationParams.isNotEmpty,
        'has_filters': filterParams.isNotEmpty,
      },
      'url_breakdown': {
        'scheme': fullUrl.scheme,
        'host': fullUrl.host,
        'port': fullUrl.port,
        'path': fullUrl.path,
        'query': fullUrl.query,
        'fragment': fullUrl.fragment,
      },
    }));
  }

  /// Example 3: Complete request inspection WITHOUT manual Request parameter
  @Post(path: '/complete')
  Future<Response> inspectCompleteRequest(
    @RequestBody() Map<String, dynamic> body,              // Request body
    @RequestHeader.all() Map<String, String> allHeaders,   // All headers
    @QueryParam.all() Map<String, String> allQueryParams,  // All query params
    @RequestMethod() String method,                         // HTTP method
    @RequestPath() String path,                            // Request path
    @RequestScheme() String scheme,                        // http/https
    @RequestUrl() Uri fullUrl,                             // Complete URL
    // NO Request request parameter needed! 🎉
  ) async {
    
    // Complete request analysis with zero manual extraction
    return jsonResponse(jsonEncode({
      'message': 'Complete request analyzed without manual Request parameter',
      'elimination_achieved': 'No Request request parameter needed!',
      'direct_access': {
        'method': method,
        'path': path,
        'scheme': scheme,
        'full_url': fullUrl.toString(),
      },
      'captured_data': {
        'body': body,
        'headers_count': allHeaders.length,
        'query_params_count': allQueryParams.length,
        'total_data_points': body.length + allHeaders.length + allQueryParams.length,
      },
      'comprehensive_analysis': {
        'request_body': body,
        'all_headers': allHeaders,
        'all_query_params': allQueryParams,
        'is_secure': scheme == 'https',
        'has_body': body.isNotEmpty,
        'has_headers': allHeaders.isNotEmpty,
        'has_query': allQueryParams.isNotEmpty,
      },
      'framework_improvement': {
        'before': 'Required Request request parameter',
        'after': 'Direct parameter injection with annotations',
        'benefits': [
          'Less boilerplate code',
          'More declarative approach',
          'Automatic data extraction',
          'Type-safe parameters',
          'Better testability',
        ],
      },
    }));
  }

  /// Example 4: Request context handling (useful for JWT)
  @Get(path: '/context')
  Future<Response> inspectRequestContext(
    @RequestContext.all() Map<String, dynamic> allContext,  // 🆕 ALL context
    @RequestContext('jwt_payload') Map<String, dynamic>? jwtPayload,  // 🆕 Specific context
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    
    return jsonResponse(jsonEncode({
      'message': 'Request context captured automatically',
      'context_info': {
        'total_context_keys': allContext.length,
        'all_context': allContext,
        'context_keys': allContext.keys.toList(),
        'has_jwt': jwtPayload != null,
        'jwt_payload': jwtPayload,
      },
      'request_info': {
        'method': method,
        'path': path,
      },
      'context_analysis': {
        'middleware_data': allContext.keys
          .where((key) => key != 'jwt_payload')
          .toList(),
        'jwt_present': allContext.containsKey('jwt_payload'),
        'custom_data': allContext.entries
          .where((entry) => !['jwt_payload'].contains(entry.key))
          .map((entry) => '${entry.key}: ${entry.value.runtimeType}')
          .toList(),
      },
    }));
  }
}

/// User controller demonstrating JWT with enhanced annotations
@RestController(basePath: '/api/user')
class EnhancedUserController extends BaseController {

  /// JWT endpoint with automatic context extraction - NO manual Request!
  @Get(path: '/profile')
  @JWTEndpoint([MyUserValidator()])
  Future<Response> getUserProfile(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,  // 🆕 Direct JWT access
    @RequestHeader.all() Map<String, String> allHeaders,             // 🆕 All headers
    @RequestMethod() String method,                                   // 🆕 HTTP method
    @RequestPath() String path,                                      // 🆕 Request path
    // NO Request request parameter! JWT validation + extraction automatic! 🎉
  ) async {
    
    // Direct access to JWT data - no manual extraction from request.context!
    final userId = jwtPayload['user_id'] as String;
    final userRole = jwtPayload['role'] as String?;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];
    
    return jsonResponse(jsonEncode({
      'message': 'JWT endpoint with automatic context extraction',
      'framework_improvement': 'No manual request.context[\'jwt_payload\'] extraction needed!',
      'user_profile': {
        'user_id': userId,
        'role': userRole,
        'permissions': permissions,
        'active': jwtPayload['active'] ?? false,
      },
      'request_info': {
        'method': method,
        'path': path,
        'auth_header_present': allHeaders.containsKey('authorization'),
        'user_agent': allHeaders['user-agent'] ?? 'unknown',
      },
      'validation_info': {
        'jwt_validated_by': 'MyUserValidator annotation',
        'automatic_extraction': true,
        'manual_request_needed': false,
      },
      'all_headers_available': allHeaders,
    }));
  }

  /// Update profile with comprehensive parameter capture
  @Put(path: '/profile')
  @JWTEndpoint([MyUserValidator()])
  Future<Response> updateUserProfile(
    @RequestBody() Map<String, dynamic> profileData,                // Request body
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload, // JWT payload
    @RequestHeader.all() Map<String, String> allHeaders,            // All headers
    @QueryParam.all() Map<String, String> allQueryParams,           // All query params
    @RequestMethod() String method,                                  // HTTP method
    @RequestUrl() Uri fullUrl,                                      // Complete URL
    // Still NO Request request needed! Complete data access! 🎉
  ) async {
    
    final userId = jwtPayload['user_id'] as String;
    
    // Validate update permissions
    final canUpdate = (jwtPayload['permissions'] as List<dynamic>? ?? [])
      .contains('profile:update');
    
    if (!canUpdate) {
      return Response.forbidden(jsonEncode({
        'error': 'Insufficient permissions',
        'required_permission': 'profile:update',
        'user_permissions': jwtPayload['permissions'] ?? [],
      }));
    }
    
    return jsonResponse(jsonEncode({
      'message': 'Profile updated successfully',
      'comprehensive_data_access': 'All request data available without manual Request!',
      'update_result': {
        'user_id': userId,
        'updated_fields': profileData.keys.toList(),
        'profile_data': profileData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      'request_analysis': {
        'method': method,
        'full_url': fullUrl.toString(),
        'query_params': allQueryParams,
        'headers_count': allHeaders.length,
        'jwt_user': userId,
      },
      'framework_benefits': [
        'No manual Request parameter needed',
        'Automatic JWT extraction from context',
        'All headers captured declaratively',
        'All query params available',
        'Type-safe parameter injection',
        'Cleaner, more maintainable code',
      ],
    }));
  }
}

/// Example custom JWT validator (unchanged - works with new system)
class MyUserValidator extends JWTValidatorBase {
  const MyUserValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final userId = jwtPayload['user_id'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;

    if (userId == null || userId.isEmpty || !isActive) {
      return ValidationResult.invalid('Valid active user required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Valid user authentication required';
}