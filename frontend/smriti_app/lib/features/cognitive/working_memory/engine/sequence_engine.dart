// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE ENGINE
// Sequence generation, adaptive length control, and interference injection
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sequence_check_models.dart';

class SequenceEngine {
  final Random _random = Random();
  final SequenceDifficultyParams params;

  // ── Adaptive span control ──
  int _currentLength;
  int _consecutiveCorrectAtLength = 0;
  int _consecutiveWrongAtLength = 0;
  int _maxSpanReached;

  SequenceEngine({required this.params})
      : _currentLength = params.startLength,
        _maxSpanReached = params.startLength;

  /// Get the current sequence length.
  int get currentLength => _currentLength;

  /// Get the maximum span achieved so far.
  int get maxSpan => _maxSpanReached;

  /// Generate a sequence round configuration.
  SequenceRoundConfig generateRound({required int roundIndex}) {
    final totalTiles = params.gridSize * params.gridSize;

    // Generate random sequence with constraints
    final sequence = _generateSequence(
      length: _currentLength,
      maxTile: totalTiles,
    );

    // Determine challenge variations
    final bool hasInterference =
        params.enableInterference && roundIndex >= 3 && _random.nextInt(3) == 0;
    final bool isReverse =
        params.enableReverseRecall && roundIndex >= 6 && _random.nextBool();

    // Dual-task: assign colors to tiles
    List<Color>? tileColors;
    final bool hasDualTask =
        params.enableDualTask && roundIndex >= 4 && _random.nextInt(3) == 0;
    if (hasDualTask) {
      tileColors = List.generate(
        sequence.length,
        (_) => SequenceColors.getColor(_random.nextInt(SequenceColors.taskColors.length)),
      );
    }

    // Calculate cognitive load (1-10)
    int cogLoad = 2 + _currentLength;
    if (hasInterference) cogLoad += 1;
    if (isReverse) cogLoad += 2;
    if (hasDualTask) cogLoad += 2;
    cogLoad = cogLoad.clamp(1, 10);

    return SequenceRoundConfig(
      roundIndex: roundIndex,
      targetSequence: sequence,
      gridSize: params.gridSize,
      flashDurationMs: params.flashDurationMs,
      interFlashDelayMs: params.interFlashDelayMs,
      hasInterference: hasInterference,
      isReverseRecall: isReverse,
      hasDualTask: hasDualTask,
      tileColors: tileColors,
      cognitiveLoad: cogLoad,
    );
  }

  /// Generate a random sequence with constraints:
  /// - No more than 2 consecutive same-tile repeats
  /// - Tiles within valid range
  List<int> _generateSequence({required int length, required int maxTile}) {
    final sequence = <int>[];

    for (int i = 0; i < length; i++) {
      int candidate;
      int attempts = 0;
      do {
        candidate = _random.nextInt(maxTile);
        attempts++;
      } while (_hasThreeConsecutive(sequence, candidate) && attempts < 50);

      sequence.add(candidate);
    }

    return sequence;
  }

  /// Check if adding `next` would create 3+ consecutive same tiles.
  bool _hasThreeConsecutive(List<int> current, int next) {
    if (current.length < 2) return false;
    return current[current.length - 1] == next &&
        current[current.length - 2] == next;
  }

  /// Report the result of a round and adjust span adaptively.
  /// Returns: 'increase', 'repeat', or 'decrease'.
  String reportResult(bool isCorrect) {
    if (isCorrect) {
      _consecutiveCorrectAtLength++;
      _consecutiveWrongAtLength = 0;

      if (_currentLength > _maxSpanReached) {
        _maxSpanReached = _currentLength;
      }

      // 2 correct in a row at this length → increase by 1
      if (_consecutiveCorrectAtLength >= 2) {
        if (_currentLength < params.maxLength) {
          _currentLength++;
          _consecutiveCorrectAtLength = 0;
          return 'increase';
        }
      }
      return 'repeat';
    } else {
      _consecutiveWrongAtLength++;
      _consecutiveCorrectAtLength = 0;

      // 3 wrong at same length → decrease by 1 (not game over!)
      if (_consecutiveWrongAtLength >= 3) {
        if (_currentLength > 2) {
          _currentLength--;
          _consecutiveWrongAtLength = 0;
          return 'decrease';
        }
      }
      // 1 wrong → repeat same length
      return 'repeat';
    }
  }

  /// Classify errors between expected and actual sequences.
  Map<SequenceErrorType, int> classifyErrors(
      List<int> expected, List<int> actual) {
    int insertions = 0;
    int omissions = 0;
    int transpositions = 0;

    // Count elements present in actual but not in expected (insertions)
    final expectedSet = expected.toSet();
    for (final tile in actual) {
      if (!expectedSet.contains(tile)) {
        insertions++;
      }
    }

    // Count elements present in expected but not in actual (omissions)
    final actualSet = actual.toSet();
    for (final tile in expected) {
      if (!actualSet.contains(tile)) {
        omissions++;
      }
    }

    // Count position mismatches for shared elements (transpositions)
    final minLen = min(expected.length, actual.length);
    for (int i = 0; i < minLen; i++) {
      if (expected[i] != actual[i] &&
          expectedSet.contains(actual[i]) &&
          actualSet.contains(expected[i])) {
        transpositions++;
      }
    }

    return {
      SequenceErrorType.insertion: insertions,
      SequenceErrorType.omission: omissions,
      SequenceErrorType.transposition: transpositions ~/ 2, // Pairs
    };
  }

  /// Check if the user sequence matches the expected (considering reverse mode).
  bool checkSequence(List<int> expected, List<int> actual,
      {bool isReverse = false}) {
    final target = isReverse ? expected.reversed.toList() : expected;
    if (target.length != actual.length) return false;
    for (int i = 0; i < target.length; i++) {
      if (target[i] != actual[i]) return false;
    }
    return true;
  }
}
