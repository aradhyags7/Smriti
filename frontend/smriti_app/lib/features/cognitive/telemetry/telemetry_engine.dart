import 'dart:math';
import 'telemetry_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TELEMETRY ENGINE
// Singleton that collects raw events, computes fatigue, and builds envelopes
// ─────────────────────────────────────────────────────────────────────────────

class TelemetryEngine {
  // Singleton
  static final TelemetryEngine _instance = TelemetryEngine._internal();
  factory TelemetryEngine() => _instance;
  TelemetryEngine._internal();

  // ── In-memory session store ──
  final List<CognitiveSessionEnvelope> _allSessions = [];

  // ── Current session state ──
  final List<CognitiveTrialEvent> _currentTrials = [];
  final List<int> _reactionTimes = [];
  int _fatigueEventsCount = 0;
  int _restBreaksTaken = 0;
  int _encouragementEventsCount = 0;
  String _sessionStartUtc = '';
  GameType? _currentGameType;
  CognitiveDifficulty? _currentDifficulty;

  // ── Fatigue detection state ──
  double _baselineRt = 0.0;
  int _baselineTrialCount = 0;
  static const int _baselineWindow = 5;
  static const double _fatigueDriftThreshold = 0.15; // 15% above baseline
  int _consecutiveFatigueTrials = 0;
  static const int _fatigueConsecutiveThreshold = 3;

  /// Start a new session — resets all per-session state.
  void startSession(GameType gameType, CognitiveDifficulty difficulty) {
    _currentTrials.clear();
    _reactionTimes.clear();
    _fatigueEventsCount = 0;
    _restBreaksTaken = 0;
    _encouragementEventsCount = 0;
    _baselineRt = 0.0;
    _baselineTrialCount = 0;
    _consecutiveFatigueTrials = 0;
    _currentGameType = gameType;
    _currentDifficulty = difficulty;
    _sessionStartUtc = DateTime.now().toUtc().toIso8601String();
  }

  /// Record a trial event. Returns true if fatigue is detected.
  bool recordTrial(CognitiveTrialEvent event) {
    _currentTrials.add(event);

    if (event.reactionTimeMs > 0) {
      _reactionTimes.add(event.reactionTimeMs);
    }

    // Update baseline (first N trials)
    if (_baselineTrialCount < _baselineWindow && event.reactionTimeMs > 0) {
      _baselineTrialCount++;
      _baselineRt = _reactionTimes
              .take(_baselineWindow)
              .fold<double>(0, (sum, rt) => sum + rt) /
          _baselineTrialCount;
    }

    // Check fatigue (only after baseline is established)
    bool fatigueDetected = false;
    if (_baselineTrialCount >= _baselineWindow &&
        event.reactionTimeMs > 0 &&
        _baselineRt > 0) {
      final drift =
          (event.reactionTimeMs - _baselineRt) / _baselineRt;
      if (drift > _fatigueDriftThreshold) {
        _consecutiveFatigueTrials++;
        if (_consecutiveFatigueTrials >= _fatigueConsecutiveThreshold) {
          _fatigueEventsCount++;
          fatigueDetected = true;
          _consecutiveFatigueTrials = 0; // Reset after triggering
        }
      } else {
        _consecutiveFatigueTrials = 0;
      }
    }

    return fatigueDetected;
  }

  /// Record that a rest break was taken.
  void recordRestBreak() {
    _restBreaksTaken++;
  }

  /// Record that an encouragement was shown.
  void recordEncouragement() {
    _encouragementEventsCount++;
  }

  /// Get the rolling accuracy of the last N trials.
  double getRollingAccuracy({int window = 5}) {
    if (_currentTrials.isEmpty) return 1.0;
    final recent = _currentTrials.length <= window
        ? _currentTrials
        : _currentTrials.sublist(_currentTrials.length - window);
    final correct = recent.where((t) => t.isCorrect).length;
    return correct / recent.length;
  }

  /// Check if fatigue is currently flagged.
  bool get isFatigued => _consecutiveFatigueTrials >= _fatigueConsecutiveThreshold - 1;

  /// Get current trial count.
  int get currentTrialCount => _currentTrials.length;

