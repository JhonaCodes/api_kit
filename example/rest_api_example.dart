import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_secure_api/rest_api.dart';
import 'package:logger_rs/logger_rs.dart';

void main() async {
  // Create a sample controller
  final userController = UserController();
  
  // Create main router
  final router = Router();
  router.mount('/api/v1/users', userController.router);
  
  // Add health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('{"status": "healthy"}',
        headers: {'content-type': 'application/json'});
  });

  // Create secure server with production config
  final server = SecureServer(
    config: SecurityConfig.development(), // Use development for example
    router: router,
  );

  // Start the server
  final result = await server.start(
    host: 'localhost',
    port: 8080,
  );

  result.when(
    ok: (httpServer) {
      Log.i('Example server running on http://localhost:8080');
      Log.i('Try: curl http://localhost:8080/health');
      Log.i('Try: curl http://localhost:8080/api/v1/users');
      Log.i('Try: curl -X POST http://localhost:8080/api/v1/users -d \'{"name":"John"}\'');
      
      // Handle graceful shutdown
      ProcessSignal.sigint.watch().listen((_) async {
        Log.i('Shutting down server...');
        await server.stop(httpServer);
        exit(0);
      });
    },
    err: (apiErr) {
      Log.e('Failed to start server', error: apiErr.exception, stackTrace: apiErr.stackTrace);
      exit(1);
    },
  );
}

/// Example user controller demonstrating automatic annotation-based routing.
@Controller('/api/v1/users')
class UserController extends BaseController {
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': '2', 'name': 'Bob', 'email': 'bob@example.com'},
  ];

  // When reflection is available, routes are built automatically from annotations!
  // When reflection is not available, we provide a manual fallback.
  @override
  Router get router {
    // Check if reflection is available
    if (ReflectionHelper.isReflectionAvailable) {
      Log.i('Using automatic annotation-based routing');
      return super.router;
    }
    
    // Fallback to manual registration when reflection is not available
    Log.w('Reflection not available - using manual route registration');
    final manualRouter = Router();
    manualRouter.get('/', getUsers);
    manualRouter.get('/<id>', getUser);
    manualRouter.post('/', createUser);
    manualRouter.put('/<id>', updateUser);
    manualRouter.delete('/<id>', deleteUser);
    return manualRouter;
  }

  @GET('/')
  Future<Response> getUsers(Request request) async {
    logRequest(request, 'Getting all users');
    
    final response = ApiResponse.success(_users, 'Users retrieved successfully');
    return jsonResponse(response.toJson());
  }

  @GET('/<id>')
  Future<Response> getUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Getting user $id');
    
    final user = _users.firstWhere(
      (u) => u['id'] == id,
      orElse: () => {},
    );
    
    if (user.isEmpty) {
      final response = ApiResponse.notFound('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    final response = ApiResponse.success(user);
    return jsonResponse(response.toJson());
  }

  @POST('/')
  Future<Response> createUser(Request request) async {
    logRequest(request, 'Creating new user');
    
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        final response = ApiResponse.badRequest('Request body is required');
        return jsonResponse(response.toJson(), statusCode: 400);
      }
      
      // In a real app, you would validate and parse the JSON here
      final newUser = {
        'id': '${_users.length + 1}',
        'name': 'New User',
        'email': 'new@example.com',
      };
      
      _users.add(newUser);
      
      final response = ApiResponse.success(newUser, 'User created successfully');
      return jsonResponse(response.toJson(), statusCode: 201);
    } catch (e) {
      Log.e('Error creating user', error: e);
      final response = ApiResponse.error('Failed to create user');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  @PUT('/<id>')
  Future<Response> updateUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Updating user $id');
    
    final userIndex = _users.indexWhere((u) => u['id'] == id);
    if (userIndex == -1) {
      final response = ApiResponse.notFound('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    try {
      await request.readAsString();
      // In a real app, you would parse and validate the JSON here
      _users[userIndex]['name'] = 'Updated User';
      
      final response = ApiResponse.success(_users[userIndex], 'User updated successfully');
      return jsonResponse(response.toJson());
    } catch (e) {
      Log.e('Error updating user', error: e);
      final response = ApiResponse.error('Failed to update user');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  @DELETE('/<id>')
  Future<Response> deleteUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Deleting user $id');
    
    final userIndex = _users.indexWhere((u) => u['id'] == id);
    if (userIndex == -1) {
      final response = ApiResponse.notFound('User not found');
      return jsonResponse(response.toJson(), statusCode: 404);
    }
    
    _users.removeAt(userIndex);
    
    final response = ApiResponse.success(null, 'User deleted successfully');
    return jsonResponse(response.toJson());
  }
}
