import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/care/care_workflow_api.dart';
import '../../features/context/caregiver_context.dart';

class DeviceCareServices {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static void Function(String route)? _onRoute;
  static bool _initialized = false;
  static bool _firebaseReady = false;
  static StreamSubscription<RemoteMessage>? _messageSub;
  static StreamSubscription<RemoteMessage>? _openSub;

  static const _firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const _firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID');
  static const _firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _firebaseSenderId =
      String.fromEnvironment('FIREBASE_SENDER_ID');

  static bool get _hasFirebaseConfig =>
      _firebaseApiKey.isNotEmpty &&
      _firebaseAppId.isNotEmpty &&
      _firebaseProjectId.isNotEmpty &&
      _firebaseSenderId.isNotEmpty;

  static Future<void> initialize({
    required void Function(String route) onRoute,
  }) async {
    if (_initialized) {
      _onRoute = onRoute;
      return;
    }
    _onRoute = onRoute;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) {
          _onRoute?.call(route);
        }
      },
    );

    await requestPermissions();
    await _initializePush();

    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      final route = uri?.queryParameters['route'] ?? uri?.path;
      if (route != null && route.isNotEmpty) {
        scheduleMicrotask(() => _onRoute?.call(route));
      }
      HomeWidget.widgetClicked.listen((uri) {
        final route = uri?.queryParameters['route'] ?? uri?.path;
        if (route != null && route.isNotEmpty) {
          _onRoute?.call(route);
        }
      });
    } catch (_) {}

    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    var granted = true;
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      granted = await android?.requestNotificationsPermission() ?? true;
    } else if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }
    return granted;
  }

  static Future<void> _initializePush() async {
    if (!_hasFirebaseConfig) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _firebaseApiKey,
          appId: _firebaseAppId,
          messagingSenderId: _firebaseSenderId,
          projectId: _firebaseProjectId,
        ),
      );
      _firebaseReady = true;

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await CareWorkflowApi().run(
          'register_device_token',
          args: {
            'token': token,
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'metadata': {'source': 'firebase_messaging'},
          },
          timeout: const Duration(seconds: 15),
        );
      }

      _messageSub = FirebaseMessaging.onMessage.listen((message) {
        final route = message.data['route']?.toString() ?? '/notifications';
        unawaited(
          _showNow(
            title: message.notification?.title ?? 'Hani Maak',
            body: message.notification?.body ?? 'You have a care update.',
            route: route,
          ),
        );
      });
      _openSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _onRoute?.call(message.data['route']?.toString() ?? '/notifications');
      });

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        scheduleMicrotask(
          () => _onRoute?.call(
            initial.data['route']?.toString() ?? '/notifications',
          ),
        );
      }
    } catch (_) {
      _firebaseReady = false;
    }
  }

  static Future<void> sync(CaregiverContext context) async {
    if (!_initialized) return;
    await _syncHomeWidget(context);
    await _syncLocalReminders(context);
  }

  static Future<void> _syncLocalReminders(CaregiverContext context) async {
    for (var id = 40000; id < 40250; id++) {
      await _notifications.cancel(id);
    }

    final medicationById = <String, String>{
      for (final med in context.medications)
        if (med['id'] != null)
          med['id'].toString():
              med['medication_name']?.toString() ?? 'Medication',
    };

    var id = 40000;
    final now = DateTime.now();
    final pending = context.medicationEvents
        .where((event) =>
            event['status'] == 'pending' &&
            DateTime.tryParse(event['scheduled_for']?.toString() ?? '')
                    ?.isAfter(now) ==
                true)
        .take(80);

    for (final event in pending) {
      final when = DateTime.tryParse(event['scheduled_for']?.toString() ?? '');
      if (when == null) continue;
      final name = medicationById[event['patient_medication_id']?.toString()] ??
          'Medication';
      await _schedule(
        id: id++,
        when: when,
        title: 'Medication reminder',
        body: name,
        route: '/medications',
        channelId: 'hani_medication',
        channelName: 'Medication reminders',
      );
    }

    final appointments = context.appointments
        .where((item) =>
            DateTime.tryParse(item['scheduled_for']?.toString() ?? '')
                    ?.isAfter(now) ==
                true)
        .take(20);

    for (final appointment in appointments) {
      final at =
          DateTime.tryParse(appointment['scheduled_for']?.toString() ?? '');
      if (at == null) continue;
      var when = at.subtract(const Duration(hours: 24));
      if (!when.isAfter(now)) {
        when = at.subtract(const Duration(hours: 1));
      }
      if (!when.isAfter(now)) continue;
      await _schedule(
        id: id++,
        when: when,
        title: 'Upcoming appointment',
        body: appointment['reason']?.toString() ?? 'Care appointment',
        route: '/care-hub',
        channelId: 'hani_appointments',
        channelName: 'Appointments',
      );
    }
  }

  static Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String route,
    required String channelId,
    required String channelName,
  }) async {
    final local = tz.TZDateTime.from(when.toLocal(), tz.local);
    if (!local.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      local,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Hani Maak care reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: route,
    );
  }

  static Future<void> _showNow({
    required String title,
    required String body,
    required String route,
  }) async {
    await _notifications.show(
      49001,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hani_care',
          'Hani Maak care updates',
          channelDescription: 'Important care and caregiver updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }

  static Future<void> _syncHomeWidget(CaregiverContext context) async {
    try {
      final now = DateTime.now();
      final medById = <String, String>{
        for (final med in context.medications)
          if (med['id'] != null)
            med['id'].toString():
                med['medication_name']?.toString() ?? 'Medication',
      };

      Map<String, dynamic>? nextMedication;
      for (final event in context.medicationEvents) {
        final at = DateTime.tryParse(event['scheduled_for']?.toString() ?? '');
        if (event['status'] == 'pending' && at != null && at.isAfter(now)) {
          if (nextMedication == null ||
              at.isBefore(
                DateTime.parse(nextMedication['scheduled_for'].toString()),
              )) {
            nextMedication = event;
          }
        }
      }

      Map<String, dynamic>? nextAppointment;
      for (final item in context.appointments) {
        final at = DateTime.tryParse(item['scheduled_for']?.toString() ?? '');
        if (at != null && at.isAfter(now)) {
          if (nextAppointment == null ||
              at.isBefore(
                DateTime.parse(nextAppointment['scheduled_for'].toString()),
              )) {
            nextAppointment = item;
          }
        }
      }

      final medicationLabel = nextMedication == null
          ? 'No medication due'
          : medById[nextMedication['patient_medication_id']?.toString()] ??
              'Medication';
      final medicationTime = nextMedication == null
          ? ''
          : _clock(nextMedication['scheduled_for']?.toString());
      final appointmentLabel = nextAppointment == null
          ? 'No appointment scheduled'
          : nextAppointment['reason']?.toString() ?? 'Appointment';
      final appointmentTime = nextAppointment == null
          ? ''
          : _shortDate(nextAppointment['scheduled_for']?.toString());

      await HomeWidget.saveWidgetData<String>(
        'patient_name',
        context.patientName,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_medication',
        medicationLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_medication_time',
        medicationTime,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_appointment',
        appointmentLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_appointment_time',
        appointmentTime,
      );
      await HomeWidget.saveWidgetData<int>(
        'open_tasks',
        context.openTasks.length,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.hanimaak.hani_maak_mobile.HaniCareWidgetProvider',
      );
    } catch (_) {}
  }

  static String _clock(String? raw) {
    final value = DateTime.tryParse(raw ?? '')?.toLocal();
    if (value == null) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  static String _shortDate(String? raw) {
    final value = DateTime.tryParse(raw ?? '')?.toLocal();
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${_clock(raw)}';
  }

  static Future<bool> requestHomeWidget() async {
    try {
      if (!Platform.isAndroid) return false;
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName:
            'com.hanimaak.hani_maak_mobile.HaniCareWidgetProvider',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool get pushConfigured => _firebaseReady;

  static Future<void> dispose() async {
    await _messageSub?.cancel();
    await _openSub?.cancel();
  }
}
