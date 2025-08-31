// lib/annotation_data.dart

/// Base class for typed annotation data
abstract class AnnotationData {
  const AnnotationData();

  /// Converts the Map to a typed instance
  static AnnotationData fromMap(
    String annotationType,
    Map<String, dynamic> map,
  ) {
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

/// Specific data for @Get
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

/// Specific data for @Post
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

/// Specific data for @Put
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

/// Specific data for @Patch
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

/// Specific data for @Delete
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

/// Specific data for @RestController
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
  String toString() =>
      'RestControllerData(basePath: $basePath, description: $description)';
}

/// Specific data for @Service
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

/// Specific data for @Repository
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

/// Specific data for @Param
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

/// Specific data for @PathParam
class PathParamData extends AnnotationData {
  final String name;
  final String? description;

  const PathParamData({required this.name, this.description});

  factory PathParamData.fromMap(Map<String, dynamic> map) {
    return PathParamData(
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
    );
  }

  @override
  String toString() => 'PathParamData(name: $name)';
}

/// Specific data for @QueryParam
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

/// Specific data for @RequestBody
class RequestBodyData extends AnnotationData {
  final bool required;
  final String? description;

  const RequestBodyData({this.required = true, this.description});

  factory RequestBodyData.fromMap(Map<String, dynamic> map) {
    return RequestBodyData(
      required: map['required'] as bool? ?? true,
      description: map['description']?.toString(),
    );
  }

  @override
  String toString() => 'RequestBodyData(required: $required)';
}

/// Specific data for @RequestHeader
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

/// Generic data for non-specific annotations
class GenericAnnotationData extends AnnotationData {
  final Map<String, dynamic> data;

  const GenericAnnotationData(this.data);

  /// Dynamic access to properties
  dynamic operator [](String key) => data[key];

  @override
  String toString() => 'GenericAnnotationData($data)';
}
