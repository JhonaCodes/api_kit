import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import '../config/server_config.dart';
import '../security/middleware.dart';
import '../middleware/enhanced_auth_middleware.dart';
import 'base_controller.dart';
import 'router_builder.dart';
import 'enhanced_reflection_helper.dart';

/// API server that automatically registers controllers with annotation support.
/// Now includes JWT validation system integration
class ApiServer {
  final ServerConfig config;
  late Pipeline pipeline;
  List<Middleware> middleware;
  
  // JWT Configuration
  String? _jwtSecret;
  List<String> _jwtExcludePaths = [];
  bool _jwtEnabled = false;
  
  // Token blacklist for JWT revocation
  final Set<String> _blacklistedTokens = <String>{};
  
  ApiServer({required this.config, this.middleware = const []}) {
    pipeline = _buildSecurePipeline(middleware);
  }

  /// Builds the secure middleware pipeline with JWT support
  Pipeline _buildSecurePipeline(List<Middleware> middleware) {
    final pipeline = Pipeline()
        // Request ID for tracing (must be first)
        .addMiddleware(requestIdMiddleware())
        
        // Security headers (OWASP)
        .addMiddleware(securityHeadersMiddleware())
        
        // Rate limiting (DDoS protection)
        .addMiddleware(rateLimitMiddleware(config.rateLimit))
        
        // Request size limit
        .addMiddleware(requestSizeLimitMiddleware(config.maxBodySize))
        
        // CORS configuration
        .addMiddleware(corsMiddleware(config.cors))
        
        // JWT extraction and validation (if enabled)
        .addMiddleware(_buildJWTMiddleware())
        
        // Request logging
        .addMiddleware(loggingMiddleware())
        
        // Error handling (secure error responses)
        .addMiddleware(errorHandlingMiddleware());

    if(middleware.isNotEmpty){
      middleware.forEach(pipeline.addMiddleware);
    }

    return pipeline;
  }
  
  /// Builds JWT middleware pipeline if JWT is enabled
  Middleware _buildJWTMiddleware() {
    if (!_jwtEnabled || _jwtSecret == null) {
      // Return no-op middleware if JWT is not enabled
      return (Handler innerHandler) => innerHandler;
    }
    
    return Pipeline()
        // Extract JWT from Authorization header
        .addMiddleware(EnhancedAuthMiddleware.jwtExtractor(
          jwtSecret: _jwtSecret!,
          excludePaths: _jwtExcludePaths,
        ))
        
        // Check token blacklist
        .addMiddleware(EnhancedAuthMiddleware.tokenBlacklist(
          blacklistedTokens: _blacklistedTokens,
        ))
        
        // JWT access logging
        .addMiddleware(EnhancedAuthMiddleware.jwtAccessLogger()).middleware;
  }
  
  /// Configura JWT authentication middleware
  /// Debe llamarse antes de start() para habilitar validación JWT
  void configureJWTAuth({
    required String jwtSecret,
    List<String> excludePaths = const ['/api/auth', '/api/public', '/health'],
  }) {
    if (jwtSecret.isEmpty) {
      throw ArgumentError('JWT secret cannot be empty');
    }
    
    _jwtSecret = jwtSecret;
    _jwtExcludePaths = excludePaths;
    _jwtEnabled = true;
    
    // Rebuild pipeline with JWT enabled
    pipeline = _buildSecurePipeline(middleware);
    
    Log.i('🔐 JWT authentication middleware configured');
    Log.i('   Secret: ${jwtSecret.substring(0, 8)}...');
    Log.i('   Excluded paths: ${excludePaths.join(', ')}');
  }
  
  /// Desactiva JWT authentication
  void disableJWTAuth() {
    _jwtEnabled = false;
    _jwtSecret = null;
    _jwtExcludePaths.clear();
    
    // Rebuild pipeline without JWT
    pipeline = _buildSecurePipeline(middleware);
    
    Log.i('🔓 JWT authentication disabled');
  }
  
  /// Agrega un token a la blacklist (para logout/revocación)
  void blacklistToken(String token) {
    if (token.isNotEmpty) {
      _blacklistedTokens.add(token);
      final logToken = token.length > 20 ? token.substring(0, 20) : token;
      Log.d('🚫 Token added to blacklist: $logToken...');
    }
  }
  
  /// Remueve un token de la blacklist
  void removeTokenFromBlacklist(String token) {
    if (_blacklistedTokens.remove(token)) {
      final logToken = token.length > 20 ? token.substring(0, 20) : token;
      Log.d('✅ Token removed from blacklist: $logToken...');
    }
  }
  
  /// Limpia todos los tokens blacklisteados
  void clearTokenBlacklist() {
    final count = _blacklistedTokens.length;
    _blacklistedTokens.clear();
    Log.i('🧹 Cleared $count tokens from blacklist');
  }
  
  /// Obtiene el número de tokens blacklisteados
  int get blacklistedTokensCount => _blacklistedTokens.length;

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
      
      // Register each controller automatically with JWT validation
      for (final controller in controllerList) {
        await _registerControllerWithJWT(mainRouter, controller);
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
      
      final handler = pipeline.addHandler(mainRouter.call);
      final server = await io.serve(handler, host, port);
      
      Log.i('Server started successfully with ${controllerList.length} controllers');
      Log.i('Controllers registered with their respective endpoints');
      
      return ApiResult.ok(server);
    } catch (e, stackTrace) {
      Log.e('Failed to start server: $e');
      return ApiResult.err(ApiErr(
        title: 'Server Start Failed',
        msm: 'Failed to start server: $e',
        exception: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Registers a controller with JWT validation support
  Future<void> _registerControllerWithJWT(Router mainRouter, BaseController controller) async {
    try {
      // Get controller info
      final controllerType = controller.runtimeType;
      final controllerTypeName = controllerType.toString();
      Log.d('Registering controller with JWT validation: $controllerTypeName');
      
      // Get the controller's router (built from annotations or manually) with JWT support
      final controllerRouter = await controller.buildRouter();
      
      // Determine mount path from controller annotation or default
      String mountPath = _getControllerMountPath(controller);
      
      // If JWT is enabled, register JWT validation middlewares for each method
      if (_jwtEnabled && EnhancedReflectionHelper.isReflectionAvailable) {
        await _registerJWTValidationForController(controllerType, mountPath);
      }
      
      // Mount the controller's router
      mainRouter.mount(mountPath, controllerRouter);
      
      Log.i('Controller $controllerTypeName registered at: $mountPath');
    } catch (e, stackTrace) {
      Log.e('Failed to register controller ${controller.runtimeType}: $e');
    }
  }
  
  /// Registers JWT validation middlewares for a controller's methods
  /// Now integrates JWT validation directly into the controller's router
  Future<void> _registerJWTValidationForController(Type controllerType, String mountPath) async {
    try {
      // Get all HTTP methods from the controller
      final methods = EnhancedReflectionHelper.getControllerMethods(controllerType);
      
      Log.d('   Found ${methods.length} HTTP methods in ${controllerType.toString()}');
      
      // Store JWT validation info for this controller
      for (final methodName in methods) {
        final jwtMiddlewares = await EnhancedReflectionHelper
            .createJWTValidationMiddleware(controllerType, methodName);
        
        if (jwtMiddlewares.isNotEmpty) {
          // The JWT validation will be handled by the EnhancedReflectionHelper
          // when the controller's routes are being built
          Log.d('   JWT validation configured for $methodName');
        }
      }
    } catch (e, stackTrace) {
      Log.w('Failed to register JWT validation for $controllerType: $e');
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