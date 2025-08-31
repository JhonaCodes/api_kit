import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:logger_rs/logger_rs.dart';

/// 🔐 JWT Authentication Example - Modern Pattern
///
/// This example demonstrates JWT authentication with api_kit using:
/// - ✅ Enhanced parameter annotations (NO Request request needed)
/// - ✅ @RequestContext('jwt_payload') for direct JWT access
/// - ✅ Clean JWT validators without manual Request extraction
/// - ✅ Direct Ok/Err pattern with result_controller
/// - ✅ Proper security annotations
///
/// ## 🎯 JWT Features Demonstrated:
/// - @JWTPublic() - Public endpoints without JWT
/// - @JWTController() - Controller-level JWT protection
/// - @JWTEndpoint() - Method-level JWT validation
/// - @RequestContext('jwt_payload') - Direct JWT payload access
/// - Custom JWT validators with business logic
///
/// ## Running the Example:
/// ```bash
/// dart run example/jwt_example.dart
/// ```
///
/// ## Test JWT Endpoints:
/// ```bash
/// # Public endpoint (no JWT needed)
/// curl "http://localhost:8080/api/public/info"
///
/// # Protected endpoint (needs JWT)
/// curl "http://localhost:8080/api/admin/users" \
///   -H "Authorization: Bearer your_jwt_token_here"
///
/// # Financial endpoint (needs special JWT claims)
/// curl "http://localhost:8080/api/finance/transactions" \
///   -H "Authorization: Bearer financial_user_jwt_token"
/// ```

void main() async {
  final server = ApiServer(config: ServerConfig.development());

  // ✅ Configure JWT authentication
  server.configureJWTAuth(
    jwtSecret: 'your-super-secret-256-bit-key-change-in-production-please',
    excludePaths: ['/health', '/api/public'],
  );

  final result = await server.start(host: 'localhost', port: 8080);

  result.when(
    ok: (httpServer) {
      Log.i('🔐 JWT Server running on http://localhost:8080');
      Log.i('🌐 Public API: http://localhost:8080/api/public/info');
      Log.i(
        '🔒 Admin API: http://localhost:8080/api/admin/users (requires JWT)',
      );
      Log.i(
        '💰 Finance API: http://localhost:8080/api/finance/transactions (requires financial JWT)',
      );

      ProcessSignal.sigint.watch().listen((sig) async {
        Log.i('🛑 Shutting down JWT server...');
        await httpServer.close(force: false);
        exit(0);
      });
    },
    err: (error) {
      Log.e('❌ Failed to start JWT server: ${error.msm}');
      exit(1);
    },
  );
}

