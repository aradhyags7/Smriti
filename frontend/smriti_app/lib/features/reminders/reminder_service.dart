import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'reminder_model.dart';

class ReminderService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReminderItem>> fetchReminders({String? patientId}) async {
    try {
      String url = ApiEndpoints.reminders;
      if (patientId != null && patientId.isNotEmpty) {
        url = '$url?patient_id=$patientId';
      }
      final response = await _apiClient.get(url, requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => ReminderItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ReminderItem?> createReminder({
    required String title,
    required String scheduledTime,
    String reminderType = 'MEDICINE',
    String frequency = 'DAILY',
    String? patientId,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title.trim(),
        'scheduled_time': scheduledTime.trim(),
        'reminder_type': reminderType,
        'frequency': frequency,
      };
      if (patientId != null && patientId.isNotEmpty) {
        body['patient_id'] = patientId;
      }

      final response = await _apiClient.post(
        ApiEndpoints.reminders,
        body: body,
        requireAuth: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ReminderItem.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleAcknowledge(String reminderId) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.reminderAcknowledge(reminderId),
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteReminder(String reminderId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.reminderDetail(reminderId),
        requireAuth: true,
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
