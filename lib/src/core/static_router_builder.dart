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
  
  // Cache for annotation results to avoid re-analysis on every controller build
  static final Map<String, AnnotationResult> annotationCache = <String, AnnotationResult>{};
  
  /// Clear the annotation cache (useful for development/testing)
  static void clearCache() {
    annotationCache.clear();
  }

  /// Build router from controller using static analysis
  ///
  /// This method analyzes the source code to find annotated methods
  /// and builds a router without using mirrors.
  static Future<Router?> buildFromController(
    BaseController controller, {
    String? projectPath,
    List<String>? includePaths,
  }) async {
    try {
      Log.i('Building routes using static analysis...');

      // Use current directory if no path specified
      final analysisPath = projectPath ?? Directory.current.path;
      
      // Create cache key based on project path and include paths
      final cacheKey = '$analysisPath:${includePaths?.join(',') ?? 'default'}';

      // Check cache first to avoid re-analysis (O(1) lookup)
      AnnotationResult result;
      if (annotationCache.containsKey(cacheKey)) {
        result = annotationCache[cacheKey]!;
        Log.d('Using cached annotations (${result.totalAnnotations} annotations)');
      } else {
        // First time analysis - cache the result
        result = await AnnotationAPI.detectIn(analysisPath, includePaths: includePaths);
        annotationCache[cacheKey] = result;
        Log.i('Analyzed and cached ${result.totalAnnotations} annotations');
      }

      // Performance optimization: Filter annotations early to avoid processing irrelevant ones
      final controllerClassName = controller.runtimeType.toString();
      final relevantAnnotations = result.annotationList.where((annotation) =>
          annotation.targetName.contains(controllerClassName) ||
          annotation.targetName == controllerClassName).toList();
      
      Log.d('Filtered to ${relevantAnnotations.length} relevant annotations for $controllerClassName');

      // No need to register - we'll call methods directly from annotations

      // Build router from detected annotations using only relevant ones
      final router = Router();
      final routes = extractRoutesFromFilteredAnnotations(
        relevantAnnotations,
        controller,
        projectPath: analysisPath,
      );

      // Sort routes by specificity (static routes first)
      routes.sort(
        (a, b) => _getRouteSpecificity(
          a.path,
        ).compareTo(_getRouteSpecificity(b.path)),
      );

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

  /// Extract routes from filtered annotations (performance optimized)
  static List<RouteInfo> extractRoutesFromFilteredAnnotations(
    List<AnnotationDetails> filteredAnnotations,
    BaseController controller, {
    String? projectPath,
  }) {
    final routes = <RouteInfo>[];
    final controllerClassName = controller.runtimeType.toString();

    // Find the RestController annotation for base path
    String basePath = '';
    final restControllerAnnotations = filteredAnnotations.where((annotation) =>
        annotation.annotationType == 'RestController').toList();
    
    for (final restController in restControllerAnnotations) {
      if (restController.targetName == controllerClassName) {
        basePath = restController.restControllerInfo?.basePath ?? '';
        break;
      }
    }

    Log.d(
      'Processing controller $controllerClassName with basePath: $basePath',
    );

    // Process HTTP method annotations from filtered list
    for (final httpMethod in _httpMethods) {
      final methodAnnotations = filteredAnnotations.where((annotation) =>
          annotation.annotationType == httpMethod).toList();

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

  /// Extract routes from analysis result that match the controller (legacy method)
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

    Log.d(
      'Processing controller $controllerClassName with basePath: $basePath',
    );

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

      Log.d(
        'Created JWT-aware route: ${annotation.annotationType.toUpperCase()} $relativePath -> $methodName',
      );

      return RouteInfo(
        httpMethod: annotation.annotationType.toUpperCase(),
        path: relativePath,
        targetName: methodName,
        handler: handler,
        metadata: annotation.rawData,
      );
    } catch (e) {
      Log.w(
        'Failed to create route from annotation ${annotation.annotationType}: $e',
      );
      return null;
    }
  }

  /// Create handler that calls controller method from a simple method map
  static Handler _createMethodHandler(
    BaseController controller,
    String methodName,
  ) {
    return (Request request) async {
      try {
        // Get the method map from the controller - this should be implemented by each controller
        final methodMap = controller.getMethodMap();
        
        if (methodMap.containsKey(methodName)) {
          final method = methodMap[methodName]!;
          final result = await method(request);
          return result;
        } else {
          return Response.notFound(
            '{"error": "Method $methodName not found in controller ${controller.runtimeType}"}',
            headers: {'content-type': 'application/json'},
          );
        }
      } catch (e) {
        Log.e('Error calling method $methodName on ${controller.runtimeType}: $e');
        return Response.internalServerError(
          body: '{"error": "Method $methodName failed: ${e.toString()}"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
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
    Log.d(
      'Registering: ${route.httpMethod} ${route.path} -> ${route.targetName}',
    );

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
  static Future<List<String>> getAvailableRoutes(
    String projectPath, {
    List<String>? includePaths,
  }) async {
    try {
      // Use cache if available
      final cacheKey = '$projectPath:${includePaths?.join(',') ?? 'default'}';
      AnnotationResult result;
      
      if (annotationCache.containsKey(cacheKey)) {
        result = annotationCache[cacheKey]!;
      } else {
        result = await AnnotationAPI.detectIn(projectPath, includePaths: includePaths);
        annotationCache[cacheKey] = result;
      }
      
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

          routes.add(
            '${httpMethod.toUpperCase()} $path -> ${annotation.targetName}',
          );
        }
      }

      return routes;
    } catch (e) {
      Log.e('Error getting available routes: $e');
      return [];
    }
  }
}
