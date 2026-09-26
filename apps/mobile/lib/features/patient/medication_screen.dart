import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  final picker = ImagePicker();
  bool busy = false;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  Future<void> refresh() async {
    await ref.read(caregiverContextProvider.notifier).refreshContext();
  }

  Future<void> mark(
    String medicationId,
    String status, {
    String? note,
  }) async {
    setState(() => busy = true);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'record_medication_event',
        args: {
          'medicationId': medicationId,
          'status': status,
          'scheduledFor': DateTime.now().toIso8601String(),
          'actualAt': DateTime.now().toIso8601String(),
          if (note != null) 'note': note,
        },
      );
      await refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medication marked $status.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update medication: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addManual(HaniLanguage language) async {
    final name = TextEditingController();
    final dose = TextEditingController();
    final schedule = TextEditingController();
    final instructions = TextEditingController();
    final time = TextEditingController(text: '20:00');

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                t(language, 'دواء جديد', 'دواء جديد', 'Add medication',
                    'Ajouter un médicament'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter what is written on the prescription. Hani never changes a dose or treatment.',
                style: TextStyle(color: HaniColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
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
                  labelText: 'Dose as written',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: schedule,
                decoration: const InputDecoration(
                  labelText: 'Frequency / schedule',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: time,
                decoration: const InputDecoration(
                  labelText: 'Reminder time (HH:mm)',
                  prefixIcon: Icon(Icons.notifications_active_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: instructions,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions exactly as recorded',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Review and save'),
              ),
            ],
          ),
        );
      },
    );

    if (save != true || name.text.trim().isEmpty) return;

    setState(() => busy = true);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'create_medication',
        args: {
          'medicationName': name.text.trim(),
          'doseText': dose.text.trim(),
          'scheduleText': schedule.text.trim(),
          'instructions': instructions.text.trim(),
          'times': time.text.trim().isEmpty ? [] : [time.text.trim()],
          'timezone': 'Africa/Tunis',
          'source': 'manual',
          'verified': false,
        },
      );
      await refresh();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> scanPrescription(HaniLanguage language) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan medication information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(Icons.document_scanner_outlined,
                      color: HaniColors.primary),
                ),
                title: const Text('Take a prescription photo'),
                subtitle: const Text('Camera permission will be requested by the phone.'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(Icons.photo_library_outlined,
                      color: HaniColors.primary),
                ),
                title: const Text('Choose an existing image'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;

    setState(() => busy = true);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.toLowerCase();
      final mime = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final result = await ref.read(caregiverContextApiProvider).ocrPrescription(
            imageBase64: base64Encode(bytes),
            mimeType: mime,
            documentType: 'prescription',
            locale: language.code,
          );

      if (!mounted) return;
      await reviewOcr(
        language: language,
        extraction: result,
        fileName: image.name,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription scan failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reviewOcr({
    required HaniLanguage language,
    required Map<String, dynamic> extraction,
    required String fileName,
  }) async {
    final raw = extraction['medications'];
    final medications = (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medication could be read. Please add it manually.'),
        ),
      );
      return;
    }

    final editors = medications
        .map(
          (m) => _OcrMedicationEditor(
            name: TextEditingController(text: m['name']?.toString() ?? ''),
            dose: TextEditingController(text: m['dose']?.toString() ?? ''),
            frequency:
                TextEditingController(text: m['frequency']?.toString() ?? ''),
            duration:
                TextEditingController(text: m['duration']?.toString() ?? ''),
            instructions:
                TextEditingController(text: m['instructions']?.toString() ?? ''),
          ),
        )
        .toList();

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review OCR before saving'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              const HaniPill(
                label: 'CAREGIVER REVIEW REQUIRED',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                'OCR can make mistakes. Confirm every medication, dose, frequency, and duration against the original prescription.',
                style: TextStyle(color: HaniColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ...List.generate(editors.length, (index) {
                final e = editors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextField(
                            controller: e.name,
                            decoration:
                                const InputDecoration(labelText: 'Medication'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: e.dose,
                            decoration:
                                const InputDecoration(labelText: 'Dose'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: e.frequency,
                            decoration:
                                const InputDecoration(labelText: 'Frequency'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: e.duration,
                            decoration:
                                const InputDecoration(labelText: 'Duration'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: e.instructions,
                            maxLines: 2,
                            decoration:
                                const InputDecoration(labelText: 'Instructions'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('I reviewed this'),
          ),
        ],
      ),
    );

    if (approved != true) {
      for (final e in editors) {
        e.dispose();
      }
      return;
    }

    setState(() => busy = true);
    try {
      for (final e in editors) {
        if (e.name.text.trim().isEmpty) continue;
        await ref.read(caregiverContextApiProvider).action(
          'create_medication',
          args: {
            'medicationName': e.name.text.trim(),
            'doseText': e.dose.text.trim(),
            'scheduleText': e.frequency.text.trim(),
            'instructions': [
              e.instructions.text.trim(),
              if (e.duration.text.trim().isNotEmpty)
                'Duration: ${e.duration.text.trim()}',
            ].where((v) => v.isNotEmpty).join(' · '),
            'source': 'prescription_ocr',
            'verified': false,
          },
        );
      }

      await ref.read(caregiverContextApiProvider).action(
        'save_care_document',
        args: {
          'documentType': 'prescription',
          'title': 'Prescription scan',
          'originalFileName': fileName,
          'extractedText': extraction['rawText']?.toString() ?? '',
          'extraction': extraction,
          'reviewed': true,
        },
      );

      await refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviewed prescription saved to the Care Hub.'),
          ),
        );
      }
    } finally {
      for (final e in editors) {
        e.dispose();
      }
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'الأدوية', 'الأدوية', 'Medication',
            'Médicaments')),
        actions: [
          IconButton(
            tooltip: 'Scan prescription',
            onPressed: busy ? null : () => scanPrescription(language),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => addManual(language),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add medication'),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: OutlinedButton.icon(
            onPressed: refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              HaniGradientCard(
                gradient: HaniGradients.soft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.shield_outlined,
                          color: HaniColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hani helps record and remind. It never changes a medication, dose, timing, crushes, mixes, or substitutes treatment.',
                        style: TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              HaniSectionHeader(
                title: 'Active medication',
                subtitle: '${data.medications.length} recorded',
                action: 'Scan',
                onAction: busy ? null : () => scanPrescription(language),
              ),
              const SizedBox(height: 10),
              if (data.medications.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No medication recorded yet.',
                      style: TextStyle(color: HaniColors.muted),
                    ),
                  ),
                )
              else
                ...data.medications.map(
                  (med) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MedicationCard(
                      medication: med,
                      busy: busy,
                      onTaken: med['id'] == null
                          ? null
                          : () => mark(med['id'].toString(), 'taken'),
                      onSkipped: med['id'] == null
                          ? null
                          : () => mark(med['id'].toString(), 'skipped'),
                      onDelayed: med['id'] == null
                          ? null
                          : () => mark(med['id'].toString(), 'delayed'),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              HaniSectionHeader(
                title: 'Medication history',
                subtitle: '${data.medicationEvents.length} recent events',
              ),
              const SizedBox(height: 10),
              if (data.medicationEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Taken, skipped, or delayed medication events will appear here.',
                      style: TextStyle(color: HaniColors.muted),
                    ),
                  ),
                )
              else
                ...data.medicationEvents.take(20).map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MedicationEvent(
                          event: event,
                          medication: data.medications.firstWhere(
                            (m) =>
                                m['id']?.toString() ==
                                event['patient_medication_id']?.toString(),
                            orElse: () => const <String, dynamic>{},
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 18),
              HaniSectionHeader(
                title: 'Prescription archive',
                subtitle: '${data.careDocuments.length} care documents',
              ),
              const SizedBox(height: 10),
              ...data.careDocuments.take(6).map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: HaniColors.primarySoft,
                            child: Icon(
                              doc['document_type'] == 'prescription'
                                  ? Icons.description_outlined
                                  : Icons.insert_drive_file_outlined,
                              color: HaniColors.primary,
                            ),
                          ),
                          title: Text(
                            doc['title']?.toString() ?? 'Care document',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            doc['reviewed'] == true
                                ? 'Reviewed'
                                : 'Needs review',
                          ),
                          trailing: Icon(
                            doc['reviewed'] == true
                                ? Icons.verified_outlined
                                : Icons.fact_check_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.busy,
    this.onTaken,
    this.onSkipped,
    this.onDelayed,
  });

  final Map<String, dynamic> medication;
  final bool busy;
  final VoidCallback? onTaken;
  final VoidCallback? onSkipped;
  final VoidCallback? onDelayed;

  @override
  Widget build(BuildContext context) {
    final verified = medication['verified'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: verified
                      ? HaniColors.primarySoft
                      : HaniColors.warm,
                  child: Icon(
                    Icons.medication_outlined,
                    color: verified
                        ? HaniColors.primary
                        : HaniColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication['medication_name']?.toString() ??
                            'Medication',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          medication['dose_text']?.toString(),
                          medication['schedule_text']?.toString(),
                        ]
                            .whereType<String>()
                            .where((v) => v.trim().isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(color: HaniColors.muted),
                      ),
                    ],
                  ),
                ),
                HaniPill(
                  label: verified ? 'VERIFIED' : 'REVIEWED',
                  icon: verified
                      ? Icons.verified_rounded
                      : Icons.fact_check_outlined,
                  background: verified
                      ? HaniColors.primarySoft
                      : HaniColors.warm,
                  foreground: verified
                      ? HaniColors.primaryDeep
                      : HaniColors.warning,
                ),
              ],
            ),
            if ((medication['instructions']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                medication['instructions'].toString(),
                style: const TextStyle(height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onTaken,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Taken'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDelayed,
                    child: const Text('Delayed'),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.outlined(
                  tooltip: 'Skipped',
                  onPressed: busy ? null : onSkipped,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationEvent extends StatelessWidget {
  const _MedicationEvent({
    required this.event,
    required this.medication,
  });

  final Map<String, dynamic> event;
  final Map<String, dynamic> medication;

  @override
  Widget build(BuildContext context) {
    final status = event['status']?.toString() ?? 'pending';
    final icon = switch (status) {
      'taken' => Icons.check_circle_outline_rounded,
      'skipped' => Icons.cancel_outlined,
      'delayed' => Icons.schedule_rounded,
      _ => Icons.notifications_none_rounded,
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: HaniColors.primarySoft,
          child: Icon(icon, color: HaniColors.primary),
        ),
        title: Text(
          medication['medication_name']?.toString() ?? 'Medication',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            status.toUpperCase(),
            event['scheduled_for']?.toString(),
          ].whereType<String>().join(' · '),
        ),
      ),
    );
  }
}

class _OcrMedicationEditor {
  _OcrMedicationEditor({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  final TextEditingController name;
  final TextEditingController dose;
  final TextEditingController frequency;
  final TextEditingController duration;
  final TextEditingController instructions;

  void dispose() {
    name.dispose();
    dose.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
  }
}
