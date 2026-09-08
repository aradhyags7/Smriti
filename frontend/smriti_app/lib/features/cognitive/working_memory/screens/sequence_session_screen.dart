// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE CHECK SESSION SCREEN
// Full working memory game with watch → recall → adaptive loop
// Includes fatigue detection, encouragement, haptics, rest prompts
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../models/sequence_check_models.dart';
import '../engine/sequence_engine.dart';
import '../../shared/adaptive_controller.dart';
import '../../shared/fatigue_monitor.dart';
import '../../shared/encouragement_engine.dart';
import '../../shared/haptic_feedback.dart';
import '../../shared/rest_prompt_overlay.dart';
import '../../telemetry/telemetry_models.dart';
import '../../telemetry/telemetry_engine.dart';
import 'sequence_results_screen.dart';

class SequenceSessionScreen extends StatefulWidget {
  final SequenceDifficulty difficulty;

  const SequenceSessionScreen({super.key, required this.difficulty});

  @override
  State<SequenceSessionScreen> createState() => _SequenceSessionScreenState();
}

class _SequenceSessionScreenState extends State<SequenceSessionScreen>
    with TickerProviderStateMixin {
  // ── Core state ──
  late SequenceDifficultyParams _params;
  late SequenceEngine _engine;
  late AdaptiveController _adaptiveController;
  late FatigueMonitor _fatigueMonitor;
  final EncouragementEngine _encouragement = EncouragementEngine();
  final TelemetryEngine _telemetry = TelemetryEngine();

  // ── Round state ──
  SequenceRoundConfig? _currentRound;
  int _currentRoundIndex = 0;
  bool _isPlayingSequence = false;
  bool _isRecallPhase = false;
  bool _showInterference = false;
  bool _showRestPrompt = false;
  bool _isDisposed = false;
  int? _activeLitIndex;
  Color? _activeLitColor;
  final List<int> _userTapSequence = [];
  int _consecutiveCorrect = 0;
  String? _feedbackMessage;
  Timer? _feedbackTimer;

  // ── Scoring accumulators ──
  final List<bool> _roundResults = [];
  int _totalInsertions = 0;
  int _totalOmissions = 0;
  int _totalTranspositions = 0;
  int _sessionStartMs = 0;
  String _sessionId = '';
  int _lastTapTimestamp = 0;

  // ── Animation ──
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _params = SequenceDifficultyParams.forDifficulty(widget.difficulty);
    _engine = SequenceEngine(params: _params);
    _adaptiveController = AdaptiveController(
      baseDifficulty: CognitiveDifficulty.values
          .firstWhere((d) => d.name == widget.difficulty.name),
    );
    _fatigueMonitor = FatigueMonitor();
    _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    _sessionId =
        'sc_${DateTime.now().millisecondsSinceEpoch}_${widget.difficulty.name}';

    _telemetry.startSession(
      GameType.sequenceCheck,
      CognitiveDifficulty.values
          .firstWhere((d) => d.name == widget.difficulty.name),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startNextRound();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _feedbackTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startNextRound() async {
    if (!mounted || _isDisposed) return;

    if (_currentRoundIndex >= _params.maxRounds) {
      _endSession();
      return;
    }

    final round = _engine.generateRound(roundIndex: _currentRoundIndex);

    setState(() {
      _currentRound = round;
      _isPlayingSequence = true;
      _isRecallPhase = false;
      _showInterference = false;
      _userTapSequence.clear();
      _activeLitIndex = null;
      _activeLitColor = null;
      _feedbackMessage = null;
    });

    // Brief pause before playback
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isDisposed) return;

    // Play sequence
    for (int i = 0; i < round.targetSequence.length; i++) {
      if (!mounted || _isDisposed) return;

      final tileIndex = round.targetSequence[i];
      final color = round.tileColors != null
          ? round.tileColors![i]
          : const Color(0xFFA78BFA);

      // Light up tile
      setState(() {
        _activeLitIndex = tileIndex;
        _activeLitColor = color;
      });

      await Future.delayed(Duration(milliseconds: round.flashDurationMs));
      if (!mounted || _isDisposed) return;

      // Unlight tile
      setState(() {
        _activeLitIndex = null;
        _activeLitColor = null;
      });

      await Future.delayed(Duration(milliseconds: round.interFlashDelayMs));
      if (!mounted || _isDisposed) return;
    }

    // Show interference if enabled
    if (round.hasInterference) {
      setState(() {
        _showInterference = true;
        _isPlayingSequence = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted || _isDisposed) return;
      setState(() => _showInterference = false);
    }

    // Switch to recall phase
    if (!mounted || _isDisposed) return;
    setState(() {
      _isPlayingSequence = false;
      _isRecallPhase = true;
      _lastTapTimestamp = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _handleTileTap(int tileIndex) {
    if (!_isRecallPhase || _currentRound == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final reactionTime = now - _lastTapTimestamp;
    _lastTapTimestamp = now;

    // Visual feedback flash
    setState(() {
      _activeLitIndex = tileIndex;
      _activeLitColor = const Color(0xFFA78BFA);
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _activeLitIndex = null;
          _activeLitColor = null;
        });
      }
    });

    _userTapSequence.add(tileIndex);

    // Check fatigue
    final fatigued = _fatigueMonitor.recordReactionTime(reactionTime);
    if (fatigued) {
      _showRestPromptOverlay();
      return;
    }

    // Check if user has tapped enough tiles
    final expectedLength = _currentRound!.targetSequence.length;
    if (_userTapSequence.length >= expectedLength) {
      _evaluateRound();
    }
  }

  void _evaluateRound() {
    final round = _currentRound!;
    final expected = round.isReverseRecall
        ? round.targetSequence.reversed.toList()
        : round.targetSequence;

    final isCorrect = _engine.checkSequence(
      round.targetSequence,
      _userTapSequence,
      isReverse: round.isReverseRecall,
    );

    // Classify errors
    final errors = _engine.classifyErrors(expected, _userTapSequence);
    _totalInsertions += errors[SequenceErrorType.insertion] ?? 0;
    _totalOmissions += errors[SequenceErrorType.omission] ?? 0;
    _totalTranspositions += errors[SequenceErrorType.transposition] ?? 0;

    _roundResults.add(isCorrect);

    // Adaptive span adjustment
    final adjustment = _engine.reportResult(isCorrect);
    _adaptiveController.recordResult(isCorrect, _currentRoundIndex);

    // Record telemetry
    final elapsed = DateTime.now().millisecondsSinceEpoch - _sessionStartMs;
    _telemetry.recordTrial(CognitiveTrialEvent(
      eventId: 'sc_round_${_currentRoundIndex}_${DateTime.now().millisecondsSinceEpoch}',
      trialIndex: _currentRoundIndex,
      utcTimestamp: DateTime.now().toUtc().toIso8601String(),
      reactionTimeMs: _lastTapTimestamp - _sessionStartMs > 0
          ? DateTime.now().millisecondsSinceEpoch - _lastTapTimestamp
          : 0,
      isCorrect: isCorrect,
      responseType: isCorrect
          ? CognitiveResponseType.correct
          : CognitiveResponseType.incorrect,
      cognitiveLoad: round.cognitiveLoad,
      fatigueSignal: _fatigueMonitor.isFatigued,
      sessionElapsedTimeMs: elapsed,
      gameSpecific: {
        'sequenceLength': round.targetSequence.length,
        'gridSize': round.gridSize,
        'targetSequence': round.targetSequence,
        'userSequence': _userTapSequence,
        'isReverseRecall': round.isReverseRecall,
        'hasInterference': round.hasInterference,
        'hasDualTask': round.hasDualTask,
        'spanAdjustment': adjustment,
        'currentSpan': _engine.currentLength,
        'maxSpanReached': _engine.maxSpan,
        'errors': {
          'insertions': errors[SequenceErrorType.insertion],
          'omissions': errors[SequenceErrorType.omission],
          'transpositions': errors[SequenceErrorType.transposition],
        },
      },
    ));

    // Haptic + encouragement
    if (isCorrect) {
      SmritiHaptics.lightTap();
      _consecutiveCorrect++;
      if (_encouragement.shouldShowMilestone(_consecutiveCorrect)) {
        _showFeedback(_encouragement.getMilestoneMessage());
        SmritiHaptics.milestone();
        _telemetry.recordEncouragement();
      } else {
        _showFeedback(_encouragement.getSequenceEncouragement());
      }
    } else {
      SmritiHaptics.softAcknowledge();
      _consecutiveCorrect = 0;
      _showFeedback(_encouragement.getMissMessage());
    }

    _currentRoundIndex++;

    // Brief delay then next round
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && !_isDisposed) _startNextRound();
    });
  }

  void _showFeedback(String message) {
    _feedbackTimer?.cancel();
    setState(() => _feedbackMessage = message);
    _feedbackTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  void _showRestPromptOverlay() {
    setState(() => _showRestPrompt = true);
    _telemetry.recordRestBreak();
  }

  void _onRestComplete() {
    _fatigueMonitor.acknowledgeRest();
    setState(() {
      _showRestPrompt = false;
      _isRecallPhase = false;
    });
    _currentRoundIndex++;
    _startNextRound();
  }

  void _endSession() {
    String osName = 'unknown';
    try {
      if (Platform.isAndroid) osName = 'android';
      if (Platform.isIOS) osName = 'ios';
    } catch (_) {
      osName = 'mobile';
    }

    final mediaQuery = MediaQuery.of(context);
    final deviceMeta = DeviceMetadata(
      deviceModel: 'Mobile ($osName)',
      os: osName,
      osVersion: '1.0.0',
      appVersion: '1.0.0',
      screenWidthDp: mediaQuery.size.width.round(),
      screenHeightDp: mediaQuery.size.height.round(),
      devicePixelRatio: mediaQuery.devicePixelRatio,
      timezone: DateTime.now().timeZoneName,
    );

    final envelope = _telemetry.buildEnvelope(
      sessionId: _sessionId,
      userId: 'default_user',
      deviceMetadata: deviceMeta,
      adaptiveState: _adaptiveController.buildAdaptiveState(),
      maxSpan: _engine.maxSpan,
    );

    _telemetry.saveSession(envelope);
    SmritiHaptics.sessionComplete();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SequenceResultsScreen(
          envelope: envelope,
          maxSpan: _engine.maxSpan,
          roundResults: _roundResults,
          totalInsertions: _totalInsertions,
          totalOmissions: _totalOmissions,
          totalTranspositions: _totalTranspositions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final round = _currentRound;
    final gridSize = round?.gridSize ?? _params.gridSize;
    final totalTiles = gridSize * gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Status Bar ──
                _buildStatusBar(),

                // ── Grid Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: totalTiles,
                          itemBuilder: (context, index) {
                            final isLit = _activeLitIndex == index;
                            final litColor = _activeLitColor;

                            return GestureDetector(
                              onTap: () => _handleTileTap(index),
                              child: AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: isLit
                                          ? (litColor ?? const Color(0xFFA78BFA))
                                          : const Color(0xFF1E293B),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isLit
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                        width: isLit ? 3 : 1.5,
                                      ),
                                      boxShadow: isLit
                                          ? [
                                              BoxShadow(
                                                color: (litColor ??
                                                        const Color(0xFFA78BFA))
                                                    .withValues(alpha: 0.6 * _glowAnimation.value),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : [],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom instruction ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      if (round?.isReverseRecall == true && _isRecallPhase)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF87171).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '↩ TAP IN REVERSE ORDER',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        _isPlayingSequence
                            ? 'Watch the sequence...'
                            : (_showInterference
                                ? '⚡ Focus...'
                                : (_isRecallPhase
                                    ? 'Your turn — tap the tiles'
                                    : 'Get ready...')),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Interference overlay ──
            if (_showInterference)
              Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 60,
                          color: Color(0xFFF59E0B)),
                      SizedBox(height: 12),
                      Text(
                        'Hold that thought...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Feedback overlay ──
            if (_feedbackMessage != null)
              Positioned(
                bottom: 100,
                left: 40,
                right: 40,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _feedbackMessage != null ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFA78BFA), width: 1.5),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Rest prompt overlay ──
            if (_showRestPrompt)
              RestPromptOverlay(
                message: _encouragement.getRestPromptMessage(),
                onRestComplete: _onRestComplete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: _isPlayingSequence
          ? const Color(0xFFF59E0B).withValues(alpha: 0.9)
          : const Color(0xFFA78BFA).withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Round progress
          Text(
            'Round ${_currentRoundIndex + 1} / ${_params.maxRounds}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          // Span indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Span: ${_engine.currentLength}  |  Best: ${_engine.maxSpan}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.difficulty.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
