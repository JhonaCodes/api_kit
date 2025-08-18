# API Kit Documentation

Welcome to the complete documentation for **api_kit** - A production-ready REST API framework with comprehensive JWT authentication system.

## 📚 Documentation Index

### 🚀 Getting Started
- [01. Setup](01-setup.md) - Initial project setup and installation
- [02. First Controller](02-first-controller.md) - Creating your first API controller
- [03. GET Requests](03-get-requests.md) - Handling GET requests and responses

### 📝 HTTP Methods
- [04. POST Requests](04-post-requests.md) - Creating resources with POST
- [05. PUT Requests](05-put-requests.md) - Updating resources with PUT  
- [06. PATCH Requests](06-patch-requests.md) - Partial updates with PATCH
- [07. DELETE Requests](07-delete-requests.md) - Removing resources with DELETE

### 🔧 Advanced Features  
- [08. Query Parameters](08-query-parameters.md) - Working with query strings and filters
- [09. Middlewares](09-middlewares.md) - Custom middleware and pipeline configuration
- [11. Error Handling](11-error-handling.md) - Robust error handling patterns

### 🧪 Testing & Deployment
- [12. Testing](12-testing.md) - Unit testing, integration testing, and test utilities
- [13. Deployment](13-deployment.md) - Production deployment strategies
- [14. Examples](14-examples.md) - Complete working examples and use cases

### 🔐 JWT Authentication System (NEW in v0.0.2)
- [15. JWT Validation System](15-jwt-validation-system.md) - **Complete JWT authentication guide**
- [16. JWT Quick Start](16-jwt-quick-start.md) - Fast JWT setup for immediate use

### 📋 Reference & Information
- [17. Version Information](17-version-info.md) - Current version details and release notes
- [18. API Reference](18-api-reference.md) - Complete API documentation
- [19. Changelog](19-changelog.md) - Version history and changes

## 🎯 Quick Navigation

### For Beginners
Start with [Setup](01-setup.md) → [First Controller](02-first-controller.md) → [JWT Quick Start](16-jwt-quick-start.md)

### For JWT Authentication
Go directly to [JWT Validation System](15-jwt-validation-system.md) for comprehensive authentication setup

### For Production Deployment
Check [Testing](12-testing.md) → [Deployment](13-deployment.md) → [Version Information](17-version-info.md)

### For API Reference
See [API Reference](18-api-reference.md) for complete class and method documentation

## 🔍 Key Features Covered

### Core Framework
- ✅ Annotation-based routing (@Controller, @GET, @POST, etc.)
- ✅ Reflection support with fallback
- ✅ Production-ready server configuration
- ✅ Rate limiting and security headers
- ✅ Structured logging and error handling

### JWT Authentication (v0.0.2)
- ✅ Complete JWT validation system
- ✅ Custom validators (@JWTPublic, @JWTController, @JWTEndpoint)  
- ✅ Token blacklisting and management
- ✅ AND/OR validation logic
- ✅ Production-ready security features

### Testing & Quality
- ✅ 139/139 tests passing (100% success rate)
- ✅ Comprehensive test coverage
- ✅ Integration testing with real HTTP servers
- ✅ Performance and concurrent request validation

## 📖 Documentation Standards

All documentation follows these principles:
- **Practical Examples**: Every concept includes working code
- **Production Ready**: All examples are tested and production-ready
- **Step by Step**: Clear progression from basics to advanced features
- **Real World**: Use cases based on actual application needs

## 🆕 What's New in v0.0.2

The major addition in v0.0.2 is the **complete JWT authentication system**:

```dart
// Simple JWT setup
server.configureJWTAuth(
  jwtSecret: 'your-secret-key',
  excludePaths: ['/api/public'],
);

// Custom validators
@JWTController([
  const MyAdminValidator(),
  const MyBusinessHoursValidator(),
], requireAll: true)
class AdminController extends BaseController {
  // Protected endpoints
}
```

See [JWT Validation System](15-jwt-validation-system.md) for complete details.

## 🤝 Contributing to Documentation

Found an error or want to improve the documentation?
1. Check the [API Reference](18-api-reference.md) for the most up-to-date information
2. Review [Examples](14-examples.md) for working code patterns
3. See [Version Information](17-version-info.md) for current feature status

---

**Built with ❤️ for Dart developers who need production-ready APIs fast.**