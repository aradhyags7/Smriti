import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'reminder_model.dart';

/// Contract for offline local reminder persistence in Smriti.
abstract class IReminderService {
  /// Initializes the local storage layer and prepares cached reminder data.
  Future<void> initialize();

  /// Creates and stores a new [ReminderModel].
  ///
  /// If a reminder with the same [ReminderModel.id] already exists,
  /// it is safely replaced to prevent duplicate records.
  Future<ReminderModel> createReminder(ReminderModel reminder);

  /// Retrieves a single reminder by its unique [id], or null if not found.
  Future<ReminderModel?> getReminder(String id);

  /// Retrieves all stored reminders, sorted by scheduled time (earliest first).
  Future<List<ReminderModel>> getAllReminders();

  /// Updates an existing reminder.
  ///
  /// Returns `true` if the reminder was found and updated, `false` otherwise.
  Future<bool> updateReminder(ReminderModel reminder);

  /// Deletes a reminder by its [id].
  ///
  /// Returns `true` if the reminder was found and removed, `false` if not found.
  Future<bool> deleteReminder(String id);

  /// Enables a reminder by setting `isEnabled = true`.
  ///
  /// Returns `true` if found and enabled, `false` otherwise.
  Future<bool> enableReminder(String id);

  /// Disables a reminder by setting `isEnabled = false`.
  ///
  /// Returns `true` if found and disabled, `false` otherwise.
  Future<bool> disableReminder(String id);

  /// Marks a reminder as acknowledged with the given timestamp.
  ///
  /// Returns `true` if found and updated, `false` otherwise.
  Future<bool> acknowledgeReminder(String id, {DateTime? acknowledgedAt});

  /// Clears all stored reminders from local storage.
  Future<void> clearAll();
}

/// Hybrid local-offline and cloud-sync persistence service for reminders.
///
/// Implements [IReminderService] using [SharedPreferences] for guaranteed offline
/// alarm notifications, while providing [ApiClient] hooks for the remote backend.
class ReminderService implements IReminderService {
  /// SharedPreferences key for storing serialized reminders.
  static const String storageKey = 'smriti_offline_reminders_v1';

  final SharedPreferences? _injectedPrefs;
  final Future<SharedPreferences> Function()? _prefsProvider;
  final ApiClient _apiClient = ApiClient();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  ReminderService({
    SharedPreferences? prefs,
    this._prefsProvider,
  })  : _injectedPrefs = prefs;

  /// Ensures the service and underlying preferences are loaded.
  @override
  Future<void> initialize() async {
    if (_isInitialized && _prefs != null) return;

    try {
      final provider = _prefsProvider;
      if (_injectedPrefs != null) {
        _prefs = _injectedPrefs;
      } else if (provider != null) {
        _prefs = await provider();
      } else {
        _prefs = await SharedPreferences.getInstance();
      }
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('ReminderService: Failed to initialize SharedPreferences: $e\n$stackTrace');
      _isInitialized = false;
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (!_isInitialized || _prefs == null) {
      await initialize();
    }
    return _prefs;
  }

  /// Internal helper to load and parse the raw JSON map from storage.
  Future<Map<String, ReminderModel>> _loadRemindersMap() async {
    final prefs = await _getPrefs();
    if (prefs == null) return {};

    final rawJson = prefs.getString(storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        debugPrint('ReminderService: Stored JSON is not a List. Discarding invalid payload.');
        return {};
      }

      final Map<String, ReminderModel> result = {};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final reminder = ReminderModel.fromJson(item);
            result[reminder.id] = reminder;
          } catch (e) {
            debugPrint('ReminderService: Skipped malformed reminder item: $e');
          }
        } else if (item is Map) {
          try {
            final converted = Map<String, dynamic>.from(item);
            final reminder = ReminderModel.fromJson(converted);
            result[reminder.id] = reminder;
          } catch (e) {
            debugPrint('ReminderService: Skipped malformed reminder item: $e');
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('ReminderService: Corrupted JSON data in SharedPreferences: $e. Returning empty.');
      return {};
    }
  }

