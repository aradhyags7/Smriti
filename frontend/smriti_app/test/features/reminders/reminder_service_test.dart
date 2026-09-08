import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReminderService reminderService;
  final baseTime = DateTime.utc(2026, 9, 8, 8, 0, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    reminderService = ReminderService();
    await reminderService.initialize();
  });

  group('ReminderService CRUD & State Operations', () {
    test('createReminder stores and getReminder retrieves a reminder', () async {
      final reminder = ReminderModel(
        id: 'rem-101',
        title: 'Morning Medicine',
        description: 'Take with warm water',
        scheduledAt: baseTime.add(const Duration(hours: 1)),
        recurrence: ReminderRecurrence.daily,
        createdAt: baseTime,
      );

      final created = await reminderService.createReminder(reminder);
      expect(created, equals(reminder));

      final retrieved = await reminderService.getReminder('rem-101');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('rem-101'));
      expect(retrieved.title, equals('Morning Medicine'));
      expect(retrieved.description, equals('Take with warm water'));
      expect(retrieved.recurrence, equals(ReminderRecurrence.daily));
      expect(retrieved.isEnabled, isTrue);
    });

    test('getAllReminders returns all items sorted chronologically', () async {
      final r1 = ReminderModel(
        id: 'r-late',
        title: 'Evening Exercise',
        scheduledAt: baseTime.add(const Duration(hours: 10)),
        createdAt: baseTime,
      );

      final r2 = ReminderModel(
        id: 'r-early',
        title: 'Morning Walk',
        scheduledAt: baseTime.add(const Duration(hours: 1)),
        createdAt: baseTime,
      );

      final r3 = ReminderModel(
        id: 'r-mid',
        title: 'Lunch Pill',
        scheduledAt: baseTime.add(const Duration(hours: 5)),
        createdAt: baseTime,
      );

      await reminderService.createReminder(r1);
      await reminderService.createReminder(r2);
      await reminderService.createReminder(r3);

      final all = await reminderService.getAllReminders();
      expect(all.length, equals(3));
      expect(all[0].id, equals('r-early'));
      expect(all[1].id, equals('r-mid'));
      expect(all[2].id, equals('r-late'));
    });

    test('updateReminder updates existing reminder and returns true', () async {
      final initial = ReminderModel(
        id: 'r-update',
        title: 'Old Title',
        scheduledAt: baseTime,
        createdAt: baseTime,
      );
      await reminderService.createReminder(initial);

      final modified = initial.copyWith(
        title: 'New Title',
        description: 'Added description',
        recurrence: ReminderRecurrence.weekly,
      );

      final success = await reminderService.updateReminder(modified);
      expect(success, isTrue);

      final updated = await reminderService.getReminder('r-update');
      expect(updated!.title, equals('New Title'));
      expect(updated.description, equals('Added description'));
      expect(updated.recurrence, equals(ReminderRecurrence.weekly));
    });

    test('updateReminder returns false for nonexistent reminder', () async {
      final nonExistent = ReminderModel(
        id: 'nonexistent-id',
        title: 'Does not exist',
        scheduledAt: baseTime,
        createdAt: baseTime,
      );

      final success = await reminderService.updateReminder(nonExistent);
      expect(success, isFalse);
    });

    test('deleteReminder removes reminder and returns true', () async {
      final reminder = ReminderModel(
        id: 'r-del',
        title: 'To Delete',
        scheduledAt: baseTime,
        createdAt: baseTime,
      );
      await reminderService.createReminder(reminder);

      final deleted = await reminderService.deleteReminder('r-del');
      expect(deleted, isTrue);

      final check = await reminderService.getReminder('r-del');
      expect(check, isNull);

      final all = await reminderService.getAllReminders();
      expect(all, isEmpty);
    });

    test('deleteReminder returns false for nonexistent reminder', () async {
      final deleted = await reminderService.deleteReminder('does-not-exist');
      expect(deleted, isFalse);
    });

    test('enableReminder and disableReminder toggle state correctly', () async {
      final reminder = ReminderModel(
        id: 'r-toggle',
        title: 'Toggle Test',
        isEnabled: true,
        scheduledAt: baseTime,
        createdAt: baseTime,
      );
      await reminderService.createReminder(reminder);

      final disabledSuccess = await reminderService.disableReminder('r-toggle');
      expect(disabledSuccess, isTrue);
      expect((await reminderService.getReminder('r-toggle'))!.isEnabled, isFalse);

      final enabledSuccess = await reminderService.enableReminder('r-toggle');
      expect(enabledSuccess, isTrue);
      expect((await reminderService.getReminder('r-toggle'))!.isEnabled, isTrue);
    });

    test('enableReminder and disableReminder return false for nonexistent reminder', () async {
      expect(await reminderService.enableReminder('missing'), isFalse);
      expect(await reminderService.disableReminder('missing'), isFalse);
    });

    test('acknowledgeReminder marks acknowledgedAt timestamp', () async {
      final reminder = ReminderModel(
        id: 'r-ack',
        title: 'Acknowledge Test',
        scheduledAt: baseTime,
        createdAt: baseTime,
      );
      await reminderService.createReminder(reminder);

      final ackTime = DateTime.utc(2026, 9, 8, 8, 15, 0);
      final success = await reminderService.acknowledgeReminder('r-ack', acknowledgedAt: ackTime);
      expect(success, isTrue);

      final fetched = await reminderService.getReminder('r-ack');
      expect(fetched!.acknowledgedAt, equals(ackTime));
    });

    test('acknowledgeReminder returns false for nonexistent reminder', () async {
      final success = await reminderService.acknowledgeReminder('missing');
      expect(success, isFalse);
    });

    test('createReminder with duplicate ID safely replaces existing entry without duplicating', () async {
      final r1 = ReminderModel(
        id: 'dup-1',
        title: 'First Version',
        scheduledAt: baseTime,
        createdAt: baseTime,
      );
      final r2 = ReminderModel(
        id: 'dup-1',
        title: 'Second Version',
        scheduledAt: baseTime.add(const Duration(minutes: 30)),
        createdAt: baseTime,
      );

      await reminderService.createReminder(r1);
      await reminderService.createReminder(r2);

      final all = await reminderService.getAllReminders();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Second Version'));
    });

    test('clearAll removes all reminders from persistence', () async {
      await reminderService.createReminder(
        ReminderModel(id: 'c1', title: 'T1', scheduledAt: baseTime, createdAt: baseTime),
      );
      await reminderService.createReminder(
        ReminderModel(id: 'c2', title: 'T2', scheduledAt: baseTime, createdAt: baseTime),
      );

      expect((await reminderService.getAllReminders()).length, equals(2));

      await reminderService.clearAll();
      expect(await reminderService.getAllReminders(), isEmpty);
    });
  });

  group('ReminderService Fault Tolerance & Storage Corruptions', () {
    test('handles empty storage gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ReminderService();
      await service.initialize();

      expect(await service.getAllReminders(), isEmpty);
      expect(await service.getReminder('any-id'), isNull);
    });

    test('handles completely invalid JSON syntax without crashing', () async {
      SharedPreferences.setMockInitialValues({
        ReminderService.storageKey: '{malformed: [json, broken...',
      });

      final service = ReminderService();
      await service.initialize();

      final list = await service.getAllReminders();
      expect(list, isEmpty);
    });

    test('handles non-list JSON payload without crashing', () async {
      SharedPreferences.setMockInitialValues({
        ReminderService.storageKey: '{"single": "object", "not": "a list"}',
      });

      final service = ReminderService();
      await service.initialize();

      final list = await service.getAllReminders();
      expect(list, isEmpty);
    });

    test('filters out corrupted items in a list while preserving valid reminders', () async {
      final rawListString = '''
      [
        {"id": "valid-1", "title": "Valid Reminder", "scheduledAt": "${baseTime.toIso8601String()}", "createdAt": "${baseTime.toIso8601String()}"},
        {"title": "Missing ID", "scheduledAt": "${baseTime.toIso8601String()}", "createdAt": "${baseTime.toIso8601String()}"},
        "not-even-a-map",
        {"id": "bad-date-1", "title": "Bad Date", "scheduledAt": "invalid", "createdAt": "${baseTime.toIso8601String()}"}
      ]
      ''';

      SharedPreferences.setMockInitialValues({
        ReminderService.storageKey: rawListString,
      });

      final service = ReminderService();
      await service.initialize();

      final reminders = await service.getAllReminders();
      expect(reminders.length, equals(1));
      expect(reminders.first.id, equals('valid-1'));
      expect(reminders.first.title, equals('Valid Reminder'));
    });

    test('handles empty or whitespace ID lookups safely', () async {
      expect(await reminderService.getReminder(''), isNull);
      expect(await reminderService.getReminder('   '), isNull);
      expect(await reminderService.deleteReminder(''), isFalse);
      expect(await reminderService.enableReminder(''), isFalse);
      expect(await reminderService.disableReminder(''), isFalse);
      expect(await reminderService.acknowledgeReminder(''), isFalse);
    });
  });
}
