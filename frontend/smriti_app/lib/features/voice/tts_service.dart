import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// TTS Lifecycle and Failure Models
// ============================================================================

/// Represents the operational status of the TTS adapter.
enum TtsStatus {
  /// The adapter has not yet been initialized.
  notInitialized,

  /// The adapter is currently initializing.
  initializing,

  /// The adapter is initialized and ready to synthesize speech.
  ready,

  /// Speech is currently being synthesized or played.
  speaking,

  /// Speech playback has completed or was stopped.
  stopped,

  /// An error occurred during synthesis or playback.
  error,
}

/// Categorized failure reasons for text-to-speech operations.
enum TtsFailureType {
  /// Underlying TTS engine or audio player failed to initialize.
  initializationFailed,

  /// The requested language is not supported by this TTS configuration.
  unsupportedLanguage,

  /// Synthesis computation or conversion failed.
  synthesisFailed,

  /// Audio playback hardware or audio decoding failed.
  playbackFailed,

  /// Network error occurred during remote synthesis request.
  networkError,

  /// Playback was interrupted by another request or stop command.
  interrupted,

  /// Synthesis is pending configuration (real runtime/endpoint not yet supplied).
  pendingConfiguration,

  /// General or uncategorized error.
  unknown,
}

/// Structured, non-crashing error model representing a TTS failure.
class TtsFailure {
  /// Categorized failure type.
  final TtsFailureType type;

  /// Human-readable description of the failure.
  final String message;

  /// Optional underlying exception or error object.
  final Object? originalError;

