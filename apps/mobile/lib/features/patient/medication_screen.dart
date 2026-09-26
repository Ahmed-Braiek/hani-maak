import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../care/care_workflow_api.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _manual() async {
    final draft = await _editMedication(
      context,
      const <String, dynamic>{},
      source: 'manual',
    );
    if (draft == null) return;
    await _saveDraft(draft);
  }

  Future<void> _scan(String mode) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1800,
    );
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final lower = file.name.toLowerCase();
      final mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final result = await CareWorkflowApi().run(
        'analyze_medication_image',
        args: {
          'mode': mode,
          'imageDataUrl': dataUrl,
        },
      );
      final extraction = result['extraction'] is Map
          ? Map<String, dynamic>.from(result['extraction'] as Map)
          : <String, dynamic>{};
      final meds = (extraction['medications'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;
      if (meds.isEmpty) {
        _message(
          'No medication could be read confidently. Try a clearer image or add it manually.',
        );
        return;
      }

      await CareWorkflowApi().run(
        'save_document',
        args: {
          'documentType':
              mode == 'medication_box' ? 'medication_box' : 'prescription',
          'title': mode == 'medication_box'
              ? 'Medication box scan'
              : 'Prescription scan',
          'fileName': file.name,
          'extractedText':
              (extraction['visibleText'] as List? ?? const []).join('\n'),
          'extraction': extraction,
          'reviewed': false,
        },
      );

      for (final candidate in meds) {
        if (!mounted) return;
        final draft = await _editMedication(
          context,
          candidate,
          source: mode,
        );
        if (draft != null) {
          await _saveDraft(draft, refresh: false);
        }
      }
      await ref.read(caregiverContextProvider.notifier).refreshContext();
      if (mounted) _message('Medication information saved after your review.');
    } catch (error) {
      if (mounted) {
        _message(
          'Scan could not be completed: ${_friendlyError(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDraft(
    Map<String, dynamic> draft, {
    bool refresh = true,
  }) async {
    setState(() => _busy = true);
    try {
      final times = (draft['times'] as List<String>? ?? const []);
      final scheduled = _nextScheduledTimes(times, days: 7);
      await CareWorkflowApi().run(
        'save_medication',
        args: {
          ...draft,
          'scheduledTimes': scheduled,
          'timezone': 'Africa/Tunis',
        },
      );
      if (refresh) {
        await ref.read(caregiverContextProvider.notifier).refreshContext();
      }
      if (mounted && refresh) _message('Medication saved.');
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _nextScheduledTimes(List<String> times, {required int days}) {
    final now = DateTime.now();
    final result = <String>[];
    for (var day = 0; day < days; day++) {
      final date = now.add(Duration(days: day));
      for (final raw in times) {
        final parts = raw.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null ||
            minute == null ||
            hour < 0 ||
            hour > 23 ||
            minute < 0 ||
            minute > 59) {
          continue;
        }
        final when =
            DateTime(date.year, date.month, date.day, hour, minute);
        if (when.isAfter(now)) result.add(when.toUtc().toIso8601String());
      }
    }
    result.sort();
    return result;
  }

  Future<void> _mark(
    String eventId,
    String status, {
    int? delayMinutes,
  }) async {
    setState(() => _busy = true);
    try {
      await CareWorkflowApi().run(
        'record_medication_event',
        args: {
          'eventId': eventId,
          'status': status,
          if (delayMinutes != null) 'delayMinutes': delayMinutes,
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _friendlyError(Object error) {
    final value = error.toString().replaceFirst('Bad state: ', '');
    return switch (value) {
      'medication_ocr_not_configured' =>
        'OCR service is not configured on the server.',
      'medication_image_too_large' =>
        'The image is too large. Try another photo.',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication'),
      ),
      body: Stack(
        children: [
          state.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(caregiverContextProvider.notifier)
                    .refreshContext(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
            data: (data) => _MedicationContent(
              data: data,
              onManual: _manual,
              onScanPrescription: () => _scan('prescription'),
              onScanBox: () => _scan('medication_box'),
              onMark: _mark,
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: .08),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationContent extends StatelessWidget {
  const _MedicationContent({
    required this.data,
    required this.onManual,
    required this.onScanPrescription,
    required this.onScanBox,
    required this.onMark,
  });

  final CaregiverContext data;
  final VoidCallback onManual;
  final VoidCallback onScanPrescription;
  final VoidCallback onScanBox;
  final Future<void> Function(
    String eventId,
    String status, {
    int? delayMinutes,
  }) onMark;

  @override
  Widget build(BuildContext context) {
    final medById = <String, Map<String, dynamic>>{
      for (final item in data.medications)
        if (item['id'] != null) item['id'].toString(): item,
    };
    final now = DateTime.now();
    final upcoming = data.medicationEvents
        .where((item) {
          final at =
              DateTime.tryParse(item['scheduled_for']?.toString() ?? '');
          return item['status'] == 'pending' &&
              at != null &&
              at.isAfter(now);
        })
        .toList()
      ..sort((a, b) => a['scheduled_for']
          .toString()
          .compareTo(b['scheduled_for'].toString()));
    final history = data.medicationEvents
        .where((item) => item['status'] != 'pending')
        .take(12)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        HaniGradientCard(
          gradient: HaniGradients.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HaniPill(
                label: 'MEDICATION WORKFLOW',
                icon: Icons.medication_outlined,
                background: Color(0x2AFFFFFF),
                foreground: Colors.white,
              ),
              const SizedBox(height: 14),
              const Text(
                'Review first. Save second.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Add a medication manually or scan a prescription/box. Hani Maak never changes a dose or treatment instruction.',
                style: TextStyle(
                  color: Color(0xFFEAF6FF),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: HaniColors.primaryDeep,
                      ),
                      onPressed: onManual,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add manually'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.document_scanner_outlined,
                title: 'Scan prescription',
                onTap: onScanPrescription,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan box',
                onTap: onScanBox,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        HaniSectionHeader(
          title: 'Active medications',
          subtitle: '${data.medications.length} recorded',
        ),
        const SizedBox(height: 10),
        if (data.medications.isEmpty)
          const _EmptyCard(
            icon: Icons.medication_outlined,
            text: 'No medication has been added yet.',
          )
        else
          ...data.medications.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: const CircleAvatar(
                    backgroundColor: HaniColors.primarySoft,
                    child: Icon(
                      Icons.medication_outlined,
                      color: HaniColors.primary,
                    ),
                  ),
                  title: Text(
                    med['medication_name']?.toString() ?? 'Medication',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    [
                      med['dose_text']?.toString(),
                      med['schedule_text']?.toString(),
                    ]
                        .whereType<String>()
                        .where((item) => item.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: Icon(
                    med['verified'] == true
                        ? Icons.verified_rounded
                        : Icons.edit_note_rounded,
                    color: med['verified'] == true
                        ? HaniColors.primary
                        : HaniColors.muted,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        HaniSectionHeader(
          title: 'Next doses',
          subtitle: upcoming.isEmpty
              ? 'Nothing pending'
              : '${upcoming.length} upcoming',
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _EmptyCard(
            icon: Icons.schedule_rounded,
            text: 'No medication reminders are currently pending.',
          )
        else
          ...upcoming.take(8).map((event) {
            final med =
                medById[event['patient_medication_id']?.toString()];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DoseCard(
                name:
                    med?['medication_name']?.toString() ?? 'Medication',
                scheduledFor: event['scheduled_for']?.toString(),
                onTaken: () => onMark(event['id'].toString(), 'taken'),
                onSkipped: () =>
                    onMark(event['id'].toString(), 'skipped'),
                onDelayed: () => onMark(
                  event['id'].toString(),
                  'delayed',
                  delayMinutes: 30,
                ),
              ),
            );
          }),
        const SizedBox(height: 18),
        HaniSectionHeader(
          title: 'Medication history',
          subtitle: 'Taken · skipped · delayed',
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          const _EmptyCard(
            icon: Icons.history_rounded,
            text: 'Medication history will appear here.',
          )
        else
          ...history.map((event) {
            final med =
                medById[event['patient_medication_id']?.toString()];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusTint(event['status']?.toString()),
                  child: Icon(
                    _statusIcon(event['status']?.toString()),
                    color: _statusColor(event['status']?.toString()),
                  ),
                ),
                title: Text(
                  med?['medication_name']?.toString() ?? 'Medication',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${event['status'] ?? ''} · ${_dateTime(event['scheduled_for']?.toString())}',
                ),
              ),
            );
          }),
        if (data.careDocuments.isNotEmpty) ...[
          const SizedBox(height: 22),
          HaniSectionHeader(
            title: 'Prescription & scan history',
            subtitle: '${data.careDocuments.length} documents',
          ),
          const SizedBox(height: 10),
          ...data.careDocuments.take(6).map(
                (doc) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: HaniColors.primarySoft,
                      child: Icon(
                        Icons.description_outlined,
                        color: HaniColors.primary,
                      ),
                    ),
                    title: Text(
                      doc['title']?.toString() ?? 'Care document',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      doc['document_type']?.toString() ?? '',
                    ),
                    trailing: Icon(
                      doc['reviewed'] == true
                          ? Icons.verified_user_outlined
                          : Icons.rate_review_outlined,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  static String _dateTime(String? raw) {
    final value = DateTime.tryParse(raw ?? '')?.toLocal();
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  static Color _statusTint(String? status) => switch (status) {
        'taken' => HaniColors.primarySoft,
        'skipped' => const Color(0xFFFFE7E7),
        _ => HaniColors.warm,
      };

  static Color _statusColor(String? status) => switch (status) {
        'taken' => HaniColors.primary,
        'skipped' => HaniColors.danger,
        _ => HaniColors.warning,
      };

  static IconData _statusIcon(String? status) => switch (status) {
        'taken' => Icons.check_rounded,
        'skipped' => Icons.close_rounded,
        _ => Icons.schedule_rounded,
      };
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(icon, color: HaniColors.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.name,
    required this.scheduledFor,
    required this.onTaken,
    required this.onSkipped,
    required this.onDelayed,
  });

  final String name;
  final String? scheduledFor;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VoidCallback onDelayed;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: HaniColors.primarySoft,
                    child: Icon(
                      Icons.alarm_rounded,
                      color: HaniColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    _MedicationContent._dateTime(scheduledFor),
                    style: const TextStyle(
                      color: HaniColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onTaken,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Taken'),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filledTonal(
                    tooltip: 'Delay 30 minutes',
                    onPressed: onDelayed,
                    icon: const Icon(Icons.schedule_rounded),
                  ),
                  const SizedBox(width: 7),
                  IconButton.outlined(
                    tooltip: 'Skipped',
                    onPressed: onSkipped,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: HaniColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: HaniColors.muted),
                ),
              ),
            ],
          ),
        ),
      );
}

Future<Map<String, dynamic>?> _editMedication(
  BuildContext context,
  Map<String, dynamic> initial, {
  required String source,
}) async {
  String value(String key, [String fallback = '']) =>
      initial[key]?.toString() ?? fallback;

  final name = TextEditingController(text: value('medicationName'));
  final dose = TextEditingController(text: value('doseText'));
  final frequency = TextEditingController(text: value('frequencyText'));
  final duration = TextEditingController(text: value('durationText'));
  final instructions = TextEditingController(text: value('instructions'));
  final times = TextEditingController(
    text: (initial['scheduleTimes'] as List? ?? const []).join(', '),
  );

  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HaniSectionHeader(
              title: 'Review medication',
              subtitle:
                  'Correct anything OCR read incorrectly before saving.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Medication name',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dose,
              decoration: const InputDecoration(
                labelText: 'Dose / amount',
                hintText: 'Only what is written or known',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                hintText: 'e.g. morning and evening',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: duration,
              decoration: const InputDecoration(
                labelText: 'Treatment duration',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: times,
              decoration: const InputDecoration(
                labelText: 'Reminder times',
                hintText: '08:00, 20:00',
                prefixIcon: Icon(Icons.alarm_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instructions,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Instructions / notes',
              ),
            ),
            const SizedBox(height: 12),
            const HaniGradientCard(
              gradient: HaniGradients.wellbeing,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: HaniColors.warning,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hani Maak records what you confirm. It does not infer or modify a prescribed dose, schedule, or treatment.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                final parsedTimes = times.text
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
                        .hasMatch(item))
                    .toList();
                Navigator.pop(context, {
                  'medicationName': name.text.trim(),
                  'doseText': dose.text.trim(),
                  'frequencyText': frequency.text.trim(),
                  'durationText': duration.text.trim(),
                  'instructions': instructions.text.trim(),
                  'times': parsedTimes,
                  'source': source,
                });
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save reviewed medication'),
            ),
          ],
        ),
      ),
    ),
  );

  name.dispose();
  dose.dispose();
  frequency.dispose();
  duration.dispose();
  instructions.dispose();
  times.dispose();
  return result;
}
