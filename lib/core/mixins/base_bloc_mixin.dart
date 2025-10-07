import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../error/failures.dart';
import '../error/models/result.dart';

/// Base BLoC mixin for unified operation handling with automatic state management
/// 
/// Eliminates boilerplate code and provides consistent error handling across BLoCs.
/// Works seamlessly with the error handling system.
mixin BaseBlocMixin<Event, State> on Bloc<Event, State> {
  
  /// Execute operation with automatic loading, success, and error state handling
  Future<void> executeWithStates<T>({
    required Future<Result<T>> Function() operation,
    required State Function() loadingState,
    required State Function(T data) successState,
    required State Function(String error) errorState,
    required Emitter<State> emit,
    String? operationName,
  }) async {
    emit(loadingState());

    final result = await operation();

    result.fold(
      onSuccess: (data) => emit(successState(data)),
      onError: (failure) {
        _logError(operationName, failure);
        emit(errorState(failure.userMessage));
      },
    );
  }

  /// Execute async operation with automatic loading, success, and error state handling
  Future<void> executeWithStatesAsync<T>({
    required Future<Result<T>> Function() operation,
    required FutureOr<State> Function() loadingState,
    required FutureOr<State> Function(T data) successState,
    required FutureOr<State> Function(String error) errorState,
    required Emitter<State> emit,
    String? operationName,
  }) async {
    final loading = await Future.sync(() => loadingState());
    emit(loading);

    final result = await operation();

    await result.fold(
      onSuccess: (data) async {
        final success = await Future.sync(() => successState(data));
        emit(success);
      },
      onError: (failure) async {
        _logError(operationName, failure);
        final errorS = await Future.sync(() => errorState(failure.userMessage));
        emit(errorS);
      },
    );
  }

  /// Execute operation with custom state handling
  Future<void> executeWithCustomHandling<T>({
    required Future<Result<T>> Function() operation,
    required void Function() onLoading,
    required void Function(T data) onSuccess,
    required void Function(Failure failure) onError,
    String? operationName,
  }) async {
    onLoading();

    final result = await operation();

    result.fold(
      onSuccess: onSuccess,
      onError: (failure) {
        _logError(operationName, failure);
        onError(failure);
      },
    );
  }

  /// Execute async operation with custom state handling
  Future<void> executeWithCustomHandlingAsync<T>({
    required Future<Result<T>> Function() operation,
    required FutureOr<void> Function() onLoading,
    required FutureOr<void> Function(T data) onSuccess,
    required FutureOr<void> Function(Failure failure) onError,
    String? operationName,
  }) async {
    await Future.sync(() => onLoading());

    final result = await operation();

    await result.fold(
      onSuccess: (data) async {
        await Future.sync(() => onSuccess(data));
      },
      onError: (failure) async {
        _logError(operationName, failure);
        await Future.sync(() => onError(failure));
      },
    );
  }

  /// Log error in debug mode with structured format (consistent with SafeExecutor)
  void _logError(String? operationName, Failure failure) {
    if (kDebugMode && operationName != null) {
      debugPrint('❌ BLoC ERROR in $operationName');
      debugPrint('   Type: ${failure.type}');
      debugPrint('   Code: ${failure.code}');
      debugPrint('   Message: ${failure.message}');
      debugPrint('   User Message: ${failure.userMessage}');
    }
  }
}
