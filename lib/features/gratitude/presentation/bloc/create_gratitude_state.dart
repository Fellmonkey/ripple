import 'package:equatable/equatable.dart';
import '../../domain/entities/gratitude_entity.dart';

/// Create gratitude states
abstract class CreateGratitudeState extends Equatable {
  const CreateGratitudeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CreateGratitudeInitial extends CreateGratitudeState {
  const CreateGratitudeInitial();
}

/// Submitting state
class CreateGratitudeSubmitting extends CreateGratitudeState {
  const CreateGratitudeSubmitting();
}

/// Success state
class CreateGratitudeSuccess extends CreateGratitudeState {
  final GratitudeEntity gratitude;

  const CreateGratitudeSuccess(this.gratitude);

  @override
  List<Object?> get props => [gratitude];
}

/// Error state
class CreateGratitudeError extends CreateGratitudeState {
  final String message;

  const CreateGratitudeError(this.message);

  @override
  List<Object?> get props => [message];
}
