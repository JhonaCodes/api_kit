## 0.0.1

- **Initial release** - Complete framework for secure REST APIs with annotation support
- **ApiServer**: HTTP server with comprehensive middleware pipeline and controller registration
- **BaseController**: Abstract base class with automatic route generation
- **Annotation-Based Routing**: Automatic route generation using @Controller, @GET, @POST, @PUT, @DELETE, @PATCH
- **Reflection Support**: Automatic detection and fallback for environments without reflection
- **ServerConfig**: Configurable server settings for production and development
- **Rate Limiting**: Advanced rate limiting with automatic IP banning and violation tracking
- **Security Headers**: Automatic OWASP security headers (XSS, CSRF, etc.)
- **Structured Logging**: Integration with logger_rs for comprehensive request/error logging
- **Result Pattern**: Robust error handling with result_controller and ApiResult<T>
- **ApiResponse**: Standardized API response model with success/error handling
- **Request Processing**: Built-in parameter extraction, logging, and JSON response helpers
- **Example Implementation**: Complete working example with annotation-based CRUD operations
- **Cross-Environment Support**: Works in Dart VM (with reflection) and Flutter Web (manual fallback)
