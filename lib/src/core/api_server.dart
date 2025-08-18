import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import '../config/server_config.dart';
import '../security/middleware.dart';
import 'base_controller.dart';
import 'router_builder.dart';

/// API server that automatically registers controllers with annotation support.
class ApiServer {
  final ServerConfig config;
  late final Pipeline pipeline;

  ApiServer({required this.config}) {
    pipeline = _buildSecurePipeline();
  }

  /// Builds the middleware pipeline.
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

  /// Starts the server with automatic controller registration.
  Future<ApiResult<HttpServer>> start({
    required String host,
    required int port,
    required List<BaseController> controllerList,
    Router? additionalRoutes,
  }) async {
    try {
      Log.i('Starting secure API server on $host:$port');
      Log.i('Registering ${controllerList.length} controllers...');
      
      // Create main router
      final mainRouter = Router();
      
      // Register each controller automatically
      for (final controller in controllerList) {
        _registerController(mainRouter, controller);
      }
      
      // Add additional routes if provided
      if (additionalRoutes != null) {
        mainRouter.mount('/', additionalRoutes);
      }
      
      // Health check endpoint is optional - controllers can provide their own
      // mainRouter.get('/health', (Request request) {
      //   return Response.ok('{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
      //       headers: {'content-type': 'application/json'});
      // });
      
      final handler = pipeline.addHandler(mainRouter);
      final server = await io.serve(handler, host, port);
      
      Log.i('Server started successfully with ${controllerList.length} controllers');
      Log.i('Controllers registered with their respective endpoints');
      
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

  /// Registers a controller and its routes automatically.
  void _registerController(Router mainRouter, BaseController controller) {
    try {
      // Get controller info
      final controllerType = controller.runtimeType.toString();
      Log.d('Registering controller: $controllerType');
      
      // Get the controller's router (built from annotations or manually)
      final controllerRouter = controller.router;
      
      // Determine mount path from controller annotation or default
      String mountPath = _getControllerMountPath(controller);
      
      // Mount the controller's router
      mainRouter.mount(mountPath, controllerRouter);
      
      Log.i('Controller $controllerType registered at: $mountPath');
    } catch (e, stackTrace) {
      Log.e('Failed to register controller ${controller.runtimeType}', 
            error: e, stackTrace: stackTrace);
    }
  }

  /// Extracts the mount path from controller annotations or uses default.
  String _getControllerMountPath(BaseController controller) {
    // Try to extract from @Controller annotation if reflection is available
    final extractedPath = RouterBuilder.extractControllerPath(controller);
    
    if (extractedPath != null && extractedPath.isNotEmpty) {
      return extractedPath;
    }
    
    // Fallback: use controller class name
    final className = controller.runtimeType.toString();
    final baseName = className.replaceAll('Controller', '').toLowerCase();
    return '/api/v1/$baseName';
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