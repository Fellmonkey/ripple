import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/models/result.dart';
import '../../../../core/mixins/base_bloc_mixin.dart';
import '../../domain/usecases/create_anonymous_session.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/has_active_session.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication BLoC
/// 
/// Handles anonymous authentication flow:
/// 1. Check if user has active session on app start
/// 2. Create anonymous session if not
/// 3. Manage authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> with BaseBlocMixin<AuthEvent, AuthState> {
  final CreateAnonymousSessionUseCase createAnonymousSession;
  final GetCurrentUserUseCase getCurrentUser;
  final HasActiveSessionUseCase hasActiveSession;

  AuthBloc({
    required this.createAnonymousSession,
    required this.getCurrentUser,
    required this.hasActiveSession,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInAnonymously>(_onSignInAnonymously);
    on<SignOut>(_onSignOut);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Check if user has active session
    final hasSessionResult = await hasActiveSession();

    await hasSessionResult.fold(
      onSuccess: (hasSession) async {
        if (hasSession) {
          // Get current user
          final userResult = await getCurrentUser();
          await userResult.fold(
            onSuccess: (user) async => emit(Authenticated(user)),
            onError: (failure) async => emit(const Unauthenticated()),
          );
        } else {
          // No session, create anonymous one
          final createResult = await createAnonymousSession();
          await createResult.fold(
            onSuccess: (user) async => emit(Authenticated(user)),
            onError: (failure) async => emit(AuthError(failure.userMessage)),
          );
        }
      },
      onError: (failure) async => emit(const Unauthenticated()),
    );
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    await executeWithStates(
      operation: () => createAnonymousSession(),
      loadingState: () => const AuthLoading(),
      successState: (user) => Authenticated(user),
      errorState: (error) => AuthError(error),
      emit: emit,
      operationName: 'Sign in anonymously',
    );
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }
}
