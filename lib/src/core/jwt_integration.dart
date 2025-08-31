import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

import '../annotations/annotation_api.dart';
import '../annotations/annotation_details.dart';
import '../annotations/annotation_result.dart';
import '../validators/jwt_validator_base.dart';
import 'base_controller.dart';
import 'static_router_builder.dart';

/// Integration system for automatic JWT validation based on annotations
/// Connects @JWTController, @JWTEndpoint, @JWTPublic with routing system
class JWTIntegration {
  // Cache for JWT configuration to avoid re-analysis on every request
  static final Map<String, JWTEndpointConfig> _jwtConfigCache =
      <String, JWTEndpointConfig>{};

  /// Creates a JWT-aware handler that applies validators based on annotations
  static Handler createJWTAwareHandler({
    required BaseController controller,
    required String methodName,
    required Future<Response> Function(Request) originalHandler,
    String? projectPath,
  }) {
    return (Request request) async {
      try {
        // Get JWT validation requirements for this endpoint
        final jwtConfig = await _getJWTConfigForEndpoint(
          controller,
          methodName,
          projectPath,
        );

        // Apply JWT validation if required
        if (jwtConfig.isPublic) {
          // Public endpoint - no JWT validation
          Log.d('Public endpoint: $methodName - skipping JWT validation');
          return await originalHandler(request);
        }

        if (jwtConfig.validators.isEmpty) {
          // No specific JWT validators - use basic JWT check if enabled
          final jwtPayload =
              request.context['jwt_payload'] as Map<String, dynamic>?;
          if (jwtPayload == null) {
            return Response.unauthorized('JWT token required');
          }
          return await originalHandler(request);
        }

        // Apply specific JWT validators
        final validationResult = await _validateWithValidators(
          request,
          jwtConfig.validators,
          jwtConfig.requireAll,
        );

        if (!validationResult.isValid) {
          return Response.forbidden(
            validationResult.errorMessage ?? 'Access denied',
          );
        }

        // All validations passed - proceed with original handler
        return await originalHandler(request);
      } catch (e) {
        Log.e('Error in JWT integration for $methodName: $e');
        return Response.internalServerError(
          body: '{"error": "Authentication error"}',
        );
      }
    };
  }

  /// Gets JWT configuration for a specific endpoint
  static Future<JWTEndpointConfig> _getJWTConfigForEndpoint(
    BaseController controller,
    String methodName,
    String? projectPath,
  ) async {
    try {
      final controllerName = controller.runtimeType.toString();
      final cacheKey = '$controllerName.$methodName';

      // Check cache first (O(1) lookup)
      if (_jwtConfigCache.containsKey(cacheKey)) {
        return _jwtConfigCache[cacheKey]!;
      }

      // Use StaticRouterBuilder cache to avoid re-analysis
      final analysisPath = projectPath ?? Directory.current.path;
      final builderCacheKey = '$analysisPath:default';

      AnnotationResult? result;
      // Try to get from StaticRouterBuilder cache
      if (StaticRouterBuilder.annotationCache.containsKey(builderCacheKey)) {
        result = StaticRouterBuilder.annotationCache[builderCacheKey]!;
      } else {
        // Fallback: run analysis and cache it
        result = await AnnotationAPI.detectIn(analysisPath);
        StaticRouterBuilder.annotationCache[builderCacheKey] = result;
      }

      // Check for @JWTPublic on the specific method
      final publicAnnotations = result.ofType('JWTPublic');
      for (final annotation in publicAnnotations) {
        if (annotation.targetName == '$controllerName.$methodName') {
          final config = JWTEndpointConfig.public();
          _jwtConfigCache[cacheKey] = config;
          return config;
        }
      }

      // Check for @JWTEndpoint on the specific method
      final endpointAnnotations = result.ofType('JWTEndpoint');
      for (final annotation in endpointAnnotations) {
        if (annotation.targetName == '$controllerName.$methodName') {
          final config = _extractJWTEndpointConfig(annotation);
          _jwtConfigCache[cacheKey] = config;
          return config;
        }
      }

      // Check for @JWTController on the controller class
      final controllerAnnotations = result.ofType('JWTController');
      for (final annotation in controllerAnnotations) {
        if (annotation.targetName == controllerName) {
          final config = _extractJWTControllerConfig(annotation);
          _jwtConfigCache[cacheKey] = config;
          return config;
        }
      }

      // No JWT annotations found - return basic auth requirement
      final config = JWTEndpointConfig.basicAuth();
      _jwtConfigCache[cacheKey] = config;
      return config;
    } catch (e) {
      Log.w('Error getting JWT config for .$methodName: $e');
      return JWTEndpointConfig.basicAuth();
    }
  }

