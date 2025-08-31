/// JWT Auto-Discovery Integration Example
/// 
/// This example demonstrates the complete JWT validation system integrated
/// with automatic controller discovery. It shows:
/// 
/// 1. Auto-discovery of controllers with @RestController
/// 2. Automatic JWT validation based on @JWTController, @JWTEndpoint, @JWTPublic
/// 3. Custom JWT validators working automatically
/// 4. Multiple validation levels and logic (AND/OR)
/// 5. Seamless integration without manual configuration per endpoint

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:shelf/shelf.dart';

void main() async {
  print('🚀 Starting JWT Auto-Discovery Integration Example...\n');

  try {
    // Create server with JWT configuration
    final server = ApiServer.create(
      config: ServerConfig.development(),
      middleware: [
        // Configure JWT middleware with example secret
        EnhancedAuthMiddleware.jwtExtractor(
          jwtSecret: 'your-super-secret-jwt-key-256-bits-long!',
          excludePaths: ['/api/public', '/health'],
        ),
        EnhancedAuthMiddleware.jwtAccessLogger(),
      ],
    )
    .configureJWT(
      jwtSecret: 'your-super-secret-jwt-key-256-bits-long!',
      excludePaths: ['/api/public', '/health'],
    )
    .configureEndpointDisplay(showInConsole: true)
    .configureEnvironment();

    print('📊 JWT Auto-Discovery System Features:');
    print('   ✅ Automatic controller detection via static analysis');
    print('   ✅ JWT validation applied based on annotations');
    print('   ✅ @JWTPublic endpoints skip authentication');
    print('   ✅ @JWTController applies validators to all methods');
    print('   ✅ @JWTEndpoint applies specific validators per method');
    print('   ✅ Multiple validators with AND/OR logic');
    print('   ✅ Custom validation logic and error handling');
    print('   ✅ Seamless integration with auto-discovery routing\n');

    // Start server with auto-discovery (no manual controller registration!)
    final result = await server.start(
      host: 'localhost',
      port: 8080,
      projectPath: Directory.current.path,
    );

    result.when(
      ok: (httpServer) {
        print('\n🎯 JWT Auto-Discovery Server Status:');
        print('   🟢 Server running at http://${httpServer.address.host}:${httpServer.port}');
        print('   🔍 Controllers auto-discovered and JWT validation configured');
        print('   📋 All endpoints shown above with their JWT requirements');
        
        print('\n🧪 Test the JWT System:');
        print('   📤 Public endpoint (no JWT):');
        print('      curl http://localhost:8080/api/public/info');
        
        print('\n   🔐 Admin endpoint (requires admin JWT):');
        print('      curl -H "Authorization: Bearer \$ADMIN_TOKEN" http://localhost:8080/api/admin/users');
        
        print('\n   🏢 HR endpoint (requires HR department JWT):');
        print('      curl -H "Authorization: Bearer \$HR_TOKEN" http://localhost:8080/api/hr/employees');
        
        print('\n   💰 Financial endpoint (requires financial validator):');
        print('      curl -H "Authorization: Bearer \$FINANCIAL_TOKEN" http://localhost:8080/api/finance/transactions');

        print('\n📝 Example JWT Payloads:');
        print('   👑 Admin Token Payload:');
        print('      {');
        print('        "user_id": "admin123",');
        print('        "role": "admin",');
        print('        "active": true,');
        print('        "permissions": ["admin_access"]');
        print('      }');
        
        print('\n   🏢 HR Token Payload:');
        print('      {');
        print('        "user_id": "hr456",');
        print('        "department": "hr",');
        print('        "employee_level": "manager"');
        print('      }');
        
        print('\n   💰 Financial Token Payload:');
        print('      {');
        print('        "user_id": "finance789",');
        print('        "department": "finance",');
        print('        "clearance_level": 4,');
        print('        "certifications": ["financial_ops_certified"],');
        print('        "max_transaction_amount": 50000.0');
        print('      }');

        print('\n⚡ System Advantages:');
        print('   🎯 Zero manual JWT configuration per endpoint');
        print('   🚀 Automatic validation based on annotations');
        print('   🔧 Extensible custom validator system');
        print('   🛡️ Production-ready security features');
        print('   📊 Comprehensive logging and error handling');
        print('   🎨 Clean, annotation-based development experience');

        print('\n🔍 Monitoring:');
        print('   📋 Check server logs for JWT validation details');
        print('   🎯 Failed authentications will show specific reasons');
        print('   ✅ Successful authentications logged with user context');

        print('\n⚠️  Press Ctrl+C to stop the server');
        
      },
      err: (error) {
        print('❌ Failed to start JWT Auto-Discovery server: $error');
        exit(1);
      },
    );

    // Keep server running
    await ProcessSignal.sigint.watch().first;
    
  } catch (e, stackTrace) {
    print('💥 Error in JWT Auto-Discovery example: $e');
    print('📚 Stack trace: $stackTrace');
    exit(1);
  }

  print('\n👋 JWT Auto-Discovery server stopped');
  exit(0);
}

