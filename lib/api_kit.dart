/// Production-ready REST API framework with comprehensive JWT authentication system.
///
/// ## 🚀 v0.0.5+ Features - NOW AOT COMPATIBLE! 
/// - ⚡ **Hybrid routing system** - Generated code (AOT) + Mirrors fallback (JIT)
/// - 🔐 Complete JWT validation with @JWTPublic, @JWTController, @JWTEndpoint annotations
/// - 🎯 Custom validators extending JWTValidatorBase with AND/OR logic
/// - 🚫 Token blacklisting and management system
/// - 📝 Annotation-based routing with @Controller, @GET, @POST, etc.
/// - 🛡️ Enterprise-grade security headers and middleware pipeline
/// - 🧪 140+ tests passing - production ready
/// - 📦 **AOT compilation support** with code generation
///
/// ## Migration Path
/// - Existing code works unchanged (static analysis)
/// - Run `dart run build_runner build` for AOT compatibility
/// - Zero breaking changes from previous versions
///
/// Perfect for MVPs, rapid prototyping, and enterprise applications.
library;

// Core exports
export 'src/core/api_server.dart';
export 'src/core/base_controller.dart';
export 'src/core/router_builder.dart';
export 'src/core/middleware_registry.dart';
export 'src/core/controller_registry.dart';

// ✅ Static analysis system - no mirrors required!

// Security exports
export 'src/security/rate_limiter.dart';
export 'src/security/middleware.dart';
export 'src/middleware/enhanced_auth_middleware.dart';

// Configuration exports
export 'src/config/server_config.dart';

// JWT Annotations exports (keeping only JWT-specific)
export 'src/annotations/jwt_annotations.dart';

// Models exports
export 'src/models/api_response.dart';

// JWT Validation System exports
export 'src/validators/jwt_validator_base.dart';
export 'src/validators/example_validators.dart';

// 🆕 NEW: Static Analysis Annotation System (Replaces Mirrors)
export 'src/annotations/annotation_api.dart';
export 'src/annotations/annotation_details.dart';
export 'src/annotations/annotation_result.dart';
export 'src/annotations/annotation_data.dart';
export 'src/annotations/rest_annotations.dart';

// 🆕 NEW: Static Router Builder (AOT Compatible)
export 'src/core/static_router_builder.dart';
export 'src/core/method_dispatcher.dart';

// External dependencies re-exports (for convenience)
export 'package:shelf/shelf.dart' show Request, Response;
export 'package:result_controller/result_controller.dart' show ApiResult;
