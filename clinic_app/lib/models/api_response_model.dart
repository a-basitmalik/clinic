class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? pagination;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success:    json['success'] as bool? ?? false,
      message:    json['message'] as String? ?? '',
      data:       fromData != null && json['data'] != null
                      ? fromData(json['data'])
                      : json['data'] as T?,
      errors:     json['errors'] as Map<String, dynamic>?,
      pagination: json['pagination'] as Map<String, dynamic>?,
    );
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;

  String get firstError {
    if (errors == null || errors!.isEmpty) return message;
    return errors!.values.first.toString();
  }
}

/// Thrown when the server returns a non-2xx status code or success:false.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
