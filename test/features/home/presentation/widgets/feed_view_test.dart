import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ripple/features/gratitude/domain/entities/gratitude_entity.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_bloc.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_event.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_state.dart';
import 'package:ripple/features/home/presentation/widgets/feed_view.dart';

class MockGratitudeBloc extends Mock implements GratitudeBloc {}

void main() {
  late MockGratitudeBloc mockGratitudeBloc;

  setUp(() {
    mockGratitudeBloc = MockGratitudeBloc();
    registerFallbackValue(const LoadGratitudes());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<GratitudeBloc>.value(
          value: mockGratitudeBloc,
          child: const FeedView(),
        ),
      ),
    );
  }

  group('FeedView Widget Tests', () {
    testWidgets('shows loading indicator when state is GratitudeLoading',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockGratitudeBloc.state).thenReturn(const GratitudeLoading());
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(const GratitudeLoading()));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byKey(const Key('feed_loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message and retry button when state is GratitudeError',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load gratitudes';
      when(() => mockGratitudeBloc.state)
          .thenReturn(const GratitudeError(errorMessage));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(const GratitudeError(errorMessage)));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byKey(const Key('feed_error')), findsOneWidget);
      expect(find.text('Error loading gratitudes'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('retry button triggers LoadGratitudes event',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockGratitudeBloc.state)
          .thenReturn(const GratitudeError('Error'));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(const GratitudeError('Error')));
      when(() => mockGratitudeBloc.add(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump();

      // Assert
      verify(() => mockGratitudeBloc.add(const LoadGratitudes())).called(1);
    });

    testWidgets('shows empty state when gratitudes list is empty',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockGratitudeBloc.state)
          .thenReturn(const GratitudeLoaded(gratitudes: []));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(const GratitudeLoaded(gratitudes: [])));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byKey(const Key('feed_empty')), findsOneWidget);
      expect(find.text('No gratitudes yet'), findsOneWidget);
      expect(find.text('Be the first to share your gratitude!'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
    });

    testWidgets('shows list of gratitudes when state is GratitudeLoaded with data',
        (WidgetTester tester) async {
      // Arrange
      final gratitudes = [
        GratitudeEntity(
          gratitudeId: '1',
          authorId: 'user1',
          text: 'Grateful for sunshine',
          category: 'NATURE',
          tags: const ['nature', 'weather'],
          point: (51.5074, -0.1278),
          photo: null,
          likesCount: 5,
          repliesCount: 2,
          parentId: null,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        GratitudeEntity(
          gratitudeId: '2',
          authorId: 'user2',
          text: 'Thankful for my health',
          category: 'HEALTH',
          tags: const ['health'],
          point: (51.5074, -0.1278),
          photo: null,
          likesCount: 10,
          repliesCount: 0,
          parentId: null,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      when(() => mockGratitudeBloc.state)
          .thenReturn(GratitudeLoaded(gratitudes: gratitudes));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(GratitudeLoaded(gratitudes: gratitudes)));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byKey(const Key('feed_list')), findsOneWidget);
      expect(find.byKey(const Key('gratitude_card_0')), findsOneWidget);
      expect(find.byKey(const Key('gratitude_card_1')), findsOneWidget);
      expect(find.text('Grateful for sunshine'), findsOneWidget);
      expect(find.text('Thankful for my health'), findsOneWidget);
    });

    testWidgets('filter chips are visible and functional',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockGratitudeBloc.state)
          .thenReturn(const GratitudeLoaded(gratitudes: []));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(const GratitudeLoaded(gratitudes: [])));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('All'), findsOneWidget);
      expect(find.text('My Gratitudes'), findsOneWidget);

      // Tap on "My Gratitudes" chip
      await tester.tap(find.text('My Gratitudes'));
      await tester.pump();

      // Both chips should still be visible
      expect(find.text('All'), findsOneWidget);
      expect(find.text('My Gratitudes'), findsOneWidget);
    });

    testWidgets('pull to refresh triggers LoadGratitudes event',
        (WidgetTester tester) async {
      // Arrange
      final gratitudes = [
        GratitudeEntity(
          gratitudeId: '1',
          authorId: 'user1',
          text: 'Test gratitude',
          category: 'OTHER',
          tags: const [],
          point: (0, 0),
          photo: null,
          likesCount: 0,
          repliesCount: 0,
          parentId: null,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockGratitudeBloc.state)
          .thenReturn(GratitudeLoaded(gratitudes: gratitudes));
      when(() => mockGratitudeBloc.stream)
          .thenAnswer((_) => Stream.value(GratitudeLoaded(gratitudes: gratitudes)));
      when(() => mockGratitudeBloc.add(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Simulate pull to refresh
      await tester.drag(find.byKey(const Key('feed_list')), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockGratitudeBloc.add(const LoadGratitudes())).called(greaterThanOrEqualTo(1));
    });
  });
}
