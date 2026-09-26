import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class CareCircleScreen extends ConsumerStatefulWidget {
  const CareCircleScreen({super.key});

  @override
  ConsumerState<CareCircleScreen> createState() => _CareCircleScreenState();
}

class _CareCircleScreenState extends ConsumerState<CareCircleScreen> {
  String? busyRequest;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  Future<void> respond(
    String requestId,
    String response, {
    String? alternativeNote,
  }) async {
    setState(() => busyRequest = requestId);
    try {
      await ref.read(caregiverContextApiProvider).action(
        'respond_task_request',
        args: {
          'requestId': requestId,
          'response': response,
          if (alternativeNote != null) 'alternativeNote': alternativeNote,
        },
      );
      await ref.read(caregiverContextProvider.notifier).refreshContext();
    } finally {
      if (mounted) setState(() => busyRequest = null);
    }
  }

  Future<void> proposeAlternative(
    BuildContext context,
    String requestId,
    HaniLanguage language,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          t(language, 'اقترح بديل', 'اقترح بديلًا', 'Propose an alternative',
              'Proposer une alternative'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: t(
              language,
              'مثال: نجم ناخذها غدوة في الصباح',
              'مثال: أستطيع القيام بها غدًا صباحًا',
              'Example: I can take this tomorrow morning',
              'Exemple : je peux m’en charger demain matin',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t(language, 'إلغاء', 'إلغاء', 'Cancel', 'Annuler')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child:
                Text(t(language, 'اقترح', 'اقتراح', 'Propose', 'Proposer')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null && note.trim().isNotEmpty) {
      await respond(requestId, 'alternative', alternativeNote: note.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: OutlinedButton.icon(
          onPressed: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t(language, 'عاود جرّب', 'حاول مجددًا', 'Retry',
              'Réessayer')),
        ),
      ),
      data: (data) {
        final members = data.careCircleMembers;
        final ownId = data.caregiver['id']?.toString();
        final ownTasks = data.openTasks
            .where((task) =>
                task['assigned_to_profile_id']?.toString() == ownId)
            .toList();
        final weight = ownTasks.fold<double>(
          0,
          (sum, task) =>
              sum + ((task['effort_weight'] as num?)?.toDouble() ?? 1),
        );
        final load = weight >= 5
            ? t(language, 'ثقيل', 'مرتفع', 'Heavy', 'Élevée')
            : weight >= 2
                ? t(language, 'متوسط', 'متوسط', 'Moderate', 'Modérée')
                : t(language, 'خفيف', 'خفيف', 'Light', 'Légère');

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
            children: [
              HaniAnimatedEntrance(
                child: HaniPageHeader(
                  title: t(language, 'دائرة العائلة', 'دائرة الرعاية',
                      'Care Circle', 'Cercle de soins'),
                  subtitle: t(
                    language,
                    'نظّموا رعاية ' +
                        data.patientName +
                        ' بلا لوم وبلا حساب شكون عمل أكثر.',
                    'نظّموا رعاية ' +
                        data.patientName +
                        ' دون لوم أو مقارنة بين أفراد العائلة.',
                    'Coordinate care for ' +
                        data.patientName +
                        ' without blame or scorekeeping.',
                    'Coordonner les soins de ' +
                        data.patientName +
                        ', sans jugement ni classement.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              HaniAnimatedEntrance(
                delay: const Duration(milliseconds: 70),
                child: HaniGradientCard(
                  gradient: weight >= 5
                      ? HaniGradients.wellbeing
                      : HaniGradients.soft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(
                          weight >= 5
                              ? Icons.battery_2_bar_rounded
                              : Icons.balance_rounded,
                          color: weight >= 5
                              ? HaniColors.warning
                              : HaniColors.primary,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(language, 'حمل الرعاية متاعك',
                                  'حمل الرعاية الحالي', 'Your current care load',
                                  'Votre charge actuelle'),
                              style: const TextStyle(
                                color: HaniColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              load +
                                  ' · ' +
                                  ownTasks.length.toString() +
                                  ' ' +
                                  t(language, 'مسؤوليات مفتوحة',
                                      'مسؤوليات مفتوحة',
                                      'open responsibilities',
                                      'responsabilités ouvertes'),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: t(language, 'اطلب مساعدة', 'اطلب مساعدة',
                            'Ask for relief', 'Demander du relais'),
                        onPressed: () => context.push('/hani'),
                        icon: const Icon(Icons.handshake_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.incomingTaskRequests.isNotEmpty) ...[
                const SizedBox(height: 24),
                HaniSectionHeader(
                  title: t(language, 'طلبات تستنا فيك', 'طلبات بانتظارك',
                      'Requests waiting for you', 'Demandes en attente'),
                  subtitle: t(
                    language,
                    'إنت تقرّر: اقبل، ارفض، ولا اقترح بديل.',
                    'أنت تقرر: قبول أو رفض أو اقتراح بديل.',
                    'You stay in control: accept, decline, or propose an alternative.',
                    'Vous gardez le contrôle : accepter, refuser ou proposer une alternative.',
                  ),
                ),
                const SizedBox(height: 10),
                ...data.incomingTaskRequests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(
                      request: request,
                      loading: busyRequest == request['id']?.toString(),
                      language: language,
                      t: t,
                      onAccept: () => respond(
                        request['id'].toString(),
                        'accepted',
                      ),
                      onDecline: () => respond(
                        request['id'].toString(),
                        'declined',
                      ),
                      onAlternative: () => proposeAlternative(
                        context,
                        request['id'].toString(),
                        language,
                      ),
                    ),
                  ),
                ),
              ],
              if (data.outgoingTaskRequests.isNotEmpty) ...[
                const SizedBox(height: 22),
                HaniSectionHeader(
                  title: t(language, 'طلباتك', 'طلباتك', 'Your requests',
                      'Vos demandes'),
                  subtitle: t(language, 'متابعة محايدة بلا لوم',
                      'متابعة محايدة دون لوم', 'Neutral status, no blame',
                      'Suivi neutre, sans reproche'),
                ),
                const SizedBox(height: 10),
                ...data.outgoingTaskRequests.take(4).map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _OutgoingRequest(
                          request: request,
                          language: language,
                          t: t,
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 22),
              HaniSectionHeader(
                title: t(language, 'شكون معاكم', 'الأشخاص', 'People',
                    'Les personnes'),
                subtitle: members.length.toString() +
                    ' ' +
                    t(language, 'نشطين', 'نشطون', 'active', 'actifs'),
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
                          child:
                              Text(name.isEmpty ? 'C' : name[0].toUpperCase()),
                        ),
                        title: Text(
                          name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          current
                              ? t(language, 'المرافق الرئيسي · إنت',
                                  'مقدم الرعاية الرئيسي · أنت',
                                  'Primary caregiver · You',
                                  'Aidant principal · Vous')
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
                title: t(language, 'المسؤوليات', 'المسؤوليات',
                    'Responsibilities', 'Responsabilités'),
                subtitle: data.openTasks.length.toString() +
                    ' ' +
                    t(language, 'مفتوحة', 'مفتوحة', 'open', 'ouvertes'),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            [
                              task['difficulty']?.toString(),
                              if (task['effort_weight'] != null)
                                'weight ' + task['effort_weight'].toString(),
                              if (task['overnight'] == true)
                                t(language, 'ليلي', 'ليلي', 'overnight',
                                    'de nuit'),
                            ].whereType<String>().join(' · '),
                          ),
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
                        t(
                          language,
                          'تعبت؟ هاني ينجم يعاونك تطلب من شخص آخر يشد مهمة.',
                          'تحتاج إلى تخفيف الحمل؟ يساعدك هاني في طلب الدعم.',
                          'Need relief? Hani can help you ask someone to take a responsibility.',
                          'Besoin de souffler ? Hani peut vous aider à demander du relais.',
                        ),
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
          ),
        );
      },
    );
  }
}

typedef Localize = String Function(
  HaniLanguage,
  String,
  String,
  String,
  String,
);

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.loading,
    required this.language,
    required this.t,
    required this.onAccept,
    required this.onDecline,
    required this.onAlternative,
  });

  final Map<String, dynamic> request;
  final bool loading;
  final HaniLanguage language;
  final Localize t;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onAlternative;

  @override
  Widget build(BuildContext context) {
    final task = request['task'] is Map
        ? Map<String, dynamic>.from(request['task'] as Map)
        : <String, dynamic>{};
    return HaniGradientCard(
      gradient: HaniGradients.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HaniPill(
            label: 'CARE REQUEST',
            icon: Icons.handshake_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            task['title']?.toString() ??
                t(language, 'طلب مساعدة', 'طلب مساعدة', 'Care request',
                    'Demande de relais'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (request['message']?.toString().trim().isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Text(
              request['message'].toString(),
              style: const TextStyle(
                color: HaniColors.muted,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 15),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      t(language, 'نقبل', 'قبول', 'Accept', 'Accepter'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(
                      t(language, 'ما نجمش', 'رفض', 'Decline', 'Refuser'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAlternative,
              icon: const Icon(Icons.event_repeat_outlined),
              label: Text(
                t(language, 'اقترح بديل', 'اقترح بديلًا',
                    'Propose an alternative', 'Proposer une alternative'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutgoingRequest extends StatelessWidget {
  const _OutgoingRequest({
    required this.request,
    required this.language,
    required this.t,
  });

  final Map<String, dynamic> request;
  final HaniLanguage language;
  final Localize t;

  @override
  Widget build(BuildContext context) {
    final task = request['task'] is Map
        ? Map<String, dynamic>.from(request['task'] as Map)
        : <String, dynamic>{};
    final status = request['status']?.toString() ?? 'pending';
    final statusIcon = switch (status) {
      'accepted' => Icons.check_circle_outline_rounded,
      'declined' => Icons.cancel_outlined,
      'alternative' => Icons.event_repeat_outlined,
      _ => Icons.schedule_rounded,
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: HaniColors.primarySoft,
          child: Icon(statusIcon, color: HaniColors.primary),
        ),
        title: Text(
          task['title']?.toString() ?? 'Care request',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          request['alternative_note']?.toString().trim().isNotEmpty == true
              ? status + ' · ' + request['alternative_note'].toString()
              : status,
        ),
      ),
    );
  }
}
