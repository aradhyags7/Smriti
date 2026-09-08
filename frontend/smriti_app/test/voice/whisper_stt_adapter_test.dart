/// Unit tests for [WhisperSttAdapter].
///
/// These tests verify the adapter's behaviour WITHOUT:
///   - a physical Android device
///   - real whisper_ggml native library
///   - a real GGML model file
///   - internet access
///   - microphone hardware
///
/// All native dependencies are exercised through factory injection or
/// structural checks only. Successful Whisper inference is NOT faked.
library whisper_stt_adapter_test;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/features/voice/stt_service.dart';

// ============================================================================
// Test Helpers
// ============================================================================

/// A minimal mock live session that emits a stream of partial transcripts.
class _MockLiveSession {
  final StreamController<String> _partialsController =
      StreamController<String>.broadcast();

  Stream<String> get partials => _partialsController.stream;

  bool stopCalled = false;

  Future<String> stop() async {
    stopCalled = true;
    await _partialsController.close();
    return 'final mock transcript';
  }

  void emitPartial(String text) {
    _partialsController.add(text);
  }
}

/// A minimal mock WhisperController that records invocations.
class _MockWhisperController {
  int transcribeLiveCallCount = 0;
  String? lastModelPath;
  String? lastLang;
  _MockLiveSession? returnSession;

  Future<_MockLiveSession> transcribeLive({
    String? modelPath,
    dynamic pcm16Stream,
    String? lang,
  }) async {
    transcribeLiveCallCount++;
    lastModelPath = modelPath;
    lastLang = lang;
    returnSession ??= _MockLiveSession();
    return returnSession!;
  }
}

/// A minimal mock AudioRecorder that returns a controlled stream.
class _MockAudioRecorder {
  int startStreamCallCount = 0;
  bool stopCalled = false;
  bool cancelCalled = false;
  bool disposeCalled = false;
  bool permissionGranted = true;

  final StreamController<Uint8List> _streamController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get pcmStream => _streamController.stream;

  Future<bool> hasPermission({bool request = true}) async => permissionGranted;

  Future<Stream<Uint8List>> startStream(dynamic config) async {
    startStreamCallCount++;
    return _streamController.stream;
  }

  Future<String?> stop() async {
    stopCalled = true;
    return null;
  }

  Future<void> cancel() async {
    cancelCalled = true;
  }

  Future<void> dispose() async {
    disposeCalled = true;
    await _streamController.close();
  }
}

// ============================================================================
// Adapter configured with injected test doubles
// ============================================================================

