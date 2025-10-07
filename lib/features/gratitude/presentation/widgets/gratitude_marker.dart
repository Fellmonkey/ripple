import 'package:flutter/material.dart';
import '../../domain/entities/gratitude_entity.dart';
import '../../domain/entities/gratitude_category.dart';

/// Custom marker widget for gratitude on map
class GratitudeMarker extends StatelessWidget {
  final GratitudeEntity gratitude;
  final VoidCallback onTap;

  const GratitudeMarker({
    required this.gratitude,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final category = GratitudeCategory.fromValue(gratitude.category);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getCategoryColor(category),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getCategoryEmoji(category),
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(GratitudeCategory category) {
    switch (category) {
      case GratitudeCategory.health:
        return Colors.red.shade100;
      case GratitudeCategory.nature:
        return Colors.green.shade100;
      case GratitudeCategory.people:
        return Colors.blue.shade100;
      case GratitudeCategory.events:
        return Colors.purple.shade100;
      case GratitudeCategory.achievements:
        return Colors.orange.shade100;
      case GratitudeCategory.other:
        return Colors.grey.shade100;
    }
  }

  String _getCategoryEmoji(GratitudeCategory category) {
    switch (category) {
      case GratitudeCategory.health:
        return '🏥';
      case GratitudeCategory.nature:
        return '🌿';
      case GratitudeCategory.people:
        return '👥';
      case GratitudeCategory.events:
        return '🎉';
      case GratitudeCategory.achievements:
        return '🏆';
      case GratitudeCategory.other:
        return '✨';
    }
  }
}
