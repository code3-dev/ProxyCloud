import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguageCode = 'en';

  // Get saved language from storage
  Future<AppLanguage> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey) ?? _defaultLanguageCode;
      return AppLanguage.getByCode(savedCode);
    } catch (e) {
      return AppLanguage.getByCode(_defaultLanguageCode);
    }
  }

  // Save language to storage
  Future<bool> saveLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, language.code);
    } catch (e) {
      return false;
    }
  }

  // Load all available languages from assets
  Future<List<AppLanguage>> getAvailableLanguages() async {
    try {
      return AppLanguage.supportedLanguages;
    } catch (e) {
      return [AppLanguage.getByCode(_defaultLanguageCode)];
    }
  }

  // Load translations for a specific language
  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/languages/$languageCode.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap;
    } catch (e) {
      // If loading fails, try to load default language
      if (languageCode != _defaultLanguageCode) {
        return await loadTranslations(_defaultLanguageCode);
      }
      // Return empty map if even default fails
      return {};
    }
  }

  // Get device locale
  String getDeviceLocale() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return locale.languageCode;
    } catch (e) {
      return _defaultLanguageCode;
    }
  }

  // Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return AppLanguage.supportedLocales.contains(languageCode);
  }

  // Get best matching language for device
  Future<AppLanguage> getDeviceLanguage() async {
    final deviceLocale = getDeviceLocale();

    if (isLanguageSupported(deviceLocale)) {
      return AppLanguage.getByCode(deviceLocale);
    }

    // If exact match not found, check for language family (e.g., 'en-US' -> 'en')
    for (final supportedCode in AppLanguage.supportedLocales) {
      if (deviceLocale.startsWith(supportedCode)) {
        return AppLanguage.getByCode(supportedCode);
      }
    }

    return AppLanguage.getByCode(_defaultLanguageCode);
  }

  // Initialize language on first app launch
  Future<AppLanguage> initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);

      if (savedCode != null) {
        // User has previously selected a language
        return AppLanguage.getByCode(savedCode);
      } else {
        // First time launch, use device language
        final deviceLanguage = await getDeviceLanguage();
        await saveLanguage(deviceLanguage);
        return deviceLanguage;
      }
    } catch (e) {
      return AppLanguage.getByCode(_defaultLanguageCode);
    }
  }

  // Clear saved language (reset to default)
  Future<bool> clearSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_languageKey);
    } catch (e) {
      return false;
    }
  }
}
