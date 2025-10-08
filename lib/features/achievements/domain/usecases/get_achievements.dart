import '../../../../core/error/models/result.dart';
import '../entities/achievement_entity.dart';
import '../repositories/achievements_repository.dart';

/// Use case for getting achievements with unlock status
class GetAchievementsUseCase {
  final AchievementsRepository repository;

  GetAchievementsUseCase(this.repository);

  Future<Result<List<Achievement>>> call({
    required String userId,
    required int userGratitudesCount,
    required Map<String, int> categoryCounts,
  }) {
    return repository.getAchievementsWithStatus(
      userId: userId,
      userGratitudesCount: userGratitudesCount,
      categoryCounts: categoryCounts,
    );
  }
}
