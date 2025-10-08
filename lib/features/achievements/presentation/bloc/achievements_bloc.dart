import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/models/result.dart';
import '../../../../core/mixins/base_bloc_mixin.dart';
import '../../domain/usecases/get_achievements.dart';
import '../../../gratitude/domain/usecases/get_gratitudes.dart';
import 'achievements_event.dart';
import 'achievements_state.dart';

/// Achievements BLoC
class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState>
    with BaseBlocMixin<AchievementsEvent, AchievementsState> {
  final GetAchievementsUseCase getAchievements;
  final GetGratitudesUseCase getGratitudes;

  AchievementsBloc({
    required this.getAchievements,
    required this.getGratitudes,
  }) : super(const AchievementsInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
    on<RefreshAchievements>(_onRefreshAchievements);
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementsState> emit,
  ) async {
    await _loadAchievements(event.userId, emit);
  }

  Future<void> _onRefreshAchievements(
    RefreshAchievements event,
    Emitter<AchievementsState> emit,
  ) async {
    await _loadAchievements(event.userId, emit);
  }

  Future<void> _loadAchievements(
    String userId,
    Emitter<AchievementsState> emit,
  ) async {
    // First, get user's gratitudes to calculate stats
    final gratitudesResult = await getGratitudes(
      currentUserId: userId,
      limit: 1000, // Get all for stats
    );

    if (gratitudesResult.isError) {
      emit(AchievementsError(
        gratitudesResult.failure?.userMessage ?? 'Failed to load gratitudes',
      ));
      return;
    }

    final gratitudes = gratitudesResult.data ?? [];
    final userGratitudes = gratitudes.where((g) => g.authorId == userId).toList();
    
    // Calculate category counts
    final categoryCounts = <String, int>{};
    for (final gratitude in userGratitudes) {
      categoryCounts[gratitude.category] = (categoryCounts[gratitude.category] ?? 0) + 1;
    }

    // Get achievements with status
    await executeWithStates(
      operation: () => getAchievements(
        userId: userId,
        userGratitudesCount: userGratitudes.length,
        categoryCounts: categoryCounts,
      ),
      loadingState: () => const AchievementsLoading(),
      successState: (achievements) {
        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        return AchievementsLoaded(
          achievements: achievements,
          unlockedCount: unlockedCount,
          totalCount: achievements.length,
        );
      },
      errorState: (error) => AchievementsError(error),
      emit: emit,
      operationName: 'Load achievements',
    );
  }
}
