// ignore_for_file: uri_does_not_exist
import 'dart:mirrors' as mirrors;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import '../annotations/controller_annotations.dart';

/// Helper class to handle reflection-based route building.
class ReflectionHelper {
  /// Indicates if mirrors are available in the current environment.
  static bool get isReflectionAvailable {
    try {
      // Try to actually use mirrors API with a simple test
      mirrors.reflect('test');
      return true;
    } catch (e) {
      Log.d('Mirrors not available: $e');
      return false;
    }
  }

  /// Builds routes using reflection if available.
  static Router? buildRoutesWithReflection(Object controller) {
    Log.i('Checking reflection availability...');
    if (!isReflectionAvailable) {
      Log.w('Reflection not available. Use manual route registration.');
      return null;
    }

    Log.i('Reflection available, building routes...');
    try {
      final router = Router();
      final controllerMirror = mirrors.reflect(controller);
      final classMirror = controllerMirror.type;
      Log.d('Controller type: ${classMirror.simpleName}');
      
      // Get base path from @Controller annotation
      String basePath = '';
      for (final metadata in classMirror.metadata) {
        if (metadata.reflectee is Controller) {
          basePath = (metadata.reflectee as Controller).path;
          Log.d('Found controller with base path: $basePath');
          break;
        }
      }
      
      // Process all methods looking for HTTP annotations
      Log.d('Processing ${classMirror.declarations.length} declarations...');
      int routeCount = 0;
      for (final declaration in classMirror.declarations.entries) {
        final methodMirror = declaration.value;
        
        if (methodMirror is mirrors.MethodMirror && 
            !methodMirror.isConstructor && 
            !methodMirror.isGetter && 
            !methodMirror.isSetter) {
          final methodName = declaration.key;
          
          // Check for HTTP method annotations
          for (final metadata in methodMirror.metadata) {
            final annotation = metadata.reflectee;
            String? httpMethod;
            String routePath = '';
            
            if (annotation is GET) {
              httpMethod = 'GET';
              routePath = annotation.path;
            } else if (annotation is POST) {
              httpMethod = 'POST';
              routePath = annotation.path;
            } else if (annotation is PUT) {
              httpMethod = 'PUT';
              routePath = annotation.path;
            } else if (annotation is DELETE) {
              httpMethod = 'DELETE';
              routePath = annotation.path;
            } else if (annotation is PATCH) {
              httpMethod = 'PATCH';
              routePath = annotation.path;
            }
            
            if (httpMethod != null) {
              final fullPath = basePath + routePath;
              final normalizedPath = routePath.isEmpty ? '/' : routePath;
              
              Log.d('Registering route: $httpMethod $fullPath -> $methodName');
              Log.d('  routePath: "$routePath"');
              Log.d('  normalizedPath: "$normalizedPath"');
              Log.d('  basePath: "$basePath"');
              
              // Create handler that calls the controller method
              Handler handler = (Request request) async {
                try {
                  final result = controllerMirror.invoke(methodName, [request]);
                  
                  // Handle both sync and async methods
                  if (result.reflectee is Future) {
                    return await result.reflectee as Response;
                  } else {
                    return result.reflectee as Response;
                  }
                } catch (e, stackTrace) {
                  Log.e('Error in route handler $httpMethod $fullPath', 
                        error: e, stackTrace: stackTrace);
                  return Response.internalServerError(
                    body: '{"error": "Internal server error"}',
                    headers: {'content-type': 'application/json'},
                  );
                }
              };
              
              // Register the route
              switch (httpMethod) {
                case 'GET':
                  router.get(normalizedPath, handler);
                  break;
                case 'POST':
                  router.post(normalizedPath, handler);
                  break;
                case 'PUT':
                  router.put(normalizedPath, handler);
                  break;
                case 'DELETE':
                  router.delete(normalizedPath, handler);
                  break;
                case 'PATCH':
                  router.patch(normalizedPath, handler);
                  break;
              }
              routeCount++;
            }
          }
        }
      }
      
      Log.i('Successfully registered $routeCount routes using reflection');
      return router;
    } catch (e, stackTrace) {
      Log.e('Error building routes with reflection', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Extracts the controller path from @Controller annotation.
  static String? extractControllerPath(Object controller) {
    if (!isReflectionAvailable) {
      return null;
    }

    try {
      final controllerMirror = mirrors.reflect(controller);
      final classMirror = controllerMirror.type;
      
      // Get base path from @Controller annotation
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
}
