import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/app/app.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/reminder_notification_service.dart';
import 'package:smriti_app/features/reminders/reminder_service.dart';
import 'package:smriti_app/features/reminders/reminders_screen.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';
import 'package:smriti_app/features/voice/voice_controller.dart';

class _FakeReminderService implements IReminderService {
  final Map<String, ReminderModel> storage = {};
  bool shouldThrowOnSave = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    if (shouldThrowOnSave) throw Exception('Simulated persistence failure');
    storage[reminder.id] = reminder;
    return reminder;
  }

  @override
  Future<ReminderModel?> getReminder(String id) async => storage[id];

  @override
  Future<List<ReminderModel>> getAllReminders() async => storage.values.toList();

  @override
  Future<bool> updateReminder(ReminderModel reminder) async {
    if (!storage.containsKey(reminder.id)) return false;
    storage[reminder.id] = reminder;
    return true;
  }

  @override
  Future<bool> deleteReminder(String id) async {
    if (!storage.containsKey(id)) return false;
    storage.remove(id);
    return true;
  }

  @override
  Future<bool> enableReminder(String id) async {
    final r = storage[id];
    if (r == null) return false;
    storage[id] = r.copyWith(isEnabled: true);
    return true;
  }

  @override
  Future<bool> disableReminder(String id) async {
    final r = storage[id];
    if (r == null) return false;
    storage[id] = r.copyWith(isEnabled: false);
    return true;
  }

  @override
  Future<bool> acknowledgeReminder(String id, {DateTime? acknowledgedAt}) async {
    final r = storage[id];
    if (r == null) return false;
    storage[id] = r.copyWith(acknowledgedAt: acknowledgedAt ?? DateTime.now());
    return true;
  }

  @override
  Future<void> clearAll() async => storage.clear();
}

