import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(caregiverContextProvider.notifier)
          .refreshContext(),
      child: value.when(
        loading: () => const _LoadingToday(),
        error: (error, _) => _ErrorToday(
          onRetry: () => ref
              .read(caregiverContextProvider.notifier)
              .refreshContext(),
        ),
        data: (data) => _TodayContent(data: data),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.data});
  final CaregiverContext data;

  @override
  Widget build(BuildContext context) {
    final latestWellbeing =
        data.wellbeing.isNotEmpty ? data.wellbeing.first : null;
    final firstName = data.caregiverName.split(' ').first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good evening, $firstName',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${data.patientName} is in your care circle. You do not have to carry everything alone.',
                    style: const TextStyle(
                      color: HaniColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: HaniColors.primarySoft,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M',
                style: const TextStyle(
                  color: HaniColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _HaniHero(patientName: data.patientName),
        const SizedBox(height: 22),
        const _SectionHeading(
          title: 'Today',
          subtitle: 'Only what needs your attention.',
        ),
        const SizedBox(height: 10),
        if (data.openTasks.isEmpty)
          const _SoftCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Nothing urgent right now',
            subtitle: 'Hani will surface the next useful step when it matters.',
          )
        else
          ...data.openTasks.take(4).map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskCard(task: task),
            ),
          ),
        const SizedBox(height: 16),
        const _SectionHeading(
          title: 'For you',
          subtitle: 'Private by default.',
        ),
        const SizedBox(height: 10),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context.go('/me'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: HaniColors.warm,
                    child: Icon(
                      Icons.favorite_outline_rounded,
                      color: HaniColors.warning,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How are you holding up?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latestWellbeing == null
                              ? 'A 20-second private check-in.'
                              : _wellbeingSummary(latestWellbeing),
                          style: const TextStyle(
                            color: HaniColors.muted,
                            height: 1.35,
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
        ),
        if (data.privateIncidents.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'Private incident draft',
            subtitle: 'Only you can see this until you approve sharing.',
          ),
          const SizedBox(height: 10),
          _IncidentDraftCard(incident: data.privateIncidents.first),
        ],
      ],
    );
  }

  static String _wellbeingSummary(Map<String, dynamic> item) {
    final mood = item['mood_label']?.toString();
    final energy = item['energy_label']?.toString();
    if (mood != null && energy != null) {
      return 'Last check-in: $mood · energy $energy';
    }
    if (mood != null) return 'Last check-in: $mood';
    return 'Your recent check-in is saved privately.';
  }
}

class _HaniHero extends StatelessWidget {
  const _HaniHero({required this.patientName});
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F5F4), Color(0xFFF8FBFA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7E9E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: HaniColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hani is here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(
                      'Text or voice · Derja, Arabic, French, English',
                      style: TextStyle(fontSize: 12.5, color: HaniColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Something difficult happening with $patientName?',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell Hani what is happening. It already knows the care context and will ask only what is useful.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/hani'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message Hani'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Live voice',
                onPressed: () => context.push('/voice'),
                icon: const Icon(Icons.mic_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final difficulty = task['difficulty']?.toString();
    final due = DateTime.tryParse(task['due_at']?.toString() ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: HaniColors.primarySoft,
              child: Icon(
                task['overnight'] == true
                    ? Icons.nights_stay_outlined
                    : Icons.task_alt_rounded,
                color: HaniColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['title']?.toString() ?? 'Care task', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (difficulty != null) difficulty,
                      if (due != null) _formatDue(due),
                    ].join(' · '),
                    style: const TextStyle(color: HaniColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  static String _formatDue(DateTime due) {
    final local = due.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _IncidentDraftCard extends StatelessWidget {
  const _IncidentDraftCard({required this.incident});
  final Map<String, dynamic> incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18),
                SizedBox(width: 7),
                Text('Private', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident['title']?.toString() ?? 'Recent incident',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(incident['summary']?.toString() ?? '', style: const TextStyle(height: 1.45)),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => context.push('/hani'),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Review with Hani before sharing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: HaniColors.muted, fontSize: 12)),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: HaniColors.primarySoft,
          child: Icon(icon, color: HaniColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _LoadingToday extends StatelessWidget {
  const _LoadingToday();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 18),
        Center(child: Text('Loading your care context…')),
      ],
    );
  }
}

class _ErrorToday extends StatelessWidget {
  const _ErrorToday({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.cloud_off_rounded, size: 44),
        const SizedBox(height: 16),
        const Text(
          'Hani Maak could not load your care context.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pull to retry, or reconnect now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: HaniColors.muted),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
