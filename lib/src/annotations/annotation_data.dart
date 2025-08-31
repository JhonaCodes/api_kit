// lib/annotation_data.dart

/// Clase base para datos de anotaciones tipados
abstract class AnnotationData {
  const AnnotationData();
  
  /// Convierte el Map a una instancia tipada
  static AnnotationData fromMap(String annotationType, Map<String, dynamic> map) {
    return switch (annotationType) {
      // HTTP Methods
      'Get' => GetData.fromMap(map),
      'Post' => PostData.fromMap(map),
      'Put' => PutData.fromMap(map),
      'Patch' => PatchData.fromMap(map),
      'Delete' => DeleteData.fromMap(map),
      
      // Controllers
      'RestController' => RestControllerData.fromMap(map),
      'Service' => ServiceData.fromMap(map),
      'Repository' => RepositoryData.fromMap(map),
      
      // Parameters
      'Param' => ParamData.fromMap(map),
      'PathParam' => PathParamData.fromMap(map),
      'QueryParam' => QueryParamData.fromMap(map),
      'RequestBody' => RequestBodyData.fromMap(map),
      'RequestHeader' => RequestHeaderData.fromMap(map),
      
      _ => GenericAnnotationData(map),
    };
  }
}

// === HTTP METHOD DATA CLASSES ===

/// Datos específicos para @Get
class GetData extends AnnotationData {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;
  
  const GetData({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = false,
  });
  
  factory GetData.fromMap(Map<String, dynamic> map) {
    return GetData(
      path: map['path']?.toString() ?? '',
      description: map['description']?.toString(),
      statusCode: map['statusCode'] as int? ?? 200,
      requiresAuth: map['requiresAuth'] as bool? ?? false,
    );
  }
  
  @override
  String toString() => 'GetData(path: $path, description: $description)';
}

/// Datos específicos para @Post
class PostData extends AnnotationData {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;
  
  const PostData({
    required this.path,
    this.description,
    this.statusCode = 201,
    this.requiresAuth = false,
  });
  
  factory PostData.fromMap(Map<String, dynamic> map) {
    return PostData(
      path: map['path']?.toString() ?? '',
      description: map['description']?.toString(),
      statusCode: map['statusCode'] as int? ?? 201,
      requiresAuth: map['requiresAuth'] as bool? ?? false,
    );
  }
  
  @override
  String toString() => 'PostData(path: $path, description: $description)';
}

/// Datos específicos para @Put
class PutData extends AnnotationData {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;
  
  const PutData({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = true,
  });
  
  factory PutData.fromMap(Map<String, dynamic> map) {
    return PutData(
      path: map['path']?.toString() ?? '',
      description: map['description']?.toString(),
      statusCode: map['statusCode'] as int? ?? 200,
      requiresAuth: map['requiresAuth'] as bool? ?? true,
    );
  }
  
  @override
  String toString() => 'PutData(path: $path, description: $description)';
}

/// Datos específicos para @Patch
class PatchData extends AnnotationData {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;
  
  const PatchData({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = true,
  });
  
  factory PatchData.fromMap(Map<String, dynamic> map) {
    return PatchData(
      path: map['path']?.toString() ?? '',
      description: map['description']?.toString(),
      statusCode: map['statusCode'] as int? ?? 200,
      requiresAuth: map['requiresAuth'] as bool? ?? true,
    );
  }
  
  @override
  String toString() => 'PatchData(path: $path, description: $description)';
}

/// Datos específicos para @Delete
class DeleteData extends AnnotationData {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;
  
  const DeleteData({
    required this.path,
    this.description,
    this.statusCode = 204,
    this.requiresAuth = true,
  });
  
  factory DeleteData.fromMap(Map<String, dynamic> map) {
    return DeleteData(
      path: map['path']?.toString() ?? '',
      description: map['description']?.toString(),
      statusCode: map['statusCode'] as int? ?? 204,
      requiresAuth: map['requiresAuth'] as bool? ?? true,
    );
  }
  
  @override
  String toString() => 'DeleteData(path: $path, description: $description)';
}

// === CONTROLLER DATA CLASSES ===

/// Datos específicos para @RestController
class RestControllerData extends AnnotationData {
  final String basePath;
  final String? description;
  final List<String> tags;
  final bool requiresAuth;
  
