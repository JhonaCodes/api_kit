/// Ejemplo de uso de @PathParam
/// Demuestra cómo capturar parámetros de la URL como /users/{id}/orders/{orderId}
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🛤️  PathParam Example - Capturing URL parameters');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8090,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test PathParam endpoints:');
      print('   curl http://localhost:8090/api/users/123');
      print('   curl http://localhost:8090/api/users/456/orders/789');
      print('   curl http://localhost:8090/api/products/electronics/items/laptop');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demostrando el uso de PathParam
@RestController(basePath: '/api')
class PathParamController extends BaseController {

  /// Ejemplo básico: un solo path parameter
  @Get(path: '/users/{id}')
  Future<Response> getUserById(
    Request request,
    @PathParam('id', description: 'User unique identifier') String userId,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'User retrieved successfully',
      'path_param': {
        'parameter_name': 'id',
        'parameter_value': userId,
        'parameter_type': 'String',
      },
      'user': {
        'id': userId,
        'name': 'User #$userId',
        'email': 'user$userId@example.com',
        'status': 'active',
      },
    }));
  }

  /// Ejemplo con múltiples path parameters
  @Get(path: '/users/{userId}/orders/{orderId}')
  Future<Response> getUserOrder(
    Request request,
    @PathParam('userId', description: 'User ID') String userId,
    @PathParam('orderId', description: 'Order ID') String orderId,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'User order retrieved successfully',
      'path_params': {
        'userId': userId,
        'orderId': orderId,
      },
      'order': {
        'id': orderId,
        'user_id': userId,
        'status': 'completed',
        'total': 99.99,
        'items_count': 3,
      },
    }));
  }

  /// Ejemplo con path parameters más complejos
  @Get(path: '/products/{category}/items/{itemName}')
  Future<Response> getProductItem(
    Request request,
    @PathParam('category', description: 'Product category') String category,
    @PathParam('itemName', description: 'Item name') String itemName,
  ) async {
    return jsonResponse(jsonEncode({
      'message': 'Product item found',
      'path_params': {
        'category': category,
        'itemName': itemName,
      },
      'product': {
        'name': itemName,
        'category': category,
        'price': 299.99,
        'in_stock': true,
        'description': 'High-quality $itemName in $category category',
      },
    }));
  }
}