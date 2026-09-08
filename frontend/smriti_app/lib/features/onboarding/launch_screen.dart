import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  String _selectedLanguageCode = 'en';
  String _selectedDialect = 'English';

  // Exactly the 6 Northeast & regional languages requested in their native script
  final List<Map<String, String>> _dialects = [
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
      'native': 'English',
      'english': 'English',
      'code': 'en',
    },
    {
      'native': 'মৈতৈলোন্',
      'english': 'Manipuri',
      'code': 'mni',
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
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('preferred_language');
    if (savedCode != null && mounted) {
      final match = _dialects.firstWhere(
        (d) => d['code'] == savedCode,
        orElse: () => _dialects[2], // English default
      );
      setState(() {
        _selectedLanguageCode = match['code']!;
        _selectedDialect = match['native']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  // Top Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1CCBA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.spa,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'COGNITIVE WELLNESS',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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
                    'Namaskar \u2022 Khurumjari \u2022 Ronggila \u2022 Welcome',
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
                      border:
                          Border.all(color: const Color(0xFFDDEEE4), width: 4),
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
                          return const Icon(Icons.image,
                              size: 48, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'SMRITI',
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
                    'Remember \u2022 Reconnect \u2022 Thrive',
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
                          child: const Row(
                            children: [
                              Icon(Icons.favorite, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'Patient Care Portal',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_forward, size: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.family_restroom, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Family Caregiver Portal',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.health_and_safety, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'ASHA / Health Worker Portal',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Dialect section
                        Text(
                          'CHOOSE DIALECT',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF5A7264),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        // Grid of 6 dialects in their native words
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.6,
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
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                    'preferred_language', dialect['code']!);
                                await prefs.setString(
                                    'selected_dialect', dialect['native']!);
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
                      Text(
                        'A gentle space for cherished memories and daily peace',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF4A6B5D),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assamese \u2022 Bengali \u2022 English \u2022 Manipuri \u2022 Mizo \u2022 Nagamese',
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
  }
}
