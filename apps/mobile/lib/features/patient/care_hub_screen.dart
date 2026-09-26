import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class CareHubScreen extends ConsumerWidget {
  const CareHubScreen({super.key});

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
    final data = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'مركز الرعاية', 'مركز الرعاية', 'Care hub',
            'Centre de soins')),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Care hub unavailable.')),
        data: (ctx) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            HaniGradientCard(
              gradient: HaniGradients.soft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HaniPill(
                    label: 'SHARED CARE',
                    icon: Icons.hub_outlined,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(
                      language,
                      'معلومات الرعاية المهمة في بلاصة وحدة',
                      'معلومات الرعاية المهمة في مكان واحد',
                      'Important care information in one place',
                      'Les informations utiles au même endroit',
                    ),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t(
                      language,
                      'المعلومات الخاصة بيك تبقى خارج المساحة المشتركة.',
                      'تبقى معلوماتك الخاصة خارج المساحة المشتركة.',
                      'Your private wellbeing stays outside the shared care space.',
                      'Votre bien-être privé reste hors de l’espace partagé.',
                    ),
                    style: const TextStyle(color: HaniColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _HubTile(
              icon: Icons.timeline_rounded,
              title: t(language, 'الخط الزمني', 'الخط الزمني',
                  'Care timeline', 'Chronologie'),
              subtitle: ctx.timeline.length.toString() +
                  ' ' +
                  t(language, 'أحداث مشتركة', 'أحداث مشتركة',
                      'shared events', 'événements partagés'),
              onTap: () => context.go('/patient'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.calendar_month_outlined,
              title: t(language, 'المواعيد', 'المواعيد', 'Appointments',
                  'Rendez-vous'),
              subtitle: ctx.appointments.length.toString() +
                  ' ' +
                  t(language, 'مواعيد مسجلة', 'مواعيد مسجلة',
                      'care appointments', 'rendez-vous de soins'),
              onTap: () => context.go('/patient'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.verified_user_outlined,
              title: t(language, 'تعليمات المختص', 'تعليمات المختص',
                  'Verified instructions', 'Instructions vérifiées'),
              subtitle: ctx.instructions.length.toString() +
                  ' ' +
                  t(language, 'تعليمات', 'تعليمات', 'instructions',
                      'instructions'),
              onTap: () => context.go('/patient'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.medical_services_outlined,
              title: t(language, 'شبكة المختصين', 'شبكة المختصين',
                  'Professional network', 'Réseau professionnel'),
              subtitle: ctx.professionals.length.toString() +
                  ' ' +
                  t(language, 'مسارات موثقة', 'مسارات موثقة',
                      'verified routes', 'parcours vérifiés'),
              onTap: () => context.push('/handoff'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.extension_outlined,
              title: t(language, 'نشاط مع المريض', 'نشاط مع المريض',
                  'Patient activity', 'Activité patient'),
              subtitle: t(
                language,
                'لحظة مألوفة يطلقها المرافق',
                'نشاط لطيف يطلقه مقدم الرعاية',
                'Caregiver-launched familiar activity',
                'Activité familière lancée par l’aidant',
              ),
              onTap: () => context.push('/activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: HaniColors.primarySoft,
            child: Icon(icon, color: HaniColors.primary),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: HaniColors.muted),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}
