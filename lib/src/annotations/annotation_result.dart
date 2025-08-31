import 'annotation_details.dart';

/// Clase que obtiene todos los datos y unidades de las annotaciones.
class AnnotationResult {
  final List<AnnotationDetails> annotationList;
  final Duration processingTime;

  AnnotationResult({
    required this.annotationList,
    required this.processingTime,
  });

  int get totalAnnotations => annotationList.length;

  Map<String, int> get annotationStats {

    final Map<String, int> stats = <String, int> {};

    /// Obtiene lo stats en un map
    for (final annotation in annotationList) {
      stats[annotation.annotationType] = (stats[annotation.annotationType] ?? 0) + 1;
    }

    return stats;
  }
}
