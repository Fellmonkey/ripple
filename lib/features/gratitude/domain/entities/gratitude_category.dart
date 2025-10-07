/// Gratitude categories
enum GratitudeCategory {
  health('HEALTH', '🏥 Health'),
  nature('NATURE', '🌿 Nature'),
  people('PEOPLE', '👥 People'),
  events('EVENTS', '🎉 Events'),
  achievements('ACHIEVEMENTS', '🏆 Achievements'),
  other('OTHER', '✨ Other');

  final String value;
  final String label;

  const GratitudeCategory(this.value, this.label);

  static GratitudeCategory fromValue(String value) {
    return GratitudeCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => GratitudeCategory.other,
    );
  }
}
