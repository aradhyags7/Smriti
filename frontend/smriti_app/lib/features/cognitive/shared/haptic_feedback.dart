// ─────────────────────────────────────────────────────────────────────────────
// HAPTIC FEEDBACK HELPER
// Thin wrapper for consistent multi-sensory feedback across all games
// Proprioceptive reinforcement aids memory consolidation in dementia patients
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';

class SmritiHaptics {
  /// Light tap feedback — correct response confirmation.
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — milestone achievement.
  static Future<void> milestone() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — session complete.
  static Future<void> sessionComplete() async {
    await HapticFeedback.heavyImpact();
  }

  /// Gentle selection click — UI navigation / button press.
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Gentle vibration — rest prompt or attention cue.
  static Future<void> gentlePulse() async {
    await HapticFeedback.vibrate();
  }

  /// No vibration for wrong answers — we don't punish.
  /// Instead, we use a very soft click to acknowledge the tap was registered.
  static Future<void> softAcknowledge() async {
    await HapticFeedback.selectionClick();
  }
}
