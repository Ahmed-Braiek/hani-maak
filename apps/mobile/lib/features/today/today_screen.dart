import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
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
  const _TodayContent({required this.data, required this.settings});
  final CaregiverContext data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final firstName = data.caregiverName.split(' ').first;
    final ownId = data.caregiver['id']?.toString();
    final ownTasks = data.openTasks
        .where((t) => t['assigned_to_profile_id']?.toString() == ownId)
        .toList();
    final latestWellbeing =
        data.wellbeing.isNotEmpty ? data.wellbeing.first : null;

    String greeting() {
      return switch (settings.language) {
        HaniLanguage.tounsi => 'عسلامة $firstName',        HaniLanguage.arabic => 'عسلامة $firstName',
        HaniLanguage.french => 'Bonsoir, $firstName',
        HaniLanguage.english => 'Good evening, $firstName',
      };
    }

    String subtitle() {
      return switch (settings.language) {
        HaniLanguage.tounsi => '${data.patientName} معاك اليوم. موش لازم تشيل كل شي وحدك.',        HaniLanguage.arabic => '${data.patientName} معاك اليوم. موش لازم تشيل كل شي وحدك.',
        HaniLanguage.french =>
          '${data.patientName} est dans votre cercle. Vous n’avez pas à tout porter seul.',
        HaniLanguage.english =>
          '${data.patientName} is in your care circle. You do not have to carry everything alone.',
      };
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 122),
      children: [
        HaniAnimatedEntrance(
          child: HaniPageHeader(
            title: greeting(),
            subtitle: subtitle(),
            trailing: CircleAvatar(
              radius: 24,
              backgroundColor: HaniColors.primarySoft,
              child: Text(
                firstName.isEmpty ? 'M' : firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: HaniColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        if (settings.showHaniWidget) ...[
          const SizedBox(height: 22),
          HaniAnimatedEntrance(
            delay: const Duration(milliseconds: 80),
            child: _HaniHero(
              patientName: data.patientName,
              language: settings.language,
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (settings.showPatientWidget ||
            settings.showCareLoadWidget ||
            settings.showWellbeingWidget)
          HaniAnimatedEntrance(
            delay: const Duration(milliseconds: 120),
            child: _WidgetGrid(
              data: data,
              settings: settings,
              ownTasks: ownTasks,
              latestWellbeing: latestWellbeing,
            ),
          ),
        const SizedBox(height: 24),
        HaniSectionHeader(
          title: switch (settings.language) {
            HaniLanguage.tounsi => 'شنوّة يلزم اليوم',        HaniLanguage.arabic => 'شنوّة يلزم اليوم',
            HaniLanguage.french => 'À faire aujourd’hui',
            HaniLanguage.english => 'What needs you today',
          },
          subtitle: switch (settings.language) {
            HaniLanguage.tounsi => 'كان الحاجات المهمّة، بلا ضغط زايد.',        HaniLanguage.arabic => 'كان الحاجات المهمّة، بلا ضغط زايد.',
            HaniLanguage.french => 'Seulement ce qui mérite votre attention.',
            HaniLanguage.english => 'Only what deserves your attention.',
          },
          action: switch (settings.language) {
            HaniLanguage.tounsi => 'الدائرة',        HaniLanguage.arabic => 'الدائرة',
            HaniLanguage.french => 'Cercle',
            HaniLanguage.english => 'Care Circle',
          },
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
        if (data.privateIncidents.isNotEmpty) ...[
          const SizedBox(height: 18),
          HaniSectionHeader(
            title: switch (settings.language) {
              HaniLanguage.tounsi => 'مسودّة خاصة',        HaniLanguage.arabic => 'مسودّة خاصة',
              HaniLanguage.french => 'Brouillon privé',
              HaniLanguage.english => 'Private incident draft',
            },
            subtitle: switch (settings.language) {
              HaniLanguage.tounsi => 'إنت وحدك تشوفها لين توافق تشاركها.',        HaniLanguage.arabic => 'إنت وحدك تشوفها لين توافق تشاركها.',
              HaniLanguage.french =>
                'Visible seulement par vous jusqu’à votre accord.',
              HaniLanguage.english =>
                'Only you can see it until you approve sharing.',
            },
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
  const _HaniHero({required this.patientName, required this.language});
  final String patientName;
  final HaniLanguage language;

  @override
  Widget build(BuildContext context) {
    final title = switch (language) {
      HaniLanguage.tounsi => 'صار شيء صعيب مع $patientName؟',        HaniLanguage.arabic => 'صار شيء صعيب مع $patientName؟',
      HaniLanguage.french => 'Quelque chose de difficile avec $patientName ?',
      HaniLanguage.english => 'Something difficult with $patientName?',
    };
    final body = switch (language) {
      HaniLanguage.tounsi => 'احكي عادي. هاني يعرف سياق الرعاية ويسألك كان على اللي يلزم.',        HaniLanguage.arabic => 'احكي عادي. هاني يعرف سياق الرعاية ويسألك كان على اللي يلزم.',
      HaniLanguage.french =>
        'Parlez naturellement. Hani connaît le contexte et ne demande que l’essentiel.',
      HaniLanguage.english =>
        'Talk naturally. Hani knows the care context and asks only what matters.',
    };

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
                      'تونسي · Français · English',
                      style: TextStyle(color: Color(0xFFD8EEEA), fontSize: 12),
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
            title,
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
            body,
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
                    language == HaniLanguage.french
                        ? 'Message'
                        : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                            ? 'اكتب لهاني'
                            : 'Message Hani',
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
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .25), width: 5),
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
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
          label: '${data.stage} · patient',
          onTap: () => context.go('/patient'),
        ),
      );
    }

    if (settings.showCareLoadWidget) {
      final totalWeight = ownTasks.fold<double>(
        0,
        (sum, task) =>
            sum + ((task['effort_weight'] as num?)?.toDouble() ?? 1),
      );
      final label = totalWeight >= 5
          ? 'Heavy load'
          : totalWeight >= 2
              ? 'Moderate load'
              : 'Light load';
      cards.add(
        HaniMetricCard(
          icon: Icons.balance_rounded,
          value: label,
          label: '${ownTasks.length} open responsibilities',
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
  const _TaskCard({required this.task, required this.onTap});
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
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
              const Icon(Icons.chevron_right_rounded, color: HaniColors.muted),
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

  @override
  Widget build(BuildContext context) {
    return HaniGradientCard(
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
              language == HaniLanguage.french
                  ? 'Revoir avec Hani'
                  : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                      ? 'راجعها مع هاني'
                      : 'Review with Hani',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.language});
  final HaniLanguage language;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: HaniColors.primarySoft,
              child: Icon(Icons.check_rounded, color: HaniColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                language == HaniLanguage.french
                    ? 'Rien d’urgent pour le moment.'
                    : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                        ? 'ما فما حتى شيء مستعجل توّا.'
                        : 'Nothing urgent right now.',
                style: const TextStyle(fontWeight: FontWeight.w800),
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
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
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
