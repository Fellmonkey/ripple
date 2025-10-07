import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../gratitude/presentation/bloc/gratitude_bloc.dart';
import '../../../gratitude/presentation/bloc/gratitude_event.dart';
import '../../../gratitude/presentation/bloc/gratitude_state.dart';
import '../../../gratitude/presentation/widgets/gratitude_card.dart';

/// Feed view widget showing list of gratitudes
class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String _filter = 'all'; // 'all' or 'my'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filter = 'all');
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('My Gratitudes'),
                selected: _filter == 'my',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filter = 'my');
                  }
                },
              ),
            ],
          ),
        ),

        // Gratitude list
        Expanded(
          child: BlocBuilder<GratitudeBloc, GratitudeState>(
            builder: (context, state) {
              if (state is GratitudeLoading) {
                return const Center(
                  key: Key('feed_loading'),
                  child: CircularProgressIndicator(),
                );
              }

              if (state is GratitudeError) {
                return Center(
                  key: const Key('feed_error'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading gratitudes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        key: const Key('retry_button'),
                        onPressed: () {
                          context.read<GratitudeBloc>().add(const LoadGratitudes());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is GratitudeLoaded) {
                final gratitudes = state.gratitudes;

                if (gratitudes.isEmpty) {
                  return Center(
                    key: const Key('feed_empty'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.volunteer_activism,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No gratitudes yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to share your gratitude!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  key: const Key('feed_refresh'),
                  onRefresh: () async {
                    context.read<GratitudeBloc>().add(const LoadGratitudes());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    key: const Key('feed_list'),
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 80, // Space for FAB
                    ),
                    itemCount: gratitudes.length,
                    itemBuilder: (context, index) {
                      final gratitude = gratitudes[index];
                      return GratitudeCard(
                        key: Key('gratitude_card_$index'),
                        gratitude: gratitude,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Details for: ${gratitude.text}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onLike: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Like feature coming soon!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
