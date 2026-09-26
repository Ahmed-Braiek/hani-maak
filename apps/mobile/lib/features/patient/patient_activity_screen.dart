import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class PatientActivityScreen extends ConsumerStatefulWidget {
  const PatientActivityScreen({super.key});

  @override
  ConsumerState<PatientActivityScreen> createState() =>
      _PatientActivityScreenState();
}

class _PatientActivityScreenState
    extends ConsumerState<PatientActivityScreen> {
  String? activeId;
  DateTime? startedAt;
  bool busy = false;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  IconData iconFor(String type) => switch (type) {
        'person' => Icons.people_alt_outlined,
        'place' => Icons.place_outlined,
        'routine' => Icons.wb_sunny_outlined,
        'music' => Icons.music_note_outlined,
        'memory' => Icons.auto_stories_outlined,
        'activity' => Icons.extension_outlined,
        _ => Icons.favorite_outline_rounded,
      };

  Future<void> startItem(Map<String, dynamic> item) async {
    if (activeId == item['id']?.toString()) {
      await finishItem(item);
      return;
    }
    setState(() {
      activeId = item['id']?.toString();
      startedAt = DateTime.now();
    });
  }

  Future<void> finishItem(Map<String, dynamic> item) async {
    final response = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How did the moment feel?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a simple family observation, not a clinical score.',
              style: TextStyle(color: HaniColors.muted),
            ),
            const SizedBox(height: 14),
            ...[
              ('calm', Icons.spa_outlined, 'Calm'),
              ('engaged', Icons.visibility_outlined, 'Engaged'),
              ('neutral', Icons.remove_circle_outline_rounded, 'Neutral'),
              ('uncomfortable', Icons.sentiment_dissatisfied_outlined,
                  'Uncomfortable — stop'),
            ].map(
              (choice) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(choice.$2, color: HaniColors.primary),
                ),
                title: Text(choice.$3),
                onTap: () => Navigator.pop(context, choice.$1),
              ),
            ),
          ],
        ),
      ),
    );
    if (response == null) return;

    setState(() => busy = true);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'record_patient_activity',
        args: {
          'memoryItemId': item['id'],
          'activityType': item['item_type'] ?? 'activity',
          'startedAt': (startedAt ?? DateTime.now()).toIso8601String(),
          'endedAt': DateTime.now().toIso8601String(),
          'responseLabel': response,
          'note': 'Caregiver-recorded patient activity.',
          'metadata': {
            'title': item['title'],
            'nonClinical': true,
          },
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
      if (mounted) {
        setState(() {
          activeId = null;
          startedAt = null;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'لحظة مع المريض', 'نشاط مع المريض',
            'Patient activity', 'Activité patient')),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Activity unavailable.')),
        data: (data) {
          final name = data.patientName;
          final items = data.memoryItems;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              HaniGradientCard(
                gradient: HaniGradients.soft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.spa_outlined, color: HaniColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(language, 'نشاط خفيف، موش اختبار',
                                'نشاط لطيف وليس اختبارًا',
                                'A gentle moment, not a test',
                                'Un moment doux, pas un test'),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t(
                              language,
                              'استعمل وجوه، بلايص، موسيقى وروتين يعرفهم $name. إذا بان الضيق، النشاط يوقف.',
                              'استخدم وجوهًا وأماكن وموسيقى وروتينًا مألوفًا لدى $name، وتوقف إذا ظهر الانزعاج.',
                              'Use people, places, music, and routines familiar to $name. Stop if the moment becomes uncomfortable.',
                              'Utilisez des personnes, lieux, musiques et routines familiers à $name. Arrêtez si le moment devient inconfortable.',
                            ),
                            style: const TextStyle(
                              color: HaniColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No familiar items have been added yet.',
                      style: TextStyle(color: HaniColors.muted),
                    ),
                  ),
                )
              else
                ...items.map((item) {
                  final id = item['id']?.toString();
                  final selected = id != null && activeId == id;
                  final image = item['image_url']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      decoration: BoxDecoration(
                        color:
                            selected ? HaniColors.primarySoft : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color:
                              selected ? HaniColors.primary : HaniColors.line,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: busy ? null : () => startItem(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (image.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 16 / 7,
                                child: Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: HaniColors.primarySoft,
                                    child: Icon(
                                      iconFor(item['item_type']?.toString() ?? ''),
                                      size: 44,
                                      color: HaniColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (image.isEmpty)
                                    CircleAvatar(
                                      backgroundColor: selected
                                          ? HaniColors.primary
                                          : HaniColors.primarySoft,
                                      child: Icon(
                                        iconFor(
                                          item['item_type']?.toString() ?? '',
                                        ),
                                        color: selected
                                            ? Colors.white
                                            : HaniColors.primary,
                                      ),
                                    ),
                                  if (image.isEmpty) const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title']?.toString() ??
                                              'Familiar activity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if ((item['subtitle']?.toString() ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item['subtitle'].toString(),
                                            style: const TextStyle(
                                              color: HaniColors.muted,
                                            ),
                                          ),
                                        ],
                                        if ((item['prompt']?.toString() ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            item['prompt'].toString(),
                                            style:
                                                const TextStyle(height: 1.4),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    selected
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline_rounded,
                                    color: HaniColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              HaniSectionHeader(
                title: t(language, 'آخر الأنشطة', 'آخر الأنشطة',
                    'Recent activity', 'Activité récente'),
                subtitle: '${data.activitySessions.length} sessions',
              ),
              const SizedBox(height: 10),
              ...data.activitySessions.take(8).map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: HaniColors.primarySoft,
                            child: Icon(Icons.history_rounded,
                                color: HaniColors.primary),
                          ),
                          title: Text(
                            session['activity_type']?.toString() ??
                                'Patient activity',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            [
                              session['response_label']?.toString(),
                              session['started_at']?.toString(),
                            ].whereType<String>().join(' · '),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
