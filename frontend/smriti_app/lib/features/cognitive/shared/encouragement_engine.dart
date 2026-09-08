// ─────────────────────────────────────────────────────────────────────────────
// ENCOURAGEMENT ENGINE
// Positive reinforcement system — NO negative language ever
// Clinically proven to improve engagement and adherence in dementia patients
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';

class EncouragementEngine {
  final Random _random = Random();

  // ── Message pools ──

  static const List<String> _correctMessages = [
    'Great job! 🌟',
    'Nicely done!',
    'Sharp mind! ✨',
    'Excellent focus!',
    'Well spotted! 👁️',
    'Perfect recall!',
    'You\'re on fire! 🔥',
    'Wonderful!',
    'That was quick!',
    'Brilliant!',
  ];

  static const List<String> _encourageAfterMiss = [
    'Almost there! Try again 💪',
    'Good effort! Let\'s keep going',
    'You\'re learning! That\'s what matters',
    'Take your time — no rush',
    'Every attempt trains your brain',
    'Getting closer!',
    'That was a tricky one!',
    'You\'ve got this! 🌈',
    'Stay steady — you\'re doing great',
    'Practice makes progress!',
  ];

  static const List<String> _milestoneMessages = [
    'Amazing streak! Your brain is loving this! 🧠',
    'Incredible focus! You\'re improving beautifully!',
    'Milestone reached! You should be proud! 🏆',
    'Your brain is getting stronger every session!',
    'What an achievement! Keep it up! 🌟',
  ];

  static const List<String> _sessionCompleteMessages = [
    'You trained your brain today! That\'s what counts! 💚',
    'Every session helps build stronger neural pathways! 🧠',
    'Wonderful session — your future self thanks you!',
    'Brain exercise complete! You\'re investing in your health!',
    'Great work today! Rest well and come back stronger! 🌟',
  ];

  static const List<String> _restPromptMessages = [
    'Let\'s take a breather — your brain deserves it 🌿',
    'Quick rest break — you\'ve been working hard!',
    'Take a moment to relax — we\'ll continue soon',
    'A short pause helps your brain consolidate learning',
    'Breathe deeply — rest is part of the training',
  ];

  static const List<String> _spatialEncourage = [
    'Great spatial awareness! 🗺️',
    'Your navigation skills are sharp!',
    'Excellent sense of direction!',
    'You remembered the path perfectly!',
  ];

  static const List<String> _sequenceEncourage = [
    'Your working memory is impressive! 🔢',
    'Sequence mastered!',
    'Excellent pattern recall!',
    'Your memory span is growing!',
  ];

  // ── Public API ──

  /// Get a positive message for a correct response.
  String getCorrectMessage() => _pick(_correctMessages);

  /// Get an encouraging message after an incorrect response (NEVER negative).
  String getMissMessage() => _pick(_encourageAfterMiss);

  /// Get a milestone celebration message.
  String getMilestoneMessage() => _pick(_milestoneMessages);

  /// Get a session completion message.
  String getSessionCompleteMessage() => _pick(_sessionCompleteMessages);

  /// Get a rest prompt message.
  String getRestPromptMessage() => _pick(_restPromptMessages);

  /// Get a game-specific encouragement.
  String getSpatialEncouragement() => _pick(_spatialEncourage);
  String getSequenceEncouragement() => _pick(_sequenceEncourage);

  /// Determine if a milestone message should be shown based on streak.
  bool shouldShowMilestone(int consecutiveCorrect) {
    // Show milestone at 5, 10, 15, 20...
    return consecutiveCorrect > 0 && consecutiveCorrect % 5 == 0;
  }

  /// Get appropriate message based on accuracy.
  String getAccuracyFeedback(double accuracy) {
    if (accuracy >= 0.9) return 'Outstanding accuracy! 🏆';
    if (accuracy >= 0.75) return 'Solid performance! Keep it up! 💪';
    if (accuracy >= 0.5) return 'Great effort! You\'re improving! 🌱';
    return 'Every session helps your brain grow stronger! 🧠';
  }

  String _pick(List<String> pool) => pool[_random.nextInt(pool.length)];
}
