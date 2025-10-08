import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../../../core/config/appwrite_config.dart';
import '../../domain/entities/gratitude_entity.dart';

/// Remote data source for gratitude operations
abstract class GratitudeRemoteDataSource {
  /// Get gratitudes from Appwrite
  Future<List<GratitudeEntity>> getGratitudes({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
    String? currentUserId,
    String? searchQuery,
  });

  /// Create new gratitude
  Future<GratitudeEntity> createGratitude({
    required String userId,
    required String text,
    required String category,
    required List<String> tags,
    required (double, double) point,
    String? photoUrl,
    String? parentId,
  });

  /// Get gratitude replies (chains)
  Future<List<GratitudeEntity>> getGratitudeReplies(String parentId);
  
  /// Check if user has liked specific gratitudes
  Future<Set<String>> getUserLikedGratitudeIds({
    required String userId,
    required List<String> gratitudeIds,
  });
  
  /// Add user like
  Future<void> addUserLike({
    required String userId,
    required String gratitudeId,
  });
  
  /// Remove user like
  Future<void> removeUserLike({
    required String userId,
    required String gratitudeId,
  });
}

class GratitudeRemoteDataSourceImpl implements GratitudeRemoteDataSource {
  final TablesDB databases;

  GratitudeRemoteDataSourceImpl({
    required this.databases,
  });

  @override
  Future<List<GratitudeEntity>> getGratitudes({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
    String? currentUserId,
    String? searchQuery,
  }) async {
    final queries = <String>[
      Query.limit(limit),
      Query.offset(offset),
      Query.orderDesc('\$createdAt'),
    ];

    // Add category filter if provided
    if (category != null) {
      queries.add(Query.equal('category', category));
    }

    // Add search query for tags and text if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Search in both tags and text fields
      queries.add(Query.or([
        Query.search('tags', searchQuery),
        Query.search('text', searchQuery),
      ]));
    }

