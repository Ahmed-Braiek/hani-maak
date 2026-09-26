import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../care/care_workflow_api.dart';
import '../context/caregiver_context_provider.dart';

class PatientActivityScreen extends ConsumerStatefulWidget {
  const PatientActivityScreen({super.key});

  @override
  ConsumerState<PatientActivityScreen> createState() =>
      _PatientActivityScreenState();
}

class _PatientActivityScreenState
    extends ConsumerState<PatientActivityScreen> {
  bool busy = false;

  Future<void> _start(Map<String, dynamic> item) async {
    final started = DateTime.now();
    final response = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title']?.toString() ?? 'Activity',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if ((item['prompt']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item['prompt'].toString(),
                  style: const TextStyle(
                    color: HaniColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'How did the activity feel?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResponseChip(
                    label: 'Engaged',
                    icon: Icons.visibility_outlined,
                    onTap: () => Navigator.pop(context, 'engaged'),
                  ),
                  _ResponseChip(
                    label: 'Calm',
                    icon: Icons.self_improvement_outlined,
                    onTap: () => Navigator.pop(context, 'calm'),
                  ),
                  _ResponseChip(
                    label: 'Neutral',
                    icon: Icons.remove_rounded,
                    onTap: () => Navigator.pop(context, 'neutral'),
                  ),
                  _ResponseChip(
                    label: 'Stopped',
                    icon: Icons.stop_circle_outlined,
                    onTap: () => Navigator.pop(context, 'stopped'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (response == null) return;

    setState(() => busy = true);
    try {
      await CareWorkflowApi().run(
        'record_patient_activity',
        args: {
          'memoryItemId': item['id'],
          'activityType': item['item_type'] ?? 'reminiscence',
          'startedAt': started.toUtc().toIso8601String(),
          'endedAt': DateTime.now().toUtc().toIso8601String(),
          'responseLabel': response,
          'metadata': {
            'title': item['title'],
            'source': 'patient_activity',
          },
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity saved to the care history.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverContextProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Patient activity')),
      body: Stack(
        children: [
          state.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Patient activity is unavailable.'),
            ),
            data: (data) {
              final items =
                  data.memoryItems.isEmpty ? _fallbackItems : data.memoryItems;
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
                children: [
                  HaniGradientCard(
                    gradient: HaniGradients.hero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HaniPill(
                          label: 'FAMILIARITY FIRST',
                          icon: Icons.favorite_outline_rounded,
                          background: Color(0x2AFFFFFF),
                          foreground: Colors.white,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Moments that already mean something to ${data.patientName}.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'People, places, routines, music and memories can be used by a caregiver as gentle conversation or reminiscence cues. This is not a diagnostic exercise.',
                          style: TextStyle(
                            color: Color(0xFFEAF6FF),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  HaniSectionHeader(
                    title: 'Familiar library',
                    subtitle: '${items.length} care memories',
                  ),
                  const SizedBox(height: 10),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MemoryCard(
                        item: item,
                        onTap: () => _start(item),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  HaniSectionHeader(
                    title: 'Recent activity',
                    subtitle:
                        '${data.activitySessions.length} recorded sessions',
                  ),
                  const SizedBox(height: 10),
                  if (data.activitySessions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Completed activities will appear here.',
                          style: TextStyle(color: HaniColors.muted),
                        ),
                      ),
                    )
                  else
                    ...data.activitySessions.take(10).map(
                          (session) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: HaniColors.primarySoft,
                                child: Icon(
                                  _iconFor(
                                    session['activity_type']?.toString(),
                                  ),
                                  color: HaniColors.primary,
                                ),
                              ),
                              title: Text(
                                session['metadata'] is Map
                                    ? (session['metadata']['title']
                                            ?.toString() ??
                                        'Patient activity')
                                    : 'Patient activity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  session['response_label']?.toString(),
                                  _shortDate(session['started_at']?.toString()),
                                ]
                                    .whereType<String>()
                                    .where((item) => item.isNotEmpty)
                                    .join(' · '),
                              ),
                            ),
                          ),
                        ),
                ],
              );
            },
          ),
          if (busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x14000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  static String _shortDate(String? raw) {
    final value = DateTime.tryParse(raw ?? '')?.toLocal();
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  static IconData _iconFor(String? type) => switch (type) {
        'person' => Icons.people_outline_rounded,
        'place' => Icons.place_outlined,
        'routine' => Icons.repeat_rounded,
        'music' => Icons.music_note_outlined,
        'memory' => Icons.photo_album_outlined,
        _ => Icons.local_activity_outlined,
      };

  static const _fallbackItems = <Map<String, dynamic>>[
    {
      'id': null,
      'item_type': 'person',
      'title': 'Mariem and Sami',
      'subtitle': 'Familiar family faces',
      'prompt': 'Who is in this family memory? What would you like to tell them?',
    },
    {
      'id': null,
      'item_type': 'place',
      'title': 'The family kitchen',
      'subtitle': 'Morning coffee and familiar routines',
      'prompt': 'What do you usually like to prepare here in the morning?',
    },
    {
      'id': null,
      'item_type': 'routine',
      'title': 'Morning window routine',
      'subtitle': 'Open the curtains, tea, then a quiet sit',
      'prompt': 'Would you like to do the first familiar step together?',
    },
    {
      'id': null,
      'item_type': 'music',
      'title': 'Familiar Tunisian music',
      'subtitle': 'A calm playlist the family recognizes',
      'prompt': 'Would you like to listen for a few minutes?',
    },
    {
      'id': null,
      'item_type': 'memory',
      'title': 'Family lunch memories',
      'subtitle': 'Shared stories around the table',
      'prompt': 'Who used to sit next to you at family lunches?',
    },
  ];
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = item['item_type']?.toString();
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: HaniGradients.soft,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  _PatientActivityScreenState._iconFor(type),
                  color: HaniColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? 'Familiar memory',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle']?.toString() ?? '',
                      style: const TextStyle(
                        color: HaniColors.muted,
                        height: 1.35,
                        fontSize: 12.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseChip extends StatelessWidget {
  const _ResponseChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 17),
        label: Text(label),
        onPressed: onTap,
      );
}
