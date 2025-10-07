import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/gratitude_entity.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';
import '../bloc/gratitude_state.dart';
import '../widgets/gratitude_card.dart';
import 'add_gratitude_bottom_sheet.dart';

/// Bottom sheet showing replies to a gratitude (Chains of Kindness)
/// 
/// Displays:
/// - Parent gratitude card
/// - List of replies
/// - Button to add a reply
Future<void> showRepliesBottomSheet(
  BuildContext context,
  GratitudeEntity parentGratitude,
) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RepliesBottomSheet(
      parentGratitude: parentGratitude,
    ),
  );
}

class RepliesBottomSheet extends StatefulWidget {
  final GratitudeEntity parentGratitude;

  const RepliesBottomSheet({
    required this.parentGratitude,
    super.key,
  });

  @override
  State<RepliesBottomSheet> createState() => _RepliesBottomSheetState();
}

class _RepliesBottomSheetState extends State<RepliesBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Load replies when sheet opens
    context.read<GratitudeBloc>().add(
          LoadReplies(widget.parentGratitude.gratitudeId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chains of Kindness',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: BlocBuilder<GratitudeBloc, GratitudeState>(
              builder: (context, state) {
                if (state is GratitudeRepliesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is GratitudeRepliesError) {
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
                          'Failed to load replies',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<GratitudeBloc>().add(
                                  LoadReplies(widget.parentGratitude.gratitudeId),
                                );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final replies = state is GratitudeRepliesLoaded ? state.replies : <GratitudeEntity>[];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Parent gratitude card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Original Gratitude',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GratitudeCard(
                                gratitude: widget.parentGratitude,
                                onTap: () {},
                                onLike: () {
                                  final authState = context.read<AuthBloc>().state;
                                  final userId = authState is Authenticated ? authState.user.$id : null;
                                  if (userId != null) {
                                    context.read<GratitudeBloc>().add(
                                          ToggleGratitudeLike(
                                            userId: userId,
                                            gratitudeId: widget.parentGratitude.gratitudeId,
                                            currentLikes: widget.parentGratitude.likesCount,
                                            isLiked: widget.parentGratitude.isLiked,
                                          ),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Replies header
                      Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Replies (${replies.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Replies list
                      if (replies.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No replies yet',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to respond!',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...replies.map(
                          (reply) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            child: GratitudeCard(
                              gratitude: reply,
                              onTap: () {},
                              onLike: () {
                                final authState = context.read<AuthBloc>().state;
                                final userId = authState is Authenticated ? authState.user.$id : null;
                                if (userId != null) {
                                  context.read<GratitudeBloc>().add(
                                        ToggleGratitudeLike(
                                          userId: userId,
                                          gratitudeId: reply.gratitudeId,
                                          currentLikes: reply.likesCount,
                                          isLiked: reply.isLiked,
                                        ),
                                      );
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add reply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () async {
                  // Use parent's location for the reply
                  final parentLocation = LatLng(
                    widget.parentGratitude.point.$1,
                    widget.parentGratitude.point.$2,
                  );
                  
                  // Show add gratitude bottom sheet with parent ID
                  await showAddGratitudeBottomSheet(
                    context,
                    selectedLocationNotifier: ValueNotifier(parentLocation),
                    isSelectingLocationNotifier: ValueNotifier(false),
                    initialLocation: parentLocation,
                    parentId: widget.parentGratitude.gratitudeId,
                  );

                  // Reload replies after adding
                  if (context.mounted) {
                    context.read<GratitudeBloc>().add(
                          LoadReplies(widget.parentGratitude.gratitudeId),
                        );
                  }
                },
                icon: const Icon(Icons.reply),
                label: const Text('Add Reply'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
