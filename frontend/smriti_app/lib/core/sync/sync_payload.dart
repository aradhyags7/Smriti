// SMRITI - Offline Sync Event & Payload Model
// Owner: Aradhya (AI + Database + Sync)

import 'dart:convert';

class OfflineEvent {
  final String eventId;
  final int? localId;
  final String patientId;
  final String eventType;
  final String createdAt;
  final Map<String, dynamic> payload;
  final String syncStatus;

  OfflineEvent({
    required this.eventId,
    this.localId,
    required this.patientId,
    required this.eventType,
    required this.createdAt,
    required this.payload,
    this.syncStatus = 'PENDING',
  });

  Map<String, dynamic> toBackendJson() => {
    'event_id': eventId,
    'local_id': localId,
    'patient_id': patientId,
    'event_type': eventType,
    'created_at': createdAt,
    'payload': payload,
  };

  Map<String, dynamic> toDbMap() => {
    'event_id': eventId,
    'local_id': localId,
    'patient_id': patientId,
    'event_type': eventType,
    'created_at': createdAt,
    'payload': jsonEncode(payload),
    'sync_status': syncStatus,
  };

  factory OfflineEvent.fromDbMap(Map<String, dynamic> map) => OfflineEvent(
    eventId: map['event_id'] as String,
    localId: map['local_id'] as int?,
    patientId: map['patient_id'] as String,
    eventType: map['event_type'] as String,
    createdAt: map['created_at'] as String,
    payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
    syncStatus: map['sync_status'] as String? ?? 'PENDING',
  );
}

class SyncBatchPayload {
  final String patientId;
  final List<OfflineEvent> events;

  SyncBatchPayload({
    required this.patientId,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'events': events.map((e) => e.toBackendJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());
}
