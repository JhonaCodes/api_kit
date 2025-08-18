import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:api_kit/api_kit.dart';

/// Ejemplo de cómo usar JWT con el sistema existente de api_kit
/// 
/// Este ejemplo demuestra:
/// - Uso de @RequireAuth() para endpoints protegidos
/// - Registro de middleware JWT global
/// - Endpoints públicos sin autenticación
/// - Validación por roles

void main() async {
  // 1. Crear servidor
  final server = ApiServer(config: ServerConfig.development());
  
  // 2. Registrar middleware JWT global
  MiddlewareRegistry.register('jwt', BuiltInMiddleware.jwt(
    secret: 'your-secret-key-here',
    requiredRoles: [], // Sin roles requeridos por defecto
  ));
  
  // 3. Registrar middleware JWT para admin
  MiddlewareRegistry.register('jwt-admin', BuiltInMiddleware.jwt(
    secret: 'your-secret-key-here',
    requiredRoles: ['admin'], // Requiere rol admin
  ));
  
  // 4. Iniciar servidor con controladores
  final result = await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [
      PublicController(),
      UserController(),
      AdminController(),
    ],
  );
  
  result.when(
    ok: (httpServer) {
      print('🚀 Server running on http://localhost:8080');
      print('');
      print('📋 Available endpoints:');
      print('  GET  /public/health        (Public - no auth)');
      print('  GET  /users/profile        (Protected - requires JWT)');
      print('  POST /users/update         (Protected - requires JWT)');
      print('  GET  /admin/users          (Protected - requires admin role)');
      print('  DELETE /admin/users/<id>   (Protected - requires admin role)');
      print('');
      print('🔑 Test with:');
      print('  curl -X GET http://localhost:8080/public/health');
      print('  curl -X GET http://localhost:8080/users/profile \\');
      print('    -H "Authorization: Bearer your-jwt-token"');
    },
    err: (error) => print('❌ Failed to start: ${error.msm}'),
  );
}

/// Controlador público sin autenticación
@Controller('/public')
class PublicController extends BaseController {
  
  @GET('/health')
  Future<Response> health(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'server': 'api_kit with JWT'
    }));
  }
  
  @GET('/info')
  Future<Response> info(Request request) async {
    return jsonResponse(jsonEncode({
      'name': 'api_kit JWT Example',
      'version': '1.0.0',
      'authentication': 'JWT Bearer Token'
    }));
  }
}

/// Controlador que requiere autenticación JWT básica
@Controller('/users')
class UserController extends BaseController {
  
  /// Endpoint protegido - requiere JWT válido
  @GET('/profile')
  @RequireAuth()
  // Nota: El middleware JWT se aplica según las anotaciones
  Future<Response> getProfile(Request request) async {
    // Obtener datos del usuario desde el contexto JWT
    final userId = request.context['user_id'] as String?;
    final userEmail = request.context['user_email'] as String?;
    final userRoles = request.context['user_roles'] as List<dynamic>?;
    
    return jsonResponse(jsonEncode({
      'success': true,
      'data': {
        'user_id': userId,
        'email': userEmail,
        'roles': userRoles,
        'profile': {
          'name': 'User Name',
          'created_at': '2024-01-01T00:00:00Z',
        }
      },
      'message': 'Profile retrieved successfully'
    }));
  }
  
  /// Endpoint protegido para actualizar perfil
  @POST('/update')
  @RequireAuth()
  Future<Response> updateProfile(Request request) async {
    final userId = request.context['user_id'] as String?;
    // final body = await request.readAsString(); // No usado en este ejemplo
    
    return jsonResponse(jsonEncode({
      'success': true,
      'message': 'Profile updated successfully',
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String()
    }), statusCode: 200);
  }
}

/// Controlador que requiere rol de administrador
@Controller('/admin')
class AdminController extends BaseController {
  
