// ─────────────────────────────────────────────────────────────────────────────
// SPATIAL SCORING ENGINE
// Measures spatial accuracy, path ordering, and partial credit
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import '../models/wayfinder_models.dart';

class SpatialScoring {
  /// Calculate Euclidean distance between two points.
  static double euclideanDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  /// Score a single trial based on ordering accuracy.
  /// Returns a score from 0.0 to 1.0.
  static double scorePathOrdering(
      List<int> expectedPath, List<int> userPath) {
    if (expectedPath.isEmpty || userPath.isEmpty) return 0.0;

    int correctPositions = 0;
    final compareLength = min(expectedPath.length, userPath.length);

    for (int i = 0; i < compareLength; i++) {
      if (userPath[i] == expectedPath[i]) {
        correctPositions++;
      }
    }

    return correctPositions / expectedPath.length;
  }

  /// Compute Kendall Tau correlation coefficient for path ordering.
  /// Measures how "shuffled" the user's ordering is vs the target.
  /// Returns -1.0 (inverse) to 1.0 (perfect match).
  static double kendallTau(List<int> expected, List<int> actual) {
    if (expected.length != actual.length || expected.isEmpty) return 0.0;

    final n = expected.length;
    if (n < 2) return actual.first == expected.first ? 1.0 : -1.0;

    // Build rank mapping
    final expectedRank = <int, int>{};
    for (int i = 0; i < n; i++) {
      expectedRank[expected[i]] = i;
    }

    // Count concordant and discordant pairs
    int concordant = 0;
    int discordant = 0;

    for (int i = 0; i < n - 1; i++) {
      for (int j = i + 1; j < n; j++) {
        final rankI = expectedRank[actual[i]];
        final rankJ = expectedRank[actual[j]];
        if (rankI == null || rankJ == null) continue;

        if (rankI < rankJ) {
          concordant++;
        } else {
          discordant++;
        }
      }
    }

    final totalPairs = n * (n - 1) / 2;
    return totalPairs > 0 ? (concordant - discordant) / totalPairs : 0.0;
  }

  /// Calculate average spatial tap accuracy across all taps in a trial.
  /// Lower distance error = higher accuracy.
  static double spatialTapAccuracy(List<SpatialTapEvent> taps,
      {double maxAcceptableError = 0.15}) {
    if (taps.isEmpty) return 0.0;

    double totalAccuracy = 0;
    for (final tap in taps) {
      // Convert distance error to accuracy (0.0 to 1.0)
      final accuracy = (1.0 - (tap.distanceError / maxAcceptableError))
          .clamp(0.0, 1.0);
      totalAccuracy += accuracy;
    }

    return totalAccuracy / taps.length;
  }

  /// Compute partial credit score for a trial.
  /// Awards points for:
  /// - Correct node (regardless of order): 0.3 points each
  /// - Correct position in sequence: 0.7 points each
  static double partialCreditScore(
      List<int> expectedPath, List<int> userPath) {
    if (expectedPath.isEmpty) return 0.0;

    double score = 0;
    final maxScore = expectedPath.length;

    for (int i = 0; i < userPath.length && i < expectedPath.length; i++) {
      if (userPath[i] == expectedPath[i]) {
        // Correct node in correct position
        score += 1.0;
      } else if (expectedPath.contains(userPath[i])) {
        // Correct node but wrong position
        score += 0.3;
      }
      // Tapped a decoy = 0 points (but no penalty)
    }

    return score / maxScore;
  }

  /// Generate a plain-language summary of spatial performance.
  static String generateSummary({
    required double pathScore,
    required double spatialAccuracy,
    required int trialsCompleted,
    required int totalTrials,
  }) {
    final overallScore = (pathScore * 0.7 + spatialAccuracy * 0.3);

    if (overallScore >= 0.9) {
      return 'Exceptional spatial memory! You navigated $trialsCompleted paths with excellent precision.';
    } else if (overallScore >= 0.7) {
      return 'Strong navigation skills! Your spatial recall is solid across $trialsCompleted paths.';
    } else if (overallScore >= 0.5) {
      return 'Good progress! Your spatial memory is building. $trialsCompleted paths explored.';
    } else {
      return 'Great effort! Every path you explore strengthens your spatial memory. $trialsCompleted paths completed.';
    }
  }
}
