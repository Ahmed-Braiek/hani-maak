import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widget_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  Future<void> persist(WidgetRef ref) async {
    final s = ref.read(appSettingsProvider);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'update_app_preferences',
        args: {
          'language': s.language.code,
          'showHaniWidget': s.showHaniWidget,
          'showPatientWidget': s.showPatientWidget,
          'showCareLoadWidget': s.showCareLoadWidget,
          'showWellbeingWidget': s.showWellbeingWidget,
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
    } catch (_) {
      // Keep the UI responsive if a local preview backend is unavailable.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final c = ref.read(appSettingsProvider.notifier);
    String t(String tn, String ar, String en, String fr) =>
        haniText(s.language, tn: tn, ar: ar, en: en, fr: fr);

    void update(void Function() change) {
      change();
      persist(ref);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('ويدجات هاني', 'عناصر هاني', 'Hani widgets', 'Widgets Hani'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          HaniGradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HaniPill(
                  label: t('خصّص الويدجات', 'خصّص العناصر', 'Personalize widgets', 'Personnaliser les widgets'),
                  icon: Icons.dashboard_customize_outlined,
                ),
                const SizedBox(height: 13),
                Text(
                  t('خلي الشاشة خفيفة.', 'حافظ على شاشة بسيطة.', 'Keep the home screen calm.', 'Gardez un écran d’accueil léger.'),
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  t(
                    'ورّي كان المعلومات اللي تعاونك تتحرّك بسرعة.',
                    'اعرض فقط المعلومات التي تساعدك على التصرف بسرعة.',
                    'Show only information that helps you act quickly.',
                    'Affichez uniquement les informations utiles pour agir rapidement.',
                  ),
                  style: const TextStyle(color: HaniColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              final supported =
                  await HaniHomeWidgetService.instance.requestPin();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    supported
                        ? t(
                            'أندرويد حلّ طلب إضافة ويدجات هاني.',
                            'فتح أندرويد طلب إضافة عنصر هاني.',
                            'Android opened the Hani Maak widget request.',
                            'Android a ouvert la demande d’ajout du widget Hani Maak.',
                          )
                        : t(
                            'اضغط مطوّل على الشاشة الرئيسية، اختار Widgets وبعد Hani Maak.',
                            'اضغط مطولًا على الشاشة الرئيسية، اختر Widgets ثم Hani Maak.',
                            'Long-press the home screen, choose Widgets, then Hani Maak.',
                            'Appuyez longuement sur l’écran d’accueil, choisissez Widgets puis Hani Maak.',
                          ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_to_home_screen_rounded),
            label: Text(t('زيد ويدجات هاني للتليفون', 'أضف عنصر هاني للهاتف', 'Add Hani Maak widget to phone', 'Ajouter le widget Hani Maak')),
          ),
          const SizedBox(height: 10),
          Text(
            t(
              'كان أندرويد ما ورّاش التأكيد: اضغط مطوّل على الشاشة → Widgets → Hani Maak.',
              'إذا لم يظهر التأكيد: اضغط مطولًا على الشاشة → Widgets → Hani Maak.',
              'If Android shows no confirmation: long-press home → Widgets → Hani Maak.',
              'Si Android n’affiche rien : appui long sur l’accueil → Widgets → Hani Maak.',
            ),
            style: const TextStyle(color: HaniColors.muted, fontSize: 12.2),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                _Toggle(
                  icon: Icons.auto_awesome_rounded,
                  title: t('هاني', 'هاني', 'Hani companion', 'Compagnon Hani'),
                  subtitle: t('وصول سريع للنص والصوت', 'وصول سريع للنص والصوت', 'Fast text and live voice access', 'Accès rapide au texte et à la voix'),
                  value: s.showHaniWidget,
                  onChanged: (v) => update(() => c.setHaniWidget(v)),
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.favorite_outline_rounded,
                  title: t('لمحة على المريض', 'ملخص المريض', 'Patient snapshot', 'Aperçu patient'),
                  subtitle: t('مرحلة الرعاية والسياق الحالي', 'مرحلة الرعاية والسياق الحالي', 'Care stage and current context', 'Étape de soins et contexte actuel'),
                  value: s.showPatientWidget,
                  onChanged: (v) => update(() => c.setPatientWidget(v)),
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.balance_rounded,
                  title: t('حمل الرعاية', 'عبء الرعاية', 'Care load', 'Charge de soins'),
                  subtitle: t('مسؤولياتك المفتوحة بسرعة', 'مسؤولياتك المفتوحة بنظرة سريعة', 'Your open responsibilities at a glance', 'Vos responsabilités ouvertes en un coup d’œil'),
                  value: s.showCareLoadWidget,
                  onChanged: (v) => update(() => c.setCareLoadWidget(v)),
                ),
                const Divider(indent: 70),
                _Toggle(
                  icon: Icons.self_improvement_rounded,
                  title: t('حالتك', 'مؤشر الرفاه', 'Wellbeing pulse', 'État de bien-être'),
                  subtitle: t('اختصار خاص للتقييم', 'اختصار خاص للتقييم', 'Private check-in shortcut', 'Raccourci privé de suivi'),
                  value: s.showWellbeingWidget,
                  onChanged: (v) => update(() => c.setWellbeingWidget(v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      secondary: CircleAvatar(
        backgroundColor: HaniColors.primarySoft,
        child: Icon(icon, color: HaniColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: HaniColors.muted, fontSize: 12.2),
      ),
    );
  }
}
