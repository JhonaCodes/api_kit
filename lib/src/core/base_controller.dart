import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import 'router_builder.dart';

/// Base class for all API controllers with common functionality.
abstract class BaseController {
  Router? _cachedRouter;

  /// Returns the router for this controller, built automatically from annotations.
  Router get router {
    _cachedRouter ??= RouterBuilder.buildFromController(this);
    return _cachedRouter!;
  }

  /// Extracts a required parameter from the request.
  String getRequiredParam(Request request, String name) {
    final value = request.params[name];
    if (value == null || value.isEmpty) {
      throw ArgumentError('Required parameter "$name" is missing');
    }
    return value;
  }

  /// Extracts an optional parameter from the request.
  String? getOptionalParam(Request request, String name) {
    return request.params[name];
  }

  /// Logs request information.
  void logRequest(Request request, String action) {
    Log.i('${request.method} ${request.url.path} - $action');
  }

  /// Creates a JSON response with proper headers.
  Response jsonResponse(
    String body, {
    int statusCode = 200,
    Map<String, String> additionalHeaders = const {},
  }) {
    return Response(
      statusCode,
      body: body,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...additionalHeaders,
      },
    );
  }

  /// Creates an error response.
  Response errorResponse(
    String message, {
    int statusCode = 500,
  }) {
    return jsonResponse(
      '{"error": "$message"}',
      statusCode: statusCode,
    );
  }
}