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
  final String? dementiaType;
  final String relationship;
  final String status;
  final String statusColor;
  final int remindersCount;
  final double baselineMemory;
  final String preferredLanguage;
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
    this.dementiaType,
    required this.relationship,
    required this.status,
    required this.statusColor,
    required this.remindersCount,
    required this.baselineMemory,
    this.preferredLanguage = 'en',
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
      dementiaType: json['dementia_type'],
      relationship: json['relationship'] ?? 'Family Caregiver',
      status: json['status'] ?? 'Active',
      statusColor: json['status_color'] ?? 'green',
      remindersCount: json['reminders_count'] ?? 0,
      baselineMemory: (json['baseline_memory'] as num?)?.toDouble() ?? 70.0,
      preferredLanguage: json['preferred_language'] ?? 'en',
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

class TrendPoint {
  final String date;
  final double memory;
  final double attention;
  final double engagement;

  TrendPoint({
    required this.date,
    required this.memory,
    required this.attention,
    required this.engagement,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] ?? '',
      memory: (json['memory'] as num?)?.toDouble() ?? 70.0,
      attention: (json['attention'] as num?)?.toDouble() ?? 70.0,
      engagement: (json['engagement'] as num?)?.toDouble() ?? 70.0,
    );
  }
}

class CognitiveAnalyticsData {
  final String patientId;
  final String patientName;
  final String riskLevel;
  final double currentMemory;
  final double currentAttention;
  final double currentEngagement;
  final List<TrendPoint> trend;

  CognitiveAnalyticsData({
    required this.patientId,
    required this.patientName,
    required this.riskLevel,
    required this.currentMemory,
    required this.currentAttention,
    required this.currentEngagement,
    required this.trend,
  });

  factory CognitiveAnalyticsData.fromJson(Map<String, dynamic> json) {
    final list = (json['trend'] as List<dynamic>?) ?? [];
    return CognitiveAnalyticsData(
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      riskLevel: json['risk_level'] ?? 'STABLE',
      currentMemory: (json['current_memory'] as num?)?.toDouble() ?? 70.0,
      currentAttention: (json['current_attention'] as num?)?.toDouble() ?? 70.0,
      currentEngagement: (json['current_engagement'] as num?)?.toDouble() ?? 70.0,
      trend: list.map((item) => TrendPoint.fromJson(item)).toList(),
    );
  }
}

class GameActivityItem {
  final String id;
  final String gameType;
  final String gameName;
  final int score;
  final int mistakes;
  final double? reactionTimeSeconds;
  final String? playedAt;

  GameActivityItem({
    required this.id,
    required this.gameType,
    required this.gameName,
    required this.score,
    required this.mistakes,
    this.reactionTimeSeconds,
    this.playedAt,
  });

  factory GameActivityItem.fromJson(Map<String, dynamic> json) {
    return GameActivityItem(
      id: json['id'] ?? '',
      gameType: json['game_type'] ?? '',
      gameName: json['game_name'] ?? 'Calibration Game',
      score: json['score'] ?? 0,
      mistakes: json['mistakes'] ?? 0,
      reactionTimeSeconds: (json['reaction_time_seconds'] as num?)?.toDouble(),
      playedAt: json['played_at'],
    );
  }
}

class DailyCheckinSummary {
  final String? mood;
  final double? sleepHours;
  final List<String> symptoms;
  final String? notes;
  final String? recordedAt;

  DailyCheckinSummary({
    this.mood,
    this.sleepHours,
    this.symptoms = const [],
    this.notes,
    this.recordedAt,
  });

  factory DailyCheckinSummary.fromJson(Map<String, dynamic> json) {
    final sym = (json['symptoms'] as List<dynamic>?) ?? [];
    return DailyCheckinSummary(
      mood: json['mood'],
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      symptoms: sym.map((e) => e.toString()).toList(),
      notes: json['notes'],
      recordedAt: json['recorded_at'],
    );
  }
}

class DailyActivityFeed {
  final String date;
  final List<GameActivityItem> games;
  final DailyCheckinSummary? checkin;

  DailyActivityFeed({
    required this.date,
    required this.games,
    this.checkin,
  });

  factory DailyActivityFeed.fromJson(Map<String, dynamic> json) {
    final gamesList = (json['games'] as List<dynamic>?) ?? [];
    return DailyActivityFeed(
      date: json['date'] ?? '',
      games: gamesList.map((g) => GameActivityItem.fromJson(g)).toList(),
      checkin: json['checkin'] != null ? DailyCheckinSummary.fromJson(json['checkin']) : null,
    );
  }
}

class CaregiverAlert {
  final String id;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final bool isAcknowledged;
  final String? createdAt;

  CaregiverAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.isAcknowledged,
    this.createdAt,
  });

  CaregiverAlert copyWith({bool? isAcknowledged}) {
    return CaregiverAlert(
      id: id,
      alertType: alertType,
      severity: severity,
      title: title,
      message: message,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      createdAt: createdAt,
    );
  }

  factory CaregiverAlert.fromJson(Map<String, dynamic> json) {
    return CaregiverAlert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? 'GENERAL',
      severity: json['severity'] ?? 'INFO',
      title: json['title'] ?? 'Care Alert',
      message: json['message'] ?? '',
      isAcknowledged: json['is_acknowledged'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class ReminiscenceVaultItem {
  final String id;
  final String patientId;
  final String title;
  final String? caption;
  final String mediaType;
  final String? mediaUrl;
  final String relationshipTag;
  final String? createdAt;

  ReminiscenceVaultItem({
    required this.id,
    required this.patientId,
    required this.title,
    this.caption,
    required this.mediaType,
    this.mediaUrl,
    required this.relationshipTag,
    this.createdAt,
  });

  factory ReminiscenceVaultItem.fromJson(Map<String, dynamic> json) {
    return ReminiscenceVaultItem(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      title: json['title'] ?? 'Family Memory',
      caption: json['caption'],
      mediaType: json['media_type'] ?? 'PHOTO',
      mediaUrl: json['media_url'],
      relationshipTag: json['relationship_tag'] ?? 'Family',
      createdAt: json['created_at'],
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
      final Map<String, dynamic> map = {'relationship': relationship};
      if (patientId != null) map['patient_id'] = patientId;
      if (patientEmail != null) map['patient_email'] = patientEmail;
      final body = jsonEncode(map);
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

  Future<CognitiveAnalyticsData?> fetchAnalytics(String patientId, {int days = 14}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverAnalytics(patientId, days: days)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return CognitiveAnalyticsData.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<DailyActivityFeed?> fetchActivityFeed(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverActivityFeed(patientId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return DailyActivityFeed.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<List<CaregiverAlert>> fetchAlerts(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverAlerts(patientId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((a) => CaregiverAlert.fromJson(a)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.caregiverAcknowledgeAlert(alertId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<ReminiscenceVaultItem>> fetchReminiscences(String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.caregiverReminiscences(patientId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((r) => ReminiscenceVaultItem.fromJson(r)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<ReminiscenceVaultItem?> createReminiscence({
    required String patientId,
    required String title,
    String? caption,
    String mediaType = 'PHOTO',
    String? mediaUrl,
    String? relationshipTag,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'caption': caption,
        'media_type': mediaType,
        'media_url': mediaUrl,
        'relationship_tag': relationshipTag ?? 'Family',
      });
      final response = await http.post(
        Uri.parse(ApiEndpoints.caregiverReminiscences(patientId)),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        return ReminiscenceVaultItem.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteReminiscence(String memoryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(ApiEndpoints.caregiverDeleteReminiscence(memoryId)),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
