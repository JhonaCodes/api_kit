// lib/annotations/params/params.dart

/// Anotación para parámetros generales
final class Param {
  final String name;
  final bool required;
  final dynamic defaultValue;
  final String? description;

  const Param(
    this.name, {
    this.required = true,
    this.defaultValue,
    this.description,
  });
}

/// Anotación para parámetros de path (/users/{id})
final class PathParam {
  final String name;
  final String? description;

  const PathParam(
    this.name, {
    this.description,
  });
}

/// Anotación para parámetros de query (?page=1&size=10)
/// 
/// Uso específico: @QueryParam('page') int page
/// Uso para todos: @QueryParam.all() Map<String, String> allParams
final class QueryParam {
  final String? name;  // Opcional ahora - null significa "todos los params"
  final bool required;
  final dynamic defaultValue;
  final String? description;

  /// Constructor para parámetro específico (comportamiento actual)
  const QueryParam(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });
  
  /// Constructor para obtener TODOS los query parameters como Map<String, String>
  /// Ejemplo: @QueryParam.all() Map<String, String> allQueryParams
  const QueryParam.all({
    this.required = false,
    this.description = 'All query parameters as Map<String, String>',
  }) : name = null, defaultValue = null;
}

/// Anotación para el body de la request
final class RequestBody {
  final bool required;
  final String? description;

  const RequestBody({
    this.required = true,
    this.description,
  });
}

/// Anotación para headers HTTP
/// 
/// Uso específico: @RequestHeader('Authorization') String authHeader
/// Uso para todos: @RequestHeader.all() Map<String, String> allHeaders
final class RequestHeader {
  final String? name;  // Opcional ahora - null significa "todos los headers"
  final bool required;
  final String? defaultValue;
  final String? description;

  /// Constructor para header específico (comportamiento actual)
  const RequestHeader(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });
  
  /// Constructor para obtener TODOS los headers como Map<String, String>
  /// Ejemplo: @RequestHeader.all() Map<String, String> allHeaders
  const RequestHeader.all({
    this.required = false,
    this.description = 'All HTTP headers as Map<String, String>',
  }) : name = null, defaultValue = null;
}

/// Anotación para el método HTTP (GET, POST, PUT, etc.)
final class RequestMethod {
  final String? description;
  
  /// Obtiene el método HTTP como String (GET, POST, PUT, DELETE, etc.)
  /// Ejemplo: @RequestMethod() String httpMethod
  const RequestMethod({
    this.description = 'HTTP method (GET, POST, PUT, DELETE, etc.)',
  });
}

/// Anotación para la ruta/path de la request
final class RequestPath {
  final String? description;
  
  /// Obtiene la ruta completa de la request como String
  /// Ejemplo: @RequestPath() String requestPath
  const RequestPath({
    this.description = 'Request path (e.g., /api/users/123)',
  });
}

/// Anotación para el host del request
final class RequestHost {
  final String? description;
  
  /// Obtiene el host del request como String
  /// Ejemplo: @RequestHost() String host
  const RequestHost({
    this.description = 'Request host (e.g., localhost, api.example.com)',
  });
}

/// Anotación para el puerto del request
final class RequestPort {
  final String? description;
  
  /// Obtiene el puerto del request como int
  /// Ejemplo: @RequestPort() int port
  const RequestPort({
    this.description = 'Request port (e.g., 8080, 443)',
  });
}

/// Anotación para el scheme del request (http/https)
final class RequestScheme {
  final String? description;
  
  /// Obtiene el scheme del request como String (http o https)
  /// Ejemplo: @RequestScheme() String scheme
  const RequestScheme({
    this.description = 'Request scheme (http or https)',
  });
}

/// Anotación para la URL completa del request
final class RequestUrl {
  final String? description;
  
  /// Obtiene la URL completa del request como Uri
  /// Ejemplo: @RequestUrl() Uri fullUrl
  const RequestUrl({
    this.description = 'Complete request URL as Uri object',
  });
}

/// Anotación para el context del request
/// 
/// Uso específico: @RequestContext('jwt_payload') Map<String, dynamic> jwt
/// Uso para todos: @RequestContext.all() Map<String, dynamic> allContext
final class RequestContext {
  final String? key;  // Si se especifica key, obtiene solo ese valor del context
  final String? description;
  
  /// Constructor para obtener un valor específico del context
  /// Ejemplo: @RequestContext('jwt_payload') Map<String, dynamic> jwtData
  const RequestContext(
    this.key, {
    this.description,
  });
  
  /// Constructor para obtener TODO el context como Map<String, dynamic>
  /// Ejemplo: @RequestContext.all() Map<String, dynamic> allContext
  const RequestContext.all({
    this.description = 'Complete request context as Map<String, dynamic>',
  }) : key = null;
}