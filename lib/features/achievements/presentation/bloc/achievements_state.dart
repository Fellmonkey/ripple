import 'package:equatable/equatable.dart';
import '../../domain/entities/achievement_entity.dart';

/// Achievements states
abstract class AchievementsState extends Equatable {
  const AchievementsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AchievementsInitial extends AchievementsState {
  const AchievementsInitial();
}

/// Loading state
class AchievementsLoading extends AchievementsState {
  const AchievementsLoading();
}

/// Loaded state
class AchievementsLoaded extends AchievementsState {
  final List<Achievement> achievements;
  final int unlockedCount;
  final int totalCount;

  const AchievementsLoaded({
    required this.achievements,
    required this.unlockedCount,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [achievements, unlockedCount, totalCount];
  
  AchievementsLoaded copyWith({
    List<Achievement>? achievements,
    int? unlockedCount,
    int? totalCount,
  }) {
    return AchievementsLoaded(
      achievements: achievements ?? this.achievements,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Error state
class AchievementsError extends AchievementsState {
  final String message;

  const AchievementsError(this.message);

  @override
  List<Object?> get props => [message];
}
