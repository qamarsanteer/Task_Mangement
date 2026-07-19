import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _isDarkModeKey = 'is_dark_mode';
  static const _localeCodeKey = 'locale_code';

  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get isDarkMode => _prefs.getBool(_isDarkModeKey) ?? false;

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_isDarkModeKey, value);
  }

  String get localeCode => _prefs.getString(_localeCodeKey) ?? 'en';

  Future<void> setLocaleCode(String code) async {
    await _prefs.setString(_localeCodeKey, code);
  }
}