import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti_app/core/localization/app_language.dart';
import 'package:smriti_app/core/localization/app_translations.dart';
import 'package:smriti_app/core/localization/language_selection_modal.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.setLanguage('en');
  });

  group('AppLanguage and AppTranslations', () {
    test('supports all 7 required languages', () {
      final codes = AppLanguage.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'hi', 'as', 'bn', 'lus', 'nag', 'mni']));
      expect(AppLanguage.supportedLanguages.length, equals(7));
    });

    test('default language is English', () {
      expect(AppLanguage.currentCode, equals('en'));
      expect(AppLanguage.tr('app_title'), equals('Smriti'));
    });

    test('switches language and translates properly for Hindi', () async {
      await AppLanguage.setLanguage('hi');
      expect(AppLanguage.currentCode, equals('hi'));
      expect(AppLanguage.tr('app_title'), equals('स्मृति'));
      expect(AppLanguage.tr('change_language'), equals('भाषा बदलें'));
      expect(AppLanguage.tr('role_patient'), equals('मरीज़'));
    });

    test('switches language and translates properly for Assamese', () async {
      await AppLanguage.setLanguage('as');
      expect(AppLanguage.currentCode, equals('as'));
      expect(AppLanguage.tr('app_title'), equals('স্মৃতি'));
      expect(AppLanguage.tr('change_language'), equals('ভাষা সলনি কৰক'));
      expect(AppLanguage.tr('role_patient'), equals('ৰোগী'));
    });

    test('switches language and translates properly for Bengali', () async {
      await AppLanguage.setLanguage('bn');
      expect(AppLanguage.currentCode, equals('bn'));
      expect(AppLanguage.tr('app_title'), equals('স্মৃতি'));
      expect(AppLanguage.tr('change_language'), equals('ভাষা পরিবর্তন করুন'));
      expect(AppLanguage.tr('role_caregiver'), equals('সেবাকারী'));
    });

    test('switches language and translates properly for Mizo', () async {
      await AppLanguage.setLanguage('lus');
      expect(AppLanguage.currentCode, equals('lus'));
      expect(AppLanguage.tr('app_title'), equals('Smriti'));
      expect(AppLanguage.tr('change_language'), equals('Ṭawng thlakna'));
      expect(AppLanguage.tr('role_patient'), equals('Damlo'));
    });

    test('switches language and translates properly for Nagamese', () async {
      await AppLanguage.setLanguage('nag');
      expect(AppLanguage.currentCode, equals('nag'));
      expect(AppLanguage.tr('app_title'), equals('Smriti'));
      expect(AppLanguage.tr('change_language'), equals('Bhasha bodli koribi'));
      expect(AppLanguage.tr('role_patient'), equals('Bimar manu'));
    });

    test('switches language and translates properly for Manipuri', () async {
      await AppLanguage.setLanguage('mni');
      expect(AppLanguage.currentCode, equals('mni'));
      expect(AppLanguage.tr('app_title'), equals('স্মৃতী'));
      expect(AppLanguage.tr('change_language'), equals('লোন হোংদোকউ'));
      expect(AppLanguage.tr('role_patient'), equals('অনাবা'));
    });

    test('interpolates parameters correctly', () {
      final greeting = AppTranslations.get('hello_user', 'en', params: {'name': 'Ramesh'});
      expect(greeting, equals('Hello, Ramesh'));

      final hiGreeting = AppTranslations.get('hello_user', 'hi', params: {'name': 'रमेश'});
      expect(hiGreeting, equals('नमस्ते, रमेश'));
    });

    test('falls back safely to English for missing keys', () {
      final fallback = AppTranslations.get('non_existent_key_xyz', 'hi');
      expect(fallback, equals('non_existent_key_xyz'));
    });
  });

  group('Language Selection Sheet Widget Tests', () {
    testWidgets('renders all 7 languages in sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showLanguageSelectionSheet(context),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check native language names exist
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('অসমীয়া'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget);
      expect(find.text('Mizo ṭawng'), findsOneWidget);
      expect(find.text('নাগামিজ'), findsOneWidget);
      expect(find.text('মৈতৈলোন্'), findsOneWidget);

      // Select Hindi
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // AppLanguage should now be Hindi
      expect(AppLanguage.currentCode, equals('hi'));
    });
  });
}
