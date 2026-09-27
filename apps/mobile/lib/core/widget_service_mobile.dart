import 'package:flutter/services.dart';

import '../features/context/caregiver_context.dart';
import 'settings/app_settings.dart';
import 'widget_service.dart';

final HaniHomeWidgetService homeWidgetServiceInstance =
    _MobileHomeWidgetService();

class _MobileHomeWidgetService implements HaniHomeWidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.hanimaak/native');

  @override
  Future<void> sync(CaregiverContext context, HaniLanguage language) async {
    final nextMedication = _nextMedication(context);
    final nextAppointment = context.appointments
        .where((a) => a['scheduled_for'] != null)
        .toList()
      ..sort((a, b) => (a['scheduled_for']?.toString() ?? '')
          .compareTo(b['scheduled_for']?.toString() ?? ''));

    final medicationText = nextMedication.isEmpty
        ? haniText(
            language,
            tn: 'ما فماش دواء قريب',
            ar: 'لا يوجد دواء قريب',
            en: 'No medication due',
            fr: 'Aucun médicament prévu',
          )
        : [
            nextMedication['medication_name']?.toString() ??
                haniText(
                  language,
                  tn: 'دواء',
                  ar: 'دواء',
                  en: 'Medication',
                  fr: 'Médicament',
                ),
            nextMedication['dose_text']?.toString(),
            nextMedication['_next_time']?.toString(),
          ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

    final appointmentText = nextAppointment.isEmpty
        ? haniText(
            language,
            tn: 'ما فماش موعد قريب',
            ar: 'لا يوجد موعد قريب',
            en: 'No upcoming appointment',
            fr: 'Aucun rendez-vous à venir',
          )
        : [
            nextAppointment.first['reason']?.toString() ??
                haniText(
                  language,
                  tn: 'موعد',
                  ar: 'موعد',
                  en: 'Appointment',
                  fr: 'Rendez-vous',
                ),
            nextAppointment.first['scheduled_for']?.toString(),
          ].whereType<String>().join(' · ');

    await _channel.invokeMethod<void>('updateWidget', {
      'patientName': context.patientName,
      'nextMedication': medicationText,
      'nextAppointment': appointmentText,
      'openTasks': context.openTasks.length,
      'careStatus': context.followUp == null
          ? haniText(
              language,
              tn: 'الرعاية محدثة',
              ar: 'خطة الرعاية محدثة',
              en: 'Care plan up to date',
              fr: 'Plan de soins à jour',
            )
          : context.followUp!['title']?.toString() ??
              haniText(
                language,
                tn: 'فما متابعة',
                ar: 'توجد متابعة',
                en: 'Follow-up available',
                fr: 'Suivi disponible',
              ),
      'language': language.code,
      'tasksLabel': haniText(
        language,
        tn: 'مهام',
        ar: 'مهام',
        en: 'tasks',
        fr: 'tâches',
      ),
      'callLabel': haniText(
        language,
        tn: 'احكي مع هاني',
        ar: 'اتصل بهاني',
        en: 'Call Hani',
        fr: 'Appeler Hani',
      ),
    });
  }

  @override
  Future<bool> requestPin() async {
    final result = await _channel.invokeMethod<bool>('requestPinWidget');
    return result ?? false;
  }

  Map<String, dynamic> _nextMedication(CaregiverContext context) {
    final now = DateTime.now();
    Map<String, dynamic>? best;
    DateTime? bestAt;

    for (final schedule in context.medicationSchedules) {
      if (schedule['active'] != true) continue;
      final medicationId = schedule['patient_medication_id']?.toString();
      final medication = context.medications.firstWhere(
        (item) => item['id']?.toString() == medicationId,
        orElse: () => const <String, dynamic>{},
      );
      if (medication.isEmpty) continue;

      final days =
          (schedule['days_of_week'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])
              .map((value) => int.tryParse(value.toString()) ?? 0)
              .where((value) => value >= 1 && value <= 7)
              .toSet();
      final times = (schedule['times'] as List? ?? const [])
          .map((value) => value.toString())
          .toList();

      for (var offset = 0; offset < 8; offset++) {
        final day = DateTime(now.year, now.month, now.day)
            .add(Duration(days: offset));
        if (!days.contains(day.weekday)) continue;

        for (final raw in times) {
          final parts = raw.split(':');
          if (parts.length < 2) continue;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          final candidate = DateTime(
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          );
          if (!candidate.isAfter(now)) continue;
          if (bestAt == null || candidate.isBefore(bestAt)) {
            bestAt = candidate;
            best = {
              ...medication,
              '_next_time':
                  "${candidate.hour.toString().padLeft(2, '0')}:${candidate.minute.toString().padLeft(2, '0')}",
            };
          }
        }
      }
    }

    return best ??
        (context.medications.isNotEmpty
            ? Map<String, dynamic>.from(context.medications.first)
            : <String, dynamic>{});
  }
}
