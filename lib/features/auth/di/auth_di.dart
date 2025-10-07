import 'package:get_it/get_it.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/create_anonymous_session.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/has_active_session.dart';
import '../presentation/bloc/auth_bloc.dart';

/// Dependency injection for auth feature
Future<void> initAuthDependencies(GetIt sl) async {
  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      createAnonymousSession: sl(),
      getCurrentUser: sl(),
      hasActiveSession: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateAnonymousSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => HasActiveSessionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
}
