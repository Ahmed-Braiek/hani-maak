import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../care/care_workflow_api.dart';
import '../context/caregiver_context_provider.dart';

class CareSummaryScreen extends ConsumerStatefulWidget {
  const CareSummaryScreen({super.key});

  @override
  ConsumerState<CareSummaryScreen> createState() =>
      _CareSummaryScreenState();
}

class _CareSummaryScreenState extends ConsumerState<CareSummaryScreen> {
  final recipient = TextEditingController(
    text: const String.fromEnvironment(
      'HANI_WHATSAPP_TEST_RECIPIENT',
      defaultValue: '',
    ),
  );
  String summary = '';
  String status = '';
  bool busy = false;
  String summaryType = 'daily';

  @override
  void dispose() {
    recipient.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() => busy = true);
    try {
      final result = await CareWorkflowApi().run(
        'prepare_summary',
        args: {'summaryType': summaryType},
      );
      setState(() {
        summary = result['summary']?.toString() ?? '';
        status = result['status']?.toString() ?? 'prepared';
      });
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _send() async {
    final value = recipient.text.trim();
    if (value.isEmpty) {
      _show('Enter the WhatsApp recipient in international format.');
      return;
    }
    setState(() => busy = true);
    try {
      final result = await CareWorkflowApi().run(
        'send_whatsapp_summary',
        args: {
          'summaryType': summaryType,
          'recipient': value,
        },
      );
      if (!mounted) return;
      setState(() {
        summary = result['summary']?.toString() ?? summary;
        status = result['status']?.toString() ?? '';
      });

      if (status == 'sent') {
        _show('Summary sent through the configured WhatsApp Business sender.');
      } else if (status == 'configuration_required') {
        final missing = (result['missing'] as List? ?? const []).join(', ');
        _show(
          'WhatsApp Business API is not configured yet. Missing: $missing. You can still open WhatsApp with the prepared summary.',
        );
      } else {
        _show('WhatsApp delivery was not completed.');
      }
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openWhatsApp() async {
    if (summary.isEmpty) await _prepare();
    if (!mounted || summary.isEmpty) return;
    final digits = recipient.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _show('Enter a WhatsApp number first.');
      return;
    }
    final uri = Uri.https(
      'wa.me',
      '/$digits',
      {'text': summary},
    );
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _show('WhatsApp could not be opened on this device.');
    }
  }

  void _show(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value.replaceFirst('Bad state: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(caregiverContextProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Care summary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          HaniGradientCard(
            gradient: HaniGradients.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HaniPill(
                  label: 'MINIMUM NECESSARY',
                  icon: Icons.privacy_tip_outlined,
                  background: Color(0x2AFFFFFF),
                  foreground: Colors.white,
                ),
                const SizedBox(height: 14),
                Text(
                  data == null
                      ? 'A useful caregiver summary.'
                      : 'A useful summary for ${data.patientName}.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Medication activity, appointments, shared timeline updates and open care tasks can be included. Private caregiver wellbeing and private Hani conversations are excluded.',
                  style: TextStyle(
                    color: Color(0xFFEAF6FF),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'daily',
                icon: Icon(Icons.today_outlined),
                label: Text('Daily'),
              ),
              ButtonSegment(
                value: 'weekly',
                icon: Icon(Icons.date_range_outlined),
                label: Text('Weekly'),
              ),
            ],
            selected: {summaryType},
            onSelectionChanged: busy
                ? null
                : (selection) {
                    setState(() {
                      summaryType = selection.first;
                      summary = '';
                    });
                  },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : _prepare,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Generate summary'),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            HaniSectionHeader(
              title: 'Prepared summary',
              subtitle: status.isEmpty ? null : status,
            ),
            const SizedBox(height: 9),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: SelectableText(
                  summary,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: summary));
                if (mounted) _show('Summary copied.');
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy summary'),
            ),
          ],
          const SizedBox(height: 22),
          const HaniSectionHeader(
            title: 'WhatsApp delivery',
            subtitle:
                'Business API when configured · device handoff as fallback',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: recipient,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Recipient',
              hintText: '+216…',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: busy ? null : _send,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send with WhatsApp Business'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : _openWhatsApp,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open WhatsApp to send'),
          ),
          const SizedBox(height: 14),
          const HaniGradientCard(
            gradient: HaniGradients.soft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: HaniColors.primary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Direct server delivery requires a WhatsApp Business Cloud API sender. If those credentials are absent, Hani Maak explicitly reports configuration_required and never claims the message was sent.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
