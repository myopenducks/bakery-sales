import 'package:dio/dio.dart';

/// Converts any exception (especially DioException) into a clean,
/// human-readable error message suitable for display in the UI.
String friendlyError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    // Try to extract a server-sent error message
    if (data is Map) {
      if (data['error'] != null) return data['error'].toString();
      if (data['message'] != null) return data['message'].toString();
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'Not authorized. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'A conflict occurred. This item may already exist.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error. Please try again.';
    }
  }

  return error.toString();
}
