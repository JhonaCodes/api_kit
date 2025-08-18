// ignore_for_file: uri_does_not_exist
import 'dart:convert';
import 'dart:mirrors' as mirrors;
import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

import 'reflection_helper.dart';
import '../annotations/jwt_annotations.dart';
import '../validators/jwt_validator_base.dart';

/// Sistema de reflexión mejorado para JWT validation
/// 
/// Extiende ReflectionHelper con capacidades de detección y procesamiento
/// de anotaciones JWT (@JWTController, @JWTEndpoint, @JWTPublic)
class EnhancedReflectionHelper extends ReflectionHelper {
  
  /// Verifica si reflection está disponible
  static bool get isReflectionAvailable => ReflectionHelper.isReflectionAvailable;
  
  /// Obtiene la lista de métodos HTTP de un controlador
  static List<String> getControllerMethods(Type controllerType) {
    if (!isReflectionAvailable) return [];
    
    try {
      final classMirror = mirrors.reflectClass(controllerType);
      final methods = <String>[];
      
      // Obtener todos los métodos que tienen anotaciones HTTP
      for (final declaration in classMirror.declarations.entries) {
        if (declaration.value is mirrors.MethodMirror) {
          final methodMirror = declaration.value as mirrors.MethodMirror;
          final methodName = declaration.key.toString();
          
          // Verificar si el método tiene alguna anotación HTTP
          for (final metadata in methodMirror.metadata) {
            final annotation = metadata.reflectee;
            if (_isHttpAnnotation(annotation)) {
              methods.add(methodName);
              break;
            }
          }
        }
      }
      
      Log.d('Found ${methods.length} HTTP methods in $controllerType: ${methods.join(', ')}');
      return methods;
    } catch (e) {
      Log.w('Failed to get controller methods for $controllerType: $e');
      return [];
    }
  }
  
  /// Verifica si una anotación es una anotación HTTP
  static bool _isHttpAnnotation(dynamic annotation) {
    return annotation.runtimeType.toString() == 'GET' ||
           annotation.runtimeType.toString() == 'POST' ||
           annotation.runtimeType.toString() == 'PUT' ||
           annotation.runtimeType.toString() == 'DELETE' ||
           annotation.runtimeType.toString() == 'PATCH';
  }
  
  /// Extrae el nombre del método de una representación Symbol
  /// Maneja múltiples formatos: Symbol("methodName"), Symbol(methodName), methodName
  static String _extractMethodNameFromSymbol(String methodName) {
    // Log para debugging
    Log.d('Processing method name: "$methodName"');
    
    // Formato: Symbol("methodName")
    if (methodName.startsWith('Symbol("') && methodName.endsWith('")')) {
      final extracted = methodName.substring(8, methodName.length - 2);
      Log.d('  -> Extracted from Symbol("..."): "$extracted"');
      return extracted;
    }
    
    // Formato: Symbol(methodName) 
    if (methodName.startsWith('Symbol(') && methodName.endsWith(')')) {
      final extracted = methodName.substring(7, methodName.length - 1);
      Log.d('  -> Extracted from Symbol(...): "$extracted"');
      return extracted;
    }
    
    // Ya está limpio
    Log.d('  -> Using as-is: "$methodName"');
    return methodName;
  }
  
  /// Detecta y procesa anotaciones JWT en controladores y endpoints
  /// 
  /// [controllerType] - Tipo del controlador a analizar
  /// [methodName] - Nombre del método/endpoint a analizar
  /// 
  /// Retorna lista de middlewares JWT que deben aplicarse a este endpoint
  static Future<List<Middleware>> createJWTValidationMiddleware(
    Type controllerType,
    String methodName,
  ) async {
    final middlewares = <Middleware>[];
    
    try {
      Log.d('Creating JWT validation middleware for: $controllerType.$methodName');
      
      // Verificar anotación @JWTPublic primero (mayor prioridad)
      if (_hasJWTPublicAnnotation(controllerType, methodName)) {
        Log.i('🔓 Public endpoint detected: $controllerType.$methodName - No JWT validation required');
        return middlewares; // Sin middleware de validación
      }
      
      // Obtener validadores del método (endpoint-level)
      final endpointValidators = _getJWTEndpointValidators(controllerType, methodName);
      
      // Si hay validadores a nivel de endpoint, usarlos (sobrescriben controller)
      if (endpointValidators != null) {
        Log.i('🔐 Endpoint-level JWT validation: $controllerType.$methodName');
        middlewares.add(_createValidationMiddleware(
          endpointValidators.validators, 
          endpointValidators.requireAll,
          '$controllerType.$methodName'
        ));
        return middlewares;
      }
      
      // Obtener validadores del controlador (controller-level)
      final controllerValidators = _getJWTControllerValidators(controllerType);
      
      if (controllerValidators != null) {
        Log.i('🔐 Controller-level JWT validation: $controllerType.$methodName');
        middlewares.add(_createValidationMiddleware(
          controllerValidators.validators, 
          controllerValidators.requireAll,
          '$controllerType.$methodName'
        ));
        return middlewares;
      }
      
      // Sin validación JWT configurada
      Log.d('🔓 No JWT validation configured for: $controllerType.$methodName');
      return middlewares;
      
    } catch (e, stackTrace) {
      Log.e('Error creating JWT validation middleware for $controllerType.$methodName: $e');
      return middlewares;
    }
  }
  
