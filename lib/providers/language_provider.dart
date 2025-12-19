import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  // Supported languages
  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    LanguageModel(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    LanguageModel(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    LanguageModel(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    LanguageModel(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  ];

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  String getCurrentLanguageName() {
    final language = supportedLanguages.firstWhere(
          (lang) => lang.code == _currentLocale.languageCode,
      orElse: () => supportedLanguages.first,
    );
    return language.name;
  }

  bool isRTL() {
    return _currentLocale.languageCode == 'ar' || _currentLocale.languageCode == 'ur';
  }
}

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}