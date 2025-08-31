import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:result_controller/result_controller.dart';

import '../config/server_config.dart';
import '../security/middleware.dart';
import '../middleware/enhanced_auth_middleware.dart';
import '../annotations/annotation_api.dart';
import 'base_controller.dart';
import 'static_router_builder.dart';
import 'controller_registry.dart';

/// API server with auto-discovery and fluent configuration.
/// Supports automatic controller registration without manual controllerList
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
  
  // Display configuration
  bool _showEndpointsInConsole = false;
  

  ApiServer._({required this.config, this.middleware = const []}) {
    pipeline = _buildSecurePipeline(middleware);
  }
  
  /// Creates a new ApiServer instance with fluent configuration support
  factory ApiServer.create({ServerConfig? config, List<Middleware> middleware = const []}) {
    return ApiServer._(
      config: config ?? ServerConfig.development(),
      middleware: middleware,
    );
  }
  
  /// Legacy constructor for backward compatibility
  factory ApiServer({required ServerConfig config, List<Middleware> middleware = const []}) {
    return ApiServer._(
      config: config,
      middleware: middleware,
    );
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

    if (middleware.isNotEmpty) {
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
        .addMiddleware(
          EnhancedAuthMiddleware.jwtExtractor(
            jwtSecret: _jwtSecret!,
            excludePaths: _jwtExcludePaths,
          ),
        )
        // Check token blacklist
        .addMiddleware(
          EnhancedAuthMiddleware.tokenBlacklist(
            blacklistedTokens: _blacklistedTokens,
          ),
        )
        // JWT access logging
        .addMiddleware(EnhancedAuthMiddleware.jwtAccessLogger())
        .middleware;
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
  
  /// Configures JWT authentication with fluent interface
  ApiServer configureJWT({
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

    Log.i('🔐 JWT authentication configured');
    Log.d('   Secret: ${jwtSecret.substring(0, 8)}...');
    Log.d('   Excluded paths: ${excludePaths.join(', ')}');
    
    return this;
  }
  
  /// Configures environment variables loading
  ApiServer configureEnvironment({bool loadEnvFile = true}) {
    if (loadEnvFile) {
      Log.d('🌍 Environment configuration loaded');
    }
    return this;
  }
  
  /// Configures endpoint display in console
  ApiServer configureEndpointDisplay({bool showInConsole = false}) {
    _showEndpointsInConsole = showInConsole;
    return this;
  }

  /// Starts the server with automatic controller auto-discovery.
  /// No longer requires manual controllerList - discovers controllers automatically
  Future<ApiResult<HttpServer>> start({
    required String host,
    required int port,
    Router? additionalRoutes,
    String? projectPath,
  }) async {
    try {
      Log.i('🚀 Starting secure API server on $host:$port');
      
      // Auto-discover controllers using static analysis
      Log.i('🔍 Auto-discovering controllers...');
      final controllerList = await ControllerRegistry.discoverControllers(projectPath);
      
      if (controllerList.isEmpty) {
        Log.w('⚠️  No controllers found - server will start with no endpoints');
      }

      // Create main router
      final mainRouter = Router();

      // Register each auto-discovered controller with JWT validation
      int totalEndpoints = 0;
      for (final controller in controllerList) {
        final endpointCount = await _registerControllerWithJWT(mainRouter, controller);
        totalEndpoints += endpointCount;
      }

      // Add additional routes if provided
      if (additionalRoutes != null) {
        mainRouter.mount('/', additionalRoutes.call);
      }

      // Health check endpoint is optional - controllers can provide their own
      // mainRouter.get('/health', (Request request) {
      //   return Response.ok('{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
      //       headers: {'content-type': 'application/json'});
      // });

      // Log hybrid routing analysis before starting server
      // Static analysis routing - no logging needed

      final handler = pipeline.addHandler(mainRouter.call);
      final server = await io.serve(handler, host, port);

      Log.i('🎯 Server started successfully');
      Log.i('📊 Auto-discovered ${controllerList.length} controllers with $totalEndpoints endpoints');
      
      // Display endpoints table if configured
      if (_showEndpointsInConsole && controllerList.isNotEmpty) {
        await _displayEndpointsTable(controllerList);
      }
      
      Log.i('✅ AOT Compatible (Static Analysis)');

      return ApiResult.ok(server);
    } catch (e, stackTrace) {
      Log.e('Failed to start server: $e');
      return ApiResult.err(
        ApiErr(
          title: 'Server Start Failed',
          msm: 'Failed to start server: $e',
          exception: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Registers a controller with JWT validation support
  /// Returns the number of endpoints registered
  Future<int> _registerControllerWithJWT(
    Router mainRouter,
    BaseController controller,
  ) async {
    try {
      // Get controller info
      final controllerType = controller.runtimeType;
      final controllerTypeName = controllerType.toString();
      Log.d('Registering controller with JWT validation: $controllerTypeName');

      // Get the controller's router using static analysis
      final controllerRouter = await StaticRouterBuilder.buildFromController(
        controller,
      ) ?? await controller.buildRouter(); // Fallback to manual router if static analysis fails

      // Determine mount path from controller annotation or default
      String mountPath = await _getControllerMountPath(controller);

      // If JWT is enabled, register JWT validation middlewares for each method
      if (_jwtEnabled) {
        await _registerJWTValidationForController(controllerType, mountPath);
      }

      // Mount the controller's router
      mainRouter.mount(mountPath, controllerRouter.call);
      
      // Count endpoints registered for this controller
      final routes = await StaticRouterBuilder.getAvailableRoutes(Directory.current.path);
      final controllerRoutes = routes.where((route) => route.contains(controllerTypeName)).length;

      Log.d('Controller $controllerTypeName registered at: $mountPath ($controllerRoutes endpoints)');
      
      return controllerRoutes;
    } catch (e) {
      Log.e('Failed to register controller ${controller.runtimeType}: $e');
      return 0;
    }
  }

  /// Registers JWT validation middlewares for a controller's methods
  /// JWT validation is now handled by the static analysis system
  Future<void> _registerJWTValidationForController(
    Type controllerType,
    String mountPath,
  ) async {
    try {
      Log.d('JWT validation configured for ${controllerType.toString()} via static analysis');
      
      // JWT validation is now handled automatically by the StaticRouterBuilder
      // through annotation analysis and method dispatcher integration
    } catch (e) {
      Log.w('Failed to register JWT validation for $controllerType: $e');
    }
  }

  /// Extracts the mount path from controller annotations or uses default.
  Future<String> _getControllerMountPath(BaseController controller) async {
    // Extract basePath from @RestController annotation using static analysis
    try {
      final result = await AnnotationAPI.detectIn(Directory.current.path);
      final controllerName = controller.runtimeType.toString();
      
      // Find RestController annotation for this controller
      final restControllerAnnotation = result.annotationList
          .where((annotation) => 
              annotation.annotationType == 'RestController' &&
              annotation.targetName.contains(controllerName))
          .firstOrNull;
          
      if (restControllerAnnotation?.restControllerInfo?.basePath != null) {
        final basePath = restControllerAnnotation!.restControllerInfo!.basePath;
        Log.d('Extracted basePath from @RestController: $basePath');
        return basePath;
      }
    } catch (e) {
      Log.w('Could not extract basePath from annotations: $e');
    }

    // Fallback: use controller class name
    final className = controller.runtimeType.toString();
    final baseName = className.replaceAll('Controller', '').toLowerCase();
    return '/api/v1/$baseName';
  }

  /// Displays a formatted table of all registered endpoints
  Future<void> _displayEndpointsTable(List<BaseController> controllers) async {
    try {
      Log.i('');
      Log.i('╭─── API Endpoints ────────────────────────────────╮');
      
      for (final controller in controllers) {
        final controllerName = controller.runtimeType.toString();
        final mountPath = await _getControllerMountPath(controller);
        
        // Get routes for this controller
        final result = await AnnotationAPI.detectIn(Directory.current.path);
        final routes = StaticRouterBuilder.extractRoutesFromResult(result, controller);
        
        for (final route in routes) {
          final fullPath = mountPath + (route.path == '/' ? '' : route.path);
          final method = route.httpMethod.padRight(6);
          final path = fullPath.padRight(25);
          final controllerShort = controllerName.replaceAll('Controller', '');
          
          Log.i('│ $method $path $controllerShort │');
        }
      }
      
      Log.i('╰─────────────────────────────────────────────────╯');
      Log.i('');
    } catch (e) {
      Log.w('Failed to display endpoints table: $e');
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
