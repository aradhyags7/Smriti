import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smriti_app/features/reminders/reminder_notification_service.dart';
import 'package:smriti_app/features/reminders/reminder_service.dart';
import 'package:smriti_app/features/reminders/reminders_screen.dart';
import 'package:smriti_app/features/reminders/voice_reminder_bridge.dart';
import 'package:smriti_app/features/voice/intent_engine.dart';
import 'package:smriti_app/features/voice/stt_service.dart';
import 'package:smriti_app/features/voice/tts_service.dart';
import 'package:smriti_app/features/voice/voice_controller.dart';

/// Root application widget for Smriti with minimal Voice Testing UI.
class SmritiApp extends StatelessWidget {
  final FutureOr<VoiceController> Function()? voiceControllerFactory;
  final IReminderService? reminderService;
  final IReminderNotificationService? notificationService;
  final DateTime Function()? nowProvider;

  const SmritiApp({
    super.key,
    this.voiceControllerFactory,
    this.reminderService,
    this.notificationService,
    this.nowProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smriti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: VoiceTestScreen(
        voiceControllerFactory: voiceControllerFactory,
        reminderService: reminderService,
        notificationService: notificationService,
        nowProvider: nowProvider,
      ),
    );
  }
}

/// Minimal Voice Testing UI screen for on-device testing.
class VoiceTestScreen extends StatefulWidget {
  final FutureOr<VoiceController> Function()? voiceControllerFactory;
  final IReminderService? reminderService;
  final IReminderNotificationService? notificationService;
  final DateTime Function()? nowProvider;

  const VoiceTestScreen({
    super.key,
    this.voiceControllerFactory,
    this.reminderService,
    this.notificationService,
    this.nowProvider,
  });

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  late final IReminderService _reminderService;
  late final IReminderNotificationService _notificationService;
  VoiceReminderDraft? _lastReminderDraft;

