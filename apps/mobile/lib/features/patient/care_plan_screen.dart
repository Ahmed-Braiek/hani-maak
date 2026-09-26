import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class CarePlanScreen extends ConsumerWidget {
  const CarePlanScreen({super.key});

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'خطة الرعاية', 'خطة الرعاية',
            'Care plan', 'Plan de soins')),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref
                .read(caregiverContextProvider.notifier)
                .refreshContext(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
        data: (data) {
          final openTasks = data.openTasks;
          final upcoming = data.appointments.where((item) {
            final raw = item['scheduled_for']?.toString();
            final date = raw == null ? null : DateTime.tryParse(raw);
            return date != null && date.isAfter(DateTime.now());
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(caregiverContextProvider.notifier).refreshContext(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
              children: [
                HaniGradientCard(
                  gradient: HaniGradients.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HaniPill(
                        label: 'LIVE CARE PLAN',
                        icon: Icons.route_outlined,
                        background: Color(0x2AFFFFFF),
                        foreground: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          language,
                          'الخطة تجمع تعليمات المختص، المسؤوليات، المواعيد والمتابعة في بلاصة وحدة.',
                          'تجمع الخطة تعليمات المختص والمسؤوليات والمواعيد والمتابعة في مكان واحد.',
                          'Verified instructions, responsibilities, appointments and follow-up in one live plan.',
                          'Instructions vérifiées, responsabilités, rendez-vous et suivi dans un plan vivant.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFE7F5FF),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _PlanMetric(
                  icon: Icons.verified_user_outlined,
                  title: t(language, 'تعليمات المختص', 'تعليمات المختص',
                      'Verified instructions', 'Instructions vérifiées'),
                  value: data.instructions.length.toString(),
                  onTap: () => context.go('/patient'),
                ),
                const SizedBox(height: 9),
                _PlanMetric(
                  icon: Icons.task_alt_outlined,
                  title: t(language, 'مسؤوليات مفتوحة', 'مسؤوليات مفتوحة',
                      'Open responsibilities', 'Responsabilités ouvertes'),
                  value: openTasks.length.toString(),
                  onTap: () => context.go('/circle'),
                ),
                const SizedBox(height: 9),
                _PlanMetric(
                  icon: Icons.calendar_month_outlined,
                  title: t(language, 'مواعيد جاية', 'مواعيد قادمة',
                      'Upcoming appointments', 'Rendez-vous à venir'),
                  value: upcoming.length.toString(),
                  onTap: () => context.go('/patient'),
                ),
                const SizedBox(height: 22),
                HaniSectionHeader(
                  title: t(language, 'الأولوية توّا', 'الأولوية الآن',
                      'What needs attention now', 'À surveiller maintenant'),
                ),
                const SizedBox(height: 10),
                if (data.followUp != null)
                  HaniGradientCard(
                    gradient: HaniGradients.soft,
                    onTap: () => context.push('/hani'),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.history_rounded,
                              color: HaniColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data.followUp?['body']?.toString() ??
                                data.followUp?['title']?.toString() ??
                                'Follow-up ready',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  )
                else if (openTasks.isNotEmpty)
                  ...openTasks.take(3).map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Card(
                            child: ListTile(
                              onTap: () => context.go('/circle'),
                              leading: const CircleAvatar(
                                backgroundColor: HaniColors.primarySoft,
                                child: Icon(Icons.task_alt_outlined,
                                    color: HaniColors.primary),
                              ),
                              title: Text(
                                task['title']?.toString() ?? 'Care task',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              subtitle: Text(
                                task['difficulty']?.toString() ?? 'routine',
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        ),
                      )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: HaniColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No urgent care-plan item right now.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.push('/hani'),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    t(language, 'راجع الخطة مع هاني', 'راجع الخطة مع هاني',
                        'Review the plan with Hani',
                        'Revoir le plan avec Hani'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(15),
          leading: CircleAvatar(
            backgroundColor: HaniColors.primarySoft,
            child: Icon(icon, color: HaniColors.primary),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: HaniColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
}
