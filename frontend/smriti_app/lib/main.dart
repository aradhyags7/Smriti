import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/launch_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/patient/patient_home_screen.dart';
import 'features/patient/patient_onboarding_screen.dart';
import 'features/onboarding/cognitive_health_check_screen.dart';
import 'features/caregiver/caregiver_dashboard_screen.dart';
import 'features/asha/asha_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/daily_games_screen.dart';

void main() {
  runApp(const SmritiApp());
}

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smriti',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LaunchScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const PatientHomeScreen(),
        '/patient-onboarding': (context) => const PatientOnboardingScreen(),
        '/health-check': (context) => const CognitiveHealthCheckScreen(),
        '/caregiver-dashboard': (context) => const CaregiverDashboardScreen(),
        '/asha-dashboard': (context) => const AshaDashboardScreen(),
        '/games': (context) => const HomeScreen(),
        '/daily-games': (context) => const DailyGamesScreen(),
      },
    );
  }
}
