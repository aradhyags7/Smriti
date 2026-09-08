import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Offline-first local persistence service for reminders using [SharedPreferences].
///
/// Designed to be fully isolated from UI widgets, BuildContext, network APIs,
/// and notification schedulers. Safely handles missing, empty, or corrupted storage.
class ReminderService implements IReminderService {
  /// SharedPreferences key for storing serialized reminders.
  static const String storageKey = 'smriti_offline_reminders_v1';

  final SharedPreferences? _injectedPrefs;
  final Future<SharedPreferences> Function()? _prefsProvider;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  ReminderService({
    SharedPreferences? prefs,
    Future<SharedPreferences> Function()? prefsProvider,
  })  : _injectedPrefs = prefs,
        _prefsProvider = prefsProvider;

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

  /// Internal helper to load and parse reminders safely from storage.
  Future<Map<String, ReminderModel>> _loadRemindersMap() async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return {};
    }

    final rawJson = prefs.getString(storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return {};
    }

    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        debugPrint('ReminderService: Stored JSON is not a List. Discarding invalid payload.');
        return {};
      }

      final Map<String, ReminderModel> map = {};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final reminder = ReminderModel.fromJson(item);
            map[reminder.id] = reminder;
          } catch (e) {
            debugPrint('ReminderService: Skipped malformed reminder item: $e');
          }
        } else if (item is Map) {
          try {
            final converted = item.map((k, v) => MapEntry(k.toString(), v));
            final reminder = ReminderModel.fromJson(converted);
            map[reminder.id] = reminder;
          } catch (e) {
            debugPrint('ReminderService: Skipped malformed reminder item: $e');
          }
        }
      }
      return map;
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
    if (!map.containsKey(id.trim())) {
      return false;
    }
    map.remove(id.trim());
    return await _saveRemindersMap(map);
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
    return await _saveRemindersMap(map);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(storageKey);
    }
  }
}
