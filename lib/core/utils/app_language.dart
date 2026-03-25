import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported game languages.
enum GameLanguage {
  en,
  tr;

  String get displayName {
    switch (this) {
      case GameLanguage.en:
        return 'English';
      case GameLanguage.tr:
        return 'Türkçe';
    }
  }

  String get flag {
    switch (this) {
      case GameLanguage.en:
        return '🇬🇧';
      case GameLanguage.tr:
        return '🇹🇷';
    }
  }
}

/// Global language state with SharedPreferences persistence.
class AppLanguageNotifier extends ChangeNotifier {
  static const _key = 'game_language';

  GameLanguage _language = GameLanguage.en;
  GameLanguage get language => _language;

  AppLanguageNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'tr') {
      _language = GameLanguage.tr;
    } else {
      _language = GameLanguage.en;
    }
    notifyListeners();
  }

  Future<void> setLanguage(GameLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.name);
  }

  Future<void> toggle() async {
    await setLanguage(
      _language == GameLanguage.en ? GameLanguage.tr : GameLanguage.en,
    );
  }
}
