import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/patient/patient_home_screen.dart';
import 'package:smriti_app/screens/daily_games_screen.dart';
import 'package:smriti_app/screens/home_screen.dart';

void main() {
  testWidgets('PatientHomeScreen displays 3 cards and navigates cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PatientHomeScreen()));
    await tester.pump();

    // Verify 3 cards
    expect(find.text('1. Daily Games'), findsOneWidget);
    expect(find.text('2. More Games'), findsOneWidget);
    expect(find.text('3. Reminders'), findsOneWidget);

    // Verify Bottom Navigation Bar
    expect(find.text('ASHA Worker'), findsOneWidget);
    expect(find.text('Reminders'), findsWidgets);

    // Tap on Card 1: 1. Daily Games -> Navigates to DailyGamesScreen
    await tester.ensureVisible(find.text('1. Daily Games'));
    await tester.tap(find.text('1. Daily Games'));
    await tester.pumpAndSettle();

    // Verify DailyGamesScreen contains ONLY Daily Calibration Test
    expect(find.byType(DailyGamesScreen), findsOneWidget);
    expect(find.text('Daily Calibration Test'), findsOneWidget);
    expect(find.text('Pulse Trainer'), findsNothing);
    expect(find.text('Wayfinder'), findsNothing);
    expect(find.text('Sequence Check'), findsNothing);

    // Pop back to PatientHomeScreen
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.byType(PatientHomeScreen), findsOneWidget);

    // Tap on Card 2: 2. More Games -> Navigates to HomeScreen (More Games)
    await tester.ensureVisible(find.text('2. More Games'));
    await tester.tap(find.text('2. More Games'));
    await tester.pumpAndSettle();

    // Verify More Games contains Pulse Trainer, Wayfinder, Sequence Check, and NOT Daily Calibration
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Pulse Trainer'), findsOneWidget);
    expect(find.text('Wayfinder'), findsOneWidget);
    expect(find.text('Sequence Check'), findsOneWidget);
    expect(find.text('Daily Calibration Test'), findsNothing);
  });
}
