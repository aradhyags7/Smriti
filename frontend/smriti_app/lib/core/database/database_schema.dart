// SMRITI - Local SQLite Database Schema
// Owner: Aradhya (AI + Database + Sync)

class DatabaseSchema {
  static const String dbName = 'smriti_local.db';
  static const int dbVersion = 1;

  // Table Names
  static const String tablePatients = 'patients';
  static const String tableSessions = 'sessions';
  static const String tableGameAttempts = 'game_attempts';
  static const String tableDailyCheckins = 'daily_checkins';
  static const String tableReminders = 'reminders';
  static const String tableReminiscences = 'reminiscences';
  static const String tableAlerts = 'alerts';
  static const String tableOfflineEvents = 'offline_events';

  // Sync Status Values
  static const String syncPending = 'PENDING';
  static const String syncSyncing = 'SYNCING';
  static const String syncSynced = 'SYNCED';
  static const String syncFailed = 'FAILED';

  static const String createPatientsTable = '''
    CREATE TABLE IF NOT EXISTS $tablePatients (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER NOT NULL,
      language TEXT NOT NULL DEFAULT 'as',
      location TEXT NOT NULL DEFAULT 'Dibrugarh, Assam',
      consent_for_asha INTEGER NOT NULL DEFAULT 1,
      baseline_memory REAL DEFAULT 70.0,
      baseline_attention REAL DEFAULT 70.0,
      baseline_engagement REAL DEFAULT 70.0,
      created_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT '$syncPending'
    );
  ''';

  static const String createGameAttemptsTable = '''
    CREATE TABLE IF NOT EXISTS $tableGameAttempts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT UNIQUE NOT NULL,
      patient_id TEXT NOT NULL,
      game_type TEXT NOT NULL,
      score REAL NOT NULL,
      mistakes INTEGER NOT NULL DEFAULT 0,
      reaction_time_ms REAL NOT NULL DEFAULT 0.0,
      difficulty TEXT NOT NULL DEFAULT 'EASY',
      completed INTEGER NOT NULL DEFAULT 1,
      timestamp TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT '$syncPending'
    );
  ''';

  static const String createDailyCheckinsTable = '''
    CREATE TABLE IF NOT EXISTS $tableDailyCheckins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT UNIQUE NOT NULL,
      patient_id TEXT NOT NULL,
      mood INTEGER NOT NULL DEFAULT 4,
      sleep_quality INTEGER NOT NULL DEFAULT 3,
      activity_level INTEGER NOT NULL DEFAULT 3,
      notes TEXT,
      timestamp TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT '$syncPending'
    );
  ''';

  static const String createRemindersTable = '''
    CREATE TABLE IF NOT EXISTS $tableReminders (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      title TEXT NOT NULL,
      reminder_type TEXT NOT NULL DEFAULT 'MEDICINE',
      scheduled_time TEXT NOT NULL,
      frequency TEXT NOT NULL DEFAULT 'DAILY',
      is_acknowledged INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT '$syncPending'
    );
  ''';

  static const String createOfflineEventsTable = '''
    CREATE TABLE IF NOT EXISTS $tableOfflineEvents (
      event_id TEXT PRIMARY KEY,
      local_id INTEGER,
      patient_id TEXT NOT NULL,
      event_type TEXT NOT NULL,
      created_at TEXT NOT NULL,
      payload TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT '$syncPending'
    );
  ''';

  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_game_sync ON $tableGameAttempts (sync_status, timestamp);',
    'CREATE INDEX IF NOT EXISTS idx_checkin_sync ON $tableDailyCheckins (sync_status, timestamp);',
    'CREATE INDEX IF NOT EXISTS idx_events_sync ON $tableOfflineEvents (sync_status, created_at);',
  ];
}
