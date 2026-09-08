import 'dart:math';
import '../models/pulse_trainer_models.dart';

class TrialGenerator {
  final int totalTrialsCount;
  final DifficultyLevel level;
  int _currentTrialIndex;
  final Random _random;

  TrialGenerator({
    required this.totalTrialsCount,
    this.level = DifficultyLevel.moderate,
  })  : _currentTrialIndex = 0,
        _random = Random();

  TrialConfig generateNextTrial(
    int tierMs,
    StimulusPair pair,
    RuleMode activeRule, [
    RuleMode? previousRule,
  ]) {
    final trialIndex = _currentTrialIndex;
    _currentTrialIndex += 1;

    final rand = _random.nextDouble();
    TrialType trialType = TrialType.go;
    bool isNoGo = false;
    bool isDistractorPresent = false;
    int? distractorRingIndex;

    if (level == DifficultyLevel.simple) {
      // Easy: Pure GO trials only.
      // 55+ users need to learn the game format without inhibition pressure.
      trialType = TrialType.go;
    } else if (level == DifficultyLevel.moderate) {
      // Moderate: Gentle NO-GO (10%) + mild distractors (15%).
      // Introduces inhibitory control at a comfortable pace.
      if (rand < 0.10) {
        trialType = TrialType.noGo;
        isNoGo = true;
      } else if (rand < 0.25) {
        trialType = TrialType.distractor;
        isDistractorPresent = true;
      }
    } else {
      // Hard: Slightly higher NO-GO (15%) + distractors (20%).
      // Rule switches and sequence trials removed — too disorienting for 55+.
      if (rand < 0.15) {
        trialType = TrialType.noGo;
        isNoGo = true;
      } else if (rand < 0.35) {
        trialType = TrialType.distractor;
        isDistractorPresent = true;
      }
    }

    // Easy: 4 cardinal ring positions (clear, unambiguous directions).
    // Moderate/Hard: 8 radial positions for finer spatial discrimination.
    final List<int> ringDegrees = level == DifficultyLevel.simple
        ? const [0, 90, 180, 270]
        : const [0, 45, 90, 135, 180, 225, 270, 315];

    final targetRingIndex = _random.nextInt(ringDegrees.length);
    final targetRingDeg = ringDegrees[targetRingIndex];

    if (isDistractorPresent) {
      int dIdx = _random.nextInt(ringDegrees.length);
      while (dIdx == targetRingIndex) {
        dIdx = _random.nextInt(ringDegrees.length);
      }
      distractorRingIndex = dIdx;
    }

    final isiMs = 400 + _random.nextInt(601); // 400 to 1000ms
    // Easy: large 72dp tap target — accommodates motor precision differences in 55+.
    // Moderate/Hard: smaller targets for more precise tracking.
    final targetSizeDp = level == DifficultyLevel.simple
        ? 72.0
        : 55.0 + _random.nextInt(16); // 55–70dp range

    final isImageA = _random.nextBool();
    final targetCentralItem = isImageA ? pair.imageA : pair.imageB;

    final expectedSequence = [
      targetCentralItem.label,
      'ring_pos_$targetRingIndex',
    ];

    final difficultyParams = DifficultyParams(
      tierMs: tierMs,
      isiMs: isiMs,
      targetSizeDp: targetSizeDp,
      ringPositionDeg: targetRingDeg,
      ruleName: activeRule.name,
      isDistractorPresent: isDistractorPresent,
    );

    return TrialConfig(
      trialIndex: trialIndex,
      trialType: trialType,
      difficultyParams: difficultyParams,
      targetCentralItem: targetCentralItem,
      targetRingIndex: targetRingIndex,
      targetRingDeg: targetRingDeg,
      isNoGo: isNoGo,
      isDistractorPresent: isDistractorPresent,
      distractorRingIndex: distractorRingIndex,
      ruleName: activeRule,
      previousRuleName: previousRule,
      expectedSequence: expectedSequence,
    );
  }

  void reset() {
    _currentTrialIndex = 0;
  }
}
