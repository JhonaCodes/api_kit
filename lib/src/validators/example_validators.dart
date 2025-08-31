import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

import 'jwt_validator_base.dart';

/// Validator for admin users
/// Verifies role, active status, and admin permissions
class MyAdminValidator extends JWTValidatorBase {
  const MyAdminValidator();

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // The developer has full control over the JWT structure
    final userRole = jwtPayload['role'] as String?;
    final isActive = jwtPayload['active'] as bool? ?? false;
    final permissions = jwtPayload['permissions'] as List<dynamic>? ?? [];

    // Custom developer logic
    if (userRole != 'admin') {
      return ValidationResult.invalid('User must be an administrator');
    }

    if (!isActive) {
      return ValidationResult.invalid('Administrator account is inactive');
    }

    if (!permissions.contains('admin_access')) {
      return ValidationResult.invalid('Missing admin access permission');
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Administrator access required';

  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final userName = jwtPayload['name'] ?? 'Unknown';
    final requestId = request.context['request_id'] ?? 'unknown';
    Log.i('🔐 [$requestId] Admin access granted to: $userName');
  }

  @override
  void onValidationFailed(
    Request request,
    Map<String, dynamic> jwtPayload,
    String reason,
  ) {
    final userEmail = jwtPayload['email'] ?? 'unknown@example.com';
    final endpoint = request.requestedUri.path;
    final requestId = request.context['request_id'] ?? 'unknown';
    Log.w(
      '🚫 [$requestId] Admin access denied for: $userEmail at $endpoint - Reason: $reason',
    );
  }
}

/// Validator for financial operations
/// Allows configuring specific requirements such as minimum amounts
class MyFinancialValidator extends JWTValidatorBase {
  final double minimumAmount;

  const MyFinancialValidator({this.minimumAmount = 0.0});

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // JWT structure completely controlled by the developer
    final userDepartment = jwtPayload['department'] as String?;
    final clearanceLevel = jwtPayload['clearance_level'] as int? ?? 0;
    final certifications = jwtPayload['certifications'] as List<dynamic>? ?? [];
    final maxTransactionAmount =
        jwtPayload['max_transaction_amount'] as double? ?? 0.0;

    // Department validation
    if (userDepartment != 'finance' && userDepartment != 'accounting') {
      return ValidationResult.invalid(
        'Access restricted to financial departments',
      );
    }

    // Authorization level validation
    if (clearanceLevel < 3) {
      return ValidationResult.invalid(
        'Insufficient clearance level for financial operations',
      );
    }

    // Certification validation
    if (!certifications.contains('financial_ops_certified')) {
      return ValidationResult.invalid(
        'Financial operations certification required',
      );
    }

    // Specific validation based on the operation amount
    if (minimumAmount > 0 && maxTransactionAmount < minimumAmount) {
      return ValidationResult.invalid(
        'Transaction amount exceeds user authorization limit',
      );
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Financial operations access required';

  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final userId = jwtPayload['user_id'];
    final department = jwtPayload['department'];
    final requestId = request.context['request_id'] ?? 'unknown';
    Log.i(
      '💰 [$requestId] Financial access granted to user $userId from $department department',
    );
  }
}

/// Validator for specific departments
/// Allows configuring allowed departments and required level
class MyDepartmentValidator extends JWTValidatorBase {
  final List<String> allowedDepartments;
  final bool requireManagerLevel;

  const MyDepartmentValidator({
    required this.allowedDepartments,
    this.requireManagerLevel = false,
  });

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    // Full developer control over JWT fields
    final userDepartment = jwtPayload['department'] as String?;
    final employeeLevel = jwtPayload['employee_level'] as String?;

    // Validate department
    if (userDepartment == null ||
        !allowedDepartments.contains(userDepartment)) {
      return ValidationResult.invalid(
        'Access restricted to: ${allowedDepartments.join(", ")} departments',
      );
    }

    // Validate manager level if required
    if (requireManagerLevel) {
      if (employeeLevel != 'manager' && employeeLevel != 'director') {
        return ValidationResult.invalid('Management level access required');
      }
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Department access required';

  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final userDepartment = jwtPayload['department'];
    final employeeLevel = jwtPayload['employee_level'] ?? 'employee';
    final requestId = request.context['request_id'] ?? 'unknown';
    Log.i(
      '🏢 [$requestId] Department access granted: $userDepartment ($employeeLevel)',
    );
  }
}

/// Validator for business hours
/// Verifies that access occurs within allowed hours
class MyBusinessHoursValidator extends JWTValidatorBase {
  final int startHour;
  final int endHour;
  final List<int> allowedWeekdays;

  const MyBusinessHoursValidator({
    this.startHour = 9,
    this.endHour = 17,
    this.allowedWeekdays = const [1, 2, 3, 4, 5], // Monday to Friday
  });

  @override
  ValidationResult validate(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();

    // Validate day of the week
    if (!allowedWeekdays.contains(now.weekday)) {
      return ValidationResult.invalid('Access restricted to business days');
    }

    // Validate time
    if (now.hour < startHour || now.hour >= endHour) {
      // The JWT can contain specific user overrides
      final hasAfterHoursAccess =
          jwtPayload['after_hours_access'] as bool? ?? false;
      if (!hasAfterHoursAccess) {
        return ValidationResult.invalid(
          'Access restricted to business hours ($startHour:00 - $endHour:00)',
        );
      }
    }

    return ValidationResult.valid();
  }

  @override
  String get defaultErrorMessage => 'Business hours access required';

  @override
  void onValidationSuccess(Request request, Map<String, dynamic> jwtPayload) {
    final now = DateTime.now();
    final hasAfterHoursAccess =
        jwtPayload['after_hours_access'] as bool? ?? false;
    final accessType =
        (now.hour < startHour || now.hour >= endHour) && hasAfterHoursAccess
        ? 'after-hours'
        : 'business-hours';
    final requestId = request.context['request_id'] ?? 'unknown';
    Log.i(
      '🕐 [$requestId] Time-based access granted: $accessType at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
  }
}
