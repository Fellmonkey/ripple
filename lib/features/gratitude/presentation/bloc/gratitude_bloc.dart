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
    on<SearchGratitudes>(_onSearchGratitudes);
    on<ClearSearch>(_onClearSearch);
    on<LoadMoreGratitudes>(_onLoadMoreGratitudes);
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
        searchQuery: event.searchQuery,
      ),
      loadingState: () => const GratitudeLoading(),
      successState: (gratitudes) => GratitudeLoaded(
        gratitudes: gratitudes,
        activeCategory: event.category,
        activeTags: event.tags,
        searchQuery: event.searchQuery,
      ),
      errorState: (error) => GratitudeError(error),
      emit: emit,
      operationName: 'Load gratitudes',
    );
  }

  Future<void> _onSearchGratitudes(
    SearchGratitudes event,
    Emitter<GratitudeState> emit,
  ) async {
    await executeWithStates(
      operation: () => getGratitudes(
        searchQuery: event.searchQuery,
        currentUserId: event.currentUserId,
      ),
      loadingState: () => const GratitudeLoading(),
      successState: (gratitudes) => GratitudeLoaded(
        gratitudes: gratitudes,
        searchQuery: event.searchQuery,
      ),
      errorState: (error) => GratitudeError(error),
      emit: emit,
      operationName: 'Search gratitudes',
    );
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<GratitudeState> emit,
  ) async {
    await executeWithStates(
      operation: () => getGratitudes(
        currentUserId: event.currentUserId,
      ),
      loadingState: () => const GratitudeLoading(),
      successState: (gratitudes) => GratitudeLoaded(
        gratitudes: gratitudes,
      ),
      errorState: (error) => GratitudeError(error),
      emit: emit,
      operationName: 'Clear search',
    );
  }

  Future<void> _onLoadMoreGratitudes(
    LoadMoreGratitudes event,
    Emitter<GratitudeState> emit,
  ) async {
    // Only load more if we're in a loaded state
    if (state is! GratitudeLoaded) return;

    final currentState = state as GratitudeLoaded;
    
    // Don't load if already loading or no more data
    if (currentState.isLoadingMore || !currentState.hasMoreData) return;

    // Set loading more flag
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // Calculate offset from current gratitudes length
      final offset = currentState.gratitudes.length;
      const limit = 50; // Default page size

      // Load more gratitudes with current filters and search
      final result = await getGratitudes(
        category: currentState.activeCategory,
        tags: currentState.activeTags,
        currentUserId: event.currentUserId,
        searchQuery: event.searchQuery,
        limit: limit,
        offset: offset,
      );

      // Handle result
      if (result.isSuccess && result.data != null) {
        final newGratitudes = result.data!;
        
        // Append new gratitudes to existing list
        final updatedGratitudes = [
          ...currentState.gratitudes,
          ...newGratitudes,
        ];

        // Update hasMoreData flag based on result count
        final hasMoreData = newGratitudes.length == limit;

        emit(currentState.copyWith(
          gratitudes: updatedGratitudes,
          isLoadingMore: false,
          hasMoreData: hasMoreData,
        ));
      } else {
        // On error, just stop loading
        emit(currentState.copyWith(isLoadingMore: false));
        if (kDebugMode) {
          print('❌ BLoC ERROR [GratitudeBloc.Load more]: ${result.failure?.userMessage}');
        }
      }
    } catch (e) {
      // On exception, stop loading
      emit(currentState.copyWith(isLoadingMore: false));
      if (kDebugMode) {
        print('❌ BLoC EXCEPTION [GratitudeBloc.Load more]: $e');
      }
    }
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

    // If successful, refresh to get accurate counts from user_likes table
    if (result.isSuccess) {
      // Refresh gratitudes to get accurate like counts
      final refreshResult = await getGratitudes(
        category: currentState.activeCategory,
        tags: currentState.activeTags,
        currentUserId: event.userId,
        searchQuery: currentState.searchQuery,
      );
      
      if (refreshResult.isSuccess && refreshResult.data != null) {
        emit(currentState.copyWith(
          gratitudes: refreshResult.data!,
        ));
      }
    } else {
      // If failed, revert to previous state
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
