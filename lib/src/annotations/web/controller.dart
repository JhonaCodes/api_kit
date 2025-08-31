// lib/annotations/web/controller.dart

/// Anotación para marcar clases como controladores REST
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

/// Anotación para componentes de servicio
final class Service {
  final String? name;
  final String? description;

  const Service({
    this.name,
    this.description,
  });
}

/// Anotación para repositorios
final class Repository {
  final String? name;
  final String? description;

  const Repository({
    this.name,
    this.description,
  });
}