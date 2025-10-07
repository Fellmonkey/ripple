import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../error/failures.dart';
import 'models/result.dart';

/// Appwrite exception handler based on official documentation
/// https://appwrite.io/docs/advanced/platform/response-codes
/// https://appwrite.io/docs/advanced/platform/error-handling
class AppwriteExceptionHandler {
  AppwriteExceptionHandler._();

  /// Convert Appwrite exception to typed failure
  static Failure handleAppwriteException(AppwriteException exception) {
    final message = exception.message ?? 'Unknown error occurred';
    final type = exception.type ?? 'unknown';
    final code = exception.code ?? 500;

    // Classify by error type prefix (most reliable method)
    final failureType = _classifyByType(type);
    if (failureType != null) {
      return failureType(message: message, type: type, code: code);
    }

    // Fallback: classify by HTTP status code
    return _classifyByCode(code, message: message, type: type);
  }

  /// Handle general exceptions (non-Appwrite)
  static Failure handleGeneralException(Object exception) {
    if (exception is AppwriteException) {
      return handleAppwriteException(exception);
    }

    if (exception is FormatException) {
      return ValidationFailure(
        message: 'Invalid data format: ${exception.message}',
        type: 'validation_format_error',
        code: 400,
      );
    }

    if (exception is TypeError) {
      return ValidationFailure(
        message: 'Data type error: ${exception.toString()}',
        type: 'validation_type_error',
        code: 400,
      );
    }

    return PlatformFailure(
      message: exception.toString(),
      type: 'general_unknown',
      code: 500,
    );
  }

  /// Classify failure by Appwrite error type prefix
  static Failure Function({
    required String message,
    required String type,
    required int code,
  })? _classifyByType(String type) {
    // Authentication errors
    if (type.startsWith('user_') ||
        type.startsWith('team_') ||
        type.startsWith('membership_')) {
      return AuthFailure.new;
    }

    // Database errors
    if (type.startsWith('database_') ||
        type.startsWith('table_') ||
        type.startsWith('row_') ||
        type.startsWith('column_') ||
        type.startsWith('index_') ||
        type.startsWith('execution_')) {
      return DatabaseFailure.new;
    }

    // Storage errors
    if (type.startsWith('storage_')) {
      return StorageFailure.new;
    }

    // Function errors
    if (type.startsWith('function_') ||
        type.startsWith('build_') ||
        type.startsWith('deployment_') ||
        type.startsWith('installation_') ||
        type.startsWith('provider_repository_') ||
        type.startsWith('repository_') ||
        type.startsWith('variable_')) {
      return FunctionFailure.new;
    }

    return null;
  }

  /// Classify failure by HTTP status code
  static Failure _classifyByCode(
    int code, {
    required String message,
    required String type,
  }) {
    switch (code) {
      // 400: Bad Request - Validation
      case 400:
        return ValidationFailure(message: message, type: type, code: code);

      // 401: Unauthorized, 403: Forbidden - Auth
      case 401:
      case 403:
        return AuthFailure(message: message, type: type, code: code);

      // 404: Not Found - depends on context, default to Platform
      case 404:
        return PlatformFailure(message: message, type: type, code: code);

      // 409: Conflict - depends on context, default to Platform
      case 409:
        return PlatformFailure(message: message, type: type, code: code);

      // 429: Rate Limit, 503: Service Unavailable, 504: Gateway Timeout - Network
      case 429:
      case 503:
      case 504:
        return NetworkFailure(message: message, type: type, code: code);

      // Default: Platform error
      default:
        return PlatformFailure(message: message, type: type, code: code);
    }
  }
}

/// Safe execution wrapper for async operations with enhanced error handling
class SafeExecutor {
  
  /// Execute operation with comprehensive error handling
  static Future<Result<T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } on AppwriteException catch (e) {
      final failure = AppwriteExceptionHandler.handleAppwriteException(e);
      _logError(operationName, e, failure);
      return Error(failure);
    } catch (e) {
      final failure = AppwriteExceptionHandler.handleGeneralException(e);
      _logError(operationName, e, failure);
      return Error(failure);
    }
  }

  /// Execute operation with custom error mapping
  static Future<Result<T>> executeWithMapping<T>(
    Future<T> Function() operation,
    Failure Function(Object exception) errorMapper, {
    String? operationName,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      final failure = errorMapper(e);
      _logError(operationName, e, failure);
      return Error(failure);
    }
  }

  /// Log errors for debugging (in production, use proper logging service)
  static void _logError(String? operationName, Object exception, Failure failure) {
    final operation = operationName ?? 'Unknown operation';
    debugPrint('ERROR in $operation: ${failure.type} - ${failure.message}');
    debugPrint('Original exception: $exception');
    // In production, replace with proper logging:
    // logger.error('ERROR in $operation', exception: exception, failure: failure);
  }
}

/// Retry policy for temporary failures (rate limits, network issues)
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  /// Default retryable error types based on Appwrite docs
  static const defaultRetryableTypes = [
    'general_rate_limit_exceeded', // 429
    'general_service_disabled', // 503
    'general_server_error', // 500
  ];

  /// Default retryable HTTP codes
  static const defaultRetryableCodes = [429, 500, 503, 504];

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Execute operation with exponential backoff retry
  Future<Result<T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    Duration currentDelay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await SafeExecutor.execute(
        operation,
        operationName: operationName,
      );

      // Success - return immediately
      if (result.isSuccess) return result;

      final failure = result.failure!;

      // Check if error is retryable
      final isRetryable = defaultRetryableTypes.contains(failure.type) ||
          defaultRetryableCodes.contains(failure.code);

      // Don't retry if not retryable or last attempt
      if (!isRetryable || attempt == maxAttempts) {
        return result;
      }

      // Wait before retry with exponential backoff
      if (kDebugMode) {
        debugPrint('🔄 Retry attempt $attempt/$maxAttempts after ${currentDelay.inMilliseconds}ms');
      }
      
      await Future.delayed(currentDelay);

      // Calculate next delay
      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
      ).clamp(initialDelay, maxDelay);
    }

    // Fallback (should never reach here)
    return const Error(
      PlatformFailure(
        message: 'Max retry attempts exceeded',
        type: 'general_max_retries_exceeded',
        code: 500,
      ),
    );
  }
}

extension on Duration {
  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}