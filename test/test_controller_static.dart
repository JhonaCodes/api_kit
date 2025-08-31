/// Test controller using the new static analysis system
import 'package:api_kit/api_kit.dart';

/// Test controller that uses the new static annotation system
@RestController(basePath: '/api/test')
class TestControllerStatic extends BaseController {
  
  /// Simple GET endpoint
  @Get(path: '/hello')
  Future<Response> getHello(Request request) async {
    return jsonResponse('{"message": "Hello from static analysis!"}');
  }
  
  /// GET endpoint with path parameter  
  @Get(path: '/user/{id}')
  Future<Response> getUser(Request request) async {
    return jsonResponse('{"user_id": "123", "name": "Test User"}');
  }
  
  /// POST endpoint
  @Post(
    path: '/users',
    description: 'Create a new user',
    statusCode: 201,
    requiresAuth: true,
  )
  Future<Response> createUser(Request request) async {
    return jsonResponse('{"created": true, "id": "456"}');
  }
  
  /// PUT endpoint
  @Put(
    path: '/users/{id}',
    description: 'Update user',
    requiresAuth: true,
  )
  Future<Response> updateUser(Request request) async {
    return jsonResponse('{"updated": true, "id": "123"}');
  }
  
  /// DELETE endpoint
  @Delete(
    path: '/users/{id}',
    description: 'Delete user',
    requiresAuth: true,
  )
  Future<Response> deleteUser(Request request) async {
    return Response.ok('{"deleted": true}');
  }
  
  /// Override to register methods with the dispatcher
  @override
  void registerMethods() {
    registerMethodsMap({
      'getHello': getHello,
      'getUser': getUser,
      'createUser': createUser,
      'updateUser': updateUser,
      'deleteUser': deleteUser,
    });
  }
}