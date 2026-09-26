import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final copy = AppCopy(settings.language);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HaniColors.mint.withValues(alpha: .45),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                Row(
                  children: [
                    const _BrandMark(),
                    const Spacer(),
                    PopupMenuButton<HaniLanguage>(
                      tooltip: copy.t('language'),
                      onSelected: ref
                          .read(appSettingsProvider.notifier)
                          .setLanguage,
                      itemBuilder: (_) => HaniLanguage.values
                          .map(
                            (lang) => PopupMenuItem(
                              value: lang,
                              child: Text(lang.label),
                            ),
                          )
                          .toList(),
                      child: HaniPill(
                        label: settings.language.label,
                        icon: Icons.language_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 52),
                HaniAnimatedEntrance(
                  child: Text(
                    copy.t('welcomeTitle'),
                    style: const TextStyle(
                      fontSize: 39,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
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
                const SizedBox(height: 30),
                const HaniAnimatedEntrance(
                  delay: Duration(milliseconds: 140),
                  child: HaniGradientCard(
                    gradient: HaniGradients.hero,
                    child: _WelcomeHero(),
                  ),
                ),
                const SizedBox(height: 20),
                const _Benefit(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Live AI voice',
                  text: 'Natural continuous conversation with interruption.',
                ),
                const SizedBox(height: 11),
                const _Benefit(
                  icon: Icons.psychology_alt_outlined,
                  title: 'Context that follows care',
                  text: 'Patient, incidents, tasks and verified instructions.',
                ),
                const SizedBox(height: 11),
                const _Benefit(
                  icon: Icons.groups_2_outlined,
                  title: 'Share the load',
                  text: 'Coordinate the Care Circle without scoring or blame.',
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: () => context.go('/today'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(copy.t('startDemo')),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.push('/sign-in'),
                  child: Text(copy.t('signIn')),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Judge-safe demo · Synthetic data · Privacy-first',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HaniColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            gradient: HaniGradients.hero,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'Hani Maak',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: -.4,
          ),
        ),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
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
                    'تونسي · Français · English',
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
}

class _Orb extends StatelessWidget {
  const _Orb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .14),
        border: Border.all(color: Colors.white.withValues(alpha: .3), width: 8),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 34),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    text,
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
}
