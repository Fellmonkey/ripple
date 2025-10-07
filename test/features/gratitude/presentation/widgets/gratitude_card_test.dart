import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripple/features/gratitude/domain/entities/gratitude_entity.dart';
import 'package:ripple/features/gratitude/presentation/widgets/gratitude_card.dart';

void main() {
  group('GratitudeCard Widget Tests', () {
    testWidgets('displays all gratitude information correctly',
        (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Grateful for beautiful weather today',
        category: 'NATURE',
        tags: const ['nature', 'weather'],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 5,
        repliesCount: 2,
        parentId: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);
      expect(find.text('Grateful for beautiful weather today'),
          findsOneWidget);
      expect(find.text('nature'), findsOneWidget);
      expect(find.text('weather'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('by user123'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('displays photo when present', (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Beautiful sunset',
        category: 'NATURE',
        tags: const [],
        point: (0.0, 0.0),
        photo: 'https://example.com/photo.jpg',
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert - photo widget should be present
      expect(find.byKey(const Key('gratitude_photo')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('does not display photo when null',
        (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'No photo here',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert - photo widget should NOT be present
      expect(find.byKey(const Key('gratitude_photo')), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('truncates long author ID', (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'verylongauthorid123456789',
        text: 'Test text',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert - author should be truncated
      expect(find.text('by verylong...'), findsOneWidget);
      expect(find.text('by verylongauthorid123456789'), findsNothing);
    });

    testWidgets('does not display tags when empty',
        (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'No tags',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert - no chips should be displayed
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('does display replies count when zero',
        (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'No replies',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('calls onTap callback when card is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Tap test',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(
              gratitude: gratitude,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GratitudeCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, true);
    });

    testWidgets('calls onLike callback when like button is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool liked = false;
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Like test',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(
              gratitude: gratitude,
              onLike: () => liked = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Assert
      expect(liked, true);
    });

    testWidgets('formats date correctly for minutes', (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Recent post',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert
      expect(find.text('30m ago'), findsOneWidget);
    });

    testWidgets('formats date correctly for days', (WidgetTester tester) async {
      // Arrange
      final gratitude = GratitudeEntity(
        gratitudeId: '1',
        authorId: 'user123',
        text: 'Post from 3 days ago',
        category: 'OTHER',
        tags: const [],
        point: (0.0, 0.0),
        photo: null,
        likesCount: 0,
        repliesCount: 0,
        parentId: null,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GratitudeCard(gratitude: gratitude),
          ),
        ),
      );

      // Assert
      expect(find.text('3d ago'), findsOneWidget);
    });

    testWidgets('displays all category emojis correctly',
        (WidgetTester tester) async {
      // Test all categories
      final categories = [
        ('HEALTH', '💚', 'Health'),
        ('NATURE', '🌿', 'Nature'),
        ('PEOPLE', '🤝', 'People'),
        ('EVENTS', '🎉', 'Events'),
        ('ACHIEVEMENTS', '🏆', 'Achievements'),
        ('OTHER', '✨', 'Other'),
      ];

      for (final (value, emoji, label) in categories) {
        // Arrange
        final gratitude = GratitudeEntity(
          gratitudeId: '1',
          authorId: 'user123',
          text: 'Test $label',
          category: value,
          tags: const [],
          point: (0.0, 0.0),
          photo: null,
          likesCount: 0,
          repliesCount: 0,
          parentId: null,
          createdAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GratitudeCard(gratitude: gratitude),
            ),
          ),
        );

        // Assert
        expect(find.text(emoji), findsOneWidget,
            reason: 'Emoji $emoji for $label not found');
        expect(find.text(label), findsOneWidget,
            reason: 'Label $label not found');

        // Clear for next test
        await tester.pumpWidget(Container());
      }
    });
  });
}
