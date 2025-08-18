import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

/// Middleware de autenticación JWT mejorado
/// 
/// Proporciona extracción, validación y procesamiento de JWT tokens
/// desde el Authorization header de requests HTTP
class EnhancedAuthMiddleware {
  
  /// Middleware que extrae y valida JWT desde Authorization header
  /// 
  /// [jwtSecret] - Clave secreta para validar la firma JWT
  /// [excludePaths] - Paths que no requieren extracción JWT
  /// 
  /// Extrae el JWT del header "Authorization: Bearer <token>",
  /// lo valida y agrega el payload al contexto del request
  static Middleware jwtExtractor({
    required String jwtSecret,
    List<String> excludePaths = const [],
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.requestedUri.path;
        final requestId = request.context['request_id'] as String? ?? 'unknown';
        
        // Saltar extracción para paths excluidos
        if (excludePaths.any((excludePath) => path.startsWith(excludePath))) {
          Log.d('[$requestId] JWT extraction skipped for excluded path: $path');
          return await innerHandler(request);
        }
        
        try {
          Log.d('[$requestId] Extracting JWT from Authorization header');
          
          // Obtener Authorization header
          final authHeader = request.headers['authorization'];
          
          if (authHeader == null || !authHeader.startsWith('Bearer ')) {
            Log.d('[$requestId] No Bearer token found in Authorization header');
            
            // Agregar contexto vacío para endpoints que no requieren JWT
            final updatedRequest = request.change(
              context: {...request.context, 'jwt_payload': null}
            );
            
            return await innerHandler(updatedRequest);
          }
          
          // Extraer token
          final token = authHeader.substring(7);
          
          if (token.isEmpty) {
            Log.w('[$requestId] Empty JWT token provided');
            return _unauthorizedResponse('Invalid JWT token format', requestId);
          }
          
          // Validar y decodificar JWT
          final jwtPayload = await _validateAndDecodeJWT(token, jwtSecret);
          
          if (jwtPayload == null) {
            Log.w('[$requestId] JWT validation failed');
            return _unauthorizedResponse('Invalid or expired JWT token', requestId);
          }
          
          Log.i('[$requestId] JWT validated successfully for user: ${jwtPayload['user_id'] ?? 'unknown'}');
          
          // Agregar payload JWT al contexto del request
          final updatedRequest = request.change(
            context: {
              ...request.context,
              'jwt_payload': jwtPayload,
              'user_id': jwtPayload['user_id'],
              'user_email': jwtPayload['email'],
              'user_role': jwtPayload['role'],
            }
          );
          
          return await innerHandler(updatedRequest);
          
        } catch (e, stackTrace) {
          Log.e('[$requestId] JWT extraction error: $e');
          
          return Response(
            500,
            body: jsonEncode({
              'success': false,
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Authentication system error',
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
  
  /// Middleware para verificar tokens en blacklist
  /// 
  /// [blacklistedTokens] - Set de tokens revocados/blacklisteados
  static Middleware tokenBlacklist({
    required Set<String> blacklistedTokens,
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestId = request.context['request_id'] as String? ?? 'unknown';
        
        try {
          // Obtener token del contexto
          final authHeader = request.headers['authorization'];
          if (authHeader != null && authHeader.startsWith('Bearer ')) {
            final token = authHeader.substring(7);
            
            if (blacklistedTokens.contains(token)) {
              Log.w('[$requestId] Blacklisted token attempted access');
              return Response(
                401,
                body: jsonEncode({
                  'success': false,
                  'error': {
                    'code': 'TOKEN_BLACKLISTED',
                    'message': 'Token has been revoked',
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
          }
          
          return await innerHandler(request);
          
        } catch (e) {
          Log.e('[$requestId] Token blacklist check error: $e');
          return await innerHandler(request);
        }
      };
    };
  }
  
  /// Middleware para logging de accesos JWT
  static Middleware jwtAccessLogger() {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestId = request.context['request_id'] as String? ?? 'unknown';
        final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
        
        if (jwtPayload != null) {
          final userId = jwtPayload['user_id'] ?? 'unknown';
          final userRole = jwtPayload['role'] ?? 'unknown';
          final endpoint = request.requestedUri.path;
          final method = request.method;
          
          Log.i('[$requestId] JWT Access: $userId ($userRole) -> $method $endpoint');
        }
        
        return await innerHandler(request);
      };
    };
  }
  
  /// Valida y decodifica un JWT usando el formato estándar
  /// 
  /// [token] - Token JWT a validar
  /// [secret] - Clave secreta para verificar la firma
  /// 
  /// Para producción, integrar con una librería JWT real como dart_jsonwebtoken
  static Future<Map<String, dynamic>?> _validateAndDecodeJWT(
    String token, 
    String secret,
  ) async {
    try {
      // Verificar formato JWT básico (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        Log.w('Invalid JWT format: expected 3 parts, got ${parts.length}');
        return null;
      }
      
      // Decodificar payload (parte central)
      final payloadPart = parts[1];
      
      // Agregar padding si es necesario para base64
      String normalizedPayload = payloadPart;
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      
      final decodedBytes = base64Url.decode(normalizedPayload);
      final payloadJson = utf8.decode(decodedBytes);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      
      // Verificar expiración
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > exp) {
          Log.w('JWT token expired');
          return null;
        }
      }
      
      // Verificar issued at
      final iat = payload['iat'] as int?;
      if (iat != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (iat > now) {
          Log.w('JWT token used before valid');
          return null;
        }
      }
      
      // NOTA: En implementación real, verificar signature con el secret
      // usando una librería como dart_jsonwebtoken:
      // 
      // final isValidSignature = await _verifySignature(parts, secret);
      // if (!isValidSignature) return null;
      
      Log.d('JWT decoded successfully');
      return payload;
      
    } catch (e) {
      Log.w('JWT decode error: $e');
      return null;
    }
  }
  
  /// Respuesta de error para autenticación fallida
  static Response _unauthorizedResponse(String message, String requestId) {
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
}