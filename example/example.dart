import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:logger_rs/logger_rs.dart';

/// 🚀 api_kit Clean Example - Modern Annotation-Based API
///
/// This example demonstrates the CURRENT BEST PRACTICES for api_kit:
/// - ✅ Use enhanced parameter annotations (NO Request request needed)
/// - ✅ Direct Ok/Err pattern with result_controller
/// - ✅ Clean declarative endpoints
/// - ✅ JWT authentication integration
/// - ✅ Comprehensive parameter handling
///
/// ## 🎯 Key Features Demonstrated:
/// - @RequestHeader.all() - All headers automatically
/// - @QueryParam.all() - All query parameters automatically
/// - @RequestContext('jwt_payload') - Direct JWT access
/// - @RequestMethod(), @RequestPath() - Request info directly
/// - ApiKit.ok() / ApiKit.err() - Direct result creation
/// - ApiResponseBuilder.fromResult() - Response conversion
///
/// ## Running the Example:
/// ```bash
/// dart run example/example.dart
/// ```
///
/// ## Test Endpoints:
/// ```bash
/// # GET users list
/// curl "http://localhost:8080/api/v1/users?page=1&limit=10"
///
/// # GET user by ID
/// curl "http://localhost:8080/api/v1/users/1"
///
/// # POST create user
/// curl -X POST "http://localhost:8080/api/v1/users" \
///   -H "Content-Type: application/json" \
///   -d '{"name":"John Doe","email":"john@example.com"}'
///
/// # PUT update user
/// curl -X PUT "http://localhost:8080/api/v1/users/1" \
///   -H "Content-Type: application/json" \
///   -d '{"name":"Jane Doe"}'
///
/// # DELETE user
/// curl -X DELETE "http://localhost:8080/api/v1/users/1"
/// ```

void main() async {
  // Create API server with development configuration
  final server = ApiServer(config: ServerConfig.development());

  // Start server with controller
  final result = await server.start(host: 'localhost', port: 8080);

  result.when(
    ok: (httpServer) {
      Log.i('🚀 Clean API Server running on http://localhost:8080');
      Log.i('📖 API Documentation: http://localhost:8080/api/v1/users');
      Log.i('🛠️  Test endpoints with curl commands above');

      // Graceful shutdown
      ProcessSignal.sigint.watch().listen((sig) async {
        Log.i('🛑 Shutting down server...');
        await httpServer.close(force: false);
        exit(0);
      });
    },
    err: (error) {
      Log.e('❌ Failed to start server: ${error.msm}');
      exit(1);
    },
  );
}

