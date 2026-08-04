import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/connectivity_service.dart';
import 'syncable.dart';

/// بيسمع لحظة رجوع الإنترنت وبينده كل الـ Repositories (Syncable)
/// حتى تبعت أي تعديلات صارت وقت ما كان الموبايل أوفلاين.
///
/// يتسجّل كـ singleton واحد بالـ service locator، وينادى `start()` مرة
/// وحدة بس عند إقلاع التطبيق (بـ main.dart).
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

  /// يبلش الاستماع لتغيّرات الاتصال، وكمان يجرب مزامنة فورية
  /// (بحال كان في تعديلات معلّقة من جلسة سابقة قبل ما يفتح التطبيق).
  void start() {
    _subscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      // منزامن بس لما نكون *رجعنا* متصلين (مش كل مرة الـ stream يبعت حدث).
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
        // إذا فشلت مزامنة Repository وحدة (مثلاً السيرفر رجع خطأ)،
        // منكمل بالباقي ومنجرب هاي كمان بالمرة الجاية.
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
