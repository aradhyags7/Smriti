import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/patient/patient_home_screen.dart';
import 'package:smriti_app/screens/home_screen.dart';

void main() {
  testWidgets('PatientHomeScreen displays 3 cards and navigates to Games',
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

    // Tap on Card 1: 1. Daily Games -> Navigates to HomeScreen
    await tester.ensureVisible(find.text('1. Daily Games'));
    await tester.tap(find.text('1. Daily Games'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
