import 'package:flutter/material.dart';
import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  String _selectedLanguageCode = 'en';
  String _selectedDialect = 'English';

  // All 7 supported languages in their authentic native script
  final List<Map<String, String>> _dialects = const [
    {
      'native': 'English',
      'english': 'English',
      'code': 'en',
    },
    {
      'native': 'हिन्दी',
      'english': 'Hindi',
      'code': 'hi',
    },
    {
      'native': 'অসমীয়া',
      'english': 'Assamese',
      'code': 'as',
    },
    {
      'native': 'বাংলা',
      'english': 'Bengali',
      'code': 'bn',
    },
    {
      'native': 'Mizo ṭawng',
      'english': 'Mizo',
      'code': 'lus',
    },
    {
      'native': 'নাগামিজ',
      'english': 'Nagamese',
      'code': 'nag',
    },
    {
      'native': 'মৈতৈলোন্',
      'english': 'Manipuri',
      'code': 'mni',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = AppLanguage.currentCode;
    final match = _dialects.firstWhere(
      (d) => d['code'] == _selectedLanguageCode,
      orElse: () => _dialects[0],
    );
    _selectedDialect = match['native']!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.languageNotifier,
      builder: (context, activeCode, _) {
        _selectedLanguageCode = activeCode;
        final currentMatch = _dialects.firstWhere(
          (d) => d['code'] == activeCode,
          orElse: () => _dialects[0],
        );
        _selectedDialect = currentMatch['native']!;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC1E4CE), // soft mint green
                  Color(0xFFEDF3E8), // pale base
                  Color(0xFFF1F1E6),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    children: [
                      // Top Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1CCBA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.spa, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'COGNITIVE WELLNESS',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Greetings
                      Text(
                        'Namaskar • Khurumjari • Ronggila • Welcome',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Logo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDDEEE4), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo/smriti-logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 48, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        AppLanguage.tr('app_title').toUpperCase(),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remember With Us',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Remember • Reconnect • Thrive',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF4A6B5D),
                            ),
                      ),
                      const SizedBox(height: 32),
                      // Main Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Patient Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                  arguments: {
                                    'role': 'patient',
                                    'language': _selectedLanguageCode,
                                    'dialect': _selectedDialect,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF387E61),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${AppLanguage.tr('role_patient')} Care Portal',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward, size: 22),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Caregiver Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                  arguments: {
                                    'role': 'caregiver',
                                    'language': _selectedLanguageCode,
                                    'dialect': _selectedDialect,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1EFE3),
                                foregroundColor: const Color(0xFF1F4D36),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shield, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLanguage.tr('caregiver_dashboard'),
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // ASHA Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                  arguments: {
                                    'role': 'asha',
                                    'language': _selectedLanguageCode,
                                    'dialect': _selectedDialect,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1EFE3),
                                foregroundColor: const Color(0xFF1F4D36),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.health_and_safety, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLanguage.tr('asha_portal'),
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Dialect section
                            Text(
                              AppLanguage.tr('choose_language').toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF5A7264),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Grid of 7 dialects in their native words
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _dialects.length,
                              itemBuilder: (context, index) {
                                final dialect = _dialects[index];
                                final isSelected =
                                    _selectedLanguageCode == dialect['code'];
                                return GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _selectedLanguageCode = dialect['code']!;
                                      _selectedDialect = dialect['native']!;
                                    });
                                    await AppLanguage.setLanguage(dialect['code']!);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF387E61)
                                          : const Color(0xFFF1EFE3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2B634C)
                                            : const Color(0xFFE5DEC9),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dialect['native']!,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF1F4D36),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                dialect['english']!,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : const Color(0xFF6B8074),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded,
                                              color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AppLanguage.tr('app_tagline'),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF4A6B5D),
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assamese • Bengali • English • Hindi • Manipuri • Mizo • Nagamese',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF7A8D83),
                              fontSize: 10,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