/// 🌐 Public Controller - No JWT Required
///
/// ✅ Uses @JWTPublic() to mark endpoints as publicly accessible
@RestController(basePath: '/api/public')
class PublicController extends BaseController {
  /// Public info endpoint - accessible without JWT
  @Get(path: '/info')
  @JWTPublic() // ✅ Marks endpoint as public (no JWT needed)
  Future<Response> getPublicInfo(
    @RequestMethod() String method,
    @RequestPath() String path,
    @RequestHeader.all() Map<String, String> allHeaders,
  ) async {
    final result = ApiKit.ok({
      'service': 'api_kit JWT Example',
      'version': '1.0.0',
      'public_access': true,
      'jwt_required': false,
      'request_info': {
        'method': method,
        'path': path,
        'headers_count': allHeaders.length,
      },
      'message': 'This endpoint is publicly accessible - no JWT required!',
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// Health check - also public
  @Get(path: '/health')
  @JWTPublic()
  Future<Response> healthCheck() async {
    final result = ApiKit.ok({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'jwt_example_server',
      'jwt_system': 'active',
    });

    return ApiResponseBuilder.fromResult(result);
  }
}

/// 🔒 Admin Controller - JWT Required with Admin Role
///
/// ✅ Uses @JWTController() for controller-level protection
/// ✅ Uses @RequestContext('jwt_payload') for direct JWT access
@RestController(basePath: '/api/admin')
@JWTController([
  AdminRoleValidator(), // Custom validator for admin role
  ActiveUserValidator(), // Ensures user account is active
], requireAll: true) // Both validators must pass (AND logic)
class AdminController extends BaseController {
  final List<Map<String, dynamic>> _users = [
    {'id': 'usr_1', 'name': 'John Admin', 'role': 'admin', 'active': true},
    {'id': 'usr_2', 'name': 'Jane Manager', 'role': 'manager', 'active': true},
    {'id': 'usr_3', 'name': 'Bob User', 'role': 'user', 'active': false},
  ];

  /// Get all users - requires admin JWT
  @Get(path: '/users')
  Future<Response> getAllUsers(
    @RequestContext('jwt_payload')
    Map<String, dynamic> jwtPayload, // ✅ Direct JWT access
    @RequestHeader.all() Map<String, String> allHeaders,
    @QueryParam.all() Map<String, String> allQueryParams,
  ) async {
    // ✅ JWT payload available directly - no manual extraction
    final currentUserId = jwtPayload['user_id'];
    final currentUserRole = jwtPayload['role'];
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    // Apply filtering if requested
    final roleFilter = allQueryParams['role'];
    var filteredUsers = _users;

    if (roleFilter != null && roleFilter.isNotEmpty) {
      filteredUsers = _users.where((u) => u['role'] == roleFilter).toList();
    }

    final result = ApiKit.ok({
      'users': filteredUsers,
      'admin_info': {
        'current_admin_id': currentUserId,
        'current_admin_role': currentUserRole,
        'admin_permissions': permissions,
      },
      'filters_applied': {
        'role_filter': roleFilter,
        'total_found': filteredUsers.length,
        'total_users': _users.length,
      },
      'request_context': {
        'headers_count': allHeaders.length,
        'query_params': allQueryParams.keys.toList(),
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// Create new user - admin only operation
  @Post(path: '/users')
  Future<Response> createUser(
    @RequestBody() Map<String, dynamic> userData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @RequestMethod() String method,
  ) async {
    try {
      // ✅ Validation with direct JWT access
      if (userData['name'] == null ||
          userData['name'].toString().trim().isEmpty) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Name is required',
          validations: {'name': 'Name cannot be empty'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      final currentAdminId = jwtPayload['user_id'];
      final adminRole = jwtPayload['role'];

      // Create new user
      final newUser = {
        'id': 'usr_${_users.length + 1}',
        'name': userData['name'].toString().trim(),
        'role': userData['role'] ?? 'user',
        'active': true,
        'created_by': currentAdminId,
        'created_at': DateTime.now().toIso8601String(),
      };

      _users.add(newUser);

      final result = ApiKit.ok({
        'user': newUser,
        'message': 'User created successfully by admin',
        'admin_context': {
          'created_by_admin': currentAdminId,
          'admin_role': adminRole,
          'method': method,
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to create user: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }

  /// Delete user - requires special admin permission
  @Delete(path: '/users/{id}')
  @JWTEndpoint([
    AdminRoleValidator(),
    UserManagementPermissionValidator(), // Additional permission check
  ], requireAll: true)
  Future<Response> deleteUser(
    @PathParam('id') String userId,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @RequestPath() String path,
  ) async {
    final userIndex = _users.indexWhere((u) => u['id'] == userId);

    if (userIndex == -1) {
      final result = ApiKit.notFound<Map<String, dynamic>>(
        'User with ID $userId not found',
      );
      return ApiResponseBuilder.fromResult(result);
    }

    final deletedUser = _users.removeAt(userIndex);
    final adminId = jwtPayload['user_id'];
    final adminPermissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    final result = ApiKit.ok({
      'message': 'User deleted successfully',
      'deleted_user': {
        'id': deletedUser['id'],
        'name': deletedUser['name'],
        'deleted_by': adminId,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      'admin_context': {
        'admin_id': adminId,
        'admin_permissions': adminPermissions,
        'deletion_path': path,
      },
      'remaining_users': _users.length,
    });

    return ApiResponseBuilder.fromResult(result);
  }
}

/// 💰 Finance Controller - Specialized JWT Requirements
///
/// ✅ Uses financial-specific JWT validators
/// ✅ Demonstrates complex JWT validation with business rules
@RestController(basePath: '/api/finance')
@JWTController([
  FinancialRoleValidator(), // Must have financial role
  BusinessHoursValidator(), // Only during business hours
], requireAll: true)
class FinanceController extends BaseController {
  final List<Map<String, dynamic>> _transactions = [
    {'id': 'txn_1', 'amount': 1500.00, 'type': 'credit', 'account': 'acc_123'},
    {'id': 'txn_2', 'amount': -750.00, 'type': 'debit', 'account': 'acc_456'},
    {'id': 'txn_3', 'amount': 2250.00, 'type': 'credit', 'account': 'acc_789'},
  ];

  /// Get transactions - financial access required
  @Get(path: '/transactions')
  Future<Response> getTransactions(
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
    @QueryParam.all() Map<String, String> allQueryParams,
  ) async {
    // ✅ Financial JWT context available directly
    final financialUserId = jwtPayload['user_id'];
    final financialRole = jwtPayload['role'];
    final clearanceLevel = jwtPayload['clearance_level'] ?? 1;
    final authorizedAccounts =
        jwtPayload['authorized_accounts'] as List<dynamic>? ?? [];

    // Filter by account if specified and authorized
    final accountFilter = allQueryParams['account'];
    var filteredTransactions = _transactions;

    if (accountFilter != null && accountFilter.isNotEmpty) {
      if (authorizedAccounts.contains(accountFilter)) {
        filteredTransactions = _transactions
            .where((txn) => txn['account'] == accountFilter)
            .toList();
      } else {
        final result = ApiKit.forbidden<Map<String, dynamic>>(
          'Not authorized to access account $accountFilter',
        );
        return ApiResponseBuilder.fromResult(result);
      }
    }

    // Filter by clearance level (higher amounts need higher clearance)
    if (clearanceLevel < 3) {
      filteredTransactions = filteredTransactions.where((txn) {
        final amount = (txn['amount'] as num).abs();
        return amount <=
            1000.00; // Level 1-2 can only see transactions <= $1000
      }).toList();
    }

    final result = ApiKit.ok({
      'transactions': filteredTransactions,
      'financial_context': {
        'financial_user_id': financialUserId,
        'role': financialRole,
        'clearance_level': clearanceLevel,
        'authorized_accounts': authorizedAccounts,
      },
      'filters_applied': {
        'account_filter': accountFilter,
        'clearance_filtering': clearanceLevel < 3,
        'visible_transactions': filteredTransactions.length,
        'total_transactions': _transactions.length,
      },
      'business_rules': {
        'high_amount_threshold': clearanceLevel >= 3
            ? 'unlimited'
            : '\$1000.00',
        'account_access_restricted': authorizedAccounts.isNotEmpty,
      },
    });

    return ApiResponseBuilder.fromResult(result);
  }

  /// Create financial transaction - high clearance required
  @Post(path: '/transactions')
  @JWTEndpoint([
    FinancialRoleValidator(),
    HighClearanceValidator(), // Requires clearance level >= 3
    TransactionPermissionValidator(), // Can create transactions
  ], requireAll: true)
  Future<Response> createTransaction(
    @RequestBody() Map<String, dynamic> transactionData,
    @RequestContext('jwt_payload') Map<String, dynamic> jwtPayload,
  ) async {
    try {
      // ✅ Comprehensive validation with JWT context
      final amount = transactionData['amount'] as num?;
      if (amount == null) {
        final result = ApiKit.badRequest<Map<String, dynamic>>(
          'Amount is required',
          validations: {'amount': 'Transaction amount must be specified'},
        );
        return ApiResponseBuilder.fromResult(result);
      }

      final clearanceLevel = jwtPayload['clearance_level'] ?? 1;
      final maxTransactionLimit = jwtPayload['max_transaction_limit'] ?? 1000.0;

      // Check transaction limits based on JWT claims
      if (amount.abs() > maxTransactionLimit) {
        final result = ApiKit.forbidden<Map<String, dynamic>>(
          'Transaction amount exceeds authorized limit of \$${maxTransactionLimit.toStringAsFixed(2)}',
        );
        return ApiResponseBuilder.fromResult(result);
      }

      final newTransaction = {
        'id': 'txn_${_transactions.length + 1}',
        'amount': amount,
        'type': amount >= 0 ? 'credit' : 'debit',
        'account': transactionData['account'] ?? 'default_account',
        'created_by': jwtPayload['user_id'],
        'clearance_used': clearanceLevel,
        'created_at': DateTime.now().toIso8601String(),
      };

      _transactions.add(newTransaction);

      final result = ApiKit.ok({
        'transaction': newTransaction,
        'message': 'Financial transaction created successfully',
        'authorization_context': {
          'authorized_by': jwtPayload['user_id'],
          'clearance_level': clearanceLevel,
          'max_limit': maxTransactionLimit,
          'within_limits': true,
        },
      });

      return ApiResponseBuilder.fromResult(result);
    } catch (e, stack) {
      final result = ApiKit.serverError<Map<String, dynamic>>(
        'Failed to create transaction: ${e.toString()}',
        exception: e,
        stackTrace: stack,
      );
      return ApiResponseBuilder.fromResult(result);
    }
  }
}

// ===== JWT VALIDATORS =====

/// Admin role validator - checks for admin role in JWT
class AdminRoleValidator extends JWTValidatorBase {
  const AdminRoleValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;

    if (role != 'admin') {
      return ValidationResult.invalid('Administrator role required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Administrator access required';
}

/// Active user validator - ensures account is active
class ActiveUserValidator extends JWTValidatorBase {
  const ActiveUserValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final isActive = jwtPayload['active'] as bool? ?? false;

    if (!isActive) {
      return ValidationResult.invalid('Account is inactive');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'User account must be active';
}

/// User management permission validator
class UserManagementPermissionValidator extends JWTValidatorBase {
  const UserManagementPermissionValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    if (!permissions.contains('user_management')) {
      return ValidationResult.invalid('User management permission required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'User management permission required';
}

/// Financial role validator - requires financial department access
class FinancialRoleValidator extends JWTValidatorBase {
  const FinancialRoleValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final role = jwtPayload['role'] as String?;
    final department = jwtPayload['department'] as String?;

    if (role != 'financial_analyst' &&
        role != 'financial_manager' &&
        department != 'finance') {
      return ValidationResult.invalid('Financial department access required');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Financial department access required';
}

/// Business hours validator - only allows access during business hours
class BusinessHoursValidator extends JWTValidatorBase {
  const BusinessHoursValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    final hour = now.hour;

    // Business hours: 9 AM to 5 PM, Monday to Friday
    if (now.weekday > 5 || hour < 9 || hour >= 17) {
      return ValidationResult.invalid(
        'Financial operations only available during business hours (9 AM - 5 PM, Mon-Fri)',
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage =>
      'Financial operations only available during business hours';
}

/// High clearance validator - requires clearance level >= 3
class HighClearanceValidator extends JWTValidatorBase {
  const HighClearanceValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final clearanceLevel = jwtPayload['clearance_level'] as int? ?? 1;

    if (clearanceLevel < 3) {
      return ValidationResult.invalid(
        'High clearance level (3+) required for this operation',
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'High clearance level (3+) required';
}

/// Transaction permission validator
class TransactionPermissionValidator extends JWTValidatorBase {
  const TransactionPermissionValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    if (!permissions.contains('create_transactions')) {
      return ValidationResult.invalid(
        'Transaction creation permission required',
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Transaction creation permission required';
}
