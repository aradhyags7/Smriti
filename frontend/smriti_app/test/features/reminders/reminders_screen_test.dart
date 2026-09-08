import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/reminder_notification_service.dart';
import 'package:smriti_app/features/reminders/reminder_service.dart';
import 'package:smriti_app/features/reminders/reminders_screen.dart';

/// In-memory fake reminder service for isolated widget testing.
class FakeReminderService implements IReminderService {
  final Map<String, ReminderModel> _storage = {};
  bool shouldThrowOnLoad = false;
  bool shouldThrowOnSave = false;

  @override
  Future<void> initialize() async {
    if (shouldThrowOnLoad) throw Exception('Simulated load error');
  }

  @override
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    if (shouldThrowOnSave) throw Exception('Simulated create error');
    _storage[reminder.id] = reminder;
    return reminder;
  }

  @override
  Future<ReminderModel?> getReminder(String id) async => _storage[id];

  @override
  Future<List<ReminderModel>> getAllReminders() async {
    if (shouldThrowOnLoad) throw Exception('Simulated get error');
    final list = _storage.values.toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  @override
  Future<bool> updateReminder(ReminderModel reminder) async {
    if (shouldThrowOnSave) throw Exception('Simulated update error');
    if (!_storage.containsKey(reminder.id)) return false;
    _storage[reminder.id] = reminder;
    return true;
  }

  @override
  Future<bool> deleteReminder(String id) async {
    if (!_storage.containsKey(id)) return false;
    _storage.remove(id);
    return true;
  }

  @override
  Future<bool> enableReminder(String id) async {
    final r = _storage[id];
    if (r == null) return false;
    _storage[id] = r.copyWith(isEnabled: true);
    return true;
  }

  @override
  Future<bool> disableReminder(String id) async {
    final r = _storage[id];
    if (r == null) return false;
    _storage[id] = r.copyWith(isEnabled: false);
    return true;
  }

  @override
  Future<bool> acknowledgeReminder(String id, {DateTime? acknowledgedAt}) async {
    final r = _storage[id];
    if (r == null) return false;
    _storage[id] = r.copyWith(acknowledgedAt: acknowledgedAt ?? DateTime.now());
    return true;
  }

  @override
  Future<void> clearAll() async => _storage.clear();
}

/// In-memory fake notification service avoiding platform dependencies in tests.
class FakeReminderNotificationService implements IReminderNotificationService {
  final List<String> scheduledIds = [];
  final List<String> cancelledIds = [];
  bool shouldFailScheduling = false;
  bool shouldThrowScheduling = false;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> scheduleReminder(ReminderModel reminder) async {
    if (shouldThrowScheduling) throw Exception('Simulated notification crash');
    if (shouldFailScheduling) return false;
    scheduledIds.add(reminder.id);
    return true;
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    cancelledIds.add(reminderId);
    scheduledIds.remove(reminderId);
  }

  @override
  Future<void> cancelAllReminders() async {
    cancelledIds.addAll(scheduledIds);
    scheduledIds.clear();
  }

