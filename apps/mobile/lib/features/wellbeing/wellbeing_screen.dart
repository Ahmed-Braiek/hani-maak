import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class WellbeingScreen extends ConsumerStatefulWidget {
  const WellbeingScreen({super.key});

  @override
  ConsumerState<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends ConsumerState<WellbeingScreen> {
  String? savingMood;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  Future<void> checkIn(
    HaniLanguage language,
    String mood, {
    String? energy,
    String? sleep,
  }) async {
    setState(() => savingMood = mood);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'record_wellbeing_checkin',
        args: {
          'moodLabel': mood,
          if (energy != null) 'energyLabel': energy,
          if (sleep != null) 'sleepLabel': sleep,
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(language, 'تسجّل في مساحتك الخاصة.',
                  'تم الحفظ في مساحتك الخاصة.',
                  'Saved to your private space.',
                  'Enregistré dans votre espace privé.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => savingMood = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton.icon(
          onPressed: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t(language, 'عاود جرّب', 'حاول مجددًا', 'Retry',
              'Réessayer')),
        ),
      ),
      data: (data) {
        final recent = data.wellbeing;
        final strainPatterns = data.patterns
            .where((p) => p['type'] == 'caregiver_strain')
            .toList();

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
            children: [
              HaniPageHeader(
                title: t(language, 'مساحتي', 'مساحتي', 'My space',
                    'Mon espace'),
                subtitle: t(
                  language,
                  'إحساسك وكلامك مع هاني يبقاو خاصّين بيك.',
                  'يبقى شعورك ومحادثتك مع هاني خاصين بك.',
                  'Your wellbeing stays private by default.',
                  'Votre bien-être reste privé par défaut.',
                ),
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
                      t(language, 'كيفاش إنت اليوم؟', 'كيف حالك اليوم؟',
                          'How are you holding up today?',
                          'Comment tenez-vous aujourd’hui ?'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(language, 'اختيار واحد يكفي. لا سكور، لا حكم.',
                          'اختيار واحد يكفي. لا درجات ولا أحكام.',
                          'One choice is enough. No score, no judgment.',
                          'Un choix suffit. Aucun score, aucun jugement.'),
                      style: const TextStyle(color: HaniColors.muted),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MoodChip(
                          icon: Icons.sentiment_satisfied_alt_outlined,
                          label: t(language, 'لاباس', 'بخير', 'I’m okay',
                              'Ça va'),
                          loading: savingMood == 'okay',
                          onTap: () => checkIn(
                            language,
                            'okay',
                            energy: 'medium',
                            sleep: 'okay',
                          ),
                        ),
                        _MoodChip(
                          icon: Icons.battery_2_bar_rounded,
                          label: t(language, 'تعبان', 'متعب', 'Tired',
                              'Fatigué'),
                          loading: savingMood == 'tired',
                          onTap: () => checkIn(
                            language,
                            'tired',
                            energy: 'low',
                          ),
                        ),
                        _MoodChip(
                          icon: Icons.waves_outlined,
                          label: t(language, 'فوق طاقتي', 'مرهق جدًا',
                              'Overwhelmed', 'Débordé'),
                          loading: savingMood == 'overwhelmed',
                          onTap: () => checkIn(
                            language,
                            'overwhelmed',
                            energy: 'low',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (strainPatterns.isNotEmpty) ...[
                const SizedBox(height: 18),
                _PatternCard(
                  language: language,
                  t: t,
                  pattern: strainPatterns.first,
                  onTalk: () => context.push('/hani'),
                ),
              ],
              const SizedBox(height: 22),
              HaniSectionHeader(
                title: t(language, 'آخر المرّات', 'آخر المتابعات',
                    'Recent check-ins', 'Derniers check-ins'),
                subtitle: t(
                  language,
                  'تاريخ بسيط ليك إنت، موش تشخيص.',
                  'سجل بسيط لك وليس تشخيصًا.',
                  'A simple private history, not a diagnosis.',
                  'Un historique simple et privé, pas un diagnostic.',
                ),
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Text(
                      t(language, 'ما سجلنا حتى check-in توّا.',
                          'لا توجد متابعة مسجلة بعد.',
                          'No check-ins yet.',
                          'Aucun check-in pour le moment.'),
                      style: const TextStyle(color: HaniColors.muted),
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
                                  'Energy ' +
                                      item['energy_label'].toString(),
                                if (item['sleep_label'] != null)
                                  'Sleep ' + item['sleep_label'].toString(),
                              ].join(' · '),
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 18),
              _LinkCard(
                icon: Icons.fact_check_outlined,
                title: t(language, 'استبيان الراحة النفسية',
                    'استبيان الرفاه لمقدم الرعاية',
                    'Caregiver wellbeing questionnaire',
                    'Questionnaire de bien-être'),
                subtitle: data.questionnaires.isEmpty
                    ? t(
                        language,
                        'يتفعّل كان بأداة صادق عليها المختص.',
                        'يُفعّل فقط عند توفر أداة معتمدة من المختص.',
                        'Activated only when a specialist-validated instrument is available.',
                        'Activé uniquement avec un instrument validé par un spécialiste.',
                      )
                    : t(
                        language,
                        'فما أداة مصادق عليها جاهزة.',
                        'توجد أداة معتمدة جاهزة.',
                        'A validated instrument is available.',
                        'Un instrument validé est disponible.',
                      ),
                onTap: () => context.push('/questionnaire'),
              ),
              const SizedBox(height: 9),
              _LinkCard(
                icon: Icons.support_agent_rounded,
                title: t(language, 'احكي مع مختص', 'تحدث مع مختص',
                    'Talk to a professional', 'Parler à un professionnel'),
                subtitle: 'Call · WhatsApp · appointment',
                onTap: () => context.push('/handoff'),
              ),
              const SizedBox(height: 9),
              _LinkCard(
                icon: Icons.tune_rounded,
                title: t(language, 'الإعدادات', 'الإعدادات', 'Preferences',
                    'Préférences'),
                subtitle: 'Language · notifications · widgets',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}

typedef Localize = String Function(
  HaniLanguage,
  String,
  String,
  String,
  String,
);

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        onPressed: loading ? null : onTap,
        avatar: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18, color: HaniColors.primary),
        label: Text(label),
        side: const BorderSide(color: Color(0xFFE8DCCB)),
        backgroundColor: Colors.white.withValues(alpha: .78),
      );
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.language,
    required this.t,
    required this.pattern,
    required this.onTalk,
  });

  final HaniLanguage language;
  final Localize t;
  final Map<String, dynamic> pattern;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) => HaniGradientCard(
        gradient: HaniGradients.soft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.insights_outlined, color: HaniColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(language, 'الأيام الأخيرة أثقل شوية',
                        'الأيام الأخيرة تبدو أثقل قليلًا',
                        'The last few check-ins look heavier',
                        'Les derniers check-ins semblent plus lourds'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    t(
                      language,
                      'هذا نمط ملاحظ، موش تشخيص. تنجم تحكي مع هاني إذا تحب تسمع أو تنقص الحمل.',
                      'هذا نمط ملاحظ وليس تشخيصًا. يمكنك التحدث مع هاني للاستماع أو لتخفيف العبء.',
                      'This is an observed pattern, not a diagnosis. Talk to Hani if you want listening, practical help, or relief.',
                      'C’est une tendance observée, pas un diagnostic. Parlez à Hani pour être écouté ou alléger la charge.',
                    ),
                    style: const TextStyle(
                      color: HaniColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onTalk,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      t(language, 'احكي مع هاني', 'تحدث مع هاني',
                          'Talk to Hani', 'Parler à Hani'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
