import 'package:appwrite/models.dart' as models;
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/models/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<models.User>> createAnonymousSession() {
    return SafeExecutor.execute(
      () => remoteDataSource.createAnonymousSession(),
      operationName: 'Create anonymous session',
    );
  }

  @override
  Future<Result<models.User>> getCurrentUser() {
    return SafeExecutor.execute(
      () => remoteDataSource.getCurrentUser(),
      operationName: 'Get current user',
    );
  }

  @override
  Future<Result<bool>> hasActiveSession() {
    return SafeExecutor.execute(
      () => remoteDataSource.hasActiveSession(),
      operationName: 'Check active session',
    );
  }

  @override
  Future<Result<void>> logout() {
    return SafeExecutor.execute(
      () => remoteDataSource.deleteSession(),
      operationName: 'Logout',
    );
  }
}