  const RestControllerData({
    this.basePath = '',
    this.description,
    this.tags = const [],
    this.requiresAuth = false,
  });
  
  factory RestControllerData.fromMap(Map<String, dynamic> map) {
    return RestControllerData(
      basePath: map['basePath']?.toString() ?? '',
      description: map['description']?.toString(),
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      requiresAuth: map['requiresAuth'] as bool? ?? false,
    );
  }
  
  @override
  String toString() => 'RestControllerData(basePath: $basePath, description: $description)';
}

/// Datos específicos para @Service
class ServiceData extends AnnotationData {
  final String? name;
  final String? description;
  
  const ServiceData({this.name, this.description});
  
  factory ServiceData.fromMap(Map<String, dynamic> map) {
    return ServiceData(
      name: map['name']?.toString(),
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'ServiceData(name: $name, description: $description)';
}

/// Datos específicos para @Repository
class RepositoryData extends AnnotationData {
  final String? name;
  final String? description;
  
  const RepositoryData({this.name, this.description});
  
  factory RepositoryData.fromMap(Map<String, dynamic> map) {
    return RepositoryData(
      name: map['name']?.toString(),
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'RepositoryData(name: $name, description: $description)';
}

// === PARAMETER DATA CLASSES ===

/// Datos específicos para @Param
class ParamData extends AnnotationData {
  final String name;
  final bool required;
  final dynamic defaultValue;
  final String? description;
  
  const ParamData({
    required this.name,
    this.required = true,
    this.defaultValue,
    this.description,
  });
  
  factory ParamData.fromMap(Map<String, dynamic> map) {
    return ParamData(
      name: map['name']?.toString() ?? '',
      required: map['required'] as bool? ?? true,
      defaultValue: map['defaultValue'],
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'ParamData(name: $name, required: $required)';
}

/// Datos específicos para @PathParam
class PathParamData extends AnnotationData {
  final String name;
  final String? description;
  
  const PathParamData({
    required this.name,
    this.description,
  });
  
  factory PathParamData.fromMap(Map<String, dynamic> map) {
    return PathParamData(
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'PathParamData(name: $name)';
}

/// Datos específicos para @QueryParam
class QueryParamData extends AnnotationData {
  final String name;
  final bool required;
  final dynamic defaultValue;
  final String? description;
  
  const QueryParamData({
    required this.name,
    this.required = false,
    this.defaultValue,
    this.description,
  });
  
  factory QueryParamData.fromMap(Map<String, dynamic> map) {
    return QueryParamData(
      name: map['name']?.toString() ?? '',
      required: map['required'] as bool? ?? false,
      defaultValue: map['defaultValue'],
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'QueryParamData(name: $name, required: $required)';
}

/// Datos específicos para @RequestBody
class RequestBodyData extends AnnotationData {
  final bool required;
  final String? description;
  
  const RequestBodyData({
    this.required = true,
    this.description,
  });
  
  factory RequestBodyData.fromMap(Map<String, dynamic> map) {
    return RequestBodyData(
      required: map['required'] as bool? ?? true,
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'RequestBodyData(required: $required)';
}

/// Datos específicos para @RequestHeader
class RequestHeaderData extends AnnotationData {
  final String name;
  final bool required;
  final String? defaultValue;
  final String? description;
  
  const RequestHeaderData({
    required this.name,
    this.required = false,
    this.defaultValue,
    this.description,
  });
  
  factory RequestHeaderData.fromMap(Map<String, dynamic> map) {
    return RequestHeaderData(
      name: map['name']?.toString() ?? '',
      required: map['required'] as bool? ?? false,
      defaultValue: map['defaultValue']?.toString(),
      description: map['description']?.toString(),
    );
  }
  
  @override
  String toString() => 'RequestHeaderData(name: $name, required: $required)';
}

/// Datos genéricos para anotaciones no específicas
class GenericAnnotationData extends AnnotationData {
  final Map<String, dynamic> data;
  
  const GenericAnnotationData(this.data);
  
  /// Acceso dinámico a propiedades
  dynamic operator [](String key) => data[key];
  
  @override
  String toString() => 'GenericAnnotationData($data)';
}