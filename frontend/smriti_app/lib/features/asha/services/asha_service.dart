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
  final String? dementiaType;
  final String village;
  final String district;
  final String status;
  final String statusColor;
  final String triagePriority;
  final bool consentForAsha;
  final String? caregiverName;
  final String? caregiverPhone;
  final String? caregiverRelationship;
  final double baselineMemory;
  final double baselineAttention;
  final double baselineEngagement;
  final String primaryLanguage;
  final String? medicalNotes;
  final String lastVisit;
  final int unresolvedAlertsCount;

  AshaPatient({
    required this.patientId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.age,
    required this.gender,
    this.dementiaType,
    required this.village,
    required this.district,
    required this.status,
    required this.statusColor,
    this.triagePriority = 'STABLE',
    required this.consentForAsha,
    this.caregiverName,
    this.caregiverPhone,
    this.caregiverRelationship = 'Family Caregiver',
    required this.baselineMemory,
    this.baselineAttention = 70.0,
    this.baselineEngagement = 70.0,
    this.primaryLanguage = 'en',
    this.medicalNotes,
    required this.lastVisit,
    this.unresolvedAlertsCount = 0,
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
      dementiaType: json['dementia_type'],
      village: json['village'] ?? 'Guwahati Sector',
      district: json['district'] ?? 'Kamrup',
      status: json['status'] ?? 'Stable',
      statusColor: json['status_color'] ?? 'green',
      triagePriority: json['triage_priority'] ?? 'STABLE',
      consentForAsha: json['consent_for_asha'] ?? true,
      caregiverName: json['caregiver_name'],
      caregiverPhone: json['caregiver_phone'],
      caregiverRelationship: json['caregiver_relationship'] ?? 'Family Caregiver',
      baselineMemory: (json['baseline_memory'] as num?)?.toDouble() ?? 70.0,
      baselineAttention: (json['baseline_attention'] as num?)?.toDouble() ?? 70.0,
      baselineEngagement: (json['baseline_engagement'] as num?)?.toDouble() ?? 70.0,
      primaryLanguage: json['primary_language'] ?? 'en',
      medicalNotes: json['medical_notes'],
      lastVisit: json['last_visit'] ?? 'Recent',
      unresolvedAlertsCount: json['unresolved_alerts_count'] ?? 0,
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

class AshaEmergencyAlert {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String riskLevel;
  final String severity;
  final String reason;
  final bool isAcknowledged;
  final String createdAt;

  AshaEmergencyAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.riskLevel,
    required this.severity,
    required this.reason,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory AshaEmergencyAlert.fromJson(Map<String, dynamic> json) {
    return AshaEmergencyAlert(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? 'Patient',
      patientAge: json['patient_age'] ?? 72,
      riskLevel: json['risk_level'] ?? 'MONITOR',
      severity: json['severity'] ?? 'MEDIUM',
      reason: json['reason'] ?? '',
      isAcknowledged: json['is_acknowledged'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AshaPatientDetailData {
  final AshaPatient patient;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? activityFeed;
  final List<AshaEmergencyAlert> alerts;
  final List<String> medicalNotesHistory;

  AshaPatientDetailData({
    required this.patient,
    this.analytics,
    this.activityFeed,
    required this.alerts,
    required this.medicalNotesHistory,
  });

  factory AshaPatientDetailData.fromJson(Map<String, dynamic> json) {
    final patientJson = json['patient'] as Map<String, dynamic>? ?? {};
    final alertsList = (json['alerts'] as List<dynamic>?)
            ?.map((e) => AshaEmergencyAlert.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final notesList = (json['medical_notes_history'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AshaPatientDetailData(
      patient: AshaPatient.fromJson(patientJson),
      analytics: json['analytics'] as Map<String, dynamic>?,
      activityFeed: json['activity_feed'] as Map<String, dynamic>?,
      alerts: alertsList,
      medicalNotesHistory: notesList,
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

  Future<Map<String, dynamic>?> fetchTriageBoard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.ashaTriageBoard),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> patientsRaw = data['patients'] ?? [];
        final patients = patientsRaw.map((p) => AshaPatient.fromJson(p)).toList();
        return {
          'total_patients': data['total_patients'] ?? patients.length,
          'critical_count': data['critical_count'] ?? 0,
          'attention_count': data['attention_count'] ?? 0,
          'monitor_count': data['monitor_count'] ?? 0,
          'stable_count': data['stable_count'] ?? 0,
          'patients': patients,
        };
      }
    } catch (_) {}
    return null;
  }

  Future<List<AshaEmergencyAlert>> fetchEmergencyAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.ashaEmergencyAlerts),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => AshaEmergencyAlert.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> updateMedicalNotes({
    required String patientId,
    required String notes,
    String? visitDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> payload = {'notes': notes};
      if (visitDate != null) payload['visit_date'] = visitDate;
      final response = await http.post(
        Uri.parse(ApiEndpoints.ashaMedicalNotes(patientId)),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AshaPatientDetailData?> fetchPatientDetail(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.ashaPatientDetail(patientId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AshaPatientDetailData.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
