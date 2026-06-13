import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Service to handle system-level local notifications for workout reminders.
class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();

  /// Initializes the notification settings and prepares the timezone data.
  Future<void> init() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      // In 5.x+, getLocalTimezone returns a TimezoneInfo object with an 'identifier' property.
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Configure Android & iOS settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const settings = InitializationSettings(android: android, iOS: ios);

    // 3. Initialize the plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // App opened from notification
      },
    );

    // 4. Schedule the recurring reminder automatically on init
    await scheduleDailyReminder();
  }

  /// Requests permissions specifically for Android 13+ and iOS.
  Future<void> requestPermissions() async {
    // Android 13+ permission
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // iOS permission
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a daily reminder at 9:00 AM local time.
  Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      1001, // Unique ID for daily reminder
      'Time to Rank Up! ⚔️',
      'Your daily workout is waiting for you. Don\'t break your streak today!',
      _nextInstanceOf9AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Notifications to remind you of your daily workout routine.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Calculates the next instance of 9:00 AM in the local timezone.
  tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    
    // If it's already past 9:00 AM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
