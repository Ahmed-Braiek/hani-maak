import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good evening, Mariem', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('You do not have to carry everything alone.', style: TextStyle(color: HaniColors.muted)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: HaniColors.primarySoft,
              child: Icon(Icons.person_rounded, color: HaniColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Something difficult happening?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Tell Hani what is happening with Fatma. Speak naturally — Derja, French, Arabic or English.'),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.push('/hani'),
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Talk to Hani'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Today'),
        const SizedBox(height: 10),
        const _TodayItem(
          icon: Icons.medication_outlined,
          title: 'Evening medication',
          subtitle: 'Professional instruction available',
          time: '20:00',
        ),
        const SizedBox(height: 10),
        const _TodayItem(
          icon: Icons.nightlight_outlined,
          title: 'Check sleep routine',
          subtitle: 'Sami can help if you need a break',
          time: '21:30',
        ),
        const SizedBox(height: 20),
        const _SectionTitle('For you'),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: HaniColors.warm,
              child: Icon(Icons.favorite_outline, color: HaniColors.warning),
            ),
            title: const Text('How are you holding up today?', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Private to you · about 20 seconds'),
            trailing: const Icon(Icons.chevron_right),
            onTap: null,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
}

class _TodayItem extends StatelessWidget {
  const _TodayItem({required this.icon, required this.title, required this.subtitle, required this.time});
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: HaniColors.primarySoft, child: Icon(icon, color: HaniColors.primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: HaniColors.muted)),
                ],
              ),
            ),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