  @override
  Future<bool> rescheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder.id);
    return scheduleReminder(reminder);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReminderService fakeReminderService;
  late FakeReminderNotificationService fakeNotificationService;

  final fixedTime = DateTime.utc(2026, 9, 8, 8, 30, 0);

  setUp(() {
    fakeReminderService = FakeReminderService();
    fakeNotificationService = FakeReminderNotificationService();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: RemindersScreen(
        reminderService: fakeReminderService,
        notificationService: fakeNotificationService,
      ),
    );
  }

  group('RemindersScreen Widget Tests', () {
    testWidgets('renders header and empty state when no reminders exist', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Your gentle daily routine'), findsOneWidget);
      expect(find.text('0 of 0 Done'), findsOneWidget);
      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(find.text('Add a reminder for medicines, hydration, or your daily routine.'), findsOneWidget);
      expect(find.byKey(const Key('empty_add_reminder_button')), findsOneWidget);
    });

    testWidgets('renders reminder cards with title, scheduled time, and recurrence', (tester) async {
      final r1 = ReminderModel(
        id: 'r1',
        title: 'Blood Pressure Pill',
        description: 'Take 1 tablet after food',
        scheduledAt: fixedTime,
        recurrence: ReminderRecurrence.daily,
        isEnabled: true,
        createdAt: fixedTime,
      );
      final r2 = ReminderModel(
        id: 'r2',
        title: 'Drink 2 glasses of water',
        scheduledAt: fixedTime.add(const Duration(hours: 2)),
        recurrence: ReminderRecurrence.none,
        isEnabled: false,
        createdAt: fixedTime,
      );

      await fakeReminderService.createReminder(r1);
      await fakeReminderService.createReminder(r2);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Blood Pressure Pill'), findsOneWidget);
      expect(find.text('Take 1 tablet after food'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('Drink 2 glasses of water'), findsOneWidget);
      expect(find.text('One-time'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);

      expect(find.text('0 of 2 Done'), findsOneWidget);
    });

    testWidgets('acknowledging a reminder marks it as Done and updates progress badge', (tester) async {
      final r = ReminderModel(
        id: 'r-done',
        title: 'Morning Walk',
        scheduledAt: fixedTime,
        recurrence: ReminderRecurrence.daily,
        isEnabled: true,
        createdAt: fixedTime,
      );
      await fakeReminderService.createReminder(r);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0 of 1 Done'), findsOneWidget);
      expect(find.byKey(const Key('done_r-done')), findsOneWidget);

      // Tap Done
      await tester.tap(find.byKey(const Key('done_r-done')));
      await tester.pumpAndSettle();

      // Should now show Completed / Done
      expect(find.text('1 of 1 Done'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Marked "Morning Walk" as done.'), findsOneWidget);
    });

    testWidgets('validation prevents saving reminder with empty title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open Add Reminder bottom sheet
      await tester.tap(find.byKey(const Key('add_reminder_top_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_reminder_button')), findsOneWidget);

      // Attempt to save without entering title
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a reminder title.'), findsOneWidget);
      expect(fakeReminderService._storage, isEmpty);
    });

    testWidgets('creates a new reminder and schedules notification', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open form
      await tester.tap(find.byKey(const Key('add_reminder_top_button')));
      await tester.pumpAndSettle();

      // Fill title & description
      await tester.enterText(find.byKey(const Key('reminder_title_field')), 'Take Calcium Supplement');
      await tester.enterText(find.byKey(const Key('reminder_desc_field')), 'With milk at 9 PM');
      await tester.pumpAndSettle();

      // Select Daily recurrence
      await tester.tap(find.byKey(const Key('recurrence_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Every day (Daily)').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      // Verify created in service and UI
      expect(find.text('Take Calcium Supplement'), findsOneWidget);
      expect(find.text('With milk at 9 PM'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(fakeReminderService._storage.length, equals(1));
      expect(fakeNotificationService.scheduledIds.length, equals(1));
    });

    testWidgets('edits existing reminder title and recurrence', (tester) async {
      final r = ReminderModel(
        id: 'r-edit',
        title: 'Original Reminder',
        scheduledAt: fixedTime,
        recurrence: ReminderRecurrence.none,
        createdAt: fixedTime,
      );
      await fakeReminderService.createReminder(r);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byKey(const Key('menu_r-edit')));
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Reminder'), findsOneWidget);

      // Edit title
      await tester.enterText(find.byKey(const Key('reminder_title_field')), 'Updated Medicine Routine');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      expect(find.text('Updated Medicine Routine'), findsOneWidget);
      expect(fakeReminderService._storage['r-edit']!.title, equals('Updated Medicine Routine'));
    });

    testWidgets('toggles reminder active and paused state', (tester) async {
      final r = ReminderModel(
        id: 'r-toggle',
        title: 'Toggle Routine',
        scheduledAt: fixedTime,
        isEnabled: true,
        createdAt: fixedTime,
      );
      await fakeReminderService.createReminder(r);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);

      // Open menu and tap Pause
      await tester.tap(find.byKey(const Key('menu_r-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();

      expect(find.text('Paused'), findsOneWidget);
      expect(fakeReminderService._storage['r-toggle']!.isEnabled, isFalse);

      // Open menu and tap Resume
      await tester.tap(find.byKey(const Key('menu_r-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(fakeReminderService._storage['r-toggle']!.isEnabled, isTrue);
    });

    testWidgets('delete requires confirmation dialog and deletes on confirm', (tester) async {
      final r = ReminderModel(
        id: 'r-delete',
        title: 'Delete Me',
        scheduledAt: fixedTime,
        createdAt: fixedTime,
      );
      await fakeReminderService.createReminder(r);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open menu and tap Delete
      await tester.tap(find.byKey(const Key('menu_r-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Check confirmation dialog
      expect(find.text('Delete Reminder'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Delete Me"?'), findsOneWidget);

      // Tap Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);
      expect(fakeReminderService._storage.containsKey('r-delete'), isTrue);

      // Open menu and tap Delete again
      await tester.tap(find.byKey(const Key('menu_r-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete to confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(fakeReminderService._storage.isEmpty, isTrue);
      expect(fakeNotificationService.cancelledIds, contains('r-delete'));
    });

    testWidgets('shows non-blocking SnackBar when notification scheduling fails', (tester) async {
      fakeNotificationService.shouldFailScheduling = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add reminder
      await tester.tap(find.byKey(const Key('add_reminder_top_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reminder_title_field')), 'Reminder Without Notification');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      // Reminder is still saved
      expect(find.text('Reminder Without Notification'), findsOneWidget);
      expect(fakeReminderService._storage.length, equals(1));

      // Warning snackbar is displayed
      expect(
        find.text('Reminder saved, but notification could not be scheduled.'),
        findsOneWidget,
      );
    });

    testWidgets('UI does not crash when notification service throws an exception', (tester) async {
      fakeNotificationService.shouldThrowScheduling = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_reminder_top_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reminder_title_field')), 'Resilient Reminder');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      // Reminder saved safely without crash
      expect(find.text('Resilient Reminder'), findsOneWidget);
      expect(fakeReminderService._storage.length, equals(1));
    });

    testWidgets('handles persistence failure gracefully with user feedback', (tester) async {
      fakeReminderService.shouldThrowOnLoad = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Could not load reminders. Please try again.'), findsOneWidget);
    });
  });
}
