/// Annotations for defining API controllers and endpoints.
library;

import 'package:shelf/shelf.dart' show Middleware;

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

/// Annotation to require authentication on specific endpoints.
class RequireAuth {
  final String? role;
  final List<String> permissions;
  
  const RequireAuth({this.role, this.permissions = const []});
}

/// Annotation to apply custom middleware to specific endpoints.
class UseMiddleware {
  final List<Middleware Function()> middlewares;
  
  const UseMiddleware(this.middlewares);
}

/// Annotation to skip default middleware on specific endpoints.
class SkipMiddleware {
  final List<String> skip;
  
  const SkipMiddleware(this.skip);
}

/// Annotation for rate limiting specific endpoints.
class RateLimit {
  final int maxRequests;
  final Duration window;
  
  const RateLimit({required this.maxRequests, required this.window});
}