import 'package:uuid/uuid.dart';

import 'reminder_model.dart';

/// Structured intermediate draft extracted from a voice reminder command.
///
/// If [hasEnoughInformation] is true, this draft can be converted into a valid
/// [ReminderModel] using [toReminderModel()].
///
/// If [hasEnoughInformation] is false (for example, when [isTimeMissing] is true),
/// the draft must be handed to the UI so the user can review, pick a time, and save.
class VoiceReminderDraft {
  /// The original, unprocessed voice transcript.
  final String rawTranscript;

  /// Cleaned reminder title/content (e.g., "drink water", "take medicine"),
  /// or null if no title content could be extracted.
  final String? title;

  /// Optional description extracted from the command.
  final String? description;

  /// Scheduled trigger date and time, or null if no valid time was specified.
  final DateTime? scheduledAt;

  /// Repetition cadence (defaults to [ReminderRecurrence.none]).
  final ReminderRecurrence recurrence;

  /// Whether enough information is present to automatically create a [ReminderModel].
  ///
  /// Requires both a non-empty [title] and a non-null [scheduledAt].
  final bool hasEnoughInformation;

  /// Indicates that time was not specified or was ambiguous.
  final bool isTimeMissing;

  /// Indicates that no meaningful title content could be extracted.
  final bool isTitleMissing;

  const VoiceReminderDraft({
    required this.rawTranscript,
    this.title,
    this.description,
    this.scheduledAt,
    this.recurrence = ReminderRecurrence.none,
    required this.hasEnoughInformation,
    this.isTimeMissing = false,
    this.isTitleMissing = false,
  });

  /// Converts this draft into a [ReminderModel] if [hasEnoughInformation] is true.
  ///
  /// Returns `null` if required information is missing.
  /// Generates a UUID v4 identifier and sets [createdAt] via [nowProvider] (or [DateTime.now]).
  ReminderModel? toReminderModel({
    String? id,
    DateTime Function()? nowProvider,
  }) {
    if (!hasEnoughInformation || title == null || title!.trim().isEmpty || scheduledAt == null) {
      return null;
    }
    final now = nowProvider != null ? nowProvider() : DateTime.now();
    return ReminderModel(
      id: id ?? const Uuid().v4(),
      title: title!.trim(),
      description: description,
      scheduledAt: scheduledAt!,
      recurrence: recurrence,
      isEnabled: true,
      createdAt: now,
    );
  }

  @override
  String toString() =>
      'VoiceReminderDraft(title: "$title", scheduledAt: $scheduledAt, recurrence: $recurrence, ready: $hasEnoughInformation)';
}

/// Pure-Dart offline parser and bridge converting voice transcripts into
/// structured [VoiceReminderDraft] objects.
///
/// Designed to be 100% offline, deterministic, and free of Flutter UI,
/// notifications, database, network, LLMs, or external NLP libraries.
class VoiceReminderBridge {
  /// Deterministically parses [transcript] into a [VoiceReminderDraft].
  ///
  /// Safe and non-crashing: unhandled parsing edge cases fail safely by
  /// returning an incomplete draft with [hasEnoughInformation] = false.
  ///
  /// [nowProvider] is used to resolve relative times deterministically in tests.
  static VoiceReminderDraft parse(
    String? transcript, {
    DateTime Function()? nowProvider,
  }) {
    if (transcript == null || transcript.trim().isEmpty) {
      return const VoiceReminderDraft(
        rawTranscript: '',
        title: null,
        hasEnoughInformation: false,
        isTimeMissing: true,
        isTitleMissing: true,
      );
    }

    try {
      final now = nowProvider != null ? nowProvider() : DateTime.now();
      return _parseInternal(transcript.trim(), now);
    } catch (_) {
      return VoiceReminderDraft(
        rawTranscript: transcript,
        title: null,
        hasEnoughInformation: false,
        isTimeMissing: true,
        isTitleMissing: true,
      );
    }
  }

