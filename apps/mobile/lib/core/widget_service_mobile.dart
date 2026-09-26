import 'package:home_widget/home_widget.dart';

import '../features/context/caregiver_context.dart';
import 'widget_service.dart';

final HaniHomeWidgetService homeWidgetServiceInstance =
    _MobileHomeWidgetService();

class _MobileHomeWidgetService implements HaniHomeWidgetService {
  @override
  Future<void> sync(CaregiverContext context) async {
    final nextMedication = context.medications.isNotEmpty
        ? context.medications.first
        : const <String, dynamic>{};
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
              nextMedication['schedule_text']?.toString(),
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
}
