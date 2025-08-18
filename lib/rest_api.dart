/// A comprehensive security framework for Dart/Shelf APIs.
///
/// This library provides OWASP protection, rate limiting, circuit breaker pattern,
/// and auto-recovery capabilities for building secure REST APIs with Dart and Shelf.
library;

// Core exports
export 'src/core/secure_server.dart';
export 'src/core/base_controller.dart';
export 'src/core/router_builder.dart';
export 'src/core/reflection_helper.dart';

// Security exports
export 'src/security/rate_limiter.dart';
export 'src/security/middleware.dart';

// Configuration exports
export 'src/config/security_config.dart';

// Annotations exports
export 'src/annotations/controller_annotations.dart';

// Models exports
export 'src/models/api_response.dart';
