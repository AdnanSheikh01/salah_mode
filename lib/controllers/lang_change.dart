import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangChangeController with ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> loadLocale() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    String? code = sp.getString('language_code');

    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  void changeLang(Locale locale) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    _locale = locale;

    await sp.setString('language_code', locale.languageCode);

    notifyListeners();
  }
}
