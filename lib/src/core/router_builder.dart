/// Router Builder - Now uses Static Analysis as primary method
/// Falls back to mirrors only when necessary for backward compatibility
library;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logger_rs/logger_rs.dart';

// import 'reflection_helper.dart'; // REMOVED - No more mirrors!
import 'static_router_builder.dart';
import 'base_controller.dart';

/// Builds routes automatically from controller annotations.
///
/// 🆕 NEW: Uses ONLY static analysis (AOT compatible, mirrors-free!)
/// ❌ OLD: Mirrors completely removed - no fallback!
class RouterBuilder {
  /// Builds a router from a controller using static analysis ONLY
  ///
  /// Requirements:
  /// 1. Controller must extend BaseController
  /// 2. Controller must override registerMethods()
  /// 3. Use annotations from static_analysis package
  static Future<Router> buildFromController(Object controller) async {
    // Ensure the controller is a BaseController for method registration
    if (controller is BaseController) {
      return await _buildWithStaticAnalysis(controller);
    }

    Log.e('❌ Controller must extend BaseController for static analysis!');
    Log.e('❌ Mirrors have been completely removed from api_kit');
    return _createEmptyRouterWithInstructions();
  }

  /// Build using static analysis (preferred method)
  static Future<Router> _buildWithStaticAnalysis(
    BaseController controller,
  ) async {
    try {
      Log.i('🚀 Building routes using static analysis (AOT compatible)...');

      // Try static analysis first
      final staticRouter = await StaticRouterBuilder.buildFromController(
        controller,
      );

      if (staticRouter != null) {
        Log.i('✅ Routes built successfully using static analysis');
        return staticRouter;
      }

      Log.e('❌ Static analysis returned null - check your annotations');
      return _createEmptyRouterWithInstructions();
    } catch (e) {
      Log.e('❌ Static analysis failed: $e');
      return _createEmptyRouterWithInstructions();
    }
  }

  // 🚫 NO REFLECTION FALLBACK - MIRRORS COMPLETELY REMOVED!

  /// Create empty router with instructions for manual registration
  static Router _createEmptyRouterWithInstructions() {
    Log.e('❌ Static analysis failed - mirrors are NOT available!');
    Log.w('📝 Manual router registration required');
    Log.w('💡 Example: @override Router get router {');
    Log.w('💡   final r = Router();');
    Log.w('💡   r.get("/api/users", getUsersHandler);');
    Log.w('💡   return r;');
    Log.w('💡 }');
    Log.w('');
    Log.w('🔧 For static analysis to work:');
    Log.w('   1. Ensure controller extends BaseController');
    Log.w('   2. Override registerMethods() to register your handlers');
    Log.w('   3. Use annotations from static_analysis package');
    Log.w('   4. Ensure your source code is analyzable');

    return Router();
  }

  /// Helper method to register routes manually when auto-discovery fails
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

  /// Extracts the controller path from annotations using static analysis
  static String? extractControllerPath(Object controller) {
    // TODO: Implement controller path extraction from static analysis
    Log.w(
      'Controller path extraction from static analysis not yet implemented',
    );
    return null;
  }

  /// Get routing method being used (for debugging)
  static Future<String> getRoutingMethod(Object controller) async {
    if (controller is BaseController) {
      try {
        final staticRouter = await StaticRouterBuilder.buildFromController(
          controller,
        );
        if (staticRouter != null) {
          return 'Static Analysis (AOT Compatible)';
        }
      } catch (e) {
        // Static analysis failed
      }
    }

    return 'Manual Registration Required (Static Analysis Failed)';
  }

  /// Get routing statistics
  static Future<Map<String, dynamic>> getRoutingStats(Object controller) async {
    final method = await getRoutingMethod(controller);

    return {
      'routing_method': method,
      'is_aot_compatible': method.contains('Static Analysis'),
      'controller_type': controller.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
