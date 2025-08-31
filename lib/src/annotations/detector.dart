import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'annotation_visitor.dart';
import 'annotation_result.dart';

class AnnotationDetector {
  final Directory projectRoot;
  final List<String>? includePaths;

  AnnotationDetector({
    required this.projectRoot,
    this.includePaths, // Optional custom paths
  });

  Future<AnnotationResult> detect() async {
    final stopwatch = Stopwatch()..start();

    try {
      final collection = AnalysisContextCollection(
        includedPaths: [projectRoot.absolute.path],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      return await _performAnalysis(collection, stopwatch);
    } catch (e) {
      // If we get SDK errors (common with Flutter test), return empty result
      if (e.toString().contains('PathNotFoundException') ||
          e.toString().contains('sdk_library_metadata') ||
          e.toString().contains('libraries.dart')) {
        stopwatch.stop();
        return AnnotationResult(
          annotationList: [],
          processingTime: stopwatch.elapsed,
        );
      }
      rethrow;
    }
  }

  Future<AnnotationResult> _performAnalysis(
    AnalysisContextCollection collection,
    Stopwatch stopwatch,
  ) async {
    final visitor = AnnotationVisitor();

    for (final context in collection.contexts) {
      // Use custom include paths if provided, otherwise default paths
      final projectPath = projectRoot.absolute.path;
      final List<String> pathsToInclude;

      if (includePaths != null && includePaths!.isNotEmpty) {
        // Use custom paths - make them absolute
        pathsToInclude = includePaths!.map((path) {
          if (path.startsWith('/')) return path;
          return '$projectPath/$path';
        }).toList();
      } else {
        // Default paths: lib/, bin/, and example/
        pathsToInclude = [
          '$projectPath/lib',
          '$projectPath/bin',
          '$projectPath/example',
        ];
      }

      final files = context.contextRoot
          .analyzedFiles()
          .where((file) => file.endsWith('.dart'))
          .where((file) => !file.contains('.dart_tool'))
          .where(
            (file) => pathsToInclude.any(
              (includePath) => file.startsWith(includePath),
            ),
          )
          .toList();

      for (final filePath in files) {
        final libraryResult = await context.currentSession.getResolvedLibrary(
          filePath,
        );
        if (libraryResult is ResolvedLibraryResult) {
          for (final unit in libraryResult.units) {
            unit.unit.visitChildren(visitor);
          }
        }
      }
    }

    stopwatch.stop();
    return AnnotationResult(
      annotationList: visitor.foundAnnotations,
      processingTime: stopwatch.elapsed,
    );
  }
}
