import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> save(WidgetRef ref) async {
    final s = ref.read(appSettingsProvider);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'update_notification_preferences',
        args: {
          'enabled': s.notificationsEnabled,
          'incidentFollowup': s.incidentFollowups,
          'wellbeingCheckin': s.wellbeingReminders,
          'careCircleRequests': s.careCircleRequests,
          'appointments': s.appointments,
          'medicationReminders': s.medicationReminders,
          'dailySummaries': s.dailySummaries,
          'importantPatientEvents': s.importantPatientEvents,
          'quietHours': s.quietHours,
          'quietHoursStart': '22:00',
          'quietHoursEnd': '07:00',
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
    } catch (_) {
      // Local UI stays responsive even if a preview backend is unavailable.
    }
  }

  Future<void> openNotification(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final id = item['id']?.toString();
    if (id != null && id.isNotEmpty && !id.startsWith('demo-')) {
      try {
        await ref.read(caregiverContextApiProvider).action(
          'open_notification',
          args: {'notificationId': id},
        );
      } catch (_) {}
    }

    final action = item['action_type']?.toString();
    if (!context.mounted) return;
    if (action == 'open_hani_followup') {
      context.push('/hani');
    } else if (action == 'open_care_circle') {
      context.go('/circle');
    } else if (action == 'open_professional') {
      context.push('/handoff');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final copy = AppCopy(settings.language);
    final arabicScript = settings.language == HaniLanguage.tounsi ||
        settings.language == HaniLanguage.arabic;

    Future<void> update(void Function() change) async {
      change();
      await save(ref);
    }

    return Scaffold(
      appBar: AppBar(title: Text(copy.t('notifications'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          HaniGradientCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: HaniColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.language == HaniLanguage.french
                            ? 'Calmes et utiles'
                            : arabicScript
                                ? 'إشعارات هادئة ومفيدة'
                                : 'Quiet and useful',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.language == HaniLanguage.french
                            ? 'Seulement ce qui change votre prochaine action.'
                            : arabicScript
                                ? 'كان الحاجة اللي تبدّل شنوّة يلزمك تعمل بعد.'
                                : 'Only what can change your next action.',
                        style: const TextStyle(
                          color: HaniColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (v) => update(() => controller.setNotifications(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Suivi des incidents'
                      : arabicScript
                          ? 'متابعة الحوادث'
                          : 'Incident follow-ups',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Hani peut reprendre un événement important plus tard.'
                      : arabicScript
                          ? 'هاني ينجم يرجع معاك للحادثة وقت تكون مستعد.'
                          : 'Hani can follow up on a meaningful care event later.',
                  value: settings.incidentFollowups,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setIncidentFollowups(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Bien-être'
                      : arabicScript
                          ? 'الراحة النفسية'
                          : 'Wellbeing check-ins',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Rappels privés pour vous, pas pour la famille.'
                      : arabicScript
                          ? 'تذكير خاص بيك، موش للعائلة.'
                          : 'Private caregiver reminders, not family data.',
                  value: settings.wellbeingReminders,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setWellbeingReminders(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Cercle de soins'
                      : arabicScript
                          ? 'طلبات الدائرة'
                          : 'Care Circle requests',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Demandes, réponses et alternatives.'
                      : arabicScript
                          ? 'طلبات المساعدة، الردود والبدائل.'
                          : 'Requests, responses, and alternatives.',
                  value: settings.careCircleRequests,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setCareCircleRequests(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Rendez-vous'
                      : arabicScript
                          ? 'المواعيد'
                          : 'Appointments',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Mises à jour du soutien professionnel.'
                      : arabicScript
                          ? 'تحديثات الدعم والمواعيد.'
                          : 'Professional support and appointment updates.',
                  value: settings.appointments,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) => update(() => controller.setAppointments(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Médicaments'
                      : arabicScript
                          ? 'تذكير الأدوية'
                          : 'Medication reminders',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Rappels natifs pour les prises planifiées.'
                      : arabicScript
                          ? 'تذكيرات على الهاتف للجرعات المسجّلة.'
                          : 'Native phone reminders for scheduled doses.',
                  value: settings.medicationReminders,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setMedicationReminders(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Résumé quotidien'
                      : arabicScript
                          ? 'الملخص اليومي'
                          : 'Daily summaries',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Résumé des soins, tâches et rappels importants.'
                      : arabicScript
                          ? 'ملخّص للرعاية والمهام والحاجات المهمّة.'
                          : 'Care, tasks, and important reminder summaries.',
                  value: settings.dailySummaries,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setDailySummaries(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Événements patient importants'
                      : arabicScript
                          ? 'أحداث مهمّة للمريض'
                          : 'Important patient events',
                  subtitle: settings.language == HaniLanguage.french
                      ? 'Mises à jour qui nécessitent votre attention.'
                      : arabicScript
                          ? 'تحديثات تستحق انتباهك.'
                          : 'Care changes that deserve your attention.',
                  value: settings.importantPatientEvents,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) =>
                      update(() => controller.setImportantPatientEvents(v)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Heures calmes'
                      : arabicScript
                          ? 'وقت هادئ'
                          : 'Quiet hours',
                  subtitle: '22:00–07:00',
                  value: settings.quietHours,
                  enabled: settings.notificationsEnabled,
                  onChanged: (v) => update(() => controller.setQuietHours(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          HaniSectionHeader(
            title: settings.language == HaniLanguage.french
                ? 'Boîte de réception'
                : arabicScript
                    ? 'الإشعارات الأخيرة'
                    : 'Inbox',
            subtitle: settings.language == HaniLanguage.french
                ? 'Pas de conversation invisible en arrière-plan.'
                : arabicScript
                    ? 'ما فماش محادثة كاملة تصير في الخلفية من غيرك.'
                    : 'No unseen full conversation runs in the background.',
          ),
          const SizedBox(height: 10),
          value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Card(
              child: Padding(
                padding: EdgeInsets.all(17),
                child: Text('Notifications unavailable.'),
              ),
            ),
            data: (data) {
              if (data.notifications.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 38,
                          color: HaniColors.primary,
                        ),
                        SizedBox(height: 9),
                        Text(
                          'You are all caught up.',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: data.notifications
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => openNotification(context, ref, item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pref extends StatelessWidget {
  const _Pref({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: enabled && value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: HaniColors.muted,
            fontSize: 12.2,
          ),
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opened = item['opened_at'] != null;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor:
              opened ? const Color(0xFFF0F3F2) : HaniColors.primarySoft,
          child: Icon(
            _icon(item['category']?.toString()),
            color: opened ? HaniColors.muted : HaniColors.primary,
          ),
        ),
        title: Text(
          item['title']?.toString() ?? 'Hani Maak',
          style: TextStyle(
            fontWeight: opened ? FontWeight.w700 : FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item['body']?.toString() ?? '',
            style: const TextStyle(height: 1.35),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  static IconData _icon(String? category) => switch (category) {
        'care_circle_request' => Icons.groups_outlined,
        'appointment' => Icons.calendar_month_outlined,
        'incident_followup' => Icons.history_rounded,
        'wellbeing_checkin' => Icons.favorite_outline_rounded,
        _ => Icons.notifications_none_rounded,
      };
}
