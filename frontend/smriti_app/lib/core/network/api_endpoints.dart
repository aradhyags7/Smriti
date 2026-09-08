import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Live Render backend URL.
  // Can be configured directly here or passed at build time:
  // flutter build apk --dart-define=BACKEND_URL=https://your-service.onrender.com
  static const String _envUrl = String.fromEnvironment('BACKEND_URL');

  // Production Render cloud backend URL
  static String liveBackendUrl = 'https://smriti-rmbr.onrender.com';

  // Local development fallback for emulators and local testing
  static String get localFallbackUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static String get baseUrl {
    // 1. Build-time override via --dart-define=BACKEND_URL=...
    if (_envUrl.isNotEmpty) {
      return _envUrl.endsWith('/') ? _envUrl.substring(0, _envUrl.length - 1) : _envUrl;
    }

    // 2. In release/APK mode (standalone APK on real phones), ALWAYS use the live cloud backend
    if (kReleaseMode || kProfileMode) {
      return liveBackendUrl.endsWith('/')
          ? liveBackendUrl.substring(0, liveBackendUrl.length - 1)
          : liveBackendUrl;
    }

    // 3. In debug mode: try live backend first, with automatic local fallback in ApiClient
    return liveBackendUrl.endsWith('/')
        ? liveBackendUrl.substring(0, liveBackendUrl.length - 1)
        : liveBackendUrl;
  }

  static String get rootHealth => '$baseUrl/';
  static String get signup => '$baseUrl/api/v1/auth/signup';
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get googleLogin => '$baseUrl/api/v1/auth/google';
  static String get me => '$baseUrl/api/v1/auth/me';
  static String get patients => '$baseUrl/api/v1/patients';
  static String get patientMe => '$baseUrl/api/v1/patients/me';
  static String get patientOnboarding => '$baseUrl/api/v1/patients/onboarding';
  static String get games => '$baseUrl/api/v1/games';
  static String get sync => '$baseUrl/api/v1/sync';
  
  // Reminders
  static String get reminders => '$baseUrl/api/v1/reminders/';
  static String reminderAcknowledge(String id) => '$baseUrl/api/v1/reminders/$id/acknowledge';
  static String reminderDetail(String id) => '$baseUrl/api/v1/reminders/$id';

  // Caregiver Patient Connection
  static String get caregiverMyPatients => '$baseUrl/api/v1/caregivers/my-patients';
  static String get caregiverAvailablePatients => '$baseUrl/api/v1/caregivers/available-patients';
  static String get caregiverConnectPatient => '$baseUrl/api/v1/caregivers/connect-patient';
  static String caregiverDisconnectPatient(String patientId) => '$baseUrl/api/v1/caregivers/disconnect-patient/$patientId';

  // ASHA Worker Patient Management
  static String get ashaMyPatients => '$baseUrl/api/v1/asha/my-patients';
  static String get ashaCommunityPatients => '$baseUrl/api/v1/asha/community-patients';
  static String get ashaAssignPatient => '$baseUrl/api/v1/asha/assign-patient';
  static String ashaUnassignPatient(String patientId) => '$baseUrl/api/v1/asha/unassign-patient/$patientId';

  // Patient Care Circle
  static String get patientCareCircle => '$baseUrl/api/v1/asha/care-circle';

  // Caregiver Patient Analytics & Features
  static String caregiverAnalytics(String patientId, {int days = 14}) => '$baseUrl/api/v1/caregivers/patient/$patientId/analytics?days=$days';
  static String caregiverActivityFeed(String patientId) => '$baseUrl/api/v1/caregivers/patient/$patientId/activity-feed';
  static String caregiverAlerts(String patientId) => '$baseUrl/api/v1/caregivers/patient/$patientId/alerts';
  static String caregiverAcknowledgeAlert(String alertId) => '$baseUrl/api/v1/caregivers/alerts/$alertId/acknowledge';
  static String caregiverReminiscences(String patientId) => '$baseUrl/api/v1/caregivers/patient/$patientId/reminiscence';
  static String caregiverDeleteReminiscence(String memoryId) => '$baseUrl/api/v1/caregivers/reminiscence/$memoryId';
}