    // Add tags search if provided
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        queries.add(Query.search('tags', tag));
      }
    }

    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.gratitudesCollectionId,
      queries: queries,
    );

    final gratitudes = response.rows.map(_mapToGratitudeEntity).toList();
    
    // If we have gratitudes, count replies and likes for each one
    if (gratitudes.isNotEmpty) {
      // Get all gratitude IDs
      final gratitudeIds = gratitudes.map((g) => g.gratitudeId).toList();
      
      // Fetch all replies for these gratitudes in ONE query
      final repliesResponse = await databases.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.gratitudesCollectionId,
        queries: [
          Query.isNotNull('parentId'),
          Query.limit(1000), // Adjust if needed
        ],
      );
      
      // Count replies for each parent
      final repliesCountMap = <String, int>{};
      for (final replyDoc in repliesResponse.rows) {
        final parentId = replyDoc.data['parentId'] as String?;
        if (parentId != null && gratitudeIds.contains(parentId)) {
          repliesCountMap[parentId] = (repliesCountMap[parentId] ?? 0) + 1;
        }
      }
      
      // Fetch all likes for these gratitudes in ONE query
      final likesResponse = await databases.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userLikesCollectionId,
        queries: [
          Query.limit(5000), // Adjust if needed
        ],
      );
      
      // Count likes for each gratitude
      final likesCountMap = <String, int>{};
      final likedGratitudeIds = <String>{};
      
      for (final likeDoc in likesResponse.rows) {
        final gratitudeId = likeDoc.data['gratitudeId'] as String?;
        final userId = likeDoc.data['userId'] as String?;
        
        if (gratitudeId != null && gratitudeIds.contains(gratitudeId)) {
          // Count total likes
          likesCountMap[gratitudeId] = (likesCountMap[gratitudeId] ?? 0) + 1;
          
          // Track if current user liked this
          if (currentUserId != null && userId == currentUserId) {
            likedGratitudeIds.add(gratitudeId);
          }
        }
      }
      
      // Update gratitudes with correct counts and isLiked status
      return gratitudes.map((g) {
        final replyCount = repliesCountMap[g.gratitudeId] ?? 0;
        final likeCount = likesCountMap[g.gratitudeId] ?? 0;
        final isLiked = likedGratitudeIds.contains(g.gratitudeId);
        
        return GratitudeEntity(
          gratitudeId: g.gratitudeId,
          authorId: g.authorId,
          text: g.text,
          category: g.category,
          tags: g.tags,
          point: g.point,
          photo: g.photo,
          likesCount: likeCount,
          repliesCount: replyCount,
          parentId: g.parentId,
          createdAt: g.createdAt,
          isLiked: isLiked,
        );
      }).toList();
    }

    return gratitudes;
  }

  @override
  Future<GratitudeEntity> createGratitude({
    required String userId,
    required String text,
    required String category,
    required List<String> tags,
    required (double, double) point,
    String? photoUrl,
    String? parentId,
  }) async {
    final document = await databases.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.gratitudesCollectionId,
      rowId: ID.unique(),
      data: {
        'authorId': userId,
        'text': text,
        'category': category,
        'tags': tags,
        'point': [point.$1, point.$2], // Appwrite point type
        if (photoUrl != null) 'photo': photoUrl,
        if (parentId != null) 'parentId': parentId,
        // 'likes' field removed - now calculated from user_likes table
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );

    return _mapToGratitudeEntity(document);
  }

  @override
  Future<List<GratitudeEntity>> getGratitudeReplies(String parentId) async {
    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.gratitudesCollectionId,
      queries: [
        Query.equal('parentId', parentId),
        Query.orderDesc('\$createdAt'),
      ],
    );

    return response.rows.map(_mapToGratitudeEntity).toList();
  }

  /// Map Appwrite document to GratitudeEntity
  GratitudeEntity _mapToGratitudeEntity(models.Row doc) {
    final data = doc.data;
    final pointData = data['point'] as List;
    final tagsList = data['tags'] as List?;
    
    return GratitudeEntity(
      gratitudeId: doc.$id,
      authorId: data['authorId'] as String,
      text: data['text'] as String,
      category: data['category'] as String,
      tags: tagsList?.map((e) => e.toString()).toList() ?? [],
      point: (
        (pointData[0] as num).toDouble(),
        (pointData[1] as num).toDouble(),
      ),
      photo: data['photo'] as String?,
      likesCount: 0, // Will be calculated in getGratitudes() from user_likes table
      repliesCount: 0, // Will be calculated in getGratitudes()
      parentId: data['parentId'] as String?,
      createdAt: DateTime.parse(doc.$createdAt),
      isLiked: false, // Will be calculated in getGratitudes()
    );
  }
  
  @override
  Future<Set<String>> getUserLikedGratitudeIds({
    required String userId,
    required List<String> gratitudeIds,
  }) async {
    if (gratitudeIds.isEmpty) return {};
    
    // Query user_likes collection for this user and these gratitudes
    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userLikesCollectionId,
      queries: [
        Query.equal('userId', userId),
        Query.limit(1000), // Should be enough for pagination
      ],
    );
    
    // Filter to only gratitudes in our list and return as Set
    return response.rows
        .map((doc) => doc.data['gratitudeId'] as String)
        .where((id) => gratitudeIds.contains(id))
        .toSet();
  }
  
  @override
  Future<void> addUserLike({
    required String userId,
    required String gratitudeId,
  }) async {
    await databases.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userLikesCollectionId,
      rowId: ID.unique(),
      data: {
        'userId': userId,
        'gratitudeId': gratitudeId,
        'likedAt': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.delete(Role.user(userId)),
      ],
    );
  }
  
  @override
  Future<void> removeUserLike({
    required String userId,
    required String gratitudeId,
  }) async {
    // Find the like document
    final response = await databases.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.userLikesCollectionId,
      queries: [
        Query.equal('userId', userId),
        Query.equal('gratitudeId', gratitudeId),
        Query.limit(1),
      ],
    );
    
    if (response.rows.isNotEmpty) {
      final likeDoc = response.rows.first;
      await databases.deleteRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userLikesCollectionId,
        rowId: likeDoc.$id,
      );
    }
  }
}
