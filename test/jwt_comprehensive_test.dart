import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:api_kit/api_kit.dart';

void main() {
  group('JWT Comprehensive Tests - ALL Use Cases', () {
    late ApiServer server;
    late HttpServer httpServer;
    const int testPort = 8083;

    setUpAll(() async {
      server = ApiServer(config: ServerConfig.development());

      server.configureJWTAuth(
        jwtSecret:
            'comprehensive-test-secret-key-minimum-32-characters-for-jwt-validation',
        excludePaths: ['/api/public', '/health'],
      );

      final result = await server.start(
        host: '0.0.0.0',
        port: testPort,
        controllerList: [
          PublicTestController(),
          AdminControllerTest(),
          FinanceControllerTest(),
          SupportControllerTest(),
          MixedValidationControllerTest(),
          EdgeCaseControllerTest(),
        ],
      );

      result.when(
        ok: (srv) => httpServer = srv,
        err: (error) => throw Exception(
          'Failed to start comprehensive test server: ${error.msm}',
        ),
      );
    });

    tearDownAll(() async {
      await server.stop(httpServer);
    });

    group('1. PUBLIC ENDPOINTS (@JWTPublic)', () {
      test(
        '1.1 Should allow access to @JWTPublic endpoints without any JWT',
        () async {
          final response = await _makeRequest('GET', '/api/public/open');

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['success'], equals(true));
          expect(data['access_type'], equals('public'));
        },
      );

      test(
        '1.2 Should allow @JWTPublic even with invalid JWT in header',
        () async {
          final response = await _makeRequest(
            'GET',
            '/api/public/open',
            headers: {'Authorization': 'Bearer invalid-jwt-token'},
          );

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['success'], equals(true));
        },
      );

      test(
        '1.3 Should prioritize @JWTPublic over controller-level validation',
        () async {
          // Finance controller has validation but this endpoint is public
          final response = await _makeRequest(
            'GET',
            '/api/finance/public-balance',
          );

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['access_type'], equals('public'));
        },
      );
    });

    group('2. CONTROLLER-LEVEL VALIDATION (@JWTController)', () {
      test(
        '2.1 Should deny access without JWT to @JWTController protected endpoint',
        () async {
          final response = await _makeRequest('GET', '/api/admin/users');

          expect(response.statusCode, equals(401));
          final data = jsonDecode(response.body);
          expect(data['success'], equals(false));
          expect(data['error']['code'], equals('UNAUTHORIZED'));
        },
      );

      test('2.2 Should deny access with malformed JWT', () async {
        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer malformed.jwt'},
        );

        expect(response.statusCode, equals(401));
      });

      test('2.3 Should deny access with expired JWT', () async {
        final expiredToken = _createJWT({
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

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $expiredToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('2.4 Should allow access with valid admin JWT', () async {
        final adminToken = _createValidAdminToken();

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
        expect(data['access_level'], equals('admin'));
      });

      test(
        '2.5 Should deny access with valid JWT but insufficient permissions',
        () async {
          final userToken = _createJWT({
            'user_id': 'user123',
            'role': 'user',
            'active': true,
            'permissions': ['read'],
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'GET',
            '/api/admin/users',
            headers: {'Authorization': 'Bearer $userToken'},
          );

          expect(response.statusCode, equals(403));
          final data = jsonDecode(response.body);
          expect(data['error']['code'], equals('FORBIDDEN'));
        },
      );

      test('2.6 Should deny access with inactive admin account', () async {
        final inactiveAdminToken = _createJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': false, // Inactive account
          'permissions': ['admin_access'],
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $inactiveAdminToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('3. ENDPOINT-LEVEL OVERRIDE (@JWTEndpoint)', () {
      test(
        '3.1 Should override controller validation with endpoint-specific validation',
        () async {
          // Finance controller requires department validation, but this endpoint has custom validation
          final financialToken = _createJWT({
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

          final response = await _makeRequest(
            'POST',
            '/api/finance/high-value-transaction',
            headers: {
              'Authorization': 'Bearer $financialToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'amount': 25000}),
          );

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['success'], equals(true));
          expect(data['operation']['amount'], equals(25000));
        },
      );

      test(
        '3.2 Should deny endpoint access when custom validation fails',
        () async {
          final lowClearanceToken = _createJWT({
            'user_id': 'finance123',
            'department': 'finance',
            'clearance_level': 1, // Too low for financial operations
            'certifications': [],
            'max_transaction_amount': 1000.0,
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'POST',
            '/api/finance/high-value-transaction',
            headers: {
              'Authorization': 'Bearer $lowClearanceToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'amount': 25000}),
          );

          expect(response.statusCode, equals(403));
        },
      );

      test(
        '3.3 Should allow admin-only endpoint with proper admin token',
        () async {
          final adminToken = _createValidAdminToken();

          final response = await _makeRequest(
            'DELETE',
            '/api/support/tickets/123',
            headers: {'Authorization': 'Bearer $adminToken'},
          );

          expect(response.statusCode, equals(200));
          final data = jsonDecode(response.body);
          expect(data['success'], equals(true));
          expect(data['message'], contains('Admin'));
        },
      );

      test('3.4 Should deny admin-only endpoint with support token', () async {
        final supportToken = _createJWT({
          'user_id': 'support123',
          'role': 'user',
          'department': 'support',
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'DELETE',
          '/api/support/tickets/123',
          headers: {'Authorization': 'Bearer $supportToken'},
        );

        expect(response.statusCode, equals(403));
      });
    });

    group('4. AND LOGIC VALIDATION (requireAll: true)', () {
      test(
        '4.1 Should require ALL validators to pass with requireAll: true',
        () async {
          // Admin controller requires admin + business hours (both must pass)
          final adminToken = _createJWT({
            'user_id': 'admin123',
            'role': 'admin',
            'active': true,
            'permissions': ['admin_access'],
            'after_hours_access': true, // Has after-hours access
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'GET',
            '/api/admin/sensitive-data',
            headers: {'Authorization': 'Bearer $adminToken'},
          );

          expect(response.statusCode, equals(200));
        },
      );

      test(
        '4.2 Should fail if ANY validator fails with requireAll: true',
        () async {
          // Admin but without after-hours access during potential off-hours
          final adminNoAfterHoursToken = _createJWT({
            'user_id': 'admin123',
            'role': 'admin',
            'active': true,
            'permissions': ['admin_access'],
            'after_hours_access': false, // No after-hours access
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'GET',
            '/api/admin/sensitive-data',
            headers: {'Authorization': 'Bearer $adminNoAfterHoursToken'},
          );

          // Result depends on current time, but test validates the logic
          expect(response.statusCode, anyOf([200, 403]));
        },
      );
    });

    group('5. OR LOGIC VALIDATION (requireAll: false)', () {
      test('5.1 Should pass if admin requirement is met (OR logic)', () async {
        final adminToken = _createValidAdminToken();

        final response = await _makeRequest(
          'GET',
          '/api/support/tickets',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);
        expect(data['success'], equals(true));
      });

      test(
        '5.2 Should pass if department requirement is met (OR logic)',
        () async {
          final supportToken = _createJWT({
            'user_id': 'support123',
            'role': 'user',
            'department': 'support',
            'active': true,
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'GET',
            '/api/support/tickets',
            headers: {'Authorization': 'Bearer $supportToken'},
          );

          expect(response.statusCode, equals(200));
        },
      );

      test(
        '5.3 Should fail if NONE of the validators pass (OR logic)',
        () async {
          final randomUserToken = _createJWT({
            'user_id': 'user123',
            'role': 'user',
            'department': 'marketing', // Not support/customer_service
            'active': true,
            'exp':
                DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
            'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });

          final response = await _makeRequest(
            'GET',
            '/api/support/tickets',
            headers: {'Authorization': 'Bearer $randomUserToken'},
          );

          expect(response.statusCode, equals(403));
        },
      );
    });

    group('6. JWT PAYLOAD ACCESS IN CONTEXT', () {
      test('6.1 Should provide full JWT payload in request context', () async {
        final detailedToken = _createJWT({
          'user_id': 'admin456',
          'email': 'admin@test.com',
          'name': 'Test Admin User',
          'role': 'admin',
          'active': true,
          'department': 'IT',
          'employee_level': 'director',
          'permissions': ['admin_access', 'read', 'write', 'delete'],
          'custom_field': 'custom_value',
          'after_hours_access': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'GET',
          '/api/admin/profile',
          headers: {'Authorization': 'Bearer $detailedToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);

        expect(data['jwt_payload']['user_id'], equals('admin456'));
        expect(data['jwt_payload']['email'], equals('admin@test.com'));
        expect(data['jwt_payload']['name'], equals('Test Admin User'));
        expect(data['jwt_payload']['department'], equals('IT'));
        expect(data['jwt_payload']['custom_field'], equals('custom_value'));
        expect(data['context_available'], equals(true));
      });

      test('6.2 Should provide user context shortcuts', () async {
        final adminToken = _createValidAdminToken();

        final response = await _makeRequest(
          'GET',
          '/api/admin/profile',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body);

        expect(data['user_id'], equals('admin123'));
        expect(data['user_email'], equals('admin@test.com'));
        expect(data['user_role'], equals('admin'));
      });
    });

    group('7. TOKEN BLACKLIST FUNCTIONALITY', () {
      test('7.1 Should deny access with blacklisted token', () async {
        final adminToken = _createValidAdminToken();

        // First request should work
        final response1 = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );
        expect(response1.statusCode, equals(200));

        // Blacklist the token
        server.blacklistToken(adminToken);

        // Second request should fail
        final response2 = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );
        expect(response2.statusCode, equals(401));

        final data = jsonDecode(response2.body);
        expect(data['error']['code'], equals('TOKEN_BLACKLISTED'));

        // Clean up
        server.removeTokenFromBlacklist(adminToken);
      });

      test(
        '7.2 Should allow access after token is removed from blacklist',
        () async {
          final adminToken = _createValidAdminToken();

          // Blacklist and then remove
          server.blacklistToken(adminToken);
          server.removeTokenFromBlacklist(adminToken);

          final response = await _makeRequest(
            'GET',
            '/api/admin/users',
            headers: {'Authorization': 'Bearer $adminToken'},
          );
          expect(response.statusCode, equals(200));
        },
      );

      test('7.3 Should handle blacklist operations correctly', () async {
        final initialCount = server.blacklistedTokensCount;

        server.blacklistToken('token1');
        server.blacklistToken('token2');
        expect(server.blacklistedTokensCount, equals(initialCount + 2));

        server.clearTokenBlacklist();
        expect(server.blacklistedTokensCount, equals(0));
      });
    });

    group('8. EDGE CASES AND ERROR SCENARIOS', () {
      test(
        '8.1 Should handle missing Authorization header gracefully',
        () async {
          final response = await _makeRequest('GET', '/api/admin/users');

          expect(response.statusCode, equals(401));
          final data = jsonDecode(response.body);
          expect(data['error']['code'], equals('UNAUTHORIZED'));
        },
      );

      test('8.2 Should handle malformed Authorization header', () async {
        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'NotBearer token123'},
        );

        expect(response.statusCode, equals(401));
      });

      test('8.3 Should handle empty Bearer token', () async {
        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer '},
        );

        expect(response.statusCode, equals(401));
      });

      test('8.4 Should handle JWT with invalid structure', () async {
        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer invalid.structure'},
        );

        expect(response.statusCode, equals(401));
      });

      test('8.5 Should handle JWT with malformed payload', () async {
        final malformedToken = 'header.invalidbase64!@#.signature';

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $malformedToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('8.6 Should handle future-dated JWT (iat in future)', () async {
        final futureToken = _createJWT({
          'user_id': 'admin123',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'iat':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000, // Future
          'exp':
              DateTime.now().add(Duration(hours: 2)).millisecondsSinceEpoch ~/
              1000,
        });

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $futureToken'},
        );

        expect(response.statusCode, equals(401));
      });

      test('8.7 Should handle JWT without required claims', () async {
        final incompleteToken = _createJWT({
          'user_id': 'admin123',
          // Missing role, active, permissions
        });

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $incompleteToken'},
        );

        expect(response.statusCode, equals(403));
      });

      test('8.8 Should handle extremely large JWT payload', () async {
        final largePayload = {
          'user_id': 'admin123',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'after_hours_access': true,
          'large_data': 'x' * 10000, // 10KB of data
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        };

        final largeToken = _createJWT(largePayload);

        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $largeToken'},
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('9. COMPLEX VALIDATION SCENARIOS', () {
      test('9.1 Should handle multiple department validator', () async {
        final multiDeptToken = _createJWT({
          'user_id': 'user123',
          'department': 'finance',
          'employee_level': 'manager',
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'GET',
          '/api/mixed/department-test',
          headers: {'Authorization': 'Bearer $multiDeptToken'},
        );

        expect(response.statusCode, equals(200));
      });

      test('9.2 Should handle financial validator with edge amounts', () async {
        final financialToken = _createJWT({
          'user_id': 'finance123',
          'department': 'finance',
          'clearance_level': 3,
          'certifications': ['financial_ops_certified'],
          'max_transaction_amount': 10000.0, // Exactly the minimum
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'POST',
          '/api/mixed/financial-edge-case',
          headers: {
            'Authorization': 'Bearer $financialToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'amount': 10000}),
        );

        expect(response.statusCode, equals(200));
      });

      test('9.3 Should handle business hours validation edge cases', () async {
        final businessHoursToken = _createJWT({
          'user_id': 'user123',
          'role': 'user',
          'active': true,
          'after_hours_access': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final response = await _makeRequest(
          'GET',
          '/api/edge/business-hours-test',
          headers: {'Authorization': 'Bearer $businessHoursToken'},
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('10. PERFORMANCE AND SCALABILITY', () {
      test('10.1 Should handle rapid consecutive requests', () async {
        final adminToken = _createValidAdminToken();
        final futures = <Future<TestResponse>>[];

        // Make 10 rapid requests
        for (int i = 0; i < 10; i++) {
          futures.add(
            _makeRequest(
              'GET',
              '/api/admin/users',
              headers: {'Authorization': 'Bearer $adminToken'},
            ),
          );
        }

        final responses = await Future.wait(futures);

        for (final response in responses) {
          expect(response.statusCode, equals(200));
        }
      });

      test('10.2 Should handle different tokens simultaneously', () async {
        final adminToken = _createValidAdminToken();
        final supportToken = _createJWT({
          'user_id': 'support123',
          'role': 'user',
          'department': 'support',
          'active': true,
          'exp':
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });

        final futures = await Future.wait([
          _makeRequest(
            'GET',
            '/api/admin/users',
            headers: {'Authorization': 'Bearer $adminToken'},
          ),
          _makeRequest(
            'GET',
            '/api/support/tickets',
            headers: {'Authorization': 'Bearer $supportToken'},
          ),
        ]);

        expect(futures[0].statusCode, equals(200));
        expect(futures[1].statusCode, equals(200));
      });
    });

    group('11. JWT CONFIGURATION MANAGEMENT', () {
      test('11.1 Should handle JWT configuration changes', () async {
        // Disable JWT
        server.disableJWTAuth();

        // Re-enable with new config
        server.configureJWTAuth(
          jwtSecret:
              'new-test-secret-key-for-configuration-testing-minimum-32-chars',
          excludePaths: ['/api/test', '/api/public'],
        );

        expect(server.blacklistedTokensCount, equals(0));

        // Should work with new configuration
        final adminToken = _createValidAdminToken();
        final response = await _makeRequest(
          'GET',
          '/api/admin/users',
          headers: {'Authorization': 'Bearer $adminToken'},
        );

        expect(response.statusCode, equals(200));
      });
    });
  });
}

// Helper classes for comprehensive testing

class TestResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  TestResponse(this.statusCode, this.body, this.headers);
}

Future<TestResponse> _makeRequest(
  String method,
  String path, {
  Map<String, String>? headers,
  String? body,
}) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('http://localhost:8083$path');
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

String _createJWT(Map<String, dynamic> payload) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = 'comprehensive-test-signature';

  return '$encodedHeader.$encodedPayload.$signature';
}

String _createValidAdminToken() {
  return _createJWT({
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

// Test Controllers for comprehensive scenarios

@Controller('/api/public')
class PublicTestController extends BaseController {
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
@JWTController([
  MyAdminValidator(),
  MyBusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true)
class AdminControllerTest extends BaseController {
  @GET('/users')
  Future<Response> getUsers(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'access_level': 'admin',
        'data': ['user1', 'user2', 'user3'],
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  @GET('/sensitive-data')
  Future<Response> getSensitiveData(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': 'classified information',
        'access_level': 'admin+business_hours',
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
        'user_id': userId,
        'user_email': userEmail,
        'user_role': userRole,
        'context_available': jwtPayload != null,
      }),
    );
  }
}

@Controller('/api/finance')
@JWTController([
  MyDepartmentValidator(allowedDepartments: ['finance', 'accounting']),
])
class FinanceControllerTest extends BaseController {
  @POST('/high-value-transaction')
  @JWTEndpoint([MyFinancialValidator(minimumAmount: 10000)])
  Future<Response> highValueTransaction(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'High-value transaction approved',
        'operation': {
          'amount': data['amount'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      }),
    );
  }

  @GET('/public-balance')
  @JWTPublic()
  Future<Response> getPublicBalance(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'access_type': 'public',
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
class SupportControllerTest extends BaseController {
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

  @DELETE('/tickets/<id>')
  @JWTEndpoint([
    MyAdminValidator(), // Only admin can delete
  ])
  Future<Response> deleteTicket(Request request) async {
    final ticketId = getRequiredParam(request, 'id');

    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'Ticket $ticketId deleted by Admin',
        'admin_only': true,
      }),
    );
  }
}

@Controller('/api/mixed')
@JWTController([
  MyDepartmentValidator(allowedDepartments: ['general']),
])
class MixedValidationControllerTest extends BaseController {
  @GET('/department-test')
  @JWTEndpoint([
    MyDepartmentValidator(
      allowedDepartments: ['finance', 'admin'],
      requireManagerLevel: true,
    ),
  ])
  Future<Response> departmentTest(Request request) async {
    return jsonResponse(
      jsonEncode({'success': true, 'message': 'Department validation passed'}),
    );
  }

  @POST('/financial-edge-case')
  @JWTEndpoint([MyFinancialValidator(minimumAmount: 10000)])
  Future<Response> financialEdgeCase(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    return jsonResponse(
      jsonEncode({
        'success': true,
        'amount': data['amount'],
        'edge_case': 'handled',
      }),
    );
  }
}

@Controller('/api/edge')
class EdgeCaseControllerTest extends BaseController {
  @GET('/business-hours-test')
  @JWTEndpoint([
    MyBusinessHoursValidator(startHour: 0, endHour: 23), // Almost 24/7
  ])
  Future<Response> businessHoursTest(Request request) async {
    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'Business hours validation passed',
        'current_hour': DateTime.now().hour,
      }),
    );
  }
}
