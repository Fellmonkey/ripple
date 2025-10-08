import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/achievements_bloc.dart';
import '../bloc/achievements_event.dart';
import '../bloc/achievements_state.dart';
import '../widgets/achievement_card.dart';

/// Achievements screen showing user's progress
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AchievementsBloc>(),
      child: const _AchievementsView(),
    );
  }
}

class _AchievementsView extends StatefulWidget {
  const _AchievementsView();

  @override
  State<_AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<_AchievementsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<AchievementsBloc>().add(LoadAchievements(authState.user.$id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: BlocBuilder<AchievementsBloc, AchievementsState>(
        builder: (context, state) {
          if (state is AchievementsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AchievementsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) {
                        context.read<AchievementsBloc>().add(
                              RefreshAchievements(authState.user.$id),
                            );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AchievementsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  context.read<AchievementsBloc>().add(
                        RefreshAchievements(authState.user.$id),
                      );
                }
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Column(
                children: [
                  // Progress header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🏆',
                          style: TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.unlockedCount} / ${state.totalCount}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Achievements Unlocked',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  // Achievements list
                  Expanded(
                    child: state.achievements.isEmpty
                        ? const Center(
                            child: Text('No achievements available'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.achievements.length,
                            itemBuilder: (context, index) {
                              final achievement = state.achievements[index];
                              return AchievementCard(
                                achievement: achievement,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          // Initial state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
