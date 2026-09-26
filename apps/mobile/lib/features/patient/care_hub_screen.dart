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
              icon: Icons.route_outlined,
              title: t(language, 'خطة الرعاية', 'خطة الرعاية',
                  'Care plan', 'Plan de soins'),
              subtitle: t(
                language,
                'تعليمات، مسؤوليات، مواعيد ومتابعة',
                'تعليمات ومسؤوليات ومواعيد ومتابعة',
                'Instructions, responsibilities, appointments and follow-up',
                'Instructions, responsabilités, rendez-vous et suivi',
              ),
              onTap: () => context.push('/care-plan'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.folder_copy_outlined,
              title: t(language, 'الوثائق المهمة', 'الوثائق المهمة',
                  'Important documents', 'Documents importants'),
              subtitle: '${ctx.careDocuments.length} ' +
                  t(language, 'وثائق محفوظة', 'وثائق محفوظة',
                      'saved documents', 'documents enregistrés'),
              onTap: () => context.push('/documents'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.groups_outlined,
              title: t(language, 'العائلة والمرافقين', 'العائلة ومقدمو الرعاية',
                  'Family & caregivers', 'Famille et aidants'),
              subtitle: t(language, 'تقسيم المسؤوليات وطلبات المساعدة',
                  'تقسيم المسؤوليات وطلبات المساعدة',
                  'Responsibilities, workload and help requests',
                  'Responsabilités, charge et demandes d’aide'),
              onTap: () => context.go('/circle'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.notifications_active_outlined,
              title: t(language, 'التذكيرات والتنبيهات', 'التذكيرات والتنبيهات',
                  'Reminders & notifications', 'Rappels et notifications'),
              subtitle: '${ctx.notifications.length} ' +
                  t(language, 'تنبيهات رعاية', 'تنبيهات رعاية',
                      'care updates', 'mises à jour'),
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.medication_outlined,
              title: t(language, 'الأدوية والتذكير', 'الأدوية والتذكير',
                  'Medication & reminders', 'Médicaments et rappels'),
              subtitle: '${ctx.medications.length} active · ${ctx.medicationEvents.length} recent events',
              onTap: () => context.push('/medications'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.document_scanner_outlined,
              title: t(language, 'مسح الوصفة', 'مسح الوصفة',
                  'Prescription scanning', 'Scanner une ordonnance'),
              subtitle: t(language, 'OCR مع مراجعة قبل الحفظ',
                  'OCR مع مراجعة قبل الحفظ',
                  'OCR with caregiver review before saving',
                  'OCR avec validation avant enregistrement'),
              onTap: () => context.push('/medications'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.summarize_outlined,
              title: t(language, 'ملخص العائلة', 'ملخص العائلة',
                  'Caregiver summary', 'Résumé aidant'),
              subtitle: t(language, 'نشاط، أدوية، مواعيد وتنبيهات',
                  'النشاط والأدوية والمواعيد والتنبيهات',
                  'Activity, medication, appointments, and alerts',
                  'Activité, médicaments, rendez-vous et alertes'),
              onTap: () => context.push('/summary'),
            ),
            const SizedBox(height: 9),
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
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.insights_outlined,
              title: t(language, 'ملاحظات مفيدة', 'ملاحظات مفيدة',
                  'Patient insights', 'Repères utiles'),
              subtitle: ctx.patterns.isEmpty
                  ? t(language, 'هاني يراقب التكرار من غير تشخيص',
                      'يراقب هاني الأنماط دون تشخيص',
                      'Hani watches for useful patterns without diagnosing',
                      'Hani repère des tendances utiles sans diagnostic')
                  : '${ctx.patterns.length} ' +
                      t(language, 'ملاحظات سياقية', 'ملاحظات سياقية',
                          'contextual patterns', 'tendances contextuelles'),
              onTap: () => context.push('/hani'),
            ),
            const SizedBox(height: 9),
            _HubTile(
              icon: Icons.contact_phone_outlined,
              title: t(language, 'جهات الاتصال المهمة', 'جهات الاتصال المهمة',
                  'Important contacts', 'Contacts importants'),
              subtitle: t(language, 'المختصون ومسارات الدعم الموثقة',
                  'المختصون ومسارات الدعم الموثقة',
                  'Verified professionals and support routes',
                  'Professionnels vérifiés et voies de soutien'),
              onTap: () => context.push('/handoff'),
            ),
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
