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
  final String? searchQuery;
  final bool hasMoreData;
  final bool isLoadingMore;

  const GratitudeLoaded({
    required this.gratitudes,
    this.activeCategory,
    this.activeTags,
    this.searchQuery,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
        gratitudes,
        activeCategory,
        activeTags,
        searchQuery,
        hasMoreData,
        isLoadingMore,
      ];

  GratitudeLoaded copyWith({
    List<GratitudeEntity>? gratitudes,
    String? activeCategory,
    List<String>? activeTags,
    String? searchQuery,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return GratitudeLoaded(
      gratitudes: gratitudes ?? this.gratitudes,
      activeCategory: activeCategory ?? this.activeCategory,
      activeTags: activeTags ?? this.activeTags,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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

/// Replies loading state
class GratitudeRepliesLoading extends GratitudeState {
  const GratitudeRepliesLoading();
}

/// Replies loaded state
class GratitudeRepliesLoaded extends GratitudeState {
  final List<GratitudeEntity> replies;

  const GratitudeRepliesLoaded(this.replies);

  @override
  List<Object?> get props => [replies];
}

/// Replies error state
class GratitudeRepliesError extends GratitudeState {
  final String message;

  const GratitudeRepliesError(this.message);

  @override
  List<Object?> get props => [message];
}
