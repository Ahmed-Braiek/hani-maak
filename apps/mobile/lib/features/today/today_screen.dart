import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/care/care_load.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context.dart';
import '../context/caregiver_context_provider.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final settings = ref.watch(appSettingsProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(caregiverContextProvider.notifier).refreshContext(),
      child: value.when(
        loading: () => const _LoadingToday(),
        error: (_, __) => _ErrorToday(
          onRetry: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
        ),
        data: (data) => _TodayContent(data: data, settings: settings),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.data,
    required this.settings,
  });

  final CaregiverContext data;
  final AppSettings settings;

  String t(String tn, String ar, String en, String fr) =>
      switch (settings.language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) {
    final firstName = data.caregiverName.split(' ').first;
    final ownId = data.caregiver['id']?.toString();
    final ownTasks = data.openTasks
        .where((task) =>
            task['assigned_to_profile_id']?.toString() == ownId)
        .toList();
    final latestWellbeing =
        data.wellbeing.isNotEmpty ? data.wellbeing.first : null;

    final title = t(
      'عسلامة ' + firstName,
      'مرحبًا ' + firstName,
      'Good evening, ' + firstName,
      'Bonsoir, ' + firstName,
    );
    final subtitle = t(
      data.patientName + ' معاك اليوم. موش لازم تشيل كل شي وحدك.',
      data.patientName + ' معك اليوم. لست مضطرًا لحمل كل شيء وحدك.',
      data.patientName +
          ' is in your care circle. You do not have to carry everything alone.',
      data.patientName +
          ' est dans votre cercle. Vous n’avez pas à tout porter seul.',
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 122),
      children: [
        HaniAnimatedEntrance(
          child: HaniPageHeader(
            title: title,
            subtitle: subtitle,
            trailing: CircleAvatar(
              radius: 24,
              backgroundColor: HaniColors.primarySoft,
              child: Text(
                firstName.isEmpty ? 'C' : firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: HaniColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        if (data.followUp != null) ...[
          const SizedBox(height: 18),
          HaniAnimatedEntrance(
            delay: const Duration(milliseconds: 50),
            child: _FollowUpCard(
              followUp: data.followUp!,
              language: settings.language,
            ),
          ),
        ],
        if (settings.showHaniWidget) ...[
          const SizedBox(height: 18),
          HaniAnimatedEntrance(
            delay: const Duration(milliseconds: 90),
            child: _HaniHero(
              patientName: data.patientName,
              language: settings.language,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _DailyDilemmaCard(
          language: settings.language,
          onTap: () => context.push('/dilemmas'),
        ),
        const SizedBox(height: 10),
        _DiscoverCard(
          language: settings.language,
          onTap: () => context.push('/how-it-works'),
        ),
        const SizedBox(height: 20),
        if (settings.showPatientWidget ||
            settings.showCareLoadWidget ||
            settings.showWellbeingWidget)
          HaniAnimatedEntrance(
            delay: const Duration(milliseconds: 130),
            child: _WidgetGrid(
              data: data,
              settings: settings,
              ownTasks: ownTasks,
              latestWellbeing: latestWellbeing,
            ),
          ),
        if (data.patterns.isNotEmpty) ...[
          const SizedBox(height: 20),
          _PatternPulse(
            pattern: data.patterns.first,
            language: settings.language,
          ),
        ],
        const SizedBox(height: 24),
        HaniSectionHeader(
          title: t('شنوّة يلزم اليوم', 'ما الذي يحتاجك اليوم؟',
              'What needs you today', 'À faire aujourd’hui'),
          subtitle: t(
            'كان الحاجات المهمّة، بلا ضغط زايد.',
            'فقط ما يحتاج إلى انتباهك، دون ضغط إضافي.',
            'Only what deserves your attention.',
            'Seulement ce qui mérite votre attention.',
          ),
          action: t('الدائرة', 'الدائرة', 'Care Circle', 'Cercle'),
          onAction: () => context.go('/circle'),
        ),
        const SizedBox(height: 10),
        if (data.openTasks.isEmpty)
          _EmptyToday(language: settings.language)
        else
          ...data.openTasks.take(4).map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskCard(
                    task: task,
                    onTap: () => context.go('/circle'),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        HaniGradientCard(
          onTap: () => context.push('/care-hub'),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.hub_outlined,
                  color: HaniColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('مركز الرعاية', 'مركز الرعاية', 'Care hub',
                          'Centre de soins'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t(
                        'الخط الزمني، المواعيد، تعليمات المختص والنشاطات.',
                        'الخط الزمني والمواعيد وتعليمات المختص والأنشطة.',
                        'Timeline, appointments, verified instructions, and patient activities.',
                        'Chronologie, rendez-vous, instructions vérifiées et activités.',
                      ),
                      style: const TextStyle(
                        color: HaniColors.muted,
                        fontSize: 12.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        if (data.privateIncidents.isNotEmpty) ...[
          const SizedBox(height: 22),
          HaniSectionHeader(
            title: t('مسودّة خاصة', 'مسودة خاصة', 'Private incident draft',
                'Brouillon privé'),
            subtitle: t(
              'إنت وحدك تشوفها لين توافق تشاركها.',
              'لا يراها غيرك حتى توافق على مشاركتها.',
              'Only you can see it until you approve sharing.',
              'Visible seulement par vous jusqu’à votre accord.',
            ),
          ),
          const SizedBox(height: 10),
          _IncidentDraftCard(
            incident: data.privateIncidents.first,
            language: settings.language,
          ),
        ],
      ],
    );
  }
}

class _HaniHero extends StatelessWidget {
  const _HaniHero({
    required this.patientName,
    required this.language,
  });

  final String patientName;
  final HaniLanguage language;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) {
    return HaniGradientCard(
      gradient: HaniGradients.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _HeroOrb(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hani Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تونسي · العربية · Français · English',
                      style: TextStyle(
                        color: Color(0xFFD8EEEA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              HaniPill(
                label: 'LIVE',
                icon: Icons.waves_rounded,
                background: Color(0x2BFFFFFF),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            t(
              'صار شيء صعيب مع ' + patientName + '؟',
              'هل حدث شيء صعب مع ' + patientName + '؟',
              'Something difficult with ' + patientName + '?',
              'Quelque chose de difficile avec ' + patientName + ' ?',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            t(
              'احكي عادي. هاني يعرف سياق الرعاية ويسألك كان على اللي يلزم.',
              'تحدث بشكل طبيعي. يعرف هاني سياق الرعاية ويسأل فقط عما يحتاجه.',
              'Talk naturally. Hani knows the care context and asks only what matters.',
              'Parlez naturellement. Hani connaît le contexte et ne demande que l’essentiel.',
            ),
            style: const TextStyle(
              color: Color(0xFFE8F5F2),
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HaniColors.primaryDeep,
                  ),
                  onPressed: () => context.push('/hani'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(
                    t('اكتب لهاني', 'اكتب لهاني', 'Message Hani', 'Message'),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filled(
                tooltip: 'Live voice',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .15),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(52, 52),
                ),
                onPressed: () => context.push('/voice'),
                icon: const Icon(Icons.mic_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb();

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: .25),
            width: 5,
          ),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      );
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.followUp,
    required this.language,
  });

  final Map<String, dynamic> followUp;
  final HaniLanguage language;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) => HaniGradientCard(
        gradient: HaniGradients.wellbeing,
        onTap: () => context.push('/hani'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child:
                  Icon(Icons.history_rounded, color: HaniColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HaniPill(
                    label: t('متابعة', 'متابعة', 'FOLLOW-UP', 'SUIVI'),
                    icon: Icons.schedule_rounded,
                    background: const Color(0xFFFFE4BE),
                    foreground: HaniColors.warning,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    followUp['title']?.toString() ??
                        t('كيفاش مشات؟', 'كيف سارت الأمور؟',
                            'How did it go?', 'Comment cela s’est passé ?'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    followUp['body']?.toString() ??
                        t(
                          'هاني يتفكر الحادثة وتنجم تكمل من وين وقفت.',
                          'يتذكر هاني الحدث ويمكنك المتابعة من حيث توقفت.',
                          'Hani remembers the care moment so you can continue where you left off.',
                          'Hani se souvient de ce moment de soin pour reprendre là où vous vous êtes arrêté.',
                        ),
                    style: const TextStyle(
                      color: HaniColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.language,
    required this.onTap,
  });

  final HaniLanguage language;
  final VoidCallback onTap;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(15),
          leading: const CircleAvatar(
            backgroundColor: HaniColors.lilac,
            child: Icon(
              Icons.explore_outlined,
              color: HaniColors.lilacInk,
            ),
          ),
          title: Text(
            t('شنوّة يعمل هاني بالضبط؟', 'ماذا يفعل هاني بالضبط؟',
                'What does Hani actually do?', 'Que fait Hani exactement ?'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            t(
              'شرح سريع للخصوصية، المساعدة، الدائرة والمختصين.',
              'شرح سريع للخصوصية والدعم ودائرة الرعاية والمختصين.',
              'A one-minute guide to privacy, support, Care Circle, and human handoff.',
              'Un guide d’une minute sur la confidentialité, le soutien, le Cercle et le relais humain.',
            ),
            style: const TextStyle(
              color: HaniColors.muted,
              fontSize: 12.2,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class _PatternPulse extends StatelessWidget {
  const _PatternPulse({
    required this.pattern,
    required this.language,
  });

  final Map<String, dynamic> pattern;
  final HaniLanguage language;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) {
    final strain = pattern['type'] == 'caregiver_strain';
    return Card(
      child: ListTile(
        onTap: () => context.push(strain ? '/me' : '/patient'),
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor:
              strain ? HaniColors.warm : HaniColors.primarySoft,
          child: Icon(
            strain ? Icons.insights_outlined : Icons.timeline_rounded,
            color: strain ? HaniColors.warning : HaniColors.primary,
          ),
        ),
        title: Text(
          strain
              ? t('الأيام الأخيرة أثقل شوية',
                  'الأيام الأخيرة تبدو أثقل قليلًا',
                  'The last few days look heavier',
                  'Les derniers jours semblent plus lourds')
              : t('فما نمط يتعاود', 'هناك نمط متكرر',
                  'A pattern is repeating', 'Une tendance se répète'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          t(
            'هاني يوريك النمط بلا تشخيص ولا تخمين للسبب.',
            'يعرض هاني النمط دون تشخيص أو تخمين للسبب.',
            'Hani can surface the pattern without diagnosing its cause.',
            'Hani peut montrer la tendance sans diagnostiquer sa cause.',
          ),
          style: const TextStyle(color: HaniColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _WidgetGrid extends StatelessWidget {
  const _WidgetGrid({
    required this.data,
    required this.settings,
    required this.ownTasks,
    required this.latestWellbeing,
  });

  final CaregiverContext data;
  final AppSettings settings;
  final List<Map<String, dynamic>> ownTasks;
  final Map<String, dynamic>? latestWellbeing;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    if (settings.showPatientWidget) {
      cards.add(
        HaniMetricCard(
          icon: Icons.favorite_outline_rounded,
          value: data.patientName,
          label: data.stage + ' · patient',
          onTap: () => context.go('/patient'),
        ),
      );
    }

    if (settings.showCareLoadWidget) {
      final totalWeight = ownTasks.fold<double>(
        0,
        (sum, task) => sum + haniTaskLoadScore(task),
      );
      final band = haniLoadBand(totalWeight);
      final label = band == 'heavy'
          ? 'Heavy load'
          : band == 'moderate'
              ? 'Moderate load'
              : 'Light load';
      cards.add(
        HaniMetricCard(
          icon: Icons.balance_rounded,
          value: label,
          label: ownTasks.length.toString() + ' open responsibilities',
          tint: HaniColors.lilac,
          iconColor: HaniColors.lilacInk,
          onTap: () => context.go('/circle'),
        ),
      );
    }

    if (settings.showWellbeingWidget) {
      final mood = latestWellbeing?['mood_label']?.toString() ?? 'Check in';
      cards.add(
        HaniMetricCard(
          icon: Icons.self_improvement_rounded,
          value: mood,
          label: 'Your private wellbeing',
          tint: HaniColors.warm,
          iconColor: HaniColors.warning,
          onTap: () => context.go('/me'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficulty = task['difficulty']?.toString() ?? 'routine';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: task['overnight'] == true
                    ? HaniColors.lilac
                    : HaniColors.primarySoft,
                child: Icon(
                  task['overnight'] == true
                      ? Icons.nights_stay_outlined
                      : Icons.checklist_rounded,
                  color: task['overnight'] == true
                      ? HaniColors.lilacInk
                      : HaniColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title']?.toString() ?? 'Care task',
                      style:
                          const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      difficulty,
                      style: const TextStyle(
                        color: HaniColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: HaniColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentDraftCard extends StatelessWidget {
  const _IncidentDraftCard({
    required this.incident,
    required this.language,
  });

  final Map<String, dynamic> incident;
  final HaniLanguage language;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) => HaniGradientCard(
        gradient: HaniGradients.wellbeing,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HaniPill(
              label: 'PRIVATE',
              icon: Icons.lock_outline_rounded,
              background: Color(0xFFFFE7C7),
              foreground: HaniColors.warning,
            ),
            const SizedBox(height: 12),
            Text(
              incident['title']?.toString() ?? 'Recent incident',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              incident['summary']?.toString() ?? '',
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 13),
            TextButton.icon(
              onPressed: () => context.push('/hani'),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                t('راجعها مع هاني', 'راجعها مع هاني', 'Review with Hani',
                    'Revoir avec Hani'),
              ),
            ),
          ],
        ),
      );
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.language});

  final HaniLanguage language;

  @override
  Widget build(BuildContext context) {
    final text = switch (language) {
      HaniLanguage.tounsi => 'ما فما حتى شيء مستعجل توّا.',
      HaniLanguage.arabic => 'لا يوجد شيء مستعجل الآن.',
      HaniLanguage.english => 'Nothing urgent right now.',
      HaniLanguage.french => 'Rien d’urgent pour le moment.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: HaniColors.primarySoft,
              child: Icon(
                Icons.check_rounded,
                color: HaniColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                text,
                style:
                    const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingToday extends StatelessWidget {
  const _LoadingToday();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 150),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(child: Text('Loading care context…')),
        ],
      );
}

class _ErrorToday extends StatelessWidget {
  const _ErrorToday({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Could not load care context.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
}


class _DailyDilemmaCard extends StatelessWidget {
  const _DailyDilemmaCard({
    required this.language,
    required this.onTap,
  });

  final HaniLanguage language;
  final VoidCallback onTap;

  String t(String tn, String ar, String en, String fr) => switch (language) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) => HaniGradientCard(
        gradient: HaniGradients.soft,
        onTap: onTap,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.psychology_alt_outlined,
                color: HaniColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HaniPill(
                    label: t(
                      'موقف يومي',
                      'موقف يومي',
                      'DAILY DILEMMA',
                      'DILEMME DU JOUR',
                    ),
                    icon: Icons.route_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'شنوّة صاير اليوم؟',
                      'ما الموقف الذي تواجهه اليوم؟',
                      'What is happening today?',
                      'Quelle situation vous préoccupe aujourd’hui ?',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'اختار من 10 مواقف رعاية أساسية وابدأ مباشرة مع هاني.',
                      'اختر من 10 مواقف رعاية أساسية وابدأ مباشرة مع هاني.',
                      'Choose one of 10 core care situations and start directly with Hani.',
                      'Choisissez l’une des 10 situations de soins principales et commencez avec Hani.',
                    ),
                    style: const TextStyle(
                      color: HaniColors.muted,
                      height: 1.35,
                      fontSize: 12.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
}
