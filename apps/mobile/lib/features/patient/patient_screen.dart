import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton.icon(
          onPressed: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ),
      data: (data) => _PatientContent(data: data, language: language),
    );
  }
}

class _PatientContent extends StatelessWidget {
  const _PatientContent({required this.data, required this.language});
  final CaregiverContext data;
  final HaniLanguage language;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
      children: [
        HaniPageHeader(
          title: data.patientName,
          subtitle: switch (language) {
            HaniLanguage.tounsi =>
              'معلومات رعاية مشتركة · المرحلة: ${data.stage}',
            HaniLanguage.french =>
              'Informations partagées · Stade : ${data.stage}',
            HaniLanguage.english =>
              'Shared care information · Stage: ${data.stage}',
          },
          trailing: CircleAvatar(
            radius: 28,
            backgroundColor: HaniColors.primarySoft,
            child: Text(
              data.patientName.isEmpty ? 'P' : data.patientName[0].toUpperCase(),
              style: const TextStyle(
                color: HaniColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        HaniGradientCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: HaniColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  switch (language) {
                    HaniLanguage.tounsi =>
                      'تعليمات المختص واضحة كمعلومة موثّقة. ملاحظات العائلة تبقى ملاحظات وما تتخلطش بالتشخيص.',
                    HaniLanguage.french =>
                      'Les instructions professionnelles sont identifiées comme vérifiées. Les observations familiales restent des observations.',
                    HaniLanguage.english =>
                      'Professional instructions are clearly verified. Family observations remain observations, not diagnoses.',
                  },
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        HaniSectionHeader(
          title: language == HaniLanguage.french
              ? 'Médicaments'
              : language == HaniLanguage.tounsi
                  ? 'الأدوية'
                  : 'Medications',
          subtitle: language == HaniLanguage.tounsi
              ? 'هاني ما يبدّلش الجرعة ولا التوقيت.'
              : language == HaniLanguage.french
                  ? 'Hani ne modifie jamais dose ou horaire.'
                  : 'Hani never changes dose or timing.',
          action: data.medications.isEmpty ? null : '${data.medications.length}',
        ),
        const SizedBox(height: 10),
        if (data.medications.isEmpty)
          const _Empty(text: 'No active medication information.')
        else
          ...data.medications.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MedicationCard(med: med),
            ),
          ),
        const SizedBox(height: 16),
        HaniSectionHeader(
          title: language == HaniLanguage.french
              ? 'Instructions vérifiées'
              : language == HaniLanguage.tounsi
                  ? 'تعليمات المختص'
                  : 'Verified instructions',
          action: '${data.instructions.length}',
        ),
        const SizedBox(height: 10),
        if (data.instructions.isEmpty)
          const _Empty(text: 'No verified professional instructions yet.')
        else
          ...data.instructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InstructionCard(instruction: instruction),
            ),
          ),
        const SizedBox(height: 16),
        HaniSectionHeader(
          title: language == HaniLanguage.french
              ? 'Chronologie récente'
              : language == HaniLanguage.tounsi
                  ? 'آخر الملاحظات'
                  : 'Recent care timeline',
          subtitle: '${data.sharedIncidents.length} shared',
        ),
        const SizedBox(height: 10),
        if (data.incidents.isEmpty)
          const _Empty(text: 'No incidents recorded yet.')
        else
          ...data.incidents.take(8).map(
                (incident) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IncidentCard(incident: incident),
                ),
              ),
        const SizedBox(height: 18),
        HaniGradientCard(
          onTap: () => context.push('/hani'),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: HaniColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language == HaniLanguage.french
                      ? 'Quelque chose a changé ? Dites-le à Hani.'
                      : language == HaniLanguage.tounsi
                          ? 'تبدّل شيء؟ احكيه لهاني وخليه يرتّبلك الملاحظة.'
                          : 'Something changed? Tell Hani and structure a private draft.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.med});
  final Map<String, dynamic> med;

  @override
  Widget build(BuildContext context) {
    final verified = med['verified'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  verified ? HaniColors.primarySoft : HaniColors.warm,
              child: Icon(
                Icons.medication_outlined,
                color: verified ? HaniColors.primary : HaniColors.warning,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['medication_name']?.toString() ?? 'Medication',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      med['dose_text']?.toString(),
                      med['schedule_text']?.toString(),
                    ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      color: HaniColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              verified ? Icons.verified_rounded : Icons.info_outline_rounded,
              color: verified ? HaniColors.primary : HaniColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.instruction});
  final Map<String, dynamic> instruction;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HaniPill(
                label: 'VERIFIED',
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 11),
              Text(
                instruction['title']?.toString() ?? 'Instruction',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                instruction['body']?.toString() ?? '',
                style: const TextStyle(height: 1.45),
              ),
            ],
          ),
        ),
      );
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});
  final Map<String, dynamic> incident;

  @override
  Widget build(BuildContext context) {
    final private = incident['visibility'] == 'private_draft';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: private ? () => context.push('/hani') : null,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HaniPill(
                label: private ? 'PRIVATE DRAFT' : 'CARE TIMELINE',
                icon: private
                    ? Icons.lock_outline_rounded
                    : Icons.groups_outlined,
                background: private ? HaniColors.warm : HaniColors.primarySoft,
                foreground:
                    private ? HaniColors.warning : HaniColors.primaryDeep,
              ),
              const SizedBox(height: 10),
              Text(
                incident['title']?.toString() ?? 'Care incident',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                incident['summary']?.toString() ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Text(text, style: const TextStyle(color: HaniColors.muted)),
        ),
      );
}
