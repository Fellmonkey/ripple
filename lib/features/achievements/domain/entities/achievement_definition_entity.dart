import 'package:equatable/equatable.dart';

/// Achievement definition entity
class AchievementDefinitionEntity extends Equatable {
  final String achievementId;
  final String titleKey;
  final String descriptionKey;
  final String icon;
  final String checkType;
  final int checkValue;

  const AchievementDefinitionEntity({
    required this.achievementId,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.checkType,
    required this.checkValue,
  });

  @override
  List<Object?> get props => [
        achievementId,
        titleKey,
        descriptionKey,
        icon,
        checkType,
        checkValue,
      ];
}
