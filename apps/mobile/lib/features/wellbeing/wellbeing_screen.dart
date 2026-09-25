import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: () => ref
              .read(caregiverContextProvider.notifier)
              .refreshContext(),
          child: const Text('Retry'),
        ),
      ),
      data: (data) {
        final recent = data.wellbeing;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text(
              'Me',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your space. Private by default.',
              style: TextStyle(color: HaniColors.muted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HaniColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: HaniColors.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Your emotional check-ins and Hani conversations are not shared with the Care Circle.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How are you holding up?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A quick check-in. No score, no judgment.',
                      style: TextStyle(color: HaniColors.muted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('I’m okay'),
                          onPressed: () => _checkIn(context, ref, 'okay'),
                        ),
                        ActionChip(
                          label: const Text('Tired'),
                          onPressed: () => _checkIn(context, ref, 'tired'),
                        ),
                        ActionChip(
                          label: const Text('Overwhelmed'),
                          onPressed: () => _checkIn(context, ref, 'overwhelmed'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Recent check-ins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(17),
                  child: Text(
                    'No check-ins yet. When you are ready, start with one word.',
                    style: TextStyle(color: HaniColors.muted),
                  ),
                ),
              )
            else
              ...recent.take(7).map(
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (item['energy_label'] != null)
                            'Energy ' + item['energy_label'].toString(),
                          if (item['sleep_label'] != null)
                            'Sleep ' + item['sleep_label'].toString(),
                        ].join(' · '),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push('/questionnaire'),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: HaniColors.primarySoft,
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: HaniColors.primary,
                        ),
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caregiver wellbeing questionnaire',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Versioned clinical questionnaire engine with private history.',
                              style: TextStyle(color: HaniColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push('/handoff'),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: HaniColors.primarySoft,
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: HaniColors.primary,
                        ),
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Talk to a professional',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Call, WhatsApp or request an appointment with minimum-necessary sharing.',
                              style: TextStyle(color: HaniColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
