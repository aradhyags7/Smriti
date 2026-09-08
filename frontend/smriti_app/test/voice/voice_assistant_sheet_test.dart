/*
 * Widget and integration tests for [VoiceAssistantSheet].
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/reminder_notification_service.dart';
import 'package:smriti_app/features/reminders/reminder_service.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';
import 'package:smriti_app/features/voice/voice_assistant_sheet.dart';
import 'package:smriti_app/features/voice/voice_controller.dart';
import 'package:smriti_app/screens/daily_games_screen.dart';

class _FakeReminderService implements IReminderService {
  final Map<String, ReminderModel> storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    storage[reminder.id] = reminder;
    return reminder;
  }

  @override
  Future<ReminderModel?> getReminder(String id) async => storage[id];

  @override
  Future<List<ReminderModel>> getAllReminders() async => storage.values.toList();

  @override
  Future<bool> updateReminder(ReminderModel reminder) async {
    storage[reminder.id] = reminder;
    return true;
  }

  @override
  Future<bool> deleteReminder(String id) async {
    storage.remove(id);
    return true;
  }

  @override
  Future<bool> enableReminder(String id) async => true;

  @override
  Future<bool> disableReminder(String id) async => true;

  @override
  Future<bool> acknowledgeReminder(String id, {DateTime? acknowledgedAt}) async => true;

  @override
  Future<void> clearAll() async => storage.clear();
}

class _FakeNotificationService implements IReminderNotificationService {
  final List<String> scheduledIds = [];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> scheduleReminder(ReminderModel reminder) async {
    scheduledIds.add(reminder.id);
    return true;
  }

  @override
  Future<void> cancelReminder(String reminderId) async {}

  @override
  Future<void> cancelAllReminders() async {
    scheduledIds.clear();
  }

  @override
  Future<bool> rescheduleReminder(ReminderModel reminder) async => scheduleReminder(reminder);
}

void main() {
  group('VoiceAssistantSheet Widget Tests', () {
    testWidgets('renders all initial UI elements correctly', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  VoiceAssistantSheet.show(
                    context,
                    controllerFactory: () => VoiceController(
                      stt: mockStt,
                      tts: mockTts,
                      engine: engine,
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Smriti Voice Assistant'), findsOneWidget);
      expect(find.byKey(const Key('sheet_status_text')), findsOneWidget);
      expect(find.byKey(const Key('sheet_transcript_text')), findsOneWidget);
      expect(find.byKey(const Key('sheet_mic_icon')), findsOneWidget);
    });

    testWidgets('tapping mic button toggles listening state', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  VoiceAssistantSheet.show(
                    context,
                    controllerFactory: () => VoiceController(
                      stt: mockStt,
                      tts: mockTts,
                      engine: engine,
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially starts listening (due to auto-listen for elder ease)
      // Tap mic to stop
      await tester.tap(find.byKey(const Key('sheet_mic_icon')));
      await tester.pump();

      // Tap again to start
      await tester.tap(find.byKey(const Key('sheet_mic_icon')));
      await tester.pump();

      expect(mockStt.isListening, isTrue);
    });

    testWidgets('startGame intent navigates to DailyGamesScreen', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      late VoiceController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  VoiceAssistantSheet.show(
                    context,
                    controllerFactory: () {
                      controller = VoiceController(
                        stt: mockStt,
                        tts: mockTts,
                        engine: engine,
                      );
                      return controller;
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Simulate spoken command "start the game"
      mockStt.simulateSpeech('start the game', isFinal: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Verify sheet popped and DailyGamesScreen opened
      expect(find.byType(DailyGamesScreen), findsOneWidget);
    });

    testWidgets('setReminder intent schedules reminder', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminders = _FakeReminderService();
      final fakeNotifications = _FakeNotificationService();
      late VoiceController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  VoiceAssistantSheet.show(
                    context,
                    reminderService: fakeReminders,
                    notificationService: fakeNotifications,
                    controllerFactory: () {
                      controller = VoiceController(
                        stt: mockStt,
                        tts: mockTts,
                        engine: engine,
                      );
                      return controller;
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Spoken command with time
      mockStt.simulateSpeech('remind me to drink water at 10 AM', isFinal: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify reminder created and notification scheduled
      expect(fakeReminders.storage.values.length, 1);
      expect(fakeNotifications.scheduledIds.length, 1);
      expect(fakeReminders.storage.values.first.title.toLowerCase(), contains('water'));

      // Flush auto-dismiss timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });
  });
}
