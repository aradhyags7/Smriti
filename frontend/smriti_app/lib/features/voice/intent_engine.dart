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

/// The recognized intent of a user voice utterance.
enum VoiceIntent {
  /// User wants to launch or play a cognitive game.
  startGame,

  /// User wants to open the memory/reminiscence vault.
  openMemory,

  /// User wants to schedule or create a reminder.
  setReminder,

  /// User wants to contact their assigned caregiver or ASHA worker.
  callCaregiver,

  /// User wants to see their schedule or activities for today.
  checkToday,

  /// User wants to view their cognitive progress or score trends.
  showProgress,

  /// The input did not match any supported intent with sufficient confidence.
  unknown,
}

// ---------------------------------------------------------------------------
// VoiceIntentResult
// ---------------------------------------------------------------------------

/// Structured output from [IntentEngine.recognize].
class VoiceIntentResult {
  /// The classified intent.
  final VoiceIntent intent;

  /// The normalized transcript string used for classification.
  final String transcript;

  /// Recognition confidence in [0.0, 1.0].
  final double confidence;

  /// Extracted slots/parameters (e.g. {'time': '08:00', 'type': 'pulse'}).
  final Map<String, dynamic>? parameters;

  const VoiceIntentResult({
    required this.intent,
    required this.transcript,
    required this.confidence,
    this.parameters,
  });

  @override
  String toString() =>
      'VoiceIntentResult(intent: $intent, confidence: ${confidence.toStringAsFixed(2)}, transcript: "$transcript", parameters: $parameters)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceIntentResult &&
          runtimeType == other.runtimeType &&
          intent == other.intent &&
          transcript == other.transcript &&
          (confidence - other.confidence).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(intent, transcript, confidence);
}

// ---------------------------------------------------------------------------
// Pattern Definition Internal Models
// ---------------------------------------------------------------------------

class _PatternEntry {
  final List<List<String>> keywordGroups;
  final double weight;

  const _PatternEntry(this.keywordGroups, {this.weight = 1.0});
}

// ---------------------------------------------------------------------------
// IntentEngine
// ---------------------------------------------------------------------------

