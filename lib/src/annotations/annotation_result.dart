import 'annotation_details.dart';

/// Class that gets all the data and units of the annotations.
class AnnotationResult {
  final List<AnnotationDetails> annotationList;
  final Duration processingTime;

  AnnotationResult({
    required this.annotationList,
    required this.processingTime,
  });

  int get totalAnnotations => annotationList.length;

  Map<String, int> get annotationStats {
    final Map<String, int> stats = <String, int>{};

    /// Gets the stats in a map
    for (final annotation in annotationList) {
      stats[annotation.annotationType] =
          (stats[annotation.annotationType] ?? 0) + 1;
    }

    return stats;
  }
}
