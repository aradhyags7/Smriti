// SMRITI - Sync Manager & Connectivity Orchestrator
// Owner: Aradhya (AI + Database + Sync)

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sync_queue.dart';
import 'sync_status.dart';

class SyncManager extends ChangeNotifier {
  final SyncQueue _queue;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  SyncProgress _progress = const SyncProgress(state: SyncStatusState.pending);
  SyncProgress get progress => _progress;

  String patientId;

  SyncManager({
    SyncQueue? queue,
    Connectivity? connectivity,
    this.patientId = 'P102',
  })  : _queue = queue ?? SyncQueue(),
        _connectivity = connectivity ?? Connectivity() {
    _initListener();
  }

  void _initListener() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (isOnline) {
        syncNow();
      }
    });
  }

  Future<bool> syncNow() async {
    _progress = _progress.copyWith(state: SyncStatusState.syncing);
    notifyListeners();

    final success = await _queue.processSyncBatch(patientId);

    if (success) {
      _progress = _progress.copyWith(
        state: SyncStatusState.synced,
        lastSyncedAt: DateTime.now(),
      );
    } else {
      _progress = _progress.copyWith(
        state: SyncStatusState.failed,
        errorMessage: 'Sync failed or backend unreachable',
      );
    }

    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
