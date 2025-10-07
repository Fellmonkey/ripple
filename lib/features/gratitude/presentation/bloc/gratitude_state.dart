import 'package:equatable/equatable.dart';
import '../../domain/entities/gratitude_entity.dart';

/// Gratitude states
abstract class GratitudeState extends Equatable {
  const GratitudeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GratitudeInitial extends GratitudeState {
  const GratitudeInitial();
}

/// Loading state
class GratitudeLoading extends GratitudeState {
  const GratitudeLoading();
}

/// Loaded state
class GratitudeLoaded extends GratitudeState {
  final List<GratitudeEntity> gratitudes;
  final String? activeCategory;
  final List<String>? activeTags;

  const GratitudeLoaded({
    required this.gratitudes,
    this.activeCategory,
    this.activeTags,
  });

  @override
  List<Object?> get props => [gratitudes, activeCategory, activeTags];

  GratitudeLoaded copyWith({
    List<GratitudeEntity>? gratitudes,
    String? activeCategory,
    List<String>? activeTags,
  }) {
    return GratitudeLoaded(
      gratitudes: gratitudes ?? this.gratitudes,
      activeCategory: activeCategory ?? this.activeCategory,
      activeTags: activeTags ?? this.activeTags,
    );
  }
}

/// Error state
class GratitudeError extends GratitudeState {
  final String message;

  const GratitudeError(this.message);

  @override
  List<Object?> get props => [message];
}
