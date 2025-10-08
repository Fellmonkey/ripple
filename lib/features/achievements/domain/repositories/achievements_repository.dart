import '../../../../core/error/models/result.dart';
import '../entities/achievement_entity.dart';

/// Repository interface for achievements
abstract class AchievementsRepository {
  /// Get all achievement definitions
  Future<Result<List<AchievementDefinition>>> getAchievementDefinitions();
  
  /// Get user's unlocked achievements
  Future<Result<List<UserAchievement>>> getUserAchievements(String userId);
  
  /// Unlock an achievement for user
  Future<Result<UserAchievement>> unlockAchievement({
    required String userId,
    required String achievementId,
  });
  
  /// Get achievements with unlock status for user
  Future<Result<List<Achievement>>> getAchievementsWithStatus({
    required String userId,
    required int userGratitudesCount,
    required Map<String, int> categoryCounts,
  });
}
