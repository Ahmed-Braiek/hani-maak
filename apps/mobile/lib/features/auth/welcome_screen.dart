import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: HaniColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 22),
              const Text(
                'Hani Maak',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Caregiving is hard. You should not have to carry the uncertainty alone.',
                style: TextStyle(fontSize: 19, height: 1.4, color: HaniColors.muted),
              ),
              const SizedBox(height: 30),
              const _Benefit(icon: Icons.mic_none_rounded, title: 'Talk naturally', text: 'Tunisian Derja, Arabic, French or English.'),
              const SizedBox(height: 14),
              const _Benefit(icon: Icons.psychology_alt_outlined, title: 'Context that follows you', text: 'Hani remembers the patient, incidents and care plan.'),
              const SizedBox(height: 14),
              const _Benefit(icon: Icons.groups_2_outlined, title: 'Share the load', text: 'Coordinate the Care Circle without blame or scoring.'),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                onPressed: () => context.go('/today'),
                child: const Text('Explore caregiver demo'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => context.push('/sign-in'),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Demo data is synthetic.', style: TextStyle(color: HaniColors.muted, fontSize: 11.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(backgroundColor: HaniColors.primarySoft, child: Icon(icon, color: HaniColors.primary)),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(color: HaniColors.muted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
