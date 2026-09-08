import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/reminder_notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// In-memory mock scheduler capturing all notification calls for verification.
class MockNotificationScheduler implements INotificationScheduler {
  bool initializeSuccess = true;
  bool requestPermissionSuccess = true;
  bool shouldThrowOnSchedule = false;

  final List<ScheduledNotificationRecord> scheduledRecords = [];
  final List<int> cancelledIds = [];
  bool cancelAllCalled = false;
  InitializationSettings? lastInitSettings;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    lastInitSettings = initializationSettings;
    return initializeSuccess;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    if (shouldThrowOnSchedule) {
      throw Exception('Simulated scheduling platform error');
    }
    scheduledRecords.add(ScheduledNotificationRecord(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    ));
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
    scheduledRecords.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
    cancelledIds.addAll(scheduledRecords.map((r) => r.id));
    scheduledRecords.clear();
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    return requestPermissionSuccess;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final testLocation = tz.getLocation('UTC');
  final simulatedNow = DateTime.utc(2026, 9, 8, 12, 0, 0);

  late MockNotificationScheduler mockScheduler;
  late ReminderNotificationService notificationService;

  setUp(() {
    mockScheduler = MockNotificationScheduler();
    notificationService = ReminderNotificationService(
      scheduler: mockScheduler,
      clock: () => simulatedNow,
      location: testLocation,
    );
  });

  group('ReminderNotificationService Initialization', () {
    test('initializes successfully with Android and iOS settings', () async {
      final success = await notificationService.initialize();
      expect(success, isTrue);
      expect(notificationService.isInitialized, isTrue);
      expect(mockScheduler.lastInitSettings, isNotNull);
      expect(mockScheduler.lastInitSettings!.android, isNotNull);
      expect(mockScheduler.lastInitSettings!.iOS, isNotNull);
    });

    test('handles initialization failure gracefully without throwing', () async {
      mockScheduler.initializeSuccess = false;
      final service = ReminderNotificationService(
        scheduler: mockScheduler,
        clock: () => simulatedNow,
        location: testLocation,
      );

      final success = await service.initialize();
      expect(success, isFalse);
      expect(service.isInitialized, isFalse);
    });

    test('handles permission denial gracefully during initialization', () async {
      mockScheduler.requestPermissionSuccess = false;
      final success = await notificationService.initialize();
      expect(success, isTrue); // Plugin init succeeds even if permission is denied
    });
  });

  group('Deterministic Notification IDs', () {
    test('same reminder ID always produces the exact same integer ID', () {
      const id1 = 'rem-medicine-morning';
      const id2 = 'rem-walk-evening';

      final notifId1a = ReminderNotificationService.deterministicNotificationId(id1);
      final notifId1b = ReminderNotificationService.deterministicNotificationId(id1);
      final notifId2 = ReminderNotificationService.deterministicNotificationId(id2);

      expect(notifId1a, equals(notifId1b));
      expect(notifId1a, isNot(equals(notifId2)));
      expect(notifId1a, isPositive);
      expect(notifId2, isPositive);
    });

    test('empty reminder ID returns 0 safely', () {
      expect(ReminderNotificationService.deterministicNotificationId(''), equals(0));
    });
  });

