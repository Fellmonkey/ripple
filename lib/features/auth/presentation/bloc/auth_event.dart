import 'package:equatable/equatable.dart';

/// Authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user has active session
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Create anonymous session
class SignInAnonymously extends AuthEvent {
  const SignInAnonymously();
}

/// Logout
class SignOut extends AuthEvent {
  const SignOut();
}