/// 🎯 Modern REST Controller - NO Request Parameters Needed!
///
/// This controller demonstrates the latest api_kit patterns:
/// - Enhanced parameter annotations eliminate Request parameter
/// - Direct result_controller integration
/// - Clean, declarative endpoint definitions
@RestController(basePath: '/api/v1/users')
class UsersController extends BaseController {
  // In-memory data for demo (use database in production)
  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': 'Alice Johnson',
      'email': 'alice@example.com',
      'created_at': '2024-01-15T10:00:00Z',
    },
    {
      'id': '2',
      'name': 'Bob Smith',
      'email': 'bob@example.com',
      'created_at': '2024-01-16T14:30:00Z',
    },
    {
      'id': '3',
      'name': 'Carol Brown',
      'email': 'carol@example.com',
      'created_at': '2024-01-17T09:15:00Z',
    },
  ];

  /// 📋 GET /api/v1/users - List all users with filtering
  ///
  /// ✅ MODERN PATTERN: No Request parameter needed!
  /// - @QueryParam.all() captures ALL query parameters
  /// - @RequestHeader.all() captures ALL headers
  /// - @RequestMethod() and @RequestPath() for request info
  /// - Direct ApiKit.ok() result creation
  @Get(path: '/')
  Future<Response> getUsers(
    @QueryParam.all() Map<String, String> allQueryParams,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
    @RequestPath() String path,
  ) async {
    // Extract pagination parameters
    final pageStr = allQueryParams['page'] ?? '1';
    final limitStr = allQueryParams['limit'] ?? '10';
    final searchQuery = allQueryParams['search'];

    final page = int.tryParse(pageStr) ?? 1;
    final limit = int.tryParse(limitStr) ?? 10;

    // Apply search filter if provided
    var filteredUsers = _users;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredUsers = _users
          .where(
            (user) =>
                user['name'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                user['email'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    final paginatedUsers = filteredUsers.sublist(
      startIndex.clamp(0, filteredUsers.length),
      endIndex.clamp(0, filteredUsers.length),
    );

    // ✅ Direct result creation - no safeExecute needed
    final result = ApiKit.ok({
      'users': paginatedUsers,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': filteredUsers.length,
        'total_pages': (filteredUsers.length / limit).ceil(),
      },
      'filters_applied': {
        'search': searchQuery,
        'has_search': searchQuery != null,
      },
      'request_info': {
        'method': method,
        'path': path,
        'query_params_count': allQueryParams.length,
        'headers_count': allHeaders.length,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// 👤 GET /api/v1/users/{id} - Get specific user
  ///
  /// ✅ MODERN PATTERN: Path parameter with enhanced annotations
  @Get(path: '/{id}')
  Future<Response> getUserById(
    @PathParam('id') String userId,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestPath() String path,
  ) async {
    // Find user by ID
    final user = _users.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => <String, dynamic>{},
    );

    // ✅ Direct error handling with ApiKit
    if (user.isEmpty) {
      final result = ApiKit.notFound<Map<String, dynamic>>(
        'User with ID $userId not found',
      );
      return ApiResponseBuilder.fromResult(result);
    }

    // ✅ Success response
    final result = ApiKit.ok({
      'user': user,
      'request_info': {
        'path': path,
        'user_id': userId,
        'headers_received': allHeaders.keys.toList(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// ➕ POST /api/v1/users - Create new user
  ///
  /// ✅ MODERN PATTERN: Request body parsing with validation
  @Post(path: '/')
  Future<Response> createUser(
    @RequestBody() Map<String, dynamic> userData,
    @RequestHeader.all() Map<String, String> allHeaders,
    @RequestMethod() String method,
  ) async {
    try {
      // ✅ Direct validation - no safeExecuteAsync needed
      if (userData['name'] == null ||
          userData['name'].toString().trim().isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Name is required',
          validations: {'name': 'Name cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      if (userData['email'] == null ||
          userData['email'].toString().trim().isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Email is required',
          validations: {'email': 'Email cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Check for duplicate email
      final existingUser = _users.firstWhere(
        (u) => u['email'] == userData['email'],
        orElse: () => <String, dynamic>{},
      );

      if (existingUser.isNotEmpty) {
        final result = ApiKit.conflict<Map<String, dynamic>>(
          'User with this email already exists',
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Create new user
      final newUser = {
        'id': '${_users.length + 1}',
        'name': userData['name'].toString().trim(),
        'email': userData['email'].toString().trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      _users.add(newUser);

      // ✅ Success response
      final result = ApiKit.ok({
        'user': newUser,
        'message': 'User created successfully',
        'request_info': {
          'method': method,
          'content_type': allHeaders['content-type'],
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      // ✅ Error handling with full context
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to create user: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }

  /// ✏️ PUT /api/v1/users/{id} - Update existing user
  ///
  /// ✅ MODERN PATTERN: Combining path params with request body
  @Put(path: '/{id}')
  Future<Response> updateUser(
    @PathParam('id') String userId,
    @RequestBody() Map<String, dynamic> updateData,
    @RequestHeader.all() Map<String, String> allHeaders,
  ) async {
    try {
      // Find existing user
      final userIndex = _users.indexWhere((u) => u['id'] == userId);

      if (userIndex == -1) {
        final result = ApiKit.notFound<Map<String, dynamic>>(
          'User with ID $userId not found',
        );
        return ApiResponseBuilder.fromResult(result);
      }

      // Update user data
      final existingUser = Map<String, dynamic>.from(_users[userIndex]);

      if (updateData['name'] != null) {
        existingUser['name'] = updateData['name'].toString().trim();
      }

      if (updateData['email'] != null) {
        final newEmail = updateData['email'].toString().trim();

        // Check for duplicate email (excluding current user)
        final duplicateUser = _users.firstWhere(
          (u) => u['email'] == newEmail && u['id'] != userId,
          orElse: () => <String, dynamic>{},
        );

        if (duplicateUser.isNotEmpty) {
          final result = ApiKit.conflict<Map<String, dynamic>>(
            'Email already in use by another user',
          );
          return ApiResponseBuilder.fromResult(result);
        }

        existingUser['email'] = newEmail;
      }

      existingUser['updated_at'] = DateTime.now().toIso8601String();
      _users[userIndex] = existingUser;

      // ✅ Success response
      final result = ApiKit.ok({
        'user': existingUser,
        'message': 'User updated successfully',
        'changes_applied': updateData.keys.toList(),
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to update user: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }

  /// 🗑️ DELETE /api/v1/users/{id} - Delete user
  ///
  /// ✅ MODERN PATTERN: Simple deletion with validation
  @Delete(path: '/{id}')
  Future<Response> deleteUser(
    @PathParam('id') String userId,
    @RequestPath() String path,
    @RequestMethod() String method,
  ) async {
    // Find user to delete
    final userIndex = _users.indexWhere((u) => u['id'] == userId);

    if (userIndex == -1) {
      final result = ApiKit.notFound<Map<String, dynamic>>(
        'User with ID $userId not found',
      );
      return ApiResponseBuilder.fromResult(result);
    }

    final deletedUser = _users.removeAt(userIndex);

    // ✅ Success response with deletion info
    final result = ApiKit.ok({
      'message': 'User deleted successfully',
      'deleted_user': {
        'id': deletedUser['id'],
        'name': deletedUser['name'],
        'deleted_at': DateTime.now().toIso8601String(),
      },
      'remaining_users': _users.length,
      'request_info': {'method': method, 'path': path},
    });

    return ApiResponseBuilder.fromResult(result);
  }
}
