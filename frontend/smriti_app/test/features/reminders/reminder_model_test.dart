import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';

void main() {
  group('ReminderModel Domain & Serialization Tests', () {
    final now = DateTime.utc(2026, 9, 8, 10, 30, 0);
    final scheduled = DateTime.utc(2026, 9, 8, 14, 0, 0);

    test('instantiates with correct immutable properties', () {
      final reminder = ReminderModel(
        id: 'rem-1',
        title: 'Take evening medication',
        description: 'Take 1 pill after dinner with water',
        scheduledAt: scheduled,
        recurrence: ReminderRecurrence.daily,
        isEnabled: true,
        createdAt: now,
      );

      expect(reminder.id, equals('rem-1'));
      expect(reminder.title, equals('Take evening medication'));
      expect(reminder.description, equals('Take 1 pill after dinner with water'));
      expect(reminder.scheduledAt, equals(scheduled));
      expect(reminder.recurrence, equals(ReminderRecurrence.daily));
      expect(reminder.isEnabled, isTrue);
      expect(reminder.createdAt, equals(now));
      expect(reminder.acknowledgedAt, isNull);
      expect(reminder.lastTriggeredAt, isNull);
    });

    test('serializes to JSON using deterministic ISO-8601 strings', () {
      final ackTime = DateTime.utc(2026, 9, 8, 14, 5, 0);
      final trigTime = DateTime.utc(2026, 9, 8, 14, 0, 10);

      final reminder = ReminderModel(
        id: 'rem-2',
        title: 'Doctor appointment',
        description: 'Visit clinic room 302',
        scheduledAt: scheduled,
        recurrence: ReminderRecurrence.weekly,
        isEnabled: false,
        createdAt: now,
        acknowledgedAt: ackTime,
        lastTriggeredAt: trigTime,
      );

      final json = reminder.toJson();

      expect(json['id'], equals('rem-2'));
      expect(json['title'], equals('Doctor appointment'));
      expect(json['description'], equals('Visit clinic room 302'));
      expect(json['scheduledAt'], equals('2026-09-08T14:00:00.000Z'));
      expect(json['recurrence'], equals('weekly'));
      expect(json['isEnabled'], isFalse);
      expect(json['createdAt'], equals('2026-09-08T10:30:00.000Z'));
      expect(json['acknowledgedAt'], equals('2026-09-08T14:05:00.000Z'));
      expect(json['lastTriggeredAt'], equals('2026-09-08T14:00:10.000Z'));
    });

    test('deserializes from JSON correctly (round-trip equality)', () {
      final reminder = ReminderModel(
        id: 'rem-3',
        title: 'Drink water',
        scheduledAt: scheduled,
        recurrence: ReminderRecurrence.none,
        isEnabled: true,
        createdAt: now,
      );

      final json = reminder.toJson();
      final parsed = ReminderModel.fromJson(json);

      expect(parsed, equals(reminder));
      expect(parsed.id, equals('rem-3'));
      expect(parsed.title, equals('Drink water'));
      expect(parsed.description, isNull);
      expect(parsed.recurrence, equals(ReminderRecurrence.none));
      expect(parsed.isEnabled, isTrue);
    });

    test('deserializes with safe defaults when optional fields are omitted', () {
      final minimalJson = {
        'id': 'rem-min',
        'title': 'Walk in park',
        'scheduledAt': scheduled.toIso8601String(),
        'createdAt': now.toIso8601String(),
      };

      final parsed = ReminderModel.fromJson(minimalJson);

      expect(parsed.id, equals('rem-min'));
      expect(parsed.title, equals('Walk in park'));
      expect(parsed.description, isNull);
      expect(parsed.recurrence, equals(ReminderRecurrence.none));
      expect(parsed.isEnabled, isTrue);
      expect(parsed.acknowledgedAt, isNull);
      expect(parsed.lastTriggeredAt, isNull);
    });

    test('throws FormatException on missing required fields', () {
      expect(
        () => ReminderModel.fromJson({'title': 'No ID'}),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ReminderModel.fromJson({'id': '123'}),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ReminderModel.fromJson({
          'id': '123',
          'title': 'Missing Scheduled Time',
          'createdAt': now.toIso8601String(),
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ReminderModel.fromJson({
          'id': '123',
          'title': 'Missing Created Time',
          'scheduledAt': scheduled.toIso8601String(),
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('copyWith properly updates specific fields and clears nullable values', () {
      final reminder = ReminderModel(
        id: 'rem-copy',
        title: 'Original Title',
        description: 'Original Desc',
        scheduledAt: scheduled,
        recurrence: ReminderRecurrence.none,
        createdAt: now,
      );

      final updated = reminder.copyWith(
        title: 'New Title',
        recurrence: ReminderRecurrence.daily,
        isEnabled: false,
      );

      expect(updated.id, equals('rem-copy'));
      expect(updated.title, equals('New Title'));
      expect(updated.description, equals('Original Desc'));
      expect(updated.recurrence, equals(ReminderRecurrence.daily));
      expect(updated.isEnabled, isFalse);

      final cleared = updated.copyWith(clearDescription: true);
      expect(cleared.description, isNull);
    });

    test('value equality and hashCode behavior', () {
      final r1 = ReminderModel(
        id: 'rem-eq',
        title: 'Test',
        scheduledAt: scheduled,
        createdAt: now,
      );

      final r2 = ReminderModel(
        id: 'rem-eq',
        title: 'Test',
        scheduledAt: scheduled,
        createdAt: now,
      );

      final r3 = ReminderModel(
        id: 'rem-different',
        title: 'Test',
        scheduledAt: scheduled,
        createdAt: now,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('ReminderRecurrence enum serialization and safe fallback', () {
      expect(ReminderRecurrence.none.toJson(), equals('none'));
      expect(ReminderRecurrence.daily.toJson(), equals('daily'));
      expect(ReminderRecurrence.weekly.toJson(), equals('weekly'));

      expect(ReminderRecurrence.fromJson('daily'), equals(ReminderRecurrence.daily));
      expect(ReminderRecurrence.fromJson('WEEKLY'), equals(ReminderRecurrence.weekly));
      expect(ReminderRecurrence.fromJson('none'), equals(ReminderRecurrence.none));
      expect(ReminderRecurrence.fromJson('unknown_interval'), equals(ReminderRecurrence.none));
      expect(ReminderRecurrence.fromJson(null), equals(ReminderRecurrence.none));
    });
  });
}
