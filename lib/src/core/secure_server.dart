import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import '../config/server_config.dart';
import '../security/middleware.dart';

/// A secure HTTP server built on top of Shelf with comprehensive security features.
class SecureServer {
  final ServerConfig config;
  final Router router;
  late final Pipeline pipeline;

  SecureServer({
    required this.config,
    required this.router,
  }) {
    pipeline = _buildSecurePipeline();
  }

  /// Builds the secure middleware pipeline.
  Pipeline _buildSecurePipeline() {
    return Pipeline()
        // Request ID for tracing
        .addMiddleware(requestIdMiddleware())
        
        // Security headers (OWASP)
        .addMiddleware(securityHeadersMiddleware())
        
        // Rate limiting (DDoS protection)
        .addMiddleware(rateLimitMiddleware(config.rateLimit))
        
        // Request size limit
        .addMiddleware(requestSizeLimitMiddleware(config.maxBodySize))
        
        // CORS configuration
        .addMiddleware(corsMiddleware(config.cors))
        
        // Request logging
        .addMiddleware(loggingMiddleware())
        
        // Error handling (secure error responses)
        .addMiddleware(errorHandlingMiddleware());
  }

  /// Starts the server with the specified configuration.
  Future<ApiResult<HttpServer>> start({
    required String host,
    required int port,
  }) async {
    try {
      Log.i('Starting secure server on $host:$port');
      
      final handler = pipeline.addHandler(router);
      final server = await io.serve(handler, host, port);
      
      Log.i('Server started successfully');
      return ApiResult.ok(server);
    } catch (e, stackTrace) {
      Log.e('Failed to start server', error: e, stackTrace: stackTrace);
      return ApiResult.err(ApiErr(
        title: 'Server Start Failed',
        msm: 'Failed to start server: $e',
        exception: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Stops the server gracefully.
  Future<void> stop(HttpServer server) async {
    try {
      Log.i('Stopping server gracefully...');
      await server.close(force: false);
      Log.i('Server stopped');
    } catch (e, stackTrace) {
      Log.e('Error stopping server', error: e, stackTrace: stackTrace);
    }
  }
}