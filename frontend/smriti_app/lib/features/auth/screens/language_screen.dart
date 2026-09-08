import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_selection_modal.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.tr('select_language')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F4D36),
        elevation: 0,
      ),
      body: const SafeArea(
        child: LanguageSelectionSheet(),
      ),
    );
  }
}
