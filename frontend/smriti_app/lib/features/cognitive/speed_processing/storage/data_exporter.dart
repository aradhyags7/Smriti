import 'dart:convert';
import '../models/pulse_trainer_models.dart';

class LocalEventStorage {
  static final List<PulseTrainerSessionData> _sessionLogs = [];

  static Future<void> saveSession(PulseTrainerSessionData sessionData) async {
    _sessionLogs.add(sessionData);
  }

  static Future<List<PulseTrainerSessionData>> getAllSessions() async {
    return _sessionLogs;
  }

  static Future<void> clearAll() async {
    _sessionLogs.clear();
  }
}

class DataExporter {
  /// Converts a session's raw trial events into JSONL format (one JSON object per line).
  static String exportSessionToJsonl(PulseTrainerSessionData sessionData) {
    final headerLine = jsonEncode({
      'type': 'session_header',
      'sessionId': sessionData.sessionId,
      'userId': sessionData.userId,
      'pairId': sessionData.pairId,
      'thresholdMs': sessionData.thresholdMs,
      'researchConsentGiven': sessionData.researchConsentGiven,
      'metadata': sessionData.metadata.toJson(),
    });

    final trialLines = sessionData.trials.map(
      (trial) => jsonEncode({
        'type': 'raw_trial_event',
        'sessionId': sessionData.sessionId,
        ...trial.toJson(),
      }),
    );

    return [headerLine, ...trialLines].join('\n');
  }
}
