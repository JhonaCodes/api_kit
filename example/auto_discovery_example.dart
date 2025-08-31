import 'dart:io';
import 'package:api_kit/api_kit.dart';

/// Example demonstrating the new auto-discovery system.
///
/// This example showcases the new features of api_kit v0.1.0+:
/// - 🔍 **Auto-discovery** - No manual controller registration required
/// - ⚙️ **Fluent configuration** - Clean configuration chain
/// - 🎯 **Professional console output** - Clean startup logs
/// - 📊 **Optional endpoints display** - Beautiful ASCII table
/// 
/// ## Key Improvements
/// - No more `controllerList: [...]` manual registration
/// - Configuration happens BEFORE static analysis
/// - Clean console output similar to Spring Boot
/// - Single static analysis run for better performance
///
/// ## Running the Example
///
/// 1. Run with: `dart run example/auto_discovery_example.dart`
/// 2. Notice the clean console output and automatic controller discovery
/// 3. Test endpoints:
///    - GET http://localhost:8080/api/v1/users
///    - GET http://localhost:8080/api/v1/users/1
///    - POST http://localhost:8080/api/v1/users
///    - PUT http://localhost:8080/api/v1/users/1
///    - DELETE http://localhost:8080/api/v1/users/1
///
/// ## Comparison with Previous Version
///
/// ### Before (Manual Registration):
/// ```dart
/// final server = ApiServer(config: ServerConfig.development());
/// server.configureJWTAuth(jwtSecret: 'secret');
/// await server.start(
///   host: 'localhost',
///   port: 8080,
///   controllerList: [UserController()], // ❌ Manual registration
/// );
/// ```
///
/// ### After (Auto-Discovery):
/// ```dart
/// final server = ApiServer.create()
///   ..configureJWT(jwtSecret: 'secret')
///   ..configureEndpointDisplay(showInConsole: true);
/// await server.start(host: 'localhost', port: 8080);
/// // ✅ Controllers auto-discovered automatically
/// ```
void main() async {
  // 🆕 NEW: Create server with fluent configuration
  final server = ApiServer.create()
    // 🔐 Configure JWT authentication (optional)
    // ..configureJWT(
    //   jwtSecret: 'your-secret-key-256-bits-long',
    //   excludePaths: ['/health', '/api/public'],
    // )
    // 🌍 Configure environment loading (optional)
    ..configureEnvironment(loadEnvFile: true)
    // 📊 Configure endpoints display in console (optional)
    ..configureEndpointDisplay(showInConsole: true);

  // 🚀 Start server with auto-discovery - NO manual controllerList!
  final result = await server.start(
    host: 'localhost',
    port: 8080,
    // 🎯 Notice: No controllerList parameter!
    // Controllers are auto-discovered from @RestController annotations
  );

  result.when(
    ok: (httpServer) {
      print('');
      print('🌟 Auto-Discovery Example Server Started!');
      print('');
      print('🧪 Test the auto-discovered endpoints:');
      print('   curl http://localhost:8080/api/v1/users');
      print('   curl http://localhost:8080/api/v1/users/1');
      print('   curl -X POST http://localhost:8080/api/v1/users -d \'{"name":"Auto User"}\'');
      print('');
      print('💡 Notice: UserController was discovered automatically!');
      print('   No manual registration in controllerList required.');
      print('');

      // Handle graceful shutdown
      ProcessSignal.sigint.watch().listen((_) async {
        print('🛑 Shutting down auto-discovery server...');
        await server.stop(httpServer);
        exit(0);
      });
    },
    err: (apiErr) {
      print('❌ Failed to start auto-discovery server: ${apiErr.msm}');
      exit(1);
    },
  );
}

