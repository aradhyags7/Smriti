// ─────────────────────────────────────────────────────────────────────────────
// FATIGUE MONITOR
// Detects cognitive fatigue via reaction time drift analysis
// Triggers automatic rest prompts to protect patients
// ─────────────────────────────────────────────────────────────────────────────

class FatigueMonitor {
  final int baselineWindow;
  final double driftThreshold;
  final int consecutiveRequired;

  final List<int> _allReactionTimes = [];
  double _baselineRt = 0.0;
  int _consecutiveFatigueTrials = 0;
  int _totalFatigueEvents = 0;
  bool _fatigueActive = false;

  FatigueMonitor({
    this.baselineWindow = 5,
    this.driftThreshold = 0.15,
    this.consecutiveRequired = 3,
  });

  /// Record a reaction time. Returns true if fatigue is now detected.
  bool recordReactionTime(int reactionTimeMs) {
    if (reactionTimeMs <= 0) return false;

    _allReactionTimes.add(reactionTimeMs);

    // Build baseline from first N valid RTs
    if (_allReactionTimes.length <= baselineWindow) {
      _baselineRt = _allReactionTimes.fold<double>(0, (s, r) => s + r) /
          _allReactionTimes.length;
      return false;
    }

    // Check drift against baseline
    final drift = (reactionTimeMs - _baselineRt) / _baselineRt;

    if (drift > driftThreshold) {
      _consecutiveFatigueTrials++;
      if (_consecutiveFatigueTrials >= consecutiveRequired) {
        _fatigueActive = true;
        _totalFatigueEvents++;
        _consecutiveFatigueTrials = 0;
        return true;
      }
    } else {
      _consecutiveFatigueTrials = 0;
      _fatigueActive = false;
    }

    return false;
  }

  /// Acknowledge that a rest break was taken (resets fatigue flag).
  void acknowledgeRest() {
    _fatigueActive = false;
    _consecutiveFatigueTrials = 0;

    // Recalibrate baseline after rest (use last 3 RTs as new baseline)
    if (_allReactionTimes.length >= 3) {
      final recent = _allReactionTimes.sublist(_allReactionTimes.length - 3);
      _baselineRt = recent.fold<double>(0, (s, r) => s + r) / recent.length;
    }
  }

  /// Whether fatigue is currently active (hasn't been acknowledged).
  bool get isFatigued => _fatigueActive;

  /// Total number of fatigue events in this session.
  int get totalFatigueEvents => _totalFatigueEvents;

  /// Current baseline reaction time.
  double get baselineReactionTime => _baselineRt;

  /// Get the fatigue drift percentage for the last trial.
  double get lastDriftPercent {
    if (_allReactionTimes.isEmpty || _baselineRt <= 0) return 0.0;
    final lastRt = _allReactionTimes.last;
    return ((lastRt - _baselineRt) / _baselineRt * 100);
  }

  /// Reset all state (for new session).
  void reset() {
    _allReactionTimes.clear();
    _baselineRt = 0.0;
    _consecutiveFatigueTrials = 0;
    _totalFatigueEvents = 0;
    _fatigueActive = false;
  }
}
