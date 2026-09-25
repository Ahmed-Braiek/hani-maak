import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref
              .read(caregiverContextProvider.notifier)
              .refreshContext(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ),
      data: (data) => _PatientContent(data: data),
    );
  }
}

class _PatientContent extends StatelessWidget {
  const _PatientContent({required this.data});
  final CaregiverContext data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: HaniColors.primarySoft,
              child: Text(
                data.patientName.isNotEmpty ? data.patientName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: HaniColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.patientName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Shared care information · Alzheimer stage: ' + data.stage,
                    style: const TextStyle(color: HaniColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _InfoBanner(
          icon: Icons.verified_user_outlined,
          title: 'Care information is separated by source',
          text:
              'Professional instructions are shown as verified. Caregiver observations remain observations.',
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Medications',
          action: data.medications.isEmpty ? null : '${data.medications.length} active',
        ),
        const SizedBox(height: 10),
        if (data.medications.isEmpty)
          const _EmptyCard(
            text: 'No active medication information is loaded for this demo patient.',
          )
        else
          ...data.medications.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: med['verified'] == true
                        ? HaniColors.primarySoft
                        : const Color(0xFFFFF3E6),
                    child: Icon(
                      Icons.medication_outlined,
                      color: med['verified'] == true
                          ? HaniColors.primary
                          : HaniColors.warning,
                    ),
                  ),
                  title: Text(
                    med['medication_name']?.toString() ?? 'Medication',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      med['dose_text']?.toString(),
                      med['schedule_text']?.toString(),
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                  ),
                  trailing: med['verified'] == true
                      ? const Icon(Icons.verified_rounded, color: HaniColors.primary)
                      : const Icon(Icons.info_outline_rounded),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Professional instructions',
          action: data.instructions.isEmpty ? null : '${data.instructions.length}',
        ),
        const SizedBox(height: 10),
        if (data.instructions.isEmpty)
          const _EmptyCard(
            text: 'No verified professional instructions are loaded yet.',
          )
        else
          ...data.instructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 17, color: HaniColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Professional instruction',
                            style: TextStyle(
                              color: HaniColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        instruction['title']?.toString() ?? 'Instruction',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        instruction['body']?.toString() ?? '',
                        style: const TextStyle(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Recent care timeline',
          action: '${data.sharedIncidents.length} shared',
        ),
        const SizedBox(height: 10),
        if (data.incidents.isEmpty)
          const _EmptyCard(text: 'No incidents have been recorded yet.')
        else
          ...data.incidents.take(8).map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IncidentCard(incident: incident),
            ),
          ),
        const SizedBox(height: 18),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context.push('/hani'),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: HaniColors.primarySoft,
                    child: Icon(Icons.auto_awesome_rounded, color: HaniColors.primary),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Something changed?', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text(
                          'Tell Hani what you noticed. It can help structure a private incident draft.',
                          style: TextStyle(color: HaniColors.muted, height: 1.35),
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
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});
  final Map<String, dynamic> incident;

  @override
  Widget build(BuildContext context) {
    final private = incident['visibility'] == 'private_draft';
    final support =
        incident['support_level']?.toString().replaceAll('_', ' ') ?? 'routine';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  private ? Icons.lock_outline_rounded : Icons.groups_outlined,
                  size: 17,
                  color: private ? HaniColors.muted : HaniColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  private ? 'Private draft' : 'Shared care timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: private ? HaniColors.muted : HaniColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  support,
                  style: const TextStyle(fontSize: 11.5, color: HaniColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              incident['title']?.toString() ?? 'Care incident',
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              incident['summary']?.toString() ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.4),
            ),
            if (private) ...[
              const SizedBox(height: 9),
              TextButton.icon(
                onPressed: () => context.push('/hani'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Review and share with Hani'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HaniColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HaniColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(color: HaniColors.muted, fontSize: 12),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Text(text, style: const TextStyle(color: HaniColors.muted)),
      ),
    );
  }
}
