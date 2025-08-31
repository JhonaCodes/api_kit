// lib/annotation_api.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'detector.dart';
import 'annotation_result.dart';
import 'annotation_details.dart';

/// Simple API to detect annotations
class AnnotationAPI {
  /// Detects annotations in the current directory
  static Future<AnnotationResult> detect() async {
    return detectIn(Directory.current.path);
  }

  /// Detects annotations in a specific directory
  static Future<AnnotationResult> detectIn(
    String inputPath, {
    List<String>? includePaths,
  }) async {
    // Normalize the path to be absolute
    final absolutePath = path.isAbsolute(inputPath)
        ? path.normalize(inputPath)
        : path.normalize(path.absolute(inputPath));

    final projectDir = Directory(absolutePath);
    final detector = AnnotationDetector(
      projectRoot: projectDir,
      includePaths: includePaths,
    );
    return await detector.detect();
  }

  /// Detects only annotations of a specific type
  static Future<List<AnnotationDetails>> detectType(
    String annotationType, {
    String? path,
    List<String>? includePaths,
  }) async {
    final result = path != null
        ? await detectIn(path, includePaths: includePaths)
        : await detect();
    return result.annotationList
        .where((annotation) => annotation.annotationType == annotationType)
        .toList();
  }

  /// Gets only GET endpoints
  static Future<List<AnnotationDetails>> getEndpoints({
    String? path,
    List<String>? includePaths,
  }) async {
    return await detectType('Get', path: path, includePaths: includePaths);
  }

  /// Gets quick stats
  static Future<Map<String, int>> getStats({
    String? path,
    List<String>? includePaths,
  }) async {
    final result = path != null
        ? await detectIn(path, includePaths: includePaths)
        : await detect();
    return result.annotationStats;
  }
}

/// Extensions to facilitate use
extension AnnotationResultExtensions on AnnotationResult {
  /// Gets only annotations of a type
  List<AnnotationDetails> ofType(String type) {
    return annotationList.where((a) => a.annotationType == type).toList();
  }

  /// Gets only GET endpoints
  List<AnnotationDetails> get getEndpoints {
    return ofType('Get');
  }

  /// Prints results in a simple way
  void printResults() {
    print('📊 Total: $totalAnnotations annotations');
    print('⏱️  Time: ${processingTime.inMilliseconds}ms');

    if (annotationStats.isNotEmpty) {
      print('\n📈 Stats:');
      annotationStats.forEach((type, count) => print('• $type: $count'));
    }

    print('\n🔍 Found:');
    for (final annotation in annotationList) {
      print('📌 ${annotation.annotationType} → ${annotation.targetName}');
      if (annotation.annotationData.isNotEmpty) {
        annotation.annotationData.forEach((key, value) {
          print('   $key: $value');
        });
      }
    }
  }

  /// Prints only GET endpoints clearly
  void printEndpoints() {
    final endpoints = getEndpoints;
    print('🌐 REST Endpoints (${endpoints.length}):');

    for (final endpoint in endpoints) {
      // Use typed properties
      final path =
          endpoint.getInfo?.path ??
          endpoint.annotationData['path']?.toString() ??
          '';
      print('• GET $path → ${endpoint.targetName}');
    }
  }
}
