import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/daily_games_screen.dart';
import '../reminders/reminder_notification_service.dart';
import '../reminders/reminder_service.dart';
import '../reminders/reminders_screen.dart';
import '../reminders/voice_reminder_bridge.dart';
import 'intent_engine.dart';
import 'stt_service.dart';
import 'tts_service.dart';
import 'voice_controller.dart';

/// An elder-accessible, interactive Voice Assistant bottom sheet for Smriti.
///
/// Features:
/// - Real-time animated microphone button
/// - Live transcription display
/// - Clear visual status badge (Listening, Processing, Speaking, Idle)
/// - Direct execution of recognized intents (Daily Games, Reminders, Care Circle)
class VoiceAssistantSheet extends StatefulWidget {
  final FutureOr<VoiceController> Function()? controllerFactory;
  final IReminderService? reminderService;
  final IReminderNotificationService? notificationService;
  final VoidCallback? onOpenCareCircle;

  const VoiceAssistantSheet({
    super.key,
    this.controllerFactory,
    this.reminderService,
    this.notificationService,
    this.onOpenCareCircle,
  });

  /// Displays the Voice Assistant modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    FutureOr<VoiceController> Function()? controllerFactory,
    IReminderService? reminderService,
    IReminderNotificationService? notificationService,
    VoidCallback? onOpenCareCircle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceAssistantSheet(
        controllerFactory: controllerFactory,
        reminderService: reminderService,
        notificationService: notificationService,
        onOpenCareCircle: onOpenCareCircle,
      ),
    );
  }

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late final IReminderService _reminderService;
  late final IReminderNotificationService _notificationService;

  VoiceController? _controller;
  bool _isInitializing = false;
  VoiceControllerState _state = VoiceControllerState.idle;
  String _statusText = 'Tap the microphone to speak';
  String _transcript = '';
  String? _recognizedIntent;
  String? _actionFeedback;
  String? _errorMessage;

  late final AnimationController _pulseAnimController;
  late final Animation<double> _pulseScaleAnimation;

  @override
  void initState() {
    super.initState();
    _reminderService = widget.reminderService ?? ReminderService();
    _notificationService =
        widget.notificationService ?? ReminderNotificationService();

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _initController();
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initController() async {
    if (_isInitializing || _controller != null) return;
    setState(() {
      _isInitializing = true;
      _statusText = 'Starting Voice Engine...';
    });

    try {
      VoiceController ctrl;
      if (widget.controllerFactory != null) {
        ctrl = await widget.controllerFactory!();
      } else {
        final stt = await WhisperSttAdapter.createWithResolvedModelPath();
        final tts = IndicTtsAdapter();
        ctrl = VoiceController(
          stt: stt,
          tts: tts,
          engine: IntentEngine(),
        );
      }

      _wireController(ctrl);
      await ctrl.initialize();

      if (mounted) {
        setState(() {
          _controller = ctrl;
          _isInitializing = false;
          _statusText = 'Listening for your command...';
        });
        // Auto-start listening on sheet open for elder convenience
        await ctrl.startListening();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Could not start microphone: $e';
          _statusText = 'Voice Assistant unavailable';
        });
      }
    }
  }

  void _wireController(VoiceController controller) {
    controller.onStateChanged = (state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        switch (state) {
          case VoiceControllerState.idle:
            if (_actionFeedback == null) {
              _statusText = 'Tap the microphone to speak';
            }
            break;
          case VoiceControllerState.listening:
            _statusText = 'Listening... Speak clearly';
            _errorMessage = null;
            break;
          case VoiceControllerState.processing:
            _statusText = 'Thinking... Processing command';
            break;
          case VoiceControllerState.speaking:
            _statusText = 'Speaking response...';
            break;
          case VoiceControllerState.error:
            _statusText = 'Encountered an issue';
            break;
        }
      });
    };

    controller.onTranscript = (transcript) {
      if (!mounted) return;
      setState(() {
        _transcript = transcript;
      });
    };

    controller.onError = (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _statusText = 'Error';
      });
    };

    // Intent execution handlers
    controller.onStartGame = () => _handleStartGame();
    controller.onShowProgress = () => _handleShowProgress();
    controller.onCallCaregiver = () => _handleCallCaregiver();
    controller.onCheckToday = () => _handleCheckToday();
    controller.onSetReminderWithResult = (result) => _handleSetReminder(result);
  }

  Future<void> _handleStartGame() async {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'START_GAME';
      _actionFeedback = 'Opening Memory Games...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyGamesScreen()),
      );
    }
  }

  Future<void> _handleShowProgress() async {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'SHOW_PROGRESS';
      _actionFeedback = 'Opening Daily Progress...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyGamesScreen()),
      );
    }
  }

  Future<void> _handleCallCaregiver() async {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'CALL_CAREGIVER';
      _actionFeedback = 'Connecting to Care Circle...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
      if (widget.onOpenCareCircle != null) {
        widget.onOpenCareCircle!();
      }
    }
  }

  Future<void> _handleCheckToday() async {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'CHECK_TODAY';
      _actionFeedback = 'Checking today\'s activities...';
    });
  }

  Future<void> _handleSetReminder(VoiceIntentResult result) async {
    final draft = VoiceReminderBridge.parse(result.transcript);

    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'SET_REMINDER';
    });

    if (draft.hasEnoughInformation) {
      final model = draft.toReminderModel();
      if (model != null) {
        try {
          await _reminderService.createReminder(model);
          await _notificationService.scheduleReminder(model);
          if (mounted) {
            setState(() {
              _actionFeedback = 'Scheduled reminder: "${model.title}"';
            });
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Could not save reminder: $e';
            });
          }
        }
      }
    } else {
      setState(() {
        _actionFeedback = 'Opening reminders to complete details...';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RemindersScreen(
              reminderService: _reminderService,
              notificationService: _notificationService,
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleListening() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    if (_state == VoiceControllerState.listening) {
      await ctrl.stopListening();
    } else {
      setState(() {
        _transcript = '';
        _actionFeedback = null;
        _errorMessage = null;
      });
      await ctrl.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _state == VoiceControllerState.listening;
    final isProcessing = _state == VoiceControllerState.processing;
    final isSpeaking = _state == VoiceControllerState.speaking;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F8F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF23654D).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFF23654D),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Smriti Voice Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F4D36),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF5A7264)),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close Assistant',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isListening
                  ? const Color(0xFFA6EBCF).withValues(alpha: 0.6)
                  : isProcessing
                      ? const Color(0xFFFED7AA)
                      : isSpeaking
                          ? const Color(0xFFB4EBA3)
                          : const Color(0xFFEFECE1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isListening)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                Flexible(
                  child: Text(
                    _statusText,
                    key: const Key('sheet_status_text'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F4D36),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transcript Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAE6D6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOU SAID:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A7264),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _transcript.isNotEmpty
                      ? _transcript
                      : 'Say: "Start the game" • "Show my progress" • "Remind me to drink water"',
                  key: const Key('sheet_transcript_text'),
                  style: TextStyle(
                    fontSize: _transcript.isNotEmpty ? 17 : 14,
                    fontWeight: _transcript.isNotEmpty
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: _transcript.isNotEmpty
                        ? const Color(0xFF1F4D36)
                        : Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
                if (_recognizedIntent != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'INTENT: $_recognizedIntent',
                      key: const Key('sheet_intent_tag'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF23654D),
                      ),
                    ),
                  ),
                ],
                if (_actionFeedback != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: Color(0xFF23654D)),
                      const SizedBox(width: 6),
                      Text(
                        _actionFeedback!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF23654D),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Central Pulsing Microphone Action Button
          Center(
            child: ScaleTransition(
              scale: isListening ? _pulseScaleAnimation : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? Colors.redAccent
                        : const Color(0xFF23654D),
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.redAccent : const Color(0xFF23654D))
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: isListening ? 4 : 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 38,
                    key: const Key('sheet_mic_icon'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isListening ? 'Tap to finish' : 'Tap to speak',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A7264),
            ),
          ),
        ],
      ),
    );
  }
}
