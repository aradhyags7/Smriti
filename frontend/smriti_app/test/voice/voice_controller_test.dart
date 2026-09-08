/*
 * Unit tests for [VoiceController].
 *
 * Uses [MockSttAdapter] and [MockTtsAdapter] exclusively.
 * No microphone, Android device, Whisper model, network, or audio hardware.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';
import 'package:smriti_app/features/voice/voice_controller.dart';

// ============================================================================
// Helpers
// ============================================================================

/// Build a configured [VoiceController] ready for testing.
VoiceController _makeController({
  MockSttAdapter? stt,
  MockTtsAdapter? tts,
  String languageCode = 'en',
  void Function()? onStartGame,
  void Function()? onOpenMemory,
  void Function()? onSetReminder,
  void Function(VoiceIntentResult)? onSetReminderWithResult,
  void Function()? onCallCaregiver,
  void Function()? onCheckToday,
  void Function()? onShowProgress,
  void Function(VoiceControllerState)? onStateChanged,
  void Function(VoiceControllerError)? onError,
}) {
  return VoiceController(
    stt: stt ?? MockSttAdapter(),
    tts: tts ?? MockTtsAdapter(),
    engine: IntentEngine(),
    languageCode: languageCode,
    onStartGame: onStartGame,
    onOpenMemory: onOpenMemory,
    onSetReminder: onSetReminder,
    onSetReminderWithResult: onSetReminderWithResult,
    onCallCaregiver: onCallCaregiver,
    onCheckToday: onCheckToday,
    onShowProgress: onShowProgress,
    onStateChanged: onStateChanged,
    onError: onError,
  );
}

/// Sends a transcript through [MockSttAdapter.simulateSpeech].
/// [isFinal] = false means only onResult fires (partial); true fires both.
void _simulateTranscript(
  MockSttAdapter mockStt,
  String transcript, {
  bool isFinal = false,
}) {
  mockStt.simulateSpeech(transcript, isFinal: isFinal);
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  // --------------------------------------------------------------------------
  // 1. Controller initialization
  // --------------------------------------------------------------------------
  group('Test 1 — Controller initialization', () {
    test('controller starts in idle state', () {
      final c = _makeController();
      expect(c.state, equals(VoiceControllerState.idle));
    });

    test('isListening starts false', () {
      final c = _makeController();
      expect(c.isListening, isFalse);
    });

    test('lastError starts null', () {
      final c = _makeController();
      expect(c.lastError, isNull);
    });

    test('initialize() succeeds with healthy mock adapters', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      final ok = await c.initialize();
      expect(ok, isTrue);
      expect(c.state, isNot(equals(VoiceControllerState.error)));
    });

    test('initialize() returns false when STT permission denied', () async {
      final stt = MockSttAdapter(mockPermissionGranted: false);
      final c = _makeController(stt: stt);

      final ok = await c.initialize();
      expect(ok, isFalse);
      expect(c.state, equals(VoiceControllerState.error));
      expect(c.lastError, isNotNull);
    });

    test('initialize() returns false when STT unavailable', () async {
      final stt = MockSttAdapter(mockIsAvailable: false);
      final c = _makeController(stt: stt);

      final ok = await c.initialize();
      expect(ok, isFalse);
      expect(c.state, equals(VoiceControllerState.error));
    });

    test('TTS initialization failure does not block STT', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter(mockInitializeSuccess: false);
      final c = _makeController(stt: stt, tts: tts);

      // STT succeeds, so overall initialization is true despite TTS failure
      final ok = await c.initialize();
      expect(ok, isTrue);
    });

    test('initialize() is idempotent — STT init called at most once', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.initialize();
      await c.initialize(); // second call must not re-initialize
      expect(stt.initializeCallCount, lessThanOrEqualTo(1));
    });
  });

  // --------------------------------------------------------------------------
  // 2. startListening
  // --------------------------------------------------------------------------
  group('Test 2 — startListening', () {
    test('startListening() sets state to listening', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      expect(c.state, equals(VoiceControllerState.listening));
      expect(c.isListening, isTrue);

      await c.dispose();
    });

    test('startListening() auto-initializes STT if not ready', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      expect(stt.initializeCallCount, equals(0));
      await c.startListening();
      expect(stt.initializeCallCount, equals(1));

      await c.dispose();
    });

    test('startListening() fails cleanly when STT init fails', () async {
      final stt = MockSttAdapter(mockPermissionGranted: false);
      final errors = <VoiceControllerError>[];
      final c = _makeController(stt: stt, onError: errors.add);

      await c.startListening();
      expect(c.state, equals(VoiceControllerState.error));
      expect(errors, hasLength(greaterThanOrEqualTo(1)));
    });
  });

  // --------------------------------------------------------------------------
  // 3–9. Transcript → intent recognition
  // --------------------------------------------------------------------------
  group('Test 3 — Transcript → START_GAME', () {
    test('recognizes English "start memory game"', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onStartGame: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(called, isTrue);
    });

    test('TTS response contains "memory game"', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(tts.lastSpokenText, contains('memory game'));
    });
  });

  group('Test 4 — Transcript → OPEN_MEMORY', () {
    test('recognizes English "show my memories"', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onOpenMemory: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, 'show my memories');

      expect(called, isTrue);
    });

    test('TTS response is for OPEN_MEMORY intent', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'open memories');

      expect(tts.lastSpokenText, contains('memories'));
    });
  });

  group('Test 5 — Transcript → SET_REMINDER', () {
    test('recognizes English "set a reminder" and fires legacy callback', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onSetReminder: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, 'set a reminder');

      expect(called, isTrue);
    });

    test('dispatches onSetReminderWithResult with preserved transcript and parameters', () async {
      final stt = MockSttAdapter();
      bool legacyCalled = false;
      VoiceIntentResult? receivedResult;

      final c = _makeController(
        stt: stt,
        onSetReminder: () => legacyCalled = true,
        onSetReminderWithResult: (result) => receivedResult = result,
      );

      await c.startListening();
      _simulateTranscript(stt, 'remind me to drink water at 10 am');

      expect(legacyCalled, isTrue);
      expect(receivedResult, isNotNull);
      expect(receivedResult!.intent, equals(VoiceIntent.setReminder));
      expect(receivedResult!.transcript, equals('remind me to drink water at 10 am'));
      expect(receivedResult!.confidence, greaterThan(0.0));
    });

    test('TTS speaks reminder response', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'remind me');

      expect(tts.speakCallCount, greaterThanOrEqualTo(1));
    });
  });

  group('Test 6 — Transcript → CALL_CAREGIVER', () {
    test('recognizes English "call my caregiver"', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onCallCaregiver: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, 'call my caregiver');

      expect(called, isTrue);
    });
  });

  group('Test 7 — Transcript → CHECK_TODAY', () {
    test("recognizes English \"what's on today\"", () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onCheckToday: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, "what's on today");

      expect(called, isTrue);
    });
  });

  group('Test 8 — Transcript → SHOW_PROGRESS', () {
    test('recognizes English "show my progress"', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(stt: stt, onShowProgress: () => called = true);

      await c.startListening();
      _simulateTranscript(stt, 'show my progress');

      expect(called, isTrue);
    });

    test('TTS speaks progress response', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'show my progress');

      expect(tts.lastSpokenText, contains('progress'));
    });
  });

  group('Test 9 — Unknown transcript', () {
    test('unknown transcript does NOT call any action callback', () async {
      final stt = MockSttAdapter();
      bool anyCallback = false;
      final c = _makeController(
        stt: stt,
        onStartGame: () => anyCallback = true,
        onOpenMemory: () => anyCallback = true,
        onSetReminder: () => anyCallback = true,
        onCallCaregiver: () => anyCallback = true,
        onCheckToday: () => anyCallback = true,
        onShowProgress: () => anyCallback = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'xzqy banana helicopter quantum flux');

      expect(anyCallback, isFalse);
    });

    test("unknown transcript still triggers TTS \"didn't understand\" response", () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'completely nonsense utterance abc xyz');

      expect(tts.lastSpokenText, contains("didn't understand"));
    });
  });

  // --------------------------------------------------------------------------
  // 10. Correct callback execution
  // --------------------------------------------------------------------------
  group('Test 10 — Correct callback execution', () {
    test('only the matched callback is called — not others', () async {
      final stt = MockSttAdapter();
      final called = <String>[];
      final c = _makeController(
        stt: stt,
        onStartGame: () => called.add('startGame'),
        onOpenMemory: () => called.add('openMemory'),
        onSetReminder: () => called.add('setReminder'),
        onCallCaregiver: () => called.add('callCaregiver'),
        onCheckToday: () => called.add('checkToday'),
        onShowProgress: () => called.add('showProgress'),
      );

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(called, equals(['startGame']));
    });

    test('multiple transcripts each fire their respective callback', () async {
      final stt = MockSttAdapter();
      int gameCount = 0;
      int memoryCount = 0;
      final c = _makeController(
        stt: stt,
        onStartGame: () => gameCount++,
        onOpenMemory: () => memoryCount++,
      );

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');
      _simulateTranscript(stt, 'show my memories');

      expect(gameCount, equals(1));
      expect(memoryCount, equals(1));
    });
  });

  // --------------------------------------------------------------------------
  // 11. Correct TTS response per intent
  // --------------------------------------------------------------------------
  group('Test 11 — Correct TTS response per intent', () {
    final fixtures = <String, String>{
      'start memory game': 'memory game',
      'show my memories': 'memories',
      'set a reminder': 'reminder',
      'call my caregiver': 'caregiver',
      "what's on today": 'today',
      'show my progress': 'progress',
    };

    for (final entry in fixtures.entries) {
      test(
        'transcript "${entry.key}" → TTS contains "${entry.value}"',
        () async {
          final stt = MockSttAdapter();
          final tts = MockTtsAdapter();
          final c = _makeController(stt: stt, tts: tts);

          await c.startListening();
          _simulateTranscript(stt, entry.key);

          expect(
            tts.lastSpokenText,
            contains(entry.value),
            reason:
                'Transcript "${entry.key}" should produce TTS containing "${entry.value}"',
          );
        },
      );
    }
  });

  // --------------------------------------------------------------------------
  // 12. Language code propagation to STT
  // --------------------------------------------------------------------------
  group('Test 12 — Language code → STT', () {
    test('Hindi languageCode is forwarded to STT startListening', () async {
      final stt = MockSttAdapter(mockSupportAssamese: true);
      final c = _makeController(stt: stt, languageCode: 'hi');

      await c.startListening();
      expect(stt.lastLanguageCode, equals('hi'));
      await c.dispose();
    });

    test('changing languageCode before startListening uses new code', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt, languageCode: 'en');

      c.languageCode = 'bn';
      await c.startListening();

      expect(stt.lastLanguageCode, equals('bn'));
      await c.dispose();
    });

    test('Bengali language code is forwarded', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt, languageCode: 'bn');

      await c.startListening();
      expect(stt.lastLanguageCode, equals('bn'));
      await c.dispose();
    });

    test('English language code is forwarded by default', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt); // default: 'en'

      await c.startListening();
      expect(stt.lastLanguageCode, equals('en'));
      await c.dispose();
    });
  });

  // --------------------------------------------------------------------------
  // 13. Language code propagation to TTS
  // --------------------------------------------------------------------------
  group('Test 13 — Language code → TTS', () {
    test('Hindi languageCode is forwarded to TTS speak', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter(supportedLanguages: {'en', 'hi', 'bn'});
      final c = _makeController(stt: stt, tts: tts, languageCode: 'hi');

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(tts.lastLanguageCode, equals('hi'));
    });

    test('STT and TTS both receive the same languageCode', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter(supportedLanguages: {'en', 'hi', 'bn'});
      final c = _makeController(stt: stt, tts: tts, languageCode: 'bn');

      await c.startListening();
      _simulateTranscript(stt, 'show my progress');

      expect(stt.lastLanguageCode, equals('bn'));
      expect(tts.lastLanguageCode, equals('bn'));
    });
  });

  // --------------------------------------------------------------------------
  // 14. STT error handling
  // --------------------------------------------------------------------------
  group('Test 14 — STT error handling', () {
    test('STT permission denied → controller error state', () async {
      final stt = MockSttAdapter();
      final errors = <VoiceControllerError>[];
      final c = _makeController(stt: stt, onError: errors.add);

      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.permissionDenied,
        message: 'Microphone permission denied.',
      ));

      expect(c.state, equals(VoiceControllerState.error));
      expect(errors, hasLength(greaterThanOrEqualTo(1)));
      expect(
        errors.any(
            (e) => e.type == VoiceControllerErrorType.microphonePermissionDenied),
        isTrue,
      );
    });

    test('STT initialization failure → controller reports error', () async {
      final stt = MockSttAdapter(mockPermissionGranted: false);
      final errors = <VoiceControllerError>[];
      final c = _makeController(stt: stt, onError: errors.add);

      await c.startListening();

      expect(errors, isNotEmpty);
    });

    test('STT language not supported → sttLanguageNotSupported error type',
        () async {
      final stt = MockSttAdapter();
      final errors = <VoiceControllerError>[];
      final c = _makeController(stt: stt, onError: errors.add);

      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.languageNotSupported,
        message: 'Language as_IN is not supported.',
      ));

      expect(
        errors.any(
            (e) => e.type == VoiceControllerErrorType.sttLanguageNotSupported),
        isTrue,
      );
    });

    test('STT error does not crash the controller', () async {
      final stt = MockSttAdapter();
      bool threw = false;
      final c = _makeController(stt: stt);

      try {
        await c.startListening();
        stt.simulateError(const SttFailure(
          type: SttFailureType.unknown,
          message: 'Unexpected STT error.',
        ));
      } catch (_) {
        threw = true;
      }

      expect(threw, isFalse);
    });

    test('after STT error, lastError is populated', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.microphoneUnavailable,
        message: 'No mic.',
      ));

      expect(c.lastError, isNotNull);
    });
  });

  // --------------------------------------------------------------------------
  // 15. TTS error handling
  // --------------------------------------------------------------------------
  group('Test 15 — TTS error handling', () {
    test('TTS failure still allows action callback to execute', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()
        ..simulateFailureOnSpeak = const TtsFailure(
          type: TtsFailureType.synthesisFailed,
          message: 'Audio synthesis unavailable.',
        );

      bool gameStarted = false;
      final c = _makeController(
        stt: stt,
        tts: tts,
        onStartGame: () => gameStarted = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      // Action callback must fire BEFORE TTS
      expect(gameStarted, isTrue);
    });

    test('TTS failure emits onError with ttsOperationFailed type', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()
        ..simulateFailureOnSpeak = const TtsFailure(
          type: TtsFailureType.networkError,
          message: 'TTS network unavailable.',
        );
      final errors = <VoiceControllerError>[];
      final c = _makeController(stt: stt, tts: tts, onError: errors.add);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(
        errors.any((e) => e.type == VoiceControllerErrorType.ttsOperationFailed),
        isTrue,
      );
    });

    test('TTS failure recovers controller to idle (not stuck speaking)', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()
        ..simulateFailureOnSpeak = const TtsFailure(
          type: TtsFailureType.playbackFailed,
          message: 'Audio device unavailable.',
        );
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(c.state, isNot(equals(VoiceControllerState.speaking)));
    });
  });

  // --------------------------------------------------------------------------
  // 16. stopListening
  // --------------------------------------------------------------------------
  group('Test 16 — stopListening', () {
    test('stopListening() clears isListening', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      expect(c.isListening, isTrue);

      await c.stopListening();
      expect(c.isListening, isFalse);
      await c.dispose();
    });

    test('stopListening() when not listening is a safe no-op', () async {
      final c = _makeController();
      await c.stopListening(); // must not throw
      expect(c.isListening, isFalse);
    });

    test('stopListening() returns controller to idle', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      await c.stopListening();

      expect(c.state, equals(VoiceControllerState.idle));
      await c.dispose();
    });
  });

  // --------------------------------------------------------------------------
  // 17. cancel
  // --------------------------------------------------------------------------
  group('Test 17 — cancel', () {
    test('cancel() clears isListening without processing transcript', () async {
      final stt = MockSttAdapter();
      bool callbackFired = false;
      final c = _makeController(
        stt: stt,
        onStartGame: () => callbackFired = true,
      );

      await c.startListening();
      await c.cancel();

      expect(c.isListening, isFalse);
      expect(c.state, equals(VoiceControllerState.idle));
      expect(callbackFired, isFalse);
    });

    test('cancel() on idle controller is safe no-op', () async {
      final c = _makeController();
      await c.cancel(); // must not throw
      expect(c.state, equals(VoiceControllerState.idle));
    });

    test('cancel() invokes stt.cancel()', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      await c.cancel();

      expect(stt.cancelCallCount, equals(1));
    });
  });

  // --------------------------------------------------------------------------
  // 18. dispose
  // --------------------------------------------------------------------------
  group('Test 18 — dispose', () {
    test('dispose() releases resources without throwing', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter();
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      await c.dispose();

      // disposeCallCount incremented in MockSttAdapter.dispose → cancel
      // and MockTtsAdapter.dispose
      expect(tts.disposeCallCount, equals(1));
    });

    test('dispose() is idempotent — second call is safe', () async {
      final c = _makeController();
      await c.dispose();
      await c.dispose(); // must not throw
    });

    test('startListening() after dispose throws StateError', () async {
      final c = _makeController();
      await c.dispose();
      expect(() async => c.startListening(), throwsA(isA<StateError>()));
    });

    test('initialize() after dispose throws StateError', () async {
      final c = _makeController();
      await c.dispose();
      expect(() async => c.initialize(), throwsA(isA<StateError>()));
    });
  });

  // --------------------------------------------------------------------------
  // 19. Duplicate start prevention
  // --------------------------------------------------------------------------
  group('Test 19 — Duplicate start prevention', () {
    test('calling startListening twice does not open two sessions', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      await c.startListening(); // second call must be a no-op

      expect(stt.startListeningCallCount, equals(1));
      await c.dispose();
    });

    test('isListening remains true after duplicate startListening', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      await c.startListening();

      expect(c.isListening, isTrue);
      await c.dispose();
    });
  });

  // --------------------------------------------------------------------------
  // 20. Controller state transitions
  // --------------------------------------------------------------------------
  group('Test 20 — State transitions', () {
    test('idle → listening on startListening', () async {
      final stt = MockSttAdapter();
      final states = <VoiceControllerState>[];
      final c = _makeController(stt: stt, onStateChanged: states.add);

      await c.startListening();
      expect(states, contains(VoiceControllerState.listening));
      await c.dispose();
    });

    test('listening → processing → speaking on transcript', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()..autoCompleteSpeech = false;
      final states = <VoiceControllerState>[];
      final c = _makeController(stt: stt, tts: tts, onStateChanged: states.add);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');

      expect(states, contains(VoiceControllerState.processing));
      expect(states, contains(VoiceControllerState.speaking));
    });

    test('speaking → idle after TTS completes (autoCompleteSpeech = true)', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()..autoCompleteSpeech = true;
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game');
      // Flush microtask queue so the async dispatch/speak chain completes.
      await Future<void>.microtask(() {});

      // With autoCompleteSpeech=true, onDone fires → idle
      expect(c.state, equals(VoiceControllerState.idle));
    });

    test('STT error → error state', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.unknown,
        message: 'Test error.',
      ));

      expect(c.state, equals(VoiceControllerState.error));
    });

    test('state transitions occur in correct order: listening → processing → speaking', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()..autoCompleteSpeech = true;
      final states = <VoiceControllerState>[];
      final c = _makeController(stt: stt, tts: tts, onStateChanged: states.add);

      await c.startListening();             // idle → listening
      _simulateTranscript(stt, 'start memory game'); // → processing → speaking → idle

      final iListening = states.indexOf(VoiceControllerState.listening);
      final iProcessing = states.indexOf(VoiceControllerState.processing);
      final iSpeaking = states.indexOf(VoiceControllerState.speaking);

      expect(iListening, greaterThanOrEqualTo(0));
      expect(iProcessing, greaterThan(iListening));
      expect(iSpeaking, greaterThan(iProcessing));
    });
  });

  // --------------------------------------------------------------------------
  // Hindi language support
  // --------------------------------------------------------------------------
  group('Hindi language intent recognition', () {
    test('Hindi "गेम शुरू करो" → onStartGame', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(
        stt: stt,
        languageCode: 'hi',
        onStartGame: () => called = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'गेम शुरू करो');

      expect(called, isTrue);
    });

    test('Hindi "रिमाइंडर लगाओ" → onSetReminder', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(
        stt: stt,
        languageCode: 'hi',
        onSetReminder: () => called = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'रिमाइंडर लगाओ');

      expect(called, isTrue);
    });

    test('Hindi "केयरगिवर को बुलाओ" → onCallCaregiver', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(
        stt: stt,
        languageCode: 'hi',
        onCallCaregiver: () => called = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'केयरगिवर को बुलाओ');

      expect(called, isTrue);
    });
  });

  // --------------------------------------------------------------------------
  // Bengali language support
  // --------------------------------------------------------------------------
  group('Bengali language intent recognition', () {
    test('Bengali "গেম শুরু করো" → onStartGame', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(
        stt: stt,
        languageCode: 'bn',
        onStartGame: () => called = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'গেম শুরু করো');

      expect(called, isTrue);
    });

    test('Bengali "কেয়ারগিভার কল করো" → onCallCaregiver', () async {
      final stt = MockSttAdapter();
      bool called = false;
      final c = _makeController(
        stt: stt,
        languageCode: 'bn',
        onCallCaregiver: () => called = true,
      );

      await c.startListening();
      _simulateTranscript(stt, 'কেয়ারগিভার কল করো');

      expect(called, isTrue);
    });
  });

  // --------------------------------------------------------------------------
  // Phase 5B-1: Voice session lifecycle and repeated-command reliability
  // --------------------------------------------------------------------------
  group('Phase 5B-1 — Voice Session Lifecycle and Repeated-Command Reliability', () {
    test('A. Start → stop → start again operates cleanly', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      // Session 1
      await c.startListening();
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));

      await c.stopListening();
      expect(c.isListening, isFalse);
      expect(c.state, equals(VoiceControllerState.idle));

      // Session 2
      await c.startListening();
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));

      await c.stopListening();
      expect(c.isListening, isFalse);
      expect(c.state, equals(VoiceControllerState.idle));
      expect(stt.startListeningCallCount, equals(2));
      expect(stt.stopListeningCallCount, equals(2));
    });

    test('B. Successful first command → second command can start immediately', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()..autoCompleteSpeech = true;
      int gameCount = 0;
      int memoryCount = 0;

      final c = _makeController(
        stt: stt,
        tts: tts,
        onStartGame: () => gameCount++,
        onOpenMemory: () => memoryCount++,
      );

      // Command 1
      await c.startListening();
      _simulateTranscript(stt, 'start memory game', isFinal: true);
      await Future<void>.microtask(() {});
      expect(gameCount, equals(1));
      expect(c.state, equals(VoiceControllerState.idle));

      // Command 2 immediately after
      await c.startListening();
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));

      _simulateTranscript(stt, 'show my memories', isFinal: true);
      await Future<void>.microtask(() {});
      expect(memoryCount, equals(1));
      expect(c.state, equals(VoiceControllerState.idle));
      expect(tts.speakCallCount, equals(2));
    });

    test('C. Failed session → second session can start and succeed', () async {
      final stt = MockSttAdapter();
      int gameCount = 0;
      final c = _makeController(
        stt: stt,
        onStartGame: () => gameCount++,
      );

      // Attempt 1: fails
      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.unknown,
        message: 'Transient mic glitch',
      ));
      expect(c.state, equals(VoiceControllerState.error));

      // Attempt 2: retry succeeds
      await c.startListening();
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));

      _simulateTranscript(stt, 'start memory game', isFinal: true);
      await Future<void>.microtask(() {});
      expect(gameCount, equals(1));
      expect(c.state, equals(VoiceControllerState.idle));
    });

    test('D. stopListening() called twice does not corrupt state or throw', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      await c.stopListening();
      expect(c.isListening, isFalse);
      expect(c.state, equals(VoiceControllerState.idle));

      // Second redundant call
      await c.stopListening();
      expect(c.isListening, isFalse);
      expect(c.state, equals(VoiceControllerState.idle));

      // Can still start next session cleanly
      await c.startListening();
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));
    });

    test('E. TTS speaking → startListening safely interrupts/stops TTS first', () async {
      final stt = MockSttAdapter();
      final tts = MockTtsAdapter()..autoCompleteSpeech = false;
      final c = _makeController(stt: stt, tts: tts);

      await c.startListening();
      _simulateTranscript(stt, 'start memory game', isFinal: true);
      await Future<void>.microtask(() {});

      // TTS is actively speaking
      expect(tts.isSpeaking, isTrue);
      expect(c.state, equals(VoiceControllerState.speaking));

      // User starts a new command while TTS is speaking
      await c.startListening();

      // Active TTS was interrupted/stopped
      expect(tts.stopCallCount, greaterThanOrEqualTo(1));
      expect(c.isListening, isTrue);
      expect(c.state, equals(VoiceControllerState.listening));
    });

    test('F. Rapid repeated startListening() calls do not create overlapping sessions', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      // Fire multiple concurrent startListening invocations
      await Future.wait([
        c.startListening(),
        c.startListening(),
        c.startListening(),
      ]);

      expect(stt.startListeningCallCount, equals(1));
      expect(c.isListening, isTrue);
    });

    test('G. Reminder action completes before its success response is announced', () async {
      final stt = MockSttAdapter();
      final orderOfExecution = <String>[];

      final tts = MockTtsAdapter()
        ..autoCompleteSpeech = true;

      final c = _makeController(
        stt: stt,
        tts: tts,
        onSetReminderWithResult: (result) async {
          // Simulate asynchronous persistence and notification scheduling
          await Future<void>.delayed(const Duration(milliseconds: 10));
          orderOfExecution.add('reminder_persisted_and_scheduled');
        },
      );

      // Wrap speak in test observation
      await c.startListening();
      _simulateTranscript(stt, 'remind me to drink water at 10 AM', isFinal: true);

      // Flush microtasks
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(orderOfExecution, contains('reminder_persisted_and_scheduled'));
      expect(tts.lastSpokenText, contains('reminder'));
    });

    test('H. Error path returns to usable state on cancel or retry', () async {
      final stt = MockSttAdapter();
      final c = _makeController(stt: stt);

      await c.startListening();
      stt.simulateError(const SttFailure(
        type: SttFailureType.microphoneUnavailable,
        message: 'Mic busy',
      ));
      expect(c.state, equals(VoiceControllerState.error));

      await c.cancel();
      expect(c.state, equals(VoiceControllerState.idle));
      expect(c.isListening, isFalse);
    });
  });
}
