import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class DilemmaLibraryScreen extends ConsumerWidget {
  const DilemmaLibraryScreen({super.key});

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final items = _items(language);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'مواقف الرعاية', 'مواقف الرعاية',
            'Daily Dilemmas', 'Dilemmes du quotidien')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          HaniGradientCard(
            gradient: HaniGradients.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HaniPill(
                  label: '10 CORE SITUATIONS',
                  icon: Icons.route_outlined,
                  background: Color(0x2FFFFFFF),
                  foreground: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    language,
                    'ابدأ من الموقف الحقيقي، موش من فورم طويل.',
                    'ابدأ من الموقف الحقيقي بدل نموذج طويل.',
                    'Start from the real situation, not a long form.',
                    'Partez de la situation réelle, pas d’un long formulaire.',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.65,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    language,
                    'هاني يسأل كان على اللي يلزم، يستعمل السياق المسموح، ويعرف وقتاش يلزم إنسان.',
                    'يسأل هاني فقط ما يلزم، يستخدم السياق المصرح به، ويعرف متى يجب إشراك إنسان.',
                    'Hani asks only what matters, uses authorized context, and knows when a human should take over.',
                    'Hani pose seulement les questions utiles, utilise le contexte autorisé et sait quand passer à un humain.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE1F1EE),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HaniGradientCard(
            gradient: HaniGradients.wellbeing,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.shield_outlined, color: HaniColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(
                      language,
                      'المحتوى السريري يبقى مربوط بالمراجعة المختصة. إذا التفاصيل الموثقة ناقصة، هاني ما يخترعهاش.',
                      'يبقى المحتوى السريري خاضعًا لمراجعة المختص. إذا نقصت التفاصيل الموثقة، لا يخترعها هاني.',
                      'Clinical guidance stays validation-gated. If reviewed content is missing, Hani does not invent it.',
                      'Le contenu clinique reste soumis à validation. Si un contenu revu manque, Hani ne l’invente pas.',
                    ),
                    style: const TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...List.generate(
            items.length,
            (index) => HaniAnimatedEntrance(
              delay: Duration(milliseconds: 35 * index),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScenarioCard(
                  item: items[index],
                  onTap: () {
                    final uri = Uri(
                      path: '/hani',
                      queryParameters: {'prompt': items[index].prompt},
                    );
                    context.push(uri.toString());
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_Scenario> _items(HaniLanguage l) => [
        _Scenario(
          icon: Icons.restaurant_outlined,
          title: t(l, 'رفض الأكل', 'رفض الطعام', 'Refusal to eat',
              'Refus de manger'),
          body: t(l, 'الأكل، الشهية والتوتر وقت الوجبة.',
              'الطعام والشهية والتوتر وقت الوجبة.',
              'Eating, appetite, and mealtime difficulty.',
              'Repas, appétit et difficulté au moment de manger.'),
          prompt: 'Daily Dilemma: refusal_to_eat. Help me understand what is happening before giving any guidance.',
        ),
        _Scenario(
          icon: Icons.shower_outlined,
          title: t(l, 'رفض الحمّام', 'رفض الاستحمام', 'Refusal to bathe',
              'Refus de la toilette'),
          body: t(l, 'مقاومة، خوف أو توتر وقت النظافة.',
              'مقاومة أو خوف أو توتر أثناء النظافة.',
              'Resistance, fear, or tension around bathing.',
              'Résistance, peur ou tension autour de la toilette.'),
          prompt: 'Daily Dilemma: refusal_to_bathe. Ask only the minimum questions needed.',
        ),
        _Scenario(
          icon: Icons.warning_amber_rounded,
          title: t(l, 'توتر أو عدوانية', 'هياج أو عدوانية',
              'Agitation or aggression', 'Agitation ou agressivité'),
          body: t(l, 'موقف متوتر يلزمه فهم هادئ وحدود أمان واضحة.',
              'موقف متوتر يحتاج فهمًا هادئًا وحدود أمان واضحة.',
              'A tense situation that needs calm understanding and clear safety boundaries.',
              'Une situation tendue qui demande calme et limites de sécurité claires.'),
          prompt: 'Daily Dilemma: agitation_aggression. First check immediate safety, then clarify the situation.',
        ),
        _Scenario(
          icon: Icons.repeat_rounded,
          title: t(l, 'تكرار الأسئلة', 'تكرار الأسئلة', 'Repeated questions',
              'Questions répétées'),
          body: t(l, 'نفس السؤال يتعاود برشة خلال النهار.',
              'السؤال نفسه يتكرر كثيرًا خلال اليوم.',
              'The same question keeps coming back.',
              'La même question revient souvent.'),
          prompt: 'Daily Dilemma: repeated_questions. Help me respond without turning this into a generic checklist.',
        ),
        _Scenario(
          icon: Icons.bedtime_outlined,
          title: t(l, 'مشاكل النوم', 'مشاكل النوم', 'Sleep problems',
              'Problèmes de sommeil'),
          body: t(l, 'ليلة صعيبة أو روتين نوم تبدّل.',
              'ليلة صعبة أو تغير في روتين النوم.',
              'A difficult night or a changed sleep pattern.',
              'Une nuit difficile ou un rythme de sommeil modifié.'),
          prompt: 'Daily Dilemma: sleep_problems. Use the recent care context if available.',
        ),
        _Scenario(
          icon: Icons.directions_walk_rounded,
          title: t(l, 'الخروج أو الضياع', 'التجول أو الضياع', 'Wandering',
              'Errance'),
          body: t(l, 'الخروج من المكان أو صعوبة تحديد وين مشى.',
              'الخروج من المكان أو صعوبة معرفة مكانه.',
              'Leaving the safe area or difficulty knowing where the person went.',
              'Sortie de la zone sûre ou difficulté à localiser la personne.'),
          prompt: 'Daily Dilemma: wandering. Check whether the person is located and safe now before anything else.',
        ),
        _Scenario(
          icon: Icons.medication_outlined,
          title: t(l, 'رفض الدواء', 'رفض الدواء', 'Refusing medication',
              'Refus du médicament'),
          body: t(l, 'نفهم الموقف من غير تبديل الجرعة أو التوقيت.',
              'نفهم الموقف دون تغيير الجرعة أو التوقيت.',
              'Understand the situation without changing dose or timing.',
              'Comprendre la situation sans modifier dose ni horaire.'),
          prompt: 'Daily Dilemma: refusing_medication. Do not change dose, timing, treatment, crush, or mix medication.',
        ),
        _Scenario(
          icon: Icons.change_circle_outlined,
          title: t(l, 'تخبّط تبدّل فجأة', 'تفاقم مفاجئ في الارتباك',
              'Sudden worsening of confusion',
              'Aggravation soudaine de la confusion'),
          body: t(l, 'تبدّل جديد مقارنة بالعادة يحتاج حدود واضحة.',
              'تغير جديد مقارنة بالمعتاد يحتاج حدودًا واضحة.',
              'A new change from usual that needs careful boundaries.',
              'Un changement nouveau par rapport à l’habitude.'),
          prompt: 'Daily Dilemma: sudden_confusion_worsening. Clarify what changed and whether there is an immediate safety concern.',
        ),
        _Scenario(
          icon: Icons.help_outline_rounded,
          title: t(l, 'هذا عادي؟ نكلم طبيب؟', 'هل هذا طبيعي؟ هل أتصل بطبيب؟',
              'Is this normal? Should I call a doctor?',
              'Est-ce normal ? Dois-je appeler un médecin ?'),
          body: t(l, 'هاني يوضح الحدود ويعاونك تعرف الخطوة الجاية.',
              'يوضح هاني حدوده ويساعدك على تحديد الخطوة التالية.',
              'Hani explains uncertainty and helps you find the next step.',
              'Hani explique l’incertitude et aide à choisir la prochaine étape.'),
          prompt: 'Daily Dilemma: is_this_normal. Help me understand what is new and whether human input is appropriate.',
        ),
        _Scenario(
          icon: Icons.battery_1_bar_rounded,
          title: t(l, 'ما عادش نجم', 'لم أعد أستطيع التحمل',
              'I cannot take this anymore',
              'Je n’en peux plus'),
          body: t(l, 'مساحة خاصة للمرافق: نسمع، نعاون عمليًا أو نوصل بإنسان.',
              'مساحة خاصة لمقدم الرعاية: استماع، مساعدة عملية أو دعم بشري.',
              'A private caregiver space for listening, practical relief, or human support.',
              'Un espace privé pour écouter, alléger la charge ou joindre un humain.'),
          prompt: 'Daily Dilemma: caregiver_cannot_take_anymore. First ask whether I want listening, practical help, or human support.',
        ),
      ];
}

class _Scenario {
  const _Scenario({
    required this.icon,
    required this.title,
    required this.body,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String body;
  final String prompt;
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.item,
    required this.onTap,
  });

  final _Scenario item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: HaniColors.primarySoft,
                  child: Icon(item.icon, color: HaniColors.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: HaniColors.muted,
                          height: 1.35,
                          fontSize: 12.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      );
}
