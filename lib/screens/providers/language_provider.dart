import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  // Supported languages with their display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ar': 'العربية (Arabic)',
    'bn': 'বাংলা (Bengali)',
    'de': 'Deutsch (German)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'gu': 'ગુજરાતી (Gujarati)',
    'hi': 'हिंदी (Hindi)',
    'id': 'Bahasa Indonesia (Indonesian)',
    'it': 'Italiano (Italian)',
    'ja': '日本語 (Japanese)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'mr': 'मराठी (Marathi)',
    'nl': 'Nederlands (Dutch)',
    'or': 'ଓଡ଼ିଆ (Odia)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'pl': 'Polski (Polish)',
    'pt': 'Português (Portuguese)',
    'ru': 'Русский (Russian)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'th': 'ไทย (Thai)',
    'tr': 'Türkçe (Turkish)',
    'ur': 'اردو (Urdu)',
    'vi': 'Tiếng Việt (Vietnamese)',
    'zh': '中文 (Chinese)',
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
