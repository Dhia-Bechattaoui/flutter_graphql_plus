/// Utility class for handling GraphQL errors and exceptions
class ErrorHandler {
  /// Handle GraphQL errors and convert them to user-friendly messages
  static String handleGraphQLError(dynamic error) {
    if (error is String) {
      return error;
    }

    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      if (message != null) {
        return message;
      }
    }

    return 'An unexpected error occurred';
  }

  /// Check if an error is a network error
  static bool isNetworkError(dynamic error) {
    if (error is String) {
      return error.toLowerCase().contains('network') ||
          error.toLowerCase().contains('connection') ||
          error.toLowerCase().contains('timeout');
    }

    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      if (message != null) {
        return message.toLowerCase().contains('network') ||
            message.toLowerCase().contains('connection') ||
            message.toLowerCase().contains('timeout');
      }
    }

    return false;
  }

  /// Check if an error is an authentication error
  static bool isAuthError(dynamic error) {
    if (error is String) {
      return error.toLowerCase().contains('unauthorized') ||
          error.toLowerCase().contains('forbidden') ||
          error.toLowerCase().contains('authentication');
    }

    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      if (message != null) {
        return message.toLowerCase().contains('unauthorized') ||
            message.toLowerCase().contains('forbidden') ||
            message.toLowerCase().contains('authentication');
      }
    }

    return false;
  }

  /// Get error severity level
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (isAuthError(error)) {
      return ErrorSeverity.critical;
    }

    if (isNetworkError(error)) {
      return ErrorSeverity.warning;
    }

    return ErrorSeverity.error;
  }
}

/// Error severity levels
enum ErrorSeverity {
  /// Low priority error
  low,

  /// Normal error
  error,

  /// Warning level
  warning,

  /// Critical error
  critical,
}
