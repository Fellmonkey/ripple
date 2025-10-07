import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../gratitude/presentation/bloc/gratitude_bloc.dart';
import '../../../gratitude/presentation/bloc/gratitude_event.dart';
import '../../../gratitude/presentation/bloc/gratitude_state.dart';
import '../../../gratitude/presentation/screens/replies_bottom_sheet.dart';
import '../../../gratitude/presentation/widgets/gratitude_card.dart';

/// Feed view widget showing list of gratitudes
class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String _filter = 'all'; // 'all' or 'my'
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  bool _isLoadingMore = false; // Prevent duplicate load calls

  // Cache the last GratitudeLoaded so the feed can still render when
  // the BLoC temporarily switches to replies-related states.
  GratitudeLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Ensure the feed is loaded at first frame if GratitudeBloc hasn't emitted data yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gratitudeState = context.read<GratitudeBloc>().state;
      // Only dispatch initial load if bloc is in its initial state. This
      // prevents duplicate LoadGratitudes being dispatched when other
      // parts of the app (or tests) already triggered a load.
      if (gratitudeState is GratitudeInitial) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is Authenticated ? authState.user.$id : null;
        context.read<GratitudeBloc>().add(LoadGratitudes(currentUserId: userId));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Prevent duplicate calls while already loading
    if (_isLoadingMore) return;

    // Check if we're near the bottom (200px threshold)
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<GratitudeBloc>().state;

      // Only load more if we're in loaded state and not already loading
      if (state is GratitudeLoaded && !state.isLoadingMore && state.hasMoreData) {
        _isLoadingMore = true;

        final authState = context.read<AuthBloc>().state;
        final userId = authState is Authenticated ? authState.user.$id : null;

        context.read<GratitudeBloc>().add(LoadMoreGratitudes(
          currentUserId: userId,
          searchQuery: state.searchQuery,
        ));

        // Reset flag after a short delay to allow next load
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isLoadingMore = false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by tags or text...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearching = false);
                        final authState = context.read<AuthBloc>().state;
                        final userId = authState is Authenticated ? authState.user.$id : null;
                        context.read<GratitudeBloc>().add(ClearSearch(currentUserId: userId));
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                setState(() => _isSearching = true);
                final authState = context.read<AuthBloc>().state;
                final userId = authState is Authenticated ? authState.user.$id : null;
                context.read<GratitudeBloc>().add(
                      SearchGratitudes(
                        searchQuery: query.trim(),
                        currentUserId: userId,
                      ),
                    );
              }
            },
          ),
        ),

        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Cache the last loaded feed so replies UI doesn't make the
              // feed disappear.
              if (state is GratitudeLoaded) {
                _lastLoadedState = state;
              }

              // Show loading indicator when explicitly loading
              if (state is GratitudeLoading) {
                return const Center(
                  key: Key('feed_loading'),
                  child: CircularProgressIndicator(),
                );
              }

              // Show error UI when error
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
                          final authState = context.read<AuthBloc>().state;
                          final userId = authState is Authenticated ? authState.user.$id : null;
                          context.read<GratitudeBloc>().add(LoadGratitudes(currentUserId: userId));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Use the last loaded state as a fallback when the bloc is in
              // a replies-related state to avoid emptying the feed.
              final displayState = (state is GratitudeLoaded)
                  ? state
                  : (_lastLoadedState ?? const GratitudeLoaded(gratitudes: []));

              final gratitudes = displayState.gratitudes;

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
                  final authState = context.read<AuthBloc>().state;
                  final userId = authState is Authenticated ? authState.user.$id : null;
                  context.read<GratitudeBloc>().add(LoadGratitudes(currentUserId: userId));
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  key: const Key('feed_list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 80, // Space for FAB
                  ),
                  itemCount: gratitudes.length + (displayState.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom
                    if (index == gratitudes.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final gratitude = gratitudes[index];

                    // Get userId from AuthBloc
                    final authState = context.watch<AuthBloc>().state;
                    final userId = authState is Authenticated ? authState.user.$id : null;

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
                      onLike: userId != null
                          ? () {
                              context.read<GratitudeBloc>().add(
                                    ToggleGratitudeLike(
                                      userId: userId,
                                      gratitudeId: gratitude.gratitudeId,
                                      currentLikes: gratitude.likesCount,
                                      isLiked: gratitude.isLiked,
                                    ),
                                  );
                            }
                          : null,
                      onRepliesTap: () {
                        showRepliesBottomSheet(context, gratitude);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
