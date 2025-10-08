/// Achievement definition entity
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String checkType; // 'count', 'first', 'streak', etc.
  final int checkValue;
  final String category; // Optional: filter by category
  
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.checkType,
    required this.checkValue,
    this.category = '',
  });
}

/// User achievement entity (unlocked achievement)
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  
  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });
}

/// Achievement with unlock status
class Achievement {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress; // Current progress towards achievement
  
  const Achievement({
    required this.definition,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0,
  });
  
  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    if (isUnlocked) return 100.0;
    if (definition.checkValue == 0) return 0.0;
    return (progress / definition.checkValue * 100).clamp(0.0, 100.0);
  }
}
