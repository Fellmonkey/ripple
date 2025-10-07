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

  /// Update gratitude likes
  Future<GratitudeEntity> updateGratitudeLikes({
    required String gratitudeId,
    required int likes,
  });

  /// Get gratitude replies (chains)
  Future<List<GratitudeEntity>> getGratitudeReplies(String parentId);
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

    return response.rows.map(_mapToGratitudeEntity).toList();
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
        'likes': 0,
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
  Future<GratitudeEntity> updateGratitudeLikes({
    required String gratitudeId,
    required int likes,
  }) async {
    final document = await databases.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.gratitudesCollectionId,
      rowId: gratitudeId,
      data: {'likes': likes},
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
      likesCount: (data['likes'] as num?)?.toInt() ?? 0,
      repliesCount: 0, // Calculated via parentId queries
      parentId: data['parentId'] as String?,
      createdAt: DateTime.parse(doc.$createdAt),
    );
  }
}
