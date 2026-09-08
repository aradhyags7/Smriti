import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:whisper_ggml/whisper_ggml.dart';

// ============================================================================
// STT Lifecycle and Status Models
// ============================================================================

/// Represents the operational status of the speech-to-text adapter.
enum SttStatus {
  /// The adapter has not yet been initialized.
  notInitialized,

  /// The adapter is currently performing initialization / requesting permissions.
  initializing,

  /// The adapter is successfully initialized and ready to listen.
  available,

  /// The adapter is actively recording / listening to microphone input.
  listening,

  /// Listening has completed or stopped.
  stopped,

  /// The STT service or microphone is unavailable on the current platform/device.
  unavailable,

  /// An error occurred during operation or initialization.
  error,
}

/// Categorized failure reasons for speech recognition operations.
enum SttFailureType {
  /// User explicitly denied microphone permission.
  permissionDenied,

  /// User permanently denied microphone permission (must open app settings).
  permissionPermanentlyDenied,

  /// Device microphone hardware is absent, busy, or unavailable.
  microphoneUnavailable,

  /// Underlying STT service failed to initialize.
  initializationFailed,

  /// The requested language is not supported by the STT implementation.
  languageNotSupported,

  /// No speech input was detected before timeout.
  timeout,

  /// Network error occurred (for engines requiring online connectivity).
  networkError,

  /// General or uncategorized error.
  unknown,
}

/// Structured, non-crashing error model representing an STT failure.
class SttFailure {
  /// The categorized failure reason.
  final SttFailureType type;

  /// Human-readable explanation of the failure.
  final String message;

  /// Optional underlying exception or platform error.
  final Object? originalError;

  const SttFailure({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'SttFailure($type: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SttFailure &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message;

  @override
  int get hashCode => Object.hash(type, message);
}

// ============================================================================
// STT Adapter Abstraction
// ============================================================================

/// Clean adapter interface for speech recognition.
///
/// Decouples the Voice Controller and UI from any concrete STT package or
/// hardware dependency. Implementations can be swapped seamlessly (e.g.
/// [SpeechToTextAdapter], future offline Whisper.cpp adapter, or [MockSttAdapter]).
abstract class SttAdapter {
  /// Current operational status of the adapter.
  SttStatus get status;

  /// Whether the STT engine is initialized and available for use.
  bool get isAvailable;

  /// Whether the adapter is actively listening to speech input.
  bool get isListening;

  /// The most recent failure encountered, if any.
  SttFailure? get lastFailure;

  /// Initializes the STT engine and verifies microphone permissions.
  ///
  /// Returns `true` if initialization succeeded and the microphone is available.
  Future<bool> initialize();

  /// Starts listening for speech input in the given language.
  ///
  /// - [languageCode]: BCP-47 tag or ISO code (e.g. 'en', 'hi', 'bn', 'as', 'en_IN').
  /// - [onResult]: Invoked with recognized transcript strings as speech is processed.
  /// - [onError]: Optional callback invoked when an [SttFailure] occurs.
  /// - [onFinalResult]: Optional callback invoked specifically when speech completes.
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript) onResult,
    void Function(SttFailure error)? onError,
    void Function(String finalTranscript)? onFinalResult,
  });

  /// Stops listening and finalizes recognition.
  Future<void> stopListening();

  /// Cancels the current listening session immediately without emitting results.
  Future<void> cancel();

  /// Releases any allocated underlying resources.
  Future<void> dispose();
}

// ============================================================================
// Concrete Implementation: SpeechToTextAdapter
// ============================================================================

/// Concrete [SttAdapter] wrapping the `speech_to_text` and `permission_handler` packages.
///
/// Note: On mobile platforms, `speech_to_text` relies on Google Speech Services
/// (Android) or Apple Dictation (iOS). Offline recognition depends entirely on
/// whether offline language packs are installed on the user's device.
class SpeechToTextAdapter implements SttAdapter {
  final stt.SpeechToText _speechToText;
  final bool Function()? _permissionStatusOverride;