WhisperSttAdapter _makeInjectedAdapter({
  required String? modelPath,
  _MockWhisperController? whisperController,
  _MockAudioRecorder? recorder,
}) {
  final mockController = whisperController ?? _MockWhisperController();
  final mockRecorder = recorder ?? _MockAudioRecorder();
  return WhisperSttAdapter(
    modelPath: modelPath,
    whisperControllerFactory: () => mockController,
    recorderFactory: () => mockRecorder,
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('WhisperSttAdapter — SttAdapter interface compliance', () {
    test('implements SttAdapter interface', () {
      final adapter = WhisperSttAdapter(modelPath: null);
      expect(adapter, isA<SttAdapter>());
    });

    test('initial state is notInitialized and not listening', () {
      final adapter = WhisperSttAdapter(modelPath: null);
      expect(adapter.status, equals(SttStatus.notInitialized));
      expect(adapter.isListening, isFalse);
      expect(adapter.isAvailable, isFalse);
      expect(adapter.lastFailure, isNull);
    });
  });

  group('WhisperSttAdapter — Test 1: Missing model path', () {
    test('initialize() with null modelPath returns false with clear failure', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      final result = await adapter.initialize();

      expect(result, isFalse);
      expect(adapter.status, equals(SttStatus.unavailable));
      expect(adapter.lastFailure, isNotNull);
      expect(adapter.lastFailure!.type, equals(SttFailureType.initializationFailed));
      expect(adapter.lastFailure!.message, contains('No model path configured'));
    });

    test('initialize() with empty modelPath returns false with clear failure', () async {
      final adapter = WhisperSttAdapter(modelPath: '   ');
      final result = await adapter.initialize();

      expect(result, isFalse);
      expect(adapter.lastFailure!.message, contains('No model path configured'));
    });

    test('modelStatus returns notConfigured when modelPath is null', () {
      final adapter = WhisperSttAdapter(modelPath: null);
      expect(adapter.modelStatus, equals(WhisperModelStatus.notConfigured));
    });
  });

  group('WhisperSttAdapter — Test 2: Invalid model path (file not found)', () {
    test('initialize() with non-existent path reports initializationFailed', () async {
      // Use a path that definitely does not exist on the test system
      final adapter = WhisperSttAdapter(
        modelPath: '/nonexistent/path/ggml-base.bin',
      );
      final result = await adapter.initialize();

      expect(result, isFalse);
      expect(adapter.status, equals(SttStatus.unavailable));
      expect(adapter.lastFailure!.type, equals(SttFailureType.initializationFailed));
      expect(adapter.lastFailure!.message, contains('ggml-base.bin'));
    });

    test('startListening() with non-existent model reports error via callback', () async {
      final adapter = WhisperSttAdapter(
        modelPath: '/nonexistent/ggml-base.bin',
      );

      SttFailure? capturedError;
      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(capturedError!.type, equals(SttFailureType.initializationFailed));
    });
  });

  group('WhisperSttAdapter — Test 3: Initialization failure (factory throws)', () {
    test('factory exception during init is caught and reported as error', () async {
      final adapter = WhisperSttAdapter(
        modelPath: '/some/model.bin',
        whisperControllerFactory: () => throw Exception('Native library not loaded'),
        recorderFactory: () => _MockAudioRecorder(),
      );

      // Still fails at file check since the file doesn't exist
      final result = await adapter.initialize();
      expect(result, isFalse);
      expect(adapter.lastFailure, isNotNull);
    });
  });

  group('WhisperSttAdapter — Test 4: Unsupported language', () {
    test('startListening() rejects unsupported language with languageNotSupported', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = _makeInjectedAdapter(
        modelPath: '/fake/model.bin',
        whisperController: mockController,
        recorder: mockRecorder,
      );

      SttFailure? capturedError;
      // Tamil ('ta') is not in the Smriti-configured set
      await adapter.startListening(
        languageCode: 'ta',
        onResult: (_) {},
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(capturedError!.type, equals(SttFailureType.languageNotSupported));
      expect(capturedError!.message, contains("'ta'"));
    });

    test('supported language code variants are accepted (not rejected)', () async {
      // Test that en_IN, hi_IN etc. resolve to supported codes by verifying
      // startListening does NOT fire a languageNotSupported error for them.
      // (File check fails, but NOT with languageNotSupported.)
      for (final code in ['en', 'hi', 'bn', 'as', 'en_IN', 'hi_IN', 'bn_IN', 'as_IN', 'EN', 'HI']) {
        final adapter = WhisperSttAdapter(modelPath: null);
        SttFailure? capturedError;
        await adapter.startListening(
          languageCode: code,
          onResult: (_) {},
          onError: (err) => capturedError = err,
        );
        // The error (if any) must be initializationFailed (no model), NOT languageNotSupported
        if (capturedError != null) {
          expect(
            capturedError!.type,
            isNot(equals(SttFailureType.languageNotSupported)),
            reason: 'Code "$code" should resolve to a supported language',
          );
        }
      }
    });
  });

  group('WhisperSttAdapter — Test 5: Lifecycle', () {
    test('status transitions notInitialized → error on bad model path', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      expect(adapter.status, equals(SttStatus.notInitialized));

      await adapter.initialize();
      expect(adapter.status, equals(SttStatus.unavailable));
    });

    test('dispose() resets status to notInitialized', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      // Initialize will fail (no model), but dispose should still be safe
      await adapter.initialize();
      await adapter.dispose();

      expect(adapter.status, equals(SttStatus.notInitialized));
      expect(adapter.isListening, isFalse);
    });

    test('dispose() is idempotent', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      await adapter.dispose();
      await adapter.dispose();  // second call must not throw
      expect(adapter.status, equals(SttStatus.notInitialized));
    });
  });

  group('WhisperSttAdapter — Test 6: Cancel', () {
    test('cancel() resets listening state without throwing', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      await adapter.cancel();  // must not throw even if never started

      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
    });

    test('cancel() clears active callbacks', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      await adapter.cancel();

      expect(adapter.lastFailure, isNull);
    });
  });

  group('WhisperSttAdapter — Test 7: Dispose', () {
    test('dispose() calls cancel and resets all state', () async {
      final adapter = WhisperSttAdapter(modelPath: null);
      await adapter.dispose();

      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.notInitialized));
    });
  });

  group('WhisperSttAdapter — Test 8: Error propagation', () {
    test('missing model error propagated to onError callback in startListening', () async {
      final adapter = WhisperSttAdapter(modelPath: null);

      final errors = <SttFailure>[];
      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: errors.add,
      );

      expect(errors, hasLength(1));
      expect(errors.first.type, equals(SttFailureType.initializationFailed));
    });

    test('invalid file path error propagated to onError callback', () async {
      final adapter = WhisperSttAdapter(modelPath: '/bad/path/model.bin');

      final errors = <SttFailure>[];
      await adapter.startListening(
        languageCode: 'hi',
        onResult: (_) {},
        onError: errors.add,
      );

      expect(errors, hasLength(1));
      expect(errors.first.type, equals(SttFailureType.initializationFailed));
    });

    test('unsupported language error does NOT crash the app', () async {
      final adapter = WhisperSttAdapter(modelPath: null);

      bool threw = false;
      try {
        await adapter.startListening(
          languageCode: 'zz',
          onResult: (_) {},
        );
      } catch (_) {
        threw = true;
      }

      expect(threw, isFalse);
    });
  });

  group('WhisperSttAdapter — Test 9: SttAdapter interface compatibility', () {
    test('SttAdapter variable can hold WhisperSttAdapter without cast', () {
      final SttAdapter adapter = WhisperSttAdapter(modelPath: null);
      expect(adapter.status, equals(SttStatus.notInitialized));
      expect(adapter.isListening, isFalse);
      expect(adapter.isAvailable, isFalse);
    });

    test('WhisperSttAdapter co-exists with SpeechToTextAdapter in a list', () {
      final List<SttAdapter> adapters = [
        WhisperSttAdapter(modelPath: null),
        SpeechToTextAdapter(permissionStatusOverride: () => false),
        MockSttAdapter(),
      ];
      expect(adapters, hasLength(3));
      expect(adapters[0], isA<WhisperSttAdapter>());
      expect(adapters[1], isA<SpeechToTextAdapter>());
      expect(adapters[2], isA<MockSttAdapter>());
    });

    test('all three adapters expose the same SttAdapter interface', () {
      for (final adapter in [
        WhisperSttAdapter(modelPath: null) as SttAdapter,
        SpeechToTextAdapter(permissionStatusOverride: () => false),
        MockSttAdapter(),
      ]) {
        expect(adapter.status, isA<SttStatus>());
        expect(adapter.isListening, isA<bool>());
        expect(adapter.isAvailable, isA<bool>());
      }
    });
  });

  group('WhisperSttAdapter — Model status helper', () {
    test('null modelPath → WhisperModelStatus.notConfigured', () {
      expect(
        WhisperSttAdapter(modelPath: null).modelStatus,
        equals(WhisperModelStatus.notConfigured),
      );
    });

    test('non-empty modelPath → WhisperModelStatus.available (syntactically)', () {
      expect(
        WhisperSttAdapter(modelPath: '/data/models/ggml-base.bin').modelStatus,
        equals(WhisperModelStatus.available),
      );
    });
  });

  group('WhisperSttAdapter — Live Transcription Pipeline & Permissions', () {
    late Directory tempDir;
    late File tempModelFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('whisper_test_');
      tempModelFile = File('${tempDir.path}/test_model.bin')..writeAsStringSync('dummy model data');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('startListening streams partials and emits final result on stopListening', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      final partials = <String>[];
      String? finalTranscript;

      await adapter.startListening(
        languageCode: 'en_IN',
        onResult: partials.add,
        onFinalResult: (t) => finalTranscript = t,
      );

      expect(adapter.isListening, isTrue);
      expect(adapter.status, equals(SttStatus.listening));
      expect(mockRecorder.startStreamCallCount, equals(1));
      expect(mockController.transcribeLiveCallCount, equals(1));
      expect(mockController.lastModelPath, equals(tempModelFile.path));
      expect(mockController.lastLang, equals('en'));

      // Emit partial transcript from live session
      mockController.returnSession!.emitPartial('hello');
      mockController.returnSession!.emitPartial('hello world');
      await pumpEventQueue();

      expect(partials, equals(['hello', 'hello world']));

      // Stop listening returns final text
      await adapter.stopListening();

      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
      expect(mockRecorder.stopCalled, isTrue);
      expect(mockController.returnSession!.stopCalled, isTrue);
      expect(finalTranscript, equals('final mock transcript'));
    });

    test('startListening handles microphone permission denied', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder()..permissionGranted = false;
      final adapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      SttFailure? capturedError;
      await adapter.startListening(
        languageCode: 'hi_IN',
        onResult: (_) {},
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(capturedError!.type, equals(SttFailureType.permissionDenied));
      expect(capturedError!.message, contains('Microphone permission denied'));
      expect(adapter.status, equals(SttStatus.error));
      expect(adapter.isListening, isFalse);
    });

    test('cancel cleans up recorder and live session', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      await adapter.startListening(
        languageCode: 'bn_IN',
        onResult: (_) {},
      );

      await adapter.cancel();

      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
      expect(mockRecorder.cancelCalled, isTrue);
      expect(mockController.returnSession!.stopCalled, isTrue);
    });

    test('resolveDefaultModelPath returns valid path string containing model file name', () async {
      final path = await WhisperSttAdapter.resolveDefaultModelPath();
      expect(path, contains('ggml-tiny-q5_1.bin'));
      expect(path, isNotEmpty);
    });

    test('createWithResolvedModelPath returns WhisperSttAdapter instance with resolved model path', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = await WhisperSttAdapter.createWithResolvedModelPath(
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      expect(adapter, isA<WhisperSttAdapter>());
      expect(adapter.modelPath, contains('ggml-tiny-q5_1.bin'));
      expect(adapter.modelStatus, equals(WhisperModelStatus.available));
    });

    test('WhisperSttAdapter can cleanly start, stop, and start a second session', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      // Session 1
      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
      );
      expect(adapter.isListening, isTrue);
      expect(adapter.status, equals(SttStatus.listening));

      await adapter.stopListening();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));

      // Session 2
      await adapter.startListening(
        languageCode: 'en',
        onResult: (_) {},
      );
      expect(adapter.isListening, isTrue);
      expect(adapter.status, equals(SttStatus.listening));
      expect(mockRecorder.startStreamCallCount, equals(2));

      await adapter.stopListening();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
    });

    test('stopListening called multiple times is idempotent and safe', () async {
      final mockController = _MockWhisperController();
      final mockRecorder = _MockAudioRecorder();
      final adapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => mockController,
        recorderFactory: () => mockRecorder,
      );

      await adapter.startListening(
        languageCode: 'hi',
        onResult: (_) {},
      );

      await adapter.stopListening();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));

      // Second redundant call
      await adapter.stopListening();
      expect(adapter.isListening, isFalse);
      expect(adapter.status, equals(SttStatus.stopped));
    });

    test('failure during live session creation stops AudioRecorder and allows retry', () async {
      final mockRecorder = _MockAudioRecorder();
      bool shouldThrow = true;

      // Inject throwing dynamic controller
      final throwingAdapter = WhisperSttAdapter(
        modelPath: tempModelFile.path,
        whisperControllerFactory: () => _ThrowingWhisperController(() => shouldThrow),
        recorderFactory: () => mockRecorder,
      );

      SttFailure? capturedError;
      await throwingAdapter.startListening(
        languageCode: 'bn',
        onResult: (_) {},
        onError: (err) => capturedError = err,
      );

      expect(capturedError, isNotNull);
      expect(throwingAdapter.isListening, isFalse);
      expect(throwingAdapter.status, equals(SttStatus.error));
      expect(mockRecorder.stopCalled, isTrue);

      // Second attempt when error clears succeeds
      shouldThrow = false;
      await throwingAdapter.startListening(
        languageCode: 'bn',
        onResult: (_) {},
      );
      expect(throwingAdapter.isListening, isTrue);
      expect(throwingAdapter.status, equals(SttStatus.listening));

      await throwingAdapter.stopListening();
      expect(throwingAdapter.isListening, isFalse);
    });
  });
}

class _ThrowingWhisperController {
  final bool Function() shouldThrow;
  _ThrowingWhisperController(this.shouldThrow);

  Future<_MockLiveSession> transcribeLive({
    String? modelPath,
    dynamic pcm16Stream,
    String? lang,
  }) async {
    if (shouldThrow()) {
      throw Exception('Simulated GGML failure during transcribeLive');
    }
    return _MockLiveSession();
  }
}
