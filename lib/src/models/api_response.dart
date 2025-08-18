import 'dart:convert';

/// Standard API response model.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.statusCode,
  });

  /// Creates a successful response.
  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  /// Creates an error response.
  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode ?? 500,
    );
  }

  /// Creates a not found response.
  factory ApiResponse.notFound([String? message]) {
    return ApiResponse<T>(
      success: false,
      error: message ?? 'Resource not found',
      statusCode: 404,
    );
  }

  /// Creates a bad request response.
  factory ApiResponse.badRequest(String error) {
    return ApiResponse<T>(success: false, error: error, statusCode: 400);
  }

  /// Creates an unauthorized response.
  factory ApiResponse.unauthorized([String? message]) {
    return ApiResponse<T>(
      success: false,
      error: message ?? 'Unauthorized',
      statusCode: 401,
    );
  }

  /// Creates a forbidden response.
  factory ApiResponse.forbidden([String? message]) {
    return ApiResponse<T>(
      success: false,
      error: message ?? 'Forbidden',
      statusCode: 403,
    );
  }

  /// Converts the response to JSON.
  String toJson() {
    final Map<String, dynamic> json = {'success': success};

    if (data != null) json['data'] = data;
    if (error != null) json['error'] = error;
    if (message != null) json['message'] = message;
    if (statusCode != null) json['status_code'] = statusCode;

    return jsonEncode(json);
  }

  /// Creates an ApiResponse from JSON.
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'],
      error: json['error'],
      message: json['message'],
      statusCode: json['status_code'],
    );
  }
}
