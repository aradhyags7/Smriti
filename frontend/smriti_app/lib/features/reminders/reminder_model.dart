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
}
