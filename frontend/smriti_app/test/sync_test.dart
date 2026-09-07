// SMRITI - Sync Unit Tests
// Owner: Aradhya (AI + Database + Sync)

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_app/core/sync/sync_payload.dart';
import 'package:smriti_app/core/sync/sync_status.dart';

void main() {
  group('Sync Payload & Offline Event Tests', () {
    test('OfflineEvent serializes to Backend JSON correctly', () {
      final event = OfflineEvent(
        eventId: 'EVT-UUID-1001',
        localId: 42,
        patientId: 'PAT-001',
        eventType: 'GAME_ATTEMPT',
        createdAt: '2026-09-07T10:00:00.000Z',
        payload: {
          'game_type': 'memory_pairs',
          'score': 88.5,
          'mistakes': 1,
          'reaction_time_ms': 1200.0,
        },
        syncStatus: 'PENDING',
      );

      final backendJson = event.toBackendJson();
      expect(backendJson['event_id'], equals('EVT-UUID-1001'));
      expect(backendJson['local_id'], equals(42));
      expect(backendJson['patient_id'], equals('PAT-001'));
      expect(backendJson['event_type'], equals('GAME_ATTEMPT'));
      expect(backendJson['payload']['score'], equals(88.5));
    });

    test('OfflineEvent serializes to SQLite DB map and roundtrips via fromDbMap', () {
      final event = OfflineEvent(
        eventId: 'EVT-UUID-1002',
        localId: 7,
        patientId: 'PAT-001',
        eventType: 'DAILY_CHECKIN',
        createdAt: '2026-09-07T10:15:00.000Z',
        payload: {
          'mood': 5,
          'sleep_quality': 4,
          'activity_level': 3,
        },
        syncStatus: 'PENDING',
      );

      final dbMap = event.toDbMap();
      expect(dbMap['event_id'], equals('EVT-UUID-1002'));
      expect(dbMap['payload'], isA<String>()); // Serialized as JSON string for SQLite

      final roundtrip = OfflineEvent.fromDbMap(dbMap);
      expect(roundtrip.eventId, equals('EVT-UUID-1002'));
      expect(roundtrip.localId, equals(7));
      expect(roundtrip.payload['mood'], equals(5));
      expect(roundtrip.payload['sleep_quality'], equals(4));
    });

    test('SyncBatchPayload combines multiple events for upload', () {
      final events = [
        OfflineEvent(
          eventId: 'EVT-1',
          patientId: 'PAT-001',
          eventType: 'GAME_ATTEMPT',
          createdAt: '2026-09-07T10:00:00.000Z',
          payload: {'score': 90.0},
        ),
        OfflineEvent(
          eventId: 'EVT-2',
          patientId: 'PAT-001',
          eventType: 'DAILY_CHECKIN',
          createdAt: '2026-09-07T10:05:00.000Z',
          payload: {'mood': 4},
        ),
      ];

      final batch = SyncBatchPayload(patientId: 'PAT-001', events: events);
      final json = batch.toJson();

      expect(json['patient_id'], equals('PAT-001'));
      expect(json['events'], isA<List>());
      expect((json['events'] as List).length, equals(2));
      expect(batch.toJsonString(), contains('EVT-1'));
    });

    test('SyncProgress tracks state transitions', () {
      var progress = const SyncProgress(
        state: SyncStatusState.pending,
        pendingCount: 5,
      );
      expect(progress.state, equals(SyncStatusState.pending));
      expect(progress.pendingCount, equals(5));

      // Transition to syncing
      progress = progress.copyWith(state: SyncStatusState.syncing);
      expect(progress.state, equals(SyncStatusState.syncing));

      // Transition to synced
      final now = DateTime.now();
      progress = progress.copyWith(
        state: SyncStatusState.synced,
        pendingCount: 0,
        lastSyncedAt: now,
      );
      expect(progress.state, equals(SyncStatusState.synced));
      expect(progress.pendingCount, equals(0));
      expect(progress.lastSyncedAt, equals(now));
    });
  });
}