  VoiceController? _controller;
  bool _isInitializing = false;
  VoiceControllerState _state = VoiceControllerState.idle;
  String _statusText = 'Idle';
  String _transcript = '';
  String _recognizedIntent = 'NONE';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _reminderService = widget.reminderService ?? ReminderService();
    _notificationService = widget.notificationService ?? ReminderNotificationService();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _wireController(VoiceController controller) {
    controller.onStateChanged = (state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        if (state == VoiceControllerState.listening ||
            state == VoiceControllerState.processing ||
            state == VoiceControllerState.error) {
          _statusText = _formatStateName(state);
        } else if (state == VoiceControllerState.idle) {
          if (!_statusText.startsWith('Reminder') &&
              !_statusText.startsWith('Time needed') &&
              !_statusText.startsWith('Add reminder')) {
            _statusText = _formatStateName(state);
          }
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

    controller.onStartGame = () => _setIntent('START_GAME');
    controller.onOpenMemory = () => _setIntent('OPEN_MEMORY');
    controller.onSetReminder = () => _setIntent('SET_REMINDER');
    controller.onSetReminderWithResult = (result) async {
      _setIntent('SET_REMINDER');
      await _handleVoiceReminder(result);
    };
    controller.onCallCaregiver = () => _setIntent('CALL_CAREGIVER');
    controller.onCheckToday = () => _setIntent('CHECK_TODAY');
    controller.onShowProgress = () => _setIntent('SHOW_PROGRESS');
  }

  Future<void> _handleVoiceReminder(VoiceIntentResult result) async {
    final draft = VoiceReminderBridge.parse(
      result.transcript,
      nowProvider: widget.nowProvider,
    );

    if (!mounted) return;
    setState(() {
      _lastReminderDraft = draft;
    });

    if (widget.reminderService == null && widget.notificationService == null) {
      // In standalone voice testing UI mode without reminder services configured:
      // record the draft without navigating.
      return;
    }

    if (draft.hasEnoughInformation) {
      final model = draft.toReminderModel(nowProvider: widget.nowProvider);
      if (model != null) {
        bool persisted = false;
        try {
          await _reminderService.createReminder(model);
          persisted = true;
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to save reminder: $e';
            });
          }
          return;
        }

        if (persisted) {
          bool scheduled = false;
          try {
            scheduled = await _notificationService.scheduleReminder(model);
          } catch (_) {
            scheduled = false;
          }

          if (mounted) {
            setState(() {
              if (scheduled) {
                _statusText = 'Reminder created: "${model.title}"';
              } else {
                _statusText = 'Reminder saved (notification failed)';
              }
            });
          }
        }
      }
    } else {
      // Time is missing or title is missing: DO NOT schedule.
      if (mounted) {
        setState(() {
          _statusText = draft.isTimeMissing
              ? 'Time needed for: "${draft.title ?? 'reminder'}"'
              : 'Add reminder details';
        });

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

  void _setIntent(String intentName) {
    if (!mounted) return;
    setState(() {
      _recognizedIntent = intentName;
    });
  }

  String _formatStateName(VoiceControllerState state) {
    switch (state) {
      case VoiceControllerState.idle:
        return 'Idle';
      case VoiceControllerState.listening:
        return 'Listening';
      case VoiceControllerState.processing:
        return 'Processing';
      case VoiceControllerState.speaking:
        return 'Speaking';
      case VoiceControllerState.error:
        return 'Error';
    }
  }

  Future<void> _handleMicPressed() async {
    if (_isInitializing) return;

    try {
      if (_controller == null) {
        setState(() {
          _isInitializing = true;
          _statusText = 'Initializing...';
          _errorMessage = null;
        });

        try {
          if (widget.voiceControllerFactory != null) {
            _controller = await widget.voiceControllerFactory!();
          } else {
            // Lazy runtime initialization: resolve model and instantiate Whisper
            final sttAdapter = await WhisperSttAdapter.createWithResolvedModelPath();
            final ttsAdapter = IndicTtsAdapter();
            final intentEngine = IntentEngine();

            _controller = VoiceController(
              stt: sttAdapter,
              tts: ttsAdapter,
              engine: intentEngine,
            );
          }

          _wireController(_controller!);
        } finally {
          _isInitializing = false;
        }
      }

      if (_controller!.isListening) {
        await _controller!.stopListening();
      } else {
        setState(() {
          _errorMessage = null;
        });
        await _controller!.startListening();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusText = 'Error';
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _state == VoiceControllerState.listening;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smriti'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Smriti',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Voice & Reminders',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Status Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _statusText,
                        key: const Key('status_label'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_state),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transcript Area
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transcript',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _transcript.isEmpty ? '(No transcript yet)' : _transcript,
                        key: const Key('transcript_area'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Last Recognized Intent Area
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Recognized Intent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recognizedIntent,
                        key: const Key('intent_area'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_lastReminderDraft != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice Reminder Draft',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Title: ${_lastReminderDraft!.title ?? "(missing)"}\n'
                          'Scheduled: ${_lastReminderDraft!.scheduledAt != null ? _lastReminderDraft!.scheduledAt.toString() : "(time missing)"}\n'
                          'Recurrence: ${_lastReminderDraft!.recurrence.name}\n'
                          'Ready: ${_lastReminderDraft!.hasEnoughInformation}',
                          key: const Key('reminder_draft_area'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  key: const Key('error_area'),
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Microphone Button
              Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    key: const Key('mic_button'),
                    onPressed: _isInitializing ? null : _handleMicPressed,
                    backgroundColor: isListening ? Colors.red : Colors.deepPurple,
                    child: _isInitializing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            size: 36,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(VoiceControllerState state) {
    switch (state) {
      case VoiceControllerState.idle:
        return Colors.blueGrey;
      case VoiceControllerState.listening:
        return Colors.red;
      case VoiceControllerState.processing:
        return Colors.orange;
      case VoiceControllerState.speaking:
        return Colors.green;
      case VoiceControllerState.error:
        return Colors.redAccent;
    }
  }
}
