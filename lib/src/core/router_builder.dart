import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

import 'reflection_helper.dart';

/// Builds routes automatically from controller annotations.
class RouterBuilder {
  /// Builds a router from a controller using annotations when possible.
  static Future<Router> buildFromController(Object controller) async {
    // Try to use reflection first
    final reflectionRouter = await ReflectionHelper.buildRoutesWithReflection(controller);
    
    if (reflectionRouter != null) {
      Log.i('Routes built successfully using reflection');
      return reflectionRouter;
    }
    
    // Fallback: return empty router with instructions
    Log.w('Reflection not available. Please override the router getter manually.');
    Log.w('Example: @override Router get router { final r = Router(); r.get("/", handler); return r; }');
    
    return Router();
  }
  
  /// Helper method to register routes manually when reflection is not available.
  static void registerRoute(
    Router router,
    String method,
    String path,
    Handler handler,
  ) {
    final normalizedPath = path.isEmpty ? '/' : path;
    
    switch (method.toUpperCase()) {
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
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
  
  /// Extracts the controller path from @Controller annotation.
  static String? extractControllerPath(Object controller) {
    try {
      // Try to use reflection to extract @Controller path
      final reflectionRouter = ReflectionHelper.extractControllerPath(controller);
      return reflectionRouter;
    } catch (e) {
      Log.d('Could not extract controller path via reflection: $e');
      return null;
    }
  }
}