import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED COGNITIVE TELEMETRY MODELS
// Shared schema for Pulse Trainer, Wayfinder, and Sequence Check
// ─────────────────────────────────────────────────────────────────────────────

/// Discriminator for which game produced this session data.
enum GameType {
  pulseTrainer,
  wayfinder,
  sequenceCheck,
}

/// Shared difficulty levels across all modules.
enum CognitiveDifficulty {
  simple,
  moderate,
  harder,
}

/// Classification of how the user responded to a trial.
enum CognitiveResponseType {
  correct,
  incorrect,
  timeout,
  partialCorrect,
  premature,
  skipped,
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE & SESSION METADATA
// ─────────────────────────────────────────────────────────────────────────────

class DeviceMetadata {
  final String deviceModel;
  final String os;
  final String osVersion;
  final String appVersion;
  final int screenWidthDp;
  final int screenHeightDp;
  final double devicePixelRatio;
  final String timezone;

  const DeviceMetadata({
    required this.deviceModel,
    required this.os,
    required this.osVersion,
    required this.appVersion,
    required this.screenWidthDp,
    required this.screenHeightDp,
    required this.devicePixelRatio,
    required this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'deviceModel': deviceModel,
        'os': os,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'screenWidthDp': screenWidthDp,
        'screenHeightDp': screenHeightDp,
        'devicePixelRatio': devicePixelRatio,
        'timezone': timezone,
      };

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) => DeviceMetadata(
        deviceModel: json['deviceModel'] as String? ?? 'unknown',
        os: json['os'] as String? ?? 'unknown',
        osVersion: json['osVersion'] as String? ?? '',
        appVersion: json['appVersion'] as String? ?? '',
        screenWidthDp: json['screenWidthDp'] as int? ?? 0,
        screenHeightDp: json['screenHeightDp'] as int? ?? 0,
        devicePixelRatio: (json['devicePixelRatio'] as num?)?.toDouble() ?? 1.0,
        timezone: json['timezone'] as String? ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADAPTIVE STATE — tracks how difficulty was adjusted during a session
// ─────────────────────────────────────────────────────────────────────────────

class AdaptiveState {
  final String initialDifficulty;
  final String finalDifficulty;
  final int adjustmentCount;
  final double rollingAccuracy;
  final List<Map<String, dynamic>> adjustmentLog;

  const AdaptiveState({
    required this.initialDifficulty,
    required this.finalDifficulty,
    required this.adjustmentCount,
    required this.rollingAccuracy,
    this.adjustmentLog = const [],
  });

  Map<String, dynamic> toJson() => {
        'initialDifficulty': initialDifficulty,
        'finalDifficulty': finalDifficulty,
        'adjustmentCount': adjustmentCount,
        'rollingAccuracy': rollingAccuracy,
        'adjustmentLog': adjustmentLog,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION SUMMARY — computed aggregates for AI model
// ─────────────────────────────────────────────────────────────────────────────

class SessionSummary {
  final int totalTrials;
  final int correctTrials;
  final double accuracy;
  final double avgReactionTimeMs;
  final double medianReactionTimeMs;
  final int fatigueEventsCount;
  final int restBreaksTaken;
  final int? maxSpan; // Sequence Check only
  final double? spatialAccuracy; // Wayfinder only
  final double cognitiveLoadAvg;
  final int totalSessionDurationMs;
  final int encouragementEventsCount;

  const SessionSummary({
    required this.totalTrials,
    required this.correctTrials,
    required this.accuracy,
    required this.avgReactionTimeMs,
    required this.medianReactionTimeMs,
    required this.fatigueEventsCount,
    required this.restBreaksTaken,
    this.maxSpan,
    this.spatialAccuracy,
    required this.cognitiveLoadAvg,
    required this.totalSessionDurationMs,
    required this.encouragementEventsCount,
  });

  Map<String, dynamic> toJson() => {
        'totalTrials': totalTrials,
        'correctTrials': correctTrials,
        'accuracy': accuracy,
        'avgReactionTimeMs': avgReactionTimeMs,
        'medianReactionTimeMs': medianReactionTimeMs,
        'fatigueEventsCount': fatigueEventsCount,
        'restBreaksTaken': restBreaksTaken,
        'maxSpan': maxSpan,
        'spatialAccuracy': spatialAccuracy,
        'cognitiveLoadAvg': cognitiveLoadAvg,
        'totalSessionDurationMs': totalSessionDurationMs,
        'encouragementEventsCount': encouragementEventsCount,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE TRIAL EVENT — shared fields across all game types
// ─────────────────────────────────────────────────────────────────────────────

class CognitiveTrialEvent {
  final String eventId;
  final int trialIndex;
  final String utcTimestamp;
  final int reactionTimeMs;
  final bool isCorrect;
  final CognitiveResponseType responseType;
  final int cognitiveLoad; // 1-10 estimated demand score
  final bool fatigueSignal;
  final int sessionElapsedTimeMs;
  final Map<String, dynamic> gameSpecific;

  const CognitiveTrialEvent({
    required this.eventId,
    required this.trialIndex,
    required this.utcTimestamp,
    required this.reactionTimeMs,
    required this.isCorrect,
    required this.responseType,
    required this.cognitiveLoad,
    required this.fatigueSignal,
    required this.sessionElapsedTimeMs,
    this.gameSpecific = const {},
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'trialIndex': trialIndex,
        'utcTimestamp': utcTimestamp,
        'reactionTimeMs': reactionTimeMs,
        'isCorrect': isCorrect,
        'responseType': responseType.name,
        'cognitiveLoad': cognitiveLoad,
        'fatigueSignal': fatigueSignal,
        'sessionElapsedTimeMs': sessionElapsedTimeMs,
        'gameSpecific': gameSpecific,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL SESSION ENVELOPE — the JSON your AI model ingests
// ─────────────────────────────────────────────────────────────────────────────

class CognitiveSessionEnvelope {
  final String schemaVersion;
  final GameType gameType;
  final String sessionId;
  final String userId;
  final CognitiveDifficulty difficultyLevel;
  final String sessionStartUtc;
  final String sessionEndUtc;
  final DeviceMetadata deviceMetadata;
  final AdaptiveState adaptiveState;
  final SessionSummary sessionSummary;
  final List<CognitiveTrialEvent> trials;

  const CognitiveSessionEnvelope({
    this.schemaVersion = '2.0',
    required this.gameType,
    required this.sessionId,
    required this.userId,
    required this.difficultyLevel,
    required this.sessionStartUtc,
    required this.sessionEndUtc,
    required this.deviceMetadata,
    required this.adaptiveState,
    required this.sessionSummary,
    required this.trials,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'gameType': gameType.name,
        'sessionId': sessionId,
        'userId': userId,
        'difficultyLevel': difficultyLevel.name,
        'sessionStartUtc': sessionStartUtc,
        'sessionEndUtc': sessionEndUtc,
        'deviceMetadata': deviceMetadata.toJson(),
        'adaptiveState': adaptiveState.toJson(),
        'sessionSummary': sessionSummary.toJson(),
        'trials': trials.map((t) => t.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY SUMMARY — cross-game aggregation for longitudinal AI analysis
// ─────────────────────────────────────────────────────────────────────────────

class DailySummaryRecord {
  final String date; // ISO 8601 date string (YYYY-MM-DD)
  final String userId;
  final int totalSessionsPlayed;
  final int totalTrialsCompleted;
  final double overallAccuracy;
  final double avgReactionTimeMs;
  final int totalTrainingDurationMs;
  final int fatigueEventsTotal;
  final Map<String, double> gameAccuracies; // gameType -> accuracy
  final Map<String, int> gameSessions; // gameType -> session count
  final double? spatialAccuracyAvg;
  final int? maxSequenceSpan;
  final double? processingSpeedMs;
  final double cognitiveLoadTrend; // rolling average over last 7 days

  const DailySummaryRecord({
    required this.date,
    required this.userId,
    required this.totalSessionsPlayed,
    required this.totalTrialsCompleted,
    required this.overallAccuracy,
    required this.avgReactionTimeMs,
    required this.totalTrainingDurationMs,
    required this.fatigueEventsTotal,
    required this.gameAccuracies,
    required this.gameSessions,
    this.spatialAccuracyAvg,
    this.maxSequenceSpan,
    this.processingSpeedMs,
    required this.cognitiveLoadTrend,
  });

  Map<String, dynamic> toJson() => {
        'type': 'daily_summary',
        'date': date,
        'userId': userId,
        'totalSessionsPlayed': totalSessionsPlayed,
        'totalTrialsCompleted': totalTrialsCompleted,
        'overallAccuracy': overallAccuracy,
        'avgReactionTimeMs': avgReactionTimeMs,
        'totalTrainingDurationMs': totalTrainingDurationMs,
        'fatigueEventsTotal': fatigueEventsTotal,
        'gameAccuracies': gameAccuracies,
        'gameSessions': gameSessions,
        'spatialAccuracyAvg': spatialAccuracyAvg,
        'maxSequenceSpan': maxSequenceSpan,
        'processingSpeedMs': processingSpeedMs,
        'cognitiveLoadTrend': cognitiveLoadTrend,
      };
}