  /// Build the final session envelope.
  CognitiveSessionEnvelope buildEnvelope({
    required String sessionId,
    required String userId,
    required DeviceMetadata deviceMetadata,
    required AdaptiveState adaptiveState,
    int? maxSpan,
    double? spatialAccuracy,
  }) {
    final endUtc = DateTime.now().toUtc().toIso8601String();
    final correctCount = _currentTrials.where((t) => t.isCorrect).length;
    final totalTrials = _currentTrials.length;
    final accuracy = totalTrials > 0 ? correctCount / totalTrials : 0.0;

    final validRts = _reactionTimes.where((rt) => rt > 0).toList();
    final avgRt = validRts.isNotEmpty
        ? validRts.fold<double>(0, (sum, rt) => sum + rt) / validRts.length
        : 0.0;

    // Compute median RT
    double medianRt = 0.0;
    if (validRts.isNotEmpty) {
      final sorted = List<int>.from(validRts)..sort();
      final mid = sorted.length ~/ 2;
      medianRt = sorted.length.isOdd
          ? sorted[mid].toDouble()
          : (sorted[mid - 1] + sorted[mid]) / 2.0;
    }

    // Compute average cognitive load
    final cogLoadAvg = _currentTrials.isNotEmpty
        ? _currentTrials.fold<double>(0, (sum, t) => sum + t.cognitiveLoad) /
            _currentTrials.length
        : 0.0;

    // Compute total session duration
    final totalDuration = _currentTrials.isNotEmpty
        ? _currentTrials.last.sessionElapsedTimeMs
        : 0;

    return CognitiveSessionEnvelope(
      gameType: _currentGameType ?? GameType.pulseTrainer,
      sessionId: sessionId,
      userId: userId,
      difficultyLevel: _currentDifficulty ?? CognitiveDifficulty.moderate,
      sessionStartUtc: _sessionStartUtc,
      sessionEndUtc: endUtc,
      deviceMetadata: deviceMetadata,
      adaptiveState: adaptiveState,
      sessionSummary: SessionSummary(
        totalTrials: totalTrials,
        correctTrials: correctCount,
        accuracy: accuracy,
        avgReactionTimeMs: avgRt,
        medianReactionTimeMs: medianRt,
        fatigueEventsCount: _fatigueEventsCount,
        restBreaksTaken: _restBreaksTaken,
        maxSpan: maxSpan,
        spatialAccuracy: spatialAccuracy,
        cognitiveLoadAvg: cogLoadAvg,
        totalSessionDurationMs: totalDuration,
        encouragementEventsCount: _encouragementEventsCount,
      ),
      trials: List.unmodifiable(_currentTrials),
    );
  }

  /// Save a completed session envelope to local storage.
  void saveSession(CognitiveSessionEnvelope envelope) {
    _allSessions.add(envelope);
  }

  /// Get all stored sessions.
  List<CognitiveSessionEnvelope> getAllSessions() =>
      List.unmodifiable(_allSessions);

  /// Get sessions filtered by game type.
  List<CognitiveSessionEnvelope> getSessionsByGame(GameType gameType) =>
      _allSessions.where((s) => s.gameType == gameType).toList();

  /// Get sessions for a specific date.
  List<CognitiveSessionEnvelope> getSessionsByDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _allSessions
        .where((s) => s.sessionStartUtc.startsWith(dateStr))
        .toList();
  }

  /// Build a daily summary record across all games.
  DailySummaryRecord? buildDailySummary(DateTime date, String userId) {
    final daySessions = getSessionsByDate(date);
    if (daySessions.isEmpty) return null;

    int totalTrials = 0;
    int totalCorrect = 0;
    double totalRt = 0;
    int rtCount = 0;
    int totalFatigue = 0;
    int totalDuration = 0;
    final gameAccuracies = <String, double>{};
    final gameSessions = <String, int>{};
    double? spatialAccuracyAvg;
    int? maxSpan;
    double? processingSpeed;

    for (final session in daySessions) {
      final gameName = session.gameType.name;
      totalTrials += session.sessionSummary.totalTrials;
      totalCorrect += session.sessionSummary.correctTrials;
      totalFatigue += session.sessionSummary.fatigueEventsCount;
      totalDuration += session.sessionSummary.totalSessionDurationMs;

      if (session.sessionSummary.avgReactionTimeMs > 0) {
        totalRt += session.sessionSummary.avgReactionTimeMs;
        rtCount++;
      }

      gameSessions[gameName] = (gameSessions[gameName] ?? 0) + 1;
      gameAccuracies[gameName] = session.sessionSummary.accuracy;

      if (session.sessionSummary.spatialAccuracy != null) {
        spatialAccuracyAvg = session.sessionSummary.spatialAccuracy;
      }
      if (session.sessionSummary.maxSpan != null) {
        maxSpan = max(maxSpan ?? 0, session.sessionSummary.maxSpan!);
      }
    }

    // Find best processing speed from pulse trainer sessions
    final pulseSessions = daySessions
        .where((s) => s.gameType == GameType.pulseTrainer)
        .toList();
    if (pulseSessions.isNotEmpty) {
      processingSpeed = pulseSessions
          .map((s) => s.sessionSummary.avgReactionTimeMs)
          .reduce(min);
    }

    return DailySummaryRecord(
      date:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      userId: userId,
      totalSessionsPlayed: daySessions.length,
      totalTrialsCompleted: totalTrials,
      overallAccuracy: totalTrials > 0 ? totalCorrect / totalTrials : 0.0,
      avgReactionTimeMs: rtCount > 0 ? totalRt / rtCount : 0.0,
      totalTrainingDurationMs: totalDuration,
      fatigueEventsTotal: totalFatigue,
      gameAccuracies: gameAccuracies,
      gameSessions: gameSessions,
      spatialAccuracyAvg: spatialAccuracyAvg,
      maxSequenceSpan: maxSpan,
      processingSpeedMs: processingSpeed,
      cognitiveLoadTrend: 5.0, // Placeholder — computed from 7-day window
    );
  }

  /// Clear all stored sessions (for testing).
  void clearAll() {
    _allSessions.clear();
  }
}
