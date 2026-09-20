import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  japanese,
  english;

  String get code => switch (this) {
        AppLanguage.japanese => 'ja',
        AppLanguage.english => 'en',
      };

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    if (code == 'en') {
      return AppLanguage.english;
    }
    return AppLanguage.japanese;
  }
}

class LocaleManager extends ChangeNotifier {
  LocaleManager(this._prefs) {
    _language = AppLanguage.fromCode(_prefs.getString(_key));
  }

  static const _key = 'santerra_language';

  final SharedPreferences _prefs;
  late AppLanguage _language;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  Future<void> setLanguage(AppLanguage value) async {
    final changed = _language != value;
    _language = value;
    // Always write so a partial/failed prior save can be repaired.
    await _prefs.setString(_key, value.code);
    if (changed) {
      notifyListeners();
    }
  }
}
