import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Uses 10.0.2.2 for Android emulator, 127.0.0.1 for Windows/Web/macOS
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static String get rootHealth => '$baseUrl/';
  static String get signup => '$baseUrl/api/v1/auth/signup';
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get me => '$baseUrl/api/v1/auth/me';
  static String get patients => '$baseUrl/api/v1/patients';
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
}
