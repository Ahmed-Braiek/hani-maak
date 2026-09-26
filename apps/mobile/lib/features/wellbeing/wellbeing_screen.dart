import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';
import '../hani/hani_controller.dart';

class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    await ref
        .read(haniChatProvider.notifier)
        .send('Please record a private wellbeing check-in for me: mood $label.');
    if (context.mounted) context.push('/hani');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: const Text('Retry'),
        ),
      ),
      data: (data) {
        final recent = data.wellbeing;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
          children: [
            HaniPageHeader(
              title: language == HaniLanguage.french
                  ? 'Mon espace'
                  : language == HaniLanguage.tounsi
                      ? 'مساحتي'
                      : 'My space',
              subtitle: language == HaniLanguage.french
                  ? 'Votre bien-être reste privé par défaut.'
                  : language == HaniLanguage.tounsi
                      ? 'إحساسك وكلامك مع هاني يبقاو خاصّين بيك.'
                      : 'Your wellbeing stays private by default.',
              trailing: IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(height: 20),
            HaniGradientCard(
              gradient: HaniGradients.wellbeing,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HaniPill(
                    label: 'PRIVATE',
                    icon: Icons.lock_outline_rounded,
                    background: Color(0xFFFFE6C4),
                    foreground: HaniColors.warning,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    language == HaniLanguage.french
                        ? 'Comment tenez-vous aujourd’hui ?'
                        : language == HaniLanguage.tounsi
                            ? 'كيفاش إنت اليوم؟'
                            : 'How are you holding up today?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    language == HaniLanguage.french
                        ? 'Un mot suffit. Aucun score, aucun jugement.'
                        : language == HaniLanguage.tounsi
                            ? 'كلمة تكفي. لا سكور، لا حكم.'
                            : 'One word is enough. No score, no judgment.',
                    style: const TextStyle(color: HaniColors.muted),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Mood(
                        emoji: '🙂',
                        label: language == HaniLanguage.french
                            ? 'Ça va'
                            : language == HaniLanguage.tounsi
                                ? 'لاباس'
                                : 'I’m okay',
                        onTap: () => _checkIn(context, ref, 'okay'),
                      ),
                      _Mood(
                        emoji: '😮‍💨',
                        label: language == HaniLanguage.french
                            ? 'Fatigué'
                            : language == HaniLanguage.tounsi
                                ? 'تعبان'
                                : 'Tired',
                        onTap: () => _checkIn(context, ref, 'tired'),
                      ),
                      _Mood(
                        emoji: '🫶',
                        label: language == HaniLanguage.french
                            ? 'Débordé'
                            : language == HaniLanguage.tounsi
                                ? 'فوق طاقتي'
                                : 'Overwhelmed',
                        onTap: () => _checkIn(context, ref, 'overwhelmed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            HaniSectionHeader(
              title: language == HaniLanguage.french
                  ? 'Derniers check-ins'
                  : language == HaniLanguage.tounsi
                      ? 'آخر المرّات'
                      : 'Recent check-ins',
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(17),
                  child: Text(
                    'No check-ins yet.',
                    style: TextStyle(color: HaniColors.muted),
                  ),
                ),
              )
            else
              ...recent.take(6).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: const CircleAvatar(
                            backgroundColor: HaniColors.warm,
                            child: Icon(
                              Icons.favorite_outline_rounded,
                              color: HaniColors.warning,
                            ),
                          ),
                          title: Text(
                            item['mood_label']?.toString() ?? 'Check-in',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (item['energy_label'] != null)
                                'Energy ${item['energy_label']}',
                              if (item['sleep_label'] != null)
                                'Sleep ${item['sleep_label']}',
                            ].join(' · '),
                          ),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 18),
            _LinkCard(
              icon: Icons.fact_check_outlined,
              title: language == HaniLanguage.french
                  ? 'Questionnaire de bien-être'
                  : language == HaniLanguage.tounsi
                      ? 'استبيان الراحة النفسية'
                      : 'Caregiver wellbeing questionnaire',
              subtitle: language == HaniLanguage.french
                  ? 'Uniquement avec un instrument validé.'
                  : language == HaniLanguage.tounsi
                      ? 'يتفعّل كان بأداة مصادق عليها من المختص.'
                      : 'Activated only with a validated instrument.',
              onTap: () => context.push('/questionnaire'),
            ),
            const SizedBox(height: 9),
            _LinkCard(
              icon: Icons.support_agent_rounded,
              title: language == HaniLanguage.french
                  ? 'Parler à un professionnel'
                  : language == HaniLanguage.tounsi
                      ? 'احكي مع مختص'
                      : 'Talk to a professional',
              subtitle: 'Call · WhatsApp · appointment',
              onTap: () => context.push('/handoff'),
            ),
            const SizedBox(height: 9),
            _LinkCard(
              icon: Icons.tune_rounded,
              title: language == HaniLanguage.french
                  ? 'Préférences'
                  : language == HaniLanguage.tounsi
                      ? 'الإعدادات'
                      : 'Preferences',
              subtitle: 'Language · notifications · widgets',
              onTap: () => context.push('/settings'),
            ),
          ],
        );
      },
    );
  }
}

class _Mood extends StatelessWidget {
  const _Mood({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        onPressed: onTap,
        avatar: Text(emoji),
        label: Text(label),
        side: const BorderSide(color: Color(0xFFE8DCCB)),
        backgroundColor: Colors.white.withValues(alpha: .75),
      );
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
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
          contentPadding: const EdgeInsets.all(15),
          leading: CircleAvatar(
            backgroundColor: HaniColors.primarySoft,
            child: Icon(icon, color: HaniColors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: HaniColors.muted,
              fontSize: 12.2,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}
