import 'dart:convert';
import 'package:api_kit/api_kit.dart';

/// Ejemplo completo del sistema JWT de api_kit
///
/// Demuestra exactamente lo especificado en la documentación:
/// - @JWTController([validadores], requireAll: true/false)
/// - @JWTEndpoint([validadores], requireAll: true/false)
/// - @JWTPublic()
/// - Validadores personalizados que extienden JWTValidatorBase
/// - Lógica AND/OR para validadores múltiples

void main() async {
  // 1. Crear servidor
  final server = ApiServer(config: ServerConfig.development());

  // 2. Configurar JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-super-secret-jwt-key-min-32-chars',
    excludePaths: [
      '/api/public', // Rutas públicas
      '/api/auth', // Endpoints de autenticación
      '/health', // Health checks
    ],
  );

  // 3. Iniciar servidor con controladores
  final result = await server.start(
    host: '0.0.0.0',
    port: 8080,
    controllerList: [
      PublicController(),
      AdminController(),
      FinanceController(),
      SupportController(),
    ],
  );

  result.when(
    ok: (httpServer) {
      print('🚀 JWT Example Server running on http://localhost:8080');
      _printUsageExamples();
    },
    err: (error) => print('❌ Failed to start: ${error.msm}'),
  );
}

/// Controlador público (sin JWT)
@Controller('/api/public')
class PublicController extends BaseController {
  @GET('/health')
  @JWTPublic() // Endpoint público explícito
  Future<Response> healthCheck(Request request) async {
    return jsonResponse(
      jsonEncode({
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'jwt_system': 'active',
      }),
    );
  }

  @GET('/info')
  @JWTPublic() // Endpoint público explícito
  Future<Response> publicInfo(Request request) async {
    return jsonResponse(
      jsonEncode({
        'name': 'api_kit JWT System',
        'version': '1.0.0',
        'documentation': 'See doc/15-jwt-validation-system.md',
      }),
    );
  }
}

/// Controlador admin con validación a nivel de controller
/// TODOS los endpoints requieren admin + business hours (AND logic)
@Controller('/api/admin')
@JWTController([
  MyAdminValidator(),
  MyBusinessHoursValidator(startHour: 8, endHour: 18),
], requireAll: true)
class AdminController extends BaseController {
  // Este endpoint hereda la validación del controlador
  @GET('/users')
  Future<Response> getAllUsers(Request request) async {
    // Requiere: admin + business hours (ambos deben pasar)
    final users = [
      {'id': '1', 'email': 'user1@example.com', 'role': 'user'},
      {'id': '2', 'email': 'admin@example.com', 'role': 'admin'},
    ];

    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': users,
        'message': 'Admin access granted',
      }),
    );
  }

  // Este endpoint también hereda la validación del controlador
  @DELETE('/users/<id>')
  Future<Response> deleteUser(Request request) async {
    final userId = getRequiredParam(request, 'id');

    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'User $userId deleted by admin',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

/// Controlador financiero con validación mixta
@Controller('/api/finance')
@JWTController([
  MyDepartmentValidator(
    allowedDepartments: ['finance', 'accounting'],
    requireManagerLevel: false,
  ),
])
class FinanceController extends BaseController {
  // Usa validación del controlador (departamento finance/accounting)
  @GET('/reports')
  Future<Response> getReports(Request request) async {
    final reports = [
      {'id': '1', 'name': 'Monthly Report', 'type': 'financial'},
      {'id': '2', 'name': 'Quarterly Summary', 'type': 'summary'},
    ];

    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': reports,
        'message': 'Financial reports accessed',
      }),
    );
  }

  // SOBRESCRIBE validación del controlador con validadores específicos
  @POST('/transactions')
  @JWTEndpoint([
    MyFinancialValidator(minimumAmount: 10000),
    MyDepartmentValidator(
      allowedDepartments: ['finance'],
      requireManagerLevel: true,
    ),
  ], requireAll: true)
  Future<Response> createTransaction(Request request) async {
    // Este endpoint requiere:
    // 1. MyFinancialValidator (certificación + nivel + límite $10k)
    // 2. MyDepartmentValidator (solo finance + nivel manager)
    // AMBOS deben pasar (requireAll: true)

    final body = await request.readAsString();
    final transactionData = jsonDecode(body) as Map<String, dynamic>;

    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'High-value transaction created',
        'transaction_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        'amount': transactionData['amount'],
      }),
      statusCode: 201,
    );
  }

  // Endpoint público que SOBRESCRIBE cualquier validación
  @GET('/balance')
  @JWTPublic()
  Future<Response> getPublicBalance(Request request) async {
    // Sin validación JWT - acceso público
    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': {
          'public_balance': 'Available for consultation',
          'transparency': 'Public access enabled',
        },
      }),
    );
  }
}

/// Controlador de soporte con lógica OR
/// El usuario puede acceder si es admin O pertenece a soporte
@Controller('/api/support')
@JWTController([
  MyAdminValidator(),
  MyDepartmentValidator(allowedDepartments: ['support', 'customer_service']),
], requireAll: false) // Lógica OR: al menos uno debe pasar
class SupportController extends BaseController {
  // Requiere ser admin OR departamento support/customer_service
  @GET('/tickets')
  Future<Response> getTickets(Request request) async {
    final tickets = [
      {'id': '1', 'title': 'Login Issue', 'status': 'open'},
      {'id': '2', 'title': 'Password Reset', 'status': 'closed'},
    ];

    return jsonResponse(
      jsonEncode({
        'success': true,
        'data': tickets,
        'message': 'Support tickets accessed',
      }),
    );
  }

