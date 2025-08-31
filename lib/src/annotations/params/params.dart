// lib/annotations/params/params.dart

/// Annotation for general parameters
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

/// Annotation for path parameters (/users/{id})
final class PathParam {
  final String name;
  final String? description;

  const PathParam(this.name, {this.description});
}

/// Annotation for query parameters (?page=1&size=10)
///
/// Specific use: @QueryParam('page') int page
/// Use for all: @QueryParam.all() ```Map<String, String>``` allParams
final class QueryParam {
  final String? name; // Optional now - null means "all params"
  final bool required;
  final dynamic defaultValue;
  final String? description;

  /// Constructor for a specific parameter (current behavior)
  const QueryParam(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });

  /// Constructor to get ALL query parameters as ```Map<String, String>```
  /// Example: ```@QueryParam.all() Map<String, String> allQueryParams```
  const QueryParam.all({
    this.required = false,
    this.description = 'All query parameters as Map<String, String>',
  }) : name = null,
       defaultValue = null;
}

/// Annotation for the request body
final class RequestBody {
  final bool required;
  final String? description;

  const RequestBody({this.required = true, this.description});
}

/// Annotation for HTTP headers
///
/// Specific use: @RequestHeader('Authorization') String authHeader
/// Use for all: ```@RequestHeader.all() Map<String, String> allHeaders```
final class RequestHeader {
  final String? name; // Optional now - null means "all headers"
  final bool required;
  final String? defaultValue;
  final String? description;

  /// Constructor for a specific header (current behavior)
  const RequestHeader(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });

  /// Constructor to get ALL headers as ```Map<String, String>```
  /// Example: ```@RequestHeader.all() Map<String, String> allHeaders```
  const RequestHeader.all({
    this.required = false,
    this.description = 'All HTTP headers as Map<String, String>',
  }) : name = null,
       defaultValue = null;
}

/// Annotation for the HTTP method (GET, POST, PUT, etc.)
final class RequestMethod {
  final String? description;

  /// Gets the HTTP method as a String (GET, POST, PUT, DELETE, etc.)
  /// Example: @RequestMethod() String httpMethod
  const RequestMethod({
    this.description = 'HTTP method (GET, POST, PUT, DELETE, etc.)',
  });
}

/// Annotation for the request path
final class RequestPath {
  final String? description;

  /// Gets the full request path as a String
  /// Example: @RequestPath() String requestPath
  const RequestPath({this.description = 'Request path (e.g., /api/users/123)'});
}

/// Annotation for the request host
final class RequestHost {
  final String? description;

  /// Gets the request host as a String
  /// Example: @RequestHost() String host
  const RequestHost({
    this.description = 'Request host (e.g., localhost, api.example.com)',
  });
}

/// Annotation for the request port
final class RequestPort {
  final String? description;

  /// Gets the request port as an int
  /// Example: @RequestPort() int port
  const RequestPort({this.description = 'Request port (e.g., 8080, 443)'});
}

/// Annotation for the request scheme (http/https)
final class RequestScheme {
  final String? description;

  /// Gets the request scheme as a String (http or https)
  /// Example: @RequestScheme() String scheme
  const RequestScheme({this.description = 'Request scheme (http or https)'});
}

/// Annotation for the full request URL
final class RequestUrl {
  final String? description;

  /// Gets the full request URL as a Uri
  /// Example: @RequestUrl() Uri fullUrl
  const RequestUrl({this.description = 'Complete request URL as Uri object'});
}

/// Annotation for the request context
///
/// Specific use: ```@RequestContext('jwt_payload') Map<String, dynamic> jwt```
/// Use for all: ```@RequestContext.all() Map<String, dynamic> allContext```
final class RequestContext {
  final String?
  key; // If key is specified, gets only that value from the context
  final String? description;

  /// Constructor to get a specific value from the context
  /// Example: ```@RequestContext('jwt_payload') Map<String, dynamic> jwtData```
  const RequestContext(this.key, {this.description});

  /// Constructor to get the ENTIRE context as ```Map<String, dynamic>```
  /// Example: ```@RequestContext.all() Map<String, dynamic> allContext```
  const RequestContext.all({
    this.description = 'Complete request context as Map<String, dynamic>',
  }) : key = null;
}
