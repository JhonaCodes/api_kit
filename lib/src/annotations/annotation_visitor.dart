import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'annotation_details.dart';
import 'extensions.dart';

class AnnotationVisitor extends RecursiveAstVisitor<void> {
  final bool verbose;
  final List<AnnotationDetails> foundAnnotations = [];

  // Context tracking
  FunctionDeclaration? _currentFunction;
  ClassDeclaration? _currentClass;
  MethodDeclaration? _currentMethod;

  AnnotationVisitor({this.verbose = false});

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _currentFunction = node;
    super.visitFunctionDeclaration(node);
    _currentFunction = null;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _currentClass = node;
    super.visitClassDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _currentMethod = node;
    super.visitMethodDeclaration(node);
    _currentMethod = null;
  }

  @override
  void visitAnnotation(Annotation node) {
    if (verbose) {
      print('DEBUG: Found annotation: ${node.name.name}');
      print(
        'DEBUG: Library ID: ${node.elementAnnotation?.element?.library?.identifier}',
      );
      print('DEBUG: Is from my package: ${node.isFromMyPackage}');
    }

    // Usar extensions genéricas - detecta CUALQUIER anotación de nuestro package
    if (node.isFromMyPackage) {
      final context = _getCurrentContext();
      if (context != null) {
        final annotationData = node.allAnnotationData;

        if (verbose) {
          print(
            'DEBUG: Adding annotation ${node.annotationType} for ${context.name}',
          );
        }

        foundAnnotations.add(
          AnnotationDetails.create(
            targetName: context.name,
            annotationType: node.annotationType,
            targetType: context.type,
            annotationData: annotationData,
            filePath: null, // TODO: Implementar después
            lineNumber: node.offset,
          ),
        );
      }
    }
  }

  _Context? _getCurrentContext() {
    if (_currentFunction != null) {
      return _Context(
        _currentFunction!.name.lexeme,
        AnnotationTargetType.topLevelFunction,
      );
    }
    if (_currentClass != null && _currentMethod != null) {
      return _Context(
        '${_currentClass!.name.lexeme}.${_currentMethod!.name.lexeme}',
        AnnotationTargetType.instanceMethod,
      );
    }
    if (_currentClass != null) {
      return _Context(_currentClass!.name.lexeme, AnnotationTargetType.class_);
    }
    return null;
  }
}

class _Context {
  final String name;
  final AnnotationTargetType type;
  _Context(this.name, this.type);
}
