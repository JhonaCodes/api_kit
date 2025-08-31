import 'package:result_controller/result_controller.dart';
import 'package:shelf/shelf.dart';
import 'dart:convert';

/// Standardized API result handling using result_controller.
/// This replaces the old ApiResponse pattern with proper Ok/Err semantics.
class ApiKit {
  /// Creates a success result with data.
  static ApiResult<T> ok<T>(T data) {
    return ApiResult.ok(data);
  }

  /// Creates an error result with details.
  static ApiResult<T> err<T>({
    required String title,
    String? message,
    Object? exception,
    StackTrace? stackTrace,
    Map<String, String>? validations,
  }) {
    return ApiResult.err(
      ApiErr(
        title: title,
        msm: message,
        exception: exception,
        stackTrace: stackTrace,
        validations: validations,
      ),
    );
  }

  /// Creates a not found error result.
  static ApiResult<T> notFound<T>([String? message]) {
    return ApiResult.err(
      ApiErr(title: 'NOT_FOUND', msm: message ?? 'Resource not found'),
    );
  }

  /// Creates a bad request error result.
  static ApiResult<T> badRequest<T>(
    String message, {
    Map<String, String>? validations,
  }) {
    return ApiResult.err(
      ApiErr(title: 'BAD_REQUEST', msm: message, validations: validations),
    );
  }

  /// Creates an unauthorized error result.
  static ApiResult<T> unauthorized<T>([String? message]) {
    return ApiResult.err(
      ApiErr(title: 'UNAUTHORIZED', msm: message ?? 'Unauthorized access'),
    );
  }

  /// Creates a forbidden error result.
  static ApiResult<T> forbidden<T>([String? message]) {
    return ApiResult.err(
      ApiErr(title: 'FORBIDDEN', msm: message ?? 'Access forbidden'),
    );
  }

  /// Creates a conflict error result.
  static ApiResult<T> conflict<T>(String message) {
    return ApiResult.err(ApiErr(title: 'CONFLICT', msm: message));
  }

  /// Creates an internal server error result.
  static ApiResult<T> serverError<T>(
    String message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return ApiResult.err(
      ApiErr(
        title: 'INTERNAL_SERVER_ERROR',
        msm: message,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }
}

/// Response builder for converting ApiResult to HTTP responses.
/// Use this to convert your business logic results into HTTP responses.
class ApiResponseBuilder {
  /// Converts an ApiResult to an HTTP Response.
  static Response fromResult<T>(ApiResult<T> result) {
    return result.when(
      ok: (data) => _buildSuccessResponse(data),
      err: (error) => _buildErrorResponse(error),
    );
  }

  /// Builds a success response with data.
  static Response _buildSuccessResponse<T>(T data, {int statusCode = 200}) {
    final responseBody = {
      'success': true,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response(
      statusCode,
      body: jsonEncode(responseBody),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// Builds an error response from ApiErr.
  static Response _buildErrorResponse(ApiErr error) {
    final statusCode = _getStatusCodeFromError(error);
    final responseBody = {
      'success': false,
      'error': {
        'code': error.title ?? 'UNKNOWN_ERROR',
        'message': error.msm ?? 'An unexpected error occurred',
        if (error.validations != null && error.validations!.isNotEmpty)
          'validations': error.validations,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    return Response(
      statusCode,
      body: jsonEncode(responseBody),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// Determines HTTP status code from error title.
  static int _getStatusCodeFromError(ApiErr error) {
    final title = error.title?.toUpperCase() ?? '';

    switch (title) {
      case 'BAD_REQUEST':
      case 'VALIDATION_ERROR':
      case 'INVALID_INPUT':
        return 400;
      case 'UNAUTHORIZED':
        return 401;
      case 'FORBIDDEN':
        return 403;
      case 'NOT_FOUND':
        return 404;
      case 'CONFLICT':
        return 409;
      case 'UNPROCESSABLE_ENTITY':
        return 422;
      case 'INTERNAL_SERVER_ERROR':
      default:
        return 500;
    }
  }
}