  /// Internal helper to serialize and commit reminders to storage.
  Future<bool> _saveRemindersMap(Map<String, ReminderModel> map) async {
    final prefs = await _getPrefs();
    if (prefs == null) return false;

    try {
      final List<Map<String, dynamic>> serializedList =
          map.values.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(serializedList);
      return await prefs.setString(storageKey, jsonString);
    } catch (e, stackTrace) {
      debugPrint('ReminderService: Failed to save reminders to SharedPreferences: $e\n$stackTrace');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // IReminderService Implementations (Offline First)
  // --------------------------------------------------------------------------

  @override
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    final map = await _loadRemindersMap();
    map[reminder.id] = reminder;
    await _saveRemindersMap(map);
    return reminder;
  }

  @override
  Future<ReminderModel?> getReminder(String id) async {
    if (id.trim().isEmpty) return null;
    final map = await _loadRemindersMap();
    return map[id.trim()];
  }

  @override
  Future<List<ReminderModel>> getAllReminders() async {
    final map = await _loadRemindersMap();
    final list = map.values.toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  @override
  Future<bool> updateReminder(ReminderModel reminder) async {
    final map = await _loadRemindersMap();
    if (!map.containsKey(reminder.id)) {
      return false;
    }
    map[reminder.id] = reminder;
    return await _saveRemindersMap(map);
  }

  @override
  Future<bool> deleteReminder(String id) async {
    if (id.trim().isEmpty) return false;
    final map = await _loadRemindersMap();
    final removed = map.remove(id.trim());
    if (removed != null) {
      await _saveRemindersMap(map);
    }

    // Also attempt remote deletion if network is reachable
    try {
      await _apiClient.delete(
        ApiEndpoints.reminderDetail(id.trim()),
        requireAuth: true,
      );
    } catch (_) {}

    return removed != null;
  }

  @override
  Future<bool> enableReminder(String id) async {
    if (id.trim().isEmpty) return false;
    final map = await _loadRemindersMap();
    final existing = map[id.trim()];
    if (existing == null) {
      return false;
    }
    map[existing.id] = existing.copyWith(isEnabled: true);
    return await _saveRemindersMap(map);
  }

  @override
  Future<bool> disableReminder(String id) async {
    if (id.trim().isEmpty) return false;
    final map = await _loadRemindersMap();
    final existing = map[id.trim()];
    if (existing == null) {
      return false;
    }
    map[existing.id] = existing.copyWith(isEnabled: false);
    return await _saveRemindersMap(map);
  }

  @override
  Future<bool> acknowledgeReminder(String id, {DateTime? acknowledgedAt}) async {
    if (id.trim().isEmpty) return false;
    final map = await _loadRemindersMap();
    final existing = map[id.trim()];
    if (existing == null) {
      return false;
    }
    map[existing.id] = existing.copyWith(
      acknowledgedAt: acknowledgedAt ?? DateTime.now(),
    );
    await _saveRemindersMap(map);

    try {
      await _apiClient.patch(
        ApiEndpoints.reminderAcknowledge(id.trim()),
        requireAuth: true,
      );
    } catch (_) {}

    return true;
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(storageKey);
    }
  }

  // --------------------------------------------------------------------------
  // Remote REST API Compatibility (Patient & Caregiver Portals)
  // --------------------------------------------------------------------------

  /// Fetches reminders from the backend API. If offline or failing, falls back
  /// to locally stored reminders converted to [ReminderItem].
  Future<List<ReminderItem>> fetchReminders({String? patientId}) async {
    try {
      String url = ApiEndpoints.reminders;
      if (patientId != null && patientId.isNotEmpty) {
        url = '$url?patient_id=$patientId';
      }
      final response = await _apiClient.get(url, requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final remoteItems =
            list.map((item) => ReminderItem.fromJson(item as Map<String, dynamic>)).toList();
        if (remoteItems.isNotEmpty) {
          return remoteItems;
        }
      }
    } catch (_) {}

    // Fallback to local offline reminders
    final localModels = await getAllReminders();
    return localModels.map((m) => m.toReminderItem(patientId: patientId ?? 'default_patient')).toList();
  }

  /// Creates a reminder on the remote backend (and caches it locally).
  Future<ReminderItem?> createRemoteReminder({
    required String title,
    required String scheduledTime,
    String reminderType = 'MEDICINE',
    String frequency = 'DAILY',
    String? patientId,
  }) async {
    ReminderItem? remoteItem;
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
        remoteItem = ReminderItem.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}

    // Also persist locally for offline notification triggers
    final localModel = (remoteItem != null)
        ? remoteItem.toReminderModel()
        : ReminderModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title.trim(),
            scheduledAt: DateTime.tryParse(scheduledTime) ?? DateTime.now().add(const Duration(hours: 1)),
            recurrence: frequency.toUpperCase() == 'DAILY'
                ? ReminderRecurrence.daily
                : frequency.toUpperCase() == 'WEEKLY'
                    ? ReminderRecurrence.weekly
                    : ReminderRecurrence.none,
            createdAt: DateTime.now(),
          );
    await createReminder(localModel);

    return remoteItem ?? localModel.toReminderItem(patientId: patientId ?? 'default_patient');
  }

  /// Toggles reminder acknowledgement on remote backend and local cache.
  Future<bool> toggleAcknowledge(String reminderId) async {
    await acknowledgeReminder(reminderId);
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.reminderAcknowledge(reminderId),
        requireAuth: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return true; // Local acknowledgement succeeded
    }
  }
}
