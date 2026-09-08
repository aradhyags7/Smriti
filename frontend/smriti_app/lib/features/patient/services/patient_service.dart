import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PatientProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int age;
  final String gender;
  final String? dementiaType;
  final bool isOnboarded;
  final String preferredLanguage;

  PatientProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.age,
    required this.gender,
    this.dementiaType,
    required this.isOnboarded,
    this.preferredLanguage = 'en',
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Patient',
      email: json['email'],
      phoneNumber: json['phone_number'],
      age: json['age'] ?? 70,
      gender: json['gender'] ?? 'other',
      dementiaType: json['dementia_type'],
      isOnboarded: json['is_onboarded'] ?? false,
      preferredLanguage: json['preferred_language'] ?? 'en',
    );
  }
}

class PatientService {
  final ApiClient _apiClient = ApiClient();

  /// Check local cached onboarding state
  Future<bool> isLocallyOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('patient_onboarded') ?? false;
  }

  /// Mark onboarding complete in local cache
  Future<void> setLocallyOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('patient_onboarded', value);
  }

  /// Fetch profile from backend to check server-side onboarding status
  Future<PatientProfile?> fetchProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.patientMe, requireAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = PatientProfile.fromJson(data);
        if (profile.isOnboarded) {
          await setLocallyOnboarded(true);
        }
        return profile;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit one-time onboarding data
  Future<Map<String, dynamic>> submitOnboarding({
    required int age,
    required String gender,
    required String dementiaType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.patientOnboarding,
        body: {
          'age': age,
          'gender': gender.toLowerCase().trim(),
          'dementia_type': dementiaType.trim(),
        },
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await setLocallyOnboarded(true);
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['detail'] ?? 'Failed to save health profile.'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
