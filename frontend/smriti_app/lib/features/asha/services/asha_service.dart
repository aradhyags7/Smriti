import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';

class AshaPatient {
  final String patientId;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int age;
  final String gender;
  final String village;
  final String district;
  final String status;
  final String statusColor;
  final bool consentForAsha;
  final String? caregiverName;
  final String? caregiverPhone;
  final double baselineMemory;
  final String lastVisit;

  AshaPatient({
    required this.patientId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.age,
    required this.gender,
    required this.village,
    required this.district,
    required this.status,
    required this.statusColor,
    required this.consentForAsha,
    this.caregiverName,
    this.caregiverPhone,
    required this.baselineMemory,
    required this.lastVisit,
  });

  factory AshaPatient.fromJson(Map<String, dynamic> json) {
    return AshaPatient(
      patientId: json['patient_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Community Patient',
      email: json['email'],
      phoneNumber: json['phone_number'],
      age: json['age'] ?? 72,
      gender: json['gender'] ?? 'other',
      village: json['village'] ?? 'Guwahati Sector',
      district: json['district'] ?? 'Kamrup',
      status: json['status'] ?? 'Stable',
      statusColor: json['status_color'] ?? 'green',
      consentForAsha: json['consent_for_asha'] ?? true,
      caregiverName: json['caregiver_name'],
      caregiverPhone: json['caregiver_phone'],
      baselineMemory: (json['baseline_memory'] as num?)?.toDouble() ?? 70.0,
      lastVisit: json['last_visit'] ?? 'Recent',
    );
  }
}

class CommunityPatient {
  final String patientId;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final bool isAssigned;
  final String? assignedAshaName;

  CommunityPatient({
    required this.patientId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.isAssigned,
    this.assignedAshaName,
  });

  factory CommunityPatient.fromJson(Map<String, dynamic> json) {
    return CommunityPatient(
      patientId: json['patient_id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Patient',
      email: json['email'],
      phoneNumber: json['phone_number'],
      isAssigned: json['is_assigned'] ?? false,
      assignedAshaName: json['assigned_asha_name'],
    );
  }
}

class AshaService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AshaPatient>> fetchMyPatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.ashaMyPatients),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => AshaPatient.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<CommunityPatient>> fetchCommunityPatients() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.ashaCommunityPatients),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => CommunityPatient.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> assignPatient({
    required String patientId,
    String? villageNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> map = {'patient_id': patientId};
      if (villageNotes != null) map['village_notes'] = villageNotes;
      final body = jsonEncode(map);
      final response = await http.post(
        Uri.parse(ApiEndpoints.ashaAssignPatient),
        headers: headers,
        body: body,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unassignPatient(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.ashaUnassignPatient(patientId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