  /// Verifica si un método tiene anotación @JWTPublic
  static bool _hasJWTPublicAnnotation(Type controllerType, String methodName) {
    if (!isReflectionAvailable) return false;
    
    try {
      final classMirror = mirrors.reflectClass(controllerType);
      final cleanMethodName = _extractMethodNameFromSymbol(methodName);
      final methodSymbol = Symbol(cleanMethodName);
      
      // Buscar el método en la clase
      for (final declaration in classMirror.declarations.entries) {
        if (declaration.key == methodSymbol && declaration.value is mirrors.MethodMirror) {
          final methodMirror = declaration.value as mirrors.MethodMirror;
          
          // Verificar si tiene anotación @JWTPublic
          for (final metadata in methodMirror.metadata) {
            if (metadata.reflectee is JWTPublic) {
              Log.d('Found @JWTPublic annotation on $controllerType.$cleanMethodName');
              return true;
            }
          }
          break;
        }
      }
      
      return false;
    } catch (e) {
      Log.w('Failed to check JWTPublic annotation for $controllerType.$methodName: $e');
      return false;
    }
  }
  
  /// Obtiene validadores de anotación @JWTEndpoint
  static JWTEndpointConfig? _getJWTEndpointValidators(Type controllerType, String methodName) {
    if (!isReflectionAvailable) return null;
    
    try {
      final classMirror = mirrors.reflectClass(controllerType);
      final cleanMethodName = _extractMethodNameFromSymbol(methodName);
      final methodSymbol = Symbol(cleanMethodName);
      
      // Buscar el método en la clase
      for (final declaration in classMirror.declarations.entries) {
        if (declaration.key == methodSymbol && declaration.value is mirrors.MethodMirror) {
          final methodMirror = declaration.value as mirrors.MethodMirror;
          
          // Verificar si tiene anotación @JWTEndpoint
          for (final metadata in methodMirror.metadata) {
            if (metadata.reflectee is JWTEndpoint) {
              final annotation = metadata.reflectee as JWTEndpoint;
              Log.d('Found @JWTEndpoint annotation on $controllerType.$cleanMethodName with ${annotation.validators.length} validators');
              return JWTEndpointConfig(annotation.validators, annotation.requireAll);
            }
          }
          break;
        }
      }
      
      return null; // No hay anotación @JWTEndpoint
      
    } catch (e) {
      Log.w('Failed to get JWTEndpoint validators for $controllerType.$methodName: $e');
      return null;
    }
  }
  
  /// Obtiene validadores de anotación @JWTController
  static JWTControllerConfig? _getJWTControllerValidators(Type controllerType) {
    if (!isReflectionAvailable) return null;
    
    try {
      final classMirror = mirrors.reflectClass(controllerType);
      
      // Verificar si tiene anotación @JWTController
      for (final metadata in classMirror.metadata) {
        if (metadata.reflectee is JWTController) {
          final annotation = metadata.reflectee as JWTController;
          Log.d('Found @JWTController annotation on $controllerType with ${annotation.validators.length} validators, requireAll: ${annotation.requireAll}');
          return JWTControllerConfig(annotation.validators, annotation.requireAll);
        }
      }
      
      return null; // No hay anotación @JWTController
      
    } catch (e) {
      Log.w('Failed to get JWTController validators for $controllerType: $e');
      return null;
    }
  }
  