  static VoiceReminderDraft _parseInternal(String rawTranscript, DateTime now) {
    // 1. Normalize numerals (Devanagari and Bengali script numerals -> ASCII 0-9)
    var working = _normalizeNumerals(rawTranscript);

    // Normalize multiple spaces
    working = working.replaceAll(RegExp(r'\s+'), ' ');

    // 2. Extract recurrence
    ReminderRecurrence recurrence = ReminderRecurrence.none;

    final weeklyRegex = RegExp(
      r'\b(every\s+week|weekly|हर\s+हफ्ते|हर\s+हफ्ता|हर\s+सप्ताह|साप्ताहिक|প্রতি\s+সপ্তাহে|সাপ্তাহিক)\b',
      caseSensitive: false,
    );
    final dailyRegex = RegExp(
      r'\b(every\s+day|daily|every\s+morning|every\s+evening|every\s+night|हर\s+दिन|रोज़|रोज|प्रतिदिन|हर\s+रोज़|हर\s+रोज|প্রতিদিন|প্রতি\s+দিন|রোজ)\b',
      caseSensitive: false,
    );

    if (weeklyRegex.hasMatch(working)) {
      recurrence = ReminderRecurrence.weekly;
      working = working.replaceAll(weeklyRegex, ' ');
    } else if (dailyRegex.hasMatch(working)) {
      recurrence = ReminderRecurrence.daily;
      working = working.replaceAll(dailyRegex, ' ');
    }

    // 3. Extract date token if present
    bool isTomorrow = false;
    bool isToday = false;

    final tomorrowRegex = RegExp(r'\b(tomorrow|कल|কাল|আগামীকাল)\b', caseSensitive: false);
    final todayRegex = RegExp(r'\b(today|आज)\b', caseSensitive: false);

    if (tomorrowRegex.hasMatch(working)) {
      isTomorrow = true;
      working = working.replaceAll(tomorrowRegex, ' ');
    } else if (todayRegex.hasMatch(working)) {
      isToday = true;
      working = working.replaceAll(todayRegex, ' ');
    }

    // 4. Extract time
    int? parsedHour24;
    int? parsedMinute;

    // 4a. English 12-hour format with AM / PM: "8 AM", "10:30 PM", "at 8 PM"
    final englishAmPmRegex = RegExp(
      r'(?:\bat\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final amPmMatch = englishAmPmRegex.firstMatch(working);

    if (amPmMatch != null) {
      final hour = int.parse(amPmMatch.group(1)!);
      final minute = amPmMatch.group(2) != null ? int.parse(amPmMatch.group(2)!) : 0;
      final amPm = amPmMatch.group(3)!.toLowerCase();

      parsedHour24 = _to24Hour(hour, minute, amPm);
      parsedMinute = minute;
      working = working.replaceRange(amPmMatch.start, amPmMatch.end, ' ');
    }

    // 4b. English period-of-day phrases: "8 in the morning", "8 in the evening", "8 at night"
    if (parsedHour24 == null) {
      final periodRegex = RegExp(
        r'(?:\bat\s+)?(\d{1,2})(?::(\d{2}))?\s+(?:in\s+the\s+(morning|afternoon|evening)|at\s+(night))\b',
        caseSensitive: false,
      );
      final periodMatch = periodRegex.firstMatch(working);
      if (periodMatch != null) {
        final hour = int.parse(periodMatch.group(1)!);
        final minute = periodMatch.group(2) != null ? int.parse(periodMatch.group(2)!) : 0;
        final period = (periodMatch.group(3) ?? periodMatch.group(4))!.toLowerCase();

        parsedHour24 = _to24Hour(hour, minute, period);
        parsedMinute = minute;
        working = working.replaceRange(periodMatch.start, periodMatch.end, ' ');
      }
    }

    // 4c. Hindi time phrases: "सुबह 8 बजे", "शाम 7 बजे", "रात 9 बजे", "दोपहर 2 बजे"
    if (parsedHour24 == null) {
      final hindiRegex1 = RegExp(r'(सुबह|दोपहर|शाम|रात)\s+(\d{1,2})(?::(\d{2}))?\s*बजे');
      final hindiRegex2 = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*बजे\s*(सुबह|दोपहर|शाम|रात)');

      final m1 = hindiRegex1.firstMatch(working);
      final m2 = hindiRegex2.firstMatch(working);

      if (m1 != null) {
        final period = m1.group(1)!;
        final hour = int.parse(m1.group(2)!);
        final minute = m1.group(3) != null ? int.parse(m1.group(3)!) : 0;
        parsedHour24 = _to24Hour(hour, minute, period);
        parsedMinute = minute;
        working = working.replaceRange(m1.start, m1.end, ' ');
      } else if (m2 != null) {
        final hour = int.parse(m2.group(1)!);
        final minute = m2.group(2) != null ? int.parse(m2.group(2)!) : 0;
        final period = m2.group(3)!;
        parsedHour24 = _to24Hour(hour, minute, period);
        parsedMinute = minute;
        working = working.replaceRange(m2.start, m2.end, ' ');
      }
    }

    // 4d. Bengali time phrases: "সকাল ৮টা", "সকাল ৮টায়", "সন্ধ্যা ৭টা", "রাত ৯টা", "দুপুর ২টা"
    if (parsedHour24 == null) {
      final bengaliRegex1 = RegExp(
        r'(সকাল|দুপুর|সন্ধ্যা|রাত)\s+(\d{1,2})(?::(\d{2}))?\s*(?:টার\s*সময়|টার\s*সময়|টায়|টায়|টা|বাজে)',
      );
      final bengaliRegex2 = RegExp(
        r'(\d{1,2})(?::(\d{2}))?\s*(?:টার\s*সময়|টার\s*সময়|টায়|টায়|টা)\s*(সকাল|দুপুর|সন্ধ্যা|রাত)',
      );

      final m1 = bengaliRegex1.firstMatch(working);
      final m2 = bengaliRegex2.firstMatch(working);

      if (m1 != null) {
        final period = m1.group(1)!;
        final hour = int.parse(m1.group(2)!);
        final minute = m1.group(3) != null ? int.parse(m1.group(3)!) : 0;
        parsedHour24 = _to24Hour(hour, minute, period);
        parsedMinute = minute;
        working = working.replaceRange(m1.start, m1.end, ' ');
      } else if (m2 != null) {
        final hour = int.parse(m2.group(1)!);
        final minute = m2.group(2) != null ? int.parse(m2.group(2)!) : 0;
        final period = m2.group(3)!;
        parsedHour24 = _to24Hour(hour, minute, period);
        parsedMinute = minute;
        working = working.replaceRange(m2.start, m2.end, ' ');
      }
    }

    // 4e. Handle ambiguous times: "at 8", "8 बजे", "8টা" without AM/PM or morning/evening context.
    // As per specification: leave unresolved so user can confirm time explicitly.
    // We remove the token from working text so it doesn't pollute the reminder title.
    final ambiguousEnglish = RegExp(r'\bat\s+\d{1,2}(?::\d{2})?\b', caseSensitive: false);
    if (ambiguousEnglish.hasMatch(working)) {
      working = working.replaceAll(ambiguousEnglish, ' ');
    }
    final ambiguousHindi = RegExp(r'\b\d{1,2}(?::\d{2})?\s*बजे\b');
    if (ambiguousHindi.hasMatch(working)) {
      working = working.replaceAll(ambiguousHindi, ' ');
    }
    final ambiguousBengali = RegExp(r'\b\d{1,2}(?::\d{2})?\s*(?:টার\s*সময়|টার\s*সময়|টায়|টায়|টা)\b');
    if (ambiguousBengali.hasMatch(working)) {
      working = working.replaceAll(ambiguousBengali, ' ');
    }

    // Compute scheduledAt if time was resolved
    DateTime? scheduledAt;
    if (parsedHour24 != null && parsedMinute != null) {
      if (isTomorrow) {
        scheduledAt = DateTime(now.year, now.month, now.day + 1, parsedHour24, parsedMinute);
      } else if (isToday) {
        scheduledAt = DateTime(now.year, now.month, now.day, parsedHour24, parsedMinute);
      } else {
        final candidate = DateTime(now.year, now.month, now.day, parsedHour24, parsedMinute);
        if (candidate.isAfter(now)) {
          scheduledAt = candidate;
        } else {
          scheduledAt = candidate.add(const Duration(days: 1));
        }
      }
    }

    // 5. Extract Title by removing command boilerplate
    final title = _extractTitle(working);

    final isTitleMissing = title == null || title.isEmpty;
    final isTimeMissing = scheduledAt == null;
    final hasEnoughInformation = !isTitleMissing && !isTimeMissing;

    return VoiceReminderDraft(
      rawTranscript: rawTranscript,
      title: title,
      scheduledAt: scheduledAt,
      recurrence: recurrence,
      hasEnoughInformation: hasEnoughInformation,
      isTimeMissing: isTimeMissing,
      isTitleMissing: isTitleMissing,
    );
  }

  /// Converts a 12-hour or period-qualified hour into a 24-hour integer.
  static int _to24Hour(int hour, int minute, String period) {
    final p = period.toLowerCase().trim();
    if (p == 'am' || p == 'morning' || p == 'सुबह' || p == 'সকাল') {
      return (hour % 12);
    }
    if (p == 'pm' || p == 'evening' || p == 'night' || p == 'शाम' || p == 'रात' || p == 'সন্ধ্যা') {
      return (hour % 12) + 12;
    }
    if (p == 'afternoon' || p == 'दोपहर' || p == 'দুপুর') {
      return hour == 12 ? 12 : (hour % 12) + 12;
    }
    return hour;
  }

  /// Replaces Devanagari and Bengali numeral digits with ASCII '0'-'9'.
  static String _normalizeNumerals(String input) {
    const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(devanagari[i], '$i');
      result = result.replaceAll(bengali[i], '$i');
    }
    return result;
  }

