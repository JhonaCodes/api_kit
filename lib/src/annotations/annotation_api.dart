// lib/annotation_api.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'detector.dart';
import 'annotation_result.dart';
import 'annotation_details.dart';

/// API Simple para detectar anotaciones
class AnnotationAPI {
  /// Detecta anotaciones en el directorio actual
  static Future<AnnotationResult> detect() async {
    return detectIn(Directory.current.path);
  }

  /// Detecta anotaciones en un directorio específico
  static Future<AnnotationResult> detectIn(String inputPath) async {
    // Normalizar la ruta para que sea absoluta
    final absolutePath = path.isAbsolute(inputPath)
        ? path.normalize(inputPath)
        : path.normalize(path.absolute(inputPath));

    final projectDir = Directory(absolutePath);
    final detector = AnnotationDetector(projectRoot: projectDir);
    return await detector.detect();
  }

  /// Detecta solo anotaciones de un tipo específico
  static Future<List<AnnotationDetails>> detectType(
    String annotationType, {
    String? path,
  }) async {
    final result = path != null ? await detectIn(path) : await detect();
    return result.annotationList
        .where((annotation) => annotation.annotationType == annotationType)
        .toList();
  }

  /// Obtiene solo los endpoints GET
  static Future<List<AnnotationDetails>> getEndpoints({String? path}) async {
    return await detectType('Get', path: path);
  }

  /// Obtiene estadísticas rápidas
  static Future<Map<String, int>> getStats({String? path}) async {
    final result = path != null ? await detectIn(path) : await detect();
    return result.annotationStats;
  }
}

/// Extensions para facilitar el uso
extension AnnotationResultExtensions on AnnotationResult {
  /// Obtiene solo anotaciones de un tipo
  List<AnnotationDetails> ofType(String type) {
    return annotationList.where((a) => a.annotationType == type).toList();
  }

  /// Obtiene solo endpoints GET
  List<AnnotationDetails> get getEndpoints {
    return ofType('Get');
  }

  /// Imprime resultados de forma simple
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

  /// Imprime solo endpoints GET de forma clara
  void printEndpoints() {
    final endpoints = getEndpoints;
    print('🌐 REST Endpoints (${endpoints.length}):');

    for (final endpoint in endpoints) {
      // Usar propiedades tipadas
      final path =
          endpoint.getInfo?.path ??
          endpoint.annotationData['path']?.toString() ??
          '';
      print('• GET $path → ${endpoint.targetName}');
    }
  }
}
