/// Static Router Builder - Replaces mirror-based reflection system
/// Uses static analysis to build routes at build-time or on-demand
library;

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import '../annotations/annotation_api.dart';
import '../annotations/annotation_details.dart';
import '../annotations/annotation_result.dart';
import 'base_controller.dart';
import 'jwt_integration.dart';

/// Route information for registration
class RouteInfo {
  final String httpMethod;
  final String path;
  final String targetName;
  final Handler handler;
  final Map<String, dynamic> metadata;

  RouteInfo({
    required this.httpMethod,
    required this.path,
    required this.targetName,
    required this.handler,
    this.metadata = const {},
  });
}

/// Static Router Builder - AOT Compatible, No Mirrors
/// 
/// This replaces the old mirror-based reflection system with static analysis.
/// Routes are discovered by analyzing the source code at build time.
class StaticRouterBuilder {
  static const _httpMethods = ['Get', 'Post', 'Put', 'Patch', 'Delete'];
  
  /// Build router from controller using static analysis
  /// 
  /// This method analyzes the source code to find annotated methods
  /// and builds a router without using mirrors.
  static Future<Router?> buildFromController(
    BaseController controller, {
    String? projectPath,
  }) async {
    try {
      Log.i('Building routes using static analysis...');
      
      // Use current directory if no path specified
      final analysisPath = projectPath ?? Directory.current.path;
      
      // Detect annotations in the project
      final result = await AnnotationAPI.detectIn(analysisPath);
      
      Log.i('Found ${result.totalAnnotations} annotations');
      
      // No need to register - we'll call methods directly from annotations
      
      // Build router from detected annotations
      final router = Router();
      final routes = extractRoutesFromResult(result, controller, projectPath: analysisPath);
      
      // Sort routes by specificity (static routes first)
      routes.sort((a, b) => _getRouteSpecificity(a.path).compareTo(_getRouteSpecificity(b.path)));
      
      // Register routes
      for (final route in routes) {
        _registerRoute(router, route);
      }
      
      Log.i('Successfully registered ${routes.length} routes');
      return router;
      
    } catch (e, stackTrace) {
      Log.e(
        'Error building routes with static analysis',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Extract routes from analysis result that match the controller
  static List<RouteInfo> extractRoutesFromResult(
    AnnotationResult result,
    BaseController controller, {
    String? projectPath,
  }) {
    final routes = <RouteInfo>[];
    final controllerClassName = controller.runtimeType.toString();
    
    // Find the RestController annotation for base path
    String basePath = '';
    final restControllers = result.ofType('RestController');
    for (final restController in restControllers) {
      if (restController.targetName == controllerClassName) {
        basePath = restController.restControllerInfo?.basePath ?? '';
        break;
      }
    }
    
    Log.d('Processing controller $controllerClassName with basePath: $basePath');
    
    // Process HTTP method annotations
    for (final httpMethod in _httpMethods) {
      final methodAnnotations = result.ofType(httpMethod);
      
      for (final annotation in methodAnnotations) {
        // Check if this annotation belongs to our controller
        if (annotation.targetName.startsWith('$controllerClassName.')) {
          final route = _createRouteFromAnnotation(
            annotation,
            controller,
            basePath,
            projectPath,
          );
          if (route != null) {
            routes.add(route);
          }
        }
      }
    }
    
    return routes;
  }
  
  /// Create route info from annotation
  static RouteInfo? _createRouteFromAnnotation(
    AnnotationDetails annotation,
    BaseController controller,
    String basePath,
    String? projectPath,
  ) {
    try {
      // Extract method name from target (e.g., "UserController.getUsers" -> "getUsers")
      final methodName = annotation.targetName.split('.').last;
      
      // Get path from annotation
      String annotationPath = '';
      switch (annotation.annotationType) {
        case 'Get':
          annotationPath = annotation.getInfo?.path ?? '';
          break;
        case 'Post':
          annotationPath = annotation.postInfo?.path ?? '';
          break;
        case 'Put':
          annotationPath = annotation.putInfo?.path ?? '';
          break;
        case 'Patch':
          annotationPath = annotation.patchInfo?.path ?? '';
          break;
        case 'Delete':
          annotationPath = annotation.deleteInfo?.path ?? '';
          break;
      }
      
      // Use only the annotation path (relative), let ApiServer handle the basePath mount
      // Convert {id} syntax to <id> syntax for Shelf router compatibility
      String relativePath = annotationPath.isEmpty ? '/' : annotationPath;
      relativePath = _convertPathParams(relativePath);
      
      // Create basic handler that calls the method on the controller
      final basicHandler = _createMethodHandler(controller, methodName);
      
      // Create JWT-aware handler using the JWT integration system
      final handler = JWTIntegration.createJWTAwareHandler(
        controller: controller,
        methodName: methodName,
        originalHandler: (Request request) async => await basicHandler(request),
        projectPath: projectPath,
      );
      
      Log.d('Created JWT-aware route: ${annotation.annotationType.toUpperCase()} $relativePath -> $methodName');
      
      return RouteInfo(
        httpMethod: annotation.annotationType.toUpperCase(),
        path: relativePath,
        targetName: methodName,
        handler: handler,
        metadata: annotation.rawData,
      );
      
    } catch (e) {
      Log.w('Failed to create route from annotation ${annotation.annotationType}: $e');
      return null;
    }
  }
  
  /// Create handler that calls the method directly on the controller
  static Handler _createMethodHandler(BaseController controller, String methodName) {
    return (Request request) async {
      try {
        // Call the method directly based on the method name from annotations
        // This is a simple approach that works without mirrors or complex registration
        
        final methodMap = _getControllerMethods(controller);
        final method = methodMap[methodName];
        
        if (method != null) {
          return await method(request);
        } else {
          return Response.notFound('Method $methodName not found in controller');
        }
        
      } catch (e) {
        Log.e('Error in method handler for $methodName: $e');
        return Response.internalServerError(
          body: '{"error": "Internal server error"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  }
  
  /// Get controller methods mapped by name for direct invocation
  static Map<String, Future<Response> Function(Request)> _getControllerMethods(BaseController controller) {
    // Try to call getMethodsMap() if the controller implements it
    try {
      final dynamic dynamicController = controller;
      if (dynamicController.getMethodsMap != null) {
        return dynamicController.getMethodsMap() as Map<String, Future<Response> Function(Request)>;
      }
    } catch (e) {
      Log.w('Controller ${controller.runtimeType} does not implement getMethodsMap(): $e');
    }
    
    return {};
  }
  
  
  /// Convert path parameters from {param} to <param> format for Shelf router
  static String _convertPathParams(String path) {
    // Convert {param} to <param> for Shelf router compatibility
    return path.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
      return '<${match.group(1)}>';
    });
  }
  
  /// Get route specificity for sorting (lower = higher priority)
  static int _getRouteSpecificity(String path) {
    // Static routes have higher priority (lower number)
    // Parameterized routes have lower priority (higher number)
    return path.contains('<') && path.contains('>') ? 1 : 0;
  }
  
  /// Register route in the router
  static void _registerRoute(Router router, RouteInfo route) {
    Log.d('Registering: ${route.httpMethod} ${route.path} -> ${route.targetName}');
    
    switch (route.httpMethod) {
      case 'GET':
        router.get(route.path, route.handler);
        break;
      case 'POST':
        router.post(route.path, route.handler);
        break;
      case 'PUT':
        router.put(route.path, route.handler);
        break;
      case 'DELETE':
        router.delete(route.path, route.handler);
        break;
      case 'PATCH':
        router.patch(route.path, route.handler);
        break;
      default:
        Log.w('Unsupported HTTP method: ${route.httpMethod}');
    }
  }
  
  /// Get all available routes from analysis
  static Future<List<String>> getAvailableRoutes(String projectPath) async {
    try {
      final result = await AnnotationAPI.detectIn(projectPath);
      final routes = <String>[];
      
      for (final httpMethod in _httpMethods) {
        final annotations = result.ofType(httpMethod);
        for (final annotation in annotations) {
          String path = '';
          switch (annotation.annotationType) {
            case 'Get':
              path = annotation.getInfo?.path ?? '';
              break;
            case 'Post':
              path = annotation.postInfo?.path ?? '';
              break;
            case 'Put':
              path = annotation.putInfo?.path ?? '';
              break;
            case 'Patch':
              path = annotation.patchInfo?.path ?? '';
              break;
            case 'Delete':
              path = annotation.deleteInfo?.path ?? '';
              break;
          }
          
          routes.add('${httpMethod.toUpperCase()} $path -> ${annotation.targetName}');
        }
      }
      
      return routes;
    } catch (e) {
      Log.e('Error getting available routes: $e');
      return [];
    }
  }
}