import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class PatientScreen extends ConsumerStatefulWidget {
  const PatientScreen({super.key});

  @override
  ConsumerState<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends ConsumerState<PatientScreen> {
  String filter = 'all';

  String t(
    HaniLanguage l,
    String tn,
    String ar,
    String en,
    String fr,
  ) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

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
      data: (data) => _buildContent(context, data, language),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CaregiverContext data,
    HaniLanguage language,
  ) {
    final events = _events(data);
    final filtered =
        filter == 'all' ? events : events.where((e) => e.type == filter).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(caregiverContextProvider.notifier).refreshContext(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 122),
        children: [
          HaniPageHeader(
            title: data.patientName,
            subtitle: t(
              language,
              'معلومات مشتركة ومسموح بيها · المرحلة: ' + data.stage,
              'معلومات رعاية مشتركة ومصرح بها · المرحلة: ' + data.stage,
              'Authorized shared care · Stage: ' + data.stage,
              'Informations partagées autorisées · Stade : ' + data.stage,
            ),
            trailing: CircleAvatar(
              radius: 28,
              backgroundColor: HaniColors.primarySoft,
              child: Text(
                data.patientName.isEmpty
                    ? 'P'
                    : data.patientName[0].toUpperCase(),
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
                    t(
                      language,
                      'تعليمات المختص تبان كموثقة. ملاحظات العائلة تبقى ملاحظات وما توليش تشخيص.',
                      'تظهر تعليمات المختص كمعلومات موثقة. وتبقى ملاحظات الأسرة ملاحظات وليست تشخيصًا.',
                      'Professional instructions are clearly verified. Family observations remain observations, not diagnoses.',
                      'Les instructions professionnelles sont identifiées comme vérifiées. Les observations familiales restent des observations.',
                    ),
                    style: const TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.extension_outlined,
                  title: t(language, 'نشاط', 'نشاط', 'Activity', 'Activité'),
                  onTap: () => context.push('/activity'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Shortcut(
                  icon: Icons.hub_outlined,
                  title:
                      t(language, 'المركز', 'المركز', 'Care hub', 'Centre'),
                  onTap: () => context.push('/care-hub'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Shortcut(
                  icon: Icons.support_agent_outlined,
                  title: t(language, 'مختص', 'مختص', 'Professional',
                      'Professionnel'),
                  onTap: () => context.push('/handoff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          HaniGradientCard(
            gradient: HaniGradients.soft,
            onTap: () => context.push('/dilemmas'),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.psychology_alt_outlined, color: HaniColors.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daily Dilemma · start from a real care situation',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          HaniSectionHeader(
            title: t(language, 'الأدوية', 'الأدوية', 'Medications',
                'Médicaments'),
            subtitle: t(
              language,
              'هاني ما يبدلش الجرعة ولا التوقيت.',
              'لا يغير هاني الجرعة أو التوقيت.',
              'Hani never changes dose or timing.',
              'Hani ne modifie jamais dose ou horaire.',
            ),
            action:
                data.medications.isEmpty ? null : data.medications.length.toString(),
          ),
          const SizedBox(height: 10),
          if (data.medications.isEmpty)
            _Empty(
              text: t(
                language,
                'ما فماش معلومات أدوية نشطة.',
                'لا توجد معلومات أدوية نشطة.',
                'No active medication information.',
                'Aucune information médicamenteuse active.',
              ),
            )
          else
            ...data.medications.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MedicationCard(med: med),
              ),
            ),
          const SizedBox(height: 16),
          HaniSectionHeader(
            title: t(language, 'تعليمات المختص', 'تعليمات المختص',
                'Verified instructions', 'Instructions vérifiées'),
            action: data.instructions.length.toString(),
          ),
          const SizedBox(height: 10),
          if (data.instructions.isEmpty)
            _Empty(
              text: t(
                language,
                'ما فماش تعليمات موثقة توّا.',
                'لا توجد تعليمات موثقة حاليًا.',
                'No verified professional instructions yet.',
                'Aucune instruction professionnelle vérifiée pour le moment.',
              ),
            )
          else
            ...data.instructions.take(5).map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InstructionCard(instruction: instruction),
              ),
            ),
          const SizedBox(height: 18),
          HaniSectionHeader(
            title: t(language, 'المواعيد', 'المواعيد', 'Appointments',
                'Rendez-vous'),
            subtitle: t(
              language,
              'طلبات ومواعيد مرتبطة بالرعاية.',
              'طلبات ومواعيد مرتبطة بالرعاية.',
              'Care-related requests and appointments.',
              'Demandes et rendez-vous liés aux soins.',
            ),
          ),
          const SizedBox(height: 10),
          if (data.appointments.isEmpty)
            _Empty(
              text: t(language, 'ما فماش موعد مسجل.', 'لا يوجد موعد مسجل.',
                  'No appointment recorded.', 'Aucun rendez-vous enregistré.'),
            )
          else
            ...data.appointments.take(5).map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _AppointmentCard(
                  appointment: appointment,
                  language: language,
                  t: t,
                ),
              ),
            ),
          const SizedBox(height: 18),
          HaniSectionHeader(
            title: t(language, 'الخط الزمني', 'الخط الزمني',
                'Care timeline', 'Chronologie de soins'),
            subtitle: t(
              language,
              'شنوّة صار ووقتاش، مع فصل المعلومة الموثقة على الملاحظة.',
              'ما الذي حدث ومتى، مع الفصل بين المعلومات الموثقة والملاحظات.',
              'What happened when, keeping verified facts distinct from observations.',
              'Ce qui s’est passé et quand, en séparant les faits vérifiés des observations.',
            ),
          ),
          const SizedBox(height: 10),
          _Filters(
            selected: filter,
            language: language,
            t: t,
            onChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            _Empty(
              text: t(language, 'ما فماش أحداث في الفيلتر هذا.',
                  'لا توجد أحداث ضمن هذا التصنيف.',
                  'No events in this view.',
                  'Aucun événement dans cette vue.'),
            )
          else
            ...filtered.take(20).map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _TimelineCard(
                  event: event,
                  language: language,
                  t: t,
                ),
              ),
            ),
          if (data.privateIncidents.isNotEmpty) ...[
            const SizedBox(height: 18),
            HaniSectionHeader(
              title: t(language, 'مسودات خاصة', 'مسودات خاصة',
                  'Private drafts', 'Brouillons privés'),
              subtitle: t(
                language,
                'ما يدخل حتى شيء للخط المشترك بلا موافقتك.',
                'لا يدخل أي شيء إلى الخط المشترك دون موافقتك.',
                'Nothing enters the shared timeline without your approval.',
                'Rien n’entre dans la chronologie partagée sans votre accord.',
              ),
            ),
            const SizedBox(height: 10),
            ...data.privateIncidents.take(3).map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _PrivateIncident(
                  incident: incident,
                  onTap: () => context.push('/hani'),
                ),
              ),
            ),
          ],
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
                    t(
                      language,
                      'تبدل شيء؟ احكيه لهاني وخليه يرتبلك الملاحظة كمسودة خاصة.',
                      'هل تغير شيء؟ أخبر هاني ليحول الملاحظة إلى مسودة خاصة.',
                      'Something changed? Tell Hani and structure a private draft.',
                      'Quelque chose a changé ? Dites-le à Hani pour structurer un brouillon privé.',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_CareEvent> _events(CaregiverContext data) {
    final result = <_CareEvent>[];

    for (final item in data.timeline) {
      result.add(
        _CareEvent(
          type: item['event_type']?.toString() ?? 'incident',
          title: item['title']?.toString() ?? 'Care event',
          body: item['summary']?.toString() ?? '',
          at: _date(item['occurred_at']) ?? _date(item['created_at']),
          verified: item['source_type'] == 'professional_instruction',
        ),
      );
    }

    for (final item in data.appointments) {
      result.add(
        _CareEvent(
          type: 'appointment',
          title: 'Appointment',
          body: [
            item['reason']?.toString(),
            item['status']?.toString(),
          ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
          at: _date(item['scheduled_for']) ?? _date(item['created_at']),
          verified: false,
        ),
      );
    }

    for (final item in data.instructions) {
      result.add(
        _CareEvent(
          type: 'instruction',
          title: item['title']?.toString() ?? 'Professional instruction',
          body: item['body']?.toString() ?? '',
          at: _date(item['created_at']) ?? _date(item['verified_at']),
          verified: true,
        ),
      );
    }

    for (final item in data.tasks) {
      result.add(
        _CareEvent(
          type: 'task',
          title: item['title']?.toString() ?? 'Care task',
          body: item['status']?.toString() ?? '',
          at: _date(item['due_at']) ?? _date(item['created_at']),
          verified: false,
        ),
      );
    }

    result.sort((a, b) {
      if (a.at == null && b.at == null) return 0;
      if (a.at == null) return 1;
      if (b.at == null) return -1;
      return b.at!.compareTo(a.at!);
    });
    return result;
  }

  DateTime? _date(dynamic raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());
}

class _CareEvent {
  const _CareEvent({
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    required this.verified,
  });

  final String type;
  final String title;
  final String body;
  final DateTime? at;
  final bool verified;
}

typedef Localize = String Function(
  HaniLanguage,
  String,
  String,
  String,
  String,
);

class _Shortcut extends StatelessWidget {
  const _Shortcut({
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
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(icon, color: HaniColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.language,
    required this.t,
  });

  final Map<String, dynamic> appointment;
  final HaniLanguage language;
  final Localize t;

  @override
  Widget build(BuildContext context) {
    final when = DateTime.tryParse(
      appointment['scheduled_for']?.toString() ?? '',
    );
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(
          backgroundColor: HaniColors.primarySoft,
          child: Icon(
            Icons.calendar_month_outlined,
            color: HaniColors.primary,
          ),
        ),
        title: Text(
          appointment['reason']?.toString().trim().isNotEmpty == true
              ? appointment['reason'].toString()
              : t(language, 'موعد رعاية', 'موعد رعاية', 'Care appointment',
                  'Rendez-vous de soins'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            appointment['status']?.toString(),
            if (when != null)
              when.toLocal().toString().substring(0, 16),
          ].whereType<String>().join(' · '),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.selected,
    required this.language,
    required this.t,
    required this.onChanged,
  });

  final String selected;
  final HaniLanguage language;
  final Localize t;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('all', t(language, 'الكل', 'الكل', 'All', 'Tout')),
            _chip('incident',
                t(language, 'حوادث', 'حوادث', 'Incidents', 'Incidents')),
            _chip(
              'appointment',
              t(language, 'مواعيد', 'مواعيد', 'Appointments', 'Rendez-vous'),
            ),
            _chip(
              'instruction',
              t(language, 'تعليمات', 'تعليمات', 'Instructions', 'Instructions'),
            ),
            _chip('task', t(language, 'مهام', 'مهام', 'Tasks', 'Tâches')),
          ],
        ),
      );

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 7),
        child: ChoiceChip(
          selected: selected == value,
          onSelected: (_) => onChanged(value),
          label: Text(label),
        ),
      );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.event,
    required this.language,
    required this.t,
  });

  final _CareEvent event;
  final HaniLanguage language;
  final Localize t;

  IconData get icon => switch (event.type) {
        'appointment' => Icons.calendar_month_outlined,
        'instruction' => Icons.verified_user_outlined,
        'task' => Icons.task_alt_outlined,
        _ => Icons.history_rounded,
      };

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: CircleAvatar(
            backgroundColor: event.verified
                ? HaniColors.primarySoft
                : const Color(0xFFF0F3F2),
            child: Icon(
              icon,
              color: event.verified ? HaniColors.primary : HaniColors.inkSoft,
            ),
          ),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (event.at != null) ...[
                const SizedBox(height: 5),
                Text(
                  event.at!.toLocal().toString().substring(0, 16),
                  style: const TextStyle(
                    color: HaniColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
          trailing: event.verified
              ? const Icon(
                  Icons.verified_rounded,
                  color: HaniColors.primary,
                  size: 19,
                )
              : null,
        ),
      );
}

class _PrivateIncident extends StatelessWidget {
  const _PrivateIncident({
    required this.incident,
    required this.onTap,
  });

  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(15),
          leading: const CircleAvatar(
            backgroundColor: HaniColors.warm,
            child:
                Icon(Icons.lock_outline_rounded, color: HaniColors.warning),
          ),
          title: Text(
            incident['title']?.toString() ?? 'Private incident',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            incident['summary']?.toString() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Text(
            text,
            style: const TextStyle(color: HaniColors.muted),
          ),
        ),
      );
}
