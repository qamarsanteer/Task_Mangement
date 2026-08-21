import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);


  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }

  List<Map<String, dynamic>>? getList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveObject(String key, Map<String, dynamic> item) async {
    await _prefs.setString(key, jsonEncode(item));
  }

  Map<String, dynamic>? getObject(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
