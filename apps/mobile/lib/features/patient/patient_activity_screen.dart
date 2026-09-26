import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class PatientActivityScreen extends ConsumerStatefulWidget {
  const PatientActivityScreen({super.key});

  @override
  ConsumerState<PatientActivityScreen> createState() =>
      _PatientActivityScreenState();
}

class _PatientActivityScreenState
    extends ConsumerState<PatientActivityScreen> {
  int? active;

  String t(HaniLanguage l, String tn, String ar, String en, String fr) =>
      switch (l) {
        HaniLanguage.tounsi => tn,
        HaniLanguage.arabic => ar,
        HaniLanguage.english => en,
        HaniLanguage.french => fr,
      };

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'لحظة مع المريض', 'نشاط مع المريض',
            'Patient activity', 'Activité patient')),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Activity unavailable.')),
        data: (data) {
          final name = data.patientName;
          final items = [
            (
              Icons.photo_library_outlined,
              t(language, 'صور ووجوه مألوفة', 'صور ووجوه مألوفة',
                  'Familiar photos and people', 'Photos et visages familiers'),
              t(
                language,
                'اختار صورة مألوفة واسأل سؤال بسيط بلا ما تحولها لاختبار ذاكرة.',
                'اختر صورة مألوفة واسأل سؤالًا بسيطًا دون تحويله إلى اختبار للذاكرة.',
                'Choose a familiar photo and invite a simple story without turning it into a memory test.',
                'Choisissez une photo familière et invitez un souvenir sans transformer le moment en test.',
              ),
            ),
            (
              Icons.place_outlined,
              t(language, 'أماكن وعادات', 'أماكن وعادات', 'Places and routines',
                  'Lieux et habitudes'),
              t(
                language,
                'احكي على بلاصة معروفة، عادة قديمة، ولا حاجة مرتبطة بالروتين.',
                'تحدث عن مكان مألوف أو عادة قديمة أو جزء معروف من الروتين.',
                'Talk about a familiar place, an old routine, or a well-known part of daily life.',
                'Parlez d’un lieu familier, d’une ancienne habitude ou d’un repère du quotidien.',
              ),
            ),
            (
              Icons.music_note_outlined,
              t(language, 'موسيقى مألوفة', 'موسيقى مألوفة', 'Familiar music',
                  'Musique familière'),
              t(
                language,
                'استعمل موسيقى يعرفها ' + name + ' وخلي النشاط خفيف. إذا بان عليه الضيق، وقف.',
                'استخدم موسيقى مألوفة لدى ' + name + ' واجعل النشاط خفيفًا. إذا ظهر الانزعاج، توقف.',
                'Use music familiar to ' + name + ' and keep the moment gentle. Stop if it becomes uncomfortable.',
                'Utilisez une musique familière à ' + name + ' et gardez le moment léger. Arrêtez si cela devient inconfortable.',
              ),
            ),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              HaniGradientCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.spa_outlined, color: HaniColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(language, 'نشاط خفيف، موش اختبار',
                                'نشاط لطيف، وليس اختبارًا',
                                'A gentle moment, not a test',
                                'Un moment doux, pas un test'),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t(
                              language,
                              'هذا مود تجريبي غير علاجي. الهدف لحظة مريحة ومألوفة مع ' + name + '.',
                              'هذا وضع تجريبي غير علاجي. الهدف لحظة مريحة ومألوفة مع ' + name + '.',
                              'This is a non-clinical prototype mode for a calm, familiar moment with ' + name + '.',
                              'Ce mode prototype est non clinique et vise un moment calme et familier avec ' + name + '.',
                            ),
                            style: const TextStyle(
                              color: HaniColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ...List.generate(items.length, (i) {
                final item = items[i];
                final selected = active == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected ? HaniColors.primarySoft : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color:
                            selected ? HaniColors.primary : HaniColors.line,
                      ),
                    ),
                    child: ListTile(
                      onTap: () =>
                          setState(() => active = selected ? null : i),
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? HaniColors.primary
                            : HaniColors.primarySoft,
                        child: Icon(
                          item.$1,
                          color:
                              selected ? Colors.white : HaniColors.primary,
                        ),
                      ),
                      title: Text(
                        item.$2,
                        style:
                            const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item.$3,
                          style: const TextStyle(
                            color: HaniColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