  // Endpoint con validación específica que SOBRESCRIBE la del controlador
  @PUT('/tickets/<id>')
  @JWTEndpoint([
    MyAdminValidator(), // Solo administradores pueden modificar tickets
  ])
  Future<Response> updateTicket(Request request) async {
    final ticketId = getRequiredParam(request, 'id');

    return jsonResponse(
      jsonEncode({
        'success': true,
        'message': 'Ticket $ticketId updated by admin',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

/// Imprime ejemplos de uso y testing
void _printUsageExamples() {
  print('''

📋 JWT Validation System Examples:

🔓 PUBLIC ENDPOINTS (No JWT required):
├── GET  /api/public/health
├── GET  /api/public/info
└── GET  /api/finance/balance

🔐 CONTROLLER-LEVEL VALIDATION:
├── GET  /api/admin/users         (Admin + Business Hours - AND)
├── DEL  /api/admin/users/{id}    (Admin + Business Hours - AND)
├── GET  /api/finance/reports     (Finance/Accounting Dept)
├── GET  /api/support/tickets     (Admin OR Support Dept - OR)

🎯 ENDPOINT-LEVEL VALIDATION (Override Controller):
├── POST /api/finance/transactions (Financial Validator + Manager - AND)
└── PUT  /api/support/tickets/{id} (Admin Only)

🧪 TESTING COMMANDS:

# 1. Test public endpoints (should work):
curl -X GET http://localhost:8080/api/public/health
curl -X GET http://localhost:8080/api/finance/balance

# 2. Test protected endpoint without JWT (should return 401):
curl -X GET http://localhost:8080/api/admin/users

# 3. Test with JWT but insufficient permissions (should return 403):
curl -X GET http://localhost:8080/api/admin/users \\
  -H "Authorization: Bearer {user-token-without-admin-role}"

# 4. Test with valid admin JWT (should return 200):
curl -X GET http://localhost:8080/api/admin/users \\
  -H "Authorization: Bearer {valid-admin-token}"

# 5. Test OR logic endpoint:
curl -X GET http://localhost:8080/api/support/tickets \\
  -H "Authorization: Bearer {support-or-admin-token}"

📝 EXAMPLE JWT PAYLOADS:

Admin User (for /api/admin/* endpoints):
{
  "user_id": "admin123",
  "email": "admin@company.com",
  "name": "Admin User",
  "role": "admin",
  "active": true,
  "permissions": ["admin_access", "read", "write"],
  "after_hours_access": true,
  "exp": ${(DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600}
}

Finance Manager (for high-value transactions):
{
  "user_id": "fin123",
  "email": "finance@company.com",
  "name": "Finance Manager",
  "role": "manager",
  "active": true,
  "department": "finance",
  "employee_level": "manager",
  "clearance_level": 5,
  "certifications": ["financial_ops_certified"],
  "max_transaction_amount": 100000.0,
  "exp": ${(DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600}
}

Support User (for support tickets):
{
  "user_id": "sup123",
  "email": "support@company.com",
  "name": "Support Agent",
  "role": "user",
  "active": true,
  "department": "support",
  "exp": ${(DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600}
}

🎯 KEY FEATURES DEMONSTRATED:

✅ @JWTController([validators], requireAll: bool) - Controller-level validation
✅ @JWTEndpoint([validators], requireAll: bool) - Endpoint-level override
✅ @JWTPublic() - Public endpoints with highest priority
✅ Custom validators extending JWTValidatorBase
✅ AND logic (requireAll: true) - all validators must pass
✅ OR logic (requireAll: false) - at least one validator must pass
✅ JWT payload access in request context
✅ Validation callbacks for success/failure
✅ Flexible JWT structure controlled by developers
✅ Hierarchical validation: endpoint overrides controller

🔧 The system works exactly as documented in:
   doc/15-jwt-validation-system.md

🚀 Server ready for testing with JWT validation!

''');
}

/// Ejemplos de JWT tokens para testing
/// NOTA: En producción usar dart_jsonwebtoken
class ExampleJWTs {
  // Estos son tokens de ejemplo - en producción usar firma real

  static String adminToken() {
    final payload = {
      'user_id': 'admin123',
      'email': 'admin@company.com',
      'name': 'Admin User',
      'role': 'admin',
      'active': true,
      'permissions': ['admin_access', 'read', 'write'],
      'after_hours_access': true,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    };

    return _createMockJWT(payload);
  }

  static String financeManagerToken() {
    final payload = {
      'user_id': 'fin123',
      'email': 'finance@company.com',
      'name': 'Finance Manager',
      'role': 'manager',
      'active': true,
      'department': 'finance',
      'employee_level': 'manager',
      'clearance_level': 5,
      'certifications': ['financial_ops_certified'],
      'max_transaction_amount': 100000.0,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    };

    return _createMockJWT(payload);
  }

  static String supportUserToken() {
    final payload = {
      'user_id': 'sup123',
      'email': 'support@company.com',
      'name': 'Support Agent',
      'role': 'user',
      'active': true,
      'department': 'support',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    };

    return _createMockJWT(payload);
  }

  static String _createMockJWT(Map<String, dynamic> payload) {
    // Crear JWT mock para testing (NO usar en producción)
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    final signature = 'mock-signature-use-real-crypto-in-production';

    return '$encodedHeader.$encodedPayload.$signature';
  }
}
