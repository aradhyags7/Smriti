import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';

class CaregiverPatient {
  final String patientId;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final int age;
  final String gender;
  final String relationship;
  final String status;
  final String statusColor;
  final int remindersCount;
  final double baselineMemory;
  final String? ashaName;
  final String? ashaPhone;
  final String? medicalNotes;

  CaregiverPatient({
    required this.patientId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.relationship,
    required this.status,
    required this.statusColor,
    required this.remindersCount,
    required this.baselineMemory,
    this.ashaName,
    this.ashaPhone,
    this.medicalNotes,
  });

  factory CaregiverPatient.fromJson(Map<String, dynamic> json) {
    return CaregiverPatient(
      patientId: json['patient_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Loved One',
      email: json['email'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'] ?? 70,
      gender: json['gender'] ?? 'other',
      relationship: json['relationship'] ?? 'Family Caregiver',
      status: json['status'] ?? 'Active',
      statusColor: json['status_color'] ?? 'green',
      remindersCount: json['reminders_count'] ?? 0,
      baselineMemory: (json['baseline_memory'] as num?)?.toDouble() ?? 70.0,
      ashaName: json['asha_name'],
      ashaPhone: json['asha_phone'],
      medicalNotes: json['medical_notes'],
    );
  }
}

class AvailablePatient {
  final String patientId;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final bool isConnected;

  AvailablePatient({
    required this.patientId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.isConnected,
  });

  factory AvailablePatient.fromJson(Map<String, dynamic> json) {
    return AvailablePatient(
      patientId: json['patient_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Patient',
      email: json['email'],
      phoneNumber: json['phone_number'],
      isConnected: json['is_connected'] ?? false,
    );
  }
}

class CaregiverService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<CaregiverPatient>> fetchMyPatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverMyPatients),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CaregiverPatient.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<AvailablePatient>> fetchAvailablePatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverAvailablePatients),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => AvailablePatient.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> connectPatient({
    String? patientId,
    String? patientEmail,
    String relationship = 'Family Caregiver',
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        if (patientId != null) 'patient_id': patientId,
        if (patientEmail != null) 'patient_email': patientEmail,
        'relationship': relationship,
      });
      final response = await http.post(
        Uri.parse(ApiEndpoints.caregiverConnectPatient),
        headers: headers,
        body: body,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disconnectPatient(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.caregiverDisconnectPatient(patientId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
