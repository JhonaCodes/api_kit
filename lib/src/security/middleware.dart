import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

import '../config/server_config.dart';
import 'rate_limiter.dart';

/// Creates request ID middleware for tracing.
Middleware requestIdMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final requestId = _generateRequestId();
      final updatedRequest = request.change(
        context: {'request_id': requestId},
      );
      
      final response = await handler(updatedRequest);
      return response.change(headers: {
        ...response.headers,
        'X-Request-ID': requestId,
      });
    };
  };
}

/// Creates security headers middleware (OWASP protection).
Middleware securityHeadersMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);
      return response.change(headers: {
        ...response.headers,
        'X-Frame-Options': 'DENY',
        'X-Content-Type-Options': 'nosniff',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        'Content-Security-Policy': 'default-src \'self\'',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
      });
    };
  };
}

/// Creates rate limiting middleware.
Middleware rateLimitMiddleware(RateLimitConfig config) {
  final rateLimiter = RateLimiter();
  return rateLimiter.create(config);
}

/// Creates request size limit middleware.
Middleware requestSizeLimitMiddleware(int maxBytes) {
  return (Handler handler) {
    return (Request request) async {
      final contentLength = request.headers['content-length'];
      if (contentLength != null) {
        final length = int.tryParse(contentLength) ?? 0;
        if (length > maxBytes) {
          Log.w('Request size limit exceeded: $length bytes');
          return Response(413, body: 'Request entity too large');
        }
      }
      return handler(request);
    };
  };
}

/// Creates CORS middleware.
Middleware corsMiddleware(CorsConfig config) {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _getCorsHeaders(config));
      }
      
      final response = await handler(request);
      return response.change(headers: {
        ...response.headers,
        ..._getCorsHeaders(config),
      });
    };
  };
}

/// Creates logging middleware.
Middleware loggingMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final requestId = request.context['request_id'] ?? 'unknown';
      final start = DateTime.now();
      
      Log.i('${request.method} ${request.url.path} [ID: $requestId]');
      
      try {
        final response = await handler(request);
        final duration = DateTime.now().difference(start);
        
        Log.i('${request.method} ${request.url.path} [ID: $requestId] '
              '${response.statusCode} ${duration.inMilliseconds}ms');
        
        return response;
      } catch (e, stackTrace) {
        final duration = DateTime.now().difference(start);
        Log.e('${request.method} ${request.url.path} [ID: $requestId] '
              'ERROR ${duration.inMilliseconds}ms', 
              error: e, stackTrace: stackTrace);
        rethrow;
      }
    };
  };
}

/// Creates error handling middleware.
Middleware errorHandlingMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      try {
        return await handler(request);
      } catch (e, stackTrace) {
        final requestId = request.context['request_id'] ?? 'unknown';
        Log.e('Unhandled error [ID: $requestId]', error: e, stackTrace: stackTrace);
        
        // Don't leak error details in production
        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Internal server error',
            'request_id': requestId,
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

/// Generates a unique request ID.
String _generateRequestId() {
  final random = Random();
  final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
}

/// Gets CORS headers based on configuration.
Map<String, String> _getCorsHeaders(CorsConfig config) {
  return {
    'Access-Control-Allow-Origin': config.allowedOrigins.join(', '),
    'Access-Control-Allow-Methods': config.allowedMethods.join(', '),
    'Access-Control-Allow-Headers': config.allowedHeaders.join(', '),
    'Access-Control-Allow-Credentials': config.credentials.toString(),
  };
}