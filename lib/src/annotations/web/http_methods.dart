// lib/annotations/web/http_methods.dart

/// Annotation for GET endpoints
final class Get {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;

  const Get({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = false,
  });
}

/// Annotation for POST endpoints
final class Post {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;

  const Post({
    required this.path,
    this.description,
    this.statusCode = 201,
    this.requiresAuth = false,
  });
}

/// Annotation for PUT endpoints
final class Put {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;

  const Put({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = true,
  });
}

/// Annotation for PATCH endpoints
final class Patch {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;

  const Patch({
    required this.path,
    this.description,
    this.statusCode = 200,
    this.requiresAuth = true,
  });
}

/// Annotation for DELETE endpoints
final class Delete {
  final String path;
  final String? description;
  final int statusCode;
  final bool requiresAuth;

  const Delete({
    required this.path,
    this.description,
    this.statusCode = 204,
    this.requiresAuth = true,
  });
}