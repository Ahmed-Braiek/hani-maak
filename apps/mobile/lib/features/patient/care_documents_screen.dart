import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';

class CareDocumentsScreen extends ConsumerWidget {
  const CareDocumentsScreen({super.key});

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
    final value = ref.watch(caregiverContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(language, 'وثائق الرعاية', 'وثائق الرعاية',
            'Care documents', 'Documents de soins')),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Documents unavailable.')),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(caregiverContextProvider.notifier).refreshContext(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
            children: [
              HaniGradientCard(
                gradient: HaniGradients.soft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.folder_copy_outlined,
                          color: HaniColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t(
                          language,
                          'الوصفات والوثائق المستخرجة بالـOCR تتراجع قبل ما تولّي جزء من ملف الرعاية.',
                          'تتم مراجعة الوصفات والوثائق المستخرجة بالـOCR قبل إضافتها إلى ملف الرعاية.',
                          'OCR documents are reviewed before becoming part of the care record.',
                          'Les documents OCR sont relus avant d’intégrer le dossier de soins.',
                        ),
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.push('/medications'),
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(
                  t(language, 'امسح وصفة أو علبة دواء',
                      'امسح وصفة أو علبة دواء',
                      'Scan prescription or medication box',
                      'Scanner ordonnance ou boîte de médicament'),
                ),
              ),
              const SizedBox(height: 22),
              HaniSectionHeader(
                title: t(language, 'الوثائق المحفوظة', 'الوثائق المحفوظة',
                    'Saved documents', 'Documents enregistrés'),
                subtitle: data.careDocuments.length.toString(),
              ),
              const SizedBox(height: 10),
              if (data.careDocuments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      t(
                        language,
                        'ما فماش وثائق محفوظة توّا.',
                        'لا توجد وثائق محفوظة حاليًا.',
                        'No saved care documents yet.',
                        'Aucun document enregistré pour le moment.',
                      ),
                      style: const TextStyle(color: HaniColors.muted),
                    ),
                  ),
                )
              else
                ...data.careDocuments.map(
                  (document) {
                    final reviewed = document['reviewed'] == true;
                    final type =
                        document['document_type']?.toString() ?? 'document';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          leading: CircleAvatar(
                            backgroundColor: reviewed
                                ? HaniColors.primarySoft
                                : HaniColors.warm,
                            child: Icon(
                              type.contains('prescription')
                                  ? Icons.receipt_long_outlined
                                  : Icons.description_outlined,
                              color: reviewed
                                  ? HaniColors.primary
                                  : HaniColors.warning,
                            ),
                          ),
                          title: Text(
                            document['title']?.toString() ??
                                document['original_file_name']?.toString() ??
                                'Care document',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            reviewed ? 'Reviewed' : 'Review required',
                          ),
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                document['extracted_text']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? document['extracted_text'].toString()
                                    : 'No extracted text stored.',
                                style: const TextStyle(
                                  color: HaniColors.muted,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
