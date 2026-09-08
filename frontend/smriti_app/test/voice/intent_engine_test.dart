/// Unit tests for [IntentEngine].
///
/// Tests cover:
///   1. Every intent — English canonical command
///   2. Every intent — Hindi canonical command
///   3. Every intent — Bengali canonical command
///   4. Empty transcript
///   5. Whitespace-only transcript
///   6. Unknown / unrelated command
///   7. Case variation
///   8. Extra whitespace
///   9. Natural phrase variation (non-canonical wording)
///  10. Ambiguous command (potential cross-intent confusion)
///  11. Punctuation handling
///
/// No Flutter, no UI, no navigation — pure Dart only.
library intent_engine_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';

void main() {
  late IntentEngine engine;

  setUp(() {
    engine = IntentEngine();
  });

  // --------------------------------------------------------------------------
  // Helper
  // --------------------------------------------------------------------------

  VoiceIntentResult r(String transcript) => engine.recognize(transcript);

  void expectIntent(String transcript, VoiceIntent expected,
      {bool checkConfidence = true}) {
    final result = r(transcript);
    expect(
      result.intent,
      equals(expected),
      reason: 'Transcript: "$transcript" → expected $expected, got ${result.intent}',
    );
    if (checkConfidence && expected != VoiceIntent.unknown) {
      expect(
        result.confidence,
        greaterThan(0.0),
        reason: 'Confidence should be > 0 for a matched intent.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // 1. English Canonical Commands
  // --------------------------------------------------------------------------

  group('English — canonical', () {
    test('startGame: "Start memory game"', () {
      expectIntent('Start memory game', VoiceIntent.startGame);
    });

    test('startGame: "Play memory game"', () {
      expectIntent('Play memory game', VoiceIntent.startGame);
    });

    test('openMemory: "Open my memories"', () {
      expectIntent('Open my memories', VoiceIntent.openMemory);
    });

    test('openMemory: "Show my memories"', () {
      expectIntent('Show my memories', VoiceIntent.openMemory);
    });

    test('setReminder: "Set a reminder"', () {
      expectIntent('Set a reminder', VoiceIntent.setReminder);
    });

    test('setReminder: "Create a reminder"', () {
      expectIntent('Create a reminder', VoiceIntent.setReminder);
    });

    test('callCaregiver: "Call caregiver"', () {
      expectIntent('Call caregiver', VoiceIntent.callCaregiver);
    });

    test('callCaregiver: "Call my caregiver"', () {
      expectIntent('Call my caregiver', VoiceIntent.callCaregiver);
    });

    test('checkToday: "Check today"', () {
      expectIntent('Check today', VoiceIntent.checkToday);
    });

    test('checkToday: "What do I have today"', () {
      expectIntent('What do I have today', VoiceIntent.checkToday);
    });

    test('showProgress: "Show my progress"', () {
      expectIntent('Show my progress', VoiceIntent.showProgress);
    });

    test('showProgress: "How am I doing"', () {
      expectIntent('How am I doing', VoiceIntent.showProgress);
    });

    test('showProgress: "Show me how I am progressing this week."', () {
      expectIntent('Show me how I am progressing this week.', VoiceIntent.showProgress);
    });
  });

  // --------------------------------------------------------------------------
  // 2. Hindi Canonical Commands
  // --------------------------------------------------------------------------

  group('Hindi — canonical', () {
    test('startGame: "मेमोरी गेम शुरू करो"', () {
      expectIntent('मेमोरी गेम शुरू करो', VoiceIntent.startGame);
    });

    test('startGame: "मेमोरी गेम चलाओ"', () {
      expectIntent('मेमोरी गेम चलाओ', VoiceIntent.startGame);
    });

    test('openMemory: "मेरी यादें खोलो"', () {
      expectIntent('मेरी यादें खोलो', VoiceIntent.openMemory);
    });

    test('openMemory: "यादें दिखाओ"', () {
      expectIntent('यादें दिखाओ', VoiceIntent.openMemory);
    });

    test('setReminder: "रिमाइंडर लगाओ"', () {
      expectIntent('रिमाइंडर लगाओ', VoiceIntent.setReminder);
    });

    test('setReminder: "मुझे याद दिलाओ"', () {
      expectIntent('मुझे याद दिलाओ', VoiceIntent.setReminder);
    });

    test('callCaregiver: "केयरगिवर को बुलाओ"', () {
      expectIntent('केयरगिवर को बुलाओ', VoiceIntent.callCaregiver);
    });

    test('callCaregiver: "केयरगिवर को कॉल करो"', () {
      expectIntent('केयरगिवर को कॉल करो', VoiceIntent.callCaregiver);
    });

    test('checkToday: "आज का क्या है"', () {
      expectIntent('आज का क्या है', VoiceIntent.checkToday);
    });

    test('checkToday: "आज का दिन दिखाओ"', () {
      expectIntent('आज का दिन दिखाओ', VoiceIntent.checkToday);
    });

    test('showProgress: "मेरा प्रोग्रेस दिखाओ"', () {
      expectIntent('मेरा प्रोग्रेस दिखाओ', VoiceIntent.showProgress);
    });

    test('showProgress: "मेरी प्रगति दिखाओ"', () {
      expectIntent('मेरी प्रगति दिखाओ', VoiceIntent.showProgress);
    });
  });

  // --------------------------------------------------------------------------
  // 3. Bengali Canonical Commands
  // --------------------------------------------------------------------------

  group('Bengali — canonical', () {
    test('startGame: "মেমোরি গেম শুরু করো"', () {
      expectIntent('মেমোরি গেম শুরু করো', VoiceIntent.startGame);
    });

    test('openMemory: "আমার স্মৃতি খোলো"', () {
      expectIntent('আমার স্মৃতি খোলো', VoiceIntent.openMemory);
    });

    test('openMemory: "আমার স্মৃতিগুলো দেখাও"', () {
      expectIntent('আমার স্মৃতিগুলো দেখাও', VoiceIntent.openMemory);
    });

    test('setReminder: "একটি রিমাইন্ডার সেট করো"', () {
      expectIntent('একটি রিমাইন্ডার সেট করো', VoiceIntent.setReminder);
    });

    test('setReminder: "আমাকে মনে করিয়ে দাও"', () {
      expectIntent('আমাকে মনে করিয়ে দাও', VoiceIntent.setReminder);
    });

    test('callCaregiver: "কেয়ারগিভারকে কল করো"', () {
      expectIntent('কেয়ারগিভারকে কল করো', VoiceIntent.callCaregiver);
    });

    test('checkToday: "আজকের দিন দেখাও"', () {
      expectIntent('আজকের দিন দেখাও', VoiceIntent.checkToday);
    });

    test('checkToday: "আজ কী আছে"', () {
      expectIntent('আজ কী আছে', VoiceIntent.checkToday);
    });

    test('showProgress: "আমার অগ্রগতি দেখাও"', () {
      expectIntent('আমার অগ্রগতি দেখাও', VoiceIntent.showProgress);
    });

    test('setReminder: "প্রতিদিন সকাল আটটায় ওষধ খাওয়ার কথা মনে করিয়ে দাও" (Whisper ওষধ variant)', () {
      expectIntent(
        'প্রতিদিন সকাল আটটায় ওষধ খাওয়ার কথা মনে করিয়ে দাও',
        VoiceIntent.setReminder,
      );
      final result = engine.recognize('প্রতিদিন সকাল আটটায় ওষধ খাওয়ার কথা মনে করিয়ে দাও');
      expect(result.transcript, contains('ওষুধ'));
    });

    test('setReminder: "প্রতিদিন সকাল আটটায় ওষুধ খাওয়ার কথা মনে করিয়ে দাও" (standard ওষুধ spelling)', () {
      expectIntent(
        'প্রতিদিন সকাল আটটায় ওষুধ খাওয়ার কথা মনে করিয়ে দাও',
        VoiceIntent.setReminder,
      );
    });
  });

  // --------------------------------------------------------------------------
  // 4. Empty / Null / Whitespace
  // --------------------------------------------------------------------------

  group('Empty and null inputs', () {
    test('Empty string → unknown, confidence 0', () {
      final result = r('');
      expect(result.intent, equals(VoiceIntent.unknown));
      expect(result.confidence, equals(0.0));
      expect(result.transcript, equals(''));
    });

    test('Whitespace only → unknown', () {
      final result = r('   ');
      expect(result.intent, equals(VoiceIntent.unknown));
      expect(result.confidence, equals(0.0));
    });

    test('Null → unknown', () {
      final result = engine.recognize(null);
      expect(result.intent, equals(VoiceIntent.unknown));
      expect(result.confidence, equals(0.0));
    });
  });

  // --------------------------------------------------------------------------
  // 5. Unknown Commands
  // --------------------------------------------------------------------------

  group('Unknown commands', () {
    test('Completely unrelated — "tell me a joke"', () {
      expectIntent('tell me a joke', VoiceIntent.unknown, checkConfidence: false);
    });

    test('Random word — "banana"', () {
      expectIntent('banana', VoiceIntent.unknown, checkConfidence: false);
    });

    test('Empty-ish noise — "um uh"', () {
      expectIntent('um uh', VoiceIntent.unknown, checkConfidence: false);
    });
  });

  // --------------------------------------------------------------------------
  // 6. Case Variations
  // --------------------------------------------------------------------------

  group('Case variations', () {
    test('ALL CAPS: "START MEMORY GAME"', () {
      expectIntent('START MEMORY GAME', VoiceIntent.startGame);
    });

    test('Mixed case: "Set A Reminder"', () {
      expectIntent('Set A Reminder', VoiceIntent.setReminder);
    });

    test('Mixed case: "SHOW MY Progress"', () {
      expectIntent('SHOW MY Progress', VoiceIntent.showProgress);
    });

    test('Mixed case: "CALL caregiver"', () {
      expectIntent('CALL caregiver', VoiceIntent.callCaregiver);
    });
  });

  // --------------------------------------------------------------------------
  // 7. Extra Whitespace
  // --------------------------------------------------------------------------

  group('Extra whitespace', () {
    test('Leading/trailing spaces', () {
      expectIntent('   Start memory game   ', VoiceIntent.startGame);
    });

    test('Internal multiple spaces', () {
      expectIntent('show   my   progress', VoiceIntent.showProgress);
    });

    test('Tab characters', () {
      expectIntent('call\tcaregiver', VoiceIntent.callCaregiver);
    });
  });

  // --------------------------------------------------------------------------
  // 8. Natural Phrase Variations
  // --------------------------------------------------------------------------

  group('Natural phrase variations', () {
    test('startGame: "please start my memory game"', () {
      expectIntent('please start my memory game', VoiceIntent.startGame);
    });

    test('startGame: "begin the memory game for me"', () {
      expectIntent('begin the memory game for me', VoiceIntent.startGame);
    });

    test('openMemory: "can you open my memories please"', () {
      expectIntent('can you open my memories please', VoiceIntent.openMemory);
    });

    test('setReminder: "remind me later"', () {
      expectIntent('remind me later', VoiceIntent.setReminder);
    });

    test('callCaregiver: "i need my caregiver"', () {
      expectIntent('i need my caregiver', VoiceIntent.callCaregiver);
    });

    test("checkToday: \"what's on today\"", () {
      expectIntent("what's on today", VoiceIntent.checkToday);
    });

    test('showProgress: "show my score"', () {
      expectIntent('show my score', VoiceIntent.showProgress);
    });

    test('showProgress: "how have i been doing"', () {
      expectIntent('how have i been doing', VoiceIntent.showProgress);
    });
  });

  // --------------------------------------------------------------------------
  // 9. Punctuation Handling
  // --------------------------------------------------------------------------

  group('Punctuation handling', () {
    test('Trailing period: "Set a reminder."', () {
      expectIntent('Set a reminder.', VoiceIntent.setReminder);
    });

    test('Trailing question mark: "Check today?"', () {
      expectIntent('Check today?', VoiceIntent.checkToday);
    });

    test('Trailing exclamation: "Call caregiver!"', () {
      expectIntent('Call caregiver!', VoiceIntent.callCaregiver);
    });

    test('Hindi danda: "रिमाइंडर लगाओ।"', () {
      expectIntent('रिमाइंडर लगाओ।', VoiceIntent.setReminder);
    });
  });

  // --------------------------------------------------------------------------
  // 10. Ambiguity — cross-intent potential confusion
  // --------------------------------------------------------------------------

  group('Ambiguous commands', () {
    // "show memories" could hit openMemory (correct) not showProgress.
    test('"show memories" → openMemory, not showProgress', () {
      final result = r('show memories');
      expect(result.intent, equals(VoiceIntent.openMemory));
    });

    // "play" alone should NOT trigger startGame (no game keyword).
    test('"play" alone → unknown', () {
      final result = r('play');
      expect(result.intent, equals(VoiceIntent.unknown));
    });

    // "call" alone should NOT trigger callCaregiver (no caregiver keyword).
    test('"call" alone → unknown', () {
      final result = r('call');
      expect(result.intent, equals(VoiceIntent.unknown));
    });

    // "remind" alone is an edge case — low score, but acceptable as setReminder.
    test('"remind" alone → setReminder with low confidence', () {
      final result = r('remind');
      // It's acceptable either as setReminder (low conf) or unknown.
      // The important thing is it does NOT fire a wrong intent.
      expect(
        result.intent == VoiceIntent.setReminder ||
            result.intent == VoiceIntent.unknown,
        isTrue,
        reason: '"remind" alone should not fire any intent except setReminder or unknown.',
      );
    });

    // "start" alone → unknown.
    test('"start" alone → unknown', () {
      final result = r('start');
      expect(result.intent, equals(VoiceIntent.unknown));
    });
  });

  // --------------------------------------------------------------------------
  // 11. VoiceIntentResult shape
  // --------------------------------------------------------------------------

  group('VoiceIntentResult properties', () {
    test('confidence is within [0.0, 1.0]', () {
      final inputs = [
        'Start memory game',
        'Set a reminder',
        'unknown gibberish xyz',
        '',
      ];
      for (final input in inputs) {
        final result = r(input);
        expect(
          result.confidence,
          inInclusiveRange(0.0, 1.0),
          reason: 'Confidence out of range for: "$input"',
        );
      }
    });

    test('transcript is normalized (trimmed, lowercased)', () {
      final result = r('   START MEMORY GAME   ');
      expect(result.transcript, equals('start memory game'));
    });

    test('parameters is null for non-parameterized intents', () {
      final result = r('Show my progress');
      // Progress has no parameter extraction yet.
      expect(result.parameters, isNull);
    });
  });
}