  SttStatus _status = SttStatus.notInitialized;
  SttFailure? _lastFailure;
  List<stt.LocaleName> _cachedLocales = [];

  void Function(String transcript)? _activeOnResult;
  void Function(SttFailure error)? _activeOnError;
  void Function(String finalTranscript)? _activeOnFinalResult;

  /// Creates a [SpeechToTextAdapter].
  ///
  /// An optional [speechToText] instance may be injected for testing.
  SpeechToTextAdapter({
    stt.SpeechToText? speechToText,
    bool Function()? permissionStatusOverride,
  })  : _speechToText = speechToText ?? stt.SpeechToText(),
        _permissionStatusOverride = permissionStatusOverride;

  @override
  SttStatus get status => _status;

  @override
  bool get isAvailable =>
      _status == SttStatus.available || _status == SttStatus.listening || _status == SttStatus.stopped;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  SttFailure? get lastFailure => _lastFailure;

  @override
  Future<bool> initialize() async {
    _status = SttStatus.initializing;
    _lastFailure = null;

    try {
      // 1. Check microphone permission
      final hasMicPermission = await _ensureMicrophonePermission();
      if (!hasMicPermission) {
        return false;
      }

      // 2. Initialize speech_to_text engine
      final available = await _speechToText.initialize(
        onError: _handlePlatformError,
        onStatus: _handlePlatformStatus,
        debugLogging: kDebugMode,
      );

      if (available) {
        _status = SttStatus.available;
        try {
          _cachedLocales = await _speechToText.locales();
        } catch (_) {
          _cachedLocales = [];
        }
        return true;
      } else {
        _status = SttStatus.unavailable;
        _lastFailure = const SttFailure(
          type: SttFailureType.microphoneUnavailable,
          message: 'Speech recognition engine is unavailable on this device.',
        );
        return false;
      }
    } catch (e) {
      _status = SttStatus.error;
      _lastFailure = SttFailure(
        type: SttFailureType.initializationFailed,
        message: 'Failed to initialize speech recognition: $e',
        originalError: e,
      );
      return false;
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript) onResult,
    void Function(SttFailure error)? onError,
    void Function(String finalTranscript)? onFinalResult,
  }) async {
    _activeOnResult = onResult;
    _activeOnError = onError;
    _activeOnFinalResult = onFinalResult;

    // Ensure initialized
    if (!isAvailable) {
      final initSuccess = await initialize();
      if (!initSuccess) {
        final failure = _lastFailure ??
            const SttFailure(
              type: SttFailureType.initializationFailed,
              message: 'STT service is not available.',
            );
        onError?.call(failure);
        return;
      }
    }

    // Check language support
    final validationError = _validateLanguageSupport(languageCode);
    if (validationError != null) {
      _lastFailure = validationError;
      onError?.call(validationError);
      return;
    }

    final localeId = _resolveLocaleId(languageCode);

    try {
      _status = SttStatus.listening;
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords;
          _activeOnResult?.call(words);
          if (result.finalResult) {
            _activeOnFinalResult?.call(words);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          localeId: localeId,
        ),
      );
    } catch (e) {
      _status = SttStatus.error;
      final failure = SttFailure(
        type: SttFailureType.unknown,
        message: 'Failed to start listening: $e',
        originalError: e,
      );
      _lastFailure = failure;
      onError?.call(failure);
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      _status = SttStatus.stopped;
    } catch (e) {
      _status = SttStatus.error;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.cancel();
      }
      _status = SttStatus.stopped;
      _activeOnResult = null;
      _activeOnError = null;
      _activeOnFinalResult = null;
    } catch (e) {
      _status = SttStatus.error;
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _status = SttStatus.notInitialized;
    _cachedLocales = [];
  }

  // --------------------------------------------------------------------------
  // Permission & Validation Helpers
  // --------------------------------------------------------------------------

  Future<bool> _ensureMicrophonePermission() async {
    final permissionOverride = _permissionStatusOverride;
    if (permissionOverride != null) {
      final granted = permissionOverride();
      if (!granted) {
        _status = SttStatus.unavailable;
        _lastFailure = const SttFailure(
          type: SttFailureType.permissionDenied,
          message: 'Microphone permission denied.',
        );
        return false;
      }
      return true;
    }

    try {
      final status = await Permission.microphone.status;

      if (status.isPermanentlyDenied) {
        _status = SttStatus.unavailable;
        _lastFailure = const SttFailure(
          type: SttFailureType.permissionPermanentlyDenied,
          message: 'Microphone permission is permanently denied. Please enable it in device settings.',
        );
        return false;
      }

      if (!status.isGranted) {
        final requestStatus = await Permission.microphone.request();

        if (requestStatus.isPermanentlyDenied) {
          _status = SttStatus.unavailable;
          _lastFailure = const SttFailure(
            type: SttFailureType.permissionPermanentlyDenied,
            message: 'Microphone permission was permanently denied.',
          );
          return false;
        }

        if (!requestStatus.isGranted) {
          _status = SttStatus.unavailable;
          _lastFailure = const SttFailure(
            type: SttFailureType.permissionDenied,
            message: 'Microphone permission was denied.',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      // If permission_handler encounters an unhandled platform exception
      _status = SttStatus.unavailable;
      _lastFailure = SttFailure(
        type: SttFailureType.permissionDenied,
        message: 'Unable to check microphone permission: $e',
        originalError: e,
      );
      return false;
    }
  }

  SttFailure? _validateLanguageSupport(String languageCode) {
    final clean = languageCode.trim().toLowerCase().replaceAll('-', '_');

    // IMPORTANT: Assamese is currently NOT verified or supported by standard OS speech engines.
    // Do NOT claim Assamese speech recognition support until verified or backed by offline Whisper.cpp.
    if (clean == 'as' || clean.startsWith('as_')) {
      final hasAssameseInCached =
          _cachedLocales.any((loc) => loc.localeId.toLowerCase().startsWith('as'));
      if (!hasAssameseInCached) {
        return const SttFailure(
          type: SttFailureType.languageNotSupported,
          message:
              'Assamese speech recognition is not supported by the current system STT engine. An offline model is required.',
        );
      }
    }

    return null;
  }

  String _resolveLocaleId(String languageCode) {
    final clean = languageCode.trim().toLowerCase().replaceAll('-', '_');
    switch (clean) {
      case 'en':
        return 'en_IN';
      case 'hi':
        return 'hi_IN';
      case 'bn':
        return 'bn_IN';
      case 'as':
        return 'as_IN';
      default:
        return languageCode.trim().replaceAll('-', '_');
    }
  }

  void _handlePlatformError(SpeechRecognitionError errorNotification) {
    final failure = _mapSpeechError(errorNotification);
    _lastFailure = failure;
    _status = SttStatus.error;
    _activeOnError?.call(failure);
  }

  void _handlePlatformStatus(String statusNotification) {
    switch (statusNotification) {
      case 'listening':
        _status = SttStatus.listening;
        break;
      case 'notListening':
      case 'done':
        _status = SttStatus.stopped;
        break;
      default:
        break;
    }
  }

  SttFailure _mapSpeechError(SpeechRecognitionError err) {
    final msg = err.errorMsg.toLowerCase();
    if (msg.contains('timeout') || msg.contains('no_match')) {
      return SttFailure(
        type: SttFailureType.timeout,
        message: 'No speech detected or recognition timed out.',
        originalError: err,
      );
    } else if (msg.contains('network')) {
      return SttFailure(
        type: SttFailureType.networkError,
        message: 'Speech recognition network error.',
        originalError: err,
      );
    } else if (msg.contains('permission')) {
      return SttFailure(
        type: SttFailureType.permissionDenied,
        message: 'Speech recognition permission error.',
        originalError: err,
      );
    } else {
      return SttFailure(
        type: SttFailureType.unknown,
        message: 'Speech recognition error: ${err.errorMsg}',
        originalError: err,
      );
    }
  }
}

// ============================================================================
// Mock Implementation: MockSttAdapter
// ============================================================================

/// In-memory mock [SttAdapter] for unit tests, integration tests, and headless environments.
///
/// Simulates speech recognition, permission states, and errors without
/// requiring a physical microphone, device hardware, or platform channels.
class MockSttAdapter implements SttAdapter {
  SttStatus _status = SttStatus.notInitialized;
  SttFailure? _lastFailure;
  bool _isListening = false;

  /// Controls whether [initialize] succeeds.
  bool mockPermissionGranted;

  /// Controls whether [initialize] reports the microphone/STT engine as available.
  bool mockIsAvailable;

  /// Whether Assamese is simulated as supported (defaults to false per requirements).
  bool mockSupportAssamese;

  /// If non-null, [startListening] will immediately trigger this failure.
  SttFailure? failureToTriggerOnStart;

  /// Records the language code supplied to the most recent [startListening] call.
  String? lastLanguageCode;

  /// Counter tracking invocations of [initialize].
  int initializeCallCount = 0;

  /// Counter tracking invocations of [startListening].
  int startListeningCallCount = 0;

  /// Counter tracking invocations of [stopListening].
  int stopListeningCallCount = 0;

  /// Counter tracking invocations of [cancel].
  int cancelCallCount = 0;

  void Function(String transcript)? _onResult;
  void Function(SttFailure error)? _onError;
  void Function(String finalTranscript)? _onFinalResult;

  MockSttAdapter({
    this.mockPermissionGranted = true,
    this.mockIsAvailable = true,
    this.mockSupportAssamese = false,
    this.failureToTriggerOnStart,
  });

  @override
  SttStatus get status => _status;

  @override
  bool get isAvailable =>
      _status == SttStatus.available || _status == SttStatus.listening || _status == SttStatus.stopped;

  @override
  bool get isListening => _isListening;

  @override
  SttFailure? get lastFailure => _lastFailure;

  @override
  Future<bool> initialize() async {
    initializeCallCount++;
    _status = SttStatus.initializing;

    if (!mockPermissionGranted) {
      _status = SttStatus.unavailable;
      _lastFailure = const SttFailure(
        type: SttFailureType.permissionDenied,
        message: 'Mock microphone permission denied.',
      );
      return false;
    }

    if (!mockIsAvailable) {
      _status = SttStatus.unavailable;
      _lastFailure = const SttFailure(
        type: SttFailureType.microphoneUnavailable,
        message: 'Mock microphone is unavailable.',
      );
      return false;
    }

    _status = SttStatus.available;
    _lastFailure = null;
    return true;
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript) onResult,
    void Function(SttFailure error)? onError,
    void Function(String finalTranscript)? onFinalResult,
  }) async {
    startListeningCallCount++;
    lastLanguageCode = languageCode;
    _onResult = onResult;
    _onError = onError;
    _onFinalResult = onFinalResult;

    if (!isAvailable) {
      final success = await initialize();
      if (!success) {
        onError?.call(_lastFailure ??
            const SttFailure(
              type: SttFailureType.initializationFailed,
              message: 'Mock STT not available.',
            ));
        return;
      }
    }

    // Assamese validation
    final clean = languageCode.trim().toLowerCase().replaceAll('-', '_');
    if ((clean == 'as' || clean.startsWith('as_')) && !mockSupportAssamese) {
      final failure = const SttFailure(
        type: SttFailureType.languageNotSupported,
        message: 'Assamese speech recognition is not supported by current implementation.',
      );
      _lastFailure = failure;
      onError?.call(failure);
      return;
    }

    if (failureToTriggerOnStart != null) {
      _lastFailure = failureToTriggerOnStart;
      _status = SttStatus.error;
      onError?.call(failureToTriggerOnStart!);
      return;
    }

    _isListening = true;
    _status = SttStatus.listening;
  }

  @override
  Future<void> stopListening() async {
    stopListeningCallCount++;
    _isListening = false;
    _status = SttStatus.stopped;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
    _isListening = false;
    _status = SttStatus.stopped;
    _onResult = null;
    _onError = null;
    _onFinalResult = null;
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _status = SttStatus.notInitialized;
  }

  // --------------------------------------------------------------------------
  // Simulation Helpers for Tests
  // --------------------------------------------------------------------------

  /// Simulates recognizing spoken words from the microphone.
  void simulateSpeech(String transcript, {bool isFinal = true}) {
    if (!_isListening && _status != SttStatus.listening) {
      return;
    }
    _onResult?.call(transcript);
    if (isFinal) {
      _onFinalResult?.call(transcript);
    }
  }

  /// Simulates an STT error callback during listening.
  void simulateError(SttFailure failure) {
    _lastFailure = failure;
    _status = SttStatus.error;
    _onError?.call(failure);
  }
}

