import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/patient/patient_home_screen.dart';

void main() {
  testWidgets('PatientHomeScreen displays Quick Play games and Games tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PatientHomeScreen()));
    await tester.pump();

    // Verify Home tab content
    expect(find.text('Good Morning, Patient'), findsOneWidget);
    expect(find.text('1. Daily Games'), findsOneWidget);
    expect(find.text('Quick Play'), findsOneWidget);
    expect(find.text('Pulse Trainer'), findsOneWidget);
    expect(find.text('Wayfinder'), findsOneWidget);
    expect(find.text('Sequence Check'), findsOneWidget);

    // Tap on the Games tab in bottom navigation bar
    expect(find.text('Games'), findsOneWidget);
    await tester.tap(find.text('Games'));
    await tester.pump();

    // Verify Games tab content
    expect(find.text('Memory & Focus'), findsOneWidget);
    expect(find.text('Daily Calibration Test'), findsOneWidget);
    expect(find.text('Clinical Game Library'), findsOneWidget);
  });
}