/// Public API Controller - Mixed authentication levels
@RestController(basePath: '/api/public')
class PublicApiController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'getPublicInfo': getPublicInfo,
      'getSystemStatus': getSystemStatus,
    };
  }
  
  /// Completely public endpoint - no JWT required
  @Get(path: '/info')
  @JWTPublic()
  Future<Response> getPublicInfo(Request request) async {
    return jsonResponse(jsonEncode({
      'message': 'This is a public endpoint',
      'timestamp': DateTime.now().toIso8601String(),
      'no_authentication_required': true,
    }));
  }
  
  /// Public endpoint with system status
  @Get(path: '/status')
  @JWTPublic()
  Future<Response> getSystemStatus(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'version': '1.0.0',
      'jwt_system': 'enabled',
      'auto_discovery': 'active',
    }));
  }
}

/// Admin Controller - Requires administrator authentication for all endpoints
@RestController(basePath: '/api/admin')
@JWTController([
  MyAdminValidator(),
], requireAll: true)
class AdminController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'getUsers': getUsers,
      'updateSystemConfig': updateSystemConfig,
      'emergencyAccess': emergencyAccess,
    };
  }
  
  /// Admin-only endpoint - inherits controller-level JWT validation
  @Get(path: '/users')
  Future<Response> getUsers(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final adminUser = jwtPayload?['user_id'] ?? 'unknown';
    
    return jsonResponse(jsonEncode({
      'message': 'Admin access granted',
      'users': ['john_doe', 'jane_smith', 'mike_wilson'],
      'accessed_by': adminUser,
      'admin_privileges': true,
    }));
  }
  
  /// Admin endpoint with additional business hours validation
  @Post(path: '/system-config')
  @JWTEndpoint([
    const MyAdminValidator(),
    const MyBusinessHoursValidator(startHour: 9, endHour: 17),
  ], requireAll: true)
  Future<Response> updateSystemConfig(Request request) async {
    final body = await request.readAsString();
    final config = jsonDecode(body);
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final adminUser = jwtPayload?['user_id'] ?? 'unknown';
    
    return jsonResponse(jsonEncode({
      'message': 'System configuration updated',
      'config': config,
      'updated_by': adminUser,
      'requires_admin_and_business_hours': true,
    }));
  }
  
  /// Emergency access - only admin required (overrides business hours)
  @Post(path: '/emergency-access')
  @JWTEndpoint([
    MyAdminValidator(),
  ])
  Future<Response> emergencyAccess(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final adminUser = jwtPayload?['user_id'] ?? 'unknown';

    return jsonResponse(jsonEncode({
      'message': 'Emergency access granted',
      'admin_user': adminUser,
      'available_24_7': true,
    }));
  }
}

/// HR Controller - Department-based authentication
@RestController(basePath: '/api/hr')
@JWTController([
  MyDepartmentValidator(allowedDepartments: ['hr', 'management']),
], requireAll: true)
class HRController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'getEmployees': getEmployees,
      'hireEmployee': hireEmployee,
    };
  }
  
  /// HR department endpoint - inherits department validation
  @Get(path: '/employees')
  Future<Response> getEmployees(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final department = jwtPayload?['department'] ?? 'unknown';
    final userId = jwtPayload?['user_id'] ?? 'unknown';
    
    return jsonResponse(jsonEncode({
      'message': 'HR data access granted',
      'employees': ['Alice Johnson', 'Bob Smith', 'Carol Wilson'],
      'department': department,
      'accessed_by': userId,
    }));
  }
  
  /// Manager-level HR operations
  @Post(path: '/hire')
  @JWTEndpoint([
    const MyDepartmentValidator(
      allowedDepartments: ['hr'],
      requireManagerLevel: true,
    ),
  ])
  Future<Response> hireEmployee(Request request) async {
    final body = await request.readAsString();
    final employeeData = jsonDecode(body);
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    return jsonResponse(jsonEncode({
      'message': 'Employee hiring process initiated',
      'employee_data': employeeData,
      'hr_manager': jwtPayload?['user_id'],
      'requires_manager_level': true,
    }));
  }
}

