import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_api.dart';
import '../context/caregiver_context_provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool busy = false;
  String type = 'daily';
  String? preview;
  String? status;
  static const testRecipient = '21627983305';

  Future<void> generate() async {
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final result = await ref.read(caregiverContextApiProvider).action(
        'preview_summary',
        args: {'summaryType': type},
      );
      setState(() => preview = result?['summaryText']?.toString() ?? '');
    } catch (e) {
      setState(() => status = 'Could not generate summary: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> send() async {
    if (preview == null || preview!.trim().isEmpty) {
      await generate();
      if (preview == null || preview!.trim().isEmpty) return;
    }

    setState(() {
      busy = true;
      status = null;
    });
    try {
      final result = await ref.read(caregiverContextApiProvider).action(
        'send_whatsapp_summary',
        args: {
          'summaryType': type,
          'recipient': testRecipient,
        },
      );

      final sent = result?['sent'] == true;
      final configurationRequired =
          result?['configurationRequired'] == true;

      if (sent) {
        setState(() => status = 'WhatsApp summary sent successfully.');
        await ref.read(caregiverContextProvider.notifier).refreshContext();
      } else if (configurationRequired) {
        setState(
          () => status =
              'WhatsApp Business API is not configured yet. You can still open WhatsApp with the exact generated summary for the team test.',
        );
      } else {
        setState(
          () => status =
              result?['delivery']?['error']?.toString() ??
              'WhatsApp provider rejected the message.',
        );
      }
    } catch (e) {
      setState(() => status = 'WhatsApp workflow failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openWhatsApp() async {
    final text = preview?.trim();
    if (text == null || text.isEmpty) {
      await generate();
      if (preview == null || preview!.trim().isEmpty) return;
    }
    final uri = Uri.parse(
      'https://wa.me/$testRecipient?text=${Uri.encodeComponent(preview!)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not available on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appSettingsProvider.select((s) => s.language));
    final history = ref.watch(caregiverContextProvider);

    String title() => switch (l) {
          HaniLanguage.tounsi => 'ملخّص العائلة',
          HaniLanguage.arabic => 'ملخص مقدم الرعاية',
          HaniLanguage.french => 'Résumé aidant',
          HaniLanguage.english => 'Caregiver summary',
        };

    return Scaffold(
      appBar: AppBar(title: Text(title())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          HaniGradientCard(
            gradient: HaniGradients.hero,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HaniPill(
                  label: 'MINIMUM NECESSARY',
                  icon: Icons.privacy_tip_outlined,
                  background: Color(0x2FFFFFFF),
                  foreground: Colors.white,
                ),
                SizedBox(height: 14),
                Text(
                  'A useful care summary without exposing private caregiver wellbeing or private Hani conversations.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
            ],
            selected: {type},
            onSelectionChanged: busy
                ? null
                : (values) {
                    setState(() {
                      type = values.first;
                      preview = null;
                    });
                  },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : generate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generate summary'),
          ),
          const SizedBox(height: 16),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else if (preview != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: SelectableText(
                  preview!,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(17),
                child: Text(
                  'Generate a summary to review exactly what would be shared.',
                  style: TextStyle(color: HaniColors.muted),
                ),
              ),
            ),
          if (status != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: HaniColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(status!, style: const TextStyle(height: 1.4)),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: busy ? null : send,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send through WhatsApp Business'),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: busy ? null : openWhatsApp,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open WhatsApp with reviewed summary'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test recipient: +216 27 983 305. Direct automated sending requires an approved WhatsApp Business sender.',
            style: TextStyle(color: HaniColors.muted, fontSize: 11.5),
          ),
          const SizedBox(height: 24),
          const HaniSectionHeader(title: 'Delivery history'),
          const SizedBox(height: 10),
          history.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (ctx) => Column(
              children: ctx.summaryDeliveries.take(10).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: HaniColors.primarySoft,
                        child: Icon(
                          item['status'] == 'sent'
                              ? Icons.check_rounded
                              : item['status'] == 'failed'
                                  ? Icons.error_outline_rounded
                                  : Icons.settings_outlined,
                          color: HaniColors.primary,
                        ),
                      ),
                      title: Text(
                        '${item['summary_type'] ?? 'daily'} summary',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${item['status'] ?? 'prepared'} · ${item['recipient'] ?? ''}',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
