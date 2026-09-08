import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

/// Structured information about a supported language in Smriti.
class AppLanguageInfo {
  final String code;
  final String englishName;
  final String nativeName;
  final String flag;
  final String bcp47;

  const AppLanguageInfo({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
    required this.bcp47,
  });
}

/// Global localization controller for the Smriti application.
///
/// Features:
/// - Reactive `languageNotifier` that triggers app-wide rebuilds
/// - Persistent language preference via `SharedPreferences`
/// - Safe fallback to English for missing keys
/// - Parameter interpolation (`{key}` placeholders)
class AppLanguage {
  /// All 7 languages officially supported across Smriti interfaces.
  static const List<AppLanguageInfo> supportedLanguages = [
    AppLanguageInfo(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      flag: '🌐',
      bcp47: 'en-IN',
    ),
    AppLanguageInfo(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      bcp47: 'hi-IN',
    ),
    AppLanguageInfo(
      code: 'as',
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
      flag: '🌸',
      bcp47: 'as-IN',
    ),
    AppLanguageInfo(
      code: 'bn',
      englishName: 'Bengali',
      nativeName: 'বাংলা',
      flag: '🌿',
      bcp47: 'bn-IN',
    ),
    AppLanguageInfo(
      code: 'lus',
      englishName: 'Mizo',
      nativeName: 'Mizo ṭawng',
      flag: '⛰️',
      bcp47: 'lus-IN',
    ),
    AppLanguageInfo(
      code: 'nag',
      englishName: 'Nagamese',
      nativeName: 'নাগামিজ',
      flag: '🦅',
      bcp47: 'nag-IN',
    ),
    AppLanguageInfo(
      code: 'mni',
      englishName: 'Manipuri',
      nativeName: 'মৈতৈলোন্',
      flag: '🌺',
      bcp47: 'mni-IN',
    ),
  ];

  /// Notifier driving reactive rebuilds across the application.
  static final ValueNotifier<String> languageNotifier =
      ValueNotifier<String>('en');

  /// Currently active 2-3 letter ISO language code.
  static String get currentCode => languageNotifier.value;

  /// Metadata for the active language.
  static AppLanguageInfo get currentLanguage {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == languageNotifier.value,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Initializes the language from stored device preferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('preferred_language');
      if (saved != null &&
          supportedLanguages.any((lang) => lang.code == saved)) {
        languageNotifier.value = saved;
      }
    } catch (_) {
      // Default remains 'en' if SharedPreferences is unavailable
    }
  }

  /// Sets the active language code, persists it, and notifies all listening widgets.
  static Future<void> setLanguage(String code) async {
    final match = supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first,
    );

    languageNotifier.value = match.code;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_language', match.code);
      await prefs.setString('selected_dialect', match.nativeName);
    } catch (_) {}
  }

  /// Translates a given translation [key] using the active language.
  ///
  /// Supports parameter interpolation via `{paramName}` tokens.
  static String tr(String key, {Map<String, String>? params}) {
    return AppTranslations.get(key, languageNotifier.value, params: params);
  }
}

/// Convenience extension on [BuildContext] for UI string translation.
extension AppLocalizationExtension on BuildContext {
  /// Translates [key] in the current application language.
  String tr(String key, {Map<String, String>? params}) {
    return AppLanguage.tr(key, params: params);
  }
}
