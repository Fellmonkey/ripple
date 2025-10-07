import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/models/result.dart';
import '../../../../core/mixins/base_bloc_mixin.dart';
import '../../domain/entities/gratitude_entity.dart';
import '../../domain/usecases/get_gratitudes.dart';
import '../../domain/usecases/get_replies.dart';
import '../../domain/usecases/toggle_like.dart';
import 'gratitude_event.dart';
import 'gratitude_state.dart';

/// Gratitude BLoC
/// 
/// Manages gratitude feed and map markers state
class GratitudeBloc extends Bloc<GratitudeEvent, GratitudeState>
    with BaseBlocMixin<GratitudeEvent, GratitudeState> {
  final GetGratitudesUseCase getGratitudes;
  final GetRepliesUseCase getReplies;
  final ToggleLikeUseCase toggleLike;

  GratitudeBloc({
    required this.getGratitudes,
    required this.getReplies,
    required this.toggleLike,
  }) : super(const GratitudeInitial()) {
    on<LoadGratitudes>(_onLoadGratitudes);
    on<RefreshGratitudes>(_onRefreshGratitudes);
    on<ToggleGratitudeLike>(_onToggleGratitudeLike);
    on<LoadReplies>(_onLoadReplies);
  }

  Future<void> _onLoadGratitudes(
    LoadGratitudes event,
    Emitter<GratitudeState> emit,
  ) async {
    await executeWithStates(
      operation: () => getGratitudes(
        category: event.category,
        tags: event.tags,
        currentUserId: event.currentUserId,
      ),
      loadingState: () => const GratitudeLoading(),
      successState: (gratitudes) => GratitudeLoaded(
        gratitudes: gratitudes,
        activeCategory: event.category,
        activeTags: event.tags,
      ),
      errorState: (error) => GratitudeError(error),
      emit: emit,
      operationName: 'Load gratitudes',
    );
  }

  Future<void> _onRefreshGratitudes(
    RefreshGratitudes event,
    Emitter<GratitudeState> emit,
  ) async {
    // Keep current filters
    String? category;
    List<String>? tags;
    
    if (state is GratitudeLoaded) {
      final currentState = state as GratitudeLoaded;
      category = currentState.activeCategory;
      tags = currentState.activeTags;
    }

    await executeWithStates(
      operation: () => getGratitudes(
        category: category,
        tags: tags,
      ),
      loadingState: () => const GratitudeLoading(),
      successState: (gratitudes) => GratitudeLoaded(
        gratitudes: gratitudes,
        activeCategory: category,
        activeTags: tags,
      ),
      errorState: (error) => GratitudeError(error),
      emit: emit,
      operationName: 'Refresh gratitudes',
    );
  }

  Future<void> _onToggleGratitudeLike(
    ToggleGratitudeLike event,
    Emitter<GratitudeState> emit,
  ) async {
    if (state is! GratitudeLoaded) return;

    final currentState = state as GratitudeLoaded;
    
    // Optimistic update
    final updatedGratitudes = currentState.gratitudes.map((g) {
      if (g.gratitudeId == event.gratitudeId) {
        return _copyGratitudeWithLikes(g, event.isLiked);
      }
      return g;
    }).toList();

    emit(currentState.copyWith(gratitudes: updatedGratitudes));

    // Actual API call
    final result = await toggleLike(
      userId: event.userId,
      gratitudeId: event.gratitudeId,
      currentLikes: event.currentLikes,
      isLiked: event.isLiked,
    );

    // If failed, revert using extension method
    if (result.isError) {
      emit(currentState);
      if (kDebugMode) {
        print('❌ BLoC ERROR [GratitudeBloc.Toggle like]: ${result.failure?.userMessage}');
      }
    }
  }

  Future<void> _onLoadReplies(
    LoadReplies event,
    Emitter<GratitudeState> emit,
  ) async {
    await executeWithStates(
      operation: () => getReplies(event.parentId),
      loadingState: () => const GratitudeRepliesLoading(),
      successState: (replies) => GratitudeRepliesLoaded(replies),
      errorState: (error) => GratitudeRepliesError(error),
      emit: emit,
      operationName: 'Load replies',
    );
  }

  /// Helper to create copy of gratitude with updated likes
  GratitudeEntity _copyGratitudeWithLikes(GratitudeEntity g, bool isLiked) {
    return GratitudeEntity(
      gratitudeId: g.gratitudeId,
      authorId: g.authorId,
      text: g.text,
      point: g.point,
      category: g.category,
      tags: g.tags,
      likesCount: isLiked ? g.likesCount - 1 : g.likesCount + 1,
      repliesCount: g.repliesCount,
      createdAt: g.createdAt,
      photo: g.photo,
      parentId: g.parentId,
      isLiked: !isLiked, // Toggle the liked status
    );
  }
}
