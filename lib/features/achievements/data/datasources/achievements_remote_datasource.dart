import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../../../core/config/appwrite_config.dart';
import '../../domain/entities/achievement_entity.dart';

/// Remote data source for achievements
abstract class AchievementsRemoteDataSource {
  /// Get all achievement definitions
  Future<List<AchievementDefinition>> getAchievementDefinitions();
  
  /// Get user's unlocked achievements
  Future<List<UserAchievement>> getUserAchievements(String userId);
  
  /// Unlock an achievement for user
  Future<UserAchievement> unlockAchievement({
    required String userId,
    required String achievementId,
  });
}

class AchievementsRemoteDataSourceImpl implements AchievementsRemoteDataSource {
  final TablesDB databases;

  AchievementsRemoteDataSourceImpl({
    required this.databases,
  });

  @override
  Future<List<AchievementDefinition>> getAchievementDefinitions() async {
    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.achievementsDefinitionsCollectionId,
      queries: [
        Query.limit(100),
      ],
    );

    return response.rows.map(_mapToAchievementDefinition).toList();
  }

  @override
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userAchievementsCollectionId,
      queries: [
        Query.equal('userId', userId),
        Query.limit(100),
      ],
    );

    return response.rows.map(_mapToUserAchievement).toList();
  }

  @override
  Future<UserAchievement> unlockAchievement({
    required String userId,
    required String achievementId,
  }) async {
    final document = await databases.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userAchievementsCollectionId,
      rowId: ID.unique(),
      data: {
        'userId': userId,
        'achievementId': achievementId,
        'unlockedAt': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.delete(Role.user(userId)),
      ],
    );

    return _mapToUserAchievement(document);
  }

  /// Map Appwrite document to AchievementDefinition
  AchievementDefinition _mapToAchievementDefinition(models.Row doc) {
    final data = doc.data;
    
    return AchievementDefinition(
      id: doc.$id,
      title: data['title'] as String,
      description: data['description'] as String,
      icon: data['icon'] as String,
      checkType: data['checkType'] as String,
      checkValue: (data['checkValue'] as num).toInt(),
      category: data['category'] as String? ?? '',
    );
  }

  /// Map Appwrite document to UserAchievement
  UserAchievement _mapToUserAchievement(models.Row doc) {
    final data = doc.data;
    
    return UserAchievement(
      id: doc.$id,
      userId: data['userId'] as String,
      achievementId: data['achievementId'] as String,
      unlockedAt: DateTime.parse(data['unlockedAt'] as String),
    );
  }
}
