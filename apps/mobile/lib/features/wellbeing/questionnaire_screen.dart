import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../context/caregiver_context_provider.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wellbeing questionnaire')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Questionnaire unavailable.')),
        data: (data) {
          final instruments = data.questionnaires;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HaniColors.primarySoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: HaniColors.primary),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Questionnaire results stay private to the caregiver unless they explicitly choose to share a summary with a professional.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Validated instruments',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'The engine supports versioned questions, language variants, scoring rules and interpretation bands.',
                style: TextStyle(color: HaniColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              if (instruments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(0xFFFFF3E6),
                              child: Icon(Icons.pending_actions_rounded, color: HaniColors.warning),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Clinical instrument not loaded yet',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The product flow is ready, but Hani Maak will not invent questionnaire wording or scoring. Load the exact psychologist-approved instrument to activate this section.',
                          style: TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HaniColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Ready schema: definition → version → language → questions → options → scoring → interpretation → history.',
                            style: TextStyle(
                              color: HaniColors.muted,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...instruments.map(
                  (instrument) {
                    final definition = instrument['definition'] is Map
                        ? Map<String, dynamic>.from(instrument['definition'] as Map)
                        : <String, dynamic>{};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            backgroundColor: HaniColors.primarySoft,
                            child: Icon(Icons.fact_check_outlined, color: HaniColors.primary),
                          ),
                          title: Text(
                            definition['name']?.toString() ?? 'Validated questionnaire',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'Version ' +
                                (instrument['version_label']?.toString() ?? '') +
                                ' · ' +
                                (instrument['language']?.toString() ?? ''),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
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
