import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../components/central_target_widget.dart';
import '../components/peripheral_ring_widget.dart';
import '../engine/difficulty_controller.dart';
import '../engine/metadata_collector.dart';
import '../engine/session_timer.dart';
import '../engine/trial_generator.dart';
import '../models/pulse_trainer_models.dart';
import '../storage/data_exporter.dart';
import 'pulse_trainer_results_screen.dart';

class PulseTrainerSessionScreen extends StatefulWidget {
  final StimulusPair sessionPair;
  final DifficultyLevel difficultyLevel;
  final String userId;
  final bool researchConsentGiven;

  PulseTrainerSessionScreen({
    super.key,
    required this.sessionPair,
    this.difficultyLevel = DifficultyLevel.moderate,
    String? userId,
    this.researchConsentGiven = true,
  }) : userId = userId ?? 'usr_anon_${Random().nextInt(900000) + 100000}';

  @override
  State<PulseTrainerSessionScreen> createState() =>
      _PulseTrainerSessionScreenState();
}

class _PulseTrainerSessionScreenState
    extends State<PulseTrainerSessionScreen> {
  late DifficultyController _difficultyController;
  late SessionTimer _timer;
  late TrialGenerator _trialGenerator;
  late MetadataCollector _metadataCollector;

  late String _sessionId;
  PulseStepState _step = PulseStepState.readyCue;
  TrialConfig? _currentTrialConfig;

  final List<TapEvent> _currentTaps = [];
  int _stimulusTimestamp = 0;
  StimulusItem? _selectedCentralItem;
  int? _selectedRingIndex;

  final List<RawTrialEvent> _rawTrialsLog = [];
  bool _showRestModal = false;

  RuleMode _activeRule = RuleMode.standard;
  RuleMode? _previousRule;

  Timer? _stepTimer;

  int _getTrialsCapForLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.simple:
        return 10;
      case DifficultyLevel.moderate:
        return 15;
      case DifficultyLevel.harder:
        return 20;
    }
  }

  @override
  void initState() {
    super.initState();
    final trialsCap = _getTrialsCapForLevel(widget.difficultyLevel);

    _difficultyController = DifficultyController(level: widget.difficultyLevel);
    _timer = SessionTimer(
        maxDurationMinutes: 15, totalTrialsCap: trialsCap, restFrequency: 10);
    _trialGenerator = TrialGenerator(
        totalTrialsCount: trialsCap, level: widget.difficultyLevel);
    _metadataCollector = MetadataCollector();

    _sessionId =
        'sess_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewTrial();
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startNewTrial() {
    if (!mounted) return;

    if (_timer.isSessionComplete()) {
      _finishSession();
      return;
    }

    if (_timer.shouldShowRestPrompt()) {
      setState(() {
        _showRestModal = true;
      });
      return;
    }

    _currentTaps.clear();
    _selectedCentralItem = null;
    _selectedRingIndex = null;

    final tierMs = _difficultyController.getCurrentTierMs();

    final progress = _timer.getProgress();
    final trialCount = progress['trialsDone'] as int;

    RuleMode newRule = RuleMode.standard;
    if (widget.difficultyLevel == DifficultyLevel.harder) {
      if (trialCount >= 14) {
        newRule = RuleMode.sequence2Step;
      } else if (trialCount >= 7) {
        newRule = RuleMode.inverted;
      }
    }

    if (newRule != _activeRule) {
      _previousRule = _activeRule;
      _activeRule = newRule;
    }

    final config = _trialGenerator.generateNextTrial(
      tierMs,
      widget.sessionPair,
      _activeRule,
      _previousRule,
    );
    _currentTrialConfig = config;

    setState(() {
      _step = PulseStepState.readyCue;
    });

    final isiMs = config.difficultyParams.isiMs;

    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(milliseconds: isiMs), () {
      if (!mounted) return;
      final stimTime = DateTime.now().millisecondsSinceEpoch;
      _stimulusTimestamp = stimTime;

      setState(() {
        _step = PulseStepState.flash;
      });

      _stepTimer = Timer(Duration(milliseconds: tierMs), () {
        if (!mounted) return;

        // NO-GO Check (P3)
        if (config.isNoGo) {
          _recordNoGoOutcome(config, stimTime);
          return;
        }

        setState(() {
          _step = PulseStepState.responseCentral;
        });
      });
    });
  }

  // P4 Premature Tap Handler
  void _handlePrematureTap(TapDownDetails details) {
    if (_step != PulseStepState.readyCue) return;
    final tapTime = DateTime.now().millisecondsSinceEpoch;

    final prematureTap = TapEvent(
      tapId: 'tap_premature_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: tapTime,
      tapX: details.globalPosition.dx,
      tapY: details.globalPosition.dy,
      targetX: 0,
      targetY: 0,
      targetSizeDp: 24,
      missDistancePx: 0,
      isWrongTap: true,
      isCorrectionTap: false,
      correctionTimeMs: 0,
      interTapIntervalMs: 0,
      targetIdentifier: 'fixation_dot',
    );

    _currentTaps.add(prematureTap);

    if (_currentTrialConfig != null) {
      _recordTrialRawEvent(
        config: _currentTrialConfig!,
        stimTime: _stimulusTimestamp != 0 ? _stimulusTimestamp : tapTime,
        respTime: tapTime,
        isCorrect: false,
        responseType: ResponseType.premature,
        timeoutOmission: false,
        prematureResponse: true,
        taps: List.from(_currentTaps),
      );
    }

    _stepTimer?.cancel();
    _stepTimer = Timer(const Duration(milliseconds: 600), () {
      _startNewTrial();
    });
  }

  // Response Step 1: Central Choice
  void _handleCentralChoice(StimulusItem item, TapDownDetails details) {
    if (_step != PulseStepState.responseCentral || _currentTrialConfig == null) {
      return;
    }
    final tapTime = DateTime.now().millisecondsSinceEpoch;

    final isWrong = item.label != _currentTrialConfig!.targetCentralItem.label;

    final centralTap = TapEvent(
      tapId: 'tap_central_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: tapTime,
      tapX: details.globalPosition.dx,
      tapY: details.globalPosition.dy,
      targetX: 0,
      targetY: 0,
      targetSizeDp: _currentTrialConfig!.difficultyParams.targetSizeDp,
      missDistancePx: isWrong ? 45 : 0,
      isWrongTap: isWrong,
      isCorrectionTap: false,
      correctionTimeMs: 0,
      interTapIntervalMs: 0,
      targetIdentifier: item.label,
    );

    _currentTaps.add(centralTap);
    _selectedCentralItem = item;

    setState(() {
      _step = PulseStepState.responseRing;
    });
  }

  // Response Step 2: Peripheral Ring Choice
  void _handleRingChoice(int ringIdx, int ringDeg, TapDownDetails details,
      double targetX, double targetY) {
    if (_step != PulseStepState.responseRing || _currentTrialConfig == null) {
      return;
    }
    final respTime = DateTime.now().millisecondsSinceEpoch;

    final isTargetHit = ringIdx == _currentTrialConfig!.targetRingIndex;
    final tapX = details.globalPosition.dx;
    final tapY = details.globalPosition.dy;
    final missDistancePx =
        sqrt(pow(tapX - targetX, 2) + pow(tapY - targetY, 2)).roundToDouble();

    final prevTap = _currentTaps.isNotEmpty ? _currentTaps.last : null;
    final interTapIntervalMs =
        prevTap != null ? respTime - prevTap.timestamp : 0;

    final ringTap = TapEvent(
      tapId: 'tap_ring_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: respTime,
      tapX: tapX,
      tapY: tapY,
      targetX: targetX,
      targetY: targetY,
      targetSizeDp: _currentTrialConfig!.difficultyParams.targetSizeDp,
      missDistancePx: missDistancePx,
      isWrongTap: !isTargetHit,
      isCorrectionTap: false,
      correctionTimeMs: 0,
      interTapIntervalMs: interTapIntervalMs,
      targetIdentifier: 'ring_pos_$ringIdx',
    );

    final updatedTaps = List<TapEvent>.from(_currentTaps)..add(ringTap);
    _selectedRingIndex = ringIdx;

    final correctCentral = _selectedCentralItem?.label ==
        _currentTrialConfig!.targetCentralItem.label;
    final correctRing = isTargetHit;
    final isFullyCorrect = correctCentral && correctRing;

    ResponseType responseType =
        isFullyCorrect ? ResponseType.goCorrect : ResponseType.wrongTarget;

    _difficultyController.registerTrialResult(isFullyCorrect);
    _timer.recordTrialCompletion();

    _recordTrialRawEvent(
      config: _currentTrialConfig!,
      stimTime: _stimulusTimestamp,
      respTime: respTime,
      isCorrect: isFullyCorrect,
      responseType: responseType,
      timeoutOmission: false,
      prematureResponse: false,
      taps: updatedTaps,
    );

    _stepTimer?.cancel();
    _stepTimer = Timer(const Duration(milliseconds: 600), () {
      _startNewTrial();
    });
  }

  void _recordNoGoOutcome(TrialConfig config, int stimTime) {
    final respTime = DateTime.now().millisecondsSinceEpoch;
    _difficultyController.registerTrialResult(true);
    _timer.recordTrialCompletion();

    _recordTrialRawEvent(
      config: config,
      stimTime: stimTime,
      respTime: respTime,
      isCorrect: true,
      responseType: ResponseType.noGoCorrectStop,
      timeoutOmission: false,
      prematureResponse: false,
      taps: [],
    );

    _stepTimer?.cancel();
    _stepTimer = Timer(const Duration(milliseconds: 600), () {
      _startNewTrial();
    });
  }

  void _recordTrialRawEvent({
    required TrialConfig config,
    required int stimTime,
    required int respTime,
    required bool isCorrect,
    required ResponseType responseType,
    required bool timeoutOmission,
    required bool prematureResponse,
    required List<TapEvent> taps,
  }) {
    final reactionTimeMs = max(0, respTime - stimTime);
    final progress = _timer.getProgress();

    final rawEvent = RawTrialEvent(
      sessionId: _sessionId,
      eventId:
          'evt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      trialIndex: config.trialIndex,
      utcTimestamp: DateTime.now().toUtc().toIso8601String(),
      stimulusTimestamp: stimTime,
      responseTimestamp: respTime,
      reactionTimeMs: reactionTimeMs,
      isCorrect: isCorrect,
      responseType: responseType,
      timeoutOmission: timeoutOmission,
      prematureResponse: prematureResponse,
      taps: taps,
      trialType: config.trialType,
      difficultyParams: config.difficultyParams,
      sessionElapsedTimeMs: (progress['elapsedSeconds'] as int) * 1000,
      previousRule: config.previousRuleName?.name,
      currentRule: config.ruleName.name,
      isPostRuleChangeTrial: config.previousRuleName != null &&
          config.previousRuleName != config.ruleName,
      expectedSequence: config.expectedSequence,
      actualSequence: taps.map((t) => t.targetIdentifier).toList(),
    );

    _rawTrialsLog.add(rawEvent);
  }

  void _resumeFromRest() {
    _timer.dismissRestPrompt();
    setState(() {
      _showRestModal = false;
    });
    _startNewTrial();
  }

  Future<void> _finishSession() async {
    setState(() {
      _step = PulseStepState.finished;
    });

    final thresholdMs = _difficultyController.calculateThresholdMs();
    final metadata = _metadataCollector.collectMetadata(context);

    final sessionData = PulseTrainerSessionData(
      sessionId: _sessionId,
      userId: widget.userId,
      metadata: metadata,
      pairId: widget.sessionPair.id,
      trials: List.from(_rawTrialsLog),
      thresholdMs: thresholdMs,
      researchConsentGiven: widget.researchConsentGiven,
      difficultyLevel: widget.difficultyLevel,
    );

    await LocalEventStorage.saveSession(sessionData);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PulseTrainerResultsScreen(sessionData: sessionData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timer.getProgress();
    final trialsDone = progress['trialsDone'] as int;
    final totalTrials = progress['totalTrials'] as int;

    final screenSize = MediaQuery.of(context).size;
    final responsiveRadius = min(screenSize.width * 0.38, 155.0);

    final positionsDegree = widget.difficultyLevel == DifficultyLevel.simple
        ? const [0, 90, 180, 270]
        : const [0, 45, 90, 135, 180, 225, 270, 315];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Exit',
                            style:
                                TextStyle(color: Color(0xFF94A3B8), fontSize: 18)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Trial ${trialsDone + 1} / $totalTrials',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.difficultyLevel.name.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Central Game Play Area
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PeripheralRingWidget(
                        mode: _step == PulseStepState.flash
                            ? 'flash'
                            : (_step == PulseStepState.responseRing
                                ? 'interactive'
                                : 'idle'),
                        positionsDegree: positionsDegree,
                        radius: responsiveRadius,
                        flashedIndex: _currentTrialConfig?.targetRingIndex,
                        distractorIndex:
                            _currentTrialConfig?.distractorRingIndex,
                        selectedIndex: _selectedRingIndex,
                        targetSizeDp:
                            _currentTrialConfig?.difficultyParams.targetSizeDp ??
                                52.0,
                        onSelectPosition: _handleRingChoice,
                      ),
                      CentralTargetWidget(
                        mode: _step == PulseStepState.readyCue
                            ? 'fixation'
                            : (_step == PulseStepState.flash
                                ? 'flash'
                                : (_step == PulseStepState.responseCentral
                                    ? 'choice'
                                    : 'hidden')),
                        activeItem: _currentTrialConfig?.targetCentralItem,
                        choiceOptionA: widget.sessionPair.imageA,
                        choiceOptionB: widget.sessionPair.imageB,
                        targetSizeDp:
                            _currentTrialConfig?.difficultyParams.targetSizeDp ??
                                110.0,
                        onSelectChoice: _handleCentralChoice,
                        onPrematureTap: _handlePrematureTap,
                      ),
                      Positioned(
                        bottom: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Text(
                            _getInstructionText(),
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // P10 Rest Break Modal Dialog (with fix)
            if (_showRestModal)
              Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Take a Breath 🌿',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Great work so far! Rest your eyes before continuing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _resumeFromRest,
                          child: const Text('Tap When Ready',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_step) {
      case PulseStepState.readyCue:
        return 'Get ready... (Wait for flash)';
      case PulseStepState.flash:
        return (_currentTrialConfig?.isNoGo ?? false)
            ? 'STOP! Do not tap'
            : 'Focus!';
      case PulseStepState.responseCentral:
        return 'Select the central image';
      case PulseStepState.responseRing:
        return 'Tap the outer ring position';
      case PulseStepState.finished:
        return 'Session complete!';
    }
  }
}
