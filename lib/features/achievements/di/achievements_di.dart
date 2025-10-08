import 'package:get_it/get_it.dart';
import '../data/datasources/achievements_remote_datasource.dart';
import '../data/repositories/achievements_repository_impl.dart';
import '../domain/repositories/achievements_repository.dart';
import '../domain/services/achievements_service.dart';
import '../domain/usecases/get_achievements.dart';
import '../domain/usecases/unlock_achievement.dart';
import '../presentation/bloc/achievements_bloc.dart';

/// Setup dependencies for achievements feature
void setupAchievementsDependencies(GetIt sl) {
  // BLoC
  sl.registerFactory(
    () => AchievementsBloc(
      getAchievements: sl(),
      getGratitudes: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAchievementsUseCase(sl()));
  sl.registerLazySingleton(() => UnlockAchievementUseCase(sl()));

  // Service
  sl.registerLazySingleton(
    () => AchievementsService(
      getAchievements: sl(),
      unlockAchievement: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AchievementsRepository>(
    () => AchievementsRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<AchievementsRemoteDataSource>(
    () => AchievementsRemoteDataSourceImpl(
      databases: sl(),
    ),
  );
}
