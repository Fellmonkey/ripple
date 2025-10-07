import '../../../../core/error/models/result.dart';
import '../entities/gratitude_entity.dart';

/// Gratitude repository interface
abstract class GratitudeRepository {
  /// Get list of gratitudes with optional filters
  Future<Result<List<GratitudeEntity>>> getGratitudes({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
    String? currentUserId,
    String? searchQuery,
  });

  /// Create new gratitude
  Future<Result<GratitudeEntity>> createGratitude({
    required String userId,
    required String text,
    required String category,
    required List<String> tags,
    required (double, double) point,
    String? photoUrl,
    String? parentId,
  });

  /// Like/unlike gratitude
  Future<Result<GratitudeEntity>> toggleLike({
    required String userId,
    required String gratitudeId,
    required int currentLikes,
    required bool isLiked,
  });

  /// Get gratitude replies (chains)
  Future<Result<List<GratitudeEntity>>> getGratitudeReplies(String parentId);
}
