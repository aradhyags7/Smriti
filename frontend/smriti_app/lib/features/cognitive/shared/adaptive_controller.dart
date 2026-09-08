// ─────────────────────────────────────────────────────────────────────────────
// ADAPTIVE DIFFICULTY CONTROLLER
// Keeps dementia patients in their "zone of proximal development"
// by auto-adjusting challenge based on rolling performance
// ─────────────────────────────────────────────────────────────────────────────

import '../telemetry/telemetry_models.dart';

/// Describes a micro-adjustment made within a session.
class AdaptiveAdjustment {
  final int atTrialIndex;
  final String direction; // 'increase' | 'decrease' | 'hold'
  final double rollingAccuracy;
  final String reason;

  const AdaptiveAdjustment({
    required this.atTrialIndex,
    required this.direction,
    required this.rollingAccuracy,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'atTrialIndex': atTrialIndex,
        'direction': direction,
        'rollingAccuracy': rollingAccuracy,
        'reason': reason,
      };
}

/// Controls in-session adaptive difficulty for any cognitive game.
class AdaptiveController {
  final CognitiveDifficulty baseDifficulty;
  final int rollingWindowSize;
  final double increaseThreshold;
  final double decreaseThreshold;

  final List<bool> _recentResults = [];
  final List<AdaptiveAdjustment> _adjustmentLog = [];

  // Current micro-adjustments (game-specific interpretation)
  int _speedAdjustment = 0; // positive = harder (faster), negative = easier
  int _complexityAdjustment = 0; // positive = more items/rules

  AdaptiveController({
    required this.baseDifficulty,
    this.rollingWindowSize = 5,
    this.increaseThreshold = 0.85,
    this.decreaseThreshold = 0.50,
  });

  /// Record a trial result and check if adjustment is needed.
  /// Returns the adjustment direction: 'increase', 'decrease', or 'hold'.
  String recordResult(bool isCorrect, int trialIndex) {
    _recentResults.add(isCorrect);

    // Only adjust after we have enough data
    if (_recentResults.length < rollingWindowSize) return 'hold';

    final windowStart = _recentResults.length - rollingWindowSize;
    final window = _recentResults.sublist(windowStart);
    final accuracy = window.where((r) => r).length / window.length;

    String direction = 'hold';

    if (accuracy >= increaseThreshold) {
      _speedAdjustment++;
      _complexityAdjustment++;
      direction = 'increase';
    } else if (accuracy <= decreaseThreshold) {
      _speedAdjustment = (_speedAdjustment - 1).clamp(-3, 10);
      _complexityAdjustment = (_complexityAdjustment - 1).clamp(-3, 10);
      direction = 'decrease';
    }

    if (direction != 'hold') {
      _adjustmentLog.add(AdaptiveAdjustment(
        atTrialIndex: trialIndex,
        direction: direction,
        rollingAccuracy: accuracy,
        reason: direction == 'increase'
            ? 'Rolling accuracy ${(accuracy * 100).toInt()}% ≥ ${(increaseThreshold * 100).toInt()}%'
            : 'Rolling accuracy ${(accuracy * 100).toInt()}% ≤ ${(decreaseThreshold * 100).toInt()}%',
      ));
    }

    return direction;
  }

  /// Get the current speed adjustment factor.
  /// Positive values mean faster/harder, negative mean slower/easier.
  int get speedAdjustment => _speedAdjustment;

  /// Get the current complexity adjustment factor.
  int get complexityAdjustment => _complexityAdjustment;

  /// Get the current rolling accuracy (0.0 - 1.0).
  double get rollingAccuracy {
    if (_recentResults.length < rollingWindowSize) {
      if (_recentResults.isEmpty) return 1.0;
      return _recentResults.where((r) => r).length / _recentResults.length;
    }
    final windowStart = _recentResults.length - rollingWindowSize;
    final window = _recentResults.sublist(windowStart);
    return window.where((r) => r).length / window.length;
  }

  /// Build the adaptive state for telemetry export.
  AdaptiveState buildAdaptiveState() {
    return AdaptiveState(
      initialDifficulty: baseDifficulty.name,
      finalDifficulty: baseDifficulty.name, // stays same tier, micro-adjustments within
      adjustmentCount: _adjustmentLog.length,
      rollingAccuracy: rollingAccuracy,
      adjustmentLog: _adjustmentLog.map((a) => a.toJson()).toList(),
    );
  }

  /// Apply speed adjustment to a base timing value (ms).
  /// Each adjustment step changes timing by ~8%.
  int adjustTiming(int baseMs) {
    final factor = 1.0 - (_speedAdjustment * 0.08);
    return (baseMs * factor).clamp(100, 5000).round();
  }

  /// Apply complexity adjustment to a base item count.
  int adjustItemCount(int baseCount) {
    return (baseCount + _complexityAdjustment).clamp(2, 16);
  }
}
