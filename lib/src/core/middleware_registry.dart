import 'package:shelf/shelf.dart';

/// Registry for custom middleware that can be applied to specific endpoints.
class MiddlewareRegistry {
  static final Map<String, Middleware Function()> _registry = {};

  /// Register a named middleware that can be referenced in annotations.
  static void register(String name, Middleware Function() middleware) {
    _registry[name] = middleware;
  }

  /// Get a registered middleware by name.
  static Middleware Function()? get(String name) {
    return _registry[name];
  }

  /// Check if a middleware is registered.
  static bool has(String name) {
    return _registry.containsKey(name);
  }

  /// Clear all registered middleware (mainly for testing).
  static void clear() {
    _registry.clear();
  }

  /// Get all registered middleware names.
  static List<String> get names => _registry.keys.toList();
}

/// Built-in middleware creators for common use cases.
class BuiltInMiddleware {
  /// Creates JWT authentication middleware.
  static Middleware Function() jwt({
    required String secret,
    String? issuer,
    List<String> requiredRoles = const [],
  }) {
    return () => (Handler handler) {
      return (Request request) async {
        // Extract JWT from Authorization header
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response(401, body: '{"error": "Missing or invalid token"}',
              headers: {'content-type': 'application/json'});
        }

        final token = authHeader.substring(7);
        
        // Here you would validate the JWT token
        // For MVP purposes, we'll just check if it exists
        if (token.isEmpty) {
          return Response(401, body: '{"error": "Invalid token"}',
              headers: {'content-type': 'application/json'});
        }

        // Add user info to request context for downstream handlers
        final updatedRequest = request.change(context: {
          ...request.context,
          'user': {'id': 'user123', 'roles': ['user']}, // Mock user
          'token': token,
        });

        return handler(updatedRequest);
      };
    };
  }

  /// Creates API key authentication middleware.
  static Middleware Function() apiKey({required String validKey}) {
    return () => (Handler handler) {
      return (Request request) async {
        final apiKey = request.headers['x-api-key'];
        if (apiKey != validKey) {
          return Response(401, body: '{"error": "Invalid API key"}',
              headers: {'content-type': 'application/json'});
        }
        return handler(request);
      };
    };
  }

  /// Creates endpoint-specific rate limiting middleware.
  static Middleware Function() rateLimit({
    required int maxRequests,
    required Duration window,
  }) {
    final Map<String, List<DateTime>> _requests = {};
    
    return () => (Handler handler) {
      return (Request request) async {
        final key = request.requestedUri.path;
        final now = DateTime.now();
        
        _requests[key] ??= [];
        _requests[key]!.removeWhere((time) => now.difference(time) > window);
        
        if (_requests[key]!.length >= maxRequests) {
          return Response(429, 
              body: '{"error": "Rate limit exceeded"}',
              headers: {'content-type': 'application/json'});
        }
        
        _requests[key]!.add(now);
        return handler(request);
      };
    };
  }
}