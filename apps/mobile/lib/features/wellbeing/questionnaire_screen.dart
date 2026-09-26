import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          language == HaniLanguage.french
              ? 'Questionnaire de bien-être'
              : language == HaniLanguage.tounsi
                  ? 'استبيان الراحة النفسية'
                  : 'Wellbeing questionnaire',
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Questionnaire unavailable.')),
        data: (data) {
          final instruments = data.questionnaires;

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
                      language == HaniLanguage.french
                          ? 'Vos réponses restent privées.'
                          : language == HaniLanguage.tounsi
                              ? 'إجاباتك تبقى خاصّة بيك.'
                              : 'Your answers stay private.',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      language == HaniLanguage.french
                          ? 'Un résumé n’est partagé avec un professionnel qu’avec votre accord.'
                          : language == HaniLanguage.tounsi
                              ? 'ما يتشارك حتى ملخّص مع مختص كان بموافقتك.'
                              : 'A professional receives a summary only after your explicit approval.',
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
                title: language == HaniLanguage.french
                    ? 'Instruments validés'
                    : language == HaniLanguage.tounsi
                        ? 'الأدوات المصادق عليها'
                        : 'Validated instruments',
              ),
              const SizedBox(height: 10),
              if (instruments.isEmpty)
                _PendingInstrument(language: language)
              else
                ...instruments.map(
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
                            'Version ${instrument['version_label'] ?? ''} · ${instrument['language'] ?? ''}',
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

class _PendingInstrument extends StatelessWidget {
  const _PendingInstrument({required this.language});
  final HaniLanguage language;

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
                language == HaniLanguage.french
                    ? 'Le parcours est prêt, mais Hani Maak n’invente ni questions ni score. L’instrument validé par le spécialiste doit être chargé.'
                    : language == HaniLanguage.tounsi
                        ? 'المسار حاضر، أمّا هاني ما يخترعش أسئلة ولا سكور. لازم تتحطّ الأداة اللي صادق عليها المختص.'
                        : 'The flow is ready, but Hani Maak does not invent questionnaire wording or scoring. A specialist-approved instrument must be loaded.',
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
