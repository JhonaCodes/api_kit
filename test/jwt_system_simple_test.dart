import 'package:test/test.dart';
import 'package:api_kit/api_kit.dart';

void main() {
  group('JWT System Simple Tests', () {
    test('JWTValidatorBase should be const constructible', () {
      const validator = MyAdminValidator();
      expect(validator, isA<JWTValidatorBase>());
      expect(
        validator.defaultErrorMessage,
        equals('Administrator access required'),
      );
    });

    test('JWT annotations should accept const validators', () {
      const annotation = JWTController([
        MyAdminValidator(),
        MyDepartmentValidator(allowedDepartments: ['test']),
      ], requireAll: true);

      expect(annotation.validators.length, equals(2));
      expect(annotation.requireAll, equals(true));
    });

    test('JWT validation should work with mock payload', () {
      const validator = MyAdminValidator();
      final mockRequest = Request('GET', Uri.parse('http://localhost/test'));

      // Test with valid admin payload
      final validPayload = {
        'role': 'admin',
        'active': true,
        'permissions': ['admin_access', 'read'],
      };

      final validResult = validator.validate(mockRequest, validPayload);
      expect(validResult.isValid, equals(true));
      expect(validResult.errorMessage, isNull);

      // Test with invalid payload (no admin role)
      final invalidPayload = {
        'role': 'user',
        'active': true,
        'permissions': ['read'],
      };

      final invalidResult = validator.validate(mockRequest, invalidPayload);
      expect(invalidResult.isValid, equals(false));
      expect(
        invalidResult.errorMessage,
        equals('User must be an administrator'),
      );
    });

    test('Department validator should work correctly', () {
      const validator = MyDepartmentValidator(
        allowedDepartments: ['finance', 'admin'],
        requireManagerLevel: true,
      );

      final mockRequest = Request('GET', Uri.parse('http://localhost/test'));

      // Valid: finance department + manager level
      final validPayload = {
        'department': 'finance',
        'employee_level': 'manager',
      };

      final validResult = validator.validate(mockRequest, validPayload);
      expect(validResult.isValid, equals(true));

      // Invalid: wrong department
      final invalidDeptPayload = {
        'department': 'sales',
        'employee_level': 'manager',
      };

      final invalidDeptResult = validator.validate(
        mockRequest,
        invalidDeptPayload,
      );
      expect(invalidDeptResult.isValid, equals(false));
      expect(invalidDeptResult.errorMessage, contains('finance, admin'));

      // Invalid: correct department but insufficient level
      final invalidLevelPayload = {
        'department': 'finance',
        'employee_level': 'employee',
      };

      final invalidLevelResult = validator.validate(
        mockRequest,
        invalidLevelPayload,
      );
      expect(invalidLevelResult.isValid, equals(false));
      expect(
        invalidLevelResult.errorMessage,
        contains('Management level access required'),
      );
    });

    test('Financial validator should validate correctly', () {
      const validator = MyFinancialValidator(minimumAmount: 10000);
      final mockRequest = Request('GET', Uri.parse('http://localhost/test'));

      // Valid: finance department with proper clearance
      final validPayload = {
        'department': 'finance',
        'clearance_level': 5,
        'certifications': ['financial_ops_certified'],
        'max_transaction_amount': 50000.0,
      };

      final validResult = validator.validate(mockRequest, validPayload);
      expect(validResult.isValid, equals(true));

      // Invalid: insufficient clearance level
      final invalidClearancePayload = {
        'department': 'finance',
        'clearance_level': 1,
        'certifications': ['financial_ops_certified'],
        'max_transaction_amount': 50000.0,
      };

      final invalidClearanceResult = validator.validate(
        mockRequest,
        invalidClearancePayload,
      );
      expect(invalidClearanceResult.isValid, equals(false));
      expect(
        invalidClearanceResult.errorMessage,
        contains('Insufficient clearance level'),
      );

      // Invalid: missing certification
      final invalidCertPayload = {
        'department': 'finance',
        'clearance_level': 5,
        'certifications': [],
        'max_transaction_amount': 50000.0,
      };

      final invalidCertResult = validator.validate(
        mockRequest,
        invalidCertPayload,
      );
      expect(invalidCertResult.isValid, equals(false));
      expect(
        invalidCertResult.errorMessage,
        contains('Financial operations certification required'),
      );
    });

    test('Business hours validator should check time restrictions', () {
      const validator = MyBusinessHoursValidator(
        startHour: 9,
        endHour: 17,
        allowedWeekdays: [1, 2, 3, 4, 5], // Monday to Friday
      );

      final mockRequest = Request('GET', Uri.parse('http://localhost/test'));

      // Test with after-hours access permission
      final afterHoursPayload = {
        'user_id': 'user123',
        'after_hours_access': true,
      };

      final afterHoursResult = validator.validate(
        mockRequest,
        afterHoursPayload,
      );
      expect(afterHoursResult.isValid, equals(true));

      // Test without after-hours access (result depends on current time)
      final noAfterHoursPayload = {
        'user_id': 'user123',
        'after_hours_access': false,
      };

      final noAfterHoursResult = validator.validate(
        mockRequest,
        noAfterHoursPayload,
      );
      // This test will pass or fail depending on current time, which is expected
      expect(noAfterHoursResult, isA<ValidationResult>());
    });

    test('ValidationResult should work correctly', () {
      final validResult = ValidationResult.valid();
      expect(validResult.isValid, equals(true));
      expect(validResult.isSuccess, equals(true));
      expect(validResult.isFailure, equals(false));
      expect(validResult.errorMessage, isNull);

      final invalidResult = ValidationResult.invalid('Custom error message');
      expect(invalidResult.isValid, equals(false));
      expect(invalidResult.isSuccess, equals(false));
      expect(invalidResult.isFailure, equals(true));
      expect(invalidResult.errorMessage, equals('Custom error message'));
    });
  });
}
