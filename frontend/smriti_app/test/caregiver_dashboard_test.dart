import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/caregiver/widgets/cognitive_line_chart.dart';
import 'package:smriti_app/features/caregiver/services/caregiver_service.dart';
import 'package:smriti_app/features/caregiver/caregiver_dashboard_screen.dart';

void main() {
  group('Caregiver Dashboard & Widgets Tests', () {
    test('CognitiveAnalyticsData deserializes properly from backend schema', () {
      final json = {
        'patient_id': 'pt-123',
        'patient_name': 'Grandmother Shanti',
        'risk_level': 'STABLE',
        'current_memory': 78.5,
        'current_attention': 82.0,
        'current_engagement': 75.0,
        'trend': [
          {'date': '09-01', 'memory': 76.0, 'attention': 80.0, 'engagement': 74.0},
          {'date': '09-02', 'memory': 78.5, 'attention': 82.0, 'engagement': 75.0},
        ],
      };

      final data = CognitiveAnalyticsData.fromJson(json);
      expect(data.patientId, 'pt-123');
      expect(data.patientName, 'Grandmother Shanti');
      expect(data.riskLevel, 'STABLE');
      expect(data.currentMemory, 78.5);
      expect(data.trend.length, 2);
      expect(data.trend.first.memory, 76.0);
    });

    test('DailyActivityFeed deserializes properly', () {
      final json = {
        'date': '2026-09-08',
        'games': [
          {
            'id': 'g1',
            'game_type': 'daily_calibration',
            'game_name': 'Daily Calibration Battery',
            'score': 88,
            'mistakes': 1,
            'reaction_time_seconds': 1.25,
            'played_at': '10:00 AM',
          }
        ],
        'checkin': {
          'mood': 'Good',
          'sleep_hours': 8.0,
          'symptoms': ['Calm', 'Rested'],
          'notes': 'Slept peacefully',
        }
      };

      final feed = DailyActivityFeed.fromJson(json);
      expect(feed.date, '2026-09-08');
      expect(feed.games.length, 1);
      expect(feed.games.first.score, 88);
      expect(feed.games.first.reactionTimeSeconds, 1.25);
      expect(feed.checkin?.mood, 'Good');
      expect(feed.checkin?.sleepHours, 8.0);
    });

    test('CaregiverAlert and ReminiscenceVaultItem deserialize properly', () {
      final alertJson = {
        'id': 'a-1',
        'alert_type': 'COGNITIVE_VARIANCE',
        'severity': 'WARNING',
        'title': 'Calibration Missed',
        'message': 'No game played for 2 days',
        'is_acknowledged': false,
      };
      final alert = CaregiverAlert.fromJson(alertJson);
      expect(alert.severity, 'WARNING');
      expect(alert.isAcknowledged, false);

      final remJson = {
        'id': 'rem-1',
        'patient_id': 'pt-1',
        'title': 'Bihu Celebration',
        'caption': 'Dancing with grandchildren',
        'media_type': 'PHOTO',
        'media_url': 'assets/images/logo/smriti-logo.jpg',
        'relationship_tag': 'Grandchildren',
      };
      final rem = ReminiscenceVaultItem.fromJson(remJson);
      expect(rem.title, 'Bihu Celebration');
      expect(rem.relationshipTag, 'Grandchildren');
      expect(rem.mediaType, 'PHOTO');
    });

    testWidgets('CognitiveLineChart renders with trend and triggers metric toggle', (tester) async {
      final trend = [
        TrendPoint(date: '09-01', memory: 75.0, attention: 80.0, engagement: 70.0),
        TrendPoint(date: '09-02', memory: 78.0, attention: 82.0, engagement: 74.0),
        TrendPoint(date: '09-03', memory: 76.5, attention: 83.0, engagement: 72.0),
      ];

      String selected = 'ALL';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CognitiveLineChart(
                  trend: trend,
                  selectedMetric: selected,
                  onMetricChanged: (val) {
                    setState(() => selected = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('All Metrics'), findsOneWidget);
      expect(find.text('Memory'), findsWidgets);
      expect(find.text('Attention'), findsWidgets);
      expect(find.text('Engagement'), findsWidgets);

      // Tap 'Attention' chip
      await tester.tap(find.text('Attention').first);
      await tester.pumpAndSettle();
      expect(selected, 'ATTENTION');
    });

    testWidgets('CaregiverDashboardScreen renders empty state when no patients connected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaregiverDashboardScreen(),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Renders Smriti Caregiver header
      expect(find.text('Smriti Caregiver'), findsOneWidget);
    });
  });
}
