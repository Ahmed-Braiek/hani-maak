import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class HowHaniWorksScreen extends ConsumerWidget {
  const HowHaniWorksScreen({super.key});

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(appSettingsProvider.select((s) => s.language));
    final steps = [
      (
        Icons.graphic_eq_rounded,
        t(l, 'احكي عادي', 'تحدث بشكل طبيعي', 'Talk naturally', 'Parlez naturellement'),
        t(l,
            'بالصوت ولا بالكتابة. هاني يستعمل سياق الرعاية المسموح به وما يخليكش تعاود كل شيء.',
            'بالصوت أو الكتابة. يستخدم هاني سياق الرعاية المصرح به دون أن يجعلك تكرر كل شيء.',
            'Use voice or text. Hani uses authorized care context so you do not repeat everything.',
            'Par voix ou texte. Hani utilise le contexte autorisé pour éviter de vous faire tout répéter.'),
      ),
      (
        Icons.route_outlined,
        t(l, 'من الحيرة لخطوة واضحة', 'من الحيرة إلى خطوة واضحة',
            'From uncertainty to a next step', 'De l’incertitude à la prochaine étape'),
        t(l,
            'يسأل كان على اللي يلزم، يوضح حدود المعلومة، ويعاونك تعرف شنوّة تعمل بعد.',
            'يسأل هاني فقط ما يلزم، يوضح حدود معلوماته، ويساعدك على تحديد الخطوة التالية.',
            'Hani asks only what matters, explains uncertainty, and helps you decide what to do next.',
            'Hani pose seulement les questions utiles, explique les limites et vous aide à choisir la prochaine étape.'),
      ),
      (
        Icons.lock_outline_rounded,
        t(l, 'مساحتك تبقى خاصة', 'مساحتك تبقى خاصة', 'Your space stays private',
            'Votre espace reste privé'),
        t(l,
            'إحساسك ومحادثاتك الخاصة ما يتشاركوش مع العائلة. الحوادث تبدأ كمسودة خاصة.',
            'لا تشارك محادثاتك العاطفية الخاصة مع العائلة. وتبدأ الحوادث كمسودة خاصة.',
            'Your private wellbeing is not family data. Care incidents start as private drafts.',
            'Votre bien-être privé n’est pas une donnée familiale. Les incidents commencent en brouillon privé.'),
      ),
      (
        Icons.groups_2_outlined,
        t(l, 'قسّم الحمل بلا لوم', 'وزّع الحمل بلا لوم', 'Share the load without blame',
            'Partager la charge sans jugement'),
        t(l,
            'اطلب مساعدة من دائرة الرعاية. الطرف الآخر ينجم يقبل، يرفض أو يقترح بديل.',
            'اطلب المساعدة من دائرة الرعاية، ويستطيع الطرف الآخر القبول أو الرفض أو اقتراح بديل.',
            'Request help from the Care Circle. The recipient can accept, decline, or propose an alternative.',
            'Demandez du relais au Cercle de soins. Le destinataire peut accepter, refuser ou proposer une alternative.'),
      ),
      (
        Icons.medical_services_outlined,
        t(l, 'الإنسان وقت يلزم', 'الإنسان عندما يلزم', 'Human support when stakes rise',
            'Un humain quand les enjeux augmentent'),
        t(l,
            'كي الموضوع يخرج على دور هاني، يسهّل عليك الاتصال بمختص بملخص قصير وبعد موافقتك.',
            'عندما تتجاوز الحالة دور هاني، يسهل التواصل مع مختص بملخص قصير وبعد موافقتك.',
            'When the situation exceeds Hani’s safe role, it helps you reach a professional with a minimum-necessary summary after consent.',
            'Quand la situation dépasse le rôle sûr de Hani, il facilite le contact avec un professionnel avec votre accord.'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t(l, 'كيفاش يخدم هاني', 'كيف يعمل هاني', 'How Hani Maak works',
            'Comment fonctionne Hani Maak')),
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
                  label: 'CAREGIVER-FIRST',
                  icon: Icons.favorite_outline_rounded,
                  background: Color(0x2FFFFFFF),
                  foreground: Colors.white,
                ),
                const SizedBox(height: 18),
                Text(
                  t(l,
                      'موش تطبيق للمريض برك. هذا التطبيق ليك إنت زادة.',
                      'ليس تطبيقًا للمريض فقط. إنه مصمم لك أنت أيضًا.',
                      'Not just a patient app. It is built for the person carrying the care.',
                      'Pas seulement une app patient. Elle est conçue pour la personne qui porte la charge.'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  t(l,
                      'هاني ينقص الحيرة، العزلة، والحمل الذهني من غير ما يعوض الطبيب أو العائلة.',
                      'يهدف هاني إلى تقليل الحيرة والعزلة والعبء الذهني دون أن يحل محل الطبيب أو العائلة.',
                      'Hani reduces uncertainty, isolation, and mental load without replacing clinicians or family.',
                      'Hani réduit l’incertitude, l’isolement et la charge mentale sans remplacer les professionnels ni la famille.'),
                  style: const TextStyle(color: Color(0xFFE1F1EE), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...List.generate(
            steps.length,
            (i) => HaniAnimatedEntrance(
              delay: Duration(milliseconds: i * 60),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StepCard(
                  index: i + 1,
                  icon: steps[i].$1,
                  title: steps[i].$2,
                  body: steps[i].$3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/hani'),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(t(l, 'ابدأ مع هاني', 'ابدأ مع هاني', 'Start with Hani',
                'Commencer avec Hani')),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: () => context.go('/today'),
            icon: const Icon(Icons.home_outlined),
            label: Text(t(l, 'امشي لليوم', 'الذهاب إلى اليوم', 'Go to Today',
                'Aller à Aujourd’hui')),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: HaniColors.primarySoft,
                    child: Icon(icon, color: HaniColors.primary),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: HaniColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(body,
                        style: const TextStyle(
                            color: HaniColors.muted, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