  /// Endpoint que requiere rol admin
  @GET('/users')
  @RequireAuth(role: 'admin')
  Future<Response> getAllUsers(Request request) async {
    final userId = request.context['user_id'] as String?;
    final userRoles = request.context['user_roles'] as List<dynamic>?;
    
    // Simular lista de usuarios
    final users = [
      {'id': '1', 'email': 'user1@example.com', 'role': 'user'},
      {'id': '2', 'email': 'user2@example.com', 'role': 'user'},
      {'id': '3', 'email': 'admin@example.com', 'role': 'admin'},
    ];
    
    return jsonResponse(jsonEncode({
      'success': true,
      'data': users,
      'message': 'Users retrieved successfully',
      'requested_by': {
        'user_id': userId,
        'roles': userRoles,
      }
    }));
  }
  
  /// Endpoint para eliminar usuario (solo admins)
  @DELETE('/users/<id>')
  @RequireAuth(role: 'admin')
  Future<Response> deleteUser(Request request) async {
    final userIdToDelete = getRequiredParam(request, 'id');
    final adminId = request.context['user_id'] as String?;
    
    return jsonResponse(jsonEncode({
      'success': true,
      'message': 'User deleted successfully',
      'deleted_user_id': userIdToDelete,
      'deleted_by': adminId,
      'timestamp': DateTime.now().toIso8601String()
    }));
  }
}

/// Clase de utilidad para generar JWTs de ejemplo
/// NOTA: En producción usar una librería JWT real como dart_jsonwebtoken
class ExampleJWTGenerator {
  
  /// Genera un JWT de ejemplo para testing
  /// En producción, usar firma criptográfica real
  static String generateMockToken({
    required String userId,
    required String email,
    List<String> roles = const ['user'],
    Duration expiration = const Duration(hours: 24),
  }) {
    final payload = {
      'user_id': userId,
      'email': email,
      'roles': roles,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(expiration).millisecondsSinceEpoch ~/ 1000,
    };
    
    // Nota: Esto NO es un JWT real con firma válida
    // Solo para demostración - usar dart_jsonwebtoken en producción
    final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    final payloadEncoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    final signature = 'mock-signature'; // En producción, usar HMAC real
    
    return '$header.$payloadEncoded.$signature';
  }
  
  /// Genera token de usuario normal
  static String generateUserToken() {
    return generateMockToken(
      userId: 'user123',
      email: 'user@example.com',
      roles: ['user'],
    );
  }
  
  /// Genera token de administrador
  static String generateAdminToken() {
    return generateMockToken(
      userId: 'admin123',
      email: 'admin@example.com',
      roles: ['user', 'admin'],
    );
  }
}

/// Información sobre cómo usar este ejemplo:
/// 
/// 1. Iniciar el servidor:
///    dart run lib/src/examples/jwt_example.dart
/// 
/// 2. Probar endpoints públicos:
///    curl -X GET http://localhost:8080/public/health
///    curl -X GET http://localhost:8080/public/info
/// 
/// 3. Probar endpoints protegidos sin token (debería fallar):
///    curl -X GET http://localhost:8080/users/profile
/// 
/// 4. Probar endpoints protegidos con token:
///    curl -X GET http://localhost:8080/users/profile \
///      -H "Authorization: Bearer your-jwt-token"
/// 
/// 5. Probar endpoints de admin sin rol admin (debería fallar):
///    curl -X GET http://localhost:8080/admin/users \
///      -H "Authorization: Bearer user-token"
/// 
/// 6. Probar endpoints de admin con rol admin:
///    curl -X GET http://localhost:8080/admin/users \
///      -H "Authorization: Bearer admin-token"
/// 
/// Para generar tokens de prueba, usar ExampleJWTGenerator:
///   final userToken = ExampleJWTGenerator.generateUserToken();
///   final adminToken = ExampleJWTGenerator.generateAdminToken();
/// 
/// En producción:
/// - Usar una librería JWT real como dart_jsonwebtoken
/// - Implementar validación de firma criptográfica
/// - Configurar secretos seguros
/// - Implementar refresh tokens
/// - Agregar logging y auditoría