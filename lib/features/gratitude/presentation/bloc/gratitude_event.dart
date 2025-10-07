import 'package:equatable/equatable.dart';

/// Gratitude events
abstract class GratitudeEvent extends Equatable {
  const GratitudeEvent();

  @override
  List<Object?> get props => [];
}

/// Load gratitudes
class LoadGratitudes extends GratitudeEvent {
  final String? category;
  final List<String>? tags;

  const LoadGratitudes({
    this.category,
    this.tags,
  });

  @override
  List<Object?> get props => [category, tags];
}

/// Refresh gratitudes
class RefreshGratitudes extends GratitudeEvent {
  const RefreshGratitudes();
}

/// Toggle like on gratitude
class ToggleGratitudeLike extends GratitudeEvent {
  final String gratitudeId;
  final int currentLikes;
  final bool isLiked;

  const ToggleGratitudeLike({
    required this.gratitudeId,
    required this.currentLikes,
    required this.isLiked,
  });

  @override
  List<Object?> get props => [gratitudeId, currentLikes, isLiked];
}
