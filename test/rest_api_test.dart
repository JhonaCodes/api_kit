import 'package:dart_secure_api/rest_api.dart';
import 'package:test/test.dart';

void main() {
  group('DartSecureAPI Tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('SecurityConfig can be created', () {
      final config = SecurityConfig.development();
      expect(config.maxBodySize, equals(50 * 1024 * 1024)); // 50MB for dev
      expect(config.enableHttps, isFalse);
    });

    test('ApiResponse.success creates valid response', () {
      final response = ApiResponse.success({'id': '1', 'name': 'Test'});
      expect(response.success, isTrue);
      expect(response.data, isNotNull);
      expect(response.error, isNull);
    });

    test('ApiResponse.error creates valid error response', () {
      final response = ApiResponse.error('Test error');
      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response.error, equals('Test error'));
    });

    test('RateLimitConfig can be created', () {
      final config = RateLimitConfig.production();
      expect(config.maxRequests, equals(100));
      expect(config.window, equals(const Duration(minutes: 1)));
    });
  });
}