/// Deterministic, offline, multilingual intent recognizer.
class IntentEngine {
  static const Map<VoiceIntent, List<_PatternEntry>> _patterns = {
    // -----------------------------------------------------------------------
    // startGame
    // -----------------------------------------------------------------------
    VoiceIntent.startGame: [
      // English — specific game titles
      _PatternEntry([
        [
          'pulse trainer',
          'pulse',
          'wayfinder',
          'sequence check',
          'sequence',
          'memory walk',
          'daily games',
          'daily game',
          'daily calibration',
          'calibration test',
          'calibration',
        ],
      ], weight: 1.6),

      // English — action + game
      _PatternEntry([
        ['start', 'play', 'begin', 'open', 'launch', 'run'],
        [
          'game',
          'games',
          'puzzle',
          'puzzles',
          'exercise',
          'exercises',
          'trainer',
          'wayfinder',
          'sequence',
          'calibration',
        ],
      ], weight: 1.5),

      // English — "open my game", "this game", "that game"
      _PatternEntry([
        ['open', 'play', 'start', 'launch', 'run'],
        ['my', 'the', 'this', 'that', 'a'],
        ['game', 'games'],
      ], weight: 1.5),

      // English — "let's play" style
      _PatternEntry([
        ["let's play", 'wanna play', 'want to play', 'i want to play', 'play a game'],
      ], weight: 1.3),

      // Standalone game keywords
      _PatternEntry([
        ['game', 'games'],
      ], weight: 0.9),

      // Hindi — खेल / गेम शुरू करो
      _PatternEntry([
        ['गेम', 'खेल', 'पल्स', 'सीक्वेंस', 'वेफाइंडर'],
        ['शुरू', 'चलाओ', 'खेलते', 'खेलो', 'चालू', 'खोलो'],
      ], weight: 1.5),
      _PatternEntry([
        ['मेमोरी'],
        ['गेम'],
        ['शुरू', 'चलाओ', 'खेलो', 'खोलो'],
      ], weight: 1.5),

      // Bengali — গেম শুরু করো
      _PatternEntry([
        ['গেম', 'খেলা'],
        ['শुरू', 'করো', 'চালাও', 'খেলো', 'চালু', 'খোল'],
      ], weight: 1.5),
      _PatternEntry([
        ['মেমোরি'],
        ['গেম'],
        ['শुरू', 'করো', 'চালাও', 'খেলো', 'চালু', 'খোল'],
      ], weight: 1.5),
    ],

    // -----------------------------------------------------------------------
    // openMemory
    // -----------------------------------------------------------------------
    VoiceIntent.openMemory: [
      // English
      _PatternEntry([
        ['open', 'show', 'see', 'view', 'browse', 'go to'],
        ['memor', 'memories', 'memory', 'vault', 'reminiscence', 'photo', 'photos', 'album'],
      ], weight: 1.5),
      _PatternEntry([
        ['my memories', 'my photos', 'my pictures', 'memory vault', 'reminiscence vault'],
      ], weight: 1.4),
      _PatternEntry([
        ['memories', 'photos'],
      ], weight: 0.9),
      // Hindi — यादें / मेमोरी vault
      _PatternEntry([
        ['यादें', 'यादों', 'यादे', 'फोटो', 'तस्वीर'],
        ['खोलो', 'दिखाओ', 'देखना', 'देखो'],
      ], weight: 1.5),
      _PatternEntry([
        ['मेरी यादें', 'पुरानी यादें'],
      ], weight: 1.3),
      // Bengali — স্মৃতি / ছবি
      _PatternEntry([
        ['স্মৃতি', 'স্মৃতিগুলো', 'স্মৃতিগুলা', 'ছবি', 'অ্যালবাম'],
        ['खोलो', 'দেখাও', 'দেখব', 'খোল'],
      ], weight: 1.5),
      _PatternEntry([
        ['আমার স্মৃতি', 'আমার স্মৃতিগুলো'],
      ], weight: 1.3),
    ],

    // -----------------------------------------------------------------------
    // setReminder
    // -----------------------------------------------------------------------
    VoiceIntent.setReminder: [
      // English — full phrase
      _PatternEntry([
        ['set', 'create', 'add', 'put', 'make'],
        ['reminder', 'remainder', 'alarm', 'alert'],
      ], weight: 1.5),
      _PatternEntry([
        ['remind', 'remainder'],
        ['me', 'us'],
      ], weight: 1.4),
      _PatternEntry([
        ['remind me to', 'remind me about', 'remind me for'],
      ], weight: 1.5),
      _PatternEntry([
        ['set my reminder', 'set my remainder', 'set reminder', 'set remainder'],
      ], weight: 1.5),
      _PatternEntry([
        ['medicine reminder', 'medicines reminder', 'medicine remainder', 'medicines remainder', 'pill reminder', 'water reminder', 'doctor reminder'],
      ], weight: 1.5),
      _PatternEntry([
        ['reminder', 'remainder'],
        ['for', 'to', 'at'],
      ], weight: 1.3),
      _PatternEntry([
        ['remind', 'reminder', 'remainder'],
      ], weight: 0.8),
      // Hindi — रिमाइंडर
      _PatternEntry([
        ['रिमाइंडर', 'अलार्म', 'याद'],
        ['लगाओ', 'सेट', 'करो', 'दिलाओ', 'रखो'],
      ], weight: 1.5),
      _PatternEntry([
        ['मुझे याद दिलाओ'],
      ], weight: 1.4),
      _PatternEntry([
        ['दवाई', 'दवा', 'गोली', 'पानी'],
        ['याद', 'रिमाइंडर'],
      ], weight: 1.3),
      _PatternEntry([
        ['रिमाइंडर'],
      ], weight: 0.8),
      // Bengali — রিমাইন্ডার
      _PatternEntry([
        ['রিমাইন্ডার', 'অ্যালার্ম', 'মনে'],
        ['সেট', 'করো', 'দাও', 'রাখো', 'করিয়ে'],
      ], weight: 1.5),
      _PatternEntry([
        ['আমাকে মনে করিয়ে দাও', 'মনে করিয়ে দাও'],
      ], weight: 1.4),
      _PatternEntry([
        ['ওষুধ', 'ওষধ', 'জল', 'পানি'],
        ['মনে', 'রিমাইন্ডার'],
      ], weight: 1.3),
      _PatternEntry([
        ['রিমাইন্ডার'],
      ], weight: 0.8),
    ],

    // -----------------------------------------------------------------------
    // callCaregiver
    // -----------------------------------------------------------------------
    VoiceIntent.callCaregiver: [
      // English
      _PatternEntry([
        ['call', 'dial', 'ring', 'phone', 'contact', 'reach'],
        ['caregiver', 'helper', 'nurse', 'doctor', 'didi', 'asha', 'worker', 'family', 'son', 'daughter'],
      ], weight: 1.5),
      _PatternEntry([
        ['i need', 'help from'],
        ['caregiver', 'helper', 'nurse', 'didi', 'asha'],
      ], weight: 1.3),
      _PatternEntry([
        ['caregiver', 'asha worker', 'asha didi'],
      ], weight: 0.8),
      // Hindi — केयरगिवर
      _PatternEntry([
        ['केयरगिवर', 'आशा', 'दीदी', 'मददगार', 'सहायक', 'डॉक्टर'],
        ['बुलाओ', 'कॉल', 'फोन', 'संपर्क', 'करो', 'लगाओ'],
      ], weight: 1.5),
      _PatternEntry([
        ['केयरगिवर'],
      ], weight: 0.8),
      // Bengali — কেয়ারগিভার
      _PatternEntry([
        ['কেয়ারগিভার', 'আশা', 'দিদি', 'সাহায্যকারী', 'ডাক্তার'],
        ['কল', 'ফোন', 'যোগাযোগ', 'করো', 'ডাকো', 'ডেকে'],
      ], weight: 1.5),
      _PatternEntry([
        ['কেয়ারগিভার'],
      ], weight: 0.8),
    ],

    // -----------------------------------------------------------------------
    // checkToday
    // -----------------------------------------------------------------------
    VoiceIntent.checkToday: [
      // English
      _PatternEntry([
        ['check', 'see', 'view', 'show', 'what is', "what's"],
        ['today', 'schedule', 'routine', 'agenda', 'plan'],
      ], weight: 1.5),
      _PatternEntry([
        [
          'check today',
          'what do i have today',
          "what's today",
          "what's on today",
          'show today',
          'today routine',
        ],
      ], weight: 1.4),
      _PatternEntry([
        ['today'],
      ], weight: 0.8),
      // Hindi — आज का / आज की
      _PatternEntry([
        ['आज'],
        ['का', 'की', 'क्या', 'दिखाओ', 'बताओ', 'है'],
      ], weight: 1.4),
      // Bengali — আজকের দিন
      _PatternEntry([
        ['আজকের', 'আজ'],
        ['দিন', 'কী', 'কি', 'আছে', 'দেখাও', 'বলো'],
      ], weight: 1.4),
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
        [
          'how am i doing',
          'how have i been doing',
          'how did i do',
          'how am i progressing',
          'how i am progressing',
        ],
      ], weight: 1.4),
      _PatternEntry([
        ['my progress', 'my score', 'my results'],
      ], weight: 1.2),
      // Hindi
      _PatternEntry([
        ['प्रोग्रेस', 'प्रगति', 'स्कोर', 'परिणाम'],
        ['दिखाओ', 'बताओ', 'देखना', 'देखो'],
      ], weight: 1.5),
      // Bengali
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

