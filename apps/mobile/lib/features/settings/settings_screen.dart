import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../../core/device/device_care_services.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final copy = AppCopy(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(copy.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          HaniGradientCard(
            gradient: HaniGradients.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HaniPill(
                  label: 'Hani Maak',
                  icon: Icons.tune_rounded,
                ),
                const SizedBox(height: 14),
                Text(
                  copy.t('settings'),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  t(
                    settings.language,
                    'خلّي التطبيق يخدم بالطريقة اللي تريحك.',
                    'اجعل التطبيق يعمل بالطريقة الأنسب لك.',
                    'Make Hani Maak fit the way you care.',
                    'Adaptez Hani Maak à votre façon de prendre soin.',
                  ),
                  style: const TextStyle(color: HaniColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                HaniSettingsTile(
                  icon: Icons.language_rounded,
                  title: copy.t('language'),
                  subtitle: settings.language.label,
                  onTap: () => _languageSheet(context, ref),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: copy.t('notifications'),
                  subtitle: settings.notificationsEnabled
                      ? t(settings.language, 'مفعّلة', 'مفعّلة', 'On · personalized',
                          'Activées · personnalisées')
                      : t(settings.language, 'مطفية', 'متوقفة', 'Off', 'Désactivées'),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: copy.t('widgets'),
                  subtitle: t(
                    settings.language,
                    'اختار شنوّة يبان في Today',
                    'اختر ما يظهر في صفحة اليوم',
                    'Choose what appears on Today',
                    'Choisissez ce qui apparaît sur Aujourd’hui',
                  ),
                  onTap: () => context.push('/widgets'),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.phone_android_rounded,
                  title: t(
                    settings.language,
                    'إعداد الهاتف',
                    'إعداد الهاتف',
                    'Phone setup',
                    'Configuration du téléphone',
                  ),
                  subtitle: t(
                    settings.language,
                    'إشعارات حقيقية وWidget على الشاشة الرئيسية',
                    'إشعارات حقيقية وودجت على الشاشة الرئيسية',
                    'Native notifications and home-screen widget',
                    'Notifications natives et widget d’écran d’accueil',
                  ),
                  onTap: () => _phoneSetup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                HaniSettingsTile(
                  icon: Icons.explore_outlined,
                  title: t(settings.language, 'كيفاش يخدم هاني',
                      'كيف يعمل هاني', 'How Hani Maak works',
                      'Comment fonctionne Hani Maak'),
                  subtitle: t(
                    settings.language,
                    'شرح سريع للخصوصية، الدعم، والدائرة.',
                    'شرح سريع للخصوصية والدعم ودائرة الرعاية.',
                    'A one-minute product guide',
                    'Guide produit en une minute',
                  ),
                  onTap: () => context.push('/how-it-works'),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.hub_outlined,
                  title: t(settings.language, 'مركز الرعاية', 'مركز الرعاية',
                      'Care hub', 'Centre de soins'),
                  subtitle: t(
                    settings.language,
                    'الخط الزمني، المواعيد، التعليمات والنشاطات',
                    'الخط الزمني والمواعيد والتعليمات والأنشطة',
                    'Timeline · appointments · instructions · activities',
                    'Chronologie · rendez-vous · instructions · activités',
                  ),
                  onTap: () => context.push('/care-hub'),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: t(settings.language, 'الخصوصية', 'الخصوصية',
                      'Privacy', 'Confidentialité'),
                  subtitle: t(
                    settings.language,
                    'الراحة النفسية متاعك تبقى خاصة افتراضيًا',
                    'يبقى رفاهك النفسي خاصًا افتراضيًا',
                    'Caregiver wellbeing stays private by default',
                    'Le bien-être de l’aidant reste privé par défaut',
                  ),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: copy.t('professionalSupport'),
                  subtitle: 'Call · WhatsApp · appointment',
                  onTap: () => context.push('/handoff'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t(
              settings.language,
              'نسخة Demo · بيانات مريض اصطناعية',
              'نسخة تجريبية · بيانات مريض اصطناعية',
              'Demo build · Synthetic patient data',
              'Build de démonstration · Données patient synthétiques',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HaniColors.muted.withValues(alpha: .8),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _phoneSetup(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HaniSectionHeader(
                title: 'Phone setup',
                subtitle:
                    'Enable the device features that make Hani Maak useful outside the app.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await DeviceCareServices.requestPermissions();
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Notification permission is ready.'
                            : 'Notification permission was not granted on this device.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Enable phone notifications'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await DeviceCareServices.requestHomeWidget();
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Home-screen widget request opened.'
                            : 'Home-screen widget pinning is unavailable on this platform.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.widgets_outlined),
                label: const Text('Add Hani Maak home widget'),
              ),
              const SizedBox(height: 11),
              const Text(
                'Remote push notifications need Firebase configuration. Local medication and appointment reminders work independently once the phone grants notification permission.',
                style: TextStyle(
                  color: HaniColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _languageSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: HaniLanguage.values
                .map(
                  (language) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: HaniColors.primarySoft,
                      child: Text(
                        switch (language) {
                          HaniLanguage.tounsi => 'TN',
                          HaniLanguage.arabic => 'AR',
                          HaniLanguage.french => 'FR',
                          HaniLanguage.english => 'EN',
                        },
                        style: const TextStyle(
                          color: HaniColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      language.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: ref.read(appSettingsProvider).language == language
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: HaniColors.primary,
                          )
                        : null,
                    onTap: () async {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setLanguage(language);
                      Navigator.pop(context);
                      try {
                        final current = ref.read(appSettingsProvider);
                        await ref.read(caregiverContextApiProvider).action(
                          'update_app_preferences',
                          args: {
                            'language': language.code,
                            'showHaniWidget': current.showHaniWidget,
                            'showPatientWidget': current.showPatientWidget,
                            'showCareLoadWidget': current.showCareLoadWidget,
                            'showWellbeingWidget': current.showWellbeingWidget,
                          },
                        );
                        await ref
                            .read(caregiverContextProvider.notifier)
                            .refreshContext();
                      } catch (_) {
                        // The selected language remains active locally; a signed-in
                        // production session will retry persistence on the next change.
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