  /// Strips command boilerplate and isolates the actual reminder content.
  static String? _extractTitle(String text) {
    var cleaned = text.trim();

    // Remove English command prefixes (ordered longest first)
    const englishPrefixes = [
      'please remind me to',
      'please remind me for',
      'please remind me about',
      'please remind me',
      'can you remind me to',
      'can you remind me',
      'schedule a reminder for',
      'schedule a reminder to',
      'schedule a reminder',
      'schedule reminder for',
      'schedule reminder to',
      'schedule reminder',
      'set a reminder for',
      'set a reminder to',
      'set a reminder about',
      'set a reminder on',
      'set a reminder',
      'set reminder for',
      'set reminder to',
      'set reminder',
      'create a reminder for',
      'create a reminder to',
      'create a reminder',
      'create reminder for',
      'create reminder to',
      'create reminder',
      'add a reminder for',
      'add a reminder to',
      'add a reminder',
      'add reminder for',
      'add reminder to',
      'add reminder',
      'put a reminder for',
      'put a reminder to',
      'put a reminder',
      'put reminder',
      'remind me to',
      'remind me for',
      'remind me about',
      'remind me',
      'reminder for',
      'reminder to',
      'reminder',
    ];

    for (final prefix in englishPrefixes) {
      if (cleaned.toLowerCase().startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    // Remove Hindi prefixes and suffixes
    const hindiPrefixes = ['कृपया मुझे', 'कृपया', 'मुझे'];
    for (final p in hindiPrefixes) {
      if (cleaned.startsWith(p)) {
        cleaned = cleaned.substring(p.length).trim();
        break;
      }
    }

    const hindiSuffixes = [
      'की याद दिलाओ',
      'का याद दिलाओ',
      'याद दिलाओ',
      'की याद दिलाना',
      'याद दिलाना',
      'की याद दिला',
      'याद दिला',
      'का रिमाइंडर लगाओ',
      'का रिमाइंडर सेट करो',
      'का रिमाइंडर बनाओ',
      'रिमाइंडर लगाओ',
      'रिमाइंडर सेट करो',
      'रिमाइंडर बनाओ',
      'रिमाइंडर',
    ];
    for (final s in hindiSuffixes) {
      if (cleaned.endsWith(s)) {
        cleaned = cleaned.substring(0, cleaned.length - s.length).trim();
        break;
      }
    }

    // Remove Bengali prefixes and suffixes
    const bengaliPrefixes = ['দয়া করে আমাকে', 'দয়া করে আমাকে', 'দয়া করে', 'দয়া করে', 'আমাকে'];
    for (final p in bengaliPrefixes) {
      if (cleaned.startsWith(p)) {
        cleaned = cleaned.substring(p.length).trim();
        break;
      }
    }

    const bengaliSuffixes = [
      'এর কথা মনে করিয়ে দাও',
      'কথা মনে করিয়ে দাও',
      'মনে করিয়ে দাও',
      'মনে করিয়ে দাও',
      'এর কথা মনে করিয়ে',
      'কথা মনে করিয়ে',
      'মনে করিয়ে',
      'মনে করিয়ে',
      'রিমাইন্ডার সেট করো',
      'রিমাইন্ডার দাও',
      'রিমাইন্ডার লাগাও',
      'রিমাইন্ডার',
    ];
    for (final s in bengaliSuffixes) {
      if (cleaned.endsWith(s)) {
        cleaned = cleaned.substring(0, cleaned.length - s.length).trim();
        break;
      }
    }

    // Strip leftover leading prepositions if any remain
    final leadingPreps = RegExp(r'^(?:to|for|about|on|at)\s+', caseSensitive: false);
    cleaned = cleaned.replaceFirst(leadingPreps, '').trim();

    // Strip leftover trailing prepositions if any remain
    final trailingPreps = RegExp(r'\s+(?:at|for|to|on)$', caseSensitive: false);
    cleaned = cleaned.replaceFirst(trailingPreps, '').trim();

    // Strip sentence punctuation and collapse spaces
    cleaned = cleaned.replaceAll(RegExp(r'^[.,!?:;।\s]+|[.,!?:;।\s]+$'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Filter out filler words that are not meaningful titles
    const emptyTitles = {'', 'to', 'for', 'about', 'reminder'};
    if (emptyTitles.contains(cleaned.toLowerCase())) {
      return null;
    }

    return cleaned.isNotEmpty ? cleaned : null;
  }
}
