/// Custom exception classes for different types of errors
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

/// Centralized error handler that converts technical errors to user-friendly messages
class ErrorHandler {
  /// Converts any exception to a user-friendly error message
  static String handleError(Object error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection and try again.';
    } else if (error is ApiException) {
      return _handleApiError(error);
    } else if (error is ValidationException) {
      return error.message;
    } else if (error.toString().contains('Network error')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toString().contains('Login failed')) {
      return 'Invalid username or password. Please try again.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handles API-specific errors based on status codes
  static String _handleApiError(ApiException error) {
    switch (error.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication failed. Please check your credentials.';
      case 403:
        return 'Access denied. Driver may not be assigned to a bus or route. Please contact administrator.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return error.message.isNotEmpty
            ? error.message
            : 'An error occurred. Please try again.';
    }
  }

  /// Creates a NetworkException for network-related errors
  static NetworkException createNetworkException(String message) {
    return NetworkException(message);
  }

  /// Creates an ApiException for API-related errors
  static ApiException createApiException(String message, {int? statusCode}) {
    return ApiException(message, statusCode: statusCode);
  }

  /// Creates a ValidationException for validation errors
  static ValidationException createValidationException(String message) {
    return ValidationException(message);
  }
}
