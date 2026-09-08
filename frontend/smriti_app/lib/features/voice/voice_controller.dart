import 'dart:async';

import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';

// ============================================================================
// VoiceControllerState
// ============================================================================

/// Observable lifecycle state of [VoiceController].
///
/// The UI layer maps these values to display strings such as
/// "Listening…", "Processing…", etc.  The controller never
/// touches [BuildContext] or any navigation primitive.
enum VoiceControllerState {
  /// Controller has not yet been initialized, or has been disposed.
  idle,

  /// Microphone is open and recording speech input.
  listening,

  /// Transcript received; intent recognition is in progress.
  processing,

  /// TTS response is playing.
  speaking,

  /// A non-fatal error occurred.  Check [VoiceController.lastError].
  error,
}

// ============================================================================
// VoiceControllerError
// ============================================================================

/// Categorized error wrapper surfaced by [VoiceController].
enum VoiceControllerErrorType {
  /// STT could not initialize (permissions, hardware, model missing).
  sttInitializationFailed,

  /// Microphone permission was denied.
  microphonePermissionDenied,

  /// The selected language is not supported by the active STT adapter.
  sttLanguageNotSupported,

  /// The Whisper model binary is absent on the device.
  whisperModelUnavailable,

  /// STT operation failed after initialization.
  sttOperationFailed,

  /// TTS synthesis or playback failed.
  ttsOperationFailed,

  /// General or unclassified error.
  unknown,
}

/// Structured error reported by [VoiceController] via [VoiceController.lastError]
/// and the optional [VoiceController.onError] callback.
class VoiceControllerError {
  final VoiceControllerErrorType type;
  final String message;
  final Object? originalError;

  const VoiceControllerError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'VoiceControllerError($type: $message)';
}

// ============================================================================
// Intent Response Map
// ============================================================================

/// Default English TTS responses for each recognized [VoiceIntent].
///
/// These are owned exclusively by [VoiceController] — not the [IntentEngine].
/// The IntentEngine has no knowledge of response text.
const Map<VoiceIntent, String> _defaultResponses = {
  VoiceIntent.startGame:
      "Okay, let's start your memory game.",
  VoiceIntent.openMemory:
      'Opening your memories.',
  VoiceIntent.setReminder:
      "Let's set a reminder.",
  VoiceIntent.callCaregiver:
      "I'll help you contact your caregiver.",
  VoiceIntent.checkToday:
      "Let's check today's activities.",
  VoiceIntent.showProgress:
      'Here is your progress.',
  VoiceIntent.unknown:
      "I didn't understand that. Please try again.",
};

// ============================================================================
// VoiceController
// ============================================================================

/// Orchestration layer connecting STT → IntentEngine → Callbacks → TTS.
///
/// PIPELINE:
///   startListening()
///     → SttAdapter.startListening
///       → transcript
///         → IntentEngine.recognize
///           → VoiceIntent
///             → intent callback (e.g. onStartGame)
///             → TtsAdapter.speak (response text)
///
/// DEPENDENCY INJECTION:
///   [stt]     — any [SttAdapter] (SpeechToTextAdapter, WhisperSttAdapter, MockSttAdapter)
///   [tts]     — any [TtsAdapter] (IndicTtsAdapter, MockTtsAdapter)
///   [engine]  — [IntentEngine] (stateless, final, offline)
///
/// NO FLUTTER COUPLING:
///   VoiceController has zero dependency on:
///     BuildContext, Navigator, MaterialApp, or any Flutter widget.
///   It is a pure Dart orchestration service.
///
/// LANGUAGE:
///   [languageCode] controls which language code is forwarded to both STT and TTS.
///   Supported codes: 'en', 'hi', 'bn'.
///   'as' (Assamese) may be passed for TTS if the TTS adapter supports it.
///   Assamese STT accuracy is unverified — the STT adapter will report
///   [SttFailureType.languageNotSupported] if its implementation rejects it.
///
/// ERROR RESILIENCE:
///   TTS failures do NOT suppress action callbacks.
///   For example: START_GAME is detected → onStartGame() fires even if TTS fails.
class VoiceController {
  // --------------------------------------------------------------------------
  // Dependencies
  // --------------------------------------------------------------------------

  final SttAdapter stt;
  final TtsAdapter tts;
  final IntentEngine engine;

  // --------------------------------------------------------------------------
  // Configuration
  // --------------------------------------------------------------------------

