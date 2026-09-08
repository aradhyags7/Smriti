import 'dart:math';
import '../../spatial_memory/models/wayfinder_models.dart';
import '../../working_memory/models/sequence_check_models.dart';
import '../../speed_processing/models/pulse_trainer_models.dart';

enum CalibrationGameType { pulse, sequence, wayfinder }

/// Configuration for a single round within the 5-round daily calibration battery.
class CalibrationRoundConfig {
  final int roundIndex; // 1 to 5
  final CalibrationGameType gameType;
  final String title;
  final String variantDetails;
  final WayfinderDifficulty wayfinderDifficulty;
  final SequenceDifficulty sequenceDifficulty;
  final DifficultyLevel pulseDifficulty;

  const CalibrationRoundConfig({
    required this.roundIndex,
    required this.gameType,
    required this.title,
    required this.variantDetails,
    required this.wayfinderDifficulty,
    required this.sequenceDifficulty,
    required this.pulseDifficulty,
  });

  Map<String, dynamic> toJson() => {
        'roundIndex': roundIndex,
        'gameType': gameType.name,
        'title': title,
        'variantDetails': variantDetails,
        'wayfinderDifficulty': wayfinderDifficulty.name,
        'sequenceDifficulty': sequenceDifficulty.name,
        'pulseDifficulty': pulseDifficulty.name,
      };
}

/// 24-Hour Seeded Daily Calibration Config generator (5-Round Mixed Battery).
class DailyCalibrationConfig {
  final String dateKey; // e.g. "2026-09-08"
  final int seed;
  final List<CalibrationRoundConfig> rounds;

  DailyCalibrationConfig._({
    required this.dateKey,
    required this.seed,
    required this.rounds,
  });

  /// Factory constructor generating a 5-round mixed game pattern from a 24-hour seed
  factory DailyCalibrationConfig.forDate(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final seed = dateKey.hashCode;
    final rng = Random(seed);

    // Pool of game types to guarantee a rich mix across 5 rounds
    final gamePool = [
      CalibrationGameType.pulse,
      CalibrationGameType.sequence,
      CalibrationGameType.sequence,
      CalibrationGameType.wayfinder,
      CalibrationGameType.pulse,
    ]..shuffle(rng);

    final wayfinderDiffs = WayfinderDifficulty.values;
    final sequenceDiffs = SequenceDifficulty.values;
    final pulseDiffs = DifficultyLevel.values;

    final List<CalibrationRoundConfig> generatedRounds = [];

    for (int i = 0; i < 5; i++) {
      final gType = gamePool[i];
      final wfDiff = wayfinderDiffs[rng.nextInt(wayfinderDiffs.length)];
      final seqDiff = sequenceDiffs[rng.nextInt(sequenceDiffs.length)];
      final pulseDiff = pulseDiffs[rng.nextInt(pulseDiffs.length)];

      String title = '';
      String details = '';

      switch (gType) {
        case CalibrationGameType.pulse:
          title = 'Pulse Processing Speed';
          details = '${pulseDiff.name.toUpperCase()} • Speed Latency & NO-GO Stop Signal';
          break;
        case CalibrationGameType.sequence:
          title = 'Sequence Working Memory';
          details = '${seqDiff.name.toUpperCase()} • Dynamic Recall Order';
          break;
        case CalibrationGameType.wayfinder:
          title = 'Wayfinder Spatial Memory';
          details = '${wfDiff.name.toUpperCase()} • Landmark Navigation & Soundscape';
          break;
      }

      generatedRounds.add(
        CalibrationRoundConfig(
          roundIndex: i + 1,
          gameType: gType,
          title: title,
          variantDetails: details,
          wayfinderDifficulty: wfDiff,
          sequenceDifficulty: seqDiff,
          pulseDifficulty: pulseDiff,
        ),
      );
    }

    return DailyCalibrationConfig._(
      dateKey: dateKey,
      seed: seed,
      rounds: generatedRounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'seed': seed,
        'roundCount': rounds.length,
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };
}

/// Consolidated 5-Round Daily Calibration Result Data Set for AI Cognitive Assessment Models.
class DailyCalibrationResult {
  final String dateKey;
  final int timestampMs;
  final double overallBaselineScore; // 0-100 composite index
  final List<Map<String, dynamic>> roundsTelemetry;

  const DailyCalibrationResult({
    required this.dateKey,
    required this.timestampMs,
    required this.overallBaselineScore,
    required this.roundsTelemetry,
  });

  Map<String, dynamic> toJson() => {
        'calibrationTestType': '24-Hour 5-Round Cognitive Baseline Battery',
        'dateKey': dateKey,
        'timestamp': timestampMs,
        'isoDate': DateTime.fromMillisecondsSinceEpoch(timestampMs).toIso8601String(),
        'overallBaselineScore': overallBaselineScore.roundToDouble(),
        'totalRoundsCompleted': roundsTelemetry.length,
        'roundsData': roundsTelemetry,
      };
}
