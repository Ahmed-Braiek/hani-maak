import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class CareHubScreen extends ConsumerWidget {
  const CareHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caregiverContextProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Care Hub')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Care Hub unavailable.')),
        data: (data) {
          final upcomingMedication = data.medicationEvents.where((item) {
            final at =
                DateTime.tryParse(item['scheduled_for']?.toString() ?? '');
            return item['status'] == 'pending' &&
                at != null &&
                at.isAfter(DateTime.now());
          }).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
            children: [
              HaniGradientCard(
                gradient: HaniGradients.hero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HaniPill(
                      label: 'CARE OPERATIONS',
                      icon: Icons.hub_outlined,
                      background: Color(0x2AFFFFFF),
                      foreground: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Everything around ${data.patientName}, in one place.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Medication, appointments, activity, care tasks, professional instructions, documents, summaries and reminders stay connected to the same patient context.',
                      style: TextStyle(
                        color: Color(0xFFEAF6FF),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _MetricStrip(
                items: [
                  (
                    Icons.medication_outlined,
                    '${data.medications.length}',
                    'medications',
                  ),
                  (
                    Icons.alarm_outlined,
                    '$upcomingMedication',
                    'doses due',
                  ),
                  (
                    Icons.task_alt_outlined,
                    '${data.openTasks.length}',
                    'open tasks',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const HaniSectionHeader(
                title: 'Manage care',
                subtitle: 'Every card opens a working care flow',
              ),
              const SizedBox(height: 10),
              _HubCard(
                icon: Icons.medication_outlined,
                title: 'Medication',
                body:
                    'Add manually, scan prescription or box, review OCR, reminders and adherence history.',
                badge: '${data.medications.length}',
                onTap: () => context.push('/medications'),
              ),
              _HubCard(
                icon: Icons.favorite_border_rounded,
                title: 'Patient activity',
                body:
                    'Familiar people, places, routines, music and memory sessions.',
                badge: '${data.memoryItems.length}',
                onTap: () => context.push('/activity'),
              ),
              _HubCard(
                icon: Icons.calendar_month_outlined,
                title: 'Appointments',
                body:
                    'Upcoming care appointments and reminders in the patient timeline.',
                badge: '${data.appointments.length}',
                onTap: () => context.push('/patient'),
              ),
              _HubCard(
                icon: Icons.groups_outlined,
                title: 'Family & Care Circle',
                body:
                    'Responsibilities, requests, workload and shared care coordination.',
                badge: '${data.careCircleMembers.length}',
                onTap: () => context.go('/circle'),
              ),
              _HubCard(
                icon: Icons.description_outlined,
                title: 'Important documents',
                body:
                    'Prescription scans and reviewed care documents linked to the patient.',
                badge: '${data.careDocuments.length}',
                onTap: () => context.push('/medications'),
              ),
              _HubCard(
                icon: Icons.summarize_outlined,
                title: 'Care summary',
                body:
                    'Create a daily or weekly summary and deliver it through WhatsApp when configured.',
                badge: '${data.summaryDeliveries.length}',
                onTap: () => context.push('/care-summary'),
              ),
              _HubCard(
                icon: Icons.support_agent_outlined,
                title: 'Professional support',
                body:
                    'Call, WhatsApp or request an appointment using minimum-necessary context.',
                badge: '${data.professionals.length}',
                onTap: () => context.push('/handoff'),
              ),
              _HubCard(
                icon: Icons.notifications_active_outlined,
                title: 'Reminders & notifications',
                body:
                    'Medication, appointment, care updates and follow-up preferences.',
                badge: '${data.notifications.length}',
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: 20),
              HaniSectionHeader(
                title: 'Useful patient insights',
                subtitle:
                    data.patterns.isEmpty ? 'No repeated pattern yet' : null,
              ),
              const SizedBox(height: 10),
              if (data.patterns.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Hani Maak will surface repeated shared-care patterns here without turning them into diagnoses.',
                      style: TextStyle(
                        color: HaniColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                ...data.patterns.take(6).map(
                      (pattern) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: HaniColors.primarySoft,
                            child: Icon(
                              Icons.insights_outlined,
                              color: HaniColors.primary,
                            ),
                          ),
                          title: Text(
                            _patternTitle(pattern['type']?.toString()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: const Text(
                            'Context signal only · not a diagnosis',
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

  static String _patternTitle(String? value) => switch (value) {
        'caregiver_strain' => 'Caregiver load has been heavier recently',
        'repeated_incident' => 'A care situation has repeated this week',
        'repeated_declined_requests' =>
          'Some Care Circle requests were declined',
        _ => 'A repeated care pattern is visible',
      };
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HaniColors.line),
                ),
                child: Column(
                  children: [
                    Icon(items[i].$1, color: HaniColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      items[i].$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: HaniColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: HaniColors.primarySoft,
                    child: Icon(icon, color: HaniColors.primary),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            color: HaniColors.muted,
                            height: 1.4,
                            fontSize: 12.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HaniPill(
                    label: badge,
                    background: HaniColors.primarySoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
