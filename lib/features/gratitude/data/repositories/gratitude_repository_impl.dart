import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/models/result.dart';
import '../../domain/entities/gratitude_entity.dart';
import '../../domain/repositories/gratitude_repository.dart';
import '../datasources/gratitude_remote_datasource.dart';

/// Implementation of GratitudeRepository
class GratitudeRepositoryImpl implements GratitudeRepository {
  final GratitudeRemoteDataSource remoteDataSource;

  GratitudeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<List<GratitudeEntity>>> getGratitudes({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
    String? currentUserId,
    String? searchQuery,
  }) {
    return SafeExecutor.execute(
      () => remoteDataSource.getGratitudes(
        category: category,
        tags: tags,
        limit: limit,
        offset: offset,
        currentUserId: currentUserId,
        searchQuery: searchQuery,
      ),
      operationName: 'Get gratitudes',
    );
  }

  @override
  Future<Result<GratitudeEntity>> createGratitude({
    required String userId,
    required String text,
    required String category,
    required List<String> tags,
    required (double, double) point,
    String? photoUrl,
    String? parentId,
  }) {
    return SafeExecutor.execute(
      () => remoteDataSource.createGratitude(
        userId: userId,
        text: text,
        category: category,
        tags: tags,
        point: point,
        photoUrl: photoUrl,
        parentId: parentId,
      ),
      operationName: 'Create gratitude',
    );
  }

  @override
  Future<Result<GratitudeEntity>> toggleLike({
    required String userId,
    required String gratitudeId,
    required int currentLikes,
    required bool isLiked,
  }) async {
    return SafeExecutor.execute(
      () async {
        // Update the like in user_likes collection
        if (isLiked) {
          await remoteDataSource.removeUserLike(
            userId: userId,
            gratitudeId: gratitudeId,
          );
        } else {
          await remoteDataSource.addUserLike(
            userId: userId,
            gratitudeId: gratitudeId,
          );
        }
        
        // Return a dummy entity since we'll refresh the feed to get updated counts
        // The UI uses optimistic updates so this return value isn't critical
        return GratitudeEntity(
          gratitudeId: gratitudeId,
          authorId: '',
          text: '',
          category: '',
          tags: const [],
          point: (0.0, 0.0),
          likesCount: isLiked ? currentLikes - 1 : currentLikes + 1,
          repliesCount: 0,
          createdAt: DateTime.now(),
          isLiked: !isLiked,
        );
      },
      operationName: 'Toggle like',
    );
  }

  @override
  Future<Result<List<GratitudeEntity>>> getGratitudeReplies(String parentId) {
    return SafeExecutor.execute(
      () => remoteDataSource.getGratitudeReplies(parentId),
      operationName: 'Get gratitude replies',
    );
  }
}
