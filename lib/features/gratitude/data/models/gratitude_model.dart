import '../../domain/entities/gratitude_entity.dart';

/// Gratitude model for data layer
class GratitudeModel extends GratitudeEntity {
  const GratitudeModel({
    required super.gratitudeId,
    required super.authorId,
    required super.text,
    required super.point,
    required super.category,
    required super.tags,
    required super.likesCount,
    required super.repliesCount,
    required super.createdAt,
    super.photo,
    super.parentId,
  });

  /// Create from JSON
  factory GratitudeModel.fromJson(Map<String, dynamic> json) {
    return GratitudeModel(
      gratitudeId: json['\$id'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String,
      point: (json['point'] as (double, double)),
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      photo: json['photo'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      repliesCount: json['repliesCount'] as int? ?? 0,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['\$createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'text': text,
      'point': point,
      'category': category,
      'tags': tags,
      'photoId': photo,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'parentId': parentId,
    };
  }

  /// Create from entity
  factory GratitudeModel.fromEntity(GratitudeEntity entity) {
    return GratitudeModel(
      gratitudeId: entity.gratitudeId,
      authorId: entity.authorId,
      text: entity.text,
      point: entity.point,
      category: entity.category,
      tags: entity.tags,
      photo: entity.photo,
      likesCount: entity.likesCount,
      repliesCount: entity.repliesCount,
      parentId: entity.parentId,
      createdAt: entity.createdAt,
    );
  }
}
