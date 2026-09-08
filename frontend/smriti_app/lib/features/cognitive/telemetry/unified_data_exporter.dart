import 'dart:convert';
import 'telemetry_models.dart';
import 'telemetry_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED DATA EXPORTER
// Single export interface for all game types → AI model consumption
// ─────────────────────────────────────────────────────────────────────────────

class UnifiedDataExporter {
  static final TelemetryEngine _engine = TelemetryEngine();

  /// Export a single session envelope to JSONL (one JSON object per line).
  /// Line 1: session header. Lines 2+: individual trial events.
  static String exportSessionToJsonl(CognitiveSessionEnvelope envelope) {
    final headerLine = jsonEncode({
      'type': 'session_header',
      'schemaVersion': envelope.schemaVersion,
      'gameType': envelope.gameType.name,
      'sessionId': envelope.sessionId,
      'userId': envelope.userId,
      'difficultyLevel': envelope.difficultyLevel.name,
      'sessionStartUtc': envelope.sessionStartUtc,
      'sessionEndUtc': envelope.sessionEndUtc,
      'deviceMetadata': envelope.deviceMetadata.toJson(),
      'adaptiveState': envelope.adaptiveState.toJson(),
      'sessionSummary': envelope.sessionSummary.toJson(),
    });

    final trialLines = envelope.trials.map(
      (trial) => jsonEncode({
        'type': 'trial_event',
        'sessionId': envelope.sessionId,
        'gameType': envelope.gameType.name,
        ...trial.toJson(),
      }),
    );

    return [headerLine, ...trialLines].join('\n');
  }

  /// Export all stored sessions as a single JSON array string.
  /// Ideal for bulk ingestion into AI pipelines.
  static String exportAllSessionsToJson() {
    final allSessions = _engine.getAllSessions();
    final jsonList = allSessions.map((s) => s.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Export sessions filtered by game type as JSON array.
  static String exportSessionsByGameToJson(GameType gameType) {
    final sessions = _engine.getSessionsByGame(gameType);
    final jsonList = sessions.map((s) => s.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Export a daily summary record as JSON.
  static String? exportDailySummary(DateTime date, String userId) {
    final summary = _engine.buildDailySummary(date, userId);
    if (summary == null) return null;
    return const JsonEncoder.withIndent('  ').convert(summary.toJson());
  }

  /// Export all sessions as JSONL (one session per block, separated by blank lines).
  static String exportAllToJsonl() {
    final allSessions = _engine.getAllSessions();
    return allSessions.map((s) => exportSessionToJsonl(s)).join('\n\n');
  }
}
