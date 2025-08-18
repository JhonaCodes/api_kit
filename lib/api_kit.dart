/// Simple, fast REST API framework with annotation-based routing.
///
/// Perfect for MVPs and rapid prototyping. Just add controllers with annotations
/// and you're ready to go. Built-in essentials included.
library;

// Core exports
export 'src/core/api_server.dart';
export 'src/core/base_controller.dart';
export 'src/core/router_builder.dart';
export 'src/core/reflection_helper.dart';
export 'src/core/enhanced_reflection_helper.dart';
export 'src/core/middleware_registry.dart';

// Security exports
export 'src/security/rate_limiter.dart';
export 'src/security/middleware.dart';
export 'src/middleware/enhanced_auth_middleware.dart';

// Configuration exports
export 'src/config/server_config.dart';

// Annotations exports
export 'src/annotations/controller_annotations.dart';
export 'src/annotations/jwt_annotations.dart';

// Models exports
export 'src/models/api_response.dart';

// JWT Validation System exports
export 'src/validators/jwt_validator_base.dart';
export 'src/validators/example_validators.dart';

// External dependencies re-exports (for convenience)
export 'package:shelf/shelf.dart' show Request, Response;
export 'package:result_controller/result_controller.dart' show ApiResult;
