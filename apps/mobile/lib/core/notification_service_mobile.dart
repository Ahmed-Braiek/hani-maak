import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/context/caregiver_context.dart';
import 'notification_service.dart';

final HaniNotificationService notificationServiceInstance =
    _MobileNotificationService();

class _MobileNotificationService implements HaniNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  void Function(String route)? routeHandler;

  static const _careChannel = AndroidNotificationChannel(
    'hani_care',
    'Hani Maak care reminders',
    description: 'Medication, appointments, caregiver and follow-up reminders.',
    importance: Importance.high,
  );

  static const _summaryChannel = AndroidNotificationChannel(
    'hani_summary',
    'Hani Maak summaries',
    description: 'Daily and weekly caregiver summaries.',
    importance: Importance.defaultImportance,
  );

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          routeHandler?.call(payload);
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_careChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);
  }

  @override
  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  NotificationDetails _details({
    bool summary = false,
  }) {
    final channel = summary ? _summaryChannel : _careChannel;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  int _id(String value) => value.codeUnits.fold<int>(
        17,
        (hash, code) => ((hash * 31) + code) & 0x7fffffff,
      );

  @override
  Future<void> sync(CaregiverContext context) async {
    await requestPermissions();

    for (final schedule in context.medicationSchedules) {
      if (schedule['active'] != true) continue;
      final medicationId = schedule['patient_medication_id']?.toString();
      final medication = context.medications.firstWhere(
        (m) => m['id']?.toString() == medicationId,
        orElse: () => const <String, dynamic>{},
      );
      final name =
          medication['medication_name']?.toString() ?? 'Medication';
      final dose = medication['dose_text']?.toString() ?? '';
      final times = (schedule['times'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
      final days = (schedule['days_of_week'] as List? ?? const [1,2,3,4,5,6,7])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e >= 1 && e <= 7)
          .toSet();
      final before =
          int.tryParse(schedule['reminder_minutes_before']?.toString() ?? '') ??
              0;

      for (var offset = 0; offset < 8; offset++) {
        final day = tz.TZDateTime.now(tz.local).add(Duration(days: offset));
        if (!days.contains(day.weekday)) continue;
        for (final time in times) {
          final parts = time.split(':');
          if (parts.length < 2) continue;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;
          final when = tz.TZDateTime(
            tz.local,
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          ).subtract(Duration(minutes: before));
          if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
          final key =
              '${schedule['id']}-$offset-$hour-$minute';
          await _plugin.zonedSchedule(
            _id(key),
            'Medication reminder',
            dose.isEmpty ? name : '$name · $dose',
            when,
            _details(),
            payload: '/medications',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }

    for (final appointment in context.appointments) {
      final raw = appointment['scheduled_for']?.toString();
      final scheduled = raw == null ? null : DateTime.tryParse(raw);
      if (scheduled == null) continue;
      final when = tz.TZDateTime.from(
        scheduled.toLocal().subtract(const Duration(hours: 1)),
        tz.local,
      );
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        _id('appointment-${appointment['id']}'),
        'Upcoming appointment',
        appointment['reason']?.toString() ?? 'Care appointment',
        when,
        _details(),
        payload: '/patient',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    for (final notification in context.notifications) {
      final raw = notification['scheduled_for']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) continue;
      final when = tz.TZDateTime.from(date.toLocal(), tz.local);
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      final route = switch (notification['action_type']?.toString()) {
        'open_care_circle' => '/circle',
        'open_patient' => '/patient',
        'open_summary' => '/summary',
        'open_medication' => '/medications',
        _ => '/today',
      };
      await _plugin.zonedSchedule(
        _id('server-${notification['id']}'),
        notification['title']?.toString() ?? 'Hani Maak',
        notification['body']?.toString() ?? '',
        when,
        _details(),
        payload: route,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> showTest() async {
    await _plugin.show(
      777001,
      'Hani Maak is ready',
      'Phone notifications are enabled.',
      _details(),
      payload: '/notifications',
    );
  }
}
