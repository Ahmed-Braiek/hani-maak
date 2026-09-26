import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final copy = AppCopy(s.language);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HaniColors.mint.withValues(alpha: .45),
              ),
            ),
          ),
          Positioned(
            top: 230,
            left: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HaniColors.lilac.withValues(alpha: .25),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              children: [
                Row(
                  children: [
                    const _Brand(),
                    const Spacer(),
                    PopupMenuButton<HaniLanguage>(
                      tooltip: copy.t('language'),
                      onSelected: ref.read(appSettingsProvider.notifier).setLanguage,
                      itemBuilder: (_) => HaniLanguage.values
                          .map((lang) => PopupMenuItem(
                                value: lang,
                                child: Text(lang.label),
                              ))
                          .toList(),
                      child: HaniPill(
                        label: s.language.label,
                        icon: Icons.language_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                HaniAnimatedEntrance(
                  child: Text(
                    copy.t('welcomeTitle'),
                    style: const TextStyle(
                      fontSize: 40,
                      height: 1.01,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                HaniAnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    copy.t('welcomeBody'),
                    style: const TextStyle(
                      fontSize: 16.5,
                      height: 1.55,
                      color: HaniColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 27),
                const HaniAnimatedEntrance(
                  delay: Duration(milliseconds: 140),
                  child: HaniGradientCard(
                    gradient: HaniGradients.hero,
                    child: _Hero(),
                  ),
                ),
                const SizedBox(height: 17),
                HaniAnimatedEntrance(
                  delay: const Duration(milliseconds: 190),
                  child: _Understand(
                    title: t(s.language, 'افهم التطبيق في دقيقة',
                        'افهم التطبيق في دقيقة',
                        'Understand the app in one minute',
                        'Comprendre l’app en une minute'),
                    body: t(s.language,
                        'شوف كيفاش هاني يحمي الخصوصية، يخفف الحمل، ويوصلك بالمختص وقت يلزم.',
                        'اكتشف كيف يحمي هاني الخصوصية ويخفف العبء ويربطك بالمختص عند الحاجة.',
                        'See how Hani protects privacy, reduces mental load, and connects you to human support when needed.',
                        'Découvrez comment Hani protège la confidentialité, réduit la charge et facilite le relais humain.'),
                    onTap: () => context.push('/how-it-works'),
                  ),
                ),
                const SizedBox(height: 17),
                _Benefit(
                  icon: Icons.graphic_eq_rounded,
                  title: t(s.language, 'صوت مباشر', 'صوت مباشر',
                      'Live AI voice', 'Voix IA en direct'),
                  body: t(s.language,
                      'محادثة متواصلة تنجم تقاطعها كي مكالمة حقيقية.',
                      'محادثة مستمرة يمكنك مقاطعتها مثل مكالمة حقيقية.',
                      'Natural continuous conversation with real interruption.',
                      'Conversation naturelle et continue avec interruption.'),
                ),
                const SizedBox(height: 10),
                _Benefit(
                  icon: Icons.psychology_alt_outlined,
                  title: t(s.language, 'سياق موش إجابات عامة',
                      'سياق وليس إجابات عامة',
                      'Context, not generic answers',
                      'Du contexte, pas des réponses génériques'),
                  body: t(s.language,
                      'المريض، الحوادث، المهام وتعليمات المختص في نفس السياق.',
                      'المريض والحوادث والمهام وتعليمات المختص في نفس السياق.',
                      'Patient, incidents, tasks, and verified instructions stay connected.',
                      'Patient, incidents, tâches et instructions vérifiées restent reliés.'),
                ),
                const SizedBox(height: 10),
                _Benefit(
                  icon: Icons.groups_2_outlined,
                  title: t(s.language, 'قسّم الحمل', 'شارك الحمل',
                      'Share the load', 'Partager la charge'),
                  body: t(s.language,
                      'تنسيق بين العائلة بلا سكور وبلا لوم.',
                      'تنسيق بين أفراد الرعاية دون نقاط أو لوم.',
                      'Coordinate the Care Circle without scores, blame, or competition.',
                      'Coordonner le Cercle de soins sans score, reproche ni compétition.'),
                ),
                const SizedBox(height: 27),
                FilledButton.icon(
                  onPressed: () => context.go('/today'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(copy.t('startDemo')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push('/sign-in'),
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(copy.t('signIn')),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Judge-safe demo · Synthetic demo data · Privacy-first architecture',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HaniColors.muted, fontSize: 10.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) =>
      const HaniBrandMark(size: 48);
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HaniPill(
            label: 'HANI LIVE',
            icon: Icons.waves_rounded,
            background: Color(0x33FFFFFF),
            foreground: Colors.white,
          ),
          SizedBox(height: 22),
          Row(
            children: [
              _Orb(),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Just talk.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'تونسي · العربية · Français · English',
                      style: TextStyle(color: Color(0xFFD8EEEA)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
}

class _Orb extends StatelessWidget {
  const _Orb();

  @override
  Widget build(BuildContext context) => Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .14),
          border: Border.all(
            color: Colors.white.withValues(alpha: .3),
            width: 8,
          ),
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 34,
        ),
      );
}

class _Understand extends StatelessWidget {
  const _Understand({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: HaniColors.lilac,
                  child: Icon(
                    Icons.explore_outlined,
                    color: HaniColors.lilacInk,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          color: HaniColors.muted,
                          height: 1.35,
                          fontSize: 12.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: HaniColors.primarySoft,
                child: Icon(icon, color: HaniColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        color: HaniColors.muted,
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
