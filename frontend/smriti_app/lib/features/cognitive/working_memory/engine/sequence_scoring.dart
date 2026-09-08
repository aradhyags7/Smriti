// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE SCORING ENGINE
// Working memory capacity estimation and error analysis
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';

class SequenceScoring {
  /// Calculate working memory capacity estimate.
  /// Based on span × accuracy formula (Cowan's K approximation).
  static double workingMemoryCapacity({
    required int maxSpan,
    required double accuracy,
  }) {
    return maxSpan * accuracy;
  }

  /// Calculate the span score as a percentile of max possible.
  static double spanPercentile({
    required int maxSpan,
    required int maxPossibleSpan,
  }) {
    if (maxPossibleSpan == 0) return 0;
    return (maxSpan / maxPossibleSpan).clamp(0.0, 1.0);
  }

  /// Generate a plain-language summary of working memory performance.
  static String generateSummary({
    required int maxSpan,
    required double accuracy,
    required int roundsCompleted,
  }) {
    final wmCapacity = workingMemoryCapacity(
        maxSpan: maxSpan, accuracy: accuracy);

    if (wmCapacity >= 6.0) {
      return 'Outstanding working memory! You handled sequences of $maxSpan — that\'s exceptional recall! 🧠';
    } else if (wmCapacity >= 4.0) {
      return 'Strong working memory! Sequences of $maxSpan with solid accuracy — great cognitive exercise!';
    } else if (wmCapacity >= 2.5) {
      return 'Good progress! Your memory span reached $maxSpan. Every round strengthens your recall! 💪';
    } else {
      return 'Great effort! You completed $roundsCompleted rounds. Your brain thanks you for the workout! 🌟';
    }
  }

  /// Calculate error rates from error counts.
  static Map<String, double> errorRates({
    required int insertions,
    required int omissions,
    required int transpositions,
    required int totalExpectedItems,
  }) {
    if (totalExpectedItems == 0) {
      return {
        'insertionRate': 0,
        'omissionRate': 0,
        'transpositionRate': 0,
      };
    }
    return {
      'insertionRate': insertions / max(totalExpectedItems, 1),
      'omissionRate': omissions / totalExpectedItems,
      'transpositionRate': transpositions / max(totalExpectedItems, 1),
    };
  }
}
