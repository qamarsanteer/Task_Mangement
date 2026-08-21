import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/connectivity_service.dart';
import 'syncable.dart';

class SyncManager {
  final ConnectivityService _connectivityService;
  final List<Syncable> _syncables;

  StreamSubscription<bool>? _subscription;
  bool _wasConnected = true;

  SyncManager({
    required ConnectivityService connectivityService,
    required List<Syncable> syncables,
  })  : _connectivityService = connectivityService,
        _syncables = syncables;

  void start() {
    _subscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected && !_wasConnected) {
        syncAll();
      }
      _wasConnected = isConnected;
    });

    syncAll();
  }

  Future<void> syncAll() async {
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      debugPrint('[SyncManager] لا يوجد اتصال، تأجيل المزامنة.');
      return;
    }

    debugPrint('[SyncManager] بدء المزامنة مع ${_syncables.length} repository...');
    for (final syncable in _syncables) {
      try {
        await syncable.syncPendingChanges();
        debugPrint('[SyncManager] ${syncable.runtimeType} — تمت المزامنة بنجاح.');
      } catch (e) {
        debugPrint('[SyncManager] ${syncable.runtimeType} — فشلت المزامنة: $e');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
