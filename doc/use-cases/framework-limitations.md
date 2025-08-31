# Current Limitations and Framework Evolution

## 🤔 User Observations (Very Valid)

During the documentation process, the user pointed out important limitations in the current design of `api_kit`:

### Problem 1: Why `Request` + `@RequestBody`?
```dart
// Why do I need both?
@Post(path: 
'/users')
Future<Response> createUser(
  Request request,                                        // ← Necessary?
  @RequestBody(required: true) Map<String, dynamic> data, // ← Already parsed
) async {
  // Shouldn't it be automatic?
}
```

### Problem 2: JWT already validated, why extract it manually?
```dart
@JWTEndpoint([MyUserValidator()]) // ← Already validated the JWT
Future<Response> updateUser(Request request) async {
  // Why extract manually if it has already been validated above?
  final jwt = request.context[
'jwt_payload'
] as Map<String, dynamic>;
}
```

### Problem 3: Validators without request context
```dart
class MyValidator extends JWTValidatorBase {
  ValidationResult validate(Request request, Map<String, dynamic> jwt) {
    // Can't I access the parsed body or path params here?
    // Only headers and JWT?
  }
}
```

## ✅ The User is Right

These observations reflect real limitations of the current framework and show how it should evolve towards a more modern design.

## 🎯 Current State vs Ideal State

### 🔴 Current State (Suboptimal)
```dart
@RestController(basePath: 
'/api/users')
class UserController extends BaseController {
  
  @Put(path: 
'/{userId}')
  @JWTEndpoint([MyUserValidator()])
  Future<Response> updateUser(
    Request request,                                    // Required for JWT
    @PathParam(
'userId'
) String userId,                 // OK
    @RequestBody(required: true) Map<String, dynamic> data, // Parsed but I need Request too
  ) async {
    
    // Manually extract JWT (redundant)
    final jwt = request.context[
'jwt_payload'
] as Map<String, dynamic>;
    final currentUserId = jwt[
'user_id'
];
    
    // Manually validate (should be in the validator)
    if (currentUserId != userId) {
      return Response.forbidden(jsonEncode({
'error'
: 'Cannot update other users'}));
    }
    
    // Process update
    return jsonResponse(jsonEncode({
'status'
: 'updated'}));
  }
}

// Limited validator
class MyUserValidator extends JWTValidatorBase {
  ValidationResult validate(Request request, Map<String, dynamic> jwt) {
    // I can't validate path params here
    // I can't validate request body here
    // Only JWT + headers
    return ValidationResult.valid();
  }
}
```

### 🟢 Ideal State (How It Should Be)
```dart
@RestController(basePath: 
'/api/users')
class UserController extends BaseController {
  
  @Put(path: 
'/{userId}')
  @JWTEndpoint([SmartUserValidator()])
  Future<Response> updateUser(
    @PathParam(
'userId'
) String userId,
    @RequestBody() Map<String, dynamic> data,
    @JWTPayload() Map<String, dynamic> jwt,        // Automatically injected
    @RequestContext() RequestMetadata context,     // Headers, IP, etc. if needed
  ) async {
    
    // JWT already available, validation already done in SmartUserValidator
    final currentUserId = jwt[
'user_id'
];
    
    // Process update (validation already done)
    return jsonResponse(jsonEncode({
'status'
: 'updated'}));
  }
}

// Smart validator with full context
class SmartUserValidator extends ContextualValidator {
  ValidationResult validate(ValidationContext context) {
    final jwt = context.jwtPayload;
    final pathParams = context.pathParams;
    final body = context.requestBody;
    
    // Validate that the user can only modify themselves
    final currentUserId = jwt[
'user_id'
];
    final targetUserId = pathParams[
'userId'
];
    
    if (currentUserId != targetUserId) {
      return ValidationResult.invalid(
'Cannot update other users'
);
    }
    
    // Validate body data if necessary
    if (body != null && body[
'email'
] != null) {
      // Specific content validations
    }
    
    return ValidationResult.valid();
  }
}
```

## 🚀 Suggested Evolution Roadmap

### Phase 1: Elimination of Redundancies
```dart
// Allow endpoints without explicit Request
@Post(path: 
'/users')
Future<Response> createUser(
  @RequestBody() UserCreateDto userData,
  @JWTPayload() JWTData jwt,
) async {
  // No raw Request
}
```

### Phase 2: Contextual Validators
```dart
class AdvancedValidator extends ContextualJWTValidator {
  ValidationResult validate(FullValidationContext context) {
    // Access to EVERYTHING: JWT, body, path params, query params, headers
    return ValidationResult.valid();
  }
}
```

### Phase 3: Typed DTOs
```dart
@Post(path: 
'/users')
Future<ApiResponse<User>> createUser(
  @RequestBody() CreateUserRequest request,
  @JWTPayload() AuthenticatedUser user,
) async {
  // Specific types instead of Map<String, dynamic>
}
```

## 💡 Current Workarounds

While the framework evolves, these are the current best practices:

### ✅ Current Best Practice
```dart
@Post(path: 
'/users')
@JWTEndpoint([MyValidator()])
Future<Response> createUser(
  Request request, // ⚠️ Necessary due to current limitation
  @RequestBody(required: true) Map<String, dynamic> userData, // ✅ Use this, not manual parsing
) async {
  
  // ⚠️ Manual extraction necessary (for now)
  final jwt = request.context[
'jwt_payload'
] as Map<String, dynamic>;
  
  // ✅ use userData directly - it's already parsed
  final name = userData[
'name'
]; // Don't do manual jsonDecode
  
  return jsonResponse(jsonEncode({
'user_created'
: true}));
}
```

### ❌ Practices to Avoid
```dart
@Post(path: 
'/users')
Future<Response> createUser(
  Request request,
  @RequestBody() Map<String, dynamic> userData, // Already parsed
) async {
  
  // ❌ Don't do manual parsing if you already have @RequestBody
  final body = await request.readAsString(); // Redundant
  final manualData = jsonDecode(body); // Unnecessary
  
  return jsonResponse(jsonEncode({
'status'
: 'bad_practice'}));
}
```

## 📝 Contribution to the Framework

These observations are valuable for the evolution of `api_kit`. Suggestions for the maintainers:

1. **Issue #1**: Eliminate the need for `Request` when using annotations
2. **Issue #2**: Automatic injection of validated JWT payload
3. **Issue #3**: Validators with access to the full request context
4. **Issue #4**: Typed DTOs instead of `Map<String, dynamic>`

## 🎯 Conclusion

The user correctly identified limitations of the current design that make the code more verbose and redundant than necessary. These are legitimate areas of improvement for future versions of the framework.

The natural evolution would be towards a more declarative system with less boilerplate, similar to Spring Boot, FastAPI, or modern frameworks in other languages.

---

**Note**: This documentation acknowledges current limitations and proposes directions for evolution based on real user feedback.

---

**Next**: [Complete E-commerce API](ecommerce-api.md) | **Previous**: [Complete CRUD Use Case](complete-crud-api.md)
