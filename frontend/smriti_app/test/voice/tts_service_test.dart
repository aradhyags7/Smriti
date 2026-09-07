import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/tts_service.dart';

void main() {
  group('MockTtsAdapter Tests', () {
    late MockTtsAdapter adapter;

    setUp(() {
      adapter = MockTtsAdapter();
    });

    test('1. TTS initialization sets status to ready', () async {
      expect(adapter.status, equals(TtsStatus.notInitialized));
      expect(adapter.isSpeaking, isFalse);

      await adapter.initialize();

      expect(adapter.status, equals(TtsStatus.ready));
      expect(adapter.initializeCallCount, equals(1));
      expect(adapter.lastFailure, isNull);
    });

    test('1. Initialization failure simulation', () async {
      final failingAdapter = MockTtsAdapter(mockInitializeSuccess: false);

      await failingAdapter.initialize();

      expect(failingAdapter.status, equals(TtsStatus.error));
      expect(failingAdapter.lastFailure?.type, equals(TtsFailureType.initializationFailed));
    });

    test('2. speak() invokes onStart and onDone callbacks and records history', () async {
      bool started = false;
      bool completed = false;

      await adapter.speak(
        text: "Okay, let's start your memory game.",
        languageCode: 'en_IN',
        onStart: () => started = true,
        onDone: () => completed = true,
      );

      expect(started, isTrue);
      expect(completed, isTrue);
      expect(adapter.speakCallCount, equals(1));
      expect(adapter.lastSpokenText, equals("Okay, let's start your memory game."));
      expect(adapter.spokenHistory, contains("Okay, let's start your memory game."));
    });

    test('3. Language code propagation preserves languageCode', () async {
      await adapter.speak(
        text: "ठीक है, मेमोरी गेम शुरू करते हैं।",
        languageCode: 'hi_IN',
      );
      expect(adapter.lastLanguageCode, equals('hi_IN'));

      await adapter.speak(
        text: "ঠিক আছে, মেমোরি গেম শুরু করি।",
        languageCode: 'bn',
      );
      expect(adapter.lastLanguageCode, equals('bn'));
    });

    test('4. stop() halts speech and sets status to stopped', () async {
      final manualAdapter = MockTtsAdapter(autoCompleteSpeech: false);
      await manualAdapter.initialize();

      await manualAdapter.speak(
        text: 'Speaking something...',
        languageCode: 'en',
      );

      expect(manualAdapter.isSpeaking, isTrue);
      expect(manualAdapter.status, equals(TtsStatus.speaking));

      await manualAdapter.stop();

      expect(manualAdapter.isSpeaking, isFalse);
      expect(manualAdapter.status, equals(TtsStatus.stopped));
      expect(manualAdapter.stopCallCount, equals(1));
    });

    test('5. dispose() cleans up resources and resets to notInitialized', () async {
      await adapter.initialize();
      expect(adapter.status, equals(TtsStatus.ready));

      await adapter.dispose();

      expect(adapter.disposeCallCount, equals(1));
      expect(adapter.status, equals(TtsStatus.notInitialized));
      expect(adapter.isSpeaking, isFalse);
    });

    test('6. speaking state transitions correctly in manual mode', () async {
      final manualAdapter = MockTtsAdapter(autoCompleteSpeech: false);
      expect(manualAdapter.isSpeaking, isFalse);

      bool doneCalled = false;
      await manualAdapter.speak(
        text: 'Waiting for manual completion',
        languageCode: 'en',
        onDone: () => doneCalled = true,
      );

      expect(manualAdapter.isSpeaking, isTrue);
      expect(manualAdapter.status, equals(TtsStatus.speaking));
      expect(doneCalled, isFalse);

      manualAdapter.finishSpeaking();

      expect(manualAdapter.isSpeaking, isFalse);
      expect(manualAdapter.status, equals(TtsStatus.stopped));
      expect(doneCalled, isTrue);
    });

    test('7. unsupported language invokes onError with unsupportedLanguage', () async {
      TtsFailure? error;

      await adapter.speak(
        text: "ঠিক আছে, আপোনাৰ মেমৰি গেম আৰম্ভ কৰোঁ।",
        languageCode: 'as_IN', // Assamese not in default {'en', 'hi', 'bn'}
        onError: (err) => error = err,
      );

      expect(error, isNotNull);
      expect(error!.type, equals(TtsFailureType.unsupportedLanguage));
      expect(adapter.status, equals(TtsStatus.error));
      expect(adapter.isSpeaking, isFalse);
    });

    test('8. synthesis failure is simulated and reports structured error', () async {
      const simulatedFailure = TtsFailure(
        type: TtsFailureType.synthesisFailed,
        message: 'Speech synthesis engine crashed.',
      );

      final failingAdapter = MockTtsAdapter(
        simulateFailureOnSpeak: simulatedFailure,
      );

      TtsFailure? receivedError;
      await failingAdapter.speak(
        text: 'Hello',
        languageCode: 'en',
        onError: (err) => receivedError = err,
      );

      expect(receivedError, equals(simulatedFailure));
      expect(failingAdapter.status, equals(TtsStatus.error));
      expect(failingAdapter.isSpeaking, isFalse);
    });

    test('9. mock implementation supports Hindi and Bengali canonical samples', () async {
      await adapter.speak(
        text: 'ठीक है, मेमोरी गेम शुरू करते हैं।',
        languageCode: 'hi',
      );
      expect(adapter.lastSpokenText, equals('ठीक है, मेमोरी गेम शुरू करते हैं।'));

      await adapter.speak(
        text: 'ঠিক আছে, মেমোরি গেম শুরু করি।',
        languageCode: 'bn',
      );
      expect(adapter.lastSpokenText, equals('ঠিক আছে, মেমোরি গেম शुरू করি।'.replaceAll('शुरू', 'শুরু')));
    });
  });

  group('IndicTtsAdapter Boundary Tests', () {
    test('Without configured synthesizer, returns pendingConfiguration failure without crashing', () async {
      final indicAdapter = IndicTtsAdapter();

      TtsFailure? capturedError;
      await indicAdapter.speak(
        text: "Okay, let's start your memory game.",
        languageCode: 'en_IN',
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(capturedError!.type, equals(TtsFailureType.pendingConfiguration));
      expect(capturedError!.message, contains('pending model/endpoint deployment'));
      expect(indicAdapter.status, equals(TtsStatus.error));
      expect(indicAdapter.isSpeaking, isFalse);
    });

    test('Rejects unsupported language (e.g. Assamese) prior to synthesis', () async {
      final indicAdapter = IndicTtsAdapter();

      TtsFailure? capturedError;
      await indicAdapter.speak(
        text: "Test text",
        languageCode: 'as',
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(capturedError!.type, equals(TtsFailureType.unsupportedLanguage));
      expect(capturedError!.message, contains("Language 'as' is not supported"));
    });

    test('With injected synthesizer, invokes synthesis function cleanly', () async {
      String? synthesizedText;
      String? synthesizedLang;

      final testSynthesizer = (String text, String lang) async {
        synthesizedText = text;
        synthesizedLang = lang;
        // Return dummy bytes
        return Uint8List.fromList([0, 1, 2, 3]);
      };

      final indicAdapter = IndicTtsAdapter(
        synthesizer: testSynthesizer,
        // Using a factory that avoids physical audio device errors in test
        audioPlayerFactory: () => null,
      );

      bool started = false;
      bool completed = false;
      TtsFailure? error;

      await indicAdapter.speak(
        text: 'ठीक है, आज का दिन देखते हैं।',
        languageCode: 'hi_IN',
        onStart: () => started = true,
        onDone: () => completed = true,
        onError: (err) => error = err,
      );

      expect(started, isTrue);
      expect(completed, isTrue);
      expect(error, isNull);
      expect(synthesizedText, equals('ठीक है, आज का दिन देखते हैं।'));
      expect(synthesizedLang, equals('hi_IN'));
    });

    test('dispose() cleans up subscriptions and player cleanly', () async {
      final indicAdapter = IndicTtsAdapter();
      await indicAdapter.dispose();
      expect(indicAdapter.status, equals(TtsStatus.notInitialized));
      expect(indicAdapter.isSpeaking, isFalse);
    });
  });
}
