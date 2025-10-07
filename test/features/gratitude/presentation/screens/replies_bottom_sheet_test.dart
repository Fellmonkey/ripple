import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/models.dart' as models;
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_state.dart';
import 'package:ripple/features/gratitude/domain/entities/gratitude_entity.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_bloc.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_event.dart';
import 'package:ripple/features/gratitude/presentation/bloc/gratitude_state.dart';
import 'package:ripple/features/gratitude/presentation/screens/replies_bottom_sheet.dart';

// Mocks
class MockGratitudeBloc extends Mock implements GratitudeBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockUser extends Mock implements models.User {}
class FakeGratitudeEvent extends Fake implements GratitudeEvent {}
class FakeGratitudeState extends Fake implements GratitudeState {}

void main() {
  late MockGratitudeBloc mockGratitudeBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeGratitudeEvent());
    registerFallbackValue(FakeGratitudeState());
  });

  setUp(() async{
    await dotenv.load(fileName: 'assets/.env');

    mockGratitudeBloc = MockGratitudeBloc();
    mockAuthBloc = MockAuthBloc();
    
    // Default auth state with mock user
    final mockUser = MockUser();
    when(() => mockUser.$id).thenReturn('test-user-id');
    
    when(() => mockAuthBloc.state).thenReturn(Authenticated(mockUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(Authenticated(mockUser)));
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    
    when(() => mockGratitudeBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    mockGratitudeBloc.close();
    mockAuthBloc.close();
  });

  final testParentGratitude = GratitudeEntity(
    gratitudeId: 'parent-1',
    authorId: 'user-1',
    text: 'Parent gratitude text',
    point: (55.7558, 37.6173),
    category: 'HEALTH',
    tags: const ['test'],
    likesCount: 5,
    repliesCount: 2,
    createdAt: DateTime.now(),
    isLiked: false,
  );

  final testReplies = [
    GratitudeEntity(
      gratitudeId: 'reply-1',
      authorId: 'user-2',
      text: 'First reply',
      point: (55.7558, 37.6173),
      category: 'HEALTH',
      tags: const [],
      likesCount: 1,
      repliesCount: 0,
      parentId: 'parent-1',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isLiked: true,
    ),
    GratitudeEntity(
      gratitudeId: 'reply-2',
      authorId: 'user-3',
      text: 'Second reply',
      point: (55.7558, 37.6173),
      category: 'HEALTH',
      tags: const [],
      likesCount: 0,
      repliesCount: 0,
      parentId: 'parent-1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isLiked: false,
    ),
  ];

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GratitudeBloc>.value(value: mockGratitudeBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => RepliesBottomSheet(
              parentGratitude: testParentGratitude,
            ),
          ),
        ),
      ),
    );
  }

  group('RepliesBottomSheet Widget Tests', () {
    testWidgets('should show loading indicator initially', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([const GratitudeRepliesLoading()]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(const GratitudeRepliesLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display parent gratitude card', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([GratitudeRepliesLoaded(testReplies)]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(GratitudeRepliesLoaded(testReplies));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Parent gratitude text'), findsOneWidget);
      expect(find.text('Chains of Kindness'), findsOneWidget);
    });

    testWidgets('should display replies when loaded', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([GratitudeRepliesLoaded(testReplies)]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(GratitudeRepliesLoaded(testReplies));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('First reply'), findsOneWidget);
      expect(find.text('Second reply'), findsOneWidget);
      // UI shows header as: Replies (N)
      expect(find.text('Replies (2)'), findsOneWidget);
    });

    testWidgets('should show empty state when no replies', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([const GratitudeRepliesLoaded([])]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(const GratitudeRepliesLoaded([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No replies yet'), findsOneWidget);
      expect(find.text('Be the first to respond!'), findsOneWidget);
    });

    testWidgets('should display error state correctly', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([const GratitudeRepliesError('Failed to load replies')]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(
        const GratitudeRepliesError('Failed to load replies'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert (allow multiple matching text widgets with different styles)
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load replies'), findsWidgets);
    });

    testWidgets('should show "Add Reply" button', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([GratitudeRepliesLoaded(testReplies)]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(GratitudeRepliesLoaded(testReplies));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

  // Assert: Add Reply label is present and at least one reply icon is in the UI
  expect(find.text('Add Reply'), findsOneWidget);
  expect(find.byIcon(Icons.reply), findsWidgets);
    });

    testWidgets('should trigger LoadReplies event on init', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([const GratitudeRepliesLoading()]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(const GratitudeRepliesLoading());
      when(() => mockGratitudeBloc.add(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      // allow one frame for initState to run
      await tester.pump();

      // Assert: verify LoadReplies was dispatched (no long pumpAndSettle to avoid timeout)
      verify(() => mockGratitudeBloc.add(LoadReplies(testParentGratitude.gratitudeId)))
        .called(1);
    });

    testWidgets('should trigger ToggleGratitudeLike on parent card like', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([GratitudeRepliesLoaded(testReplies)]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(GratitudeRepliesLoaded(testReplies));
      when(() => mockGratitudeBloc.add(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap like button on parent card
      final likeButton = find.byIcon(Icons.favorite_border).first;
      await tester.tap(likeButton);
      await tester.pump();

      // Assert
      verify(
        () => mockGratitudeBloc.add(
          any(that: predicate((e) {
            return e is ToggleGratitudeLike &&
                e.userId == 'test-user-id' &&
                e.gratitudeId == testParentGratitude.gratitudeId &&
                e.currentLikes == testParentGratitude.likesCount &&
                e.isLiked == testParentGratitude.isLiked;
          })),
        ),
      ).called(1);
    });

    testWidgets('should show filled heart for liked reply', (tester) async {
      // Arrange
      when(() => mockGratitudeBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([GratitudeRepliesLoaded(testReplies)]),
      );
      when(() => mockGratitudeBloc.state).thenReturn(GratitudeRepliesLoaded(testReplies));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - first reply is liked, should show filled heart
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      // Second reply is not liked, should show outlined heart
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(2)); // parent + second reply
    });
  });
}
