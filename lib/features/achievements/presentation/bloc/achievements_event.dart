import 'package:equatable/equatable.dart';

/// Achievements events
abstract class AchievementsEvent extends Equatable {
  const AchievementsEvent();

  @override
  List<Object?> get props => [];
}

/// Load achievements for user
class LoadAchievements extends AchievementsEvent {
  final String userId;

  const LoadAchievements(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Refresh achievements
class RefreshAchievements extends AchievementsEvent {
  final String userId;

  const RefreshAchievements(this.userId);

  @override
  List<Object?> get props => [userId];
}
