import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:logger_rs/logger_rs.dart';

/// Example demonstration of api_kit framework with a complete REST API server.
/// 
/// This example showcases the main features of api_kit:
/// - Annotation-based routing with controllers
/// - Clean server configuration
/// - Built-in error handling with Result pattern
/// - Graceful shutdown handling
/// - Production-ready development configuration
/// 
/// ## Running the Example
/// 
/// 1. Run with: `dart run example/example.dart`
/// 2. Test endpoints:
///    - GET http://localhost:8080/health (health check)
///    - GET http://localhost:8080/api/v1/users (list users)
///    - POST http://localhost:8080/api/v1/users (create user)
///    - GET http://localhost:8080/api/v1/users/1 (get specific user)
///    - PUT http://localhost:8080/api/v1/users/1 (update user)
///    - DELETE http://localhost:8080/api/v1/users/1 (delete user)
/// 
/// ## Server Configuration
/// 
/// Uses `ServerConfig.development()` which includes:
/// - Permissive CORS for local development
/// - Verbose request logging
/// - Development-friendly error messages
/// 
/// For production, use `ServerConfig.production()` instead.
void main() async {
  // Create API server with development configuration
  final server = ApiServer(
    config: ServerConfig.development(), // Use development for example
  );

  // Start the server with controller list (simple_rest style!)
  final result = await server.start(
    host: 'localhost',
    port: 8080,
    controllerList: [
      UserController(), // Just add controllers to the list!
      // ProductController(), // Add more controllers here
      // OrderController(),
    ],
  );

  result.when(
    ok: (httpServer) {
      Log.i('Example server running on http://localhost:8080');
      Log.i('Try: curl http://localhost:8080/health');
      Log.i('Try: curl http://localhost:8080/api/v1/users');
      Log.i(
        'Try: curl -X POST http://localhost:8080/api/v1/users -d \'{"name":"John"}\'',
      );

      // Handle graceful shutdown
      ProcessSignal.sigint.watch().listen((_) async {
        Log.i('Shutting down server...');
        await server.stop(httpServer);
        exit(0);
      });
    },
    err: (apiErr) {
      Log.e(
        'Failed to start server',
        error: apiErr.exception,
        stackTrace: apiErr.stackTrace,
      );
      exit(1);
    },
  );
}

