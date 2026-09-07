// SMRITI - Offline Sync Queue
// Owner: Aradhya (AI + Database + Sync)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_schema.dart';
import 'sync_payload.dart';

class SyncQueue {
  final DatabaseHelper databaseHelper;
  final String backendUrl;
  final http.Client _client;

  SyncQueue({
    DatabaseHelper? dbHelper,
    this.backendUrl = 'http://10.0.2.2:8000',
    http.Client? client,
  })  : databaseHelper = dbHelper ?? DatabaseHelper.instance,
        _client = client ?? http.Client();

  Future<List<OfflineEvent>> getPendingEvents({int limit = 100}) async {
    final db = await databaseHelper.database;
    final rows = await db.query(
      DatabaseSchema.tableOfflineEvents,
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: [DatabaseSchema.syncPending, DatabaseSchema.syncFailed],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map((r) => OfflineEvent.fromDbMap(r)).toList();
  }

  Future<void> enqueueEvent(OfflineEvent event) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseSchema.tableOfflineEvents,
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> processSyncBatch(String patientId) async {
    final pending = await getPendingEvents();
    if (pending.isEmpty) return true;

    final db = await databaseHelper.database;
    final eventIds = pending.map((e) => e.eventId).toList();
    final placeholders = List.filled(eventIds.length, '?').join(',');

    // 1. Mark SYNCING
    await db.rawUpdate('''
      UPDATE ${DatabaseSchema.tableOfflineEvents}
      SET sync_status = '${DatabaseSchema.syncSyncing}'
      WHERE event_id IN ($placeholders)
    ''', eventIds);

    final payload = SyncBatchPayload(patientId: patientId, events: pending);

    try {
      final response = await _client.post(
        Uri.parse('$backendUrl/api/sync'),
        headers: {'Content-Type': 'application/json'},
        body: payload.toJsonString(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final ackEventIds = decoded['synced_event_ids'] as List<dynamic>? ?? eventIds;

        if (ackEventIds.isNotEmpty) {
          final ackPlaceholders = List.filled(ackEventIds.length, '?').join(',');
          // 2. Mark SYNCED
          await db.rawUpdate('''
            UPDATE ${DatabaseSchema.tableOfflineEvents}
            SET sync_status = '${DatabaseSchema.syncSynced}'
            WHERE event_id IN ($ackPlaceholders)
          ''', ackEventIds);
        }
        return true;
      } else {
        // Mark FAILED
        await db.rawUpdate('''
          UPDATE ${DatabaseSchema.tableOfflineEvents}
          SET sync_status = '${DatabaseSchema.syncFailed}'
          WHERE event_id IN ($placeholders)
        ''', eventIds);
        return false;
      }
    } catch (_) {
      // Network failure: mark FAILED for retry on reconnect
      await db.rawUpdate('''
        UPDATE ${DatabaseSchema.tableOfflineEvents}
        SET sync_status = '${DatabaseSchema.syncFailed}'
        WHERE event_id IN ($placeholders)
      ''', eventIds);
      return false;
    }
  }
}
