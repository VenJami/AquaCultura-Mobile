/// A model class to standardize API responses
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  /// Creates a successful response
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  /// Creates an error response
  factory ApiResponse.error(dynamic error, {String? message}) {
    return ApiResponse(
      success: false,
      error: error,
      message: message ?? 'An error occurred',
    );
  }

  /// Converts a JSON object to ApiResponse
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] as T?,
      message: json['message'],
      error: json['error'],
    );
  }

  /// Converts ApiResponse to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'error': error,
    };
  }
}
