import 'package:flutter/services.dart';

import '../features/context/caregiver_context.dart';
import 'notification_service.dart';

final HaniNotificationService notificationServiceInstance =
    _MobileNotificationService();

class _MobileNotificationService implements HaniNotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.hanimaak/native');

  void Function(String route)? _routeHandler;
  String? _pendingLaunchRoute;
  bool _initialized = false;

  @override
  void Function(String route)? get routeHandler => _routeHandler;

  @override
  set routeHandler(void Function(String route)? handler) {
    _routeHandler = handler;
    final pending = _pendingLaunchRoute;
    if (handler != null && pending != null && pending.isNotEmpty) {
      _pendingLaunchRoute = null;
      Future<void>.microtask(() => handler(pending));
    }
  }

  void _dispatchRoute(String? route) {
    if (route == null || route.isEmpty) return;
    final handler = _routeHandler;
    if (handler != null) {
      handler(route);
    } else {
      _pendingLaunchRoute = route;
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationRoute') {
        _dispatchRoute(call.arguments?.toString());
      }
    });

    await _channel.invokeMethod<void>('initializeNotifications');
    final route =
        await _channel.invokeMethod<String>('getInitialNotificationRoute');
    _dispatchRoute(route);
  }

  @override
  Future<void> requestPermissions() async {
    await initialize();
    await _channel.invokeMethod<void>('requestNotificationPermission');
  }

  int _id(String value) => value.codeUnits.fold<int>(
        17,
        (hash, code) => ((hash * 31) + code) & 0x7fffffff,
      );

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String route,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    await _channel.invokeMethod<void>('scheduleNotification', {
      'id': id,
      'title': title,
      'body': body,
      'whenMs': when.millisecondsSinceEpoch,
      'route': route,
    });
  }

  @override
  Future<void> sync(CaregiverContext context) async {
    await initialize();
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
      final days =
          (schedule['days_of_week'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e >= 1 && e <= 7)
              .toSet();
      final before =
          int.tryParse(schedule['reminder_minutes_before']?.toString() ?? '') ??
              0;

      final now = DateTime.now();
      for (var offset = 0; offset < 8; offset++) {
        final day = DateTime(now.year, now.month, now.day)
            .add(Duration(days: offset));
        if (!days.contains(day.weekday)) continue;

        for (final time in times) {
          final parts = time.split(':');
          if (parts.length < 2) continue;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          final when = DateTime(
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          ).subtract(Duration(minutes: before));
          final key = '${schedule['id']}-$offset-$hour-$minute';
          await _schedule(
            id: _id(key),
            title: 'Medication reminder',
            body: dose.isEmpty ? name : '$name · $dose',
            when: when,
            route: '/medications',
          );
        }
      }
    }

    for (final appointment in context.appointments) {
      final raw = appointment['scheduled_for']?.toString();
      final scheduled = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
      if (scheduled == null) continue;
      await _schedule(
        id: _id('appointment-${appointment['id']}'),
        title: 'Upcoming appointment',
        body: appointment['reason']?.toString() ?? 'Care appointment',
        when: scheduled.subtract(const Duration(hours: 1)),
        route: '/patient',
      );
    }

    for (final notification in context.notifications) {
      final raw = notification['scheduled_for']?.toString();
      final date = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
      if (date == null) continue;
      final route = switch (notification['action_type']?.toString()) {
        'open_care_circle' => '/circle',
        'open_patient' => '/patient',
        'open_summary' => '/summary',
        'open_medication' => '/medications',
        'open_care_hub' => '/care-hub',
        _ => '/today',
      };
      await _schedule(
        id: _id('server-${notification['id']}'),
        title: notification['title']?.toString() ?? 'Hani Maak',
        body: notification['body']?.toString() ?? '',
        when: date,
        route: route,
      );
    }
  }

  @override
  Future<void> showTest() async {
    await initialize();
    await requestPermissions();
    await _channel.invokeMethod<void>('showTestNotification', {
      'title': 'Hani Maak is ready',
      'body': 'Phone notifications are enabled.',
      'route': '/notifications',
    });
  }
}
