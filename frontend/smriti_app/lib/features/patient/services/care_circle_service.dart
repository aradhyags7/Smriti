import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';

class CaregiverInfo {
  final String name;
  final String? phone;
  final String? email;
  final String relationship;

  CaregiverInfo({
    required this.name,
    this.phone,
    this.email,
    required this.relationship,
  });

  factory CaregiverInfo.fromJson(Map<String, dynamic> json) {
    return CaregiverInfo(
      name: json['name'] ?? 'Family Caregiver',
      phone: json['phone'],
      email: json['email'],
      relationship: json['relationship'] ?? 'Family Caregiver',
    );
  }
}

class AshaInfo {
  final String name;
  final String? phone;
  final String village;
  final String district;

  AshaInfo({
    required this.name,
    this.phone,
    required this.village,
    required this.district,
  });

  factory AshaInfo.fromJson(Map<String, dynamic> json) {
    return AshaInfo(
      name: json['name'] ?? 'ASHA Worker',
      phone: json['phone'],
      village: json['village'] ?? 'Local Village',
      district: json['district'] ?? 'District',
    );
  }
}

class CareCircleData {
  final CaregiverInfo? caregiver;
  final AshaInfo? ashaWorker;
  final String patientName;
  final String? patientEmail;

  CareCircleData({
    this.caregiver,
    this.ashaWorker,
    required this.patientName,
    this.patientEmail,
  });

  factory CareCircleData.fromJson(Map<String, dynamic> json) {
    return CareCircleData(
      caregiver: json['caregiver'] != null ? CaregiverInfo.fromJson(json['caregiver']) : null,
      ashaWorker: json['asha_worker'] != null ? AshaInfo.fromJson(json['asha_worker']) : null,
      patientName: json['patient_name'] ?? 'Patient',
      patientEmail: json['patient_email'],
    );
  }
}

class CareCircleService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<CareCircleData?> fetchCareCircle() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.patientCareCircle),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return CareCircleData.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }
}