/// Finance Controller - Financial operations with complex validation
@RestController(basePath: '/api/finance')
@JWTController([
  MyFinancialValidator(minimumAmount: 1000.0),
], requireAll: true)
class FinanceController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'getTransactions': getTransactions,
      'highValueTransfer': highValueTransfer,
    };
  }
  
  /// Financial transactions - requires financial certification
  @Get(path: '/transactions')
  Future<Response> getTransactions(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    final department = jwtPayload?['department'] ?? 'unknown';
    final clearanceLevel = jwtPayload?['clearance_level'] ?? 0;
    
    return jsonResponse(jsonEncode({
      'message': 'Financial data access granted',
      'transactions': [
        {'id': 1, 'amount': 5000.0, 'type': 'transfer'},
        {'id': 2, 'amount': 12000.0, 'type': 'payment'},
      ],
      'department': department,
      'clearance_level': clearanceLevel,
    }));
  }
  
  /// High-value transactions with multiple validators (OR logic)
  @Post(path: '/high-value-transfer')
  @JWTEndpoint([
    const MyFinancialValidator(minimumAmount: 10000.0),
    const MyAdminValidator(), // OR admin can also approve
  ], requireAll: false) // OR logic - either financial validator OR admin
  Future<Response> highValueTransfer(Request request) async {
    final body = await request.readAsString();
    final transferData = jsonDecode(body);
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    return jsonResponse(jsonEncode({
      'message': 'High-value transfer authorized',
      'transfer_data': transferData,
      'authorized_by': jwtPayload?['user_id'],
      'validation_logic': 'OR (financial_ops OR admin)',
    }));
  }
}

/// Mixed Access Controller - Demonstrates all JWT levels
@RestController(basePath: '/api/mixed')
class MixedAccessController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'welcome': welcome,
      'getProfile': getProfile,
      'adminAction': adminAction,
    };
  }
  
  /// Public endpoint in mixed controller
  @Get(path: '/welcome')
  @JWTPublic()
  Future<Response> welcome(Request request) async {
    return jsonResponse(jsonEncode({
      'message': 'Welcome to the mixed access API',
      'authentication': 'not_required',
    }));
  }
  
  /// Basic JWT required (no specific validators)
  @Get(path: '/profile')
  Future<Response> getProfile(Request request) async {
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    if (jwtPayload == null) {
      return Response.unauthorized('JWT token required');
    }
    
    return jsonResponse(jsonEncode({
      'message': 'User profile data',
      'user_id': jwtPayload['user_id'],
      'basic_jwt': 'required',
    }));
  }
  
  /// Specific validation for this endpoint only
  @Post(path: '/admin-action')
  @JWTEndpoint([
    const MyAdminValidator(),
    const MyBusinessHoursValidator(),
  ], requireAll: true)
  Future<Response> adminAction(Request request) async {
    final body = await request.readAsString();
    final jwtPayload = request.context['jwt_payload'] as Map<String, dynamic>?;
    
    return jsonResponse(jsonEncode({
      'message': 'Admin action performed',
      'action_data': jsonDecode(body),
      'admin_user': jwtPayload?['user_id'],
      'business_hours_validated': true,
    }));
  }
}

/// Health Controller for public health endpoints
@RestController(basePath: '/public')
class HealthController extends BaseController {
  
  @override
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'health': health,
    };
  }
  
  /// Public health check endpoint
  @Get(path: '/health')
  @JWTPublic()
  Future<Response> health(Request request) async {
    return jsonResponse(jsonEncode({
      'status': 'healthy',
      'version': '1.0.0',
      'jwt_system': 'auto-discovery-enabled',
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
}