// ============================================================================
// Concrete Implementation: WhisperSttAdapter (Offline, via whisper_ggml)
// ============================================================================

/// Configures how the [WhisperSttAdapter] validates and routes language codes
/// to the underlying Whisper multilingual model.
///
/// Whisper accepts standard ISO-639-1 codes. All four Smriti languages are
/// tokenized by the multilingual GGML model.
///
/// IMPORTANT — Assamese ('as'):
/// The multilingual Whisper model includes Assamese tokenizer entries.
/// Unlike the Android OS speech service (which lacked an offline Assamese
/// model), whisper.cpp inference includes Assamese vocabulary.
/// HOWEVER: real-device inference accuracy for Assamese (especially for
/// regional/dialectal utterances) has NOT been verified by the team on a
/// physical device yet. It is represented here as structurally supported
/// but requiring on-device verification.
const Set<String> _whisperSupportedLanguageCodes = {'en', 'hi', 'bn', 'as'};

/// Maps caller-supplied language code variants to the 2-letter ISO code
/// that the whisper_ggml [lang] parameter expects.
String _resolveWhisperLangCode(String code) {
  final clean = code.trim().toLowerCase().replaceAll('-', '_');
  if (clean.startsWith('en')) return 'en';
  if (clean.startsWith('hi')) return 'hi';
  if (clean.startsWith('bn')) return 'bn';
  if (clean.startsWith('as')) return 'as';
  return clean;
}

