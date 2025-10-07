import 'package:appwrite/models.dart' as models;
import '../../../../core/error/models/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for creating anonymous session
class CreateAnonymousSessionUseCase {
  final AuthRepository repository;

  CreateAnonymousSessionUseCase(this.repository);

  Future<Result<models.User>> call() {
    return repository.createAnonymousSession();
  }
}
