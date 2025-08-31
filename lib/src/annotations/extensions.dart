import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

/// Extension to detect annotations generically
extension AnnotationExtension on Annotation {
  static final List<String> _myPackageUris = [
    'package:api_kit/src/annotations/annotations.dart',
    'package:api_kit/src/annotations/rest_annotations.dart',
    'package:api_kit/src/annotations/web/http_methods.dart',
    'package:api_kit/src/annotations/web/controller.dart',
    'package:api_kit/src/annotations/params/params.dart',
    'package:api_kit/src/annotations/jwt_annotations.dart',
  ];

  /// Checks if it is an annotation from our package
  bool get isFromMyPackage {
    final libraryId = elementAnnotation?.element?.library?.identifier;
    if (libraryId == null) return false;

    return _myPackageUris.any((uri) => libraryId == uri);
  }

  /// Gets the annotation type automatically
  String get annotationType {
    return name.name; // 'Get', 'Post', 'AutoDoc', etc.
  }

  /// Extracts all data from the annotation automatically
  Map<String, dynamic> get allAnnotationData {
    final evaluatedAnnotation = elementAnnotation?.computeConstantValue();
    if (evaluatedAnnotation == null) return <String, dynamic>{};

    return evaluatedAnnotation.toMap();
  }
}

/// Extension to convert DartObject to Map
extension DartObejctExtension on DartObject {
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    final objectType = type;

    if (objectType?.element case InterfaceElement element) {
      // Use pattern matching (Dart 3.0+)
      for (final field in element.fields) {
        if (!field.isSynthetic && field.name != null) {
          final fieldValue = getField(field.name!);
          if (fieldValue != null && !fieldValue.isNull) {
            map[field.name!] = _dartObjectToValue(fieldValue);
          }
        }
      }
    }

    return map;
  }

  dynamic _dartObjectToValue(
    DartObject dartObject, {
    Set<DartObject>? visited,
  }) {
    // Prevent infinite recursion
    visited ??= <DartObject>{};
    if (visited.contains(dartObject)) {
      return dartObject.type?.getDisplayString() ?? 'CircularRef';
    }
    visited.add(dartObject);

    try {
      return switch (dartObject) {
        _ when dartObject.toBoolValue() != null => dartObject.toBoolValue(),
        _ when dartObject.toIntValue() != null => dartObject.toIntValue(),
        _ when dartObject.toDoubleValue() != null => dartObject.toDoubleValue(),
        _ when dartObject.toStringValue() != null => dartObject.toStringValue(),
        _ when dartObject.toListValue() != null => () {
          final listValue = dartObject.toListValue()!;
          if (listValue.length > 10) {
            // Prevent huge lists from being processed
            return '${listValue.length} items';
          }
          return listValue
              .map((item) => _dartObjectToValue(item, visited: visited))
              .toList();
        }(),
        _ when dartObject.toMapValue() != null => () {
          final mapValue = dartObject.toMapValue()!;
          final result = <String, dynamic>{};
          var count = 0;
          mapValue.forEach((key, value) {
            if (key != null && value != null && count < 10) {
              // Limit map size
              final keyStr = _dartObjectToValue(
                key,
                visited: visited,
              ).toString();
              result[keyStr] = _dartObjectToValue(value, visited: visited);
              count++;
            }
          });
          return result;
        }(),
        _ when dartObject.type?.element is InterfaceElement => () {
          // For complex objects, just return type info to avoid deep recursion
          final typeName = dartObject.type?.getDisplayString() ?? 'Unknown';
          return {'_type': typeName};
        }(),
        _ => dartObject.toString(),
      };
    } finally {
      visited.remove(dartObject);
    }
  }
}