/// Result of a [WhisperSttAdapter.initialize] configuration check.
enum WhisperModelStatus {
  /// Model file path was not provided.
  notConfigured,
  /// Model file was provided but does not exist at that path.
  fileNotFound,
  /// Model file exists and the adapter is ready.
  available,
}

/// Concrete [SttAdapter] wrapping the [whisper_ggml] package for fully
/// offline, on-device speech recognition using OpenAI Whisper models.
///
/// PIPELINE:
///   Microphone  →  record (16 kHz mono PCM16)
///               →  whisper_ggml (WhisperController.transcribeLive)
///               →  transcript string
///               →  onResult callback
///
/// USAGE:
/// ```dart
/// final adapter = WhisperSttAdapter(
///   modelPath: '/data/user/0/com.smriti/files/models/ggml-base.bin',
/// );
/// await adapter.initialize();
/// await adapter.startListening(languageCode: 'hi', onResult: (t) => ...);
/// ```
///
/// MODEL NOT INCLUDED IN GIT:
/// The GGML model binary must be provided at runtime by supplying [modelPath].
/// Suggested model: ggml-base.bin (multilingual, ~142 MB) or
///                  ggml-base-q5_1.bin (quantized, ~75 MB).
/// Source: https://huggingface.co/ggerganov/whisper.cpp
///
/// NO CLOUD STT:
/// All inference runs on-device. No data leaves the phone.
class WhisperSttAdapter implements SttAdapter {
  /// Absolute path to the GGML model binary on the device's local filesystem.
  ///
  /// Use [path_provider] to resolve the app documents directory at runtime.
  /// Must be set before calling [initialize] or [startListening].
  final String? modelPath;

