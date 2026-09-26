import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
                  settings.language == HaniLanguage.tounsi
                      ? 'خلّي التطبيق يخدم بالطريقة اللي تريحك.'
                      : settings.language == HaniLanguage.french
                          ? 'Adaptez Hani Maak à votre façon de prendre soin.'
                          : 'Make Hani Maak fit the way you care.',
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
                      ? 'On · personalized'
                      : 'Off',
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(indent: 70),
                HaniSettingsTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: copy.t('widgets'),
                  subtitle: 'Choose what appears on Today',
                  onTap: () => context.push('/widgets'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                HaniSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: settings.language == HaniLanguage.french
                      ? 'Confidentialité'
                      : settings.language == HaniLanguage.tounsi
                          ? 'الخصوصية'
                          : 'Privacy',
                  subtitle: 'Caregiver wellbeing stays private by default',
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
            'Demo build · Synthetic patient data',
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
                        language == HaniLanguage.tounsi
                            ? 'ت'
                            : language == HaniLanguage.french
                                ? 'FR'
                                : 'EN',
                        style: const TextStyle(
                          color: HaniColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      language.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setLanguage(language);
                      Navigator.pop(context);
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