class _FakeNotificationService implements IReminderNotificationService {
  final List<String> scheduledIds = [];
  bool shouldFailScheduling = false;
  bool shouldThrowScheduling = false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> scheduleReminder(ReminderModel reminder) async {
    if (shouldThrowScheduling) throw Exception('Simulated scheduling error');
    if (shouldFailScheduling) return false;
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
  group('VoiceTestScreen Widget Tests', () {
    testWidgets('renders all initial UI elements correctly', (tester) async {
      await tester.pumpWidget(const SmritiApp());

      // Title and Subtitle
      expect(find.text('Smriti'), findsWidgets);
      expect(find.text('Voice & Reminders'), findsOneWidget);

      // Status
      expect(find.text('Idle'), findsOneWidget);

      // Transcript area
      expect(find.text('(No transcript yet)'), findsOneWidget);

      // Intent area
      expect(find.text('NONE'), findsOneWidget);

      // Mic button
      expect(find.byKey(const Key('mic_button')), findsOneWidget);
    });

    testWidgets('mic button starts and stops listening with injected VoiceController', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      late VoiceController controller;

      await tester.pumpWidget(
        SmritiApp(
          voiceControllerFactory: () {
            controller = VoiceController(
              stt: mockStt,
              tts: mockTts,
              engine: engine,
            );
            return controller;
          },
        ),
      );

      expect(find.text('Idle'), findsOneWidget);

      // Tap mic button to start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      expect(find.text('Listening'), findsOneWidget);
      expect(controller.isListening, isTrue);

      // Tap mic button while listening to stop listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pumpAndSettle();

      expect(controller.isListening, isFalse);
      expect(find.text('Idle'), findsOneWidget);

      // Tap mic button again to start new session
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      expect(controller.isListening, isTrue);

      // Simulate speech input
      mockStt.simulateSpeech('start memory game', isFinal: true);
      await tester.pumpAndSettle();

      // Transcript and recognized intent should update
      expect(find.text('start memory game'), findsOneWidget);
      expect(find.text('START_GAME'), findsOneWidget);
    });

    testWidgets('recognizes all standard intents and updates intent area', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      await tester.pumpWidget(
        SmritiApp(
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      // Test OPEN_MEMORY
      mockStt.simulateSpeech('show my memories', isFinal: true);
      await tester.pumpAndSettle();
      expect(find.text('OPEN_MEMORY'), findsOneWidget);

      // Test SET_REMINDER
      mockStt.simulateSpeech('set a reminder', isFinal: true);
      await tester.pumpAndSettle();
      expect(find.text('SET_REMINDER'), findsOneWidget);

      // Test CALL_CAREGIVER
      mockStt.simulateSpeech('call my caregiver', isFinal: true);
      await tester.pumpAndSettle();
      expect(find.text('CALL_CAREGIVER'), findsOneWidget);

      // Test CHECK_TODAY
      mockStt.simulateSpeech("check today's schedule", isFinal: true);
      await tester.pumpAndSettle();
      expect(find.text('CHECK_TODAY'), findsOneWidget);

      // Test SHOW_PROGRESS
      mockStt.simulateSpeech('show my progress', isFinal: true);
      await tester.pumpAndSettle();
      expect(find.text('SHOW_PROGRESS'), findsOneWidget);
    });

    testWidgets('displays error message when STT fails', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();

      await tester.pumpWidget(
        SmritiApp(
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      // Simulate STT error
      mockStt.simulateError(const SttFailure(
        type: SttFailureType.microphoneUnavailable,
        message: 'Microphone hardware unavailable',
      ));
      await tester.pump();

      expect(find.text('Error'), findsOneWidget);
      expect(find.byKey(const Key('error_area')), findsOneWidget);
    });
  });

  group('Voice → Reminder End-to-End Integration Tests', () {
    final fixedNow = DateTime(2026, 9, 9, 8, 0); // 8:00 AM

    testWidgets('successful path: "remind me to drink water at 10 AM" creates and schedules reminder',
        (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminderService = _FakeReminderService();
      final fakeNotificationService = _FakeNotificationService();

      await tester.pumpWidget(
        SmritiApp(
          reminderService: fakeReminderService,
          notificationService: fakeNotificationService,
          nowProvider: () => fixedNow,
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      // Speak command with title and time
      mockStt.simulateSpeech('remind me to drink water at 10 AM', isFinal: true);
      await tester.pumpAndSettle();

      // Verify intent recognized
      expect(find.text('SET_REMINDER'), findsOneWidget);

      // Verify reminder created in persistence
      final all = await fakeReminderService.getAllReminders();
      expect(all.length, equals(1));
      expect(all.first.title, equals('drink water'));
      expect(all.first.scheduledAt.hour, equals(10));
      expect(all.first.scheduledAt.minute, equals(0));
      expect(all.first.isEnabled, isTrue);

      // Verify notification scheduled
      expect(fakeNotificationService.scheduledIds, contains(all.first.id));

      // Verify UI displays status and draft
      expect(find.text('Reminder created: "drink water"'), findsOneWidget);
      expect(find.byKey(const Key('reminder_draft_area')), findsOneWidget);
    });

    testWidgets('missing time: "remind me to drink water" does not auto-schedule and navigates to RemindersScreen',
        (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminderService = _FakeReminderService();
      final fakeNotificationService = _FakeNotificationService();

      await tester.pumpWidget(
        SmritiApp(
          reminderService: fakeReminderService,
          notificationService: fakeNotificationService,
          nowProvider: () => fixedNow,
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      // Speak command without time
      mockStt.simulateSpeech('remind me to drink water', isFinal: true);
      await tester.pumpAndSettle();

      // Verify intent recognized
      expect(find.text('SET_REMINDER', skipOffstage: false), findsOneWidget);

      // Verify NO reminder scheduled
      final all = await fakeReminderService.getAllReminders();
      expect(all, isEmpty);
      expect(fakeNotificationService.scheduledIds, isEmpty);

      // Verify RemindersScreen was opened for user to pick time
      expect(find.byType(RemindersScreen), findsOneWidget);
    });

    testWidgets('missing title and time: "set a reminder" opens RemindersScreen without scheduling',
        (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminderService = _FakeReminderService();
      final fakeNotificationService = _FakeNotificationService();

      await tester.pumpWidget(
        SmritiApp(
          reminderService: fakeReminderService,
          notificationService: fakeNotificationService,
          nowProvider: () => fixedNow,
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      mockStt.simulateSpeech('set a reminder', isFinal: true);
      await tester.pumpAndSettle();

      // Verify intent recognized
      expect(find.text('SET_REMINDER', skipOffstage: false), findsOneWidget);

      // Verify no reminders created
      final all = await fakeReminderService.getAllReminders();
      expect(all, isEmpty);
      expect(fakeNotificationService.scheduledIds, isEmpty);

      // Verify RemindersScreen was opened
      expect(find.byType(RemindersScreen), findsOneWidget);
    });

    testWidgets('persistence failure sets error message without reporting success', (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminderService = _FakeReminderService()..shouldThrowOnSave = true;
      final fakeNotificationService = _FakeNotificationService();

      await tester.pumpWidget(
        SmritiApp(
          reminderService: fakeReminderService,
          notificationService: fakeNotificationService,
          nowProvider: () => fixedNow,
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      mockStt.simulateSpeech('remind me to drink water at 10 AM', isFinal: true);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to save reminder'), findsOneWidget);
      expect(find.textContaining('Reminder created'), findsNothing);
    });

    testWidgets('notification scheduling failure preserves reminder in storage and reports warning',
        (tester) async {
      final mockStt = MockSttAdapter();
      final mockTts = MockTtsAdapter();
      final engine = IntentEngine();
      final fakeReminderService = _FakeReminderService();
      final fakeNotificationService = _FakeNotificationService()..shouldFailScheduling = true;

      await tester.pumpWidget(
        SmritiApp(
          reminderService: fakeReminderService,
          notificationService: fakeNotificationService,
          nowProvider: () => fixedNow,
          voiceControllerFactory: () => VoiceController(
            stt: mockStt,
            tts: mockTts,
            engine: engine,
          ),
        ),
      );

      // Start listening
      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      mockStt.simulateSpeech('remind me to drink water at 10 AM', isFinal: true);
      await tester.pumpAndSettle();

      // Reminder is still preserved in storage
      final all = await fakeReminderService.getAllReminders();
      expect(all.length, equals(1));
      expect(all.first.title, equals('drink water'));

      // Status indicates notification failed but saved
      expect(find.text('Reminder saved (notification failed)'), findsOneWidget);
    });
  });
}

