/*

The enum helps me define the target types in the analysis.
 */

import 'package:api_kit/api_kit.dart';

enum AnnotationTargetType {
  topLevelFunction,
  instanceMethod,
  staticMethod,
  class_,
  field,
  variable,
}

/// Class that contains all the data of a found annotation
class AnnotationDetails {
  final String targetName; // Name of the annotated element (e.g., 'getUsers')
  final String annotationType; // Type of annotation (e.g., 'Get')
  final AnnotationTargetType
  targetType; // Type of element (function, method, class)
  final AnnotationData data; // Typed data of the annotation
  final Map<String, dynamic> rawData; // Raw data for compatibility
  final String? filePath; // File where it was found
  final int? lineNumber; // Line where it was found

  const AnnotationDetails({
    required this.targetName,
    required this.annotationType,
    required this.targetType,
    required this.data,
    required this.rawData,
    this.filePath,
    this.lineNumber,
  });

  /// Factory constructor that creates the instance with typed data
  factory AnnotationDetails.create({
    required String targetName,
    required String annotationType,
    required AnnotationTargetType targetType,
    required Map<String, dynamic> annotationData,
    String? filePath,
    int? lineNumber,
  }) {
    return AnnotationDetails(
      targetName: targetName,
      annotationType: annotationType,
      targetType: targetType,
      data: AnnotationData.fromMap(annotationType, annotationData),
      rawData: annotationData,
      filePath: filePath,
      lineNumber: lineNumber,
    );
  }

  // === HTTP METHOD GETTERS ===

  /// Specific getter for @Get
  GetData? get getInfo => data is GetData ? data as GetData : null;

  /// Specific getter for @Post
  PostData? get postInfo => data is PostData ? data as PostData : null;

  /// Specific getter for @Put
  PutData? get putInfo => data is PutData ? data as PutData : null;

  /// Specific getter for @Patch
  PatchData? get patchInfo => data is PatchData ? data as PatchData : null;

  /// Specific getter for @Delete
  DeleteData? get deleteInfo => data is DeleteData ? data as DeleteData : null;

  // === CONTROLLER GETTERS ===

  /// Specific getter for @RestController
  RestControllerData? get restControllerInfo =>
      data is RestControllerData ? data as RestControllerData : null;

  /// Specific getter for @Service
  ServiceData? get serviceInfo =>
      data is ServiceData ? data as ServiceData : null;

  /// Specific getter for @Repository
  RepositoryData? get repositoryInfo =>
      data is RepositoryData ? data as RepositoryData : null;

  // === PARAMETER GETTERS ===

  /// Specific getter for @Param
  ParamData? get paramInfo => data is ParamData ? data as ParamData : null;

  /// Specific getter for @PathParam
  PathParamData? get pathParamInfo =>
      data is PathParamData ? data as PathParamData : null;

  /// Specific getter for @QueryParam
  QueryParamData? get queryParamInfo =>
      data is QueryParamData ? data as QueryParamData : null;

  /// Specific getter for @RequestBody
  RequestBodyData? get requestBodyInfo =>
      data is RequestBodyData ? data as RequestBodyData : null;

  /// Specific getter for @RequestHeader
  RequestHeaderData? get requestHeaderInfo =>
      data is RequestHeaderData ? data as RequestHeaderData : null;

  /// Backward-compatible access to the Map
  Map<String, dynamic> get annotationData => rawData;

  @override
  String toString() {
    return 'AnnotationDetails('
        'target: $targetName, '
        'type: $annotationType, '
        'targetType: $targetType, '
        'data: $data'
        ')';
  }
}
