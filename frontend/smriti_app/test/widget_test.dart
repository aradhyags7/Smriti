import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_games/main.dart';
import 'package:mind_games/screens/end_screen.dart';
import 'package:mind_games/screens/pulse_trainer_screen.dart';
import 'package:mind_games/features/cognitive/spatial_memory/screens/wayfinder_home_screen.dart';
import 'package:mind_games/features/cognitive/working_memory/screens/sequence_home_screen.dart';

void main() {
  testWidgets('HomeScreen renders and navigates to Pulse Trainer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MindGamesApp());

    expect(find.text('Smriti'), findsWidgets);
    expect(find.text('Pulse Trainer'), findsOneWidget);
    expect(find.text('Wayfinder'), findsOneWidget);
    expect(find.text('Sequence Check'), findsOneWidget);

    // Tap Pulse Trainer
    await tester.ensureVisible(find.text('Pulse Trainer'));
    await tester.tap(find.text('Pulse Trainer'));
    await tester.pumpAndSettle();

    expect(find.byType(PulseTrainerScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to Wayfinder', (WidgetTester tester) async {
    await tester.pumpWidget(const MindGamesApp());

    await tester.ensureVisible(find.text('Wayfinder'));
    await tester.tap(find.text('Wayfinder'));
    await tester.pumpAndSettle();

    expect(find.byType(WayfinderHomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen navigates to Sequence Check',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MindGamesApp());

    await tester.ensureVisible(find.text('Sequence Check'));
    await tester.tap(find.text('Sequence Check'));
    await tester.pumpAndSettle();

    expect(find.byType(SequenceHomeScreen), findsOneWidget);
  });

  testWidgets('EndScreen renders title, score, and buttons',
      (WidgetTester tester) async {
    bool playAgainPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EndScreen(
          title: 'Test Game',
          scoreString: 'Score: 10/10',
          onPlayAgain: () {
            playAgainPressed = true;
          },
        ),
      ),
    );

    expect(find.text('Test Game'), findsWidgets);
    expect(find.text('Score: 10/10'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Play Again'));
    expect(playAgainPressed, isTrue);
  });
}
