import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'reminders_channel',
        'Reminders',
        description: 'Notifications for your reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  // Schedule a reminder notification
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String description,
    required DateTime scheduledTime,
  }) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('Cannot schedule notification in the past');
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        description,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reminder_$id',
      );

      debugPrint('Scheduled: $id for $scheduledTime');
    } catch (e) {
      debugPrint('Schedule error: $e');
    }
  }

  // Show immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
      );

      debugPrint('Immediate notification shown');
    } catch (e) {
      debugPrint('Immediate error: $e');
    }
  }

  // Cancel a reminder
  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint('Cancelled reminder: $id');
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}