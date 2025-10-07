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
  final String? currentUserId;

  const LoadGratitudes({
    this.category,
    this.tags,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [category, tags, currentUserId];
}

/// Refresh gratitudes
class RefreshGratitudes extends GratitudeEvent {
  const RefreshGratitudes();
}

/// Toggle like on gratitude
class ToggleGratitudeLike extends GratitudeEvent {
  final String userId;
  final String gratitudeId;
  final int currentLikes;
  final bool isLiked;

  const ToggleGratitudeLike({
    required this.userId,
    required this.gratitudeId,
    required this.currentLikes,
    required this.isLiked,
  });

  @override
  List<Object?> get props => [userId, gratitudeId, currentLikes, isLiked];
}

/// Load replies for a gratitude
class LoadReplies extends GratitudeEvent {
  final String parentId;

  const LoadReplies(this.parentId);

  @override
  List<Object?> get props => [parentId];
}
