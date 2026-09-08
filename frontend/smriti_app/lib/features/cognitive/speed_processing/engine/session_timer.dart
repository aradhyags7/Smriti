class SessionTimer {
  final int startTimeMs;
  final int maxDurationMs;
  final int totalTrialsCap;
  final int restFrequency;
  int _completedTrialsCount;
  int _lastRestShownMilestone;

  SessionTimer({
    int maxDurationMinutes = 15,
    required this.totalTrialsCap,
    this.restFrequency = 10,
  })  : startTimeMs = DateTime.now().millisecondsSinceEpoch,
        maxDurationMs = maxDurationMinutes * 60 * 1000,
        _completedTrialsCount = 0,
        _lastRestShownMilestone = 0;

  void recordTrialCompletion() {
    _completedTrialsCount += 1;
  }

  bool shouldShowRestPrompt() {
    if (_completedTrialsCount == 0 || isSessionComplete()) return false;
    final isMilestone = _completedTrialsCount % restFrequency == 0;
    final notYetShownForThisMilestone =
        _completedTrialsCount > _lastRestShownMilestone;
    return isMilestone && notYetShownForThisMilestone;
  }

  void dismissRestPrompt() {
    _lastRestShownMilestone = _completedTrialsCount;
  }

  bool isSessionComplete() {
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimeMs;
    final timeCapExceeded = elapsed >= maxDurationMs;
    final trialsCapReached = _completedTrialsCount >= totalTrialsCap;
    return timeCapExceeded || trialsCapReached;
  }

  Map<String, dynamic> getProgress() {
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - startTimeMs) / 1000).floor();
    return {
      'trialsDone': _completedTrialsCount,
      'totalTrials': totalTrialsCap,
      'elapsedSeconds': elapsedSeconds,
    };
  }
}
