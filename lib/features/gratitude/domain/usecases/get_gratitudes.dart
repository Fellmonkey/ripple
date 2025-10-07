import '../../../../core/error/models/result.dart';
import '../entities/gratitude_entity.dart';
import '../repositories/gratitude_repository.dart';

/// Use case for getting gratitudes
class GetGratitudesUseCase {
  final GratitudeRepository repository;

  GetGratitudesUseCase(this.repository);

  Future<Result<List<GratitudeEntity>>> call({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getGratitudes(
      category: category,
      tags: tags,
      limit: limit,
      offset: offset,
    );
  }
}
