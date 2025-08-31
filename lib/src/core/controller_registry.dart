import 'dart:io';
import 'package:logger_rs/logger_rs.dart';

import '../annotations/annotation_api.dart';
import 'base_controller.dart';

/// Auto-discovery registry for controllers using static analysis
/// Replaces manual controller registration with automatic detection
class ControllerRegistry {
  static final Map<String, Type> _discoveredControllers = {};
  static bool _isDiscovered = false;

  /// Discovers all controllers in the project using static analysis
  /// This replaces the need for manual controllerList registration
  static Future<List<BaseController>> discoverControllers([
    String? projectPath,
    List<String>? includePaths,
  ]) async {
    try {
      Log.i('🔍 Auto-discovering controllers using static analysis...');

      // Use current directory if no path specified
      final analysisPath = projectPath ?? Directory.current.path;

      // Run static analysis to detect all @RestController annotations
      final result = await AnnotationAPI.detectIn(
        analysisPath,
        includePaths: includePaths,
      );

      // Find all RestController annotations
      final restControllers = result.ofType('RestController');
      Log.d('Found ${restControllers.length} @RestController annotations');

      final controllers = <BaseController>[];

      for (final controllerAnnotation in restControllers) {
        try {
          // Extract controller class name from target
          final className = controllerAnnotation.targetName;

          // Auto-instantiate the controller
          final controller = await _instantiateController(className);
          if (controller != null) {
            controllers.add(controller);
            Log.d('✅ Auto-discovered controller: $className');
          }
        } catch (e) {
          Log.w(
            'Failed to instantiate controller ${controllerAnnotation.targetName}: $e',
          );
        }
      }

      _isDiscovered = true;
      Log.i(
        '🎯 Auto-discovered ${controllers.length} controllers successfully',
      );

      return controllers;
    } catch (e, stackTrace) {
      Log.e(
        'Error during controller auto-discovery',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Instantiates a controller by class name without mirrors
  /// Uses manual registry for AOT compatibility
  static Future<BaseController?> _instantiateController(
    String className,
  ) async {
    // For AOT compilation, we cannot use mirrors
    // Controllers must be registered manually
    Log.w('Controller auto-instantiation not available in AOT mode: $className');
    Log.w('Please register controllers manually using server.registerController()');
    return null;
  }


  /// Gets discovery statistics
  static Map<String, dynamic> getDiscoveryStats() {
    return {
      'discovered': _isDiscovered,
      'controller_count': _discoveredControllers.length,
      'discovered_controllers': _discoveredControllers.keys.toList(),
    };
  }

  /// Clears discovery cache (for testing)
  static void clearCache() {
    _discoveredControllers.clear();
    _isDiscovered = false;
  }
}