  /// BCP-47 / ISO-639-1 language code forwarded to STT and TTS.
  ///
  /// Changing this property between calls to [startListening] is safe.
  /// The new code takes effect on the next [startListening] call.
  String languageCode;

  // --------------------------------------------------------------------------
  // Intent callbacks
  // --------------------------------------------------------------------------
  // All callbacks are [void Function()?] (VoidCallback-compatible).
  // They are invoked after intent recognition and BEFORE TTS.
  // Navigation and UI transitions are the responsibility of the caller.

  /// Called when [VoiceIntent.startGame] is recognized.
  FutureOr<void> Function()? onStartGame;

  /// Called when [VoiceIntent.openMemory] is recognized.
  FutureOr<void> Function()? onOpenMemory;

  /// Called when [VoiceIntent.setReminder] is recognized.
  ///
  /// Future: will receive extracted reminder parameters.
  FutureOr<void> Function()? onSetReminder;

  /// Called when [VoiceIntent.setReminder] is recognized with the full [VoiceIntentResult].
  FutureOr<void> Function(VoiceIntentResult result)? onSetReminderWithResult;

  /// Called when [VoiceIntent.callCaregiver] is recognized.
  FutureOr<void> Function()? onCallCaregiver;

  /// Called when [VoiceIntent.checkToday] is recognized.
  FutureOr<void> Function()? onCheckToday;

  /// Called when [VoiceIntent.showProgress] is recognized.
  FutureOr<void> Function()? onShowProgress;

  // --------------------------------------------------------------------------
  // Status / Error callbacks
  // --------------------------------------------------------------------------

  /// Invoked whenever [state] changes.
  ///
  /// Allows lightweight state-reactive UI without requiring ChangeNotifier.
  void Function(VoiceControllerState state)? onStateChanged;

  /// Invoked whenever an intermediate or final transcript is received from STT.
  void Function(String transcript)? onTranscript;

  /// Invoked when a non-fatal error occurs.
  void Function(VoiceControllerError error)? onError;

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------

  VoiceControllerState _state = VoiceControllerState.idle;
  VoiceControllerError? _lastError;

  /// Current operational state of the controller.
  VoiceControllerState get state => _state;

  /// The most recent error, or null if no error has occurred.
  VoiceControllerError? get lastError => _lastError;

  // --------------------------------------------------------------------------
  // Internal
  // --------------------------------------------------------------------------

  bool _isListening = false;
  bool _isStarting = false;
  bool _isStopping = false;
  bool _disposed = false;
  String? _lastDispatchedTranscript;

  /// Whether the controller is currently in a listening session.
  bool get isListening => _isListening;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

  VoiceController({
    required this.stt,
    required this.tts,
    required this.engine,
    this.languageCode = 'en',
    this.onStartGame,
    this.onOpenMemory,
    this.onSetReminder,
    this.onSetReminderWithResult,
    this.onCallCaregiver,
    this.onCheckToday,
    this.onShowProgress,
    this.onStateChanged,
    this.onTranscript,
    this.onError,
  });

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Initializes both the STT and TTS adapters.
  ///
  /// Call this once before [startListening].  It is safe to call multiple
  /// times; subsequent calls are no-ops if already initialized.
  ///
  /// Returns `true` if both adapters are ready.
  Future<bool> initialize() async {
    _assertNotDisposed();

    // Initialize TTS (non-fatal if it fails — TTS is best-effort)
    try {
      if (tts.status == TtsStatus.notInitialized) {
        await tts.initialize();
      }
    } catch (e) {
      // TTS failure is recorded but does not block STT initialization.
      _emitError(VoiceControllerError(
        type: VoiceControllerErrorType.ttsOperationFailed,
        message: 'TTS failed to initialize: $e',
        originalError: e,
      ));
    }

    // Initialize STT (fatal if it fails — cannot listen without STT)
    try {
      if (!stt.isAvailable) {
        final ok = await stt.initialize();
        if (!ok) {
          final sttError = _mapSttFailure(stt.lastFailure);
          _emitError(sttError);
          _setState(VoiceControllerState.error);
          return false;
        }
      }
    } catch (e) {
      final err = VoiceControllerError(
        type: VoiceControllerErrorType.sttInitializationFailed,
        message: 'STT failed to initialize: $e',
        originalError: e,
      );
      _emitError(err);
      _setState(VoiceControllerState.error);
      return false;
    }

    return true;
  }

