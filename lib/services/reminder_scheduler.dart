import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import '../constants/storage_keys.dart';

class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();
  Timer? _checkTimer;

  // Start periodic check for reminders (every minute)
  void startScheduler() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndScheduleReminders();
    });
    debugPrint('Reminder scheduler started');
  }

  void stopScheduler() {
    _checkTimer?.cancel();
    _checkTimer = null;
    debugPrint('Reminder scheduler stopped');
  }

  Future<void> _checkAndScheduleReminders() async {
    try {
      final remindersData = await _storage.read(key: StorageKeys.patientReminders);
      if (remindersData == null) return;

      final List<dynamic> reminders = jsonDecode(remindersData);
      final now = DateTime.now();

      for (var reminder in reminders) {
        // Parse reminder time (assuming format like "08:00 AM")
        final timeStr = reminder['time'] as String? ?? '';
        if (timeStr.isEmpty) continue;

        try {
          final reminderTime = _parseTimeString(timeStr, now);

          // Schedule if it's within the next 5 minutes and not completed
          if (reminderTime.isAfter(now) &&
              reminderTime.difference(now).inMinutes <= 5 &&
              reminderTime.difference(now).inMinutes >= 0 &&
              !(reminder['isCompleted'] ?? false)) {

            await _notificationService.scheduleReminder(
              id: int.parse(reminder['id'] ?? '0'),
              title: reminder['title'] ?? 'Reminder',
              description: reminder['description'] ?? '',
              scheduledTime: reminderTime,
            );

            debugPrint('Scheduled reminder: ${reminder['title']} at $reminderTime');
          }
        } catch (e) {
          debugPrint('Error parsing reminder time: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  DateTime _parseTimeString(String timeStr, DateTime now) {
    // Parse "08:00 AM" format
    final parts = timeStr.split(' ');
    if (parts.length != 2) return now;

    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return now;

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // Adjust for PM
    if (parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> rescheduleAllReminders() async {
    // Cancel all pending notifications first
    final pending = await _notificationService.getPendingReminders();
    for (var request in pending) {
      await _notificationService.cancelReminder(request.id);
    }

    // Reschedule
    await _checkAndScheduleReminders();
  }
}