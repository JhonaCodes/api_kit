import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:api_kit/api_kit.dart';

// Validadores estáticos para testing
final adminValidator = MyAdminValidator();
final departmentValidator = MyDepartmentValidator(allowedDepartments: ['test']);
final financialValidator = MyFinancialValidator(minimumAmount: 10000);

void main() {
  group('JWT Annotations Integration Tests', () {
    late ApiServer server;
    late HttpServer httpServer;
    const int testPort = 8082;
    
    setUpAll(() async {
      // Configurar servidor de prueba
      server = ApiServer(config: ServerConfig.development());
      
      // Configurar JWT authentication
      server.configureJWTAuth(
        jwtSecret: 'test-secret-key-for-annotations-testing-min-32-chars',
        excludePaths: ['/api/public'],
      );
      
      // Iniciar servidor con controladores de prueba
      final result = await server.start(
        host: '0.0.0.0',
        port: testPort,
        controllerList: [
          SimplePublicController(),
          SimpleAdminController(),
        ],
      );
      
      result.when(
        ok: (srv) => httpServer = srv,
        err: (error) => throw Exception('Failed to start test server: ${error.msm}'),
      );
    });
    
    tearDownAll(() async {
      await server.stop(httpServer);
    });
    
    test('JWT system should be properly initialized', () {
      expect(server.blacklistedTokensCount, equals(0));
      expect(httpServer.port, equals(testPort));
    });
    
    group('@JWTPublic Tests', () {
      test('should allow access to public endpoints without JWT', () async {
        final client = HttpClient();
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/public/open')
          );
          final response = await request.close();
          
          expect(response.statusCode, equals(200));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          expect(data['access'], equals('public'));
          expect(data['jwt_required'], equals(false));
          
        } finally {
          client.close();
        }
      });
    });
    
    group('JWT Validation Tests', () {
      test('should deny access to protected endpoints without JWT', () async {
        final client = HttpClient();
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/admin/secure')
          );
          final response = await request.close();
          
          expect(response.statusCode, equals(401));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          expect(data['success'], equals(false));
          expect(data['error']['code'], equals('UNAUTHORIZED'));
          
        } finally {
          client.close();
        }
      });
      
      test('should deny access with invalid JWT token', () async {
        final client = HttpClient();
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/admin/secure')
          );
          request.headers.add('Authorization', 'Bearer invalid-token-format');
          final response = await request.close();
          
          expect(response.statusCode, equals(401));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          expect(data['success'], equals(false));
          expect(data['error']['code'], equals('UNAUTHORIZED'));
          
        } finally {
          client.close();
        }
      });
      
      test('should allow access with valid admin JWT token', () async {
        final client = HttpClient();
        final adminToken = _createMockJWT({
          'user_id': 'admin123',
          'email': 'admin@test.com',
          'name': 'Test Admin',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access', 'read', 'write'],
          'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/admin/secure')
          );
          request.headers.add('Authorization', 'Bearer $adminToken');
          final response = await request.close();
          
          expect(response.statusCode, equals(200));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          expect(data['success'], equals(true));
          expect(data['access_level'], equals('admin'));
          
        } finally {
          client.close();
        }
      });
      
      test('should deny access with insufficient permissions', () async {
        final client = HttpClient();
        final userToken = _createMockJWT({
          'user_id': 'user123',
          'email': 'user@test.com',
          'name': 'Regular User',
          'role': 'user',
          'active': true,
          'permissions': ['read'],
          'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/admin/secure')
          );
          request.headers.add('Authorization', 'Bearer $userToken');
          final response = await request.close();
          
          expect(response.statusCode, equals(403));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          expect(data['success'], equals(false));
          expect(data['error']['code'], equals('FORBIDDEN'));
          
        } finally {
          client.close();
        }
      });
    });
    
    group('JWT Context Integration Tests', () {
      test('should provide JWT payload in request context', () async {
        final client = HttpClient();
        final adminToken = _createMockJWT({
          'user_id': 'admin456',
          'email': 'admin@test.com',
          'name': 'Admin User',
          'role': 'admin',
          'active': true,
          'permissions': ['admin_access'],
          'department': 'IT',
          'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
        
        try {
          final request = await client.getUrl(
            Uri.parse('http://localhost:$testPort/api/admin/profile')
          );
          request.headers.add('Authorization', 'Bearer $adminToken');
          final response = await request.close();
          
          expect(response.statusCode, equals(200));
          
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          
          expect(data['jwt_data']['user_id'], equals('admin456'));
          expect(data['jwt_data']['email'], equals('admin@test.com'));
          expect(data['jwt_data']['name'], equals('Admin User'));
          expect(data['jwt_data']['role'], equals('admin'));
          expect(data['jwt_data']['department'], equals('IT'));
          
        } finally {
          client.close();
        }
      });
    });
    
    group('Server Configuration Tests', () {
      test('should properly configure JWT blacklist', () async {
        final mockToken = 'mock.jwt.token.for.blacklist.testing';
        
        // Agregar token a blacklist
        server.blacklistToken(mockToken);
        expect(server.blacklistedTokensCount, equals(1));
        
        // Limpiar blacklist
        server.clearTokenBlacklist();
        expect(server.blacklistedTokensCount, equals(0));
      });
      
      test('should support JWT configuration changes', () {
        // Test que JWT está habilitado
        expect(server.blacklistedTokensCount, isA<int>());
        
        // Deshabilitar JWT
        server.disableJWTAuth();
        
        // Re-configurar JWT
        server.configureJWTAuth(
          jwtSecret: 'new-test-secret-key-for-configuration-testing',
          excludePaths: ['/api/test'],
        );
        
        expect(server.blacklistedTokensCount, equals(0));
      });
    });
  });
}

/// Controlador simple para endpoints públicos
@Controller('/api/public')
class SimplePublicController extends BaseController {
  
  @GET('/open')
  @JWTPublic()
  Future<Response> openEndpoint(Request request) async {
    return jsonResponse(jsonEncode({
      'success': true,
      'access': 'public',
      'jwt_required': false,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
}

/// Controlador simple con validación JWT usando validadores existentes
@Controller('/api/admin')  
@JWTController([
  const MyAdminValidator(),
])
class SimpleAdminController extends BaseController {
  
  @GET('/secure')
  Future<Response> secureEndpoint(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    return jsonResponse(jsonEncode({
      'success': true,
      'access_level': 'admin',
      'user_id': jwtPayload?['user_id'],
      'user_role': jwtPayload?['role'],
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  @GET('/profile')
  Future<Response> getProfile(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    return jsonResponse(jsonEncode({
      'success': true,
      'jwt_data': {
        'user_id': jwtPayload?['user_id'],
        'email': jwtPayload?['email'],
        'name': jwtPayload?['name'],
        'role': jwtPayload?['role'],
        'department': jwtPayload?['department'],
        'active': jwtPayload?['active'],
        'permissions': jwtPayload?['permissions'],
      },
      'context_available': jwtPayload != null,
    }));
  }
}

/// Helper para crear JWT mock de testing
String _createMockJWT(Map<String, dynamic> payload) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = 'test-signature-for-annotations-testing';
  
  return '$encodedHeader.$encodedPayload.$signature';
}