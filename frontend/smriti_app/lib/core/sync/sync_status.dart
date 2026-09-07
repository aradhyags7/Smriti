// SMRITI - Sync Status States
// Owner: Aradhya (AI + Database + Sync)

enum SyncStatusState {
  pending,
  syncing,
  synced,
  failed,
}

class SyncProgress {
  final SyncStatusState state;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncProgress({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncProgress copyWith({
    SyncStatusState? state,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncProgress(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
