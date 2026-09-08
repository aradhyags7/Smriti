// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE CHECK MODELS
// Data contracts for working memory / sequence recall game
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Difficulty tiers for Sequence Check.
enum SequenceDifficulty {
  simple,
  moderate,
  harder,
}

/// A single tile flash during sequence playback.
class TileFlashEvent {
  final int tileIndex;
  final int timestamp;
  final int durationMs;
  final Color color;

  const TileFlashEvent({
    required this.tileIndex,
    required this.timestamp,
    required this.durationMs,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'tileIndex': tileIndex,
        'timestamp': timestamp,
        'durationMs': durationMs,
        'color': color.toARGB32(),
      };
}

/// Configuration for a single sequence round.
class SequenceRoundConfig {
  final int roundIndex;
  final List<int> targetSequence;
  final int gridSize; // 3 for 3x3, 4 for 4x4
  final int flashDurationMs;
  final int interFlashDelayMs;
  final bool hasInterference; // Visual distractor between playback and recall
  final bool isReverseRecall;
  final bool hasDualTask; // Secondary color recall challenge
  final List<Color>? tileColors; // For dual-task mode
  final int cognitiveLoad;

  const SequenceRoundConfig({
    required this.roundIndex,
    required this.targetSequence,
    required this.gridSize,
    required this.flashDurationMs,
    required this.interFlashDelayMs,
    this.hasInterference = false,
    this.isReverseRecall = false,
    this.hasDualTask = false,
    this.tileColors,
    required this.cognitiveLoad,
  });
}

/// Difficulty parameters for each tier.
class SequenceDifficultyParams {
  final int gridSize;
  final int startLength;
  final int maxLength;
  final int flashDurationMs;
  final int interFlashDelayMs;
  final bool enableInterference;
  final bool enableReverseRecall;
  final bool enableDualTask;
  final int maxRounds;
  final String tierLabel;

  const SequenceDifficultyParams({
    required this.gridSize,
    required this.startLength,
    required this.maxLength,
    required this.flashDurationMs,
    required this.interFlashDelayMs,
    required this.enableInterference,
    required this.enableReverseRecall,
    required this.enableDualTask,
    required this.maxRounds,
    required this.tierLabel,
  });

  /// Get the preset parameters for each difficulty level.
  /// Tuned for users aged 55+ to provide gentle, progressive working memory
  /// stimulation without overwhelming cognitive load.
  static SequenceDifficultyParams forDifficulty(SequenceDifficulty diff) {
    switch (diff) {
      case SequenceDifficulty.simple:
        // Easy: 3×3 grid, short 2–4 item sequences, slow 900ms flashes.
        // Highly achievable — target ~85% success rate to build confidence.
        return const SequenceDifficultyParams(
          gridSize: 3,
          startLength: 2,
          maxLength: 4,   // Was 5 — reduced to prevent overload
          flashDurationMs: 900,  // Was 700ms — more time to register each tile
          interFlashDelayMs: 600, // Was 400ms — breathing room between flashes
          enableInterference: false,
          enableReverseRecall: false,
          enableDualTask: false, // Dual-task removed — too demanding for 55+
          maxRounds: 8,   // Was 12 — shorter session, less fatigue
          tierLabel: 'Pattern Start',
        );
      case SequenceDifficulty.moderate:
        // Moderate: 3×3 grid, 3–5 items, 700ms flashes.
        // Maintains 3×3 grid — 4×4 is too visually complex for 55+.
        return const SequenceDifficultyParams(
          gridSize: 3,
          startLength: 3,
          maxLength: 5,   // Was 7 — keeps challenge achievable
          flashDurationMs: 700,  // Was 500ms — comfortable processing time
          interFlashDelayMs: 500, // Was 300ms
          enableInterference: false, // No interference until Hard
          enableReverseRecall: false,
          enableDualTask: false,
          maxRounds: 10,  // Was 15
          tierLabel: 'Pattern Builder',
        );
      case SequenceDifficulty.harder:
        // Hard: 3×3 grid, 3–6 items, 550ms flashes, interference from round 6.
        // Still no dual-task or reverse recall — challenge comes from interference
        // and the adaptive span reaching 6 items.
        return const SequenceDifficultyParams(
          gridSize: 3,   // Was 4×4 — kept at 3×3 for 55+ visual comfort
          startLength: 3,
          maxLength: 6,   // Was 9 — 6 items is a meaningful stretch for 55+
          flashDurationMs: 550,  // Was 350ms — still fast but not rushed
          interFlashDelayMs: 400, // Was 250ms
          enableInterference: true, // Mild distractor, only from round 6
          enableReverseRecall: false, // Off — cognitive load already sufficient
          enableDualTask: false,  // Off — too stressful for target age group
          maxRounds: 12,  // Was 18
          tierLabel: 'Pattern Challenge',
        );
    }
  }
}

/// Error classification for working memory analysis.
enum SequenceErrorType {
  insertion, // User tapped extra tiles not in sequence
  omission, // User missed tiles that were in sequence
  transposition, // Correct tiles but wrong order
}

/// Tile color palette for dual-task mode.
class SequenceColors {
  static const List<Color> taskColors = [
    Color(0xFF00F0FF), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFF2DD4BF), // Teal
    Color(0xFFA78BFA), // Purple
    Color(0xFFF87171), // Red
    Color(0xFF34D399), // Green
  ];

  static Color getColor(int index) {
    return taskColors[index % taskColors.length];
  }
}
