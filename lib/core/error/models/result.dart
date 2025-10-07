import '../failures.dart';
import '../exception_handler.dart';

/// Generic result type for operations that can fail
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

/// Extension for easier result handling
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
  
  T? get data => isSuccess ? (this as Success<T>).data : null;
  Failure? get failure => isError ? (this as Error<T>).failure : null;
  
  /// Transform result data if success
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      try {
        return Success(transform(data as T));
      } catch (e) {
        final failure = AppwriteExceptionHandler.handleGeneralException(e);
        return Error(failure);
      }
    }
    return Error(failure!);
  }
  
  /// Handle result with callbacks
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(Failure) onError,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onError(failure!);
  }

  /// Execute callback if success
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess) {
      callback(data as T);
    }
    return this;
  }

  /// Execute callback if error
  Result<T> onError(void Function(Failure failure) callback) {
    if (isError) {
      callback(failure!);
    }
    return this;
  }
}

/// Helper methods for creating results
class ResultHelper {
  /// Create a successful result
  static Result<T> success<T>(T data) => Success(data);
  
  /// Create an error result
  static Result<T> error<T>(Failure failure) => Error(failure);
  
  /// Create result from exception
  static Result<T> fromException<T>(Object exception) {
    final failure = AppwriteExceptionHandler.handleGeneralException(exception);
    return Error(failure);
  }
  
  /// Execute operation and wrap in Result
  static Future<Result<T>> execute<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      final failure = AppwriteExceptionHandler.handleGeneralException(e);
      return Error(failure);
    }
  }
}
