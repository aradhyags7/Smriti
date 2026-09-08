import 'package:flutter/foundation.dart';

/// Recurrence interval for scheduled reminders.
enum ReminderRecurrence {
  none,
  daily,
  weekly;

  /// Serializes the recurrence enum to a standard string.
  String toJson() => name;

  /// Deserializes a string into [ReminderRecurrence] with safe fallback.
  static ReminderRecurrence fromJson(String? value) {
    if (value == null) return ReminderRecurrence.none;
    return ReminderRecurrence.values.firstWhere(
      (e) => e.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => ReminderRecurrence.none,
    );
  }
}

/// Immutable domain model representing an offline reminder in Smriti.
@immutable
class ReminderModel {
  /// Unique identifier for the reminder.
  final String id;

  /// User-visible title/content of the reminder (e.g., "Take morning blood pressure medication").
  final String title;

  /// Optional extended description or instructions.
  final String? description;

  /// Date and time when the reminder is scheduled to trigger.
  final DateTime scheduledAt;

  /// Repetition cadence (none, daily, weekly).
  final ReminderRecurrence recurrence;

  /// Whether the reminder is active and eligible to be triggered.
  final bool isEnabled;

  /// Timestamp when the reminder was created.
  final DateTime createdAt;

  /// Timestamp when the patient or caregiver acknowledged/dismissed the reminder.
  final DateTime? acknowledgedAt;

  /// Timestamp when the reminder was last triggered/fired.
  final DateTime? lastTriggeredAt;

  const ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.recurrence = ReminderRecurrence.none,
    this.isEnabled = true,
    required this.createdAt,
    this.acknowledgedAt,
    this.lastTriggeredAt,
  });

  /// Creates a copy of this reminder with the given fields replaced by new values.
  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledAt,
    ReminderRecurrence? recurrence,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? lastTriggeredAt,
    bool clearDescription = false,
    bool clearAcknowledgedAt = false,
    bool clearLastTriggeredAt = false,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      recurrence: recurrence ?? this.recurrence,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: clearAcknowledgedAt ? null : (acknowledgedAt ?? this.acknowledgedAt),
      lastTriggeredAt: clearLastTriggeredAt ? null : (lastTriggeredAt ?? this.lastTriggeredAt),
    );
  }

  /// Serializes the model to a JSON map with deterministic ISO-8601 date strings.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'recurrence': recurrence.toJson(),
      'isEnabled': isEnabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (acknowledgedAt != null) 'acknowledgedAt': acknowledgedAt!.toUtc().toIso8601String(),
      if (lastTriggeredAt != null) 'lastTriggeredAt': lastTriggeredAt!.toUtc().toIso8601String(),
    };
  }

  /// Deserializes a JSON map into a [ReminderModel].
  ///
  /// Throws [FormatException] if mandatory fields ('id', 'title', 'scheduledAt', 'createdAt')
  /// are missing or invalid.
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null || id is! String || id.trim().isEmpty) {
      throw const FormatException("Missing or invalid 'id' in Reminder JSON.");
    }

    final title = json['title'];
    if (title == null || title is! String || title.trim().isEmpty) {
      throw const FormatException("Missing or invalid 'title' in Reminder JSON.");
    }

    final scheduledAtStr = json['scheduledAt'];
    if (scheduledAtStr == null || scheduledAtStr is! String) {
      throw const FormatException("Missing or invalid 'scheduledAt' in Reminder JSON.");
    }
    final scheduledAt = DateTime.parse(scheduledAtStr);

    final createdAtStr = json['createdAt'];
    if (createdAtStr == null || createdAtStr is! String) {
      throw const FormatException("Missing or invalid 'createdAt' in Reminder JSON.");
    }
    final createdAt = DateTime.parse(createdAtStr);

    final recurrenceStr = json['recurrence'] as String?;
    final recurrence = ReminderRecurrence.fromJson(recurrenceStr);

    final isEnabled = (json['isEnabled'] as bool?) ?? true;
    final description = json['description'] as String?;

    final acknowledgedAtStr = json['acknowledgedAt'] as String?;
    final acknowledgedAt = acknowledgedAtStr != null ? DateTime.parse(acknowledgedAtStr) : null;

    final lastTriggeredAtStr = json['lastTriggeredAt'] as String?;
    final lastTriggeredAt = lastTriggeredAtStr != null ? DateTime.parse(lastTriggeredAtStr) : null;

    return ReminderModel(
      id: id.trim(),
      title: title.trim(),
      description: description?.trim(),
      scheduledAt: scheduledAt,
      recurrence: recurrence,
      isEnabled: isEnabled,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt,
      lastTriggeredAt: lastTriggeredAt,
    );
  }

  /// Converts this [ReminderModel] into a [ReminderItem] for remote API sync.
  ReminderItem toReminderItem({String patientId = 'default_patient'}) {
    return ReminderItem(
      id: id,
      patientId: patientId,
      title: title,
      reminderType: 'MEDICINE',
      scheduledTime: scheduledAt.toIso8601String(),
      frequency: recurrence == ReminderRecurrence.daily
          ? 'DAILY'
          : recurrence == ReminderRecurrence.weekly
              ? 'WEEKLY'
              : 'ONCE',
      isAcknowledged: !isEnabled,
      syncStatus: 'SYNCED',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          scheduledAt == other.scheduledAt &&
          recurrence == other.recurrence &&
          isEnabled == other.isEnabled &&
          createdAt == other.createdAt &&
          acknowledgedAt == other.acknowledgedAt &&
          lastTriggeredAt == other.lastTriggeredAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        scheduledAt,
        recurrence,
        isEnabled,
        createdAt,
        acknowledgedAt,
        lastTriggeredAt,
      );

  @override
  String toString() {
    return 'ReminderModel('
        'id: $id, '
        'title: "$title", '
        'scheduledAt: $scheduledAt, '
        'recurrence: ${recurrence.name}, '
        'isEnabled: $isEnabled, '
        'createdAt: $createdAt, '
        'acknowledgedAt: $acknowledgedAt, '
        'lastTriggeredAt: $lastTriggeredAt'
        ')';
  }
}

