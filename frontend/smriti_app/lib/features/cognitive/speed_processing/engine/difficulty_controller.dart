import '../models/pulse_trainer_models.dart';

class DifficultyController {
  final List<int> fixedTiersMs;
  int _currentTierIndex;
  int _consecutiveSuccesses;
  final List<Map<String, dynamic>> _tierHistory;

  DifficultyController({DifficultyLevel level = DifficultyLevel.moderate})
      : fixedTiersMs = _getTiersForLevel(level),
        _currentTierIndex = 0,
        _consecutiveSuccesses = 0,
        _tierHistory = [];

  static List<int> _getTiersForLevel(DifficultyLevel level) {
    // Tuned for users aged 55+ — average baseline reaction time is ~400–500ms.
    // All tiers are comfortably above this floor to reduce anxiety and dropout.
    switch (level) {
      case DifficultyLevel.simple:
        // Easy: 1200ms → 900ms → 700ms
        // Very relaxed pacing — builds familiarity with the game format.
        return [1200, 900, 700];
      case DifficultyLevel.moderate:
        // Moderate: 900ms → 700ms → 550ms
        // Steady challenge without inducing time-pressure stress.
        return [900, 700, 550];
      case DifficultyLevel.harder:
        // Hard: 700ms → 550ms → 400ms
        // 400ms is achievable for a healthy, engaged 65-year-old.
        // Previous min was 150ms (elite athlete territory) — removed.
        return [700, 550, 400];
    }
  }

  int getCurrentTierMs() {
    return fixedTiersMs[_currentTierIndex];
  }

  void registerTrialResult(bool isFullyCorrect) {
    final currentMs = getCurrentTierMs();
    _tierHistory.add({'tierMs': currentMs, 'isFullyCorrect': isFullyCorrect});

    if (isFullyCorrect) {
      _consecutiveSuccesses += 1;
      if (_consecutiveSuccesses >= 2) {
        if (_currentTierIndex < fixedTiersMs.length - 1) {
          _currentTierIndex += 1;
        }
        _consecutiveSuccesses = 0;
      }
    } else {
      _consecutiveSuccesses = 0;
      if (_currentTierIndex > 0) {
        _currentTierIndex -= 1;
      }
    }
  }

  int calculateThresholdMs() {
    if (_tierHistory.isEmpty) {
      return getCurrentTierMs();
    }

    final Map<int, Map<String, int>> statsByTier = {};
    for (final item in _tierHistory) {
      final int tierMs = item['tierMs'] as int;
      final bool isCorrect = item['isFullyCorrect'] as bool;
      statsByTier.putIfAbsent(tierMs, () => {'correct': 0, 'total': 0});
      statsByTier[tierMs]!['total'] = statsByTier[tierMs]!['total']! + 1;
      if (isCorrect) {
        statsByTier[tierMs]!['correct'] = statsByTier[tierMs]!['correct']! + 1;
      }
    }

    int bestThreshold = fixedTiersMs[0];
    for (final tierMs in fixedTiersMs) {
      final stats = statsByTier[tierMs];
      if (stats != null && stats['total']! > 0) {
        final double accuracy = stats['correct']! / stats['total']!;
        if (accuracy >= 0.75) {
          bestThreshold = tierMs;
        }
      }
    }

    return bestThreshold;
  }

  void reset() {
    _currentTierIndex = 0;
    _consecutiveSuccesses = 0;
    _tierHistory.clear();
  }
}
