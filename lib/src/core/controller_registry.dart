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

  /// Instantiates a controller by class name using mirrors
  /// This is the only place where mirrors are used, and only for instantiation
  static Future<BaseController?> _instantiateController(
    String className,
  ) async {
    try {
      // Use mirrors only for controller instantiation
      // This is a controlled use that can be replaced with code generation later
      final mirrors = currentMirrorSystem();

      for (final library in mirrors.libraries.values) {
        for (final classMirror in library.declarations.values) {
          if (classMirror is ClassMirror &&
              classMirror.simpleName
                      .toString()
                      .replaceAll('Symbol("', '')
                      .replaceAll('")', '') ==
                  className) {
            // Check if extends BaseController
            if (_extendsBaseController(classMirror)) {
              final instance = classMirror
                  .newInstance(Symbol(''), [])
                  .reflectee;
              if (instance is BaseController) {
                return instance;
              }
            }
          }
        }
      }

      Log.w('Controller class not found: $className');
      return null;
    } catch (e) {
      Log.e('Error instantiating controller $className: $e');
      return null;
    }
  }

  /// Checks if a class extends BaseController
  static bool _extendsBaseController(ClassMirror classMirror) {
    ClassMirror? current = classMirror;

    while (current != null) {
      final className = current.simpleName
          .toString()
          .replaceAll('Symbol("', '')
          .replaceAll('")', '');
      if (className == 'BaseController') {
        return true;
      }
      current = current.superclass;
    }

    return false;
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
