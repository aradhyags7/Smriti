// ─────────────────────────────────────────────────────────────────────────────
// WAYFINDER SESSION SCREEN
// Full spatial memory game with preview → recall → scoring loop
// Includes adaptive difficulty, fatigue detection, encouragement, haptics
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../models/wayfinder_models.dart';
import '../engine/wayfinder_engine.dart';
import '../engine/spatial_scoring.dart';
import '../services/wayfinder_audio_service.dart';
import '../../shared/adaptive_controller.dart';
import '../../shared/fatigue_monitor.dart';
import '../../shared/encouragement_engine.dart';
import '../../shared/haptic_feedback.dart';
import '../../shared/rest_prompt_overlay.dart';
import '../../telemetry/telemetry_models.dart';
import '../../telemetry/telemetry_engine.dart';
import 'wayfinder_results_screen.dart';

class WayfinderSessionScreen extends StatefulWidget {
  final WayfinderDifficulty difficulty;

  const WayfinderSessionScreen({super.key, required this.difficulty});

  @override
  State<WayfinderSessionScreen> createState() => _WayfinderSessionScreenState();
}

class _WayfinderSessionScreenState extends State<WayfinderSessionScreen>
    with TickerProviderStateMixin {
  // ── Core state ──
  late WayfinderDifficultyParams _params;
  late WayfinderEngine _engine;
  late AdaptiveController _adaptiveController;
  late FatigueMonitor _fatigueMonitor;
  final EncouragementEngine _encouragement = EncouragementEngine();
  final TelemetryEngine _telemetry = TelemetryEngine();

  // ── Trial state ──
  WayfinderTrialConfig? _currentTrial;
  int _currentTrialIndex = 0;
  bool _isPreviewPhase = true;
  bool _showRestPrompt = false;
  int _previewCountdown = 0;
  Timer? _previewTimer;
  final List<int> _userTapSequence = [];
  int _consecutiveCorrect = 0;
  String? _feedbackMessage;
  Timer? _feedbackTimer;

  // ── Scoring accumulators ──
  final List<double> _trialScores = [];
  final List<SpatialTapEvent> _allTapEvents = [];
  int _sessionStartMs = 0;
  String _sessionId = '';

  // ── Animation ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _params = WayfinderDifficultyParams.forDifficulty(widget.difficulty);
    _engine = WayfinderEngine(params: _params);
    _adaptiveController = AdaptiveController(
      baseDifficulty: CognitiveDifficulty.values
          .firstWhere((d) => d.name == widget.difficulty.name),
    );
    _fatigueMonitor = FatigueMonitor();
    _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    _sessionId =
        'wf_${DateTime.now().millisecondsSinceEpoch}_${widget.difficulty.name}';

    // Start telemetry
    _telemetry.startSession(
      GameType.wayfinder,
      CognitiveDifficulty.values
          .firstWhere((d) => d.name == widget.difficulty.name),
    );

    // Pulse animation for active node
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WayfinderAudioService().initAndPlay();

    _startNextTrial();
  }

  @override
  void dispose() {
    WayfinderAudioService().stop();
    _previewTimer?.cancel();
    _feedbackTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startNextTrial() {
    if (_currentTrialIndex >= _params.trialsPerSession) {
      _endSession();
      return;
    }

    // Generate trial with adaptive preview timing
    final adaptivePreview = _engine.computeAdaptivePreview(
      _params.previewDurationMs,
      _adaptiveController.rollingAccuracy,
    );

    final trial = _engine.generateTrial(
      trialIndex: _currentTrialIndex,
      adjustedPreviewMs: adaptivePreview,
    );

    setState(() {
      _currentTrial = trial;
      _isPreviewPhase = true;
      _userTapSequence.clear();
      _previewCountdown = (trial.previewDurationMs / 1000).ceil();
      _feedbackMessage = null;
    });

    _startPreviewCountdown();
  }

  void _startPreviewCountdown() {
    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_previewCountdown > 1) {
        setState(() => _previewCountdown--);
      } else {
        timer.cancel();
        setState(() {
          _previewCountdown = 0;
          _isPreviewPhase = false;
        });
      }
    });
  }

  void _handleNodeTap(int nodeIndex) {
    if (_isPreviewPhase || _currentTrial == null) return;
    if (_userTapSequence.contains(nodeIndex)) return; // Already tapped

    final trial = _currentTrial!;
    final tapTimestamp = DateTime.now().millisecondsSinceEpoch;
    final elapsed = tapTimestamp - _sessionStartMs;

    // Find the tapped node
    final tappedNode = trial.allNodes.firstWhere((n) => n.index == nodeIndex);
    final expectedIndex = _userTapSequence.length < trial.targetPath.length
        ? trial.targetPath[_userTapSequence.length]
        : -1;
    final expectedNode = expectedIndex >= 0
        ? trial.allNodes.firstWhere((n) => n.index == expectedIndex)
        : null;

    final isCorrect = nodeIndex == expectedIndex;
    final distError = expectedNode != null
        ? SpatialScoring.euclideanDistance(
            tappedNode.relX, tappedNode.relY,
            expectedNode.relX, expectedNode.relY)
        : 1.0;

    // Record tap event
    final tapEvent = SpatialTapEvent(
      tapId: 'tap_$tapTimestamp',
      timestamp: tapTimestamp,
      tapX: tappedNode.relX,
      tapY: tappedNode.relY,
      targetX: expectedNode?.relX ?? 0,
      targetY: expectedNode?.relY ?? 0,
      distanceError: distError,
      tappedNodeIndex: nodeIndex,
      expectedNodeIndex: expectedIndex,
      isCorrectNode: isCorrect,
      reactionTimeMs: _allTapEvents.isEmpty
          ? elapsed
          : tapTimestamp - _allTapEvents.last.timestamp,
    );
    _allTapEvents.add(tapEvent);

    setState(() {
      _userTapSequence.add(nodeIndex);
    });

    // Haptic + encouragement
    if (isCorrect) {
      SmritiHaptics.lightTap();
      WayfinderAudioService().triggerTapHaptic(isCorrect: true);
      _consecutiveCorrect++;
      if (_encouragement.shouldShowMilestone(_consecutiveCorrect)) {
        _showFeedback(_encouragement.getMilestoneMessage());
        SmritiHaptics.milestone();
        _telemetry.recordEncouragement();
      }
    } else {
      SmritiHaptics.softAcknowledge();
      WayfinderAudioService().triggerTapHaptic(isCorrect: false);
      _consecutiveCorrect = 0;
      // Show gentle hint — highlight the correct node briefly
      _showFeedback(_encouragement.getMissMessage());
    }

    // Fatigue check
    if (tapEvent.reactionTimeMs > 0) {
      final fatigued = _fatigueMonitor.recordReactionTime(tapEvent.reactionTimeMs);
      if (fatigued) {
        _showRestPromptOverlay();
        return;
      }
    }

    // Check if trial is complete
    if (_userTapSequence.length >= trial.targetPath.length) {
      _finishTrial();
    }
  }

  void _finishTrial() {
    final trial = _currentTrial!;
    final pathScore = SpatialScoring.partialCreditScore(
      trial.targetPath,
      _userTapSequence,
    );
    _trialScores.add(pathScore);

    // Record adaptive result
    _adaptiveController.recordResult(pathScore >= 0.7, _currentTrialIndex);

    // Record telemetry event
    final elapsed = DateTime.now().millisecondsSinceEpoch - _sessionStartMs;
    _telemetry.recordTrial(CognitiveTrialEvent(
      eventId: 'wf_trial_${_currentTrialIndex}_${DateTime.now().millisecondsSinceEpoch}',
      trialIndex: _currentTrialIndex,
      utcTimestamp: DateTime.now().toUtc().toIso8601String(),
      reactionTimeMs: _allTapEvents.isNotEmpty
          ? _allTapEvents.last.reactionTimeMs
          : 0,
      isCorrect: pathScore >= 0.7,
      responseType: pathScore >= 0.9
          ? CognitiveResponseType.correct
          : (pathScore >= 0.3
              ? CognitiveResponseType.partialCorrect
              : CognitiveResponseType.incorrect),
      cognitiveLoad: trial.cognitiveLoad,
      fatigueSignal: _fatigueMonitor.isFatigued,
      sessionElapsedTimeMs: elapsed,
      gameSpecific: {
        'pathLength': trial.targetPath.length,
        'totalNodes': trial.allNodes.length,
        'decoyCount': trial.allNodes.where((n) => n.isDecoy).length,
        'isRotated': trial.isRotated,
        'isMirrored': trial.isMirrored,
        'isReverseRecall': trial.isReverseRecall,
        'previewDurationMs': trial.previewDurationMs,
        'pathScore': pathScore,
        'expectedPath': trial.targetPath,
        'userPath': _userTapSequence,
        'taps': _allTapEvents
            .skip(_allTapEvents.length - _userTapSequence.length)
            .map((t) => t.toJson())
            .toList(),
      },
    ));

    // Show trial result briefly then advance
    final msg = pathScore >= 0.9
        ? _encouragement.getSpatialEncouragement()
        : (pathScore >= 0.5
            ? _encouragement.getCorrectMessage()
            : _encouragement.getMissMessage());
    _showFeedback(msg);

    _currentTrialIndex++;

    // Delay before next trial
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _startNextTrial();
    });
  }

  void _showFeedback(String message) {
    _feedbackTimer?.cancel();
    setState(() => _feedbackMessage = message);
    _feedbackTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  void _showRestPromptOverlay() {
    setState(() => _showRestPrompt = true);
    _telemetry.recordRestBreak();
  }

  void _onRestComplete() {
    _fatigueMonitor.acknowledgeRest();
    setState(() => _showRestPrompt = false);
    // Continue with next trial
    if (_userTapSequence.length >= (_currentTrial?.targetPath.length ?? 0)) {
      _currentTrialIndex++;
      _startNextTrial();
    }
  }

  void _endSession() {
    // Build device metadata
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

    final avgSpatialAccuracy = _trialScores.isNotEmpty
        ? _trialScores.fold<double>(0, (s, v) => s + v) / _trialScores.length
        : 0.0;

    final envelope = _telemetry.buildEnvelope(
      sessionId: _sessionId,
      userId: 'default_user',
      deviceMetadata: deviceMeta,
      adaptiveState: _adaptiveController.buildAdaptiveState(),
      spatialAccuracy: avgSpatialAccuracy,
    );

    _telemetry.saveSession(envelope);
    SmritiHaptics.sessionComplete();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WayfinderResultsScreen(
          envelope: envelope,
          trialScores: _trialScores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Status Bar ──
                _buildStatusBar(),

                // ── Map Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEBE6DD), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildMapArea(constraints),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom instruction ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _isPreviewPhase
                        ? 'Memorize the landmark path order'
                        : 'Tap landmarks in the correct order',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF11221C),
                    ),
                  ),
                ),
              ],
            ),

            // ── Feedback overlay ──
            if (_feedbackMessage != null)
              Positioned(
                bottom: 80,
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
                          color: const Color(0xFF2DD4BF), width: 1.5),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2DD4BF),
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
    final trial = _currentTrial;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF134E42),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Trial progress
          Text(
            'Path ${_currentTrialIndex + 1} / ${_params.trialsPerSession}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          // Phase indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isPreviewPhase
                  ? 'MEMORIZE  ⏱ ${_previewCountdown}s'
                  : 'RECALL  ${_userTapSequence.length}/${trial?.targetPath.length ?? 0}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Soundscape & Audio Settings
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
            tooltip: 'Soundscape & Audio',
            onPressed: _showAudioSettingsDialog,
          ),
          // Difficulty badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  void _showAudioSettingsDialog() {
    final audio = WayfinderAudioService();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.spatial_audio_off_rounded, color: Color(0xFF2DD4BF)),
              SizedBox(width: 10),
              Text(
                'Offline Soundscapes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alpha Wave Soundscape',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SoundscapeType>(
                initialValue: audio.currentSoundscape,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: SoundscapeType.values.map((st) {
                  return DropdownMenuItem(
                    value: st,
                    child: Text(audio.getSoundscapeLabel(st)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      audio.setSoundscape(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('${(audio.volume * 100).round()}%', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: audio.volume,
                activeColor: const Color(0xFF2DD4BF),
                inactiveColor: const Color(0xFF334155),
                onChanged: (val) {
                  setModalState(() {
                    audio.setVolume(val);
                  });
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: const Color(0xFF2DD4BF),
                title: const Text('Tactile Haptics', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Vibrations for landmark taps', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                value: audio.hapticsEnabled,
                onChanged: (val) {
                  setModalState(() {
                    audio.setHapticsEnabled(val);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea(BoxConstraints constraints) {
    final trial = _currentTrial;
    if (trial == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2DD4BF)));
    }

    final mapWidth = constraints.maxWidth;
    final mapHeight = constraints.maxHeight;
    final nodeSize = 60.0;

    return Stack(
      children: [
        // Grid background
        Positioned.fill(
          child: GridPaper(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
            divisions: 2,
            interval: 80,
          ),
        ),

        // Reverse recall indicator
        if (trial.isReverseRecall)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '↩ REVERSE ORDER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Path lines during preview (connect nodes in order)
        if (_isPreviewPhase)
          CustomPaint(
            size: Size(mapWidth, mapHeight),
            painter: _PathLinePainter(
              nodes: trial.allNodes
                  .where((n) => !n.isDecoy)
                  .toList(),
              targetPath: trial.targetPath,
              mapWidth: mapWidth,
              mapHeight: mapHeight,
              nodeSize: nodeSize,
            ),
          ),

        // Map nodes
        ...trial.allNodes.map((node) {
          final isTapped = _userTapSequence.contains(node.index);
          final tapOrder = _userTapSequence.indexOf(node.index);
          final isInPath = trial.targetPath.contains(node.index);
          final pathIndex = trial.targetPath.indexOf(node.index);

          final posX = node.relX * (mapWidth - nodeSize);
          final posY = node.relY * (mapHeight - nodeSize);

          return Positioned(
            left: posX,
            top: posY,
            child: GestureDetector(
              onTap: () => _handleNodeTap(node.index),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = (!_isPreviewPhase && !isTapped && isInPath)
                      ? _pulseAnimation.value
                      : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: nodeSize,
                      height: nodeSize,
                      decoration: BoxDecoration(
                        color: _getNodeColor(
                          isPreview: _isPreviewPhase,
                          isTapped: isTapped,
                          isDecoy: node.isDecoy,
                          isInPath: isInPath,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTapped
                              ? const Color(0xFF2DD4BF)
                              : Colors.white.withValues(alpha: 0.6),
                          width: isTapped ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPreviewPhase && isInPath) ...[
                            // Show order number during preview
                            Text(
                              '${pathIndex + 1}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ] else if (isTapped) ...[
                            // Show tap order
                            Text(
                              '${tapOrder + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ] else ...[
                            // Show landmark icon
                            Icon(
                              node.icon,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),

        // Node labels during preview
        if (_isPreviewPhase)
          ...trial.allNodes
              .where((n) => !n.isDecoy)
              .map((node) {
            final posX = node.relX * (mapWidth - nodeSize);
            final posY = node.relY * (mapHeight - nodeSize);

            return Positioned(
              left: posX - 10,
              top: posY + nodeSize + 2,
              width: nodeSize + 20,
              child: Text(
                node.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            );
          }),
      ],
    );
  }

  Color _getNodeColor({
    required bool isPreview,
    required bool isTapped,
    required bool isDecoy,
    required bool isInPath,
  }) {
    if (isTapped) return const Color(0xFF2DD4BF);
    if (isPreview && isInPath) return const Color(0xFFF59E0B);
    if (isPreview && isDecoy) return const Color(0xFF475569);
    if (isDecoy) return const Color(0xFF374151);
    return const Color(0xFF0891B2);
  }
}

/// Custom painter for drawing path lines between nodes during preview.
class _PathLinePainter extends CustomPainter {
  final List<MapNode> nodes;
  final List<int> targetPath;
  final double mapWidth;
  final double mapHeight;
  final double nodeSize;

  _PathLinePainter({
    required this.nodes,
    required this.targetPath,
    required this.mapWidth,
    required this.mapHeight,
    required this.nodeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < targetPath.length - 1; i++) {
      final fromNode = nodes.firstWhere((n) => n.index == targetPath[i]);
      final toNode = nodes.firstWhere((n) => n.index == targetPath[i + 1]);

      final from = Offset(
        fromNode.relX * (mapWidth - nodeSize) + nodeSize / 2,
        fromNode.relY * (mapHeight - nodeSize) + nodeSize / 2,
      );
      final to = Offset(
        toNode.relX * (mapWidth - nodeSize) + nodeSize / 2,
        toNode.relY * (mapHeight - nodeSize) + nodeSize / 2,
      );

      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
