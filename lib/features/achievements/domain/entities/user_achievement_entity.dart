import 'package:equatable/equatable.dart';

/// User achievement entity
class UserAchievementEntity extends Equatable {
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;

  const UserAchievementEntity({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });

  @override
  List<Object?> get props => [userId, achievementId, unlockedAt];
}
