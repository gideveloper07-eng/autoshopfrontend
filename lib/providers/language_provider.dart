import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  // Supported languages with their display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'gu': 'ગુજરાતી (Gujarati)',
    'es': 'Español (Spanish)',
  };
  
  // Get list of supported locales
  static List<Locale> get supportedLocales {
    return supportedLanguages.keys.map((code) => Locale(code)).toList();
  }
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code');
      
      if (languageCode != null && supportedLanguages.containsKey(languageCode)) {
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }
  
  // Change language and save preference
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      print('Unsupported language code: $languageCode');
      return;
    }
    
    _locale = Locale(languageCode);
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }
  
  // Get display name for current language
  String get currentLanguageName {
    return supportedLanguages[_locale.languageCode] ?? 'English';
  }
  
  // Get display name for any language code
  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }
}
