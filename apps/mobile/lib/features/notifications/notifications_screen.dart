import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final copy = AppCopy(settings.language);

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
                            : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
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
                            : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
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
                  onChanged: controller.setNotifications,
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
                      : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                          ? 'متابعة الحوادث'
                          : 'Incident follow-ups',
                  subtitle: 'Check back after meaningful care events',
                  value: settings.incidentFollowups,
                  enabled: settings.notificationsEnabled,
                  onChanged: controller.setIncidentFollowups,
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Bien-être'
                      : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                          ? 'الراحة النفسية'
                          : 'Wellbeing check-ins',
                  subtitle: 'Private caregiver reminders',
                  value: settings.wellbeingReminders,
                  enabled: settings.notificationsEnabled,
                  onChanged: controller.setWellbeingReminders,
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Cercle de soins'
                      : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                          ? 'طلبات الدائرة'
                          : 'Care Circle requests',
                  subtitle: 'Task requests and responses',
                  value: settings.careCircleRequests,
                  enabled: settings.notificationsEnabled,
                  onChanged: controller.setCareCircleRequests,
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Rendez-vous'
                      : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                          ? 'المواعيد'
                          : 'Appointments',
                  subtitle: 'Professional support updates',
                  value: settings.appointments,
                  enabled: settings.notificationsEnabled,
                  onChanged: controller.setAppointments,
                ),
                const Divider(indent: 16, endIndent: 16),
                _Pref(
                  title: settings.language == HaniLanguage.french
                      ? 'Heures calmes'
                      : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                          ? 'وقت هادئ'
                          : 'Quiet hours',
                  subtitle: '22:00–07:00 · safety-critical routes unaffected',
                  value: settings.quietHours,
                  enabled: settings.notificationsEnabled,
                  onChanged: controller.setQuietHours,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          HaniSectionHeader(
            title: settings.language == HaniLanguage.french
                ? 'Boîte de réception'
                : settings.(language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                    ? 'الإشعارات الأخيرة'
                    : 'Inbox',
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
                        child: _NotificationCard(item: item),
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
  const _NotificationCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final opened = item['opened_at'] != null;

    return Card(
      child: ListTile(
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
