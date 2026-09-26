import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  Map<String, dynamic>? questionnaire;
  final answers = <String, dynamic>{};
  bool loadingInstrument = false;
  bool submitting = false;
  Map<String, dynamic>? result;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  Future<void> loadInstrument(String versionId) async {
    setState(() {
      loadingInstrument = true;
      result = null;
      answers.clear();
    });
    try {
      final response = await ref.read(caregiverContextApiProvider).action(
        'get_questionnaire',
        args: {'versionId': versionId},
      );
      final raw = response?['questionnaire'];
      if (raw is Map) {
        setState(() => questionnaire = Map<String, dynamic>.from(raw));
      }
    } finally {
      if (mounted) setState(() => loadingInstrument = false);
    }
  }

  Future<void> submit(HaniLanguage language) async {
    final q = questionnaire;
    if (q == null) return;
    final version = q['version'] is Map
        ? Map<String, dynamic>.from(q['version'] as Map)
        : <String, dynamic>{};
    final questions = (q['questions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final missing = questions.where((question) {
      if (question['required'] != true) return false;
      return !answers.containsKey(question['id']?.toString());
    }).toList();

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(language, 'جاوب على الأسئلة المطلوبة قبل الإرسال.',
                'أجب عن الأسئلة المطلوبة قبل الإرسال.',
                'Complete the required questions before submitting.',
                'Répondez aux questions obligatoires avant de valider.'),
          ),
        ),
      );
      return;
    }

    setState(() => submitting = true);
    try {
      final response = await ref.read(caregiverContextApiProvider).action(
        'submit_questionnaire',
        args: {
          'versionId': version['id']?.toString(),
          'answers': answers.entries
              .map((entry) => {
                    'questionId': entry.key,
                    'answer': entry.value,
                  })
              .toList(),
        },
      );
      final raw = response?['result'];
      setState(() {
        result =
            raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      });
      await ref.read(caregiverContextProvider.notifier).refreshContext();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t(language, 'استبيان الراحة النفسية',
              'استبيان الرفاه لمقدم الرعاية',
              'Wellbeing questionnaire',
              'Questionnaire de bien-être'),
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Questionnaire unavailable.')),
        data: (data) {
          if (loadingInstrument) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result != null) {
            return _ResultView(
              result: result!,
              language: language,
              t: t,
              onDone: () => context.go('/me'),
              onProfessional: () => context.push('/handoff'),
            );
          }
          if (questionnaire != null) {
            return _QuestionnaireForm(
              questionnaire: questionnaire!,
              answers: answers,
              language: language,
              t: t,
              submitting: submitting,
              onAnswer: (id, answer) =>
                  setState(() => answers[id] = answer),
              onSubmit: () => submit(language),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              HaniGradientCard(
                gradient: HaniGradients.wellbeing,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HaniPill(
                      label: 'PRIVATE',
                      icon: Icons.lock_outline_rounded,
                      background: Color(0xFFFFE6C4),
                      foreground: HaniColors.warning,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t(language, 'إجاباتك تبقى خاصّة بيك.',
                          'تبقى إجاباتك خاصة بك.',
                          'Your answers stay private.',
                          'Vos réponses restent privées.'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(
                        language,
                        'ما يتشارك حتى ملخص مع مختص كان بموافقتك.',
                        'لا يُشارك أي ملخص مع مختص إلا بموافقتك.',
                        'A professional receives a summary only after your explicit approval.',
                        'Un résumé n’est partagé avec un professionnel qu’avec votre accord.',
                      ),
                      style: const TextStyle(
                        color: HaniColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              HaniSectionHeader(
                title: t(language, 'الأدوات المصادق عليها',
                    'الأدوات المعتمدة', 'Validated instruments',
                    'Instruments validés'),
              ),
              const SizedBox(height: 10),
              if (data.questionnaires.isEmpty)
                _PendingInstrument(language: language, t: t)
              else
                ...data.questionnaires.map(
                  (instrument) {
                    final definition = instrument['definition'] is Map
                        ? Map<String, dynamic>.from(
                            instrument['definition'] as Map,
                          )
                        : <String, dynamic>{};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          onTap: () =>
                              loadInstrument(instrument['id'].toString()),
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            backgroundColor: HaniColors.primarySoft,
                            child: Icon(
                              Icons.fact_check_outlined,
                              color: HaniColors.primary,
                            ),
                          ),
                          title: Text(
                            definition['name']?.toString() ??
                                'Validated questionnaire',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            'Version ' +
                                (instrument['version_label']?.toString() ?? '') +
                                ' · ' +
                                (instrument['language']?.toString() ?? ''),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right_rounded),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
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

class _QuestionnaireForm extends StatelessWidget {
  const _QuestionnaireForm({
    required this.questionnaire,
    required this.answers,
    required this.language,
    required this.t,
    required this.submitting,
    required this.onAnswer,
    required this.onSubmit,
  });

  final Map<String, dynamic> questionnaire;
  final Map<String, dynamic> answers;
  final HaniLanguage language;
  final Localize t;
  final bool submitting;
  final void Function(String id, dynamic answer) onAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final definition = questionnaire['definition'] is Map
        ? Map<String, dynamic>.from(questionnaire['definition'] as Map)
        : <String, dynamic>{};
    final version = questionnaire['version'] is Map
        ? Map<String, dynamic>.from(questionnaire['version'] as Map)
        : <String, dynamic>{};
    final questions = (questionnaire['questions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final answered = questions
        .where((q) => answers.containsKey(q['id']?.toString()))
        .length;
    final progress = questions.isEmpty ? 0.0 : answered / questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
      children: [
        HaniGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HaniPill(
                label: 'VALIDATED INSTRUMENT',
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 13),
              Text(
                definition['name']?.toString() ?? 'Questionnaire',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                (definition['purpose']?.toString() ?? '') +
                    (version['version_label'] != null
                        ? ' · Version ' + version['version_label'].toString()
                        : ''),
                style: const TextStyle(color: HaniColors.muted),
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 7),
              Text(
                answered.toString() +
                    ' / ' +
                    questions.length.toString() +
                    ' ' +
                    t(language, 'مجاوب عليهم', 'تمت الإجابة عنها', 'answered',
                        'réponses'),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: HaniColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...questions.map(
          (question) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuestionCard(
              question: question,
              answer: answers[question['id']?.toString()],
              onAnswer: (answer) =>
                  onAnswer(question['id'].toString(), answer),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            t(language, 'كمّل', 'إكمال', 'Complete questionnaire',
                'Terminer le questionnaire'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            language,
            'هاني يوريك تفسير بسيط، موش سكور تشخيصي.',
            'يعرض هاني تفسيرًا بسيطًا وليس درجة تشخيصية.',
            'Hani shows a simple interpretation, not a diagnostic score.',
            'Hani affiche une interprétation simple, pas un score diagnostique.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HaniColors.muted,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final Map<String, dynamic> question;
  final dynamic answer;
  final ValueChanged<dynamic> onAnswer;

  @override
  Widget build(BuildContext context) {
    final type = question['response_type']?.toString() ?? 'text';
    final optionsRaw = question['options'];
    final options = optionsRaw is List
        ? optionsRaw
        : optionsRaw is Map
            ? optionsRaw.entries
                .map((e) => {'value': e.key, 'label': e.value})
                .toList()
            : const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['prompt']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
            if (type == 'boolean')
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: answer == true,
                      onSelected: (_) => onAnswer(true),
                      label: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: answer == false,
                      onSelected: (_) => onAnswer(false),
                      label: const Text('No'),
                    ),
                  ),
                ],
              )
            else if (type == 'single_choice')
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: options.map<Widget>((option) {
                  final value = option is Map
                      ? (option['value'] ?? option['id'] ?? option['label'])
                      : option;
                  final label = option is Map
                      ? (option['label'] ?? option['text'] ?? value)
                      : option;
                  return ChoiceChip(
                    selected: answer == value,
                    onSelected: (_) => onAnswer(value),
                    label: Text(label.toString()),
                  );
                }).toList(),
              )
            else if (type == 'multi_choice')
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: options.map<Widget>((option) {
                  final value = option is Map
                      ? (option['value'] ?? option['id'] ?? option['label'])
                      : option;
                  final label = option is Map
                      ? (option['label'] ?? option['text'] ?? value)
                      : option;
                  final selected =
                      answer is List && (answer as List).contains(value);
                  return FilterChip(
                    selected: selected,
                    onSelected: (_) {
                      final next =
                          answer is List ? List<dynamic>.from(answer) : [];
                      selected ? next.remove(value) : next.add(value);
                      onAnswer(next);
                    },
                    label: Text(label.toString()),
                  );
                }).toList(),
              )
            else
              TextFormField(
                initialValue: answer?.toString(),
                keyboardType:
                    type == 'number' ? TextInputType.number : TextInputType.text,
                maxLines: type == 'text' ? 3 : 1,
                onChanged: (value) => onAnswer(
                  type == 'number' ? num.tryParse(value) : value,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.language,
    required this.t,
    required this.onDone,
    required this.onProfessional,
  });

  final Map<String, dynamic> result;
  final HaniLanguage language;
  final Localize t;
  final VoidCallback onDone;
  final VoidCallback onProfessional;

  @override
  Widget build(BuildContext context) {
    final needsHuman = result['requires_professional_support'] == true;
    final interpretation =
        result['interpretation_text']?.toString().trim() ?? '';
    final trend = result['trend_label']?.toString().trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 34),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              gradient: HaniGradients.hero,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 39,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t(language, 'الاستبيان كمّل', 'اكتمل الاستبيان',
              'Questionnaire complete', 'Questionnaire terminé'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          interpretation.isNotEmpty
              ? interpretation
              : t(
                  language,
                  'الإجابات تسجلت بأمان. ما فماش تفسير جاهز في إعدادات الأداة، لذلك هاني ما باش يخترع واحد.',
                  'تم حفظ الإجابات بأمان. لا يوجد تفسير مهيأ في الأداة، لذلك لن يخترع هاني تفسيرًا.',
                  'Your answers were saved safely. This validated version does not provide a configured interpretation, so Hani will not invent one.',
                  'Vos réponses ont été enregistrées. Cette version ne fournit pas d’interprétation configurée, donc Hani n’en invente pas.',
                ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: HaniColors.muted,
            height: 1.5,
          ),
        ),
        if (trend.isNotEmpty) ...[
          const SizedBox(height: 14),
          Center(
            child: HaniPill(
              label: trend,
              icon: Icons.insights_outlined,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (needsHuman) ...[
          FilledButton.icon(
            onPressed: onProfessional,
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(
              t(language, 'احكي مع مختص', 'تحدث مع مختص',
                  'Talk to a professional', 'Parler à un professionnel'),
            ),
          ),
          const SizedBox(height: 9),
        ],
        OutlinedButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(t(language, 'ارجع لمساحتي', 'العودة إلى مساحتي',
              'Back to my space', 'Retour à mon espace')),
        ),
      ],
    );
  }
}

class _PendingInstrument extends StatelessWidget {
  const _PendingInstrument({
    required this.language,
    required this.t,
  });

  final HaniLanguage language;
  final Localize t;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: HaniColors.warm,
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: HaniColors.warning,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Clinical instrument pending',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                t(
                  language,
                  'المسار حاضر، أما هاني ما يخترعش أسئلة ولا سكور. لازم تتحط الأداة اللي صادق عليها المختص.',
                  'المسار جاهز، لكن هاني لا يخترع أسئلة أو درجات. يجب إضافة الأداة المعتمدة من المختص.',
                  'The complete flow is ready, but Hani Maak does not invent questionnaire wording or scoring. A specialist-approved instrument must be loaded.',
                  'Le parcours complet est prêt, mais Hani Maak n’invente ni questions ni score. L’instrument validé par le spécialiste doit être chargé.',
                ),
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const HaniPill(
                label: 'SAFE BY DESIGN',
                icon: Icons.shield_outlined,
              ),
            ],
          ),
        ),
      );
}
