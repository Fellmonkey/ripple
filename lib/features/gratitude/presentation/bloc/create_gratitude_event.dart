import 'package:equatable/equatable.dart';

/// Create gratitude events
abstract class CreateGratitudeEvent extends Equatable {
  const CreateGratitudeEvent();

  @override
  List<Object?> get props => [];
}

/// Submit gratitude
class SubmitGratitude extends CreateGratitudeEvent {
  final String userId;
  final String text;
  final String category;
  final List<String> tags;
  final (double, double) point;
  final String? photoUrl;
  final String? parentId;

  const SubmitGratitude({
    required this.userId,
    required this.text,
    required this.category,
    required this.tags,
    required this.point,
    this.photoUrl,
    this.parentId,
  });

  @override
  List<Object?> get props => [userId, text, category, tags, point, photoUrl, parentId];
}

/// Reset form
class ResetCreateForm extends CreateGratitudeEvent {
  const ResetCreateForm();
}
