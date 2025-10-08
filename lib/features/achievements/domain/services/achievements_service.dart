import 'package:flutter/foundation.dart';
import '../../../../core/error/models/result.dart';
import '../entities/achievement_entity.dart';
import '../usecases/get_achievements.dart';
import '../usecases/unlock_achievement.dart';
import '../../../gratitude/domain/entities/gratitude_entity.dart';

/// Service for checking and unlocking achievements
class AchievementsService {
  final GetAchievementsUseCase getAchievements;
  final UnlockAchievementUseCase unlockAchievement;

  AchievementsService({
    required this.getAchievements,
    required this.unlockAchievement,
  });

  /// Check and unlock achievements after user creates a gratitude
  Future<List<Achievement>> checkAndUnlockAchievements({
    required String userId,
    required List<GratitudeEntity> userGratitudes,
  }) async {
    try {
      // Calculate stats
      final gratitudesCount = userGratitudes.length;
      final categoryCounts = <String, int>{};
      
      for (final gratitude in userGratitudes) {
        categoryCounts[gratitude.category] = (categoryCounts[gratitude.category] ?? 0) + 1;
      }

      // Get achievements with status
      final result = await getAchievements(
        userId: userId,
        userGratitudesCount: gratitudesCount,
        categoryCounts: categoryCounts,
      );

      if (result.isError || result.data == null) {
        if (kDebugMode) {
          print('❌ Failed to get achievements: ${result.failure?.userMessage}');
        }
        return [];
      }

      final achievements = result.data!;
      final newlyUnlocked = <Achievement>[];

      // Check each unlocked achievement
      for (final achievement in achievements) {
        // Skip if already unlocked
        if (achievement.isUnlocked) continue;

        // Check if criteria is met
        bool shouldUnlock = false;
        
        switch (achievement.definition.checkType) {
          case 'first':
            // First gratitude
            shouldUnlock = achievement.progress >= 1;
            break;
          case 'count':
            // Specific count of gratitudes
            shouldUnlock = achievement.progress >= achievement.definition.checkValue;
            break;
          case 'category_count':
            // Specific count in a category
            shouldUnlock = achievement.progress >= achievement.definition.checkValue;
            break;
          default:
            break;
        }

        // Unlock the achievement
        if (shouldUnlock) {
          final unlockResult = await unlockAchievement(
            userId: userId,
            achievementId: achievement.definition.id,
          );

          if (unlockResult.isSuccess) {
            newlyUnlocked.add(Achievement(
              definition: achievement.definition,
              isUnlocked: true,
              unlockedAt: DateTime.now(),
              progress: achievement.progress,
            ));
            
            if (kDebugMode) {
              print('🏆 Achievement unlocked: ${achievement.definition.title}');
            }
          }
        }
      }

      return newlyUnlocked;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking achievements: $e');
      }
      return [];
    }
  }
}
