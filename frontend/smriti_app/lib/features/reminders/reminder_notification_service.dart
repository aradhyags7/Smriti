import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_model.dart';

/// Contract for offline reminder notification scheduling in Smriti.
abstract class IReminderNotificationService {
  /// Initializes the local notification plugin, timezone database, and notification channels.
  Future<bool> initialize();

  /// Schedules or updates a local notification for the given [reminder].
  ///
  /// Returns `true` if a notification was scheduled, `false` if skipped (e.g. disabled or past one-time).
  Future<bool> scheduleReminder(ReminderModel reminder);

  /// Cancels the scheduled notification associated with [reminderId].
  Future<void> cancelReminder(String reminderId);

  /// Cancels all scheduled reminder notifications.
  Future<void> cancelAllReminders();

  /// Cancels and re-evaluates scheduling for the given [reminder].
  Future<bool> rescheduleReminder(ReminderModel reminder);
}

/// Parameters recorded when a notification is scheduled via [INotificationScheduler].
@immutable
class ScheduledNotificationRecord {
  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final AndroidScheduleMode androidScheduleMode;
  final UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;

  const ScheduledNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.androidScheduleMode,
    required this.uiLocalNotificationDateInterpretation,
    this.matchDateTimeComponents,
    this.payload,
  });
}

/// Abstract adapter interface wrapping [FlutterLocalNotificationsPlugin] for testability.
abstract class INotificationScheduler {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  });

  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<bool?> requestAndroidPermission();
}

/// Default implementation delegating to [FlutterLocalNotificationsPlugin].
class DefaultNotificationScheduler implements INotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;

  DefaultNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) {
    return _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<bool?> requestAndroidPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return null;
    return await androidImpl.requestNotificationsPermission();
  }
}

/// Dedicated service responsible ONLY for local notification scheduling and cancellation.
class ReminderNotificationService implements IReminderNotificationService {
  /// Dedicated Android notification channel ID for all patient reminders.
  static const String channelId = 'smriti_reminders';
  static const String channelName = 'Smriti Reminders';
  static const String channelDescription =
      'Notifications for patient daily routines and medication reminders';

  static const String defaultNotificationBody = 'You have a reminder.';

  final INotificationScheduler _scheduler;
  final DateTime Function() _clock;
  tz.Location? _location;
  bool _isInitialized = false;

  ReminderNotificationService({
    INotificationScheduler? scheduler,
    DateTime Function()? clock,
    tz.Location? location,
  })  : _scheduler = scheduler ?? DefaultNotificationScheduler(),
        _clock = clock ?? DateTime.now,
        _location = location;

  bool get isInitialized => _isInitialized;

  /// Generates a deterministic, positive 31-bit integer notification ID from a string ID.
  static int deterministicNotificationId(String reminderId) {
    if (reminderId.isEmpty) return 0;
    var hash = 0;
    for (var i = 0; i < reminderId.length; i++) {
      hash = (hash * 31 + reminderId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 1. Initialize timezone database
      try {
        tz.initializeTimeZones();
        _location ??= tz.local;
      } catch (e) {
        debugPrint('ReminderNotificationService: Timezone init note: $e');
        _location ??= tz.UTC;
      }

      // 2. Configure Android & iOS notification settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      final success = await _scheduler.initialize(initSettings);

      // 3. Request Android 13+ runtime permissions if available (graceful fallback)
      try {
        await _scheduler.requestAndroidPermission();
      } catch (e) {
        debugPrint('ReminderNotificationService: Notification permission request non-fatal: $e');
      }

      _isInitialized = success ?? true;
      return _isInitialized;
    } catch (e, stackTrace) {
      debugPrint('ReminderNotificationService: Initialization failed: $e\n$stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  NotificationDetails _buildNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  @override
  Future<bool> scheduleReminder(ReminderModel reminder) async {
    final notifId = deterministicNotificationId(reminder.id);

    // 1. If reminder is disabled, cancel any existing scheduled notification and return false
    if (!reminder.isEnabled) {
      await cancelReminder(reminder.id);
      return false;
    }

    if (!_isInitialized) {
      final initSuccess = await initialize();
      if (!initSuccess) {
        debugPrint('ReminderNotificationService: Cannot schedule; service uninitialized.');
        return false;
      }
    }

    final now = _clock();
    final location = _location ?? tz.local;
    var scheduledTz = tz.TZDateTime.from(reminder.scheduledAt, location);

    DateTimeComponents? matchComponents;

    switch (reminder.recurrence) {
      case ReminderRecurrence.none:
        // One-time reminder: If in the past, do NOT schedule
        if (scheduledTz.isBefore(tz.TZDateTime.from(now, location))) {
          debugPrint('ReminderNotificationService: Skipping past one-time reminder ${reminder.id}');
          await cancelReminder(reminder.id);
          return false;
        }
        matchComponents = null;
        break;

      case ReminderRecurrence.daily:
        // Daily recurrence: If scheduled time has already passed today, advance to next occurrence
        final nowTz = tz.TZDateTime.from(now, location);
        while (scheduledTz.isBefore(nowTz)) {
          scheduledTz = scheduledTz.add(const Duration(days: 1));
        }
        matchComponents = DateTimeComponents.time;
        break;

      case ReminderRecurrence.weekly:
        // Weekly recurrence: If scheduled time has passed, advance week-by-week
        final nowTz = tz.TZDateTime.from(now, location);
        while (scheduledTz.isBefore(nowTz)) {
          scheduledTz = scheduledTz.add(const Duration(days: 7));
        }
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
    }

    final body = (reminder.description != null && reminder.description!.trim().isNotEmpty)
        ? reminder.description!.trim()
        : defaultNotificationBody;

    try {
      await _scheduler.zonedSchedule(
        notifId,
        reminder.title.trim(),
        body,
        scheduledTz,
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
        payload: reminder.id,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('ReminderNotificationService: Failed to schedule ${reminder.id}: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    if (reminderId.isEmpty) return;
    try {
      final notifId = deterministicNotificationId(reminderId);
      await _scheduler.cancel(notifId);
    } catch (e) {
      debugPrint('ReminderNotificationService: Cancel failed for $reminderId: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _scheduler.cancelAll();
    } catch (e) {
      debugPrint('ReminderNotificationService: CancelAll failed: $e');
    }
  }

  @override
  Future<bool> rescheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder.id);
    return await scheduleReminder(reminder);
  }
}
