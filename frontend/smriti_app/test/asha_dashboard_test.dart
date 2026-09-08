import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_app/features/asha/asha_dashboard_screen.dart';
import 'package:smriti_app/features/asha/services/asha_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Sister Kalyani',
      'user_email': 'kalyani@asha.gov.in',
      'user_role': 'asha',
      'access_token': 'dummy-mock-token',
    });
  });

  group('ASHA Dashboard Models & Schema Deserialization Tests', () {
    test('AshaPatient deserializes correctly with triage, dementia type, and clinical notes', () {
      final json = {
        'patient_id': 'pat-101',
        'user_id': 'user-101',
        'full_name': 'Bhaben Kalita',
        'email': 'bhaben@test.com',
        'phone_number': '+919876543210',
        'age': 76,
        'gender': 'male',
        'dementia_type': "Alzheimer's disease",
        'village': 'Kamrup Sector 4',
        'district': 'Kamrup',
        'status': 'Stable',
        'status_color': 'green',
        'triage_priority': 'CRITICAL',
        'consent_for_asha': true,
        'caregiver_name': 'Son Kalita',
        'caregiver_phone': '+919876543000',
        'caregiver_relationship': 'Son',
        'baseline_memory': 68.5,
        'baseline_attention': 72.0,
        'baseline_engagement': 80.0,
        'primary_language': 'as',
        'medical_notes': '[08 Sep 2026 - Home Visit]: Blood pressure 125/80. Mood calm.',
        'last_visit': 'Today',
        'unresolved_alerts_count': 1,
      };

      final patient = AshaPatient.fromJson(json);

      expect(patient.patientId, equals('pat-101'));
      expect(patient.fullName, equals('Bhaben Kalita'));
      expect(patient.age, equals(76));
      expect(patient.gender, equals('male'));
      expect(patient.dementiaType, equals("Alzheimer's disease"));
      expect(patient.triagePriority, equals('CRITICAL'));
      expect(patient.caregiverName, equals('Son Kalita'));
      expect(patient.caregiverRelationship, equals('Son'));
      expect(patient.baselineMemory, equals(68.5));
      expect(patient.baselineAttention, equals(72.0));
      expect(patient.baselineEngagement, equals(80.0));
      expect(patient.primaryLanguage, equals('as'));
      expect(patient.medicalNotes, contains('Blood pressure 125/80'));
      expect(patient.unresolvedAlertsCount, equals(1));
    });

    test('AshaEmergencyAlert deserializes correctly', () {
      final alertJson = {
        'id': 'alert-99',
        'patient_id': 'pat-101',
        'patient_name': 'Bhaben Kalita',
        'patient_age': 76,
        'risk_level': 'CRITICAL',
        'severity': 'HIGH',
        'reason': 'Memory score dropped 18% over 7 consecutive days',
        'is_acknowledged': false,
        'created_at': 'Today, 10:30 AM',
      };

      final alert = AshaEmergencyAlert.fromJson(alertJson);

      expect(alert.id, equals('alert-99'));
      expect(alert.patientName, equals('Bhaben Kalita'));
      expect(alert.patientAge, equals(76));
      expect(alert.riskLevel, equals('CRITICAL'));
      expect(alert.severity, equals('HIGH'));
      expect(alert.reason, contains('dropped 18%'));
      expect(alert.isAcknowledged, isFalse);
    });

    test('AshaPatientDetailData deserializes full read-only patient detail', () {
      final detailJson = {
        'patient': {
          'patient_id': 'pat-101',
          'user_id': 'user-101',
          'full_name': 'Bhaben Kalita',
          'age': 76,
          'gender': 'male',
          'dementia_type': "Alzheimer's disease",
          'village': 'Kamrup Sector 4',
          'district': 'Kamrup',
          'status': 'Attention Required',
          'status_color': 'amber',
          'triage_priority': 'ATTENTION_REQUIRED',
          'consent_for_asha': true,
          'baseline_memory': 70.0,
          'last_visit': '08 Sep 2026',
        },
        'analytics': {
          'patient_id': 'pat-101',
          'patient_name': 'Bhaben Kalita',
          'risk_level': 'ATTENTION_REQUIRED',
          'current_memory': 68.0,
          'current_attention': 71.0,
          'current_engagement': 75.0,
          'trend': [
            {'date': '2026-09-01', 'memory': 75.0, 'attention': 74.0, 'engagement': 78.0},
            {'date': '2026-09-08', 'memory': 68.0, 'attention': 71.0, 'engagement': 75.0},
          ],
        },
        'activity_feed': {
          'date': '2026-09-08',
          'games': [
            {
              'id': 'game-1',
              'game_type': 'PICTURE_RECALL',
              'game_name': 'Picture Recall',
              'score': 85,
              'mistakes': 1,
              'reaction_time_seconds': 2.4,
              'played_at': '2026-09-08T09:00:00',
            }
          ],
          'checkin': {
            'mood': 'Calm',
            'sleep_hours': 7.5,
            'symptoms': ['Mild confusion'],
          },
        },
        'alerts': [
          {
            'id': 'alert-99',
            'patient_id': 'pat-101',
            'patient_name': 'Bhaben Kalita',
            'patient_age': 76,
            'risk_level': 'ATTENTION_REQUIRED',
            'severity': 'MEDIUM',
            'reason': 'Attention score lowered slightly',
            'is_acknowledged': false,
            'created_at': '08 Sep 2026',
          }
        ],
        'medical_notes_history': [
          '[01 Sep 2026 - Initial]: Patient assigned.',
          '[08 Sep 2026 - Home Visit]: Vitals normal, good engagement.',
        ],
      };

      final detail = AshaPatientDetailData.fromJson(detailJson);

      expect(detail.patient.fullName, equals('Bhaben Kalita'));
      expect(detail.analytics, isNotNull);
      expect(detail.activityFeed, isNotNull);
      expect(detail.alerts.length, equals(1));
      expect(detail.alerts.first.severity, equals('MEDIUM'));
      expect(detail.medicalNotesHistory.length, equals(2));
      expect(detail.medicalNotesHistory.last, contains('Vitals normal'));
    });
  });

  group('ASHA Worker Portal Widget Tests', () {
    testWidgets('AshaDashboardScreen renders title, triage priority summaries, and navigation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: AshaDashboardScreen(),
        ),
      );

      // Initial pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title in AppBar
      expect(find.text('ASHA Worker Portal'), findsOneWidget);
      expect(find.text('Population Health & Triage'), findsOneWidget);

      // Bottom Navigation items
      expect(find.text('Roster'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Visits'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);

      // Triage Priority stat summary labels
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Attention'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
      expect(find.text('Stable'), findsOneWidget);

      // Triage Filter chips
      expect(find.textContaining('All ('), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Tapping Emergency Alerts tab switches view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: AshaDashboardScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Emergency Alerts tab
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Alerts Inbox'), findsOneWidget);
      expect(find.text('High-severity clinical escalations across your roster'), findsOneWidget);
    });

    testWidgets('Tapping Home Visits tab switches view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: AshaDashboardScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Home Visits tab
      await tester.tap(find.text('Visits'));
      await tester.pumpAndSettle();

      expect(find.text('Home Visits & Clinical Notes'), findsOneWidget);
      expect(find.text('Log and review observations from village visits'), findsOneWidget);
    });
  });
}