  group('Scheduling Reminders by Recurrence', () {
    test('schedules future one-time reminder with exact time and no recurrence component', () async {
      final futureTime = simulatedNow.add(const Duration(hours: 2));
      final reminder = ReminderModel(
        id: 'rem-future-1',
        title: 'Afternoon Pill',
        description: 'Take with glass of water',
        scheduledAt: futureTime,
        recurrence: ReminderRecurrence.none,
        createdAt: simulatedNow,
      );

      final scheduled = await notificationService.scheduleReminder(reminder);
      expect(scheduled, isTrue);
      expect(mockScheduler.scheduledRecords.length, equals(1));

      final record = mockScheduler.scheduledRecords.first;
      expect(record.id, equals(ReminderNotificationService.deterministicNotificationId('rem-future-1')));
      expect(record.title, equals('Afternoon Pill'));
      expect(record.body, equals('Take with glass of water'));
      expect(record.matchDateTimeComponents, isNull);
      expect(record.payload, equals('rem-future-1'));
    });

    test('skips past one-time reminder and cancels existing notification safely', () async {
      final pastTime = simulatedNow.subtract(const Duration(hours: 1));
      final reminder = ReminderModel(
        id: 'rem-past-1',
        title: 'Missed Breakfast Pill',
        scheduledAt: pastTime,
        recurrence: ReminderRecurrence.none,
        createdAt: simulatedNow.subtract(const Duration(hours: 2)),
      );

      final scheduled = await notificationService.scheduleReminder(reminder);
      expect(scheduled, isFalse);
      expect(mockScheduler.scheduledRecords, isEmpty);
      expect(mockScheduler.cancelledIds, contains(ReminderNotificationService.deterministicNotificationId('rem-past-1')));
    });

    test('schedules daily reminder advancing past time to next occurrence', () async {
      // Scheduled for 8:00 AM today, but current time is 12:00 PM
      final pastTimeToday = DateTime.utc(2026, 9, 8, 8, 0, 0);
      final reminder = ReminderModel(
        id: 'rem-daily-1',
        title: 'Daily Morning Routine',
        scheduledAt: pastTimeToday,
        recurrence: ReminderRecurrence.daily,
        createdAt: simulatedNow,
      );

      final scheduled = await notificationService.scheduleReminder(reminder);
      expect(scheduled, isTrue);
      expect(mockScheduler.scheduledRecords.length, equals(1));

      final record = mockScheduler.scheduledRecords.first;
      expect(record.matchDateTimeComponents, equals(DateTimeComponents.time));
      // Should have advanced to tomorrow 8:00 AM
      final expectedNext = tz.TZDateTime.utc(2026, 9, 9, 8, 0, 0);
      expect(record.scheduledDate, equals(expectedNext));
    });

    test('schedules weekly reminder advancing past time to next week occurrence', () async {
      // Scheduled for 2 days ago
      final pastTimeDaysAgo = simulatedNow.subtract(const Duration(days: 2));
      final reminder = ReminderModel(
        id: 'rem-weekly-1',
        title: 'Weekly Doctor Call',
        scheduledAt: pastTimeDaysAgo,
        recurrence: ReminderRecurrence.weekly,
        createdAt: simulatedNow,
      );

      final scheduled = await notificationService.scheduleReminder(reminder);
      expect(scheduled, isTrue);
      expect(mockScheduler.scheduledRecords.length, equals(1));

      final record = mockScheduler.scheduledRecords.first;
      expect(record.matchDateTimeComponents, equals(DateTimeComponents.dayOfWeekAndTime));
      // Should have advanced by 7 days
      final expectedNext = tz.TZDateTime.from(pastTimeDaysAgo.add(const Duration(days: 7)), testLocation);
      expect(record.scheduledDate, equals(expectedNext));
    });

    test('disabled reminder cancels existing notification and is never scheduled', () async {
      final futureTime = simulatedNow.add(const Duration(hours: 3));
      final disabledReminder = ReminderModel(
        id: 'rem-disabled-1',
        title: 'Paused Medication',
        scheduledAt: futureTime,
        isEnabled: false,
        createdAt: simulatedNow,
      );

      final scheduled = await notificationService.scheduleReminder(disabledReminder);
      expect(scheduled, isFalse);
      expect(mockScheduler.scheduledRecords, isEmpty);
      expect(
        mockScheduler.cancelledIds,
        contains(ReminderNotificationService.deterministicNotificationId('rem-disabled-1')),
      );
    });

    test('uses fallback notification body when description is null or whitespace', () async {
      final reminder = ReminderModel(
        id: 'rem-nodesc',
        title: 'Drink Water',
        description: '   ',
        scheduledAt: simulatedNow.add(const Duration(hours: 1)),
        createdAt: simulatedNow,
      );

      await notificationService.scheduleReminder(reminder);
      expect(mockScheduler.scheduledRecords.first.body, equals(ReminderNotificationService.defaultNotificationBody));
    });
  });

  group('Cancellation & Rescheduling', () {
    test('cancelReminder cancels exactly the matching notification ID', () async {
      final r1 = ReminderModel(
        id: 'rem-c1',
        title: 'R1',
        scheduledAt: simulatedNow.add(const Duration(hours: 1)),
        createdAt: simulatedNow,
      );
      final r2 = ReminderModel(
        id: 'rem-c2',
        title: 'R2',
        scheduledAt: simulatedNow.add(const Duration(hours: 2)),
        createdAt: simulatedNow,
      );

      await notificationService.scheduleReminder(r1);
      await notificationService.scheduleReminder(r2);
      expect(mockScheduler.scheduledRecords.length, equals(2));

      await notificationService.cancelReminder('rem-c1');
      expect(mockScheduler.scheduledRecords.length, equals(1));
      expect(mockScheduler.scheduledRecords.first.payload, equals('rem-c2'));
    });

    test('cancelReminder on nonexistent or empty reminder ID is safe no-op', () async {
      await notificationService.cancelReminder('nonexistent-id');
      await notificationService.cancelReminder('');
      expect(mockScheduler.cancelledIds, contains(ReminderNotificationService.deterministicNotificationId('nonexistent-id')));
    });

    test('cancelAllReminders cancels all scheduled records', () async {
      await notificationService.scheduleReminder(
        ReminderModel(id: 'r-all-1', title: 'T1', scheduledAt: simulatedNow.add(const Duration(hours: 1)), createdAt: simulatedNow),
      );
      await notificationService.scheduleReminder(
        ReminderModel(id: 'r-all-2', title: 'T2', scheduledAt: simulatedNow.add(const Duration(hours: 2)), createdAt: simulatedNow),
      );

      await notificationService.cancelAllReminders();
      expect(mockScheduler.cancelAllCalled, isTrue);
      expect(mockScheduler.scheduledRecords, isEmpty);
    });

    test('rescheduleReminder cancels previous notification and schedules updated reminder', () async {
      final initial = ReminderModel(
        id: 'rem-resched',
        title: 'Initial Time',
        scheduledAt: simulatedNow.add(const Duration(hours: 1)),
        createdAt: simulatedNow,
      );
      await notificationService.scheduleReminder(initial);

      final updated = initial.copyWith(
        title: 'Updated Time',
        scheduledAt: simulatedNow.add(const Duration(hours: 5)),
      );

      final success = await notificationService.rescheduleReminder(updated);
      expect(success, isTrue);
      expect(mockScheduler.scheduledRecords.length, equals(1));
      expect(mockScheduler.scheduledRecords.first.title, equals('Updated Time'));
    });

    test('handles platform scheduling error gracefully without crashing', () async {
      mockScheduler.shouldThrowOnSchedule = true;

      final reminder = ReminderModel(
        id: 'rem-err',
        title: 'Will Throw',
        scheduledAt: simulatedNow.add(const Duration(hours: 1)),
        createdAt: simulatedNow,
      );

      final success = await notificationService.scheduleReminder(reminder);
      expect(success, isFalse);
    });
  });
}