  SttStatus _status = SttStatus.notInitialized;
  SttFailure? _lastFailure;
  bool _isListening = false;

  // Real native controller and live session from whisper_ggml
  dynamic _whisperController;
  dynamic _liveSession;

  // AudioRecorder from the record package
  dynamic _recorder;

  // Stream subscription for partial transcripts
  StreamSubscription<String>? _partialsSubscription;

  // Active callbacks
  void Function(String transcript)? _onResult;
  void Function(SttFailure error)? _onError;
  void Function(String finalTranscript)? _onFinalResult;

  // Factory functions for dependency injection in tests
  final dynamic Function()? _whisperControllerFactory;
  final dynamic Function()? _recorderFactory;

  WhisperSttAdapter({
    this.modelPath,
    dynamic Function()? whisperControllerFactory,
    dynamic Function()? recorderFactory,
  })  : _whisperControllerFactory = whisperControllerFactory,
        _recorderFactory = recorderFactory;

  /// Factory constructor that dynamically resolves the model path in the
  /// app-private directory (`getApplicationSupportDirectory()`) before creating
  /// the [WhisperSttAdapter].
  ///
  /// Default target: `<application-support-directory>/ggml-tiny-q5_1.bin`
  static Future<WhisperSttAdapter> createWithResolvedModelPath({
    String modelFileName = 'ggml-tiny-q5_1.bin',
    dynamic Function()? whisperControllerFactory,
    dynamic Function()? recorderFactory,
  }) async {
    final path = await resolveDefaultModelPath(modelFileName: modelFileName);
    return WhisperSttAdapter(
      modelPath: path,
      whisperControllerFactory: whisperControllerFactory,
      recorderFactory: recorderFactory,
    );
  }

