/*
 * Intent Engine — Pure Dart, completely offline.
 *
 * Responsibilities:
 *   - Receive a raw transcript string.
 *   - Normalize the transcript.
 *   - Match against multilingual phrase patterns.
 *   - Return a [VoiceIntentResult] with a typed [VoiceIntent],
 *     a confidence score, and an extensible parameters map.
 *
 * This file has NO dependency on:
 *   Flutter framework, BuildContext, navigation, STT, TTS,
 *   notifications, databases, or any network/API call.
 */

// ---------------------------------------------------------------------------
// VoiceIntent Enum
// ---------------------------------------------------------------------------

/// All intents the voice assistant can recognize.
enum VoiceIntent {
  /// Launch a cognitive game (e.g. memory pairs).
  startGame,

  /// Open the reminiscence / memory vault.
  openMemory,

  /// Create or schedule a reminder.
  setReminder,

  /// Initiate a call to the patient's caregiver.
  callCaregiver,

  /// Show today's schedule and activities.
  checkToday,

  /// Show the patient's cognitive progress / score.
  showProgress,

  /// Transcript did not match any known intent.
  unknown,
}

// ---------------------------------------------------------------------------
// VoiceIntentResult
// ---------------------------------------------------------------------------

/// The structured result returned by [IntentEngine.recognize].
class VoiceIntentResult {
  /// The recognized intent (or [VoiceIntent.unknown]).
  final VoiceIntent intent;

  /// The normalized transcript that was processed.
  final String transcript;

  /// Confidence in the match. Range [0.0, 1.0].
  /// A value of 0.0 means no match ([VoiceIntent.unknown]).
  final double confidence;

  /// Extensible parameters extracted from the transcript.
  ///
  /// Currently empty for most intents. Future expansions:
  ///   - [VoiceIntent.setReminder]: {"reminderText": "...", "time": "..."}
  ///   - [VoiceIntent.startGame]: {"gameType": "memory_pairs"}
  final Map<String, dynamic>? parameters;

  const VoiceIntentResult({
    required this.intent,
    required this.transcript,
    required this.confidence,
    this.parameters,
  });

  @override
  String toString() =>
      'VoiceIntentResult('
      'intent: $intent, '
      'confidence: ${confidence.toStringAsFixed(2)}, '
      'transcript: "$transcript")';
}

// ---------------------------------------------------------------------------
// _PatternEntry — internal matching unit
// ---------------------------------------------------------------------------

/// A single pattern entry with a list of keyword groups.
///
/// A phrase matches if the transcript contains at least one token from
/// EVERY required [keywordGroups] in the entry (logical AND of groups,
/// OR within each group).
///
/// [weight] allows tuning: longer / more specific phrases score higher.
class _PatternEntry {
  /// Each inner list is an OR group; all groups must match (AND).
  final List<List<String>> keywordGroups;

  /// Specificity weight used in confidence calculation.
  final double weight;

  /// Intents that must NOT also be triggered by this match (disambiguation).
  const _PatternEntry(this.keywordGroups, {this.weight = 1.0});
}

// ---------------------------------------------------------------------------
// IntentEngine
// ---------------------------------------------------------------------------

/// Deterministic, offline, multilingual intent recognizer.
///
/// Supported languages: English, Hindi, Bengali.
/// Assamese is NOT included in speech-command matching because STT support
/// for Assamese has not been validated at this stage.
class IntentEngine {
  // -------------------------------------------------------------------------
  // Pattern Tables
  // -------------------------------------------------------------------------

  // Each intent maps to a list of [_PatternEntry] objects.
  // Patterns are ordered: most specific (highest weight) first.
  // The engine scores ALL matching patterns and picks the intent with the
  // highest aggregate weighted score.