  /// Begins a voice recognition session.
  ///
  /// If the controller is already listening or in transition, this call is a
  /// safe no-op to prevent duplicate/overlapping sessions.
  ///
  /// Flow:
  ///   1. Safely stop TTS if active.
  ///   2. Initialize STT if needed.
  ///   3. Set state to [VoiceControllerState.listening].
  ///   4. On transcript → [VoiceControllerState.processing] → recognize intent.
  ///   5. Fire intent callback.
  ///   6. Speak TTS response (best-effort).
  Future<void> startListening() async {
    _assertNotDisposed();

    // Guard: prevent duplicate sessions or overlapping transitions
    if (_isListening || _isStarting || _isStopping || _state == VoiceControllerState.processing) {
      return;
    }

    _isStarting = true;

    try {
      // Safely interrupt active TTS before opening the microphone to avoid
      // hardware contention and recording device speaker output.
      if (tts.isSpeaking || _state == VoiceControllerState.speaking) {
        try {
          await tts.stop();
        } catch (_) {}
      }

      // Auto-initialize STT if not yet ready
      if (!stt.isAvailable) {
        final ok = await stt.initialize();
        if (!ok) {
          final err = _mapSttFailure(stt.lastFailure);
          _emitError(err);
          _setState(VoiceControllerState.error);
          return;
        }
      }

      _isListening = true;
      _lastDispatchedTranscript = null;
      _setState(VoiceControllerState.listening);

      await stt.startListening(
        languageCode: languageCode,
        onResult: _onSttResult,
        onError: _onSttError,
        onFinalResult: _onSttFinalResult,
      );
    } catch (e) {
      _isListening = false;
      final err = VoiceControllerError(
        type: VoiceControllerErrorType.sttOperationFailed,
        message: 'Failed to start listening: $e',
        originalError: e,
      );
      _emitError(err);
      _setState(VoiceControllerState.error);
    } finally {
      _isStarting = false;
    }
  }

  /// Stops the current listening session and finalizes recognition.
  Future<void> stopListening() async {
    _assertNotDisposed();
    if (!_isListening || _isStopping) return;

    _isStopping = true;
    try {
      await stt.stopListening();
      _isListening = false;
      if (_state == VoiceControllerState.listening) {
        _setState(VoiceControllerState.idle);
      }
    } catch (e) {
      _isListening = false;
      final err = VoiceControllerError(
        type: VoiceControllerErrorType.sttOperationFailed,
        message: 'Failed to stop listening: $e',
        originalError: e,
      );
      _emitError(err);
      _setState(VoiceControllerState.error);
    } finally {
      _isStopping = false;
    }
  }

  /// Cancels the current session immediately without emitting results.
  Future<void> cancel() async {
    _assertNotDisposed();
    if (!_isListening && _state == VoiceControllerState.idle) return;

    try {
      if (tts.isSpeaking || _state == VoiceControllerState.speaking) {
        try {
          await tts.stop();
        } catch (_) {}
      }
      await stt.cancel();
    } catch (_) {
      // Ignore cancel errors
    } finally {
      _isListening = false;
      _setState(VoiceControllerState.idle);
    }
  }

