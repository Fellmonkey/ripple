import '../../../../core/error/models/result.dart';
import '../entities/gratitude_entity.dart';
import '../repositories/gratitude_repository.dart';

/// Use case for getting replies to a gratitude
class GetRepliesUseCase {
  final GratitudeRepository repository;

  GetRepliesUseCase(this.repository);

  /// Get all replies for a specific gratitude
  /// 
  /// Parameters:
  /// - [parentId]: The ID of the parent gratitude
  /// 
  /// Returns:
  /// - [Result<List<GratitudeEntity>>]: List of replies or error
  Future<Result<List<GratitudeEntity>>> call(String parentId) async {
    return repository.getGratitudeReplies(parentId);
  }
}
