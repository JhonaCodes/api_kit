import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:logger_rs/logger_rs.dart';

/// 🚀 Enhanced Parameters Example - Complete Annotation Showcase
///
/// This example demonstrates ALL parameter annotation capabilities:
/// - ✅ @RequestHeader.all() - All headers automatically
/// - ✅ @QueryParam.all() - All query parameters automatically
/// - ✅ @RequestContext.all() - All request context
/// - ✅ @RequestMethod(), @RequestPath(), @RequestHost() etc - Request info
/// - ✅ @PathParam(), @RequestBody() - Standard parameter extraction
/// - ✅ Direct Ok/Err pattern with result_controller
/// - ✅ NO Request request parameter needed anywhere!
///
/// ## 🎯 Demonstrates Every Annotation:
/// All the enhanced annotations from the docs/annotations/enhanced-parameters-annotation.md
///
/// ## Running the Example:
/// ```bash
/// dart run example/params/enhanced_params_example.dart
/// ```
///
/// ## Test Complete Parameter Extraction:
/// ```bash
/// # Test all parameter types
/// curl "http://localhost:8080/api/enhanced/complete?page=1&sort=name&debug=true" \
///   -H "Authorization: Bearer token123" \
///   -H "User-Agent: api_kit_test" \
///   -H "X-Custom-Header: custom_value"
///
/// # Test POST with body and all parameters
/// curl -X POST "http://localhost:8080/api/enhanced/process/item123?priority=high" \
///   -H "Content-Type: application/json" \
///   -H "X-Request-ID: req_456" \
///   -d '{"name":"Test Item","category":"testing","metadata":{"type":"demo"}}'
///
/// # Test request info extraction
/// curl "http://localhost:8080/api/enhanced/debug/info"
/// ```

void main() async {
  final server = ApiServer(config: ServerConfig.development());

  final result = await server.start(host: 'localhost', port: 8080);

  result.when(
    ok: (httpServer) {
      Log.i('🚀 Enhanced Parameters Server running on http://localhost:8080');
      Log.i(
        '📖 Complete demo: http://localhost:8080/api/enhanced/complete?page=1&sort=name',
      );
      Log.i('🔍 Debug info: http://localhost:8080/api/enhanced/debug/info');
      Log.i('📝 POST demo: http://localhost:8080/api/enhanced/process/item123');

      ProcessSignal.sigint.watch().listen((sig) async {
        Log.i('🛑 Shutting down enhanced parameters server...');
        await httpServer.close(force: false);
        exit(0);
      });
    },
    err: (error) {
      Log.e('❌ Failed to start server: ${error.msm}');
      exit(1);
    },
  );
}

