// ignore_for_file: uri_does_not_exist
import 'dart:mirrors' as mirrors;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import '../annotations/controller_annotations.dart';
import 'enhanced_reflection_helper.dart';

/// Route information for sorting and registration
class _RouteInfo {
  final String httpMethod;
  final String path;
  final Symbol methodName;
  final Handler handler;
  final Type controllerType;
  
  _RouteInfo({
    required this.httpMethod,
    required this.path,
    required this.methodName,
    required this.handler,
    required this.controllerType,
  });
  
  /// Static routes have higher priority than parameterized routes
  int get specificity => path.contains('<') && path.contains('>') ? 1 : 0;
}

/// Spring Boot-style reflection helper for annotation-based routing
class ReflectionHelper {
  static const _httpAnnotations = {
    GET: 'GET',
    POST: 'POST', 
    PUT: 'PUT',
    DELETE: 'DELETE',
    PATCH: 'PATCH',
  };

  /// Check if reflection (mirrors) is available
  static bool get isReflectionAvailable {
    try {
      mirrors.reflect('test');
      return true;
    } catch (e) {
      Log.d('Mirrors not available: $e');
      return false;
    }
  }

  /// Build router from controller annotations (Spring Boot style)
  static Future<Router?> buildRoutesWithReflection(Object controller) async {
    if (!isReflectionAvailable) {
      Log.w('Reflection not available. Use manual route registration.');
      return null;
    }

    try {
      Log.i('Building routes from annotations...');
      final router = Router();
      final routes = _extractRoutes(controller);
      
      // Sort by specificity (static routes first)
      routes.sort((a, b) => a.specificity.compareTo(b.specificity));
      
      // Register routes in router with JWT middleware
      for (final route in routes) {
        await _registerRoute(router, route);
      }
      
      Log.i('Successfully registered ${routes.length} routes');
      return router;
    } catch (e, stackTrace) {
      Log.e('Error building routes with reflection', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Extract controller path from @Controller annotation
  static String? extractControllerPath(Object controller) {
    if (!isReflectionAvailable) return null;

    try {
      final classMirror = mirrors.reflect(controller).type;
      
      for (final metadata in classMirror.metadata) {
        if (metadata.reflectee is Controller) {
          return (metadata.reflectee as Controller).path;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extract all routes from controller methods
  static List<_RouteInfo> _extractRoutes(Object controller) {
    final routes = <_RouteInfo>[];
    final controllerMirror = mirrors.reflect(controller);
    final classMirror = controllerMirror.type;
    
    Log.d('Scanning ${classMirror.simpleName} for annotated methods');

    for (final declaration in classMirror.declarations.entries) {
      final methodMirror = declaration.value;
      
      if (_isValidMethod(methodMirror) && methodMirror is mirrors.MethodMirror) {
        final methodName = declaration.key;
        final routeInfo = _processMethod(controllerMirror, methodName, methodMirror, controller.runtimeType);
        if (routeInfo != null) {
          routes.add(routeInfo);
        }
      }
    }

    return routes;
  }

  /// Check if method is valid for route processing
  static bool _isValidMethod(mirrors.DeclarationMirror methodMirror) {
    return methodMirror is mirrors.MethodMirror && 
           !methodMirror.isConstructor && 
           !methodMirror.isGetter && 
           !methodMirror.isSetter;
  }

  /// Process method annotations to create route info
  static _RouteInfo? _processMethod(
    mirrors.InstanceMirror controllerMirror,
    Symbol methodName, 
    mirrors.MethodMirror methodMirror,
    Type controllerType,
  ) {
    for (final metadata in methodMirror.metadata) {
      final annotation = metadata.reflectee;
      
      for (final entry in _httpAnnotations.entries) {
        if (annotation.runtimeType == entry.key) {
          final httpMethod = entry.value;
          final path = _getAnnotationPath(annotation);
          final handler = _createHandler(controllerMirror, methodName, httpMethod, path);
          
          Log.d('Found route: $httpMethod $path -> $methodName');
          
          return _RouteInfo(
            httpMethod: httpMethod,
            path: path.isEmpty ? '/' : path,
            methodName: methodName,
            handler: handler,
            controllerType: controllerType,
          );
        }
      }
    }
    return null;
  }

  /// Get path from annotation
  static String _getAnnotationPath(dynamic annotation) {
    if (annotation is GET) return annotation.path;
    if (annotation is POST) return annotation.path;
    if (annotation is PUT) return annotation.path;
    if (annotation is DELETE) return annotation.path;
    if (annotation is PATCH) return annotation.path;
    return '';
  }

  /// Create handler for method invocation
  static Handler _createHandler(
    mirrors.InstanceMirror controllerMirror,
    Symbol methodName,
    String httpMethod,
    String path,
  ) {
    return (Request request) async {
      try {
        final result = controllerMirror.invoke(methodName, [request]);
        
        // Handle both sync and async methods
        if (result.reflectee is Future) {
          return await result.reflectee as Response;
        } else {
          return result.reflectee as Response;
        }
      } catch (e, stackTrace) {
        Log.e('Error in $httpMethod $path handler: $e');
        return Response.internalServerError(
          body: '{"error": "Internal server error"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  }

  /// Register route in router with JWT middleware support
  static Future<void> _registerRoute(Router router, _RouteInfo route) async {
    Log.d('Registering: ${route.httpMethod} ${route.path} -> ${route.methodName}');
    
    // Obtener middleware JWT para esta ruta
    final jwtMiddlewares = await EnhancedReflectionHelper.createJWTValidationMiddleware(
      route.controllerType, 
      route.methodName.toString()
    );
    
    // Crear handler con middleware JWT aplicado
    Handler finalHandler = route.handler;
    
    if (jwtMiddlewares.isNotEmpty) {
      Log.d('   Applying JWT middleware to ${route.httpMethod} ${route.path}');
      // Aplicar middleware JWT en orden inverso (último middleware aplicado primero)
      for (final middleware in jwtMiddlewares.reversed) {
        finalHandler = middleware(finalHandler);
      }
    }
    
    switch (route.httpMethod) {
      case 'GET':
        router.get(route.path, finalHandler);
        break;
      case 'POST':
        router.post(route.path, finalHandler);
        break;
      case 'PUT':
        router.put(route.path, finalHandler);
        break;
      case 'DELETE':
        router.delete(route.path, finalHandler);
        break;
      case 'PATCH':
        router.patch(route.path, finalHandler);
        break;
      default:
        Log.w('Unsupported HTTP method: ${route.httpMethod}');
    }
  }
}