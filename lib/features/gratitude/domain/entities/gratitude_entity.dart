import 'package:equatable/equatable.dart';

/// Gratitude entity representing a gratitude in the domain layer
class GratitudeEntity extends Equatable {
  final String gratitudeId;
  final String authorId;
  final String text;
  final (double, double) point;
  final String category;
  final List<String> tags;
  final String? photo;
  final int likesCount;
  final int repliesCount;
  final String? parentId;
  final DateTime createdAt;

  const GratitudeEntity({
    required this.gratitudeId,
    required this.authorId,
    required this.text,
    required this.point,
    required this.category,
    required this.tags,
    required this.likesCount,
    required this.repliesCount,
    required this.createdAt,
    this.photo,
    this.parentId,
  });

  @override
  List<Object?> get props => [
        gratitudeId,
        authorId,
        text,
        point,
        category,
        tags,
        photo,
        likesCount,
        repliesCount,
        parentId,
        createdAt,
      ];
}
