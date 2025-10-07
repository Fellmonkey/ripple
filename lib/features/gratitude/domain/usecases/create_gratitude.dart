import '../../../../core/error/models/result.dart';
import '../entities/gratitude_entity.dart';
import '../repositories/gratitude_repository.dart';

/// Use case for creating gratitude
class CreateGratitudeUseCase {
  final GratitudeRepository repository;

  CreateGratitudeUseCase(this.repository);

  Future<Result<GratitudeEntity>> call({
    required String userId,
    required String text,
    required String category,
    required List<String> tags,
    required (double, double) point,
    String? photoUrl,
    String? parentId,
  }) {
    return repository.createGratitude(
      userId: userId,
      text: text,
      category: category,
      tags: tags,
      point: point,
      photoUrl: photoUrl,
      parentId: parentId,
    );
  }
}
