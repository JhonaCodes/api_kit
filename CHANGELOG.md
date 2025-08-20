# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.3]
- Fix GitHub links

## [0.0.3]
- Improve documentation, warnings, etc.

## [0.0.2]

### 🚀 Major Features Added

#### **Complete JWT Authentication System**
- **JWT Annotations**: `@JWTPublic`, `@JWTController`, `@JWTEndpoint` for fine-grained access control
- **Custom Validators**: Extensible `JWTValidatorBase` class for implementing custom authorization logic
- **Hierarchical Validation**: Endpoint-level validators override controller-level validators
- **AND/OR Logic**: `requireAll` parameter for flexible validator combinations
- **Token Blacklisting**: Complete token revocation system with in-memory management
- **JWT Payload Access**: Full payload injection into `request.context` for endpoint consumption

#### **Production-Ready Validators**
- **MyAdminValidator**: Role-based admin access control with permissions validation
- **MyFinancialValidator**: Department + clearance level + certification + transaction limit validation
- **MyDepartmentValidator**: Configurable department access with optional management level requirements
- **MyBusinessHoursValidator**: Time-based access control with after-hours override support

#### **Enhanced Security & Middleware**
- **JWT Middleware Pipeline**: Automatic JWT extraction, validation, and payload injection
- **Enhanced Reflection System**: JWT-aware route registration with annotation detection
- **Error Handling**: Standardized JWT error responses (401/403) with detailed validation feedback
- **Request Context**: Automatic JWT payload and shortcut injection (`user_id`, `user_email`, `user_role`)

### 🔧 Technical Improvements

#### **Enhanced ReflectionHelper**
- **JWT Middleware Integration**: Routes automatically get JWT validation middleware applied based on annotations
- **Symbol Processing**: Robust method name extraction from Dart Symbol representations
- **Annotation Detection**: Complete scanning system for JWT annotations on controllers and methods

#### **ApiServer Enhancements** 
- **JWT Configuration**: `configureJWTAuth()`, `disableJWTAuth()` methods for dynamic JWT setup
- **Token Management**: `blacklistToken()`, `clearTokenBlacklist()`, `blacklistedTokensCount` for token lifecycle
- **Dynamic Reconfiguration**: Support for changing JWT secrets and configuration at runtime

### 🧪 Comprehensive Testing

#### **Test Coverage Achievement**
- **139/139 tests passing** (100% success rate)
- **6 dedicated JWT test files** covering all authentication scenarios
- **Production-ready test suite** with real HTTP servers and concurrent request validation
- **Edge case coverage** including malformed tokens, expired JWTs, complex payloads, and error conditions

#### **Test Files Added**
- `jwt_validation_system_test.dart` - Core JWT system functionality
- `jwt_production_ready_test.dart` - Critical production scenarios  
- `jwt_validated_system_test.dart` - Functional validation tests
- `jwt_comprehensive_test.dart` - Exhaustive edge case coverage
- `jwt_system_simple_test.dart` - Basic unit tests
- `jwt_annotations_test.dart` - Annotation integration tests

### 📚 Documentation Updates

#### **Complete README Overhaul**
- **JWT Section**: Comprehensive documentation with real-world examples
- **Custom Validators Guide**: Step-by-step validator creation with production examples
- **Configuration Examples**: JWT setup, token blacklisting, dynamic configuration
- **Error Handling Documentation**: Detailed error response formats and codes
- **Migration Guide**: Clear before/after examples for upgrading from v0.0.1

#### **Documentation Files**
- **Enhanced README.md**: Production-ready examples and comprehensive API documentation
- **JWT Quick Start Guide**: Complete authentication setup in `doc/15-jwt-validation-system.md`

### 🏗️ Architecture Enhancements

#### **JWT System Architecture**
```
@JWTController (Controller Level) 
    ↓
@JWTEndpoint (Method Level - Overrides Controller)
    ↓  
@JWTPublic (Public - Bypasses All Validation)
```

#### **Validation Pipeline**
```
HTTP Request → JWT Extraction → Custom Validators → Business Logic → Response
```

#### **Error Response Standardization**
- **401 Unauthorized**: Missing/invalid JWT tokens
- **403 Forbidden**: Valid JWT but authorization failed
- **Detailed Error Context**: Validation mode, failed validators, request IDs

### 🎯 Breaking Changes
- **JWT System**: Replaces hypothetical `@RequireAuth` annotations with new JWT system
- **Authentication Flow**: New JWT-based authentication replaces basic auth patterns

### 🚧 Developer Experience

#### **Type Safety**
- **Const Constructors**: All validators support `const` for compile-time optimization
- **Generic Validation Results**: Type-safe validation result patterns
- **Context Injection**: Strongly-typed JWT payload access

#### **Performance Optimizations**
- **Concurrent Request Handling**: Validated with load testing
- **Efficient Token Blacklisting**: O(1) lookup performance
- **Reflection Optimization**: Smart caching of annotation metadata

---

## [0.0.1]

### 🎉 Initial Release

#### **Core Framework**
- **Initial release** - Complete framework for secure REST APIs with annotation support
- **ApiServer**: HTTP server with comprehensive middleware pipeline and controller registration
- **BaseController**: Abstract base class with automatic route generation
- **Annotation-Based Routing**: Automatic route generation using @Controller, @GET, @POST, @PUT, @DELETE, @PATCH
- **Reflection Support**: Automatic detection and fallback for environments without reflection
- **ServerConfig**: Configurable server settings for production and development

#### **Security & Performance**
- **Rate Limiting**: Advanced rate limiting with automatic IP banning and violation tracking
- **Security Headers**: Automatic OWASP security headers (XSS, CSRF, etc.)
- **Structured Logging**: Integration with logger_rs for comprehensive request/error logging

#### **Developer Experience**
- **Result Pattern**: Robust error handling with result_controller and ApiResult<T>
- **ApiResponse**: Standardized API response model with success/error handling
- **Request Processing**: Built-in parameter extraction, logging, and JSON response helpers
- **Example Implementation**: Complete working example with annotation-based CRUD operations
- **Cross-Environment Support**: Works in Dart VM (with reflection) and Flutter Web (manual fallback)
