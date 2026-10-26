import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _localeKey = 'app_locale';

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  void setLocale(Locale newLocale) async {
    if (!['en', 'hi', 'kn', 'ta', 'ml'].contains(newLocale.languageCode)) return;
    
    _locale = newLocale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    
    if (languageCode != null && languageCode.isNotEmpty) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  void clearLocale() async {
    _locale = const Locale('en');
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
  }
}
