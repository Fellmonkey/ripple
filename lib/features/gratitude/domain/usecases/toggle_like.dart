import '../../../../core/error/models/result.dart';
import '../entities/gratitude_entity.dart';
import '../repositories/gratitude_repository.dart';

/// Use case for toggling gratitude like
class ToggleLikeUseCase {
  final GratitudeRepository repository;

  ToggleLikeUseCase(this.repository);

  Future<Result<GratitudeEntity>> call({
    required String gratitudeId,
    required int currentLikes,
    required bool isLiked,
  }) {
    return repository.toggleLike(
      gratitudeId: gratitudeId,
      currentLikes: currentLikes,
      isLiked: isLiked,
    );
  }
}
