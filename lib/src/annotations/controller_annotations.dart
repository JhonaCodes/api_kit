/// Annotations for defining API controllers and endpoints.
library;

/// Annotation to mark a class as an API controller.
class Controller {
  final String path;
  
  const Controller(this.path);
}

/// Annotation for GET endpoints.
class GET {
  final String path;
  
  const GET([this.path = '']);
}

/// Annotation for POST endpoints.
class POST {
  final String path;
  
  const POST([this.path = '']);
}

/// Annotation for PUT endpoints.
class PUT {
  final String path;
  
  const PUT([this.path = '']);
}

/// Annotation for DELETE endpoints.
class DELETE {
  final String path;
  
  const DELETE([this.path = '']);
}

/// Annotation for PATCH endpoints.
class PATCH {
  final String path;
  
  const PATCH([this.path = '']);
}