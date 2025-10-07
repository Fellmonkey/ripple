import '../../../core/di/injection_container.dart';
import '../data/datasources/gratitude_remote_datasource.dart';
import '../data/repositories/gratitude_repository_impl.dart';
import '../domain/repositories/gratitude_repository.dart';
import '../domain/usecases/create_gratitude.dart';
import '../domain/usecases/get_gratitudes.dart';
import '../domain/usecases/toggle_like.dart';
import '../presentation/bloc/create_gratitude_bloc.dart';
import '../presentation/bloc/gratitude_bloc.dart';

/// Initialize gratitude feature dependencies
void initGratitudeDependencies() {
  // Data sources
  sl.registerLazySingleton<GratitudeRemoteDataSource>(
    () => GratitudeRemoteDataSourceImpl(
      databases: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<GratitudeRepository>(
    () => GratitudeRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGratitudesUseCase(sl()));
  sl.registerLazySingleton(() => CreateGratitudeUseCase(sl()));
  sl.registerLazySingleton(() => ToggleLikeUseCase(sl()));

  // BLoCs
  sl.registerFactory(
    () => GratitudeBloc(
      getGratitudes: sl(),
      toggleLike: sl(),
    ),
  );
  
  sl.registerFactory(
    () => CreateGratitudeBloc(
      createGratitude: sl(),
    ),
  );
}
