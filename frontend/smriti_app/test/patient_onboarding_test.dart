import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/patient/patient_onboarding_screen.dart';

void main() {
  group('PatientOnboardingScreen Widget Tests', () {
    testWidgets('renders all onboarding form fields and 6 dementia options', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientOnboardingScreen(),
        ),
      );

      expect(find.text('Health Profile Setup'), findsOneWidget);
      expect(find.text('Your Age'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Type of Dementia'), findsOneWidget);
      expect(find.text('Save & Continue'), findsOneWidget);

      // Verify default dementia dropdown value
      expect(find.text('Alzheimer’s disease'), findsOneWidget);

      // Tap dropdown to verify all 6 required dementia diagnosis options
      await tester.tap(find.text('Alzheimer’s disease'));
      await tester.pumpAndSettle();

      expect(find.text('Alzheimer’s disease'), findsWidgets);
      expect(find.text('Vascular dementia'), findsOneWidget);
      expect(find.text('Lewy body dementia'), findsOneWidget);
      expect(find.text('Frontotemporal dementia (FTD)'), findsOneWidget);
      expect(find.text('Mixed dementia'), findsOneWidget);
      expect(find.text('Other / unspecified'), findsOneWidget);

      // Select Vascular dementia
      await tester.tap(find.text('Vascular dementia').last);
      await tester.pumpAndSettle();
      expect(find.text('Vascular dementia'), findsOneWidget);
    });

    testWidgets('validates age field on empty input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientOnboardingScreen(),
        ),
      );

      // Clear age text
      await tester.enterText(find.byType(TextFormField), '');
      await tester.ensureVisible(find.text('Save & Continue'));
      await tester.tap(find.text('Save & Continue'));
      await tester.pump();

      expect(find.text('Please enter your age'), findsOneWidget);
    });
  });
}