/// Example controller that will be auto-discovered
/// 
/// 🎯 This controller demonstrates auto-discovery:
/// - Uses @RestController annotation for auto-detection
/// - No manual registration needed in main()
/// - Automatically discovered by ControllerRegistry
/// - Routes built using static analysis
@RestController(basePath: '/api/v1/users')
class UserController extends BaseController {
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Auto Alice', 'email': 'alice@auto.com'},
    {'id': '2', 'name': 'Auto Bob', 'email': 'bob@auto.com'},
  ];

  /// Auto-discovered GET endpoint for listing users
  @Get(path: '/')
  Future<Response> getUsers(Request request) async {
    logRequest(request, 'Auto-discovered: Getting all users');

    final response = ApiResponse.success(
      _users,
      'Users retrieved via auto-discovery',
    );
    return jsonResponse(response.toJson());
  }

  /// Auto-discovered GET endpoint for getting user by ID
  @Get(path: '/{id}')
  Future<Response> getUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Auto-discovered: Getting user $id');

    final user = _users.firstWhere((u) => u['id'] == id, orElse: () => {});

    final response = user.isEmpty
        ? ApiResponse.notFound('User not found')
        : ApiResponse.success(user);

    final statusCode = user.isEmpty ? 404 : 200;
    return jsonResponse(response.toJson(), statusCode: statusCode);
  }

  /// Auto-discovered POST endpoint for creating users
  @Post(path: '/')
  Future<Response> createUser(Request request) async {
    logRequest(request, 'Auto-discovered: Creating new user');

    final body = await request.readAsString();
    if (body.isEmpty) {
      final response = ApiResponse.badRequest('Request body is required');
      return jsonResponse(response.toJson(), statusCode: 400);
    }

    final newUser = {
      'id': '${_users.length + 1}',
      'name': 'Auto User',
      'email': 'auto@example.com',
    };

    _users.add(newUser);

    final response = ApiResponse.success(newUser, 'User created via auto-discovery');
    return jsonResponse(response.toJson(), statusCode: 201);
  }

  /// Auto-discovered PUT endpoint for updating users
  @Put(path: '/{id}')
  Future<Response> updateUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Auto-discovered: Updating user $id');

    final userIndex = _users.indexWhere((u) => u['id'] == id);
    if (userIndex == -1) {
      final response = ApiResponse.notFound('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }

    try {
      await request.readAsString();
      _users[userIndex]['name'] = 'Auto Updated User';

      final response = ApiResponse.success(
        _users[userIndex],
        'User updated via auto-discovery',
      );
      return jsonResponse(response.toJson());
    } catch (e) {
      final response = ApiResponse.error('Failed to update user');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  /// Auto-discovered DELETE endpoint for deleting users
  @Delete(path: '/{id}')
  Future<Response> deleteUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Auto-discovered: Deleting user $id');

    final userIndex = _users.indexWhere((u) => u['id'] == id);
    if (userIndex == -1) {
      final response = ApiResponse.notFound('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }

    _users.removeAt(userIndex);

    final response = ApiResponse.success(null, 'User deleted via auto-discovery');
    return jsonResponse(response.toJson());
  }

  /// Auto-discovered method mapping for routing
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'getUsers': getUsers,
      'getUser': getUser,
      'createUser': createUser,
      'updateUser': updateUser,
      'deleteUser': deleteUser,
    };
  }
}

/// Additional controller to demonstrate multiple auto-discovered controllers
@RestController(basePath: '/api/v1/health')
class HealthController extends BaseController {
  
  /// Auto-discovered health check endpoint
  @Get(path: '/')
  Future<Response> healthCheck(Request request) async {
    logRequest(request, 'Auto-discovered: Health check');

    final response = ApiResponse.success(
      {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'auto_discovery': 'enabled',
        'server': 'api_kit v0.1.0+',
      },
      'Health check via auto-discovery',
    );
    return jsonResponse(response.toJson());
  }
  
  /// Auto-discovered method mapping
  Map<String, Future<Response> Function(Request)> getMethodsMap() {
    return {
      'healthCheck': healthCheck,
    };
  }
}

/// Benefits of Auto-Discovery System:
///
/// 🎯 **Zero Manual Registration**
/// - Controllers discovered automatically via @RestController annotations
/// - No need to maintain controllerList in main()
/// - Similar experience to Spring Boot @Component scanning
///
/// ⚡ **Performance Optimized**
/// - Single static analysis run (not per controller)
/// - Cached controller discovery results
/// - Efficient batch registration of endpoints
///
/// 🔧 **Developer Experience**
/// - Fluent configuration API with method chaining
/// - Clean console output with professional formatting
/// - Optional endpoints table display
/// - Configuration before analysis (proper order)
///
/// 🏗️ **Architecture Benefits**
/// - Clear separation: Config → Discovery → Registration → Start
/// - Eliminates double mount path issues
/// - AOT compatible with no mirrors usage in routing
/// - Maintains backward compatibility with legacy constructor
///
/// 🧪 **Testing & Deployment**
/// - All existing tests continue to pass
/// - Auto-discovery works with dart compile exe
/// - Production-ready with comprehensive error handling
/// - Detailed logging for debugging discovery issues