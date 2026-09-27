import 'package:home_widget/home_widget.dart';

import '../features/context/caregiver_context.dart';
import 'widget_service.dart';

final HaniHomeWidgetService homeWidgetServiceInstance =
    _MobileHomeWidgetService();

class _MobileHomeWidgetService implements HaniHomeWidgetService {
  @override
  Future<void> sync(CaregiverContext context) async {
    final nextMedication = _nextMedication(context);
    final nextAppointment = context.appointments
        .where((a) => a['scheduled_for'] != null)
        .toList()
      ..sort((a, b) => (a['scheduled_for']?.toString() ?? '')
          .compareTo(b['scheduled_for']?.toString() ?? ''));

    await HomeWidget.saveWidgetData<String>(
      'patient_name',
      context.patientName,
    );
    await HomeWidget.saveWidgetData<String>(
      'next_medication',
      nextMedication.isEmpty
          ? 'No medication due'
          : [
              nextMedication['medication_name']?.toString() ?? 'Medication',
              nextMedication['dose_text']?.toString(),
              nextMedication['_next_time']?.toString(),
            ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
    );
    await HomeWidget.saveWidgetData<String>(
      'next_appointment',
      nextAppointment.isEmpty
          ? 'No upcoming appointment'
          : [
              nextAppointment.first['reason']?.toString() ?? 'Appointment',
              nextAppointment.first['scheduled_for']?.toString(),
            ].whereType<String>().join(' · '),
    );
    await HomeWidget.saveWidgetData<int>(
      'open_tasks',
      context.openTasks.length,
    );
    await HomeWidget.saveWidgetData<String>(
      'care_status',
      context.followUp == null
          ? 'Care plan up to date'
          : context.followUp!['title']?.toString() ?? 'Follow-up available',
    );

    await HomeWidget.updateWidget(
      name: 'HaniMaakWidgetProvider',
      androidName: 'HaniMaakWidgetProvider',
    );
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

      final days = (schedule['days_of_week'] as List? ?? const [1,2,3,4,5,6,7])
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
                  '\${candidate.hour.toString().padLeft(2, '0')}:\${candidate.minute.toString().padLeft(2, '0')}',
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
