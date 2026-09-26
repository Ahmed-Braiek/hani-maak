import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';
import '../context/caregiver_context_provider.dart';
import '../hani/hani_controller.dart';

class HandoffScreen extends ConsumerWidget {
  const HandoffScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    String channel,
    String professional,
  ) async {
    await ref.read(haniChatProvider.notifier).send(
      'I want to contact $professional by $channel. Prepare only the minimum necessary summary and ask for my confirmation before sending anything.',
    );
    if (context.mounted) context.push('/hani');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(caregiverContextProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          language == HaniLanguage.french
              ? 'Aide professionnelle'
              : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                  ? 'مساعدة مختص'
                  : 'Professional support',
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Professional routes unavailable.')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            HaniGradientCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: HaniColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      language == HaniLanguage.french
                          ? 'Hani prépare uniquement un résumé pertinent. Rien n’est partagé sans votre accord explicite.'
                          : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                              ? 'هاني يجهّز كان ملخّص يلزم المختص. ما يتشارك حتى شيء بلا موافقتك.'
                              : 'Hani prepares only the relevant summary. Nothing is shared without your explicit approval.',
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (data.professionals.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No verified professional route connected yet.',
                  ),
                ),
              )
            else
              ...data.professionals.map(
                (route) {
                  final professional = route['professional'] is Map
                      ? Map<String, dynamic>.from(
                          route['professional'] as Map,
                        )
                      : <String, dynamic>{};
                  final name =
                      professional['full_name']?.toString() ?? 'Professional';
                  final specialty =
                      professional['specialty']?.toString() ?? 'Professional';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: HaniColors.primarySoft,
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    color: HaniColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          if (professional['is_verified'] ==
                                              true)
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 17,
                                              color: HaniColors.primary,
                                            ),
                                        ],
                                      ),
                                      Text(
                                        specialty,
                                        style: const TextStyle(
                                          color: HaniColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _start(context, ref, 'call', name),
                                    icon: const Icon(Icons.call_outlined),
                                    label: const Text('Call'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _start(
                                      context,
                                      ref,
                                      'WhatsApp',
                                      name,
                                    ),
                                    icon: const Icon(Icons.chat_outlined),
                                    label: const Text('WhatsApp'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => _start(
                                context,
                                ref,
                                'appointment request',
                                name,
                              ),
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                              label: Text(
                                language == HaniLanguage.french
                                    ? 'Demander un rendez-vous'
                                    : (language == HaniLanguage.tounsi || language == HaniLanguage.arabic)
                                        ? 'اطلب موعد'
                                        : 'Request appointment',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
