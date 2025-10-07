import 'package:appwrite/models.dart' as models;
import '../../../../core/error/models/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting current user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Result<models.User>> call() {
    return repository.getCurrentUser();
  }
}
