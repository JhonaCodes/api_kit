/// Method Dispatcher - Replaces mirror-based method invocation
/// Uses a registry pattern to call controller methods without reflection
library;

import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';
import 'base_controller.dart';

/// Method handler function type
typedef MethodHandler = Future<Response> Function(Request request);

/// Method dispatcher registry for AOT compatibility
///
/// Controllers must register their methods with this dispatcher
/// to enable static method calls without mirrors.
class MethodDispatcher {
  static final Map<String, Map<String, MethodHandler>> _registry = {};

  /// Register a method handler for a controller
  static void registerMethod(
    String controllerName,
    String methodName,
    MethodHandler handler,
  ) {
    _registry.putIfAbsent(controllerName, () => {});
    _registry[controllerName]![methodName] = handler;

    Log.d('Registered method: $controllerName.$methodName');
  }

  /// Register multiple methods for a controller
  static void registerController(
    String controllerName,
    Map<String, MethodHandler> methods,
  ) {
    _registry[controllerName] = methods;
    Log.d(
      'Registered controller: $controllerName with ${methods.length} methods',
    );
  }

  /// Call a registered method
  static Future<Response> callMethod(
    String controllerName,
    String methodName,
    Request request,
  ) async {
    final controllerMethods = _registry[controllerName];
    if (controllerMethods == null) {
      Log.e('Controller not registered: $controllerName');
      return Response.notFound(
        '{"error": "Controller not found: $controllerName"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final method = controllerMethods[methodName];
    if (method == null) {
      Log.e('Method not registered: $controllerName.$methodName');
      return Response.notFound(
        '{"error": "Method not found: $methodName"}',
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      Log.d('Calling method: $controllerName.$methodName');
      return await method(request);
    } catch (e, stackTrace) {
      Log.e(
        'Error calling method $controllerName.$methodName',
        error: e,
        stackTrace: stackTrace,
      );
      return Response.internalServerError(
        body: '{"error": "Internal server error"}',
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Check if a method is registered
  static bool isMethodRegistered(String controllerName, String methodName) {
    return _registry[controllerName]?.containsKey(methodName) ?? false;
  }

  /// Get all registered controllers
  static List<String> getRegisteredControllers() {
    return _registry.keys.toList();
  }

  /// Get all registered methods for a controller
  static List<String> getRegisteredMethods(String controllerName) {
    return _registry[controllerName]?.keys.toList() ?? [];
  }

  /// Clear all registrations (useful for testing)
  static void clearRegistry() {
    _registry.clear();
    Log.d('Method registry cleared');
  }

  /// Get registration statistics
  static Map<String, int> getRegistryStats() {
    final stats = <String, int>{};
    for (final entry in _registry.entries) {
      stats[entry.key] = entry.value.length;
    }
    return stats;
  }
}

/// Base class extension to help controllers register their methods
extension ControllerRegistration on BaseController {
  /// Register this controller's methods with the dispatcher
  ///
  /// Subclasses must override this method to register their HTTP methods
  void registerMethods() {
    final controllerName = runtimeType.toString();
    Log.w('Controller $controllerName should override registerMethods()');
  }

  /// Helper method to register a single method
  void registerMethod(String methodName, MethodHandler handler) {
    final controllerName = runtimeType.toString();
    MethodDispatcher.registerMethod(controllerName, methodName, handler);
  }

  /// Helper method to register multiple methods at once
  void registerMethodsMap(Map<String, MethodHandler> methods) {
    final controllerName = runtimeType.toString();
    MethodDispatcher.registerController(controllerName, methods);
  }
}