  /// Crea middleware de validación JWT según especificaciones de la documentación
  static Middleware _createValidationMiddleware(
    List<JWTValidatorBase> validators,
    bool requireAll,
    String endpointInfo,
  ) {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestId = request.context['request_id'] as String? ?? 'unknown';
        
        try {
          Log.d('[$requestId] Executing JWT validation for: $endpointInfo');
          
          // Obtener JWT del contexto (ya extraído por middleware anterior)
          final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
          
          if (jwtPayload == null) {
            Log.w('[$requestId] JWT payload not found in request context');
            return Response(
              401,
              body: jsonEncode({
                'success': false,
                'error': {
                  'code': 'UNAUTHORIZED',
                  'message': 'JWT token required',
                  'status_code': 401,
                },
                'timestamp': DateTime.now().toIso8601String(),
                'request_id': requestId,
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
          
          // Ejecutar validadores
          final validationResults = <ValidationResult>[];
          final failedReasons = <String>[];
          
          for (final validator in validators) {
            final result = validator.validate(request, jwtPayload);
            validationResults.add(result);
            
            if (result.isSuccess) {
              // Llamar callback de éxito
              validator.onValidationSuccess(request, jwtPayload);
            } else {
              // Llamar callback de falla
              final reason = result.errorMessage ?? validator.defaultErrorMessage;
              failedReasons.add(reason);
              validator.onValidationFailed(request, jwtPayload, reason);
            }
          }
          
          // Evaluar resultados según lógica AND/OR
          bool isAuthorized;
          String errorMessage;
          
          if (requireAll) {
            // Lógica AND: todos los validadores deben pasar
            isAuthorized = validationResults.every((result) => result.isSuccess);
            errorMessage = failedReasons.isNotEmpty 
              ? failedReasons.first 
              : 'Authorization failed - all validators must pass';
          } else {
            // Lógica OR: al menos uno debe pasar
            isAuthorized = validationResults.any((result) => result.isSuccess);
            
            // Solo establecer mensaje de error si NO está autorizado
            if (!isAuthorized) {
              errorMessage = failedReasons.isNotEmpty 
                ? 'All validation methods failed: ${failedReasons.join('; ')}'
                : 'Authorization failed - at least one validator must pass';
            } else {
              // Autorizado - no necesitamos mensaje de error
              errorMessage = '';
            }
          }
          
          if (!isAuthorized) {
            Log.w('[$requestId] JWT validation failed: $errorMessage');
            return _createForbiddenResponse(
              errorMessage, 
              validators.length, 
              requireAll, 
              failedReasons, 
              requestId
            );
          }
          
          Log.i('[$requestId] JWT validation successful');
          
          // Continuar con el handler
          return await innerHandler(request);
          
        } catch (e, stackTrace) {
          Log.e('[$requestId] JWT validation middleware error: $e');
          
          return Response(
            500,
            body: jsonEncode({
              'success': false,
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Authorization system error',
                'status_code': 500,
              },
              'timestamp': DateTime.now().toIso8601String(),
              'request_id': requestId,
            }),
            headers: {
              'Content-Type': 'application/json',
              'X-Request-ID': requestId,
            },
          );
        }
      };
    };
  }
  
  /// Crea respuesta de no autorizado (401)
  static Response _createUnauthorizedResponse(String message, String requestId) {
    return Response(
      401,
      body: jsonEncode({
        'success': false,
        'error': {
          'code': 'UNAUTHORIZED',
          'message': message,
          'status_code': 401,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'request_id': requestId,
      }),
      headers: {
        'Content-Type': 'application/json',
        'X-Request-ID': requestId,
      },
    );
  }
  
  /// Crea respuesta de acceso prohibido (403)
  static Response _createForbiddenResponse(
    String message,
    int validatorsCount,
    bool requireAll,
    List<String> failedReasons,
    String requestId,
  ) {
    return Response(
      403,
      body: jsonEncode({
        'success': false,
        'error': {
          'code': 'FORBIDDEN',
          'message': message,
          'status_code': 403,
          'details': {
            'validation_mode': requireAll ? 'require_all' : 'require_any',
            'validators_count': validatorsCount,
            'failed_validations': failedReasons,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
        'request_id': requestId,
      }),
      headers: {
        'Content-Type': 'application/json',
        'X-Request-ID': requestId,
      },
    );
  }
}

/// Configuración de validadores a nivel de controlador
class JWTControllerConfig {
  final List<JWTValidatorBase> validators;
  final bool requireAll;
  
  JWTControllerConfig(this.validators, this.requireAll);
}

/// Configuración de validadores a nivel de endpoint
class JWTEndpointConfig {
  final List<JWTValidatorBase> validators;
  final bool requireAll;
  
  JWTEndpointConfig(this.validators, this.requireAll);
}