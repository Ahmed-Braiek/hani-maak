import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context_provider.dart';

class CareCircleScreen extends ConsumerWidget {
  const CareCircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: () => ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: const Text('Retry'),
        ),
      ),
      data: (data) {
        final members = data.careCircleMembers;
        final ownId = data.caregiver['id']?.toString();
        final ownTasks = data.openTasks.where((t) => t['assigned_to_profile_id']?.toString() == ownId).toList();
        var weight = 0.0;
        for (final task in ownTasks) {
          if (task['effort_weight'] is num) weight += (task['effort_weight'] as num).toDouble();
        }
        final load = weight >= 5 ? 'Heavy week' : weight >= 2 ? 'Moderate week' : 'Light week';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text('Care Circle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Coordinate care for ' + data.patientName + ' without keeping score.', style: const TextStyle(color: HaniColors.muted)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: HaniColors.primarySoft, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  const Icon(Icons.balance_rounded, color: HaniColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Your current care load', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(load, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ])),
                  Text(ownTasks.length.toString() + ' open', style: const TextStyle(color: HaniColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('People', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...members.map((member) {
              final profile = member['profile'] is Map ? Map<String,dynamic>.from(member['profile'] as Map) : <String,dynamic>{};
              final name = profile['full_name']?.toString() ?? 'Caregiver';
              final current = member['profile_id']?.toString() == ownId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: current ? HaniColors.primary : HaniColors.primarySoft,
                    foregroundColor: current ? Colors.white : HaniColors.primary,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(current ? 'Primary caregiver · You' : (member['member_role']?.toString() ?? 'Caregiver')),
                )),
              );
            }),
            const SizedBox(height: 10),
            const Text('Responsibilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...data.openTasks.take(6).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: const CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(Icons.task_alt_outlined, color: HaniColors.primary),
                ),
                title: Text(task['title']?.toString() ?? 'Care task', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(task['difficulty']?.toString() ?? 'routine'),
              )),
            )),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push('/hani'),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: HaniColors.warm, child: Icon(Icons.auto_awesome_rounded, color: HaniColors.warning)),
                    SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Need someone to take over a task?', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Hani can help you ask another caregiver privately and clearly.', style: TextStyle(color: HaniColors.muted)),
                    ])),
                    Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