  VoiceIntentResult recognize(String? rawTranscript) {
    if (rawTranscript == null || rawTranscript.trim().isEmpty) {
      return const VoiceIntentResult(
        intent: VoiceIntent.unknown,
        transcript: '',
        confidence: 0.0,
      );
    }

    final normalized = _normalize(rawTranscript);

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

    if (scores.isEmpty) {
      return VoiceIntentResult(
        intent: VoiceIntent.unknown,
        transcript: normalized,
        confidence: 0.0,
      );
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.index.compareTo(b.key.index);
      });

    final bestIntent = sorted.first.key;
    final bestScore = sorted.first.value;
    final confidence = bestScore.clamp(0.0, 1.0);
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

  String _normalize(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'[.!?,।]+$'), '').trim();
    s = s.toLowerCase();
    s = s.replaceAll('ওষধ', 'ওষুধ');

    // Phonetic & common speech-to-text transcription variants
    s = s.replaceAll('remainder', 'reminder');
    s = s.replaceAll('remainders', 'reminders');
    s = s.replaceAll('medicne', 'medicine');
    s = s.replaceAll('medecine', 'medicine');
    return s;
  }

  // -------------------------------------------------------------------------
  // Internal: score a single pattern entry
  // -------------------------------------------------------------------------

  double _scorePattern(String normalized, _PatternEntry pattern) {
    int matchedGroups = 0;
    final total = pattern.keywordGroups.length;

    for (final group in pattern.keywordGroups) {
      bool groupMatched = false;
      for (final keyword in group) {
        if (_containsKeyword(normalized, keyword)) {
          groupMatched = true;
          break;
        }
      }
      if (!groupMatched) return 0.0;
      matchedGroups++;
    }

    return (matchedGroups / total) * pattern.weight;
  }

  // -------------------------------------------------------------------------
  // Internal: safe keyword containment check
  // -------------------------------------------------------------------------

  bool _containsKeyword(String text, String keyword) {
    if (keyword.isEmpty) return false;

    final isAsciiSingleWord =
        !keyword.contains(' ') && RegExp(r'^[a-z0-9]+$').hasMatch(keyword);

    if (isAsciiSingleWord) {
      return RegExp('\\b${RegExp.escape(keyword)}\\b').hasMatch(text);
    }

    return text.contains(keyword);
  }

  // -------------------------------------------------------------------------
  // Internal: extract parameters
  // -------------------------------------------------------------------------

  Map<String, dynamic> _extractParameters(
      VoiceIntent intent, String normalized) {
    switch (intent) {
      case VoiceIntent.startGame:
        if (normalized.contains('pulse')) {
          return {'gameType': 'pulse'};
        } else if (normalized.contains('wayfinder') || normalized.contains('walk')) {
          return {'gameType': 'wayfinder'};
        } else if (normalized.contains('sequence')) {
          return {'gameType': 'sequence'};
        } else if (normalized.contains('calibration')) {
          return {'gameType': 'calibration'};
        } else if (normalized.contains('more') || normalized.contains('arcade') || normalized.contains('all game')) {
          return {'gameType': 'more'};
        } else {
          return {'gameType': 'daily'};
        }
      case VoiceIntent.setReminder:
        return {};
      default:
        return {};
    }
  }
}