  const TtsFailure({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'TtsFailure($type: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsFailure &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message;

  @override
  int get hashCode => Object.hash(type, message);
}

// ============================================================================
// TTS Adapter Abstraction
// ============================================================================

/// Clean adapter interface for text-to-speech synthesis and audio playback.
///
/// Decouples the Voice Controller and UI from concrete TTS engines or audio
/// hardware. The Voice Controller interacts exclusively with [TtsAdapter].
abstract class TtsAdapter {
  /// Current operational status of the adapter.
  TtsStatus get status;

  /// Whether the adapter is actively synthesizing or playing audio.
  bool get isSpeaking;

  /// The most recent failure encountered, if any.
  TtsFailure? get lastFailure;

  /// Initializes the TTS engine and audio playback system.
  Future<void> initialize();

  /// Speaks the given text in the requested language.
  ///
  /// - [text]: Plaintext sentence to synthesize.
  /// - [languageCode]: Target language or locale code (e.g. 'en', 'hi', 'bn', 'as').
  /// - [onStart]: Optional callback invoked when speech synthesis/playback begins.
  /// - [onDone]: Optional callback invoked when speech playback finishes.
  /// - [onError]: Optional callback invoked if synthesis or playback fails.
  Future<void> speak({
    required String text,
    required String languageCode,
    void Function()? onStart,
    void Function()? onDone,
    void Function(TtsFailure error)? onError,
  });

  /// Stops any currently playing speech immediately.
  Future<void> stop();

  /// Releases allocated resources and closes audio streams.
  Future<void> dispose();
}

// ============================================================================
// IndicTTS Implementation Boundary
// ============================================================================

/// Function signature for synthesis delegate returning raw audio bytes.
typedef IndicTtsSynthesisFunction = Future<Uint8List> Function(
  String text,
  String languageCode,
);

/// Concrete [TtsAdapter] representing the IndicTTS synthesis boundary.
///
/// NOTE ON INDICTTS INTEGRATION:
/// Smriti designates IndicTTS as the voice synthesis engine. However,
/// no real IndicTTS HTTP endpoint, API URL, or offline model binary has been
/// provided in this environment. Therefore:
/// - This adapter establishes the formal architectural boundary.
/// - It supports injecting an [IndicTtsSynthesisFunction] and [AudioPlayer] for real audio playback.
/// - Without an active synthesis configuration, calls to [speak] safely report
///   [TtsFailureType.pendingConfiguration] without inventing fake endpoints or crashing.
class IndicTtsAdapter implements TtsAdapter {
  final IndicTtsSynthesisFunction? _synthesizer;
  final AudioPlayer? Function()? _audioPlayerFactory;
  final Set<String> _supportedLanguages;

  AudioPlayer? _audioPlayer;
  StreamSubscription<void>? _playerCompleteSubscription;

  TtsStatus _status = TtsStatus.notInitialized;
  TtsFailure? _lastFailure;
  bool _isSpeaking = false;

  void Function()? _activeOnDone;

  /// Verified default languages supported by standard IndicTTS releases.
  ///
  /// Assamese ('as') is intentionally omitted from default supported languages
  /// until an Assamese acoustic model is verified in the deployed runtime.
  static const Set<String> defaultSupportedLanguages = {'en', 'hi', 'bn'};

  IndicTtsAdapter({
    this._synthesizer,
    this._audioPlayerFactory,
    Set<String>? supportedLanguages,
  })  : _supportedLanguages = supportedLanguages ?? defaultSupportedLanguages;

  @override
  TtsStatus get status => _status;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  TtsFailure? get lastFailure => _lastFailure;

  @override
  Future<void> initialize() async {
    _status = TtsStatus.initializing;
    _lastFailure = null;

    try {
      final playerFactory = _audioPlayerFactory;
      if (playerFactory != null) {
        _audioPlayer = playerFactory();
      } else {
        _audioPlayer = AudioPlayer();
      }

      if (_audioPlayer != null) {
        _playerCompleteSubscription?.cancel();
        _playerCompleteSubscription = _audioPlayer!.onPlayerComplete.listen((_) {
          _isSpeaking = false;
          _status = TtsStatus.stopped;
          _activeOnDone?.call();
          _activeOnDone = null;
        });
      }

      _status = TtsStatus.ready;
    } catch (e) {
      _status = TtsStatus.error;
      _lastFailure = TtsFailure(
        type: TtsFailureType.initializationFailed,
        message: 'Failed to initialize IndicTTS audio player: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    void Function()? onStart,
    void Function()? onDone,
    void Function(TtsFailure error)? onError,
  }) async {
    _lastFailure = null;

    // 1. Language validation
    final normalizedCode = _normalizeLanguageCode(languageCode);
    if (!_supportedLanguages.contains(normalizedCode)) {
      final failure = TtsFailure(
        type: TtsFailureType.unsupportedLanguage,
        message:
            "Language '$languageCode' is not supported by the current IndicTTS configuration. "
            "Verified languages are: ${_supportedLanguages.join(', ')}.",
      );
      _lastFailure = failure;
      _status = TtsStatus.error;
      onError?.call(failure);
      return;
    }

    // 2. Synthesis configuration check
    final synthesizer = _synthesizer;
    if (synthesizer == null) {
      final failure = const TtsFailure(
        type: TtsFailureType.pendingConfiguration,
        message:
            'IndicTTS runtime or endpoint is not yet configured. '
            'Audio synthesis is pending model/endpoint deployment.',
      );
      _lastFailure = failure;
      _status = TtsStatus.error;
      onError?.call(failure);
      return;
    }

    // 3. Ensure initialized
    if (_status != TtsStatus.ready && _status != TtsStatus.stopped) {
      await initialize();
      if (_status == TtsStatus.error) {
        onError?.call(_lastFailure!);
        return;
      }
    }

    // 4. Synthesize audio bytes
    Uint8List audioBytes;
    try {
      _isSpeaking = true;
      _status = TtsStatus.speaking;
      onStart?.call();

      audioBytes = await synthesizer(text, languageCode);
    } catch (e) {
      _isSpeaking = false;
      _status = TtsStatus.error;
      final failure = TtsFailure(
        type: TtsFailureType.synthesisFailed,
        message: 'IndicTTS synthesis failed: $e',
        originalError: e,
      );
      _lastFailure = failure;
      onError?.call(failure);
      return;
    }

    // 5. Play synthesized audio
    try {
      _activeOnDone = onDone;
      if (_audioPlayer != null) {
        await _audioPlayer!.play(BytesSource(audioBytes));
      } else {
        _isSpeaking = false;
        _status = TtsStatus.stopped;
        onDone?.call();
      }
    } catch (e) {
      _isSpeaking = false;
      _status = TtsStatus.error;
      final failure = TtsFailure(
        type: TtsFailureType.playbackFailed,
        message: 'Failed to play synthesized IndicTTS audio: $e',
        originalError: e,
      );
      _lastFailure = failure;
      onError?.call(failure);
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_isSpeaking) {
        await _audioPlayer?.stop();
      }
    } catch (e) {
      // Ignore stop error
    } finally {
      _isSpeaking = false;
      _status = TtsStatus.stopped;
      _activeOnDone = null;
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;
    _status = TtsStatus.notInitialized;
  }

  String _normalizeLanguageCode(String code) {
    final clean = code.trim().toLowerCase().replaceAll('-', '_');
    if (clean.startsWith('en')) return 'en';
    if (clean.startsWith('hi')) return 'hi';
    if (clean.startsWith('bn')) return 'bn';
    if (clean.startsWith('as')) return 'as';
    return clean;
  }
}

// ============================================================================
// Mock Implementation: MockTtsAdapter
// ============================================================================

/// In-memory mock [TtsAdapter] for testing without audio hardware or remote services.
class MockTtsAdapter implements TtsAdapter {
  TtsStatus _status = TtsStatus.notInitialized;
  TtsFailure? _lastFailure;
  bool _isSpeaking = false;

  /// Whether [initialize] should succeed.
  bool mockInitializeSuccess;

  /// Set of languages supported by this mock adapter.
  Set<String> mockSupportedLanguages;

  /// If set, [speak] will immediately fail with this failure.
  TtsFailure? simulateFailureOnSpeak;

  /// When true (default), [speak] automatically triggers [onStart] and [onDone].
  bool autoCompleteSpeech;

  /// Tracks the most recent text passed to [speak].
  String? lastSpokenText;

  /// Tracks the most recent language code passed to [speak].
  String? lastLanguageCode;

  /// Chronological log of all spoken text strings.
  final List<String> spokenHistory = [];

  int initializeCallCount = 0;
  int speakCallCount = 0;
  int stopCallCount = 0;
  int disposeCallCount = 0;

  void Function()? _pendingOnDone;

  MockTtsAdapter({
    this.mockInitializeSuccess = true,
    Set<String>? supportedLanguages,
    this.simulateFailureOnSpeak,
    this.autoCompleteSpeech = true,
  }) : mockSupportedLanguages = supportedLanguages ?? {'en', 'hi', 'bn'};

  @override
  TtsStatus get status => _status;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  TtsFailure? get lastFailure => _lastFailure;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    _status = TtsStatus.initializing;

    if (!mockInitializeSuccess) {
      _status = TtsStatus.error;
      _lastFailure = const TtsFailure(
        type: TtsFailureType.initializationFailed,
        message: 'Mock initialization failed.',
      );
      return;
    }

    _status = TtsStatus.ready;
    _lastFailure = null;
  }

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    void Function()? onStart,
    void Function()? onDone,
    void Function(TtsFailure error)? onError,
  }) async {
    speakCallCount++;
    lastSpokenText = text;
    lastLanguageCode = languageCode;
    spokenHistory.add(text);
    _pendingOnDone = onDone;

    // 1. Language validation
    final normalized = _normalizeLanguageCode(languageCode);
    if (!mockSupportedLanguages.contains(normalized)) {
      final failure = TtsFailure(
        type: TtsFailureType.unsupportedLanguage,
        message: "Language '$languageCode' is not supported by MockTtsAdapter.",
      );
      _lastFailure = failure;
      _status = TtsStatus.error;
      onError?.call(failure);
      return;
    }

    // 2. Forced failure simulation
    if (simulateFailureOnSpeak != null) {
      _lastFailure = simulateFailureOnSpeak;
      _status = TtsStatus.error;
      onError?.call(simulateFailureOnSpeak!);
      return;
    }

    // 3. Ensure initialized
    if (_status != TtsStatus.ready && _status != TtsStatus.stopped) {
      await initialize();
      if (_status == TtsStatus.error) {
        onError?.call(_lastFailure!);
        return;
      }
    }

    _isSpeaking = true;
    _status = TtsStatus.speaking;
    onStart?.call();

    if (autoCompleteSpeech) {
      _isSpeaking = false;
      _status = TtsStatus.stopped;
      onDone?.call();
      _pendingOnDone = null;
    }
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _isSpeaking = false;
    _status = TtsStatus.stopped;
    _pendingOnDone = null;
  }

  @override
  Future<void> dispose() async {
    disposeCallCount++;
    await stop();
    _status = TtsStatus.notInitialized;
  }

  /// Manually triggers completion when [autoCompleteSpeech] is false.
  void finishSpeaking() {
    if (_isSpeaking) {
      _isSpeaking = false;
      _status = TtsStatus.stopped;
      _pendingOnDone?.call();
      _pendingOnDone = null;
    }
  }

  String _normalizeLanguageCode(String code) {
    final clean = code.trim().toLowerCase().replaceAll('-', '_');
    if (clean.startsWith('en')) return 'en';
    if (clean.startsWith('hi')) return 'hi';
    if (clean.startsWith('bn')) return 'bn';
    if (clean.startsWith('as')) return 'as';
    return clean;
  }
}
