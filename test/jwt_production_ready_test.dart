import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:api_kit/api_kit.dart';

void main() {
  group('JWT Production Ready Tests - All Use Cases Validated', () {
    late ApiServer server;
    late HttpServer httpServer;
    const int testPort = 8084;

    setUpAll(() async {
      server = ApiServer(config: ServerConfig.development());

      server.configureJWTAuth(
        jwtSecret:
            'production-test-secret-key-minimum-32-characters-for-complete-validation',
        excludePaths: ['/api/public', '/health'],
      );

      final result = await server.start(
        host: '0.0.0.0',
        port: testPort,
        controllerList: [
          PublicController(),
          AdminController(),
          FinanceController(),
          SupportController(),
          MixedController(),
        ],
      );

      result.when(
        ok: (srv) => httpServer = srv,
        err: (error) => throw Exception(
          'Failed to start production test server: ${error.msm}',
        ),
      );
    });

    tearDownAll(() async {
      await server.stop(httpServer);
    });

    group('CRÍTICO: Endpoints Públicos (@JWTPublic)', () {
      test('✅ Debe permitir acceso sin JWT a @JWTPublic', () async {
        final response = await _request('GET', '/api/public/info');

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['public'], equals(true));
      });

      test(
        '✅ @JWTPublic debe tener prioridad sobre validación de controller',
        () async {
          // Finance controller tiene validación pero este endpoint es público
          final response = await _request('GET', '/api/finance/public-info');

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['public'], equals(true));
        },
      );

      test(
        '✅ @JWTPublic debe funcionar incluso con JWT inválido en header',
        () async {
          final response = await _request(
            'GET',
            '/api/public/info',
            headers: {'Authorization': 'Bearer invalid-token'},
          );

          expect(response.statusCode, equals(200));
        },
      );
    });

    group('CRÍTICO: Validación Controller (@JWTController)', () {
      test('❌ Debe denegar acceso sin JWT', () async {
        final response = await _request('GET', '/api/admin/users');

        expect(response.statusCode, equals(401));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(false));
        expect(data['error']['code'], equals('UNAUTHORIZED'));
      });

      test('❌ Debe denegar con JWT malformado', () async {
        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer jwt.malformado'},
        );

        expect(response.statusCode, equals(401));
      });

      test('❌ Debe denegar con JWT expirado', () async {
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

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $expiredToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('✅ Debe permitir acceso con JWT admin válido', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['admin_access'], equals(true));
      });

      test('❌ Debe denegar acceso con permisos insuficientes', () async {
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

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $userToken'},
        );

        expect(response.statusCode, equals(403));
        final data = jsonDecode(response.body);
        expect(data['error']['code'], equals('FORBIDDEN'));
      });

      test('❌ Debe denegar cuenta admin inactiva', () async {
        final inactiveAdminToken = _createTestJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': false, // Cuenta inactiva
          'permissions': ['admin_access'],
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $inactiveAdminToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('CRÍTICO: Override Endpoint (@JWTEndpoint)', () {
      test('✅ Debe usar validación específica de endpoint', () async {
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

        final response = await _request(
          'POST',
          '/api/finance/transaction',
          headers: {
            'Authorization': 'Bearer $financeToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'amount': 25000}),
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['financial_access'], equals(true));
      });

      test(
        '❌ Debe fallar validación específica cuando no cumple requisitos',
        () async {
          final lowClearanceToken = _createTestJWT({
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

          final response = await _request(
            'POST',
            '/api/finance/transaction',
            headers: {
              'Authorization': 'Bearer $lowClearanceToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'amount': 25000}),
          );

          expect(response.statusCode, equals(403));
        },
      );

      test('✅ Admin-only endpoint debe funcionar con token admin', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _request(
          'DELETE',
          '/api/support/ticket/123',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['admin_only'], equals(true));
      });

      test('❌ Admin-only endpoint debe fallar con token no-admin', () async {
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

        final response = await _request(
          'DELETE',
          '/api/support/ticket/123',
          headers: {'Authorization': 'Bearer $supportToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('CRÍTICO: Lógica AND (requireAll: true)', () {
      test('✅ Debe requerir TODOS los validadores pasen', () async {
        final adminWithHoursToken = _createTestJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'after_hours_access': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _request(
          'GET',
          '/api/admin/critical',
          headers: {'Authorization': 'Bearer $adminWithHoursToken'},
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('CRÍTICO: Lógica OR (requireAll: false)', () {
      test('✅ Debe pasar si admin requirement se cumple', () async {
        final adminToken = _createValidAdminJWT();

        final response = await _request(
          'GET',
          '/api/support/tickets',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
      });

      test('✅ Debe pasar si department requirement se cumple', () async {
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

        final response = await _request(
          'GET',
          '/api/support/tickets',
          headers: {'Authorization': 'Bearer $supportToken'},
        );

        expect(response.statusCode, equals(200));
      });

      test('❌ Debe fallar si NINGÚN validador pasa', () async {
        final marketingToken = _createTestJWT({
          'user_id': 'user123',
          'role': 'user',
          'department': 'marketing', // No es support ni admin
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _request(
          'GET',
          '/api/support/tickets',
          headers: {'Authorization': 'Bearer $marketingToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('CRÍTICO: Acceso a JWT Payload en Context', () {
      test('✅ Debe proveer payload completo en request context', () async {
        final detailedToken = _createTestJWT({
          'user_id': 'admin456',
          'email': 'admin@test.com',
          'name': 'Test Admin',
          'role': 'admin',
          'active': true,
          'department': 'IT',
          'permissions': ['admin_access'],
          'custom_field': 'valor_personalizado',
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _request(
          'GET',
          '/api/admin/profile',
          headers: {'Authorization': 'Bearer $detailedToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);

        expect(data['jwt_payload']['user_id'], equals('admin456'));
        expect(data['jwt_payload']['email'], equals('admin@test.com'));
        expect(data['jwt_payload']['name'], equals('Test Admin'));
        expect(data['jwt_payload']['department'], equals('IT'));
        expect(
          data['jwt_payload']['custom_field'],
          equals('valor_personalizado'),
        );
        expect(data['context_shortcuts']['user_id'], equals('admin456'));
        expect(
          data['context_shortcuts']['user_email'],
          equals('admin@test.com'),
        );
        expect(data['context_shortcuts']['user_role'], equals('admin'));
      });
    });

    group('CRÍTICO: Token Blacklist', () {
      test('✅ Debe denegar acceso con token blacklisteado', () async {
        final adminToken = _createValidAdminJWT();

        // Primera request debe funcionar
        final response1 = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );
        expect(response1.statusCode, equals(200));

        // Blacklistear el token
        server.blacklistToken(adminToken);

        // Segunda request debe fallar
        final response2 = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );
        expect(response2.statusCode, equals(401));

        final data = jsonDecode(response2.body);
        expect(data['error']['code'], equals('TOKEN_BLACKLISTED'));

        // Limpiar para no afectar otros tests
        server.removeTokenFromBlacklist(adminToken);
      });

      test('✅ Debe permitir acceso después de remover de blacklist', () async {
        final adminToken = _createValidAdminJWT();

        // Blacklistear y remover
        server.blacklistToken(adminToken);
        server.removeTokenFromBlacklist(adminToken);

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );
        expect(response.statusCode, equals(200));
      });

      test('✅ Debe manejar operaciones de blacklist correctamente', () async {
        final initialCount = server.blacklistedTokensCount;

        server.blacklistToken('test-token-1');
        server.blacklistToken('test-token-2');
        expect(server.blacklistedTokensCount, equals(initialCount + 2));

        server.clearTokenBlacklist();
        expect(server.blacklistedTokensCount, equals(0));
      });
    });

    group('CRÍTICO: Casos Edge y Errores', () {
      test('❌ Header Authorization faltante', () async {
        final response = await _request('GET', '/api/admin/users');

        expect(response.statusCode, equals(401));
        final data = jsonDecode(response.body);
        expect(data['error']['code'], equals('UNAUTHORIZED'));
      });

      test('❌ Header Authorization malformado', () async {
        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'NotBearer token123'},
        );

        expect(response.statusCode, equals(401));
      });

      test('❌ Bearer token vacío', () async {
        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer '},
        );

        expect(response.statusCode, equals(401));
      });

      test('❌ JWT con estructura inválida', () async {
        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer estructura.invalida'},
        );

        expect(response.statusCode, equals(401));
      });

      test('❌ JWT con iat en el futuro', () async {
        final futureToken = _createTestJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'iat':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'exp':
              DateTime.now().add(Duration(hours: 2)).millisecondsSinceEpoch ~/
              1000,
        });

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $futureToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('❌ JWT sin claims requeridos', () async {
        final incompleteToken = _createTestJWT({
          'user_id': 'admin123',
          // Faltan role, active, permissions
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $incompleteToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('CRÍTICO: Performance y Escalabilidad', () {
      test('✅ Debe manejar múltiples requests concurrentes', () async {
        final adminToken = _createValidAdminJWT();
        final futures = <Future<TestResponse>>[];

        // 5 requests concurrentes
        for (int i = 0; i < 5; i++) {
          futures.add(
            _request(
              'GET',
              '/api/admin/users',
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
      });

      test('✅ Debe manejar diferentes tokens simultáneamente', () async {
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
          _request(
            'GET',
            '/api/admin/users',
            headers: {'Authorization': 'Bearer $adminToken'},
          ),
          _request(
            'GET',
            '/api/support/tickets',
            headers: {'Authorization': 'Bearer $supportToken'},
          ),
        ]);

        expect(responses[0].statusCode, equals(200));
        expect(responses[1].statusCode, equals(200));
      });
    });

    group('CRÍTICO: Configuración JWT', () {
      test('✅ Debe manejar cambios de configuración JWT', () async {
        // Deshabilitar JWT
        server.disableJWTAuth();

        // Re-habilitar con nueva configuración
        server.configureJWTAuth(
          jwtSecret:
              'nueva-clave-secreta-para-pruebas-de-configuracion-minimo-32-caracteres',
          excludePaths: ['/api/test', '/api/public'],
        );

        // Debe funcionar con nueva configuración
        final adminToken = _createValidAdminJWT();
        final response = await _request(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));

        // Verificar que blacklist se mantiene funcional
        expect(server.blacklistedTokensCount, isA<int>());
      });
    });
  });
}

// Helper classes y funciones

class TestResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  TestResponse(this.statusCode, this.body, this.headers);
}

Future<TestResponse> _request(
  String method,
  String path, {
  Map<String, String>? headers,
  String? body,
}) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('http://localhost:8084$path');
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

    return TestResponse(response.statusCode, responseBody, responseHeaders);
  } finally {
    client.close();
  }
}

String _createTestJWT(Map<String, dynamic> payload) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = 'production-test-signature';

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

// Controladores de Test - COHERENTES con sistema implementado

@Controller('/api/public')
class PublicController extends BaseController {
  @GET('/info')
  @JWTPublic()
  Future<Response> getInfo(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'public': true,
        'message': 'Public endpoint access',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

@Controller('/api/admin')
@JWTController([
  MyAdminValidator(),
  MyBusinessHoursValidator(startHour: 0, endHour: 23), // 24/7 para tests
], requireAll: true)
class AdminController extends BaseController {
  @GET('/users')
  Future<Response> getUsers(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'admin_access': true,
        'data': ['user1', 'user2', 'user3'],
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  @GET('/critical')
  Future<Response> getCriticalData(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'critical_access': true,
        'data': 'classified information',
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
class FinanceController extends BaseController {
  @POST('/transaction')
  @JWTEndpoint([MyFinancialValidator(minimumAmount: 10000)])
  Future<Response> createTransaction(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    return jsonResponse(
      jsonEncode({
        'success': true,
        'financial_access': true,
        'transaction': {
          'amount': data['amount'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      }),
    );
  }

  @GET('/public-info')
  @JWTPublic()
  Future<Response> getPublicInfo(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'public': true,
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
class SupportController extends BaseController {
  @GET('/tickets')
  Future<Response> getTickets(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': ['ticket1', 'ticket2'],
        'access_type': 'admin_or_support',
      }),
    );
  }

  @DELETE('/ticket/<id>')
  @JWTEndpoint([MyAdminValidator()])
  Future<Response> deleteTicket(Request request) async {
    final ticketId = getRequiredParam(request, 'id');

    return jsonResponse(
      jsonEncode({
        'success': true,
        'admin_only': true,
        'message': 'Ticket $ticketId deleted by admin',
      }),
    );
  }
}

@Controller('/api/mixed')
class MixedController extends BaseController {
  @GET('/test')
  @JWTEndpoint([
    MyDepartmentValidator(allowedDepartments: ['any']),
  ])
  Future<Response> testEndpoint(Request request) async {
    return jsonResponse(
      jsonEncode({'success': true, 'mixed_validation': true}),
    );
  }
}
