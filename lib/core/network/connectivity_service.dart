import 'package:connectivity_plus/connectivity_plus.dart';

/// طبقة عامة لفحص الاتصال بالإنترنت.
/// كل الـ Repositories بتستخدمها قبل ما تقرر تطلب من السيرفر أو ترجع للكاش.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// فحص فوري: هل في اتصال بالإنترنت هلق؟
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  /// Stream بيبعت true/false كل ما يتغير حال الاتصال (يستخدمه SyncManager).
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