/// Remote API reminder model representing items fetched from or sent to backend.
class ReminderItem {
  final String id;
  final String patientId;
  final String title;
  final String reminderType;
  final String scheduledTime;
  final String frequency;
  final bool isAcknowledged;
  final String syncStatus;

  ReminderItem({
    required this.id,
    required this.patientId,
    required this.title,
    required this.reminderType,
    required this.scheduledTime,
    required this.frequency,
    required this.isAcknowledged,
    required this.syncStatus,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      reminderType: json['reminder_type'] as String? ?? 'MEDICINE',
      scheduledTime: json['scheduled_time'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'DAILY',
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'reminder_type': reminderType,
      'scheduled_time': scheduledTime,
      'frequency': frequency,
      'is_acknowledged': isAcknowledged,
      'sync_status': syncStatus,
    };
  }

  ReminderItem copyWith({
    String? id,
    String? patientId,
    String? title,
    String? reminderType,
    String? scheduledTime,
    String? frequency,
    bool? isAcknowledged,
    String? syncStatus,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      reminderType: reminderType ?? this.reminderType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      frequency: frequency ?? this.frequency,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Converts this remote [ReminderItem] into an offline [ReminderModel].
  ReminderModel toReminderModel() {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(scheduledTime);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return ReminderModel(
      id: id,
      title: title,
      scheduledAt: parsedDate,
      recurrence: frequency.toUpperCase() == 'DAILY'
          ? ReminderRecurrence.daily
          : frequency.toUpperCase() == 'WEEKLY'
              ? ReminderRecurrence.weekly
              : ReminderRecurrence.none,
      isEnabled: !isAcknowledged,
      createdAt: DateTime.now(),
    );
  }
}