/// Example user controller demonstrating annotation-based REST API routing.
/// 
/// This controller showcases the main features of api_kit controllers:
/// - Automatic route registration with `@Controller` annotation
/// - HTTP method annotations (`@GET`, `@POST`, `@PUT`, `@DELETE`)
/// - Path parameter extraction with angle brackets (`<id>`)
/// - Built-in request logging and error handling
/// - Standardized JSON response format with `ApiResponse`
/// 
/// ## Supported Endpoints
/// 
/// - `GET /api/v1/users` - List all users
/// - `GET /api/v1/users/<id>` - Get user by ID
/// - `POST /api/v1/users` - Create new user
/// - `PUT /api/v1/users/<id>` - Update existing user
/// - `DELETE /api/v1/users/<id>` - Delete user by ID
/// 
/// ## Implementation Notes
/// 
/// - Uses in-memory storage for demonstration (replace with database in production)
/// - Includes proper HTTP status codes (200, 201, 404, 400, 500)
/// - Validates required parameters and request bodies
/// - Provides consistent error handling and logging
/// - Returns standardized JSON responses using `ApiResponse` pattern
@Controller('/api/v1/users')
class UserController extends BaseController {
  /// In-memory user storage for demonstration purposes.
  /// In production, replace with proper database integration.
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': '2', 'name': 'Bob', 'email': 'bob@example.com'},
  ];

  // No need to override router - it's built automatically from annotations!

  /// Retrieves a list of all users.
  /// 
  /// Returns a JSON array containing all users with their basic information.
  /// This endpoint demonstrates the simplest GET request handling.
  /// 
  /// **HTTP Method:** GET  
  /// **Endpoint:** `/api/v1/users`  
  /// **Response:** 200 OK with user list  
  /// 
  /// Example response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "message": "Users retrieved successfully",
  ///   "data": [
  ///     {"id": "1", "name": "Alice", "email": "alice@example.com"},
  ///     {"id": "2", "name": "Bob", "email": "bob@example.com"}
  ///   ]
  /// }
  /// ```
  @GET('/')
  Future<Response> getUsers(Request request) async {
    logRequest(request, 'Getting all users');

    final response = ApiResponse.success(
      _users,
      'Users retrieved successfully',
    );
    return jsonResponse(response.toJson());
  }

  /// Retrieves a specific user by their ID.
  /// 
  /// Demonstrates path parameter extraction using angle brackets syntax (`<id>`).
  /// The framework automatically extracts the ID from the URL path and makes it
  /// available through `getRequiredParam()`.
  /// 
  /// **HTTP Method:** GET  
  /// **Endpoint:** `/api/v1/users/<id>`  
  /// **Parameters:**
  /// - `id` (path): User ID to retrieve
  /// 
  /// **Responses:**
  /// - 200 OK: User found and returned
  /// - 404 Not Found: User with specified ID doesn't exist
  /// 
  /// Example successful response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {"id": "1", "name": "Alice", "email": "alice@example.com"}
  /// }
  /// ```
  /// 
  /// Example error response:
  /// ```json
  /// {
  ///   "success": false,
  ///   "message": "User not found"
  /// }
  /// ```
  @GET('/<id>')
  Future<Response> getUser(Request request) async {
    final id = getRequiredParam(request, 'id');
    logRequest(request, 'Getting user $id');

    final user = _users.firstWhere((u) => u['id'] == id, orElse: () => {});

    final response = user.isEmpty
        ? ApiResponse.notFound('User not found')
        : ApiResponse.success(user);

    final statusCode = user.isEmpty ? 404 : 200;
    return jsonResponse(response.toJson(), statusCode: statusCode);
  }

  /// Creates a new user from the provided JSON data.
  /// 
  /// Demonstrates POST request handling with request body validation.
  /// Shows proper HTTP status code usage (201 Created for successful creation).
  /// 
  /// **HTTP Method:** POST  
  /// **Endpoint:** `/api/v1/users`  
  /// **Request Body:** JSON object with user data  
  /// 
  /// **Responses:**
  /// - 201 Created: User successfully created
  /// - 400 Bad Request: Missing or invalid request body
  /// 
  /// Expected request body format:
  /// ```json
  /// {
  ///   "name": "John Doe",
  ///   "email": "john@example.com"
  /// }
  /// ```
  /// 
  /// Example successful response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "message": "User created successfully",
  ///   "data": {
  ///     "id": "3",
  ///     "name": "New User",
  ///     "email": "new@example.com"
  ///   }
  /// }
  /// ```
  /// 
  /// Note: This example uses simplified user creation for demonstration.
  /// In production, implement proper JSON parsing, validation, and database storage.
  @POST('/')
  Future<Response> createUser(Request request) async {
    logRequest(request, 'Creating new user');

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
  }

  /// Updates an existing user with new data.
  /// 
  /// Combines path parameter extraction with request body processing.
  /// Demonstrates proper error handling with try-catch blocks and
  /// different HTTP status codes for various scenarios.
  /// 
  /// **HTTP Method:** PUT  
  /// **Endpoint:** `/api/v1/users/<id>`  
  /// **Parameters:**
  /// - `id` (path): User ID to update
  /// 
  /// **Request Body:** JSON object with updated user data  
  /// 
  /// **Responses:**
  /// - 200 OK: User successfully updated
  /// - 404 Not Found: User with specified ID doesn't exist
  /// - 500 Internal Server Error: Update operation failed
  /// 
  /// Expected request body format:
  /// ```json
  /// {
  ///   "name": "Updated Name",
  ///   "email": "updated@example.com"
  /// }
  /// ```
  /// 
  /// Example successful response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "message": "User updated successfully",
  ///   "data": {
  ///     "id": "1",
  ///     "name": "Updated User",
  ///     "email": "alice@example.com"
  ///   }
  /// }
  /// ```
  /// 
  /// Note: This example demonstrates basic update flow.
  /// In production, implement proper JSON parsing, field validation,
  /// and database transactions with rollback capability.
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

      final response = ApiResponse.success(
        _users[userIndex],
        'User updated successfully',
      );
      return jsonResponse(response.toJson());
    } catch (e) {
      Log.e('Error updating user', error: e);
      final response = ApiResponse.error('Failed to update user');
      return jsonResponse(response.toJson(), statusCode: 500);
    }
  }

  /// Deletes a user by their ID.
  /// 
  /// Demonstrates DELETE operation with proper resource validation.
  /// Shows how to handle deletion scenarios and return appropriate
  /// responses for both successful and failed operations.
  /// 
  /// **HTTP Method:** DELETE  
  /// **Endpoint:** `/api/v1/users/<id>`  
  /// **Parameters:**
  /// - `id` (path): User ID to delete
  /// 
  /// **Responses:**
  /// - 200 OK: User successfully deleted
  /// - 404 Not Found: User with specified ID doesn't exist
  /// 
  /// Example successful response:
  /// ```json
  /// {
  ///   "success": true,
  ///   "message": "User deleted successfully",
  ///   "data": null
  /// }
  /// ```
  /// 
  /// Example error response:
  /// ```json
  /// {
  ///   "success": false,
  ///   "message": "User not found"
  /// }
  /// ```
  /// 
  /// Note: This example performs immediate deletion from memory.
  /// In production, consider implementing:
  /// - Soft deletion (marking as deleted rather than removing)
  /// - Transaction-based deletion for data integrity
  /// - Cascade deletion handling for related records
  /// - Audit logging for deletion tracking
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
