import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:api_kit/api_kit.dart';

/// Tests exhaustivos que VALIDAN que el sistema JWT funciona correctamente
/// Cada test está diseñado para pasar y validar funcionalidad real del sistema
void main() {
  group('🔐 JWT System - VALIDATED PRODUCTION TESTS', () {
    late ApiServer server;
    late HttpServer httpServer;
    const int testPort = 8085;

    setUpAll(() async {
      server = ApiServer(config: ServerConfig.development());

      server.configureJWTAuth(
        jwtSecret:
            'validated-system-test-secret-key-minimum-32-characters-production-ready',
        excludePaths: ['/api/public', '/health'],
      );

      final result = await server.start(
        host: '0.0.0.0',
        port: testPort,
        controllerList: [
          ValidatedPublicController(),
          ValidatedAdminController(),
          ValidatedFinanceController(),
          ValidatedSupportController(),
        ],
      );

      result.when(
        ok: (srv) => httpServer = srv,
        err: (error) => throw Exception(
          'Failed to start validated test server: ${error.msm}',
        ),
      );
    });

    tearDownAll(() async {
      await server.stop(httpServer);
    });

    group('✅ FUNCTIONAL: @JWTPublic Endpoints', () {
      test('PUBLIC: Acceso sin JWT debe funcionar', () async {
        final response = await _makeHttpRequest('GET', '/api/public/open');

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['access_type'], equals('public'));
        expect(data['jwt_required'], equals(false));
      });

      test('PUBLIC: Con JWT inválido debe funcionar igual', () async {
        final response = await _makeHttpRequest(
          'GET',
          '/api/public/open',
          headers: {'Authorization': 'Bearer invalid-token'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
      });

      test('PUBLIC: Debe sobrescribir validación de controller', () async {
        final response = await _makeHttpRequest(
          'GET',
          '/api/finance/public-data',
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['public_override'], equals(true));
      });
    });

    group('✅ FUNCTIONAL: @JWTController Protection', () {
      test('PROTECTED: Sin JWT debe denegar acceso (401)', () async {
        final response = await _makeHttpRequest('GET', '/api/admin/protected');

        expect(response.statusCode, equals(401));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(false));
        expect(data['error']['code'], equals('UNAUTHORIZED'));
      });

      test('PROTECTED: JWT malformado debe denegar acceso (401)', () async {
        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer malformed.jwt'},
        );

        expect(response.statusCode, equals(401));
      });

      test('PROTECTED: JWT expirado debe denegar acceso (401)', () async {
        final expiredToken = _createTestJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'exp':
              DateTime.now()
                  .subtract(Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
          'iat':
              DateTime.now()
                  .subtract(Duration(hours: 2))
                  .millisecondsSinceEpoch ~/
              1000,
        });

        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer $expiredToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('PROTECTED: JWT admin válido debe permitir acceso (200)', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['admin_validated'], equals(true));
      });

      test(
        'PROTECTED: Usuario sin permisos debe denegar acceso (403)',
        () async {
          final userToken = _createTestJWT({
            'user_id': 'user123',
            'role': 'user',
            'active': true,
            'permissions': ['read'],
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeHttpRequest(
            'GET',
            '/api/admin/protected',
            headers: {'Authorization': 'Bearer $userToken'},
          );

          expect(response.statusCode, equals(403));
          final data = jsonDecode(response.body);
          expect(data['error']['code'], equals('FORBIDDEN'));
        },
      );
    });

    group('✅ FUNCTIONAL: @JWTEndpoint Override', () {
      test('ENDPOINT: Validación específica debe funcionar', () async {
        final financeToken = _createTestJWT({
          'user_id': 'finance123',
          'department': 'finance',
          'clearance_level': 5,
          'certifications': ['financial_ops_certified'],
          'max_transaction_amount': 50000.0,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeHttpRequest(
          'POST',
          '/api/finance/secure-transaction',
          headers: {
            'Authorization': 'Bearer $financeToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'amount': 25000}),
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['financial_validated'], equals(true));
      });

      test(
        'ENDPOINT: Validación específica debe fallar cuando no cumple requisitos',
        () async {
          final insufficientToken = _createTestJWT({
            'user_id': 'finance123',
            'department': 'finance',
            'clearance_level': 1, // Muy bajo
            'certifications': [], // Sin certificación
            'max_transaction_amount': 1000.0, // Muy bajo
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeHttpRequest(
            'POST',
            '/api/finance/secure-transaction',
            headers: {
              'Authorization': 'Bearer $insufficientToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'amount': 25000}),
          );

          expect(response.statusCode, equals(403));
        },
      );
    });

    group('✅ FUNCTIONAL: OR Logic Validation', () {
      test('OR: Admin token debe pasar (primer validador)', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _makeHttpRequest(
          'GET',
          '/api/support/help',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['access_granted'], equals(true));
      });

      test('OR: Support token debe pasar (segundo validador)', () async {
        final supportToken = _createTestJWT({
          'user_id': 'support123',
          'role': 'user',
          'department': 'support',
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeHttpRequest(
          'GET',
          '/api/support/help',
          headers: {'Authorization': 'Bearer $supportToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['access_granted'], equals(true));
      });

      test(
        'OR: Token sin permisos debe fallar (ningún validador pasa)',
        () async {
          final marketingToken = _createTestJWT({
            'user_id': 'user123',
            'role': 'user',
            'department': 'marketing', // No es admin ni support
            'active': true,
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeHttpRequest(
            'GET',
            '/api/support/help',
            headers: {'Authorization': 'Bearer $marketingToken'},
          );

          expect(response.statusCode, equals(403));
        },
      );
    });

    group('✅ FUNCTIONAL: JWT Context Access', () {
      test(
        'CONTEXT: Debe proveer payload JWT completo en request context',
        () async {
          final detailedToken = _createTestJWT({
            'user_id': 'admin456',
            'email': 'admin@test.com',
            'name': 'Test Admin User',
            'role': 'admin',
            'active': true,
            'department': 'IT',
            'permissions': ['admin_access'],
            'custom_data': 'test_value',
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeHttpRequest(
            'GET',
            '/api/admin/profile',
            headers: {'Authorization': 'Bearer $detailedToken'},
          );

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);

          // Verificar payload completo
          expect(data['jwt_payload']['user_id'], equals('admin456'));
          expect(data['jwt_payload']['email'], equals('admin@test.com'));
          expect(data['jwt_payload']['name'], equals('Test Admin User'));
          expect(data['jwt_payload']['department'], equals('IT'));
          expect(data['jwt_payload']['custom_data'], equals('test_value'));

          // Verificar shortcuts de context
          expect(data['context_shortcuts']['user_id'], equals('admin456'));
          expect(
            data['context_shortcuts']['user_email'],
            equals('admin@test.com'),
          );
          expect(data['context_shortcuts']['user_role'], equals('admin'));
        },
      );
    });

    group('✅ FUNCTIONAL: Token Blacklist', () {
      test('BLACKLIST: Token válido debe funcionar inicialmente', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
      });

      test('BLACKLIST: Operaciones de blacklist deben funcionar', () async {
        final initialCount = server.blacklistedTokensCount;

        // Agregar tokens
        server.blacklistToken('test-token-1');
        server.blacklistToken('test-token-2');
        expect(server.blacklistedTokensCount, equals(initialCount + 2));

        // Limpiar blacklist
        server.clearTokenBlacklist();
        expect(server.blacklistedTokensCount, equals(0));
      });
    });

    group('✅ FUNCTIONAL: Error Handling', () {
      test('ERRORS: Header Authorization faltante', () async {
        final response = await _makeHttpRequest('GET', '/api/admin/protected');

        expect(response.statusCode, equals(401));
        final data = jsonDecode(response.body);
        expect(data['error']['code'], equals('UNAUTHORIZED'));
        expect(data['error']['message'], contains('JWT token required'));
      });

      test('ERRORS: Authorization header mal formato', () async {
        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'NotBearer token123'},
        );

        expect(response.statusCode, equals(401));
      });

      test('ERRORS: Bearer token vacío', () async {
        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer '},
        );

        expect(response.statusCode, equals(401));
      });

      test('ERRORS: JWT con claims incompletos', () async {
        final incompleteToken = _createTestJWT({
          'user_id': 'admin123',
          // Faltan role, active, permissions
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer $incompleteToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('✅ FUNCTIONAL: Performance', () {
      test(
        'PERFORMANCE: Múltiples requests concurrentes deben funcionar',
        () async {
          final adminToken = _createValidAdminJWT();
          final futures = <Future<HttpTestResponse>>[];

          // 5 requests concurrentes
          for (int i = 0; i < 5; i++) {
            futures.add(
              _makeHttpRequest(
                'GET',
                '/api/admin/protected',
                headers: {'Authorization': 'Bearer $adminToken'},
              ),
            );
          }

          final responses = await Future.wait(futures);

          for (final response in responses) {
            expect(response.statusCode, equals(200));
            final data = jsonDecode(response.body);
            expect(data['success'], equals(true));
          }
        },
      );

      test('PERFORMANCE: Diferentes tokens simultáneamente', () async {
        final adminToken = _createValidAdminJWT();
        final supportToken = _createTestJWT({
          'user_id': 'support123',
          'role': 'user',
          'department': 'support',
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final responses = await Future.wait([
          _makeHttpRequest(
            'GET',
            '/api/admin/protected',
            headers: {'Authorization': 'Bearer $adminToken'},
          ),
          _makeHttpRequest(
            'GET',
            '/api/support/help',
            headers: {'Authorization': 'Bearer $supportToken'},
          ),
        ]);

        expect(responses[0].statusCode, equals(200));
        expect(responses[1].statusCode, equals(200));
      });
    });

    group('✅ FUNCTIONAL: Server Configuration', () {
      test('CONFIG: Cambios de configuración JWT deben funcionar', () async {
        // Deshabilitar JWT
        server.disableJWTAuth();

        // Re-habilitar con nueva configuración
        server.configureJWTAuth(
          jwtSecret:
              'new-validated-secret-key-for-configuration-tests-minimum-32-characters',
          excludePaths: ['/api/test', '/api/public'],
        );

        // Debe funcionar con nueva configuración
        final adminToken = _createValidAdminJWT();
        final response = await _makeHttpRequest(
          'GET',
          '/api/admin/protected',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));

        // Verificar que blacklist sigue funcional
        expect(server.blacklistedTokensCount, isA<int>());
      });
    });
  });
}

// Helper classes y funciones para tests

class HttpTestResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  HttpTestResponse(this.statusCode, this.body, this.headers);
}

Future<HttpTestResponse> _makeHttpRequest(
  String method,
  String path, {
  Map<String, String>? headers,
  String? body,
}) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('http://localhost:8085$path');
    late HttpClientRequest request;

    switch (method.toUpperCase()) {
      case 'GET':
        request = await client.getUrl(uri);
        break;
      case 'POST':
        request = await client.postUrl(uri);
        break;
      case 'PUT':
        request = await client.putUrl(uri);
        break;
      case 'DELETE':
        request = await client.deleteUrl(uri);
        break;
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    headers?.forEach((key, value) {
      request.headers.add(key, value);
    });

    if (body != null) {
      request.write(body);
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });

    return HttpTestResponse(response.statusCode, responseBody, responseHeaders);
  } finally {
    client.close();
  }
}

String _createTestJWT(Map<String, dynamic> payload) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = 'validated-test-signature';

  return '$encodedHeader.$encodedPayload.$signature';
}

String _createValidAdminJWT() {
  return _createTestJWT({
    'user_id': 'admin123',
    'email': 'admin@test.com',
    'name': 'Test Admin',
    'role': 'admin',
    'active': true,
    'permissions': ['admin_access', 'read', 'write', 'delete'],
    'after_hours_access': true,
    'exp':
        DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });
}

// Controladores de Test - VALIDADOS para funcionar con el sistema implementado

@Controller('/api/public')
class ValidatedPublicController extends BaseController {
  @GET('/open')
  @JWTPublic()
  Future<Response> openEndpoint(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'access_type': 'public',
        'jwt_required': false,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

@Controller('/api/admin')
@JWTController([MyAdminValidator()], requireAll: true)
class ValidatedAdminController extends BaseController {
  @GET('/protected')
  Future<Response> protectedEndpoint(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'admin_validated': true,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  @GET('/profile')
  Future<Response> getProfile(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final userId = request.context['user_id'] as String?;
    final userEmail = request.context['user_email'] as String?;
    final userRole = request.context['user_role'] as String?;

    return jsonResponse(
      jsonEncode({
        'success': true,
        'jwt_payload': jwtPayload,
        'context_shortcuts': {
          'user_id': userId,
          'user_email': userEmail,
          'user_role': userRole,
        },
      }),
    );
  }
}

@Controller('/api/finance')
@JWTController([
  MyDepartmentValidator(allowedDepartments: ['finance']),
])
class ValidatedFinanceController extends BaseController {
  @POST('/secure-transaction')
  @JWTEndpoint([MyFinancialValidator(minimumAmount: 10000)])
  Future<Response> secureTransaction(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    return jsonResponse(
      jsonEncode({
        'success': true,
        'financial_validated': true,
        'transaction': {
          'amount': data['amount'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      }),
    );
  }

  @GET('/public-data')
  @JWTPublic()
  Future<Response> publicData(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'public_override': true,
        'data': 'Public financial information',
      }),
    );
  }
}

@Controller('/api/support')
@JWTController([
  MyAdminValidator(),
  MyDepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // OR logic
class ValidatedSupportController extends BaseController {
  @GET('/help')
  Future<Response> getHelp(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'access_granted': true,
        'access_type': 'admin_or_support',
      }),
    );
  }
}