/// 🎯 Enhanced Parameters Controller - Complete Annotation Showcase
///
/// Demonstrates EVERY available parameter annotation without using Request parameter
@RestController(basePath: '/api/enhanced')
class EnhancedParametersController extends BaseController {
  /// 📋 Complete Parameter Extraction Demo
  ///
  /// ✅ Shows ALL parameter types working together without Request parameter
  /// This endpoint demonstrates every type of parameter extraction available
  @Get(path: '/complete')
  Future<Response> completeParameterDemo(
    // ✅ All Headers - gets every HTTP header
    @RequestHeader.all() Map<String, String> allHeaders,

    // ✅ All Query Parameters - gets every ?param=value
    @QueryParam.all() Map<String, String> allQueryParams,

    // ✅ All Request Context - gets middleware data, etc
    @RequestContext.all() Map<String, dynamic> allContext,

    // ✅ HTTP Method info
    @RequestMethod() String method,

    // ✅ Path info
    @RequestPath() String path,

    // ✅ Host info
    @RequestHost() String host,

    // ✅ Port info
    @RequestPort() int port,

    // ✅ Scheme (http/https)
    @RequestScheme() String scheme,

    // ✅ Complete URL
    @RequestUrl() Uri fullUrl,

    // ✅ Specific headers (optional - show mixed usage)
    @RequestHeader('User-Agent') String? userAgent,
    @RequestHeader('Authorization') String? authHeader,

    // ✅ Specific query params (optional - show mixed usage)
    @QueryParam('page') String? pageParam,
    @QueryParam('sort') String? sortParam,
  ) async {
    // ✅ Process all the automatically extracted parameters
    final pageNum = int.tryParse(pageParam ?? '1') ?? 1;
    final sortBy = sortParam ?? 'id';

    // Filter headers for interesting ones
    final authHeaders = allHeaders.entries
        .where(
          (e) =>
              e.key.toLowerCase().contains('auth') ||
              e.key.toLowerCase().contains('token'),
        )
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    final customHeaders = allHeaders.entries
        .where((e) => e.key.toLowerCase().startsWith('x-'))
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    // Process query parameters
    final filterParams = allQueryParams.entries
        .where((e) => e.key.startsWith('filter_'))
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    final debugMode = allQueryParams['debug'] == 'true';

    // ✅ Direct result creation with all extracted data
    final result = ApiKit.ok({
      'message':
          'Complete parameter extraction demo - NO Request parameter needed!',
      'extraction_summary': {
        'total_headers': allHeaders.length,
        'total_query_params': allQueryParams.length,
        'total_context_keys': allContext.length,
        'method_detected': method,
      },
      'request_info': {
        'http_method': method,
        'full_path': path,
        'host': host,
        'port': port,
        'scheme': scheme,
        'complete_url': fullUrl.toString(),
      },
      'header_analysis': {
        'user_agent': userAgent ?? 'not provided',
        'authorization_header': authHeader != null ? 'present' : 'not provided',
        'auth_related_headers': authHeaders,
        'custom_headers': customHeaders,
        'total_headers_received': allHeaders.length,
      },
      'query_param_analysis': {
        'page_requested': pageNum,
        'sort_by': sortBy,
        'debug_mode': debugMode,
        'filter_parameters': filterParams,
        'all_params': allQueryParams,
      },
      'context_analysis': {
        'context_keys': allContext.keys.toList(),
        'has_middleware_data': allContext.isNotEmpty,
        'context_types': allContext.entries
            .map((e) => '${e.key}: ${e.value.runtimeType}')
            .toList(),
      },
      'demonstration': {
        'no_manual_request_extraction': true,
        'all_data_via_annotations': true,
        'type_safe_parameters': true,
        'automatic_parsing': true,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 🔧 POST Processing with Complete Parameter Set
  ///
  /// ✅ Shows request body + path params + all other parameters working together
  @Post(path: '/process/{itemId}')
  Future<Response> processWithAllParameters(
    // ✅ Path parameter
    @PathParam('itemId') String itemId,

    // ✅ Request body
    @RequestBody() Map<String, dynamic> processData,

    // ✅ All headers and query params
    @RequestHeader.all() Map<String, String> allHeaders,
    @QueryParam.all() Map<String, String> allQueryParams,

    // ✅ Request info
    @RequestMethod() String method,
    @RequestPath() String path,
    @RequestUrl() Uri fullUrl,

    // ✅ Specific important headers
    @RequestHeader('Content-Type') String? contentType,
    @RequestHeader('X-Request-ID') String? requestId,

    // ✅ Specific query parameters
    @QueryParam('priority') String? priority,
  ) async {
    try {
      // ✅ Validate required data without manual request parsing
      if (processData['name'] == null ||
          processData['name'].toString().trim().isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Item name is required',
          validations: {'name': 'Name cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Process the item with all available context
      final processedItem = {
        'item_id': itemId,
        'name': processData['name'].toString().trim(),
        'category': processData['category'] ?? 'uncategorized',
        'metadata': processData['metadata'] ?? {},
        'priority': priority ?? 'normal',
        'processed_at': DateTime.now().toIso8601String(),
        'processed_by': 'enhanced_params_controller',
        'request_id':
            requestId ??
            'auto_generated_${DateTime.now().millisecondsSinceEpoch}',
      };

      // Analyze processing context from extracted parameters
      final processingContext = {
        'http_info': {
          'method': method,
          'path': path,
          'full_url': fullUrl.toString(),
          'content_type': contentType ?? 'unknown',
        },
        'header_analysis': {
          'total_headers': allHeaders.length,
          'has_request_id': requestId != null,
          'custom_headers': allHeaders.entries
              .where((e) => e.key.toLowerCase().startsWith('x-'))
              .length,
        },
        'query_context': {
          'total_params': allQueryParams.length,
          'priority_set': priority != null,
          'all_query_params': allQueryParams,
        },
        'body_analysis': {
          'has_metadata': processData['metadata'] != null,
          'body_keys': processData.keys.toList(),
          'estimated_size': processData.toString().length,
        },
      };

      final result = ApiKit.ok({
        'message':
            'Item processed successfully with complete parameter extraction',
        'processed_item': processedItem,
        'processing_context': processingContext,
        'parameter_extraction': {
          'path_param_extracted': itemId,
          'body_parsed': true,
          'headers_captured': allHeaders.length,
          'query_params_captured': allQueryParams.length,
          'request_info_extracted': true,
        },
        'no_manual_parsing': {
          'no_request_parameter': true,
          'no_manual_header_extraction': true,
          'no_manual_query_parsing': true,
          'no_manual_body_reading': true,
          'all_via_annotations': true,
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to process item: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }

  /// 🔍 Debug Information Endpoint
  ///
  /// ✅ Shows complete request introspection without Request parameter
  @Get(path: '/debug/info')
  Future<Response> debugRequestInfo(
    @RequestHeader.all() Map<String, String> allHeaders,
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestContext.all() Map<String, dynamic> allContext,
    @RequestMethod() String method,
    @RequestPath() String path,
    @RequestHost() String host,
    @RequestPort() int port,
    @RequestScheme() String scheme,
    @RequestUrl() Uri fullUrl,
  ) async {
    final result = ApiKit.ok({
      'debug_info': 'Complete request introspection via annotations only',
      'http_request': {
        'method': method,
        'path': path,
        'host': host,
        'port': port,
        'scheme': scheme,
        'full_url': fullUrl.toString(),
        'is_secure': scheme == 'https',
        'is_localhost':
            host.contains('localhost') || host.contains('127.0.0.1'),
      },
      'headers_debug': {
        'total_count': allHeaders.length,
        'all_headers': allHeaders,
        'standard_headers': {
          'user_agent': allHeaders['user-agent'] ?? 'not set',
          'accept': allHeaders['accept'] ?? 'not set',
          'content_type': allHeaders['content-type'] ?? 'not set',
          'authorization': allHeaders['authorization'] != null
              ? 'present (hidden)'
              : 'not set',
        },
        'custom_headers': allHeaders.entries
            .where((e) => e.key.toLowerCase().startsWith('x-'))
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
      },
      'query_params_debug': {
        'total_count': allQueryParams.length,
        'all_params': allQueryParams,
        'common_params': {
          'page': allQueryParams['page'] ?? 'not set',
          'limit': allQueryParams['limit'] ?? 'not set',
          'sort': allQueryParams['sort'] ?? 'not set',
          'filter': allQueryParams['filter'] ?? 'not set',
        },
        'debug_params': allQueryParams.entries
            .where((e) => e.key.toLowerCase().contains('debug'))
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
      },
      'context_debug': {
        'total_keys': allContext.length,
        'context_keys': allContext.keys.toList(),
        'context_summary': allContext.entries
            .map((e) => '${e.key}: ${e.value.runtimeType}')
            .toList(),
        'has_jwt_data': allContext.containsKey('jwt_payload'),
        'has_middleware_data': allContext.keys.any(
          (key) => key != 'jwt_payload',
        ),
      },
      'extraction_stats': {
        'total_data_points':
            allHeaders.length +
            allQueryParams.length +
            allContext.length +
            6, // +6 for request info
        'manual_extractions': 0,
        'annotation_extractions': 'all',
        'request_parameter_needed': false,
      },
      'performance_info': {
        'no_manual_parsing_overhead': true,
        'type_safe_access': true,
        'automatic_validation': true,
        'framework_handled': true,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 🎯 Specific Parameter Types Demo
  ///
  /// ✅ Shows working with specific extracted values
  @Get(path: '/specific/{category}')
  Future<Response> specificParameterDemo(
    @PathParam('category') String category,
    @QueryParam('page') String? pageStr,
    @QueryParam('limit') String? limitStr,
    @QueryParam('search') String? searchTerm,
    @RequestHeader('User-Agent') String? userAgent,
    @RequestHeader('Accept') String? acceptHeader,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    // ✅ Type conversion and validation without manual parsing
    final page = int.tryParse(pageStr ?? '1') ?? 1;
    final limit = int.tryParse(limitStr ?? '20') ?? 20;

    // Validate parameters
    if (page < 1) {
      final result = ApiKit.badRequest<Map<String, dynamic>>(
        'Page must be 1 or greater',
        validations: {'page': 'Invalid page number'},
      );
      return ApiResponseBuilder.fromResult(result);
    }

    if (limit < 1 || limit > 100) {
      final result = ApiKit.badRequest<Map<String, dynamic>>(
        'Limit must be between 1 and 100',
        validations: {'limit': 'Invalid limit value'},
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // Mock data processing
    final mockItems = List.generate(limit, (index) {
      final itemId = (page - 1) * limit + index + 1;
      return {
        'id': 'item_$itemId',
        'category': category,
        'name': searchTerm != null
            ? 'Search result $itemId for "$searchTerm"'
            : 'Item $itemId',
        'page': page,
      };
    });

    final result = ApiKit.ok({
      'items': mockItems,
      'pagination': {
        'current_page': page,
        'items_per_page': limit,
        'total_items_shown': mockItems.length,
      },
      'category_info': {
        'category': category,
        'search_applied': searchTerm != null,
        'search_term': searchTerm ?? 'none',
      },
      'request_info': {
        'method': method,
        'path': path,
        'user_agent': userAgent ?? 'unknown',
        'accepts': acceptHeader ?? 'unknown',
      },
      'parameter_extraction': {
        'path_param': 'extracted from @PathParam',
        'query_params': 'extracted from @QueryParam',
        'headers': 'extracted from @RequestHeader',
        'request_info': 'extracted from @RequestMethod/@RequestPath',
        'manual_extraction': 'none needed',
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 🧪 Context Demonstration
  ///
  /// ✅ Shows how context data is available without manual extraction
  @Get(path: '/context-demo')
  Future<Response> contextDemo(
    @RequestContext.all() Map<String, dynamic> allContext,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
    @RequestHost() String host,
    @RequestScheme() String scheme,
  ) async {
    // Simulate adding something to context in middleware
    // In real apps, middleware would add auth, user info, request tracking, etc.

    final contextAnalysis = {
      'context_keys_found': allContext.keys.toList(),
      'context_types': allContext.entries
          .map((e) => '${e.key}: ${e.value.runtimeType}')
          .toList(),
      'has_auth_context':
          allContext.containsKey('jwt_payload') ||
          allContext.containsKey('user_id'),
      'middleware_data': allContext.entries
          .where((e) => !['jwt_payload'].contains(e.key))
          .map((e) => e.key)
          .toList(),
    };

    final result = ApiKit.ok({
      'message':
          'Context demonstration - all middleware data available directly',
      'context_analysis': contextAnalysis,
      'request_info': {
        'method': method,
        'host': host,
        'scheme': scheme,
        'headers_count': allHeaders.length,
      },
      'context_usage': {
        'automatic_extraction': true,
        'no_request_context_access': true,
        'middleware_integration': 'seamless',
        'type_safe_access': true,
      },
      'example_middleware_data': {
        'note': 'In production, middleware would populate context with:',
        'typical_context_keys': [
          'jwt_payload',
          'user_id',
          'request_id',
          'correlation_id',
          'rate_limit_info',
          'geo_location',
          'device_info',
        ],
        'all_accessible_via':
            '@RequestContext.all() or @RequestContext(\'key\')',
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }
}
