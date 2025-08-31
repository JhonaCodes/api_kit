/*

 El enum me ayuda definir los tipos de target en el analisis.
 */

import 'annotation_data.dart';

enum AnnotationTargetType {
  topLevelFunction,
  instanceMethod,
  staticMethod,
  class_,
  field,
  variable,
}

/// Clase que contiene todos los datos de una anotación encontrada
class AnnotationDetails {
  final String targetName;                   // Nombre del elemento anotado (ej: 'getUsers')
  final String annotationType;               // Tipo de anotación (ej: 'Get')
  final AnnotationTargetType targetType;     // Tipo de elemento (función, método, clase)
  final AnnotationData data;                 // Datos tipados de la anotación
  final Map<String, dynamic> rawData;        // Datos raw por compatibilidad
  final String? filePath;                    // Archivo donde se encontró
  final int? lineNumber;                     // Línea donde se encontró

  const AnnotationDetails({
    required this.targetName,
    required this.annotationType,
    required this.targetType,
    required this.data,
    required this.rawData,
    this.filePath,
    this.lineNumber,
  });

  /// Constructor factory que crea la instancia con datos tipados
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
  
  /// Getter específico para @Get
  GetData? get getInfo => data is GetData ? data as GetData : null;
  
  /// Getter específico para @Post
  PostData? get postInfo => data is PostData ? data as PostData : null;
  
  /// Getter específico para @Put
  PutData? get putInfo => data is PutData ? data as PutData : null;
  
  /// Getter específico para @Patch
  PatchData? get patchInfo => data is PatchData ? data as PatchData : null;
  
  /// Getter específico para @Delete
  DeleteData? get deleteInfo => data is DeleteData ? data as DeleteData : null;
  
  // === CONTROLLER GETTERS ===
  
  /// Getter específico para @RestController
  RestControllerData? get restControllerInfo => data is RestControllerData ? data as RestControllerData : null;
  
  /// Getter específico para @Service
  ServiceData? get serviceInfo => data is ServiceData ? data as ServiceData : null;
  
  /// Getter específico para @Repository
  RepositoryData? get repositoryInfo => data is RepositoryData ? data as RepositoryData : null;
  
  // === PARAMETER GETTERS ===
  
  /// Getter específico para @Param
  ParamData? get paramInfo => data is ParamData ? data as ParamData : null;
  
  /// Getter específico para @PathParam
  PathParamData? get pathParamInfo => data is PathParamData ? data as PathParamData : null;
  
  /// Getter específico para @QueryParam
  QueryParamData? get queryParamInfo => data is QueryParamData ? data as QueryParamData : null;
  
  /// Getter específico para @RequestBody
  RequestBodyData? get requestBodyInfo => data is RequestBodyData ? data as RequestBodyData : null;
  
  /// Getter específico para @RequestHeader
  RequestHeaderData? get requestHeaderInfo => data is RequestHeaderData ? data as RequestHeaderData : null;
  
  /// Acceso backward-compatible al Map
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