  /// Extracts configuration from @JWTEndpoint annotation
  static JWTEndpointConfig _extractJWTEndpointConfig(
    AnnotationDetails annotation,
  ) {
    try {
      // Note: Since this uses static analysis, we get the annotation data
      // but not the actual validator instances. For now, we'll use a simplified approach.
      // TODO: Implement proper validator extraction from static analysis

      Log.d('Found @JWTEndpoint annotation for ${annotation.targetName}');
      return JWTEndpointConfig.withValidators([], requireAll: true);
    } catch (e) {
      Log.w('Error extracting JWT endpoint config: $e');
      return JWTEndpointConfig.basicAuth();
    }
  }

  /// Extracts configuration from @JWTController annotation
  static JWTEndpointConfig _extractJWTControllerConfig(
    AnnotationDetails annotation,
  ) {
    try {
      Log.d('Found @JWTController annotation for ${annotation.targetName}');
      return JWTEndpointConfig.withValidators([], requireAll: true);
    } catch (e) {
      Log.w('Error extracting JWT controller config: $e');
      return JWTEndpointConfig.basicAuth();
    }
  }

  /// Validates request using the provided validators
  /// TODO: Use Map for register on static analysis, then just find by key, this help for performance.
  static Future<ValidationResult> _validateWithValidators(
    Request request,
    List<JWTValidatorBase> validators,
    bool requireAll,
  ) async {
    if (validators.isEmpty) {
      return ValidationResult.valid();
    }

    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    if (jwtPayload == null) {
      return ValidationResult.invalid('JWT token required');
    }

    final results = <ValidationResult>[];

    // Run all validators
    for (final validator in validators) {
      try {
        final result = validator.validate(request, jwtPayload);
        results.add(result);

        if (result.isSuccess) {
          validator.onValidationSuccess(request, jwtPayload);
        } else {
          validator.onValidationFailed(
            request,
            jwtPayload,
            result.errorMessage ?? 'Validation failed',
          );
        }

        // Early exit for AND logic if any validator fails
        if (requireAll && result.isFailure) {
          return result;
        }

        // Early exit for OR logic if any validator succeeds
        if (!requireAll && result.isSuccess) {
          return result;
        }
      } catch (e) {
        Log.e('Error in JWT validator ${validator.runtimeType}: $e');
        final errorResult = ValidationResult.invalid('Validator error: $e');
        results.add(errorResult);

        if (requireAll) {
          return errorResult;
        }
      }
    }

    // Determine final result based on logic type
    if (requireAll) {
      // AND logic - all must pass (we only get here if all passed)
      return ValidationResult.valid();
    } else {
      // OR logic - at least one must pass
      final hasSuccess = results.any((r) => r.isSuccess);
      return hasSuccess
          ? ValidationResult.valid()
          : ValidationResult.invalid('All JWT validations failed');
    }
  }
}

/// Configuration for JWT validation on an endpoint
class JWTEndpointConfig {
  final bool isPublic;
  final bool requiresBasicAuth;
  final List<JWTValidatorBase> validators;
  final bool requireAll;

  JWTEndpointConfig._({
    required this.isPublic,
    required this.requiresBasicAuth,
    required this.validators,
    required this.requireAll,
  });

  /// Creates a public endpoint configuration (no JWT required)
  factory JWTEndpointConfig.public() {
    return JWTEndpointConfig._(
      isPublic: true,
      requiresBasicAuth: false,
      validators: [],
      requireAll: false,
    );
  }

  /// Creates a basic auth configuration (JWT required but no specific validators)
  factory JWTEndpointConfig.basicAuth() {
    return JWTEndpointConfig._(
      isPublic: false,
      requiresBasicAuth: true,
      validators: [],
      requireAll: false,
    );
  }

  /// Creates a configuration with specific validators
  factory JWTEndpointConfig.withValidators(
    List<JWTValidatorBase> validators, {
    required bool requireAll,
  }) {
    return JWTEndpointConfig._(
      isPublic: false,
      requiresBasicAuth: false,
      validators: validators,
      requireAll: requireAll,
    );
  }
}
