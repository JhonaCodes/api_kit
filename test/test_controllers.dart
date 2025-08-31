import 'package:api_kit/api_kit.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

/// Test controller for hybrid routing system validation
@RestController(basePath: '/api/test')
class TestController extends BaseController {
  
  @Get(path: '/hello')
  Future<Response> hello(Request request) async {
    return jsonResponse(jsonEncode({'message': 'Hello World'}));
  }
  
  @Post(path: '/echo')
  Future<Response> echo(Request request) async {
    final body = await request.readAsString();
    return jsonResponse(jsonEncode({'echo': body}));
  }
  
  @Get(path: '/health')
  @JWTPublic()
  Future<Response> health(Request request) async {
    return jsonResponse(jsonEncode({'status': 'healthy'}));
  }
}

/// Test controller with JWT annotations
@RestController(basePath: '/api/secure')
@JWTController([
  MyAdminValidator(),
], requireAll: true)
class JWTTestController extends BaseController {
  
  @Get(path: '/admin')
  Future<Response> adminEndpoint(Request request) async {
    return jsonResponse(jsonEncode({'message': 'Admin only'}));
  }
  
  @Post(path: '/users')
  @JWTEndpoint([
    const MyAdminValidator(),
  ], requireAll: true)
  Future<Response> createUser(Request request) async {
    final body = await request.readAsString();
    final userData = jsonDecode(body);
    return jsonResponse(jsonEncode({'created': userData}));
  }
  
  @Get(path: '/public')
  @JWTPublic()
  Future<Response> publicEndpoint(Request request) async {
    return jsonResponse(jsonEncode({'message': 'Public access'}));
  }
}

/// Simple test controller without annotations
class SimpleController extends BaseController {
  
  @override
  Future<Router> buildRouter() async {
    final router = Router();
    
    router.get('/simple', (Request request) async {
      return jsonResponse(jsonEncode({'message': 'Simple controller'}));
    });
    
    return router;
  }
}