  /// Dynamically resolves the absolute path to the provisioned GGML model
  /// binary in the Android app-private storage directory.
  ///
  /// Priority:
  ///   1. `<getApplicationSupportDirectory()>/ggml-tiny-q5_1.bin`
  ///   2. `<getApplicationDocumentsDirectory()>/ggml-tiny-q5_1.bin`
  static Future<String> resolveDefaultModelPath({
    String modelFileName = 'ggml-tiny-q5_1.bin',
  }) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final supportPath = '${supportDir.path}/$modelFileName';
      if (File(supportPath).existsSync()) {
        return supportPath;
      }

      final docDir = await getApplicationDocumentsDirectory();
      final docPath = '${docDir.path}/$modelFileName';
      if (File(docPath).existsSync()) {
        return docPath;
      }

      return supportPath;
    } catch (_) {
      return '/data/user/0/com.example.smriti_app/files/$modelFileName';
    }
  }

  @override
  SttStatus get status => _status;

  @override
  bool get isAvailable =>
      _status == SttStatus.available ||
      _status == SttStatus.listening ||
      _status == SttStatus.stopped;

  @override
  bool get isListening => _isListening;

  @override
  SttFailure? get lastFailure => _lastFailure;

  /// Returns the current status of the model file configuration.
  WhisperModelStatus get modelStatus {
    if (modelPath == null || modelPath!.trim().isEmpty) {
      return WhisperModelStatus.notConfigured;
    }
    return WhisperModelStatus.available;
  }

  @override
  Future<bool> initialize() async {
    _status = SttStatus.initializing;
    _lastFailure = null;

    // 1. Model path validation
    if (modelPath == null || modelPath!.trim().isEmpty) {
      _status = SttStatus.unavailable;
      _lastFailure = const SttFailure(
        type: SttFailureType.initializationFailed,
        message:
            'WhisperSttAdapter: No model path configured. '
            'Provide the absolute path to a GGML model binary '
            '(e.g. ggml-base.bin) via WhisperSttAdapter(modelPath: ...).',
      );
      return false;
    }

    // 2. File existence check using dart:io File
    try {
      final file = File(modelPath!);
      if (!file.existsSync()) {
        _status = SttStatus.unavailable;
        _lastFailure = SttFailure(
          type: SttFailureType.initializationFailed,
          message:
              'WhisperSttAdapter: Model file not found at "$modelPath". '
              'Download a GGML model (e.g. ggml-base.bin) and configure '
              'the path to the app documents directory.',
        );
        return false;
      }
    } catch (e) {
      _status = SttStatus.unavailable;
      _lastFailure = SttFailure(
        type: SttFailureType.initializationFailed,
        message: 'WhisperSttAdapter: Could not verify model file at "$modelPath": $e',
        originalError: e,
      );
      return false;
    }

    // 3. Create the WhisperController and AudioRecorder instances
    try {
      final whisperFactory = _whisperControllerFactory;
      _whisperController = whisperFactory != null
          ? whisperFactory()
          : WhisperController();

      final recorderFactory = _recorderFactory;
      _recorder = recorderFactory != null
          ? recorderFactory()
          : AudioRecorder();

      _status = SttStatus.available;
      return true;
    } catch (e) {
      _status = SttStatus.error;
      _lastFailure = SttFailure(
        type: SttFailureType.initializationFailed,
        message: 'WhisperSttAdapter: Failed to create controller/recorder: $e',
        originalError: e,
      );
      return false;
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript) onResult,
    void Function(SttFailure error)? onError,
    void Function(String finalTranscript)? onFinalResult,
  }) async {
    _onResult = onResult;
    _onError = onError;
    _onFinalResult = onFinalResult;

    // Validate language code
    final resolvedCode = _resolveWhisperLangCode(languageCode);
    if (!_whisperSupportedLanguageCodes.contains(resolvedCode)) {
      final failure = SttFailure(
        type: SttFailureType.languageNotSupported,
        message:
            "WhisperSttAdapter: Language '$languageCode' (resolved: '$resolvedCode') "
            'is not in the supported language set for this adapter: '
            '${_whisperSupportedLanguageCodes.join(', ')}.',
      );
      _lastFailure = failure;
      _status = SttStatus.error;
      onError?.call(failure);
      return;
    }

    // Auto-initialize if needed
    if (!isAvailable) {
      final success = await initialize();
      if (!success) {
        onError?.call(_lastFailure!);
        return;
      }
    }

    // Check microphone permission via AudioRecorder if available
    try {
      final dynamic rec = _recorder;
      if (rec != null) {
        // ignore: avoid_dynamic_calls
        final dynamic hasPerm = await rec.hasPermission(request: true);
        if (hasPerm == false) {
          final failure = const SttFailure(
            type: SttFailureType.permissionDenied,
            message: 'WhisperSttAdapter: Microphone permission denied.',
          );
          _lastFailure = failure;
          _status = SttStatus.error;
          onError?.call(failure);
          return;
        }
      }
    } catch (_) {
      // Allow proceeding if custom test double does not implement hasPermission
    }

    try {
      _isListening = true;
      _status = SttStatus.listening;
      await _startWhisperLiveSession(resolvedCode);
    } catch (e) {
      _isListening = false;
      _status = SttStatus.error;
      try {
        await _partialsSubscription?.cancel();
      } catch (_) {}
      _partialsSubscription = null;
      try {
        final dynamic rec = _recorder;
        // ignore: avoid_dynamic_calls
        await rec?.stop();
      } catch (_) {}
      try {
        final dynamic session = _liveSession;
        // ignore: avoid_dynamic_calls
        await session?.stop();
      } catch (_) {}
      _liveSession = null;

      final failure = SttFailure(
        type: SttFailureType.unknown,
        message: 'WhisperSttAdapter: Failed to start live session: $e',
        originalError: e,
      );
      _lastFailure = failure;
      onError?.call(failure);
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening && _liveSession == null) return;
    try {
      await _partialsSubscription?.cancel();
      _partialsSubscription = null;

      final dynamic recorder = _recorder;
      // ignore: avoid_dynamic_calls
      await recorder?.stop();

      final dynamic session = _liveSession;
      _liveSession = null;
      // ignore: avoid_dynamic_calls
      final dynamic finalText = await session?.stop();
      _isListening = false;
      _status = SttStatus.stopped;
      if (finalText != null && finalText is String && finalText.isNotEmpty) {
        _onFinalResult?.call(finalText);
      }
    } catch (e) {
      _isListening = false;
      _liveSession = null;
      _status = SttStatus.error;
      final failure = SttFailure(
        type: SttFailureType.unknown,
        message: 'WhisperSttAdapter: Error during stopListening: $e',
        originalError: e,
      );
      _lastFailure = failure;
      _onError?.call(failure);
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _partialsSubscription?.cancel();
      _partialsSubscription = null;

      final dynamic recorder = _recorder;
      // ignore: avoid_dynamic_calls
      await recorder?.cancel();

      final dynamic session = _liveSession;
      _liveSession = null;
      // ignore: avoid_dynamic_calls
      await session?.stop();
    } catch (_) {
      // Ignore cancel errors
    } finally {
      _isListening = false;
      _status = SttStatus.stopped;
      _liveSession = null;
      _onResult = null;
      _onError = null;
      _onFinalResult = null;
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    try {
      final dynamic recorder = _recorder;
      // ignore: avoid_dynamic_calls
      await recorder?.dispose();
    } catch (_) {}
    _whisperController = null;
    _recorder = null;
    _status = SttStatus.notInitialized;
  }

  // --------------------------------------------------------------------------
  // Internal Live Session Startup
  // --------------------------------------------------------------------------

  Future<void> _startWhisperLiveSession(String langCode) async {
    final dynamic recorder = _recorder;
    final dynamic controller = _whisperController;

    if (recorder == null || controller == null) {
      throw StateError('WhisperSttAdapter not initialized or disposed.');
    }

    // 1. Start audio recording stream with 16kHz mono 16-bit PCM
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    // ignore: avoid_dynamic_calls
    final dynamic rawStream = await recorder.startStream(config);
    final Stream<Uint8List> pcm16Stream = rawStream is Stream<Uint8List>
        ? rawStream
        : (rawStream as Stream).cast<Uint8List>();

    try {
      // 2. Start whisper live session
      // ignore: avoid_dynamic_calls
      final dynamic session = await controller.transcribeLive(
        modelPath: modelPath!,
        pcm16Stream: pcm16Stream,
        lang: langCode,
      );

      _liveSession = session;

      // 3. Listen to partial transcripts
      // ignore: avoid_dynamic_calls
      final Stream<String> partials = session.partials as Stream<String>;
      _partialsSubscription = partials.listen(
        (partial) {
          _onResult?.call(partial);
        },
        onError: (Object err) {
          final failure = SttFailure(
            type: SttFailureType.unknown,
            message: 'WhisperSttAdapter: Transcription stream error: $err',
            originalError: err,
          );
          _lastFailure = failure;
          _onError?.call(failure);
        },
      );
    } catch (e) {
      try {
        // ignore: avoid_dynamic_calls
        await recorder.stop();
      } catch (_) {}
      rethrow;
    }
  }
}
