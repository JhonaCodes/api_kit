import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import 'router_builder.dart';

/// Base class for all API controllers with common functionality.
abstract class BaseController {
  Router? _cachedRouter;

  /// Returns the router for this controller, built automatically from annotations.
  Router get router {
    // For backward compatibility, return cached router or empty router
    // The actual router building now happens in buildRouter() method
    return _cachedRouter ?? Router();
  }

  /// Builds and caches the router for this controller asynchronously.
  /// This method supports JWT middleware integration.
  Future<Router> buildRouter() async {
    if (_cachedRouter == null) {
      _cachedRouter = await RouterBuilder.buildFromController(this);
    }
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

  /// Extracts a required query parameter from the request.
  String getRequiredQueryParam(Request request, String name) {
    final value = request.url.queryParameters[name];
    if (value == null || value.isEmpty) {
      throw ArgumentError('Required query parameter "$name" is missing');
    }
    return value;
  }

  /// Extracts an optional query parameter from the request.
  String? getOptionalQueryParam(Request request, String name, [String? defaultValue]) {
    return request.url.queryParameters[name] ?? defaultValue;
  }

  /// Extracts all query parameters as a map.
  Map<String, String> getAllQueryParams(Request request) {
    return request.url.queryParameters;
  }

  /// Extracts a required header from the request.
  String getRequiredHeader(Request request, String name) {
    final value = request.headers[name.toLowerCase()];
    if (value == null || value.isEmpty) {
      throw ArgumentError('Required header "$name" is missing');
    }
    return value;
  }

  /// Extracts an optional header from the request.
  String? getOptionalHeader(Request request, String name, [String? defaultValue]) {
    return request.headers[name.toLowerCase()] ?? defaultValue;
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