import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/stt_service.dart';

void main() {
  group('MockSttAdapter Unit Tests', () {
    late MockSttAdapter adapter;

    setUp(() {
      adapter = MockSttAdapter();
    });

    test('Initial state is notInitialized', () {
      expect(adapter.status, equals(SttStatus.notInitialized));
      expect(adapter.isAvailable, isFalse);
      expect(adapter.isListening, isFalse);
      expect(adapter.lastFailure, isNull);
    });

    test('1. Start listening sets listening state and status', () async {
      await adapter.initialize();
      expect(adapter.isAvailable, isTrue);

      String? emittedTranscript;
      await adapter.startListening(
        languageCode: 'en_IN',
        onResult: (transcript) {
          emittedTranscript = transcript;
        },
      );

      expect(adapter.isListening, isTrue);
      expect(adapter.status, equals(SttStatus.listening));
      expect(adapter.startListeningCallCount, equals(1));
      expect(emittedTranscript, isNull); // Nothing emitted until simulated
    });

    test('2. Transcript callback receives recognized words', () async {
      await adapter.initialize();
      final receivedWords = <String>[];
      String? finalWord;

      await adapter.startListening(
        languageCode: 'en_IN',
        onResult: (t) => receivedWords.add(t),
        onFinalResult: (t) => finalWord = t,
      );

      adapter.simulateSpeech('start memory game', isFinal: true);

      expect(receivedWords, equals(['start memory game']));
      expect(finalWord, equals('start memory game'));
    });

    test('3. Stop listening stops listening state and updates status', () async {
      await adapter.initialize();
      await adapter.startListening(
        languageCode: 'hi_IN',
        onResult: (_) {},
      );

      expect(adapter.isListening, isTrue);

      await adapter.stopListening();

      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
      expect(adapter.stopListeningCallCount, equals(1));
    });

    test('4. Listening state transitions correctly through lifecycle', () async {
      expect(adapter.isListening, isFalse);

      await adapter.initialize();
      expect(adapter.status, equals(SttStatus.available));
      expect(adapter.isListening, isFalse);

      await adapter.startListening(languageCode: 'en', onResult: (_) {});
      expect(adapter.isListening, isTrue);
      expect(adapter.status, equals(SttStatus.listening));

      await adapter.stopListening();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));

      await adapter.cancel();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));

      await adapter.dispose();
      expect(adapter.status, equals(SttStatus.notInitialized));
    });

    test('5. Empty transcript is handled gracefully without crashing', () async {
      await adapter.initialize();
      String? received;

      await adapter.startListening(
        languageCode: 'en_IN',
        onResult: (t) => received = t,
      );

      adapter.simulateSpeech('', isFinal: true);

      expect(received, equals(''));
    });

    test('6. Error callback receives structured SttFailure', () async {
      await adapter.initialize();
      SttFailure? receivedError;

      await adapter.startListening(
        languageCode: 'en_IN',
        onResult: (_) {},
        onError: (err) => receivedError = err,
      );

      const testFailure = SttFailure(
        type: SttFailureType.timeout,
        message: 'Speech recognition timed out.',
      );
      adapter.simulateError(testFailure);

      expect(receivedError, isNotNull);
      expect(receivedError!.type, equals(SttFailureType.timeout));
      expect(receivedError!.message, equals('Speech recognition timed out.'));
      expect(adapter.status, equals(SttStatus.error));
      expect(adapter.lastFailure, equals(testFailure));
    });

    test('7. Language code being passed correctly to adapter', () async {
      await adapter.initialize();

      await adapter.startListening(
        languageCode: 'hi_IN',
        onResult: (_) {},
      );
      expect(adapter.lastLanguageCode, equals('hi_IN'));

      await adapter.startListening(
        languageCode: 'bn_IN',
        onResult: (_) {},
      );
      expect(adapter.lastLanguageCode, equals('bn_IN'));

      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
      );
      expect(adapter.lastLanguageCode, equals('en'));
    });

    test('8. Mock adapter behavior: simulated permission failure', () async {
      final deniedAdapter = MockSttAdapter(mockPermissionGranted: false);
      final success = await deniedAdapter.initialize();

      expect(success, isFalse);
      expect(deniedAdapter.isAvailable, isFalse);
      expect(deniedAdapter.status, equals(SttStatus.unavailable));
      expect(deniedAdapter.lastFailure?.type, equals(SttFailureType.permissionDenied));
    });

    test('8. Mock adapter behavior: auto-initialization on startListening if needed', () async {
      // Starting listening without manual initialize() should trigger initialize()
      expect(adapter.initializeCallCount, equals(0));

      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
      );

      expect(adapter.initializeCallCount, equals(1));
      expect(adapter.isListening, isTrue);
    });

    test('8. Mock adapter behavior: failure on start listening', () async {
      final failingAdapter = MockSttAdapter(
        failureToTriggerOnStart: const SttFailure(
          type: SttFailureType.microphoneUnavailable,
          message: 'Hardware unavailable',
        ),
      );

      SttFailure? captured;
      await failingAdapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => captured = err,
      );

      expect(captured, isNotNull);
      expect(captured!.type, equals(SttFailureType.microphoneUnavailable));
      expect(failingAdapter.status, equals(SttStatus.error));
    });

    test('Assamese is explicitly rejected unless verified', () async {
      await adapter.initialize();

      SttFailure? errorForAs;
      await adapter.startListening(
        languageCode: 'as',
        onResult: (_) {},
        onError: (err) => errorForAs = err,
      );

      expect(errorForAs, isNotNull);
      expect(errorForAs!.type, equals(SttFailureType.languageNotSupported));

      SttFailure? errorForAsIn;
      await adapter.startListening(
        languageCode: 'as_IN',
        onResult: (_) {},
        onError: (err) => errorForAsIn = err,
      );

      expect(errorForAsIn, isNotNull);
      expect(errorForAsIn!.type, equals(SttFailureType.languageNotSupported));
    });
  });

  group('SpeechToTextAdapter Architecture Tests', () {
    test('Can be instantiated cleanly with permission override', () {
      final adapter = SpeechToTextAdapter(
        permissionStatusOverride: () => true,
      );

      expect(adapter.status, equals(SttStatus.notInitialized));
      expect(adapter.isAvailable, isFalse);
      expect(adapter.isListening, isFalse);
      expect(adapter.lastFailure, isNull);
    });

    test('Handles permission denied gracefully without throwing exceptions', () async {
      final adapter = SpeechToTextAdapter(
        permissionStatusOverride: () => false,
      );

      final result = await adapter.initialize();
      expect(result, isFalse);
      expect(adapter.status, equals(SttStatus.unavailable));
      expect(adapter.lastFailure?.type, equals(SttFailureType.permissionDenied));
    });

    test('startListening without availability reports error callback gracefully', () async {
      final adapter = SpeechToTextAdapter(
        permissionStatusOverride: () => false,
      );

      SttFailure? receivedError;
      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => receivedError = err,
      );

      expect(receivedError, isNotNull);
      expect(receivedError?.type, equals(SttFailureType.permissionDenied));
    });
  });
}