  /// Releases all adapter resources.  The controller cannot be used after this.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    if (_isListening) {
      await stt.cancel();
      _isListening = false;
    }

    await stt.dispose();

    try {
      await tts.stop();
      await tts.dispose();
    } catch (_) {
      // Ignore dispose errors
    }

    _setState(VoiceControllerState.idle);
  }

  // --------------------------------------------------------------------------
  // Internal: STT callbacks
  // --------------------------------------------------------------------------

  /// Handles intermediate transcripts from the STT adapter.
  void _onSttResult(String transcript) {
    if (_disposed || transcript.trim().isEmpty) return;
    onTranscript?.call(transcript);
    _setState(VoiceControllerState.processing);
    _processTranscript(transcript);
  }

  /// Handles the final transcript (e.g. from Whisper session.stop()).
  void _onSttFinalResult(String transcript) {
    if (_disposed || transcript.trim().isEmpty) return;
    onTranscript?.call(transcript);
    _isListening = false;
    final normalized = transcript.trim().toLowerCase();
    if (_lastDispatchedTranscript != null &&
        _lastDispatchedTranscript == normalized) {
      if (_state == VoiceControllerState.listening) {
        _setState(VoiceControllerState.idle);
      }
      return;
    }
    _setState(VoiceControllerState.processing);
    _processTranscript(transcript);
  }

  /// Handles STT-level errors.
  void _onSttError(SttFailure failure) {
    _isListening = false;
    final err = _mapSttFailure(failure);
    _emitError(err);
    _setState(VoiceControllerState.error);
  }

  // --------------------------------------------------------------------------
  // Internal: intent recognition and dispatch
  // --------------------------------------------------------------------------

  Future<void> _processTranscript(String transcript) async {
    _lastDispatchedTranscript = transcript.trim().toLowerCase();
    final result = engine.recognize(transcript);
    await _dispatchIntent(result);
  }

  Future<void> _dispatchIntent(VoiceIntentResult result) async {
    // 1. Fire the appropriate action callback FIRST (before TTS).
    //    TTS is best-effort: action must always execute.
    try {
      dynamic action;
      switch (result.intent) {
        case VoiceIntent.startGame:
          action = onStartGame?.call();
        case VoiceIntent.openMemory:
          action = onOpenMemory?.call();
        case VoiceIntent.setReminder:
          onSetReminder?.call();
          action = onSetReminderWithResult?.call(result);
        case VoiceIntent.callCaregiver:
          action = onCallCaregiver?.call();
        case VoiceIntent.checkToday:
          action = onCheckToday?.call();
        case VoiceIntent.showProgress:
          action = onShowProgress?.call();
        case VoiceIntent.unknown:
          // No action callback for unknown; TTS feedback is the only response.
          break;
      }
      if (action is Future) {
        await action;
      }
    } catch (e) {
      _emitError(VoiceControllerError(
        type: VoiceControllerErrorType.unknown,
        message: 'Action callback failed: $e',
        originalError: e,
      ));
    }

    // 2. Speak the response (best-effort, non-blocking).
    final responseText =
        _defaultResponses[result.intent] ?? _defaultResponses[VoiceIntent.unknown]!;

    await _speakResponse(responseText);
  }

  // --------------------------------------------------------------------------
  // Internal: TTS
  // --------------------------------------------------------------------------

  Future<void> _speakResponse(String text) async {
    _setState(VoiceControllerState.speaking);

    // Speak is awaited so state transitions happen in order.
    // TTS errors are reported via onError but do NOT roll back
    // already-fired action callbacks.
    await tts.speak(
      text: text,
      languageCode: languageCode,
      onDone: () {
        if (!_disposed) _setState(VoiceControllerState.idle);
      },
      onError: (TtsFailure failure) {
        if (_disposed) return;
        _emitError(VoiceControllerError(
          type: VoiceControllerErrorType.ttsOperationFailed,
          message: 'TTS speak failed: ${failure.message}',
          originalError: failure,
        ));
        // Recover to idle even after TTS error — action was already executed.
        _setState(VoiceControllerState.idle);
      },
    );
  }

  // --------------------------------------------------------------------------
  // Internal: helpers
  // --------------------------------------------------------------------------

  void _setState(VoiceControllerState next) {
    if (_state == next) return;
    _state = next;
    onStateChanged?.call(next);
  }

  void _emitError(VoiceControllerError error) {
    _lastError = error;
    onError?.call(error);
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'VoiceController has been disposed. Create a new instance.',
      );
    }
  }

  /// Maps an [SttFailure] to the controller's error vocabulary.
  VoiceControllerError _mapSttFailure(SttFailure? failure) {
    if (failure == null) {
      return const VoiceControllerError(
        type: VoiceControllerErrorType.sttInitializationFailed,
        message: 'STT initialization failed for an unknown reason.',
      );
    }

    final type = switch (failure.type) {
      SttFailureType.permissionDenied ||
      SttFailureType.permissionPermanentlyDenied =>
        VoiceControllerErrorType.microphonePermissionDenied,
      SttFailureType.languageNotSupported =>
        VoiceControllerErrorType.sttLanguageNotSupported,
      SttFailureType.initializationFailed =>
        VoiceControllerErrorType.sttInitializationFailed,
      SttFailureType.microphoneUnavailable =>
        VoiceControllerErrorType.sttInitializationFailed,
      _ => VoiceControllerErrorType.sttOperationFailed,
    };

    return VoiceControllerError(
      type: type,
      message: failure.message,
      originalError: failure,
    );
  }
}