  static const Map<VoiceIntent, List<_PatternEntry>> _patterns = {
    // -----------------------------------------------------------------------
    // startGame
    // -----------------------------------------------------------------------
    VoiceIntent.startGame: [
      // English — specific game references
      _PatternEntry([
        ['start', 'play', 'begin', 'open', 'launch'],
        ['memory', 'game', 'games', 'puzzle'],
      ], weight: 1.5),
      // English — "let's play" style
      _PatternEntry([
        ["let's play", 'wanna play', 'want to play', 'i want to play'],
      ], weight: 1.2),
      // Hindi — मेमोरी गेम शुरू करो / चलाओ
      _PatternEntry([
        ['गेम', 'खेल'],
        ['शुरू', 'चलाओ', 'खेलते', 'खेलो', 'चालू'],
      ], weight: 1.5),
      _PatternEntry([
        ['मेमोरी'],
        ['शुरू', 'चलाओ', 'खेलो'],
      ], weight: 1.5),
      // Bengali — মেমোরি গেম শুরু করো
      _PatternEntry([
        ['গেম', 'খেলা', 'মেমোরি'],
        ['শুরু', 'করো', 'চালাও', 'খেলো', 'চালু'],
      ], weight: 1.5),
    ],

    // -----------------------------------------------------------------------
    // openMemory
    // -----------------------------------------------------------------------
    VoiceIntent.openMemory: [
      // English
      _PatternEntry([
        ['open', 'show', 'see', 'view', 'browse', 'go to'],
        ['memor', 'memories', 'memory', 'vault', 'reminiscence', 'photo'],
      ], weight: 1.5),
      _PatternEntry([
        ['my memories', 'my photos', 'my pictures'],
      ], weight: 1.2),
      // Hindi — यादें / मेमोरी vault
      _PatternEntry([
        ['यादें', 'यादों', 'यादे'],
        ['खोलो', 'दिखाओ', 'देखना', 'देखो'],
      ], weight: 1.5),
      _PatternEntry([
        ['मेरी यादें', 'मेरी यादों'],
      ], weight: 1.3),
      // Bengali — স্মৃতি / ছবি
      _PatternEntry([
        ['স্মৃতি', 'স্মৃতিগুলো', 'ছবি', 'মেমোরি'],
        ['খোলো', 'দেখাও', 'দেখতে', 'দেখি'],
      ], weight: 1.5),
      _PatternEntry([
        ['আমার স্মৃতি', 'আমার স্মৃতিগুলো'],
      ], weight: 1.3),
    ],

    // -----------------------------------------------------------------------
    // setReminder
    // -----------------------------------------------------------------------
    VoiceIntent.setReminder: [
      // English
      _PatternEntry([
        ['set', 'create', 'add', 'make', 'schedule', 'put'],
        ['reminder', 'alarm', 'alert', 'notification'],
      ], weight: 1.5),
      _PatternEntry([
        ['remind me', 'remind me later', 'set an alarm', 'add a reminder'],
      ], weight: 1.4),
      _PatternEntry([
        ['remind'],
      ], weight: 0.9),
      // Hindi — रिमाइंडर / याद दिलाओ
      _PatternEntry([
        ['रिमाइंडर'],
        ['लगाओ', 'सेट करो', 'बनाओ', 'लगाना'],
      ], weight: 1.5),
      _PatternEntry([
        ['मुझे याद दिलाओ', 'याद दिलाओ', 'याद दिला'],
      ], weight: 1.4),
      _PatternEntry([
        ['याद दिलाओ'],
      ], weight: 1.0),
      // Bengali — রিমাইন্ডার / মনে করিয়ে
      _PatternEntry([
        ['রিমাইন্ডার', 'অনুস্মারক'],
        ['সেট', 'দাও', 'করো', 'লাগাও'],
      ], weight: 1.5),
      _PatternEntry([
        ['মনে করিয়ে দাও', 'মনে করিয়ে'],
      ], weight: 1.4),
    ],

    // -----------------------------------------------------------------------
    // callCaregiver
    // -----------------------------------------------------------------------
    VoiceIntent.callCaregiver: [
      // English
      _PatternEntry([
        ['call', 'phone', 'contact', 'ring', 'reach'],
        ['caregiver', 'helper', 'nurse', 'doctor', 'carer'],
      ], weight: 1.5),
      _PatternEntry([
        ['i need', 'i want'],
        ['caregiver', 'helper', 'nurse', 'carer'],
      ], weight: 1.3),
      _PatternEntry([
        ['need help', 'get help', 'call for help'],
      ], weight: 1.0),
      // Hindi — केयरगिवर को बुलाओ / कॉल करो
      _PatternEntry([
        ['केयरगिवर', 'देखभाल करने वाले', 'मदद'],
        ['बुलाओ', 'कॉल करो', 'बुला', 'फोन'],
      ], weight: 1.5),
      _PatternEntry([
        ['केयरगिवर को बुलाओ', 'केयरगिवर को कॉल'],
      ], weight: 1.4),
      // Bengali — কেয়ারগিভার কল করো
      _PatternEntry([
        ['কেয়ারগিভার', 'সাহায্যকারী', 'নার্স'],
        ['কল', 'ডাকো', 'ফোন', 'ডাক'],
      ], weight: 1.5),
      _PatternEntry([
        ['কেয়ারগিভারকে কল'],
      ], weight: 1.4),
    ],

    // -----------------------------------------------------------------------
    // checkToday
    // -----------------------------------------------------------------------
    VoiceIntent.checkToday: [
      // English
      _PatternEntry([
        ['today', "today's"],
        ['schedule', 'activities', 'activity', 'plan', 'tasks', 'list', 'what'],
      ], weight: 1.5),
      _PatternEntry([
        ['check today', 'what do i have today', "what's today",
         "what's on today", 'show today'],
      ], weight: 1.4),
      _PatternEntry([
        ['today'],
      ], weight: 0.8),
      // Hindi — आज का / आज की
      _PatternEntry([
        ['आज'],
        ['का', 'की', 'क्या', 'दिखाओ', 'बताओ', 'है'],
      ], weight: 1.4),
      _PatternEntry([
        ['आज का दिन', 'आज का क्या', 'आज क्या है'],
      ], weight: 1.5),
      // Bengali — আজকের দিন / আজ কী আছে
      _PatternEntry([
        ['আজকের', 'আজ'],
        ['দিন', 'কী', 'কি', 'আছে', 'দেখাও', 'বলো'],
      ], weight: 1.4),
      _PatternEntry([
        ['আজকের দিন দেখাও', 'আজ কী আছে', 'আজ কি আছে'],
      ], weight: 1.5),
    ],

    // -----------------------------------------------------------------------
    // showProgress
    // -----------------------------------------------------------------------
    VoiceIntent.showProgress: [
      // English
      _PatternEntry([
        ['show', 'see', 'check', 'view', 'display', 'tell'],
        ['progress', 'progressing', 'score', 'performance', 'result', 'report'],
      ], weight: 1.5),
      _PatternEntry([
        ['how am i doing', 'how have i been doing', 'how did i do', 'how am i progressing', 'how i am progressing'],
      ], weight: 1.4),
      _PatternEntry([
        ['my progress', 'my score', 'my results'],
      ], weight: 1.2),
      // Hindi — प्रोग्रेस / प्रगति दिखाओ
      _PatternEntry([
        ['प्रोग्रेस', 'प्रगति', 'स्कोर', 'परिणाम'],
        ['दिखाओ', 'बताओ', 'देखना', 'देखो'],
      ], weight: 1.5),
      _PatternEntry([
        ['मेरा प्रोग्रेस', 'मेरी प्रगति', 'मेरा स्कोर'],
      ], weight: 1.3),
      // Bengali — অগ্রগতি / স্কোর দেখাও
      _PatternEntry([
        ['অগ্রগতি', 'স্কোর', 'ফলাফল', 'প্রগতি'],
        ['দেখাও', 'বলো', 'জানাও'],
      ], weight: 1.5),
      _PatternEntry([
        ['আমার অগ্রগতি', 'আমার স্কোর'],
      ], weight: 1.3),
    ],
  };

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Recognize the intent of [rawTranscript].
  ///
  /// Returns a [VoiceIntentResult] with the best-matched [VoiceIntent]
  /// and a confidence score in [0.0, 1.0].
  ///
  /// Returns [VoiceIntent.unknown] with confidence 0.0 when:
  ///   - [rawTranscript] is null, empty, or whitespace only.
  ///   - No pattern group reaches the minimum confidence threshold.
  VoiceIntentResult recognize(String? rawTranscript) {
    // ------------------------------------------------------------------
    // Guard: null / empty
    // ------------------------------------------------------------------
    if (rawTranscript == null || rawTranscript.trim().isEmpty) {
      return const VoiceIntentResult(
        intent: VoiceIntent.unknown,
        transcript: '',
        confidence: 0.0,
      );
    }

    final normalized = _normalize(rawTranscript);

    // ------------------------------------------------------------------
    // Score each intent
    // ------------------------------------------------------------------
    final scores = <VoiceIntent, double>{};

    for (final entry in _patterns.entries) {
      final intent = entry.key;
      final patternList = entry.value;

      double bestScore = 0.0;

      for (final pattern in patternList) {
        final score = _scorePattern(normalized, pattern);
        if (score > bestScore) bestScore = score;
      }

      if (bestScore > 0.0) {
        scores[intent] = bestScore;
      }
    }

    // ------------------------------------------------------------------
    // No match
    // ------------------------------------------------------------------
    if (scores.isEmpty) {
      return VoiceIntentResult(
        intent: VoiceIntent.unknown,
        transcript: normalized,
        confidence: 0.0,
      );
    }

    // ------------------------------------------------------------------
    // Pick best intent; handle ties deterministically (enum order).
    // ------------------------------------------------------------------
    VoiceIntent bestIntent = VoiceIntent.unknown;
    double bestScore = 0.0;

    // Sort by score descending, then by enum index ascending for determinism.
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.index.compareTo(b.key.index);
      });

    bestIntent = sorted.first.key;
    bestScore = sorted.first.value;

    // ------------------------------------------------------------------
    // Normalise score to [0.0, 1.0]
    // The maximum possible raw score from a 1.5-weight full match ≈ 1.0
    // after the formula below. Values above 1.0 are clamped.
    // ------------------------------------------------------------------
    final confidence = bestScore.clamp(0.0, 1.0);

    // ------------------------------------------------------------------
    // Build parameters (extensible stub)
    // ------------------------------------------------------------------
    final params = _extractParameters(bestIntent, normalized);

    return VoiceIntentResult(
      intent: bestIntent,
      transcript: normalized,
      confidence: confidence,
      parameters: params.isNotEmpty ? params : null,
    );
  }

  // -------------------------------------------------------------------------
  // Internal: normalize
  // -------------------------------------------------------------------------

  /// Normalize a raw transcript for reliable pattern matching.
  ///
  /// Steps:
  ///   1. Trim surrounding whitespace.
  ///   2. Collapse multiple spaces/tabs into a single space.
  ///   3. Remove trailing punctuation characters (.,!?।).
  ///   4. Lowercase ASCII characters (safe for Unicode scripts; Hindi/Bengali
  ///      glyphs are already case-neutral).
  String _normalize(String raw) {
    var s = raw.trim();
    // Collapse whitespace runs.
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // Remove trailing sentence-ending punctuation.
    s = s.replaceAll(RegExp(r'[.!?,।]+$'), '').trim();
    // Lowercase (safe for Unicode — only affects ASCII).
    s = s.toLowerCase();
    // Deterministic phonetic alias for Bengali Whisper transcription variant.
    s = s.replaceAll('ওষধ', 'ওষুধ');
    return s;
  }

  // -------------------------------------------------------------------------
  // Internal: score a single pattern entry
  // -------------------------------------------------------------------------

  /// Returns a weighted score for [pattern] against [normalized].
  ///
  /// Scoring logic:
  ///   - Every keyword group must have at least one match (AND).
  ///   - A group matches if the transcript CONTAINS any of its keywords.
  ///   - If all groups match, the raw score is:
  ///       (matchedGroups / totalGroups) * weight
  ///   - If any group fails, score = 0.0.
  double _scorePattern(String normalized, _PatternEntry pattern) {
    int matchedGroups = 0;
    final total = pattern.keywordGroups.length;

    for (final group in pattern.keywordGroups) {
      bool groupMatched = false;
      for (final keyword in group) {
        // Use word-boundary-aware containment: the keyword must appear as a
        // substring with word-boundary padding to avoid false partial matches
        // (e.g. "game" should not match "caregiver").
        if (_containsKeyword(normalized, keyword)) {
          groupMatched = true;
          break;
        }
      }
      if (!groupMatched) return 0.0; // AND fails → entire pattern fails.
      matchedGroups++;
    }

    return (matchedGroups / total) * pattern.weight;
  }

  // -------------------------------------------------------------------------
  // Internal: safe keyword containment check
  // -------------------------------------------------------------------------

  /// Returns true if [text] contains [keyword] as a whole word or phrase.
  ///
  /// For single-word ASCII keywords, wraps in word boundaries (\b).
  /// For multi-word phrases and Unicode keywords, uses plain [contains]
  /// since \b does not work with non-ASCII characters.
  bool _containsKeyword(String text, String keyword) {
    if (keyword.isEmpty) return false;

    // Multi-word phrase or Unicode script: use plain contains.
    final isAsciiSingleWord =
        !keyword.contains(' ') && RegExp(r'^[a-z0-9]+$').hasMatch(keyword);

    if (isAsciiSingleWord) {
      // Word-boundary match to avoid partial hits.
      return RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(text);
    }

    // For multi-word ASCII phrases and Unicode phrases.
    return text.contains(keyword);
  }

  // -------------------------------------------------------------------------
  // Internal: extract parameters
  // -------------------------------------------------------------------------

  /// Extract structured parameters from the transcript for a recognized intent.
  ///
  /// Currently returns an empty map for all intents except [VoiceIntent.setReminder],
  /// which returns a stub indicating no time extraction was attempted.
  ///
  /// Future expansions:
  ///   - Parse time expressions ("at 8 AM", "in 30 minutes") via a dedicated
  ///     time-parser module.
  ///   - Parse game type for [VoiceIntent.startGame].
  Map<String, dynamic> _extractParameters(
      VoiceIntent intent, String normalized) {
    switch (intent) {
      case VoiceIntent.setReminder:
        // Stub: full NL time-extraction is a future task.
        // Returning an empty parameters map signals "text only, no time parsed".
        return {};
      default:
        return {};
    }
  }
}
