/// Comprehensive tests for the static analysis migration
/// Validates that the new system works correctly and replaces mirrors
library;

import 'dart:io';
import 'package:api_kit/api_kit.dart';
import 'package:test/test.dart';

import 'test_controller_static.dart';

void main() {
  group('Static Analysis Migration Tests', () {
    late String testProjectPath;
    late TestControllerStatic testController;

    setUpAll(() {
      testProjectPath = Directory.current.path;
      testController = TestControllerStatic();
      // Clear any previous registrations
      MethodDispatcher.clearRegistry();
    });

    setUp(() {
      // Register controller methods before each test
      testController.registerMethods();
    });

    test('should detect annotations using static analysis', () async {
      final result = await AnnotationAPI.detectIn(testProjectPath);

      // Should find our test controller annotations
      expect(result.totalAnnotations, greaterThan(0));

      // Should detect RestController
      final restControllers = result.ofType('RestController');
      expect(restControllers, isNotEmpty);

      // Should detect HTTP methods
      final gets = result.ofType('Get');
      final posts = result.ofType('Post');
      final puts = result.ofType('Put');
      final deletes = result.ofType('Delete');

      expect(gets, isNotEmpty, reason: 'Should detect GET annotations');
      expect(posts, isNotEmpty, reason: 'Should detect POST annotations');
      expect(puts, isNotEmpty, reason: 'Should detect PUT annotations');
      expect(deletes, isNotEmpty, reason: 'Should detect DELETE annotations');
    });

    test('should validate RestController annotation data', () async {
      final result = await AnnotationAPI.detectIn(testProjectPath);

      final restControllers = result
          .ofType('RestController')
          .where((c) => c.targetName == 'TestControllerStatic')
          .toList();

      expect(restControllers, hasLength(1));

      final controller = restControllers.first;
      expect(controller.restControllerInfo!.basePath, equals('/api/test'));
    });

    test('should validate HTTP method annotation data', () async {
      final result = await AnnotationAPI.detectIn(testProjectPath);

      // Validate GET annotation
      final getHello = result
          .ofType('Get')
          .where((g) => g.targetName.contains('getHello'))
          .toList();

      expect(getHello, hasLength(1));
      expect(getHello.first.getInfo!.path, equals('/hello'));
      expect(getHello.first.getInfo!.statusCode, equals(200));
      expect(getHello.first.getInfo!.requiresAuth, isFalse);

      // Validate POST annotation - filter by our specific controller
      final createUser = result
          .ofType('Post')
          .where(
            (p) => p.targetName.contains('TestControllerStatic.createUser'),
          )
          .toList();

      expect(createUser, hasLength(1));
      expect(createUser.first.postInfo!.path, equals('/users'));
      expect(createUser.first.postInfo!.statusCode, equals(201));
      expect(createUser.first.postInfo!.requiresAuth, isTrue);
      expect(
        createUser.first.postInfo!.description,
        equals('Create a new user'),
      );
    });

    test('should register methods in dispatcher', () async {
      expect(
        MethodDispatcher.isMethodRegistered('TestControllerStatic', 'getHello'),
        isTrue,
      );
      expect(
        MethodDispatcher.isMethodRegistered(
          'TestControllerStatic',
          'createUser',
        ),
        isTrue,
      );
      expect(
        MethodDispatcher.isMethodRegistered(
          'TestControllerStatic',
          'updateUser',
        ),
        isTrue,
      );
      expect(
        MethodDispatcher.isMethodRegistered(
          'TestControllerStatic',
          'deleteUser',
        ),
        isTrue,
      );

      final registeredMethods = MethodDispatcher.getRegisteredMethods(
        'TestControllerStatic',
      );
      expect(registeredMethods, hasLength(5));
    });

    test('should call methods through dispatcher', () async {
      final request = Request('GET', Uri.parse('http://localhost/test'));

      final response = await MethodDispatcher.callMethod(
        'TestControllerStatic',
        'getHello',
        request,
      );

      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      expect(body, contains('Hello from static analysis!'));
    });

    test('should build router using static analysis', () async {
      final router = await StaticRouterBuilder.buildFromController(
        testController,
        projectPath: testProjectPath,
      );

      expect(router, isNotNull);
      // Router should be configured but we can't easily test the internal routes
      // without actually making HTTP requests
    });

    test('should use static analysis in RouterBuilder', () async {
      final router = await RouterBuilder.buildFromController(testController);
      expect(router, isNotNull);

      final routingMethod = await RouterBuilder.getRoutingMethod(
        testController,
      );
      expect(routingMethod, contains('Static Analysis'));

      final stats = await RouterBuilder.getRoutingStats(testController);
      expect(stats['is_aot_compatible'], isTrue);
      expect(stats['controller_type'], equals('TestControllerStatic'));
    });

    test('should handle method dispatch errors gracefully', () async {
      final request = Request('GET', Uri.parse('http://localhost/test'));

      // Try to call non-existent method
      final response = await MethodDispatcher.callMethod(
        'TestControllerStatic',
        'nonExistentMethod',
        request,
      );

      expect(response.statusCode, equals(404));
    });

    test('should handle non-existent controller gracefully', () async {
      final request = Request('GET', Uri.parse('http://localhost/test'));

      final response = await MethodDispatcher.callMethod(
        'NonExistentController',
        'someMethod',
        request,
      );

      expect(response.statusCode, equals(404));
    });

    test('should provide registry statistics', () async {
      final stats = MethodDispatcher.getRegistryStats();
      expect(stats, isNotEmpty);
      expect(stats['TestControllerStatic'], equals(5));

      final controllers = MethodDispatcher.getRegisteredControllers();
      expect(controllers, contains('TestControllerStatic'));
    });

    test('should validate annotation path combinations', () async {
      final result = await AnnotationAPI.detectIn(testProjectPath);

      // Find controller base path
      final controller = result
          .ofType('RestController')
          .firstWhere((c) => c.targetName == 'TestControllerStatic');
      final basePath = controller.restControllerInfo!.basePath;
      expect(basePath, equals('/api/test'));

      // Validate combined paths would be correct
      final getUser = result
          .ofType('Get')
          .firstWhere((g) => g.targetName.contains('getUser'));
      expect(getUser.getInfo!.path, equals('/user/{id}'));
      // Combined would be: /api/test/user/{id}

      final createUser = result
          .ofType('Post')
          .firstWhere((p) => p.targetName.contains('createUser'));
      expect(createUser.postInfo!.path, equals('/users'));
      // Combined would be: /api/test/users
    });
  });

  group('Non-BaseController Tests', () {
    test('should handle non-BaseController objects gracefully', () async {
      // Test that the system handles non-BaseController objects
      // Should return empty router with clear instructions

      // Create a non-BaseController object
      final nonBaseController = Object();

      final router = await RouterBuilder.buildFromController(nonBaseController);
      expect(router, isNotNull); // Should return empty router with instructions

      final routingMethod = await RouterBuilder.getRoutingMethod(
        nonBaseController,
      );
      expect(routingMethod, contains('Manual Registration Required'));
    });
  });

  group('Error Handling Tests', () {
    test('should handle missing project path gracefully', () async {
      expect(
        () async => await AnnotationAPI.detectIn('/nonexistent/path'),
        returnsNormally, // Should not throw but return empty results
      );
    });

    test('should handle empty controller registration', () async {
      MethodDispatcher.clearRegistry();

      final stats = MethodDispatcher.getRegistryStats();
      expect(stats, isEmpty);

      final controllers = MethodDispatcher.getRegisteredControllers();
      expect(controllers, isEmpty);
    });
  });

  group('Performance Tests', () {
    test('should complete static analysis within reasonable time', () async {
      final stopwatch = Stopwatch()..start();
      final projectPath = Directory.current.path;

      final result = await AnnotationAPI.detectIn(projectPath);

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10000),
      ); // Should complete within 10 seconds
      expect(result.processingTime.inMilliseconds, lessThan(10000));
    });

    test('should handle method dispatch efficiently', () async {
      final request = Request('GET', Uri.parse('http://localhost/test'));
      final controller = TestControllerStatic();
      controller.registerMethods();

      final stopwatch = Stopwatch()..start();

      // Call method multiple times
      for (int i = 0; i < 100; i++) {
        await MethodDispatcher.callMethod(
          'TestControllerStatic',
          'getHello',
          request,
        );
      }

      stopwatch.stop();

      // Should complete 100 calls reasonably quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
