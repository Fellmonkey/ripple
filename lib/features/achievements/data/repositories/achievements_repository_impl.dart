import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/models/result.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_datasource.dart';

/// Implementation of AchievementsRepository
class AchievementsRepositoryImpl implements AchievementsRepository {
  final AchievementsRemoteDataSource remoteDataSource;

  AchievementsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<List<AchievementDefinition>>> getAchievementDefinitions() {
    return SafeExecutor.execute(
      () => remoteDataSource.getAchievementDefinitions(),
      operationName: 'Get achievement definitions',
    );
  }

  @override
  Future<Result<List<UserAchievement>>> getUserAchievements(String userId) {
    return SafeExecutor.execute(
      () => remoteDataSource.getUserAchievements(userId),
      operationName: 'Get user achievements',
    );
  }

  @override
  Future<Result<UserAchievement>> unlockAchievement({
    required String userId,
    required String achievementId,
  }) {
    return SafeExecutor.execute(
      () => remoteDataSource.unlockAchievement(
        userId: userId,
        achievementId: achievementId,
      ),
      operationName: 'Unlock achievement',
    );
  }

  @override
  Future<Result<List<Achievement>>> getAchievementsWithStatus({
    required String userId,
    required int userGratitudesCount,
    required Map<String, int> categoryCounts,
  }) async {
    return SafeExecutor.execute(
      () async {
        // Get all definitions and user's unlocked achievements in parallel
        final definitionsResult = await getAchievementDefinitions();
        final userAchievementsResult = await getUserAchievements(userId);

        if (definitionsResult.isError) {
          throw Exception(definitionsResult.failure?.userMessage ?? 'Failed to load definitions');
        }
        if (userAchievementsResult.isError) {
          throw Exception(userAchievementsResult.failure?.userMessage ?? 'Failed to load user achievements');
        }

        final definitions = definitionsResult.data!;
        final userAchievements = userAchievementsResult.data!;
        
        // Create a map of unlocked achievement IDs
        final unlockedMap = <String, DateTime>{};
        for (final ua in userAchievements) {
          unlockedMap[ua.achievementId] = ua.unlockedAt;
        }

        // Calculate progress and combine data
        final achievements = definitions.map((def) {
          final isUnlocked = unlockedMap.containsKey(def.id);
          final unlockedAt = unlockedMap[def.id];
          
          // Calculate progress based on checkType
          int progress = 0;
          switch (def.checkType) {
            case 'count':
              // Total gratitudes count
              progress = userGratitudesCount;
              break;
            case 'category_count':
              // Count for specific category
              progress = categoryCounts[def.category] ?? 0;
              break;
            case 'first':
              // First gratitude (0 or 1)
              progress = userGratitudesCount > 0 ? 1 : 0;
              break;
            default:
              progress = 0;
          }

          return Achievement(
            definition: def,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
            progress: progress,
          );
        }).toList();

        // Sort: unlocked last, then by progress percentage descending
        achievements.sort((a, b) {
          if (a.isUnlocked && !b.isUnlocked) return 1;
          if (!a.isUnlocked && b.isUnlocked) return -1;
          return b.progressPercentage.compareTo(a.progressPercentage);
        });

        return achievements;
      },
      operationName: 'Get achievements with status',
    );
  }
}
