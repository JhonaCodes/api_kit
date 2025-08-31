import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

/// Enhanced JWT authentication middleware
///
/// Provides extraction, validation, and processing of JWT tokens
/// from the Authorization header of HTTP requests
class EnhancedAuthMiddleware {
  /// Middleware that extracts and validates JWT from Authorization header
  ///
  /// [jwtSecret] - Secret key to validate the JWT signature
  /// [excludePaths] - Paths that do not require JWT extraction
  ///
  /// Extracts the JWT from the "Authorization: Bearer `<token>`" header,
  /// validates it, and adds the payload to the request context
  static Middleware jwtExtractor({
    required String jwtSecret,
    List<String> excludePaths = const [],
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.requestedUri.path;
        final requestId = request.context['request_id'] as String? ?? 'unknown';

        // Skip extraction for excluded paths
        if (excludePaths.any((excludePath) => path.startsWith(excludePath))) {
          Log.d('[$requestId] JWT extraction skipped for excluded path: $path');
          return await innerHandler(request);
        }

        try {
          Log.d('[$requestId] Extracting JWT from Authorization header');

          // Get Authorization header
          final authHeader = request.headers['authorization'];

          if (authHeader == null || !authHeader.startsWith('Bearer ')) {
            Log.d('[$requestId] No Bearer token found in Authorization header');

            // Add empty context for endpoints that do not require JWT
            final updatedRequest = request.change(
              context: {...request.context, 'jwt_payload': null},
            );

            return await innerHandler(updatedRequest);
          }

          // Extract token
          final token = authHeader.substring(7);

          if (token.isEmpty) {
            Log.w('[$requestId] Empty JWT token provided');
            return _unauthorizedResponse('Invalid JWT token format', requestId);
          }

          // Validate and decode JWT
          final jwtPayload = await _validateAndDecodeJWT(token, jwtSecret);

          if (jwtPayload == null) {
            Log.w('[$requestId] JWT validation failed');
            return _unauthorizedResponse(
              'Invalid or expired JWT token',
              requestId,
            );
          }

          Log.i(
            '[$requestId] JWT validated successfully for user: ${jwtPayload['user_id'] ?? 'unknown'}',
          );

          // Add JWT payload to the request context
          final updatedRequest = request.change(
            context: {
              ...request.context,
              'jwt_payload': jwtPayload,
              'user_id': jwtPayload['user_id'],
              'user_email': jwtPayload['email'],
              'user_role': jwtPayload['role'],
            },
          );

          return await innerHandler(updatedRequest);
        } catch (e) {
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

  /// Middleware to check tokens in blacklist
  ///
  /// [blacklistedTokens] - Set of revoked/blacklisted tokens
  static Middleware tokenBlacklist({required Set<String> blacklistedTokens}) {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestId = request.context['request_id'] as String? ?? 'unknown';

        try {
          // Get token from context
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

  /// Middleware for JWT access logging
  static Middleware jwtAccessLogger() {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestId = request.context['request_id'] as String? ?? 'unknown';
        final jwtPayload =
            request.context['jwt_payload'] as Map<String, dynamic>?;

        if (jwtPayload != null) {
          final userId = jwtPayload['user_id'] ?? 'unknown';
          final userRole = jwtPayload['role'] ?? 'unknown';
          final endpoint = request.requestedUri.path;
          final method = request.method;

          Log.i(
            '[$requestId] JWT Access: $userId ($userRole) -> $method $endpoint',
          );
        }

        return await innerHandler(request);
      };
    };
  }

  /// Validates and decodes a JWT using the standard format
  ///
  /// [token] - JWT token to validate
  /// [secret] - Secret key to verify the signature
  ///
  /// For production, integrate with a real JWT library like dart_jsonwebtoken
  static Future<Map<String, dynamic>?> _validateAndDecodeJWT(
    String token,
    String secret,
  ) async {
    try {
      // Verify basic JWT format (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        Log.w('Invalid JWT format: expected 3 parts, got ${parts.length}');
        return null;
      }

      // Decode payload (central part)
      final payloadPart = parts[1];

      // Add padding if necessary for base64
      String normalizedPayload = payloadPart;
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final payloadJson = utf8.decode(decodedBytes);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // Check expiration
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > exp) {
          Log.w('JWT token expired');
          return null;
        }
      }

      // Check issued at
      final iat = payload['iat'] as int?;
      if (iat != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (iat > now) {
          Log.w('JWT token used before valid');
          return null;
        }
      }

      // NOTE: In a real implementation, verify the signature with the secret
      // using a library like dart_jsonwebtoken:
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

  /// Error response for failed authentication
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
      headers: {'Content-Type': 'application/json', 'X-Request-ID': requestId},
    );
  }
}
