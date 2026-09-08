import 'dart:async';
import 'package:flutter/material.dart';
import '../../screens/daily_games_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/pulse_trainer_screen.dart';
import '../cognitive/calibration/screens/daily_calibration_screen.dart';
import '../cognitive/spatial_memory/screens/wayfinder_home_screen.dart';
import '../cognitive/working_memory/screens/sequence_home_screen.dart';
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
/// - Quick suggestion chips for rapid intent execution
/// - Text input option for noisy environments / devices without microphone
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
  bool _showTextInput = false;
  final TextEditingController _textController = TextEditingController();

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
    _textController.dispose();
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
        final stt = await createAdaptiveSttAdapter();
        final tts = await createAdaptiveTtsAdapter();
        ctrl = VoiceController(
          stt: stt,
          tts: tts,
          engine: IntentEngine(),
        );
      }

      _wireController(ctrl);
      final ok = await ctrl.initialize();

      if (mounted) {
        setState(() {
          _controller = ctrl;
          _isInitializing = false;
          _statusText = ok ? 'Listening for your command...' : 'Tap the microphone or a suggestion';
        });
        if (ok) {
          // Auto-start listening on sheet open for elder convenience
          await ctrl.startListening();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Microphone notice: $e';
          _statusText = 'Tap a suggestion or type below';
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
      // Do not overwrite successful action feedback if error is just best-effort TTS
      if (error.type == VoiceControllerErrorType.ttsOperationFailed) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _statusText = 'Error';
      });
    };

    // Intent execution handlers
    controller.onStartGame = () => _handleStartGame();
    controller.onStartGameWithResult = (result) => _handleStartGame(result);
    controller.onOpenMemory = () => _handleOpenMemory();
    controller.onShowProgress = () => _handleShowProgress();
    controller.onCallCaregiver = () => _handleCallCaregiver();
    controller.onCheckToday = () => _handleCheckToday();
    controller.onSetReminderWithResult = (result) => _handleSetReminder(result);
    controller.onUnknownIntent = (result) => _handleUnknownIntent(result);
  }

  Future<void> _handleStartGame([VoiceIntentResult? result]) async {
    if (!mounted) return;
    final gameType = result?.parameters?['gameType'] as String? ?? 'daily';

    String feedback;
    Widget targetScreen;

    switch (gameType) {
      case 'pulse':
        feedback = 'Opening Pulse Trainer...';
        targetScreen = const PulseTrainerScreen();
        break;
      case 'wayfinder':
        feedback = 'Opening Wayfinder Memory Walk...';
        targetScreen = const WayfinderHomeScreen();
        break;
      case 'sequence':
        feedback = 'Opening Sequence Check...';
        targetScreen = const SequenceHomeScreen();
        break;
      case 'calibration':
        feedback = 'Opening Daily Calibration...';
        targetScreen = const DailyCalibrationScreen();
        break;
      case 'more':
        feedback = 'Opening Smriti Arcade...';
        targetScreen = const HomeScreen();
        break;
      case 'daily':
      default:
        feedback = 'Opening Daily Games...';
        targetScreen = const DailyGamesScreen();
        break;
    }

    setState(() {
      _recognizedIntent = 'START_GAME';
      _actionFeedback = feedback;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    }
  }

  void _handleUnknownIntent(VoiceIntentResult result) {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'UNKNOWN';
      _actionFeedback =
          'Could not understand command. Tap a suggestion below or try: "start game", "call caregiver", or "remind me to..."';
    });
  }

  Future<void> _handleOpenMemory() async {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = 'OPEN_MEMORY';
      _actionFeedback = 'Opening Memory Vault...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory Vault: Your family photos and voice memories are saved.'),
          backgroundColor: Color(0xFF23654D),
          duration: Duration(seconds: 3),
        ),
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
      _actionFeedback = "Checking today's activities & reminders...";
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
      if (mounted && _transcript.trim().isNotEmpty && _recognizedIntent == null) {
        _triggerCommand(_transcript.trim());
      }
    } else {
      setState(() {
        _transcript = '';
        _actionFeedback = null;
        _errorMessage = null;
        _recognizedIntent = null;
      });
      await ctrl.startListening();
    }
  }

  void _triggerCommand(String text) {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      _transcript = text;
      _actionFeedback = null;
      _errorMessage = null;
    });
    ctrl.processTranscript(text);
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
                color: const Color(0xFFD6D0BE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
                      color: const Color(0xFFA6EBCF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Color(0xFF1F4D36),
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
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showTextInput ? Icons.mic_rounded : Icons.keyboard_rounded,
                      color: const Color(0xFF5A7264),
                    ),
                    tooltip: _showTextInput ? 'Switch to Mic' : 'Type Command',
                    onPressed: () {
                      setState(() {
                        _showTextInput = !_showTextInput;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5A7264)),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close Assistant',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 16),

          // Transcript Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 72),
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
                      : 'Say: "Start game" • "Show my progress" • "Remind me to drink water"',
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
                      Expanded(
                        child: Text(
                          _actionFeedback!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF23654D),
                          ),
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
          const SizedBox(height: 16),

          // Central Mic Button OR Text Input Row
          if (_showTextInput) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD7C5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.keyboard_voice_rounded, color: Color(0xFF23654D), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type: "start game", "call caregiver"...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _triggerCommand(val.trim());
                          _textController.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF23654D)),
                    onPressed: () {
                      if (_textController.text.trim().isNotEmpty) {
                        _triggerCommand(_textController.text.trim());
                        _textController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: ScaleTransition(
                scale: isListening ? _pulseScaleAnimation : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 76,
                    height: 76,
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
                      size: 36,
                      key: const Key('sheet_mic_icon'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isListening ? 'Tap to finish' : 'Tap to speak',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A7264),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Quick Suggestion Chips
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QUICK VOICE COMMANDS:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A7264),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip(
                  icon: Icons.extension_rounded,
                  label: 'Start Games',
                  command: 'start game',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.speed_rounded,
                  label: 'Pulse Trainer',
                  command: 'open pulse trainer',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.explore_rounded,
                  label: 'Wayfinder',
                  command: 'open wayfinder',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.grid_view_rounded,
                  label: 'Sequence Check',
                  command: 'open sequence check',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.medication_rounded,
                  label: 'Medicine Remainder',
                  command: 'set my remainder for medicines at 8 pm',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.alarm_rounded,
                  label: 'Water at 8 PM',
                  command: 'remind me at 8 pm to drink water',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.support_agent_rounded,
                  label: 'Call Caregiver',
                  command: 'call caregiver',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.calendar_today_rounded,
                  label: "Today's Routine",
                  command: 'check today',
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  icon: Icons.trending_up_rounded,
                  label: 'My Progress',
                  command: 'show progress',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required IconData icon,
    required String label,
    required String command,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF1F4D36)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F4D36),
        ),
      ),
      backgroundColor: const Color(0xFFF1EFE3),
      side: const BorderSide(color: Color(0xFFDDD7C5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _triggerCommand(command),
    );
  }
}
