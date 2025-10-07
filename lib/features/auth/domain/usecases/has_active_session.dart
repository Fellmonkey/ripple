import '../../../../core/error/models/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking if user has active session
class HasActiveSessionUseCase {
  final AuthRepository repository;

  HasActiveSessionUseCase(this.repository);

  Future<Result<bool>> call() {
    return repository.hasActiveSession();
  }
}
