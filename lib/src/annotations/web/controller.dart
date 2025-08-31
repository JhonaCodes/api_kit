// lib/annotations/web/controller.dart

/// Annotation to mark classes as REST controllers
final class RestController {
  final String basePath;
  final String? description;
  final List<String> tags;
  final bool requiresAuth;

  const RestController({
    this.basePath = '',
    this.description,
    this.tags = const [],
    this.requiresAuth = false,
  });
}

/// Annotation for service components
final class Service {
  final String? name;
  final String? description;

  const Service({this.name, this.description});
}

/// Annotation for repositories
final class Repository {
  final String? name;
  final String? description;

  const Repository({this.name, this.description});
}
