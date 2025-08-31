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
final class QueryParam {
  final String name;
  final bool required;
  final dynamic defaultValue;
  final String? description;

  const QueryParam(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });
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

/// Anotación para headers
final class RequestHeader {
  final String name;
  final bool required;
  final String? defaultValue;
  final String? description;

  const RequestHeader(
    this.name, {
    this.required = false,
    this.defaultValue,
    this.description,
  });
}