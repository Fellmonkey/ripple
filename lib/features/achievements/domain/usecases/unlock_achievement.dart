import '../../../../core/error/models/result.dart';
import '../entities/achievement_entity.dart';
import '../repositories/achievements_repository.dart';

/// Use case for unlocking an achievement
class UnlockAchievementUseCase {
  final AchievementsRepository repository;

  UnlockAchievementUseCase(this.repository);

  Future<Result<UserAchievement>> call({
    required String userId,
    required String achievementId,
  }) {
    return repository.unlockAchievement(
      userId: userId,
      achievementId: achievementId,
    );
  }
}
