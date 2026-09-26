import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class CareCircleScreen extends ConsumerWidget {
  const CareCircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton(
          onPressed: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: const Text('Retry'),
        ),
      ),
      data: (data) {
        final members = data.careCircleMembers;
        final ownId = data.caregiver['id']?.toString();
        final ownTasks = data.openTasks
            .where((t) => t['assigned_to_profile_id']?.toString() == ownId)
            .toList();
        final weight = ownTasks.fold<double>(
          0,
          (sum, task) =>
              sum + ((task['effort_weight'] as num?)?.toDouble() ?? 1),
        );
        final load = weight >= 5
            ? 'Heavy'
            : weight >= 2
                ? 'Moderate'
                : 'Light';

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
          children: [
            HaniPageHeader(
              title: language == HaniLanguage.french
                  ? 'Cercle de soins'
                  : language == HaniLanguage.tounsi
                      ? 'دائرة العائلة'
                      : 'Care Circle',
              subtitle: language == HaniLanguage.french
                  ? 'Coordonner les soins de ${data.patientName}, sans jugement ni classement.'
                  : language == HaniLanguage.tounsi
                      ? 'نظّموا رعاية ${data.patientName} بلا لوم وبلا حساب شكون عمل أكثر.'
                      : 'Coordinate care for ${data.patientName} without blame or scorekeeping.',
            ),
            const SizedBox(height: 20),
            HaniGradientCard(
              gradient:
                  weight >= 5 ? HaniGradients.wellbeing : HaniGradients.soft,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(
                      weight >= 5
                          ? Icons.battery_2_bar_rounded
                          : Icons.balance_rounded,
                      color:
                          weight >= 5 ? HaniColors.warning : HaniColors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == HaniLanguage.french
                              ? 'Votre charge actuelle'
                              : language == HaniLanguage.tounsi
                                  ? 'حمل الرعاية متاعك'
                                  : 'Your current care load',
                          style: const TextStyle(
                            color: HaniColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$load · ${ownTasks.length} open',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/hani'),
                    child: Text(
                      language == HaniLanguage.french
                          ? 'Aide'
                          : language == HaniLanguage.tounsi
                              ? 'عاونّي'
                              : 'Redistribute',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            HaniSectionHeader(
              title: language == HaniLanguage.french
                  ? 'Les personnes'
                  : language == HaniLanguage.tounsi
                      ? 'شكون معاكم'
                      : 'People',
              subtitle: '${members.length} active',
            ),
            const SizedBox(height: 10),
            ...members.map(
              (member) {
                final profile = member['profile'] is Map
                    ? Map<String, dynamic>.from(member['profile'] as Map)
                    : <String, dynamic>{};
                final name =
                    profile['full_name']?.toString() ?? 'Caregiver';
                final current =
                    member['profile_id']?.toString() == ownId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: current
                            ? HaniColors.primary
                            : HaniColors.primarySoft,
                        foregroundColor:
                            current ? Colors.white : HaniColors.primary,
                        child: Text(name.isEmpty ? 'C' : name[0].toUpperCase()),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        current
                            ? (language == HaniLanguage.french
                                ? 'Aidant principal · Vous'
                                : language == HaniLanguage.tounsi
                                    ? 'المرافق الرئيسي · إنت'
                                    : 'Primary caregiver · You')
                            : (member['member_role']?.toString() ??
                                'Caregiver'),
                      ),
                      trailing:
                          current ? const HaniPill(label: 'YOU') : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            HaniSectionHeader(
              title: language == HaniLanguage.french
                  ? 'Responsabilités'
                  : language == HaniLanguage.tounsi
                      ? 'المسؤوليات'
                      : 'Responsibilities',
              subtitle: '${data.openTasks.length} open',
            ),
            const SizedBox(height: 10),
            ...data.openTasks.take(8).map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Card(
                      child: ListTile(
                        onTap: () => context.push('/hani'),
                        contentPadding: const EdgeInsets.all(15),
                        leading: const CircleAvatar(
                          backgroundColor: HaniColors.primarySoft,
                          child: Icon(
                            Icons.task_alt_outlined,
                            color: HaniColors.primary,
                          ),
                        ),
                        title: Text(
                          task['title']?.toString() ?? 'Care task',
                          style:
                              const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle:
                            Text(task['difficulty']?.toString() ?? 'routine'),
                        trailing:
                            const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            HaniGradientCard(
              gradient: HaniGradients.hero,
              onTap: () => context.push('/hani'),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0x2AFFFFFF),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      language == HaniLanguage.french
                          ? 'Besoin de souffler ? Hani peut vous aider à demander du relais.'
                          : language == HaniLanguage.tounsi
                              ? 'تعبت؟ هاني ينجم يعاونك تطلب من شخص آخر يشدّ مهمّة.'
                              : 'Need relief? Hani can help you ask someone to take a task.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
