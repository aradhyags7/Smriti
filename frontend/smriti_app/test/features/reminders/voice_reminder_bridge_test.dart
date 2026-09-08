import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/reminders/reminder_model.dart';
import 'package:smriti_app/features/reminders/voice_reminder_bridge.dart';

void main() {
  group('VoiceReminderBridge Unit Tests', () {
    // Fixed reference time for deterministic testing:
    // Wednesday, 2026-09-09 at 14:00 (2:00 PM)
    final fixedNow = DateTime(2026, 9, 9, 14, 0);

    group('TITLE EXTRACTION', () {
      test('extracts "drink water" from "remind me to drink water"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to drink water',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('drink water'));
      });

      test('extracts "take medicine" from "remind me to take medicine at 9 pm"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to take medicine at 9 pm',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('take medicine'));
      });

      test('extracts "calling the doctor" from "set a reminder for calling the doctor"', () {
        final draft = VoiceReminderBridge.parse(
          'set a reminder for calling the doctor',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('calling the doctor'));
      });

      test('extracts "calling doctor" from "set a reminder for calling doctor at 5 pm"', () {
        final draft = VoiceReminderBridge.parse(
          'set a reminder for calling doctor at 5 pm',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('calling doctor'));
      });

      test('extracts "calling the doctor" from "Set a reminder for calling the doctor at 5 PM every week"', () {
        final draft = VoiceReminderBridge.parse(
          'Set a reminder for calling the doctor at 5 PM every week',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('calling the doctor'));
      });
    });

    group('TIME EXTRACTION', () {
      test('extracts 8 AM (future day when now is 2 PM)', () {
        // fixedNow is 2:00 PM, so 8:00 AM today is in the past -> rolls to tomorrow 8:00 AM
        final draft = VoiceReminderBridge.parse(
          'remind me to take medicine at 8 AM',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
        expect(draft.scheduledAt!.minute, equals(0));
        expect(draft.scheduledAt!.day, equals(10)); // Tomorrow
      });

      test('extracts 8 PM (today when now is 2 PM)', () {
        // fixedNow is 2:00 PM, 8:00 PM today is in the future -> stays today 8:00 PM
        final draft = VoiceReminderBridge.parse(
          'remind me to walk at 8 PM',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(20));
        expect(draft.scheduledAt!.minute, equals(0));
        expect(draft.scheduledAt!.day, equals(9)); // Today
      });

      test('extracts 10:30 AM', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to check blood pressure at 10:30 AM',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(10));
        expect(draft.scheduledAt!.minute, equals(30));
      });

      test('extracts 10:30 PM', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to sleep at 10:30 PM',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(22));
        expect(draft.scheduledAt!.minute, equals(30));
      });

      test('handles "tomorrow at 8 PM"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to call doctor tomorrow at 8 PM',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.year, equals(2026));
        expect(draft.scheduledAt!.month, equals(9));
        expect(draft.scheduledAt!.day, equals(10)); // Tomorrow
        expect(draft.scheduledAt!.hour, equals(20));
        expect(draft.scheduledAt!.minute, equals(0));
      });

      test('rolls past today time to next day', () {
        // Current time: 10:00 PM (22:00)
        final nightTime = DateTime(2026, 9, 9, 22, 0);
        final draft = VoiceReminderBridge.parse(
          'remind me at 8 PM',
          nowProvider: () => nightTime,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.day, equals(10)); // Tomorrow
        expect(draft.scheduledAt!.hour, equals(20));
      });

      test('extracts "8 in the morning" as 8:00 AM', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to stretch 8 in the morning',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
        expect(draft.scheduledAt!.minute, equals(0));
      });

      test('extracts "8 in the evening" as 8:00 PM (20:00)', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to eat dinner 8 in the evening',
          nowProvider: () => fixedNow,
        );
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(20));
        expect(draft.scheduledAt!.minute, equals(0));
      });
    });

    group('RECURRENCE EXTRACTION', () {
      test('extracts daily from "every day"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to take medicine at 9 PM every day',
          nowProvider: () => fixedNow,
        );
        expect(draft.recurrence, equals(ReminderRecurrence.daily));
      });

      test('extracts daily from "daily"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to take medicine daily at 9 PM',
          nowProvider: () => fixedNow,
        );
        expect(draft.recurrence, equals(ReminderRecurrence.daily));
      });

      test('extracts weekly from "every week"', () {
        final draft = VoiceReminderBridge.parse(
          'set a reminder for calling the doctor at 5 PM every week',
          nowProvider: () => fixedNow,
        );
        expect(draft.recurrence, equals(ReminderRecurrence.weekly));
      });

      test('extracts weekly from "weekly"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me weekly at 10 AM to call daughter',
          nowProvider: () => fixedNow,
        );
        expect(draft.recurrence, equals(ReminderRecurrence.weekly));
      });

      test('defaults to recurrence none when unspecified', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to drink water at 10 AM',
          nowProvider: () => fixedNow,
        );
        expect(draft.recurrence, equals(ReminderRecurrence.none));
      });
    });

    group('MISSING DATA HANDLING', () {
      test('no title when command is just "set a reminder"', () {
        final draft = VoiceReminderBridge.parse(
          'set a reminder',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, isNull);
        expect(draft.isTitleMissing, isTrue);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.hasEnoughInformation, isFalse);
      });

      test('no time when command is "remind me to drink water"', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to drink water',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('drink water'));
        expect(draft.scheduledAt, isNull);
        expect(draft.isTitleMissing, isFalse);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.hasEnoughInformation, isFalse);
      });

      test('handles empty or whitespace-only transcript', () {
        final draft = VoiceReminderBridge.parse(
          '   ',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, isNull);
        expect(draft.scheduledAt, isNull);
        expect(draft.hasEnoughInformation, isFalse);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.isTitleMissing, isTrue);
      });

      test('leaves ambiguous time "at 8" unresolved to prevent false scheduling', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to drink water at 8',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('drink water'));
        expect(draft.scheduledAt, isNull);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.hasEnoughInformation, isFalse);
      });
    });

    group('MODEL CREATION', () {
      test('creates a valid ReminderModel when all required data is present', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to take medicine at 9 PM every day',
          nowProvider: () => fixedNow,
        );
        expect(draft.hasEnoughInformation, isTrue);

        final model = draft.toReminderModel(nowProvider: () => fixedNow);
        expect(model, isNotNull);
        expect(model!.id, isNotEmpty);
        // Valid UUID v4 check: 36 chars with dashes
        expect(model.id.length, equals(36));
        expect(model.title, equals('take medicine'));
        expect(model.scheduledAt.hour, equals(21));
        expect(model.recurrence, equals(ReminderRecurrence.daily));
        expect(model.isEnabled, isTrue);
        expect(model.createdAt, equals(fixedNow));
      });

      test('returns null when attempting to build ReminderModel from incomplete draft', () {
        final draft = VoiceReminderBridge.parse(
          'remind me to drink water',
          nowProvider: () => fixedNow,
        );
        expect(draft.hasEnoughInformation, isFalse);

        final model = draft.toReminderModel(nowProvider: () => fixedNow);
        expect(model, isNull);
      });
    });

    group('LANGUAGE SUPPORT (Hindi & Bengali)', () {
      test('Hindi: extracts title and time from "मुझे सुबह 8 बजे पानी पीने की याद दिलाओ"', () {
        final draft = VoiceReminderBridge.parse(
          'मुझे सुबह 8 बजे पानी पीने की याद दिलाओ',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('पानी पीने'));
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
        expect(draft.hasEnoughInformation, isTrue);
      });

      test('Hindi: title only from "मुझे पानी पीने की याद दिलाओ" requires time selection', () {
        final draft = VoiceReminderBridge.parse(
          'मुझे पानी पीने की याद दिलाओ',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('पानी पीने'));
        expect(draft.scheduledAt, isNull);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.hasEnoughInformation, isFalse);
      });

      test('Hindi: parses Devanagari numerals "मुझे सुबह ८ बजे पानी पीने की याद दिलाओ"', () {
        final draft = VoiceReminderBridge.parse(
          'मुझे सुबह ८ बजे पानी पीने की याद दिलाओ',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('पानी पीने'));
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
        expect(draft.hasEnoughInformation, isTrue);
      });

      test('Bengali: extracts title and time from "আমাকে সকাল ৮টায় জল খাওয়ার কথা মনে করিয়ে দাও"', () {
        final draft = VoiceReminderBridge.parse(
          'আমাকে সকাল ৮টায় জল খাওয়ার কথা মনে করিয়ে দাও',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('জল খাওয়ার'));
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
        expect(draft.hasEnoughInformation, isTrue);
      });

      test('Bengali: title only from "আমাকে জল খাওয়ার কথা মনে করিয়ে দাও" requires time selection', () {
        final draft = VoiceReminderBridge.parse(
          'আমাকে জল খাওয়ার কথা মনে করিয়ে দাও',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('জল খাওয়ার'));
        expect(draft.scheduledAt, isNull);
        expect(draft.isTimeMissing, isTrue);
        expect(draft.hasEnoughInformation, isFalse);
      });

      test('Bengali: parses Bengali numerals "সকাল ৮টা"', () {
        final draft = VoiceReminderBridge.parse(
          'আমাকে সকাল ৮টা ওষুধ খাওয়ার কথা মনে করিয়ে দাও',
          nowProvider: () => fixedNow,
        );
        expect(draft.title, equals('ওষুধ খাওয়ার'));
        expect(draft.scheduledAt, isNotNull);
        expect(draft.scheduledAt!.hour, equals(8));
      });
    });
  });
}
